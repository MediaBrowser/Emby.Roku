Function InitServerData (machineID=invalid)
    if GetGlobalAA().serverData = invalid then
        Debug("Creating server data cache")
        dataString = RegRead("serverList2", "serverData")
        GetGlobalAA().serverData = CreateObject("roAssociativeArray")
        if dataString <> invalid then
            Debug("Found string in the registry: " + dataString )
            GetGlobalAA().serverData = ParseJson(dataString) 
            Debug("Parsed as: " + tostr(GetGlobalAA().serverData) )
            if GetGlobalAA().serverData = invalid then
                GetGlobalAA().serverData = createObject("roAssociativeArray")
            end if
         end if
    end if
    if machineID <> invalid and GetGlobalAA().serverData[machineID] = invalid then
        GetGlobalAA().serverData[machineID] = createObject("roAssociativeArray")
    end if
End Function

Function mrgGetSavedServerList () as Object
    InitServerData()
	servers = CreateObject("roArray", 3, true)
	data = GetGlobalAA().serverData
	
	for each serverId in data
	
		server = data[serverId]		
		if server <> invalid and firstOf(server.Name, "") <> "" and (firstOf(server.LocalAddress, "") <> "" or firstOf(server.ManualAddress, "") <> "" or firstOf(server.RemoteAddress, "") <> "") then 
			server.Id = serverId
			servers.push(server)
		end if
	end for
	
	return servers
End Function

Function mgrGetServerData ( machineID, dataName ) As Dynamic  
    InitServerData(machineID)
    
	return GetGlobalAA().serverData[machineID][dataName]
End Function

Function mgrSetServerData ( machineID, dataName, value ) As Boolean
    InitServerData(machineID)
    GetGlobalAA().serverData[machineID][dataName] = value
    RegWrite("serverList2", SimpleJSONBuilder(GetGlobalAA().serverData), "serverData")
    return true
End Function

Function mgrDeleteServerData ( machineID, dataName ) As Boolean
    InitServerData(machineID)
    data = GetGlobalAA().serverData[machineID]
    data.delete(dataName)
    RegWrite("serverList2", SimpleJSONBuilder(GetGlobalAA().serverData), "serverData")
    return true
End Function

Function mgrDeleteServer ( machineID ) As Boolean
    InitServerData()
	
    GetGlobalAA().serverData[machineID] = invalid
	
    RegWrite("serverList2", SimpleJSONBuilder(GetGlobalAA().serverData), "serverData")
    return true
End Function