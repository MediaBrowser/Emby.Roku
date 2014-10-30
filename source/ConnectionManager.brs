function connectInitial() as Object

	servers = findServers()	
	Debug ("Found " + tostr(servers.Count()) + " servers")
	
	for each server in servers
	
		SetServerData(server.Id, "Name", server.Name)
		SetServerData(server.Id, "LocalAddress", server.LocalAddress)
		
	end for
	
	ensureConnectUser()
	
	servers = getConnectServers()	
	Debug ("Connect returned " + tostr(servers.Count()) + " servers")
	
	for each server in servers
	
		SetServerData(server.SystemId, "Name", server.Name)
		
		if firstOf(server.LocalAddress, "") <> "" then  SetServerData(server.SystemId, "LocalAddress", server.LocalAddress)
		SetServerData(server.SystemId, "RemoteAddress", server.Url)
		
		SetServerData(server.SystemId, "ExchangeToken", server.AccessKey)
		SetServerData(server.SystemId, "UserType", firstOf(server.UserType, ""))
		
	end for
	
	servers = getServerList()
	
	return connectToServers(servers)

end function

function connectToServers(servers) as Object

	count = servers.Count()
	
	if count = 1
		
		result = connectToServerInfo(servers[0])
		
		if result.State = "Unavailable" then
			
			if result.ConnectUser = invalid then
				result.State = "ConnectSignIn"
			else
				result.State = "ServerSelection"
			end if
			
		end if
		
		return result
		
	end if
	
	for each server in servers
	
		if firstOf(server.AccessToken, "") <> "" then
		
			result = connectToServerInfo(server)
			
			if result.State = "SignedIn" then
				return result
			end if
			
		end if
		
	end for
	
	finalResult = {
		Servers: servers,
		ConnectUser: getCurrentConnectUser()
	}
	
	if count = 0 and finalResult.ConnectUser = invalid then
		finalResult.State = "ConnectSignIn"
	else
		finalResult.State = "ServerSelection"
	end if
	
	return finalResult

End function

function connectToServer(url) as Object

	url = normalizeAddress(url)
	
	publicInfo = tryConnect(url)
	
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
		MacAddress: publicInfo.MacAddress
	}
	
	return connectToServerInfo(serverInfo)

End function

function connectToServerInfo(server) as Object

	result = {
		State: "Unavailable"
	}
	
	connectionMode = "Local"
	systemInfo = invalid 
	
	if firstOf(server.LocalAddress, "") <> "" then
		
		systemInfo = tryConnect(server.LocalAddress)
		
		if systemInfo = invalid and firstOf(server.MacAddress, "") <> "" then
		
			sendWol(server.Id)
			
			systemInfo = tryConnect(server.LocalAddress)
			
		end if
	
	end if
	
	if systemInfo = invalid and firstOf(server.RemoteAddress, "") <> "" then
	
		systemInfo = tryConnect(server.RemoteAddress)
		connectionMode = "Remote"
	end if
	
	if systemInfo = invalid then
		result.ConnectUser = getCurrentConnectUser()
		return result
	end if
	
	importSystemInfo(server, systemInfo)
	
	ensureConnectUser()
	addAuthenticationInfoFromConnect(server, connectionMode)
	
	if firstOf(server.AccessToken, "") <> "" then
		validateLocalAuthentication(server, connectionMode)
	end if
	
	if firstOf(server.AccessToken, "") = "" then
		result.State = "ServerSignIn"
	else
		result.State = "SignedIn"
	end if
	
	result.ConnectUser = getCurrentConnectUser()
	
	return result

End function

function normalizeAddress(url) as Object

	return url
	
end function

function tryConnect(url) as Object

    ' Prepare Request
    request = HttpRequest(url + "/mediabrowser/system/info/public")
    request.ContentType("json")

    ' Execute Request
    response = request.GetToStringWithTimeout(5)
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
	return GetViewController().ConnectUser
End function

Sub ensureConnectUser() 

	connectUser = getCurrentConnectUser()
	
	connectUserId = firstOf(RegRead("connectUserId"), "")
	connectAccessToken = firstOf(RegRead("connectAccessToken"), "")
	
	if connectUser <> invalid and connectUser.Id = connectUserId then
		return
	end if
	
	GetViewController().ConnectUser = invalid
	
	if connectUserId = "" or connectAccessToken = "" then
		return
	end if
	
	GetViewController().ConnectUser = getConnectUser(connectUserId, connectAccessToken)
	
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

    ' Prepare Request
    request = HttpRequest("https://connect.mediabrowser.tv/service/servers?userId=" + tostr(connectUserId))
    request.ContentType("json")
	
    request.Http.AddHeader("X-Connect-UserToken", connectAccessToken)

    ' Execute Request
    response = request.GetToStringWithTimeout(5)
    if response <> invalid
        metaData = ParseJSON(response)

        if metaData = invalid
            Debug("Error Parsing connect user")
            return []
        end if

		return metaData
    else
        Debug("Failed to get connect user")
    end if

    return []
	
End function

function getConnectUser(id, accessToken) as Object

    ' Prepare Request
    request = HttpRequest("https://connect.mediabrowser.tv/service/user?id=" + tostr(id))
    request.ContentType("json")
	
    request.Http.AddHeader("X-Connect-UserToken", accessToken)

    ' Execute Request
    response = request.GetToStringWithTimeout(5)
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
	else
		url = server.RemoteAddress
	end if
	
	url = url + "/mediabrowser/Connect/Exchange?format=json&ConnectUserId=" + connectUserId

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
	
    request.Http.AddHeader("X-MediaBrowser-Token", exchangeToken)

    ' Execute Request
    response = request.GetToStringWithTimeout(5)
    if response <> invalid
        metaData = ParseJSON(response)

        if metaData = invalid            
			server.UserId = invalid
			server.AccessToken = invalid
		
			DeleteServerData(server.Id, "UserId")
			DeleteServerData(server.Id, "AccessToken")
			return
        end if

		server.UserId = metaData.LocalUserId
		server.AccessToken = metaData.AccessToken
		
		SetServerData(server.Id, "UserId", metaData.LocalUserId)
		SetServerData(server.Id, "AccessToken", metaData.AccessToken)
		
    else
		server.UserId = invalid
		server.AccessToken = invalid
		
		DeleteServerData(server.Id, "UserId")
		DeleteServerData(server.Id, "AccessToken")
    end if
	
End Sub

Sub validateLocalAuthentication(server, connectionMode)

	accessToken = firstOf(server.AccessToken, "")
	
	if accessToken = "" then				
		return 
	end if
	
	url = ""
	
	if connectionMode = "Local" then
		url = server.LocalAddress
	else
		url = server.RemoteAddress
	end if
	
	url = url + "/mediabrowser/system/info?format=json"

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
	
    request.Http.AddHeader("X-MediaBrowser-Token", accessToken)

    ' Execute Request
    response = request.GetToStringWithTimeout(5)
    if response <> invalid
        metaData = ParseJSON(response)

        if metaData = invalid            
			server.UserId = invalid
			server.AccessToken = invalid
		
			DeleteServerData(server.Id, "UserId")
			DeleteServerData(server.Id, "AccessToken")
			return
        end if

		importSystemInfo(server, metaData)
		
    else
		server.UserId = invalid
		server.AccessToken = invalid
		
		DeleteServerData(server.Id, "UserId")
		DeleteServerData(server.Id, "AccessToken")
    end if
	
End Sub

Sub importSystemInfo(server, systemInfo)

	server.Name = systemInfo.Name
	setServerData(server.Id, "Name", server.Name)

	if firstOf(systemInfo.LocalAddress, "") <> "" then
		server.LocalAddress = systemInfo.LocalAddress
		setServerData(server.Id, "LocalAddress", server.LocalAddress)
	end if
	
	if firstOf(systemInfo.WanAddress, "") <> "" then
		server.RemoteAddress = systemInfo.WanAddress
		setServerData(server.Id, "RemoteAddress", server.RemoteAddress)
	end if
	
	if firstOf(systemInfo.MacAddress, "") <> "" then
		server.MacAddress = systemInfo.MacAddress
		setServerData(server.Id, "MacAddress", server.MacAddress)
	end if

End Sub