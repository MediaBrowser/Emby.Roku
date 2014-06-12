'*****************************************************************
'**  Media Browser Roku Client - Server Screens
'*****************************************************************


'**********************************************************
'** Server Statup Checks
'** 0 = First Run, 1 = Server List, 2 = Connect to Server
'**********************************************************

Function serverStartUp() As Integer

    ' Get Active Server
    activeServer = RegRead("serverActive")
	
    ' If active server, check to see if it is currently running
    if activeServer <> invalid And activeServer <> ""
        activeServer = (activeServer).ToInt()
        serverList   = getServerList(activeServer)

        if serverList <> invalid
            server = serverList[0]

            ' Check Server Connection
            serverInfo = getServerInfo(server.address)

            if serverInfo = invalid
                createDialog("Unable To Connect", "We were unable to connect to that media browser server. Please make sure your server is running.", "Back")
                return 1
            end if

            ' Setup Server URL
            m.serverURL = server.address
			
			postCapabilities()

            return 2

        else
            return 1

        end if

    else
        ' Check for at least one server
        serverList = getServerList()
		
        if serverList.Count() > 0
            return 1
        else
            return 0
        end if

    end if

    return 0
End Function


'**********************************************************
'** Create Server Screen
'**********************************************************

Function createServerFirstRunSetupScreen(viewController as Object)

    header = "Welcome"
    paragraphs = []
    paragraphs.Push("To begin, please make sure you media browser server is currently running.")
    paragraphs.Push("Media Browser Server is available for download at http://www.mediabrowser.tv")
    paragraphs.Push("Below you may select to scan the network and attempt to automatically find your server or manually enter it's information.")

    screen = createParagraphScreen(header, paragraphs, viewController)
    screen.ScreenName = "FirstRun"
	
    screen.SetButton("1", "Scan Network")
    screen.SetButton("2", "Manually Add Server")

    ' Add exit button for legacy devices
    if getGlobalVar("legacyDevice")
        screen.SetButton("3", "Exit Channel")
    end if
	
	screen.HandleButton = handleFirstRunSetupScreenButton
	
	return screen

End Function

Function handleFirstRunSetupScreenButton(command, data) As Boolean

    if command = "1"
	
        facade = CreateObject("roOneLineDialog")
		facade.SetTitle("Please wait...")
		facade.ShowBusyAnimation()
		facade.Show()

		' Scan Network
        results = scanLocalNetwork()

        facade.Close()

        if results <> invalid

            ' Show Found Server Screen
            showServerFoundScreen(m.ViewController, results)
			return false
        else
            createDialog("No Server Found", "We were unable to find a server running on your local network. Please make sure your server is running or if you continue to have problems, manually add the server.", "Back", true)
			return false
        end if

    else if command = "2"

        createServerConfigurationScreen(m)
		return false
		
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

    ' Get Server List
    serverList = getServerList()

    ' Create List Screen
    screen = CreateListScreen(viewController)
	
    ' Setup Array
    contentList = CreateObject("roArray", 3, true)

    ' Build Server List
    for i = 0 to serverList.Count()-1
        entry = {
            Title: serverList[i].name,
            ShortDescriptionLine1: serverList[i].address,
            Action: "select",
            Id: serverList[i].id,
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-server-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-server-lg.png")
        }

        contentList.push( entry )
    end for

    ' Check For Open Save Slots
    if serverList.Count() < 3
        entry = {
            Title: ">> Add Server",
            ShortDescriptionLine1: "Add a new server.",
            ShortDescriptionLine2: "You may have up to three.",
            Action: "add",
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
                    
					RegWrite("serverActive", itostr(serverId))
					
					' Make them sign in again
					RegDelete("userId")
					
					viewController.ShowInitialScreen()

                else if selection = "2"
				
                    selection = createServerRemoveDialog()
                    if selection = "1"
					
                        removeServer(serverId)
                        Debug("Remove Server")
						
						viewController.ShowInitialScreen()
						
                    end if
                end if

            else if action = "add"

                selection = createServerAddDialog()
				
                if selection = "1"
				
                    facade = CreateObject("roOneLineDialog")
					facade.SetTitle("Please wait...")
					facade.ShowBusyAnimation()
					facade.Show()

					' Scan Network
                    results = scanLocalNetwork()

                    facade.Close()

                    if results <> invalid
                        ' Show Found Server Screen
                        showServerFoundScreen(viewController, results)
                    else
                        createDialog("No Server Found", "We were unable to find a server running on your local network. Please make sure your server is running or if you continue to have problems, manually add the server.", "Back")
                    end if

                else if selection = "2"

                    ' Add Server Manually
                    createServerConfigurationScreen(m)

                end if

            end if

        end if

    end if

	return handled or m.baseHandleMessage(msg)
End Function


'******************************************************
' Show Manual Server Configuration Keyboard Screens
'******************************************************

Sub createServerConfigurationScreen(parentScreen as Object) 

	screen = GetViewController().CreateTextInputScreen("Enter Server Address", "Server IP Address (ex. 192.168.1.100)", ["Server Setup"], "", false)
	screen.ValidateText = OnRequiredTextValueEntered
	screen.Show(true)

	value = screen.Text
    
	portScreen = GetViewController().CreateTextInputScreen("Enter Server Port", "Server Port #", ["Server Setup"], "8096", false)
	portScreen.ValidateText = OnRequiredTextValueEntered
	portScreen.ipAddress = value
	
	parentScreen.OnUserInput = onServerConfigurationUserInput
	portScreen.Listener = parentScreen
	
	portScreen.inputType = "port"
	portScreen.Show()

End Sub

Function OnRequiredTextValueEntered(value) As Boolean

	return value <> invalid and value <> ""
	
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

	' Check Server Connection
    serverInfo = getServerInfo(serverAddress)

    if serverInfo = invalid
        createDialog("Unable To Connect", "We were unable to connect to this server. Please make sure it is running before attempting to add it to the server list.", "Back", true)
        return 
    end if

    serverName = serverInfo.ServerName

    ' Clean Server Name
    regex      = CreateObject("roRegex", "[^a-z0-9 -]", "i")
    serverName = regex.ReplaceAll(serverName, "")

    ' Save Server Information
    saveServerInfo(serverName, serverAddress, serverInfo)

    viewController.ShowInitialScreen()
End Sub

'**********************************************************
'** Create Server Screen
'**********************************************************

Sub showServerFoundScreen(viewController as Object, serverAddress As String)

	screen = createServerFoundScreen(viewController, serverAddress)
	viewController.InitializeOtherScreen(screen, ["Server Found"])
	screen.Show()

End Sub

Function createServerFoundScreen(viewController as Object, serverAddress As String)

    header = "Server Found"
    paragraphs = []
    paragraphs.Push("We were able to find a local server running on your network at the following address:")
    paragraphs.Push("")
    paragraphs.Push(serverAddress)

    screen = createParagraphScreen(header, paragraphs, viewController)
    screen.ScreenName = "ServerFound"
	
    screen.SetButton("1", "Continue")

    ' Add exit button for legacy devices
    if getGlobalVar("legacyDevice")
        screen.SetButton("3", "Exit Channel")
    end if
	
	screen.HandleButton = serverFoundHandleButton
	screen.serverAddress = serverAddress
	
	return screen
End Function

Function serverFoundHandleButton(command, data) As Boolean
  
  if command = "1" then
    handled = true

    m.ViewController.PopScreen(m)

	' Show Server Configuration Screen
	onServerAddressDiscovered(m.ViewController, m.serverAddress)
	return false
	
  end if

  return true
End Function

'******************************************************
' Save Server Information
'******************************************************

Sub saveServerInfo(serverName As String, serverAddress As String, serverInfo As Object)

    ' Print Debug Information
    Debug("Server Name: " + serverName)
    Debug("Server Address: " + serverAddress)
    Debug("Mac Address: " + serverInfo.MacAddress)

    ' Format Server Info (name, address, mac)
    serverItem = serverName + "|" + serverAddress + "|"
    
    ' Check for mac address
    if serverInfo.MacAddress <> ""
        serverItem = serverItem + serverInfo.MacAddress
    end if

    ' Find first empty slot and save
    if RegRead("serverInfo1") = invalid Or RegRead("serverInfo1") = ""
        RegWrite("serverInfo1", serverItem)

    else if RegRead("serverInfo2") = invalid Or RegRead("serverInfo2") = ""
        RegWrite("serverInfo2", serverItem)

    else
        RegWrite("serverInfo3", serverItem)

    end if

    return
End Sub


'******************************************************
' Remove Server
'******************************************************

Function removeServer(serverId As Integer) As Boolean
    ' Remove the saved server info
    if serverId = 1
        RegDelete("serverInfo1")
    else if serverId = 2
        RegDelete("serverInfo2")
    else if serverId = 3
        RegDelete("serverInfo3")
    else
        return false
    end if

    return true
End Function


'******************************************************
' Get Server List
'******************************************************

Function getServerList(activeServer = 0 As Integer) As Object

    ' Setup Server List
    serverList = CreateObject("roArray", 3, true)

    ' Find specific server or return server list
    if activeServer = 1
        serverString = RegRead("serverInfo1")

        if serverString <> invalid
            serverInfo = serverString.tokenize("|")
            serverData = {}
            serverData.name       = serverInfo[0]
            serverData.address    = serverInfo[1]
            serverData.macAddress = serverInfo[2]
            serverData.id         = 1

            serverList.push( serverData )
        else
            return invalid
        end if

    else if activeServer = 2
        serverString = RegRead("serverInfo2")

        if serverString <> invalid
            serverInfo = serverString.tokenize("|")
            serverData = {}
            serverData.name       = serverInfo[0]
            serverData.address    = serverInfo[1]
            serverData.macAddress = serverInfo[2]
            serverData.id         = 2

            serverList.push( serverData )

        else
            return invalid
        end if

    else if activeServer = 3
        serverString = RegRead("serverInfo3")

        if serverString <> invalid
            serverInfo = serverString.tokenize("|")
            serverData = {}
            serverData.name       = serverInfo[0]
            serverData.address    = serverInfo[1]
            serverData.macAddress = serverInfo[2]
            serverData.id         = 3

            serverList.push( serverData )

        else
            return invalid
        end if

    else

        ' Build Server List
        serverString1 = RegRead("serverInfo1")
        serverString2 = RegRead("serverInfo2")
        serverString3 = RegRead("serverInfo3")

        if serverString1 <> invalid
            serverInfo = serverString1.tokenize("|")
            serverData = {}
            serverData.name       = serverInfo[0]
            serverData.address    = serverInfo[1]
            serverData.macAddress = serverInfo[2]
            serverData.id         = 1

            serverList.push( serverData )
        end if

        if serverString2 <> invalid
            serverInfo = serverString2.tokenize("|")
            serverData = {}
            serverData.name       = serverInfo[0]
            serverData.address    = serverInfo[1]
            serverData.macAddress = serverInfo[2]
            serverData.id         = 2

            serverList.push( serverData )
        end if

        if serverString3 <> invalid
            serverInfo = serverString3.tokenize("|")
            serverData = {}
            serverData.name       = serverInfo[0]
            serverData.address    = serverInfo[1]
            serverData.macAddress = serverInfo[2]
            serverData.id         = 3

            serverList.push( serverData )
        end if

    end if

    return serverList
End Function
