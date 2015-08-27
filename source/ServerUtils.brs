'******************************************************
' Get the Base Url of the MB Server
'******************************************************

Function GetServerBaseUrl(baseUrl = "")

	if baseUrl = "" then baseUrl = GetViewController().serverUrl
	
	if Instr(0, baseUrl, "://") = 0 then 
		baseUrl = "http://" + baseUrl
	end if
	
    return baseUrl + "/emby"
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
    broadcastMessage = "who is EmbyServer?"
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
                return ParseJSON(receivedMessage)
            else if msg = invalid
                Debug("Cancel UDP Broadcast")
                udp.close()
                return invalid
            end if
        end while

    end if

    return invalid
End Function

function findServers() as Object

	server = scanLocalNetwork()
	
	servers = CreateObject("roArray", 10, true)
	
	if server <> invalid then
	
		servers.push({
		
			LocalAddress: server.Address,
			Name: server.Name,
			Id: server.Id
		})
		
	end if
	
	return servers

End function

'******************************************************
' Authenticates a user by name
'******************************************************

Function authenticateUser(serverUrl As String, userText As String, passwordText As String) As Object

    if passwordText <> "" then
        ba = CreateObject("roByteArray")
        ba.FromAsciiString(passwordText)

        digest = CreateObject("roEVPDigest")
        digest.Setup("sha1")
        sha1Password = digest.Process(ba)
    else
        sha1Password = "da39a3ee5e6b4b0d3255bfef95601890afd80709"
    end if

    ' URL
    url = GetServerBaseUrl(serverUrl) + "/Users/AuthenticateByName?format=json"

    ' Prepare Request
    request = HttpRequest(url)
    request.AddAuthorization()

    ' Execute Request
    response = request.PostFromStringWithTimeout("Username=" + HttpEncode(userText) + "&Password=" + sha1Password, 5)
    if response <> invalid
        metaData = ParseJSON(response)

        if metaData = invalid
            Debug("Error parsing authentication response.")
            return invalid
        end if

        return metaData
    else
        Debug("Invalid username or password.")
    end if

    return invalid
End Function

'******************************************************
' Post capabilities
'******************************************************

Function postCapabilities() As Boolean

	Debug("Posting capabilities")
	
    url = GetServerBaseUrl() + "/Sessions/Capabilities/Full"
	
	caps = getCapabilities()

	' Prepare Request
    request = HttpRequest(url)
    request.AddAuthorization()
	request.ContentType("json")

	json = SimpleJSONBuilder(caps)
    response = request.PostFromStringWithTimeout(json, 5)
	
    if response <> invalid
        return true
    else
        Debug("Failed to Post Capabilities")
    end if

    return false
End Function


'******************************************************
' normalizeJson
'******************************************************
Function normalizeJson(json As String) as String

	' Fixes bug within BRS Json Parser
	regex         = CreateObject("roRegex", Chr(34) + "(RunTimeTicks|PlaybackPositionTicks|StartPositionTicks)" + Chr(34) + ":(-?[0-9]+)(}?]?),", "i")
	json = regex.ReplaceAll(json, Chr(34) + "\1" + Chr(34) + ":" + Chr(34) + "\2" + Chr(34) + "\3,")

	return json
	
End Function

Function getInstalledPlugins() As Object

    ' URL
    url = GetServerBaseUrl() + "/Plugins"

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

		fixedResponse = normalizeJson(response)

        return ParseJSON(fixedResponse)
		
    end if

    return invalid
End Function