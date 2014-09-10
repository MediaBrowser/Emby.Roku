'**********************************************************
'** CreateLoginScreen
'**********************************************************

Function CreateLoginScreen(viewController as Object) as Object

	' Dummy up an item
	item = CreateObject("roAssociativeArray")
	item.Title = "Login"
	
    ' Show login tiles - common convention is square images
    screen = CreatePosterScreen(viewController, item, "arced-square")

	screen.baseHandleMessage = screen.HandleMessage
	screen.HandleMessage = handleLoginScreenMessage

	screen.GetDataContainer = getLoginScreenDataContainer

	screen.OnUserInput = onLoginScreenUserInput

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

            if selectedProfile.ContentType = "user"

                if selectedProfile.HasPassword

					m.showPasswordInput(selectedProfile.Title)

                else
				
					OnPasswordEntered(selectedProfile.Title, "")
					
                end if

            else if selectedProfile.ContentType = "manual"
				
				m.showUsernameInput()

            else if selectedProfile.ContentType = "server"
				
				showServerListScreen(viewController)

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

		OnPasswordEntered(m.usernameText, firstOf(value, ""))

	end if

End Sub

Sub OnPasswordEntered(usernameText, passwordText)

	Debug ("onLoginScreenUserInput")

	' Check password
	authResult = authenticateUser(usernameText, passwordText)

	If authResult <> invalid
		RegWrite("userId", authResult.User.Id)
		SetServerData(authResult.ServerId, "AccessToken", authResult.AccessToken)
		RegWrite("activeServerId", authResult.ServerId)
		GetViewController().changeUser(authResult.User.Id)
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

    profiles = getPublicUserProfiles()

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

    ' Add Server Tile (eventually move this)
    switchServer = {
        Title: "Select Server"
        ContentType: "server"
        ShortDescriptionLine1: "Select Server"
        HDPosterUrl: viewController.getThemeImageUrl("hd-switch-server.png"),
        SDPosterUrl: viewController.getThemeImageUrl("hd-switch-server.png")
    }

    profiles.Push( manualLogin )
    profiles.Push( switchServer )

	obj = CreateObject("roAssociativeArray")
	obj.names = []
	obj.keys = []
	obj.items = profiles

	return obj

End Function