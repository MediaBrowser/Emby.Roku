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
' Get the Server Status
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
' Attempts to find local MB Server through UDP
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
' Checks the User Password with SHA1 Encoded Password
'******************************************************

Function checkUserPassword(userId As String, passwordText As String) As Boolean
    ba = CreateObject("roByteArray")
    ba.FromAsciiString(passwordText)

    digest = CreateObject("roEVPDigest")
    digest.Setup("sha1")
    sha1Password = digest.Process(ba)

    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Authenticate"

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
