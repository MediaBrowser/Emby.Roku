'**********************************************************
'**  Media Browser Roku Client - Server Utils
'**********************************************************


'******************************************************
' Get the Base Url of the MB Server
'******************************************************

Function GetServerBaseUrl()
    return "http://" + m.serverURL + "/mediabrowser"
End Function


'******************************************************
' Get the Server Status (old)
'******************************************************

Function getServerStatus(refresh = invalid) As Boolean

    ' If refreshing, ignore Memory And registry
    if refresh <> invalid
        if findLocalServer()
            ' findLocalServer() sets it to memory, save to registry
            RegWrite("serverURL", m.serverURL)
            return true
        else
            ' No serverURL discovered
            return false
        end if
    end if
    
    ' Get Server URL
    if m.serverURL <> "" And m.serverURL <> invalid
        ' Do nothing, already in memory
        
    else if RegRead("serverURL") <> invalid
        m.serverURL = RegRead("serverURL")

    else if findLocalServer()
        ' findLocalServer() sets it to memory, save to registry
        RegWrite("serverURL", m.serverURL)
        return true

    else
        ' No serverURL set or discovered
        return false

    end if

    ' URL
    url = GetServerBaseUrl() + "/System/Info"

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid
        return true ' Server is Awake
    else
        Debug("Server is not currently awake")
    end if

    return false
End Function


'******************************************************
' Attempts to find local MB Server through Udp (old)
'******************************************************

Function findLocalServer() As Boolean
    port = CreateObject("roMessagePort")

    networkMessage = "who is MediaBrowserServer?"
    networkAddress = "192.168.1.255"  ' Can only Do limited broadcast To LAN.
    networkPort = 7359

    remoteAddr = CreateObject("roSocketAddress")
    remoteAddr.setAddress(networkAddress)
    remoteAddr.setPort(networkPort)

    udp = CreateObject("roDatagramSocket")
    udp.setSendToAddress(remoteAddr) ' peer IP and port
    udp.setBroadcast(true)
    udp.notifyReadable(true) 

    udp.setMessagePort(port) 'notifications for udp come to message port

    udp.sendStr(networkMessage) ' Send message

    continue = udp.eOK()
    while continue
        event = wait(500, port)
        if type(event) = "roSocketEvent"
            if event.getSocketID() = udp.getID()
                if udp.isReadable()
                    returnMessage = udp.receiveStr(512) ' max 512 characters
                    udp.close()
                    token = returnMessage.tokenize("|")
                    m.serverURL = token[1] ' Set it To Memory
                    return true
                end if
            end if
        else if event = invalid
            udp.close()
            return false
        end if
    end while

    return false
End Function


'******************************************************
' Source: Plex Roku Client
'         https://github.com/plexinc/roku-client-public
' Return the first IP address of the Roku device
'******************************************************

Function GetFirstIPAddress()
    device = CreateObject("roDeviceInfo")
    addrs = device.GetIPAddrs()
    addrs.Reset()
    if addrs.IsNext() then
        return addrs[addrs.Next()]
    else
        return invalid
    end if
End Function


'******************************************************
' Source: Plex Roku Client
'         https://github.com/plexinc/roku-client-public
' Scan Network to find local MB Server through UDP
'******************************************************

Function scanLocalNetwork() As Dynamic

    ' Setup Broadcast message and port
    broadcastMessage = "who is MediaBrowserServer?"
    broadcastPort = 7359

    success = false
    attempts = 0

    ' Setup multicast fallback
    multicast = "239.0.0.250"
    ip = multicast

    subnetRegex = CreateObject("roRegex", "((\d+)\.(\d+)\.(\d+)\.)(\d+)", "")
    addr = GetFirstIPAddress()
    if addr <> invalid then
        match = subnetRegex.Match(addr)
        if match.Count() > 0 then
            ip = match[1] + "255"
            Debug("Using broadcast address " + ip)
        end if
    end if

    ' Attempt multiple times in case sending message fails
    while attempts < 10
        ' Setup UDP
        udp  = CreateObject("roDatagramSocket")
        port = CreateObject("roMessagePort")
        udp.setMessagePort(port)
        udp.setBroadcast(true)

        ' Loop multiple times to make send to address stick
        for i = 0 to 5
            addr = CreateObject("roSocketAddress")
            addr.setHostName(ip)
            addr.setPort(broadcastPort)
            udp.setSendToAddress(addr)

            sendTo = udp.getSendToAddress()
            if sendTo <> invalid
                sendToStr = tostr(sendTo.getAddress())
                addrStr = tostr(addr.getAddress())
                Debug("Send To Address: " + sendToStr + " / " + addrStr)
                if sendToStr = addrStr
                    exit for
                end If
            end if

            Debug("Failed To Set Send To Address")
        end for

        udp.notifyReadable(true) 

        ' Send Broadcast Message
        bytes = udp.sendStr(broadcastMessage)

        if bytes > 0
            success = udp.eOK()
        else
            success = false
            if bytes = 0
                Debug("Falling back to multicast address")
                ip = multicast
                try = 0
            end if
        end if

        if success
            exit while
        else if attempts = 9 AND ip <> multicast then
            Debug("Falling back to multicast address")
            ip = multicast
            attempts = 0
        else
            sleep(500)
            Debug("Retrying, errno " + tostr(udp.status()))
            attempts = attempts + 1
        end If
    end while

    ' Only Do Event Loop If Successful Message Sent
    if success
        while true
            msg = wait(5000, port)

            if type(msg) = "roSocketEvent" And msg.getSocketID() = udp.getID() And udp.isReadable()
                receivedMessage = udp.receiveStr(512) ' max 512 characters
                Debug("Received Message: " + receivedMessage)
                udp.close()
                token = receivedMessage.tokenize("|")
                return token[1]
            else if msg = invalid
                Debug("Cancel UDP Broadcast")
                udp.close()
                return invalid
            end if
        end while

    end if

    return invalid
End Function


'******************************************************
' Get Server Info
'******************************************************

Function getServerInfo(baseUrl = "") As Object
    ' URL
    if baseUrl <> ""
        url = "http://" + baseUrl + "/mediabrowser/System/Info"
    else
        url = GetServerBaseUrl() + "/System/Info"
    end if
    
    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid
        metaData = ParseJSON(response)

        if metaData = invalid
            Debug("Error Parsing Server Info")
            return invalid
        end if

        return metaData
    else
        Debug("Failed to get Server Info")
    end if

    return invalid
End Function


'******************************************************
' Post Server Restart
'******************************************************

Function postServerRestart() As Boolean
    ' URL
    url = GetServerBaseUrl() + "/System/Restart"

    ' Prepare Request
    request = HttpRequest(url)

    ' Execute Request
    response = request.PostFromStringWithTimeout("", 5)
    if response <> invalid
        return true
    else
        Debug("Failed to Post Server Restart")
    end if

    return false
End Function


'******************************************************
' Checks the User Password with SHA1 Encoded Password
'******************************************************

Function checkUserPassword(userId As String, passwordText As String) As Boolean
    ba = CreateObject("roByteArray")
    ba.FromAsciiString(passwordText)

    digest = CreateObject("roEVPDigest")
    digest.Setup("sha1")
    sha1Password = digest.Process(ba)

    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(userId) + "/Authenticate"

    ' Prepare Request
    request = HttpRequest(url)

    ' Execute Request
    response = request.PostFromStringWithTimeout("Password=" + sha1Password, 5)
    if response <> invalid
        return true
    else
        Debug("Failed to Check Password for User or Password did not match")
    end if

    return false
End Function
