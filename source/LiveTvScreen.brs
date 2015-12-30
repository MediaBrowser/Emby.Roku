'**********************************************************
'** createLiveTvChannelsScreen
'**********************************************************

Function createLiveTvChannelsScreen(viewController as Object) As Object

	names = ["Channels"]
	keys = ["0"]

	loader = CreateObject("roAssociativeArray")
	loader.getUrl = getLiveTvChannelsScreenUrl
	loader.parsePagedResult = parseLiveTvChannelsScreenResult

    screen = createPaginatedGridScreen(viewController, names, keys, loader, "two-row-flat-landscape-custom")

    screen.SetDescriptionVisible(true)

	return screen
End Function

Function getLiveTvChannelsScreenUrl(row as Integer, id as String) as String

    ' URL
    url = GetServerBaseUrl() + "/LiveTv/Channels?userId=" + getGlobalVar("user").Id

    return url

End Function

Function parseLiveTvChannelsScreenResult(row as Integer, id as string, startIndex as Integer, json as String) as Object

    return parseLiveTvChannelsResult(json)

End Function

'**********************************************************
'** createLiveTvProgramsScreen
'**********************************************************

Function createLiveTvProgramsScreen(viewController as Object, channel As Object) As Object

    screen = CreateListScreen(viewController)

    programResult = getLiveTvPrograms(channel.Id)
    screen.SetContent(programResult.Items)

	index = getOnAirIndex(programResult.Items)
	if index = -1 then index = 0

    screen.SetFocusedItem(index)

	return screen
End Function

Function getOnAirIndex(items as Object) as Integer

    index = 0

    for each i in items
	
        if isProgramOnAir(i) = true then return index
		
		index = index + 1
    end for
		
	return -1
End Function

'**********************************************************
'** isProgramOnAir
'**********************************************************

Function isProgramOnAir(item as Object) As Boolean

	startDateString = item.StartDate
	endDateString = item.EndDate
	
	if startDateString = invalid or endDateString = invalid then return false
	
    nowTime = CreateObject("roDateTime")
    nowTime.ToLocalTime()
    nowTimeSeconds = nowTime.AsSeconds()

    startTime = CreateObject("roDateTime")
    startTime.FromISO8601String(startDateString)
    startTime.ToLocalTime()

    endTime = CreateObject("roDateTime")
    endTime.FromISO8601String(endDateString)
    endTime.ToLocalTime()

    return nowTime.AsSeconds() >= startTime.AsSeconds() And nowTimeSeconds < endTime.AsSeconds()
	
End Function

'**********************************************************
'** createLiveTvGuideScreen
'**********************************************************

Function createLiveTvGuideScreen(viewController as Object) as Object

	limit = 3
	supporterLimit = 80
	
	if IsActiveSupporter() then
		limit = supporterLimit
	else
		createDialog("Support Emby", "Full use of the TV Guide requires an active Emby Premiere subscription. Results will be limited to " + tostr(limit) + " channels. Get Emby Premiere by visiting the server dashboard in the web interface.", "Back", true)
	end if
	
	result = getFavoriteChannels(limit)
	
	if firstOf(RegUserRead("displayedGuideInfo"), "0") = "0" then
	
		createDialog("Guide Information", "This guide is limited to " + tostr(supporterLimit) + " channels and is sorted by channels that you've liked and marked as favorite. Use the server's web interface to mark your favorite channels.", "Back", true)
		RegUserWrite("displayedGuideInfo", "1")
		
	end if
	
	names = []
	keys = []
	
	for each channel in result.Items
	
		names.push(channel.Title)
		keys.push(channel.Id)
	end for

	loader = CreateObject("roAssociativeArray")
	loader.getUrl = getProgramsForChannelUrl
	loader.parsePagedResult = parseProgramsForChannelResult

    screen = createPaginatedGridScreen(viewController, names, keys, loader, "two-row-flat-landscape-custom")

    screen.SetDescriptionVisible(true)

	return screen
End Function

Function getProgramsForChannelUrl(row as Integer, id as String) as String

    ' URL
    url = GetServerBaseUrl() + "/LiveTv/Programs?ChannelIds=" + id + "&HasAired=false&UserId=" + getGlobalVar("user").Id

    return url

End Function

Function parseProgramsForChannelResult(row as Integer, id as string, startIndex as Integer, json as String) as Object

	'return parseItemsResponse(json, 0, "two-row-flat-landscape-custom")
    return parseLiveTvProgramsResponse(json)

End Function

'**********************************************************
'** createLiveTvRecordingGroupsScreen
'**********************************************************

Function createLiveTvRecordingGroupsScreen(viewController as Object, group As Object) As Object

	names = ["Recordings"]
	keys = [group.Id]

	loader = CreateObject("roAssociativeArray")
	loader.getUrl = getLiveTvRecordingGroupsScreenUrl
	loader.parsePagedResult = parseLiveTvRecordingGroupsScreenResult

    screen = createPaginatedGridScreen(viewController, names, keys, loader, "two-row-flat-landscape-custom")

    screen.SetDescriptionVisible(true)

	return screen

End Function

Function getLiveTvRecordingGroupsScreenUrl(row as Integer, id as String) as String

    ' URL
    url = GetServerBaseUrl() + "/LiveTv/Recordings?GroupId=" + id

    ' Query
    query = {
        UserId: getGlobalVar("user").Id
        IsInProgress: "false"
    }

	for each key in query
		url = url + "&" + key +"=" + HttpEncode(query[key])
	end for

    return url

End Function

Function parseLiveTvRecordingGroupsScreenResult(row as Integer, id as string, startIndex as Integer, json as String) as Object

    return parseLiveTvRecordingsResponse(json, "recordinggroup")

End Function


'**********************************************************
'** createLiveTvRecordingsScreen
'**********************************************************

Function createLiveTvRecordingsScreen(viewController as Object) As Object

	names = ["Latest Recordings", "All Recordings"]
	keys = ["0", "1"]

	loader = CreateObject("roAssociativeArray")
	loader.getUrl = getLiveTvRecordingsScreenUrl
	loader.parsePagedResult = parseLiveTvRecordingsScreenResult

    screen = createPaginatedGridScreen(viewController, names, keys, loader, "two-row-flat-landscape-custom")

    screen.SetDescriptionVisible(true)

	return screen

End Function

Function getLiveTvRecordingsScreenUrl(row as Integer, id as String) as String

    ' URL
    url = GetServerBaseUrl() 

	query = {}

	if row = 0 then

		url = url + "/LiveTv/Recordings?userId=" + getGlobalVar("user").Id

		query = {
			IsInProgress: "false"
		}

	else if row = 1

		url = url + "/LiveTv/Recordings/Groups?userId=" + getGlobalVar("user").Id

	end if

	for each key in query
		url = url + "&" + key +"=" + HttpEncode(query[key])
	end for

    return url

End Function

Function parseLiveTvRecordingsScreenResult(row as Integer, id as string, startIndex as Integer, json as String) as Object

	if row = 0 then

		return parseLiveTvRecordingsResponse(json)

	else if row = 1

		return parseLiveTvRecordingGroupResponse(json)

	end if

End Function