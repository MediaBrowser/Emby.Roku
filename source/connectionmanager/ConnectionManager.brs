Function ConnectionManager() As Object
    if m.ConnectionManager = invalid then
        
		obj = CreateObject("roAssociativeArray")
		
		obj.isLoggedIntoConnect = mgrIsLoggedIntoConnect
		obj.logout = mgrLogout
		obj.connectToServerInfo = mgrConnectToServerInfo
		obj.connectToServer = mgrConnectToServer
		
		obj.sendWolToAllServers = mgrSendWolToAllServers
		obj.sendWol = mgrSendWol
		obj.GetSavedServerList = mrgGetSavedServerList
		obj.DeleteServerData = mgrDeleteServerData
		obj.DeleteServer = mgrDeleteServer
		obj.GetServerData = mgrGetServerData
		obj.SetServerData = mgrSetServerData
		obj.connectInitial = mrgConnectInitial
		obj.getPinCreationHttpRequest = mgrGetPinCreationHttpRequest
		obj.getPinStatusHttpRequest = mgrGetPinStatusHttpRequest
		obj.getPinExchangeHttpRequest = mgrGetPinExchangeHttpRequest
		obj.setAppInfo = mgrSetAppInfo

        ' Singleton
        m.ConnectionManager = obj
    end if

    return m.ConnectionManager
End Function

function mrgConnectInitial() as Object

	servers = connectionManagerGetServers()
	
	return connectToServers(servers)

end function

function connectionManagerGetServers() as Object

	servers = findServers()	
	Debug ("Found " + tostr(servers.Count()) + " servers")
	
	for each server in servers
	
		ConnectionManager().SetServerData(server.Id, "Name", server.Name)
		ConnectionManager().SetServerData(server.Id, "LocalAddress", server.LocalAddress)
		
	end for
	
	ensureConnectUser()
	
	servers = getConnectServers()	
	Debug ("Connect returned " + tostr(servers.Count()) + " servers")
	
	for each server in servers
	
		ConnectionManager().SetServerData(server.SystemId, "Name", server.Name)
		
		if firstOf(server.LocalAddress, "") <> "" then  ConnectionManager().SetServerData(server.SystemId, "LocalAddress", server.LocalAddress)

		ConnectionManager().SetServerData(server.SystemId, "RemoteAddress", server.Url)
		
		ConnectionManager().SetServerData(server.SystemId, "ExchangeToken", server.AccessKey)
		ConnectionManager().SetServerData(server.SystemId, "UserType", firstOf(server.UserType, ""))
		
	end for
	
	servers = ConnectionManager().GetSavedServerList()
	
	RlMergeSort(servers, ServerComparator)
	
	Debug("connectionManagerGetServers returning " + tostr(servers.Count()) + " servers")
	
	return servers

end function

function ServerComparator(serverA as Dynamic, serverB as Dynamic) as Integer
    
	a = firstOf(serverA.LastAccess, "0").toInt()
	b = firstOf(serverB.LastAccess, "0").toInt()
	
	if a > b
        return -1
    else
        return 1
    end if
end function

function connectToServers(serverList as Object) as Object

	count = serverList.Count()
	
	Debug("connectToServers called with "+tostr(count)+" servers")
	
	if count = 1
		
		result = ConnectionManager().connectToServerInfo(serverList[0])
		
		if result.State = "Unavailable" then
			
			if result.ConnectUser = invalid then
				result.State = "ConnectSignIn"
			else
				result.State = "ServerSelection"
			end if
			
		end if
		
		return result
		
	end if
	
	firstServer = serverList[0]
	
	if firstServer <> invalid and firstOf(firstServer.AccessToken, "") <> "" and firstOf(firstServer.UserId, "") <> "" then
		
		result = ConnectionManager().connectToServerInfo(firstServer)
			
		if result.State = "SignedIn" then
			return result
		end if
			
	end if
	
	finalResult = {
		Servers: serverList,
		ConnectUser: getCurrentConnectUser()
	}
	
	if count = 0 and finalResult.ConnectUser = invalid then
		finalResult.State = "ConnectSignIn"
	else
		finalResult.State = "ServerSelection"
	end if
	
	return finalResult

End function

function mgrConnectToServer(url) as Object

	url = normalizeAddress(url)
	
	publicInfo = tryConnect(url, 20)
	
	if publicInfo = invalid then
		return {
			State: "Unavailable",
			ConnectUser: getCurrentConnectUser()
		}
	end if
	
	serverInfo = {
		Name: publicInfo.ServerName,
		Id: publicInfo.Id,
		LocalAddress: publicInfo.LocalAddress,
		RemoteAddress: publicInfo.WanAddress,
		ManualAddress: url,
		MacAddress: publicInfo.MacAddress,
		Local: "-1",
		LastConnectionMode: "Manual"
	}
	
	return ConnectionManager().connectToServerInfo(serverInfo)

End function

function mgrConnectToServerInfo(server) as Object

	result = {
		State: "Unavailable",
		ConnectionMode: "Manual",
		Servers: []
	}
	
	systemInfo = invalid 
	
	if systemInfo = invalid and firstOf(server.ManualAddress, "") <> "" and server.ManualAddress <> firstOf(server.LocalAddress, "") then
	
		systemInfo = tryConnect(server.ManualAddress, 20)
		
		if systemInfo <> invalid then result.ConnectionMode = "Manual"
	end if
	
	if systemInfo = invalid and firstOf(server.LocalAddress, "") <> "" then
		
		systemInfo = tryConnect(server.LocalAddress, 10)
		
		if systemInfo = invalid and firstOf(server.MacAddress, "") <> "" then
		
			m.sendWol(server.Id)
			
			sleep (10000)
			
			systemInfo = tryConnect(server.LocalAddress, 10)
			
		end if
	
		if systemInfo <> invalid then result.ConnectionMode = "Local"
	end if
	
	if systemInfo = invalid and firstOf(server.RemoteAddress, "") <> "" and server.RemoteAddress <> firstOf(server.ManualAddress, "") then
	
		systemInfo = tryConnect(server.RemoteAddress, 20)
		
		if systemInfo <> invalid then result.ConnectionMode = "Remote"
	end if
	
	if systemInfo = invalid then
		result.ConnectUser = getCurrentConnectUser()
		result.Servers.push(server)
		return result
	end if
	
	importSystemInfo(server, systemInfo)
	
	ensureConnectUser()
	addAuthenticationInfoFromConnect(server, result.ConnectionMode)
	
	if firstOf(server.AccessToken, "") <> "" and firstOf(server.UserId, "") <> "" then
		validateLocalAuthentication(server, result.ConnectionMode)
	end if
	
	if firstOf(server.AccessToken, "") = "" or firstOf(server.UserId, "") = "" then
		result.State = "ServerSignIn"
	else
		result.State = "SignedIn"
	end if
	
	m.SetServerData(server.Id, "LastAccess", tostr(CreateObject("roDateTime").AsSeconds()))
	
	if firstOf(server.LocalAddress, "") <> "" then
		m.SetServerData(server.Id, "LocalAddress", server.LocalAddress)
	end if	
	
	if firstOf(server.RemoteAddress, "") <> "" then
		m.SetServerData(server.Id, "RemoteAddress", server.RemoteAddress)
	end if
	
	if firstOf(server.ManualAddress, "") <> "" then
		m.SetServerData(server.Id, "ManualAddress", server.ManualAddress)
	end if
	
	result.ConnectUser = getCurrentConnectUser()
	result.Servers.push(server)
	
	return result

End function

function normalizeAddress(baseUrl) as Object

	if Instr(0, baseUrl, "://") = 0 then 
		baseUrl = "http://" + baseUrl
	end if
	
	return baseUrl
	
end function

function tryConnect(url, timeout) as Object

	url = url + "/emby/system/info/public?format=json"
	
	Debug("Attempting to connect to " + url)
	
    ' Prepare Request
    request = HttpRequest(url)

    ' Execute Request
    response = request.GetToStringWithTimeout(timeout)
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

end function

function getCurrentConnectUser() as Object
	return ConnectionManager().ConnectUser
End function

Sub ensureConnectUser() 

	connectUser = getCurrentConnectUser()
	
	connectUserId = firstOf(RegRead("connectUserId"), "")
	connectAccessToken = firstOf(RegRead("connectAccessToken"), "")
	
	if connectUser <> invalid and connectUser.Id = connectUserId then
		return
	end if
	
	ConnectionManager().ConnectUser = invalid
	
	if connectUserId = "" or connectAccessToken = "" then
		return
	end if
	
	ConnectionManager().ConnectUser = getConnectUserFromServer(connectUserId, connectAccessToken)
	
end Sub

function getConnectServers() as Object

	connectUserId = firstOf(RegRead("connectUserId"), "")
	connectAccessToken = firstOf(RegRead("connectAccessToken"), "")
	
	if connectUserId = "" or connectAccessToken = "" then
		servers = CreateObject("roArray", 10, true)
		return servers
	end if

    return getConnectServersFromService(connectUserId, connectAccessToken)
	
end function

function getConnectServersFromService(connectUserId, connectAccessToken) as Object

    if firstOf(connectUserId, "") = "" or firstOf(connectAccessToken, "") = "" then
		return invalid
	end if
	
	' Prepare Request
    request = HttpRequest("https://connect.emby.media/service/servers?userId=" + tostr(connectUserId))
	
    request.Http.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.Http.InitClientCertificates()
	
    request.Http.AddHeader("X-Connect-UserToken", connectAccessToken)
	addXApplicationHeader(request.Http)

    ' Execute Request
    response = request.GetToStringWithTimeout(20)
    if response <> invalid
        metaData = ParseJSON(response)

        if metaData = invalid
            Debug("Error Parsing connect servers")
            return []
        end if

		return metaData
    else
        Debug("Failed to get connect servers")
    end if

    return []
	
End function

function getConnectUserFromServer(id, accessToken) as Object

	if firstOf(accessToken, "") = "" then
		return invalid
	end if
	
	' Prepare Request
    request = HttpRequest("https://connect.emby.media/service/user?id=" + tostr(id))
	
    request.Http.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.Http.InitClientCertificates()
	
    request.Http.AddHeader("X-Connect-UserToken", accessToken)
	addXApplicationHeader(request.Http)

    ' Execute Request
    response = request.GetToStringWithTimeout(20)
    if response <> invalid
        metaData = ParseJSON(response)

        if metaData = invalid
            Debug("Error Parsing connect user")
            return invalid
        end if

		return metaData
    else
        Debug("Failed to get connect user")
    end if

    return invalid
	
End function

Sub addAuthenticationInfoFromConnect(server, connectionMode)

	connectUserId = firstOf(RegRead("connectUserId"), "")
	connectAccessToken = firstOf(RegRead("connectAccessToken"), "")
	exchangeToken = firstOf(server.ExchangeToken, "")
	
	if connectUserId = "" or connectAccessToken = "" then				
		return 
	end if
	
	url = ""
	
	if connectionMode = "Local" then
		url = server.LocalAddress
	else if connectionMode = "Manual" then
		url = server.ManualAddress
	else
		url = server.RemoteAddress
	end if
	
	url = url + "/emby/Connect/Exchange?format=json&ConnectUserId=" + connectUserId

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
	
    request.Http.AddHeader("X-MediaBrowser-Token", exchangeToken)

	connectionManager = ConnectionManager()
	
    ' Execute Request
    response = request.GetToStringWithTimeout(20)
    if response <> invalid
        metaData = ParseJSON(response)

        if metaData = invalid            
			server.UserId = invalid
			server.AccessToken = invalid
		
			connectionManager.DeleteServerData(server.Id, "UserId")
			connectionManager.DeleteServerData(server.Id, "AccessToken")
			return
        end if

		server.UserId = metaData.LocalUserId
		server.AccessToken = metaData.AccessToken
		
		connectionManager.SetServerData(server.Id, "UserId", metaData.LocalUserId)
		connectionManager.SetServerData(server.Id, "AccessToken", metaData.AccessToken)
		
    else
		server.UserId = invalid
		server.AccessToken = invalid
		
		connectionManager.DeleteServerData(server.Id, "UserId")
		connectionManager.DeleteServerData(server.Id, "AccessToken")
    end if
	
End Sub

Sub validateLocalAuthentication(server, connectionMode)

	connectionManager = ConnectionManager()
	
	accessToken = firstOf(server.AccessToken, "")
	
	if accessToken = "" or firstOf(server.UserId, "") = "" then				
		server.UserId = invalid
		server.AccessToken = invalid
		
		connectionManager.DeleteServerData(server.Id, "UserId")
		connectionManager.DeleteServerData(server.Id, "AccessToken")
		return 
	end if
	
	url = ""
	
	if connectionMode = "Local" then
		url = server.LocalAddress
	else if connectionMode = "Manual" then
		url = server.ManualAddress
	else
		url = server.RemoteAddress
	end if
	
	url = url + "/emby/system/info?format=json"

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
	
    request.Http.AddHeader("X-MediaBrowser-Token", accessToken)

    ' Execute Request
    response = request.GetToStringWithTimeout(20)
    if response <> invalid
        metaData = ParseJSON(response)

        if metaData = invalid      

			Debug ("Local authentication info invalid, deleting saved userId and accessToke")
			
			server.UserId = invalid
			server.AccessToken = invalid
		
			connectionManager.DeleteServerData(server.Id, "UserId")
			connectionManager.DeleteServerData(server.Id, "AccessToken")
			return
        end if
		
    else
	
		Debug ("Timed out validating local authentication, deleting saved userId and accessToke")
		
		server.UserId = invalid
		server.AccessToken = invalid
		
		connectionManager.DeleteServerData(server.Id, "UserId")
		connectionManager.DeleteServerData(server.Id, "AccessToken")
    end if
	
End Sub

Sub importSystemInfo(server, systemInfo)

	server.Name = systemInfo.ServerName
	ConnectionManager().SetServerData(server.Id, "Name", server.Name)
	
	updateLocalAddress = true

	if updateLocalAddress = true then
		if firstOf(systemInfo.LocalAddress, "") <> "" then
			server.LocalAddress = systemInfo.LocalAddress
			ConnectionManager().SetServerData(server.Id, "LocalAddress", server.LocalAddress)
		end if
		
		if firstOf(systemInfo.MacAddress, "") <> "" then
			server.MacAddress = systemInfo.MacAddress
			ConnectionManager().SetServerData(server.Id, "MacAddress", server.MacAddress)
		end if
	end if
	
	if firstOf(systemInfo.WanAddress, "") <> "" then
		server.RemoteAddress = systemInfo.WanAddress
		ConnectionManager().SetServerData(server.Id, "RemoteAddress", server.RemoteAddress)
	end if

End Sub

Sub mgrLogout()

	ConnectionManager().ConnectUser = invalid
	RegDelete("connectUserId")
	RegDelete("connectAccessToken")
	
	servers = m.GetSavedServerList()
	
	for each server in servers
	
		if firstOf(server.UserType, "") = "Guest" then
			m.DeleteServer(server.Id)
		end if
		
	end for
	
	servers = m.GetSavedServerList()
	
	for each server in servers
	
		m.DeleteServerData(server.Id, "AccessToken")
		m.DeleteServerData(server.Id, "ExchangeToken")
		m.DeleteServerData(server.Id, "UserId")
		m.DeleteServerData(server.Id, "UserType")
		
	end for
	
End Sub

Function mgrIsLoggedIntoConnect()

	ensureConnectUser()
	
	return getCurrentConnectUser() <> invalid

End Function

Sub addXApplicationHeader(http)

	appName = ConnectionManager().appName
	appVersion = ConnectionManager().appVersion
	
	http.AddHeader("X-Application", appName + "/" + HttpEncode(appVersion))
	
End Sub

Sub mgrSetAppInfo(appName, appVersion)
	m.AppName = appName
	m.appVersion = appVersion
End Sub

Function mgrGetPinCreationHttpRequest()

	url = "https://connect.emby.media/service/pin"

    ' Prepare Request
    request = HttpRequest(url)
    request.Http.AddHeader("Content-Type", "application/x-www-form-urlencoded")
	
	addXApplicationHeader(request.Http)
	
    request.Http.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.Http.InitClientCertificates()
	
	return request.Http
	
End Function

Function mgrGetPinStatusHttpRequest(pinResult)

	url = "https://connect.emby.media/service/pin?pin=" + pinResult.Pin + "&deviceId=" + pinResult.DeviceId

    ' Kick off a polling request
    Debug("Sending pin poll request to " + url)
        
	' Prepare Request
    request = HttpRequest(url)
	
	addXApplicationHeader(request.Http)
	
    request.Http.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.Http.InitClientCertificates()
	
	return request.Http
	
End Function

Function mgrGetPinExchangeHttpRequest(pinResult)

	url = "https://connect.emby.media/service/pin/authenticate"

    ' Prepare Request
    request = HttpRequest(url)
    request.Http.AddHeader("Content-Type", "application/x-www-form-urlencoded")
	
	addXApplicationHeader(request.Http)
	
    request.Http.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.Http.InitClientCertificates()
	
	return request.Http
	
End Function