'**********************************************************
'** CreateLoginScreen
'**********************************************************

Function CreateLoginScreen(viewController as Object, serverUrl as String) as Object

	' Dummy up an item
	item = CreateObject("roAssociativeArray")
	item.Title = "Login"
	item.serverUrl = serverUrl
	
    ' Show login tiles - common convention is square images
    screen = CreatePosterScreen(viewController, item, "arced-square")

	screen.baseHandleMessage = screen.HandleMessage
	screen.HandleMessage = handleLoginScreenMessage

	screen.GetDataContainer = getLoginScreenDataContainer

	screen.OnUserInput = onLoginScreenUserInput

	screen.serverUrl = serverUrl
	screen.showPasswordInput = loginScreenShowPasswordInput
	screen.showUsernameInput = loginScreenShowUsernameInput

    return screen
End Function

Function handleLoginScreenMessage(msg) as Boolean

	handled = false

	viewController = m.ViewController

    if type(msg) = "roPosterScreenEvent" then

        if msg.isListItemSelected() then

			handled = true

            index = msg.GetIndex()
            content = m.contentArray[m.focusedList].content
            selectedProfile = content[index]
			serverUrl = m.serverUrl

            if selectedProfile.ContentType = "user"

                if selectedProfile.HasPassword

					m.showPasswordInput(selectedProfile.Title)

                else
				
					OnPasswordEntered(serverUrl, selectedProfile.Title, "")
					
                end if

            else if selectedProfile.ContentType = "manual"
				
				m.showUsernameInput()

            else if selectedProfile.ContentType = "server"
				
				showServerListScreen(viewController)
				
			else if selectedProfile.ContentType = "ConnectSignIn"

				viewController.createScreenForItem(content, index, ["Connect"], true)
			
            else

                'return 2
				viewController.ShowInitialScreen()

            end if

        end if
    end if

	if handled = false then
		handled = m.baseHandleMessage(msg)
	end If

	return handled

End Function

Sub loginScreenShowUsernameInput()

	screen = m.ViewController.CreateTextInputScreen(invalid, "Enter Username", ["Enter Username"], "", false)
	screen.ValidateText = OnRequiredTextValueEntered
	screen.Show(true)

	value = screen.Text
	
	if value <> invalid and value <> "" then
		m.showPasswordInput(value)
	end if
	
End Sub


Sub loginScreenShowPasswordInput(usernameText as String)

	m.usernameText = usernameText

	screen = m.ViewController.CreateTextInputScreen(invalid, "Enter Password", ["Enter Password"], "", true)
	screen.Listener = m
	screen.inputType = "password"
	screen.Show()

End Sub

Sub onLoginScreenUserInput(value, screen)

	Debug ("onLoginScreenUserInput")

	if screen.inputType = "password" then
		
		Debug ("onLoginScreenUserInput - password")

		OnPasswordEntered(m.serverUrl, m.usernameText, firstOf(value, ""))

	end if

End Sub

Sub OnPasswordEntered(serverUrl, usernameText, passwordText)

	Debug ("OnPasswordEntered")

	' Check password
	authResult = authenticateUser(serverUrl, usernameText, passwordText)

	If authResult <> invalid
		
		ConnectionManager().SetServerData(authResult.ServerId, "AccessToken", authResult.AccessToken)
		ConnectionManager().SetServerData(authResult.ServerId, "UserId", authResult.User.Id)
		
		GetViewController().onSignedIn(authResult.ServerId, serverUrl, authResult.User.Id)
	Else
		ShowPasswordFailed()
	End If

End Sub

'******************************************************
' Show Password Failed
'******************************************************

Sub ShowPasswordFailed()

    title = "Login Failed"
    message = "Invalid username or password. Please try again."

    dlg = createBaseDialog()
    dlg.Title = title
	dlg.Text = message
    dlg.SetButton("back", "Back")
    dlg.Show(true)
	
End Sub

Function getLoginScreenDataContainer(viewController as Object, item as Object) as Object

    profiles = getPublicUserProfiles(item.serverUrl)

    if profiles = invalid
        return invalid
    end if

    ' Support manual login. 
    manualLogin = {
        Title: "Manual Login"
        ContentType: "manual"
        ShortDescriptionLine1: "Manual Login"
        HDPosterUrl: viewController.getThemeImageUrl("hd-default-user.png"),
        SDPosterUrl: viewController.getThemeImageUrl("hd-default-user.png")
    }
	profiles.Push( manualLogin )
    
    ' Add Server Tile (eventually move this)
    switchServer = {
        Title: "Select Server"
        ContentType: "server"
        ShortDescriptionLine1: "Select Server"
        HDPosterUrl: viewController.getThemeImageUrl("hd-switch-server.png"),
        SDPosterUrl: viewController.getThemeImageUrl("hd-switch-server.png")
    }
    profiles.Push( switchServer )

	if ConnectionManager().isLoggedIntoConnect() = false then
		' Add Server Tile (eventually move this)
		connect = {
			Title: "Sign in with Emby Connect"
			ContentType: "ConnectSignIn"
			ShortDescriptionLine1: "Sign in with Emby Connect"
			HDPosterUrl: viewController.getThemeImageUrl("hd-connectsignin.jpg"),
			SDPosterUrl: viewController.getThemeImageUrl("hd-connectsignin.jpg")
		}
		profiles.Push( connect )
	end if
	
	obj = CreateObject("roAssociativeArray")
	obj.names = []
	obj.keys = []
	obj.items = profiles

	return obj

End Function