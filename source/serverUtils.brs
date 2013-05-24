'**********************************************************
'**  Media Browser Roku Client - MB Server Utils
'**********************************************************


'******************************************************
' Get the Base url of the MB server
'******************************************************

Function GetServerBaseUrl()
    return "http://" + m.serverURL + "/mediabrowser"
End Function


'******************************************************
' Checks the MB Server Status
'******************************************************

Function GetServerStatus(refresh=invalid) As Integer

    ' If refreshing, ignore Memory And registry
    If refresh<>invalid
        If FindServer()<>0
            ' FindServer() sets it To memory, Save To registry
            RegWrite("serverURL", m.serverURL)
            Return 1
        Else
            ' No serverURL discovered
            Return -1
        End If
    End If
    
    ' Get Server URL
    If m.serverURL<>"" And m.serverURL<>invalid
        ' Do nothing, already In memory
    Else If RegRead("serverURL")<>invalid
        m.serverURL = RegRead("serverURL")
    Else If FindServer()<>0
        ' FindServer() sets it To memory, Save To registry
        RegWrite("serverURL", m.serverURL)
        Return 1
    Else
        ' No serverURL Set Or discovered
        Return -1
    End If

    ' If getting Server URL From Memory Or registry, ping Server To make sure it Is alive
    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/System/Info")

    if (request.AsyncGetToString())
        while (true)
            msg = wait(0, request.GetPort())
            if (type(msg) = "roUrlEvent")
                code = msg.GetResponseCode()

                if (code = 200)
                    ' Server Is Alive
                    Return 1
                Else
                    Return 0
                End if
            else if (event = invalid)
                request.AsyncCancel()
            endif
        end while
    endif

    Print "Something unexpected went wrong checking Server status"
    Return 0
End Function


'******************************************************
' Finds the MB Server trhough UDP
'******************************************************

Function FindServer() As Integer
    msgPort = CreateObject("roMessagePort")

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

    udp.setMessagePort(msgPort) 'notifications for udp come to msgPort

    udp.sendStr(networkMessage) ' Send message

    continue = udp.eOK()
    while continue
        event = wait(500, msgPort)
        If type(event)="roSocketEvent"
            If event.getSocketID()=udp.getID()
                If udp.isReadable()
                    returnMessage = udp.receiveStr(512) ' max 512 characters
                    udp.close()
                    token = returnMessage.tokenize("|")
                    m.serverURL = token[1] ' Set it To Memory
                    Return 1
                End If
            End If
        Else If event=invalid
            udp.close()
            Return 0
        End If
    End While

    Return 0
End Function


'******************************************************
' Checks the User Password with SHA1 Encoded Password
'******************************************************

Function CheckUserPassword(userId As String, passwordText As String) As Boolean
    ba = CreateObject("roByteArray")
    ba.FromAsciiString(passwordText)

    digest = CreateObject("roEVPDigest")
    digest.Setup("sha1")
    sha1Password = digest.Process(ba)

    request = CreateURLTransferObject(GetServerBaseUrl() + "/Users/" + userId + "/Authenticate")
    
    If (request.AsyncPostFromString("Password=" + sha1Password))
        while (true)
            msg = wait(0, request.GetPort())

            if (type(msg) = "roUrlEvent")
                code = msg.GetResponseCode()

                If (code = 200)
                    Return true
                Else
                    Return false
                End if
            else if (event = invalid)
                request.AsyncCancel()
                exit while
            endif
        end while
    End If

    Return false
End Function


















' UDP 2-way peer-to-peer asynchronous comm on port 54321
' periodically sends out a message to a specific address and port
' prints any message it receives 
Function UDPPeer()
    msgPort = CreateObject("roMessagePort")

    ssdpAddress = "250.255.255.239"
    ssdpPort = 7359

    localAddr = CreateObject("roSocketAddress")
    localAddr.setAddress("0.0.0.0")
    localAddr.setPort(ssdpPort)

    remoteAddr = CreateObject("roSocketAddress")
    remoteAddr.setAddress("192.168.1.255") ' Can only Do limited broadcast To LAN.
    remoteAddr.setPort(ssdpPort)

    udp = CreateObject("roDatagramSocket")
    'udp.setAddress(localAddr) ' bind to all host addresses on port 7359
    udp.setSendToAddress(remoteAddr) ' peer IP and port
    'udp.setMulticastTTL(1)
    udp.setBroadcast(true)
    udp.notifyReadable(true) 
    'udp.joinGroup(remoteAddr)

    udp.setMessagePort(msgPort) 'notifications for udp come to msgPort


'    udp = CreateObject("roDatagramSocket")
'    udp.setMessagePort(msgPort) 'notifications for udp come to msgPort

'    addr = CreateObject("roSocketAddress")
'    addr.setPort(7359)
    'addr.setAddress("255.255.255.255")

 '   udp.setAddress(addr) ' bind to all host addresses on port 7359
  '  addr.SetHostName("255.255.255.255")

  '  udp.setSendToAddress(addr) ' peer IP and port
  '  udp.notifyReadable(true) 
  '  udp.setMulticastTTL(1)

    timeout = 1 * 10 * 1000 ' ten seconds in milliseconds

    message = "who is MediaBrowserServer?"
    udp.sendStr(message) ' Send message

    continue = udp.eOK()
    while continue
        event = wait(timeout, msgPort)
        If type(event)="roSocketEvent"
            If event.getSocketID()=udp.getID()
                If udp.isReadable()
                    returnMessage = udp.receiveStr(512) ' max 512 characters
                    print "Received message: '"; returnMessage; "'"
                End If
            End If
        Else If event=invalid
            Return invalid
            udp.sendStr(message) ' periodic send
        End If
    End While

    udp.close() ' would happen automatically as udp goes out of scope
End Function
