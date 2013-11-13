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

Function createServerFirstRunSetupScreen()

    ' Create Paragraph Screen
    screen = CreateParagraphScreen("Server Setup")

    ' Set Content
    screen.AddHeaderText("Welcome")
    screen.AddParagraph("To begin, please make sure you media browser server is currently running.")
    screen.AddParagraph("Below you may select to scan the network and attempt to auto find the running server or to manually add one.")
    screen.AddButton(1, "Scan Network")
    screen.AddButton(2, "Manually Add Server")

    ' Exit Button For Legacy Devices
    if getGlobalVar("legacyDevice")
        screen.AddButton(3, "Exit Channel")
    end if

    ' Show Screen
    screen.Show() 

    while true
        msg = wait(0, screen.Port)

        if type(msg) = "roParagraphScreenEvent"

            if msg.isButtonPressed()
                if msg.GetIndex() = 1
                    ' Create Waiting Dialog
                    dialog = createWaitingDialog("Please Wait...", "Please wait while we scan your network for a running media browser server.")

                    ' Scan Network
                    results = scanLocalNetwork()

                    ' Close Dialog
                    dialog.Close()

                    if results <> invalid
                        serverSaved = createServerConfigurationScreen(results)
                        if serverSaved
                            Debug("Saved Server - Close Server Setup Screen")
                            return true
                        end if
                    else
                        createDialog("No Server Found", "We were unable to find a server running on your local network. Please make sure your server is running or if you continue to have problems, manually add the server.", "Back")
                    end if
                else if msg.GetIndex() = 2
                    serverSaved = createServerConfigurationScreen("")
                    if serverSaved
                        Debug("Saved Server - Close Server Setup Screen")
                        return true
                    end if
                else
                    Debug("Close Server Setup Screen")
                    return false
                end if
            else if msg.isScreenClosed()
                Debug("Close Server Setup Screen")
                return false
            end if

        end if
    end while

    return false
End Function


'**********************************************************
'** Create Server ListScreen
'**********************************************************

Function createServerListScreen()

    ' Create List Screen
    screen = CreateListScreen("", "Server List")

    ' Setup Array
    contentList = CreateObject("roArray", 3, true)

    ' Get Server List
    serverList = getServerList()

    ' Build Server List
    for i = 0 to serverList.Count()-1
        entry = {
            Title: serverList[i].name,
            ShortDescriptionLine1: serverList[i].address,
            Action: "select",
            Id: serverList[i].id,
            HDBackgroundImageUrl: "pkg://images/hd-server-lg.png",
            SDBackgroundImageUrl: "pkg://images/sd-server-lg.png"
        }

        contentList.push( entry )
    end for

    ' Check For Open Save Slots
    if serverList.Count() < 3
        entry = {
            Title: ">> Add Server",
            ShortDescriptionLine1: "Add a new server.",
            ShortDescriptionLine2: "You may have up to 3.",
            Action: "add",
            HDBackgroundImageUrl: "pkg://images/hd-server-lg.png",
            SDBackgroundImageUrl: "pkg://images/sd-server-lg.png"
        }

        contentList.push( entry )
    end if

    ' Back Button For Legacy Devices
    if getGlobalVar("legacyDevice")
        backButton = {
            Title: ">> Exit Channel <<",
            Action: "exit"
        }

        contentList.Push( backButton )
    end if

    ' Set Header
    screen.SetHeader("Select a Server")

    ' Set Content
    screen.SetContent(contentList)

    ' Show Screen
    screen.Show() 

    while true
        msg = wait(0, screen.Port)

        if type(msg) = "roListScreenEvent"

            if msg.isListItemFocused()

            else if msg.isListItemSelected()
                ' Get Action
                action = contentList[msg.GetIndex()].Action

                if action = "select"
                    serverId  = contentList[msg.GetIndex()].Id
                    selection = createServerSelectionDialog()

                    if selection = 1
                        return serverId
                    else if selection = 2
                        selection = createServerRemoveDialog()
                        if selection = 1
                            removeServer(serverId)
                            Debug("Remove Server")
                            return 0
                        end if
                    end if

                else if action = "add"
                    selection = createServerAddDialog()
                    if selection = 1
                        ' Create Waiting Dialog
                        dialog = createWaitingDialog("Please Wait...", "Please wait while we scan your network for a running media browser server.")

                        ' Scan Network
                        results = scanLocalNetwork()

                        ' Close Dialog
                        dialog.Close()

                        if results <> invalid
                            serverSaved = createServerConfigurationScreen(results)
                            if serverSaved
                                Debug("Saved Server - Close Server List")
                                return 0
                            end if
                        else
                            createDialog("No Server Found", "We were unable to find a server running on your local network. Please make sure your server is running or if you continue to have problems, manually add the server.", "Back")
                        end if

                    else if selection = 2
                        ' Add Server Manually
                        serverSaved = createServerConfigurationScreen("")
                        if serverSaved
                            Debug("Saved Server - Close Server List")
                            return 0
                        end if

                    end if

                else if action = "exit"
                    Debug("Close Server List")
                    return -1
                end if

            else if msg.isScreenClosed()
                Debug("Close Server List")
                return -1
            end if

        end if
    end while

    return false
End Function


'******************************************************
' Show Manual Server Configuration Keyboard Screens
'******************************************************

Function createServerConfigurationScreen(serverAddress As String) As Boolean

    ' Show Keyboard for Server Name
    serverName = createKeyboardScreen("Server Setup", "Display Name (ex. Home)")

    ' Check Server Name is filled out
    if serverName = ""
        return false
    end if

    ' Show Manual Server Entry Keyboard Screens
    if serverAddress = ""

        ' Show Keyboard for IP Address
        ipAddress = createKeyboardScreen("Server Setup", "Server IP Address (ex. 192.168.1.100)")

        if ipAddress <> ""
            portNumber = createKeyboardScreen("Server Setup", "Server Port #", "8096")
        end if

        ' If they filled them both out, success, otherwise they cancelled
        if ipAddress <> "" and portNumber <> ""
            serverAddress = ipAddress + ":" + portNumber
        else
            return false
        end if

    end if

    ' Check Server Connection
    serverInfo = getServerInfo(serverAddress)

    if serverInfo = invalid
        createDialog("Unable To Connect", "We were unable to connect to that media browser server. Please make sure your server is running before attempting to add it to the server list.", "Back")
        return false
    end if

    ' Show Auto Connect Option
    'autoConnect = createAutoConnectScreen()

    ' Clean Server Name
    regex      = CreateObject("roRegex", "[^a-z0-9 -]", "i")
    serverName = regex.ReplaceAll(serverName, "")

    ' Save Server Information
    savedServer = saveServerInfo(serverName, serverAddress, serverInfo)

    if Not savedServer
        createDialog("Unable To Save Server", "We were unable to save that media browser server to the list. Please try again.", "Back")
        return false
    end if

    return true
End Function


'******************************************************
' Create Auto Connect Screen
'******************************************************

Function createAutoConnectScreen() As Integer

    ' Create Paragraph Screen
    screen = CreateParagraphScreen("Server Setup")

    ' Set Content
    screen.AddHeaderText("Auto Connect")
    screen.AddParagraph("Do you wish to automatically connect to this server at channel startup?")
    screen.AddButton(1, "Yes")
    screen.AddButton(0, "No")

    ' Show Screen
    screen.Show() 

    while true
        msg = wait(0, screen.Port)

        if type(msg) = "roParagraphScreenEvent"

            if msg.isButtonPressed()
                return msg.GetIndex()
            else if msg.isScreenClosed()
                return 0
            end if

        end if
    end while

    return 0
End Function


'******************************************************
' Save Server Information
'******************************************************

Function saveServerInfo(serverName As String, serverAddress As String, serverInfo As Object) As Boolean

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

    else if RegRead("serverInfo3") = invalid Or RegRead("serverInfo3") = ""
        RegWrite("serverInfo3", serverItem)

    else
        return false

    end if

    return true
End Function


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
