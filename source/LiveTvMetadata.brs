'******************************************************
' getLiveTvInfo
'******************************************************

Function getLiveTvInfo() As Object
    
	url = GetServerBaseUrl() + "/LiveTv/Info"
    
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()

    response = request.GetToStringWithTimeout(10)
    if response <> invalid
	
        fixedResponse = normalizeJson(response)
		metaData = ParseJSON(fixedResponse)

        return metaData

	end if

    return invalid
End Function

'******************************************************
' getLiveTvChannel
'******************************************************

Function getFavoriteChannels(limit as Integer) As Object

    ' URL
    url = GetServerBaseUrl() + "/LiveTv/Channels?EnableFavoriteSorting=true&Limit=" + tostr(limit) + "&UserId=" + getGlobalVar("user").Id

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    return parseLiveTvChannelsResult(response)
End Function

Function getLiveTvChannel(id as String) As Object
    
	url = GetServerBaseUrl() + "/LiveTv/Channels/" + id + "?userId=" + getGlobalVar("user").Id
    
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()

    response = request.GetToStringWithTimeout(10)
    if response <> invalid
	
        fixedResponse = normalizeJson(response)
		metaData = ParseJSON(fixedResponse)

        return getMetadataFromServerItem(metaData, 0, "two-row-flat-landscape-custom")

	end if

    return invalid
End Function

Function parseLiveTvProgramsResponse(response) As Object
    
	if response <> invalid

        contentList = CreateObject("roArray", 10, true)
        fixedResponse = normalizeJson(response)
        jsonObj     = ParseJSON(fixedResponse)

        if jsonObj = invalid
            Debug("Error while parsing JSON response for Live TV What's On")
            return invalid
        end if

        totalRecordCount = jsonObj.TotalRecordCount

        for each i in jsonObj.Items
            metaData = getMetadataFromServerItem(i, 0, "two-row-flat-landscape-custom", "autosize")

            contentList.push( metaData )
        end for

        return {
            Items: contentList
            TotalCount: totalRecordCount
        }
    end if

    return invalid
End Function


'**********************************************************
'** getLiveTvProgramMetadata
'**********************************************************

Function getLiveTvProgramMetadata(programId As String) As Object
    ' URL
    url = GetServerBaseUrl() + "/LiveTv/Programs/" + HttpEncode(programId)

    ' Query
    query = {
        UserId: getGlobalVar("user").Id
    }

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

        fixedResponse = normalizeJson(response)
        i = ParseJSON(fixedResponse)

        return getMetadataFromServerItem(i, 0, "two-row-flat-landscape-custom", "autosize")

    end if

    return invalid
End Function


'**********************************************************
'** getLiveTvPrograms
'**********************************************************

Function getLiveTvPrograms(channelId As String, filters = invalid As Object) As Object
    ' URL
    url = GetServerBaseUrl() + "/LiveTv/Programs"

    ' Query
    query = {
        UserId: getGlobalVar("user").Id
        ChannelIds: channelId
    }

    ' Filter/Sort Query
    if filters <> invalid
        query = AddToQuery(query, filters)
    end if

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    return parseLiveTvProgramsResponse(response)
End Function

Function parseLiveTvRecordingsResponse(response, mode = "") As Object

    if response <> invalid

        contentList = CreateObject("roArray", 10, true)
		fixedResponse = normalizeJson(response)
        jsonObj     = ParseJSON(fixedResponse)

        if jsonObj = invalid
            return invalid
        end if

        totalRecordCount = jsonObj.TotalRecordCount

        for each i in jsonObj.Items

			metaData = getLiveTvRecordingFromServerResponse(i, mode)
            contentList.push( metaData )
        end for

        return {
            Items: contentList
            TotalCount: totalRecordCount
        }
    end if

    return invalid
End Function

Function getLiveTvRecordingFromServerResponse(i as Object, mode = "") as Object

	return getMetadataFromServerItem(i, 0, "two-row-flat-landscape-custom", mode)

End Function


'**********************************************************
'** getLiveTvRecording
'**********************************************************

Function getLiveTvRecording(recordingId As String) As Object
    ' URL
    url = GetServerBaseUrl() + "/LiveTv/Recordings/" + HttpEncode(recordingId)

    ' Query
    query = {
        UserId: getGlobalVar("user").Id
    }

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

        fixedResponse = normalizeJson(response)

        i = ParseJSON(fixedResponse)

        return getLiveTvRecordingFromServerResponse(i)

    end if

    return invalid
End Function


'**********************************************************
'** parseLiveTvRecordingGroupResponse
'**********************************************************

Function parseLiveTvRecordingGroupResponse(response) As Object

    if response <> invalid

        contentList = CreateObject("roArray", 10, true)
		fixedResponse = normalizeJson(response)
        jsonObj     = ParseJSON(fixedResponse)

        if jsonObj = invalid
            return invalid
        end if

        totalRecordCount = jsonObj.TotalRecordCount

        for each i in jsonObj.Items
            metaData = {}

            metaData.ContentType = "RecordingGroup"
			metaData.Id = i.Id

            metaData.Title = firstOf(i.Name, "Unknown")
            metaData.ShortDescriptionLine1 = firstOf(i.Name, "Unknown")
            metaData.ShortDescriptionLine2 = Pluralize(i.RecordingCount, "recording")

            metaData.HDPosterUrl = GetViewController().getThemeImageUrl("hd-landscape.jpg")
            metaData.SDPosterUrl = GetViewController().getThemeImageUrl("sd-landscape.jpg")

            contentList.push( metaData )
        end for

        return {
            Items: contentList
            TotalCount: totalRecordCount
        }
    end if

    return invalid
End Function

'**********************************************************
'** parseLiveTvChannelsResult
'**********************************************************

Function parseLiveTvChannelsResult(response) As Object

    if response <> invalid

        contentList = CreateObject("roArray", 25, true)
		fixedResponse = normalizeJson(response)
        jsonObj     = ParseJSON(fixedResponse)

        if jsonObj = invalid
            return invalid
        end if

        totalRecordCount = jsonObj.TotalRecordCount

        for each i in jsonObj.Items
		
            metaData = getMetadataFromServerItem(i, 0, "two-row-flat-landscape-custom")

            contentList.push( metaData )
        end for

        return {
            Items: contentList
            TotalCount: totalRecordCount
        }
    else
        Debug("Error getting live tv channels")
    end if

    return invalid
End Function