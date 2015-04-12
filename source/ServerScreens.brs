'*****************************************************************
'**  Emby Roku Client - Server Screens
'*****************************************************************


'**********************************************************
'** Create Server Screen
'**********************************************************

Function createServerFirstRunSetupScreen(viewController as Object)

    header = "Welcome to Emby"
    paragraphs = []
    paragraphs.Push("With Emby you can easily stream videos, music and photos to Roku and other devices from your Emby Server.")
    paragraphs.Push("To begin, please make sure your Emby Server is currently running. For information on how to download and install Emby Server, visit:")
    paragraphs.Push("http://www.emby.media")

    screen = createParagraphScreen(header, paragraphs, viewController)
    screen.ScreenName = "FirstRun"
	
    screen.SetButton("gonext", "Next")

    ' Add exit button for legacy devices
    if getGlobalVar("legacyDevice")
        screen.SetButton("exit", "Exit Channel")
    end if
	
	screen.HandleButton = handleFirstRunSetupScreenButton
	
	return screen

End Function

Function handleFirstRunSetupScreenButton(command, data) As Boolean

	m.goHomeOnPop = true
	
    if command = "gonext"
	
        screen = createConnectSignInScreen(m.ViewController)
		m.ViewController.InitializeOtherScreen(screen, ["Connect"])
		screen.Show()
	
		return false

    else if command = "exit"

        m.goHomeOnPop = false
		
	end If

	return true
	
End Function


'**********************************************************
'** Create Server ListScreen
'**********************************************************

Sub showServerListScreen(viewController as Object)

	screen = createServerListScreen(viewController)
	screen.ScreenName = "Server List"
	viewController.InitializeOtherScreen(screen, ["Select Server"])
	screen.Show()

End Sub

Function createServerListScreen(viewController as Object)

	facade = CreateObject("roOneLineDialog")
	facade.SetTitle("Please wait...")
	facade.ShowBusyAnimation()
	facade.Show()

	' Get Server List
    serverList = connectionManagerGetServers()
					
	facade.Close()

    ' Create List Screen
    screen = CreateListScreen(viewController)
	
    ' Setup Array
    contentList = CreateObject("roArray", 3, true)

    ' Build Server List
    for i = 0 to serverList.Count()-1
        entry = {
            Title: serverList[i].Name,
            ShortDescriptionLine1: serverList[i].Name,
            Action: "select",
            Id: serverList[i].Id,
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-server-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-server-lg.png")
        }

        contentList.push( entry )
    end for

    entry = {
            Title: ">> Add Server",
            ShortDescriptionLine1: "Add a new server",
            Action: "add",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-server-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-server-lg.png")
        }

    contentList.push( entry )
	
	if ConnectionManager().isLoggedIntoConnect() = true then
	
		entry = {
            Title: ">> Sign out of Emby Connect",
            ShortDescriptionLine1: "Sign out of Emby Connect",
            Action: "signout",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-server-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-server-lg.png")
        }

		contentList.push( entry )

	else
	
		entry = {
            Title: ">> Sign in with Emby Connect",
            ShortDescriptionLine1: "Sign in with Emby Connect",
            Action: "signin",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-server-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-server-lg.png")
        }

		contentList.push( entry )

	end if

    ' Set Content
    screen.SetContent(contentList)

	screen.contentList = contentList

	screen.baseHandleMessage = screen.HandleMessage
	screen.HandleMessage = serverListScreenHandleMessage
	screen.servers = serverList

    return screen

End Function

Function serverListScreenHandleMessage(msg) As Boolean

    handled = false

	viewController = m.ViewController

	contentList = m.contentList

    if type(msg) = "roListScreenEvent"

        if msg.isListItemSelected()

			handled = true
				
            ' Get Action
            action = contentList[msg.GetIndex()].Action

            if action = "select"
                serverId  = contentList[msg.GetIndex()].Id
                selection = createServerSelectionDialog()

                if selection = "1"
                    
					server = invalid
					for each curr in m.servers
						if curr.Id = serverId then
							server = curr
							exit for
						end if
					end for
					
					facade = CreateObject("roOneLineDialog")
					facade.SetTitle("Please wait...")
					facade.ShowBusyAnimation()
					facade.Show()

					result = ConnectionManager().connectToServerInfo(server)
					
					facade.Close()
					
					if result.State = "Unavailable"
						createDialog("Unable To Connect", "We were unable to connect to this server. Please make sure it is running and try again.", "Back", true)
					else
						navigateFromConnectionResult(result)
					end if

                else if selection = "2"
				
                    selection = createServerRemoveDialog()
                    if selection = "1"
					
                        ConnectionManager().DeleteServer(serverId)
                        Debug("Remove Server")
						
						viewController.ShowInitialScreen()
						
                    end if
                end if

            else if action = "add"

                ' Add Server Manually
                createServerConfigurationScreen(m)

            else if action = "signin"

 				signInContext = {
					ContentType: "ConnectSignIn"
				}
                viewController.createScreenForItem(signInContext, 0, ["Connect"], true)
               

            else if action = "signout"

				viewController.Logout()

            end if

        end if

    end if

	return handled or m.baseHandleMessage(msg)
End Function


'******************************************************
' Show Manual Server Configuration Keyboard Screens
'******************************************************

Sub createServerConfigurationScreen(parentScreen as Object) 

	screen = GetViewController().CreateTextInputScreen("Enter Server Address", "Server Address (ex. 192.168.1.100 or https://myserver.com)", ["Server Setup"], "", false)
	screen.ValidateText = OnServerAddressTextValueEntered
	screen.Show(true)

	value = screen.Text
    
	portScreen = GetViewController().CreateTextInputScreen("Enter Server Port", "Server Port #", ["Server Setup"], "8096", false)
	portScreen.ValidateText = OnPortTextValueEntered
	portScreen.ipAddress = value
	
	parentScreen.OnUserInput = onServerConfigurationUserInput
	portScreen.Listener = parentScreen
	
	portScreen.inputType = "port"
	portScreen.Show()

End Sub

Function OnRequiredTextValueEntered(value) As Boolean

	if value <> invalid and value <> "" then
		return true
	else
	
		createDialog("Invalid Input", "Please enter a valid value.", "Back", true)
	
		return false
	end if
	
End Function

Function OnServerAddressTextValueEntered(value) As Boolean

	if value <> invalid and value <> "" then
		return true
	else
	
		createDialog("Invalid Input", "Please enter a valid server address.", "Back", true)
	
		return false
	end if
	
End Function

Function OnPortTextValueEntered(value) As Boolean

	if type(firstOf(value, "").toint()) = "Integer" then
		return true
	else
	
		createDialog("Invalid Input", "Please enter a valid port.", "Back", true)
	
		return false
	end if
	
End Function

Sub onServerConfigurationUserInput(value, screen)

	Debug ("onServerConfigurationUserInput - " + screen.inputType)
	
    if screen.inputType = "port"
	
		portNumber = value
		serverAddress = screen.ipAddress

		' If they filled them both out, success, otherwise they cancelled
		if portNumber <> "" and portNumber <> invalid
			serverAddress = serverAddress + ":" + portNumber
		end if

		onServerAddressDiscovered(GetViewController(), serverAddress)
	end if
	
End Sub


'******************************************************
' onServerAddressDiscovered
'******************************************************

Sub onServerAddressDiscovered(viewController as Object, serverAddress As String) 

	facade = CreateObject("roOneLineDialog")
	facade.SetTitle("Please wait...")
	facade.ShowBusyAnimation()
	facade.Show()
                    
	' Check Server Connection
    result = ConnectionManager().connectToServer(serverAddress)

	facade.Close()
	
    if result.State = "Unavailable"
		createDialog("Unable To Connect", "We were unable to connect to this server. Please make sure it is running and try again.", "Back", true)
        return 
    end if
	
	navigateFromConnectionResult(result)
	
End Sub

'**********************************************************
'** Create Server Screen
'**********************************************************

Sub showServerFoundScreen(viewController as Object, serverLocationInfo As Object)

	screen = createServerFoundScreen(viewController, serverLocationInfo)
	viewController.InitializeOtherScreen(screen, ["Server Found"])
	screen.Show()

End Sub

Function createServerFoundScreen(viewController as Object, serverLocationInfo As Object)

    header = "Server Found"
    paragraphs = []
    paragraphs.Push("We were able to find a local server running on your network at the following address:")
    paragraphs.Push("")
    paragraphs.Push(serverLocationInfo.Address)

    screen = createParagraphScreen(header, paragraphs, viewController)
    screen.ScreenName = "ServerFound"
	
    screen.SetButton("1", "Continue")
	
	screen.HandleButton = serverFoundHandleButton
	screen.serverInfo = serverLocationInfo
	
	return screen
End Function

Function serverFoundHandleButton(command, data) As Boolean
  
  if command = "1" then
    handled = true

    m.ViewController.PopScreen(m)

	' Show Server Configuration Screen
	onServerAddressDiscovered(m.ViewController, m.serverInfo.Address)
	return false
	
  end if

  return true
End Function