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


'**********************************************************
'** getMetadataFromLiveTvProgramItem
'**********************************************************

Function getMetadataFromLiveTvProgramItem(i as Object) As Object

    metaData = {}

    metaData.ContentType = i.Type
	metaData.MediaType = i.MediaType
    metaData.Id = i.Id
    metaData.ProgramId = i.Id
    metaData.ChannelId = i.ChannelId
	metaData.PrimaryImageAspectRatio = i.PrimaryImageAspectRatio

    programTitle = ""

    if i.StartDate <> invalid And i.StartDate <> ""
        programTitle = getProgramDisplayTime(i.StartDate) + " - "
    end if

    ' Add the Program Name
    programTitle = programTitle + firstOf(i.Name, "")

    metaData.Title = firstOf(programTitle, "")
    metaData.ShortDescriptionLine1 = firstOf(i.Name, "")
    metaData.ShortDescriptionLine2 = firstOf(i.EpisodeTitle, "")

    if i.Overview <> invalid
        metaData.Description = i.Overview
    end if

    if i.OfficialRating <> invalid
        metaData.Rating = i.OfficialRating
    end if

    if i.CommunityRating <> invalid
        metaData.StarRating = Int(i.CommunityRating) * 10
    end if

    if i.RunTimeTicks <> invalid and i.RunTimeTicks <> ""
        metaData.Length = Int(((i.RunTimeTicks).ToFloat() / 10000) / 1000)
    end if

    metaData.PlayAccess = firstOf(i.PlayAccess, "Full")

	metaData.StartDate = i.StartDate
	metaData.EndDate = i.EndDate

	metaData.TimerId = i.TimerId

    if i.IsHD <> invalid
        metaData.HDBranded = i.IsHD
        metaData.IsHD = i.IsHD
    end if

    if i.SeriesTimerId <> invalid And i.SeriesTimerId <> ""
        metaData.HDSmallIconUrl = GetViewController().getThemeImageUrl("SeriesRecording.png")
        metaData.SDSmallIconUrl = GetViewController().getThemeImageUrl("SeriesRecording.png")
    else if i.TimerId <> invalid And i.TimerId <> ""
        metaData.HDSmallIconUrl = GetViewController().getThemeImageUrl("Recording.png")
        metaData.SDSmallIconUrl = GetViewController().getThemeImageUrl("Recording.png")
    end if
   
    if i.IsSeries = true Or i.IsSports = true
        sizes = GetImageSizes("two-row-flat-landscape-custom")
    else
        sizes = GetImageSizes("mixed-aspect-ratio-portrait")
    end if
        
    if i.ImageTags.Primary <> "" And i.ImageTags.Primary <> invalid
        imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.Id) + "/Images/Primary/0"

        metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ImageTags.Primary, i.UserData.Played, 0)
        metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ImageTags.Primary, i.UserData.Played, 0)

    else 
        if i.IsSeries = true Or i.IsSports = true
            metaData.HDPosterUrl = GetViewController().getThemeImageUrl("hd-landscape.jpg")
            metaData.SDPosterUrl = GetViewController().getThemeImageUrl("sd-landscape.jpg")
        else
            metaData.HDPosterUrl = GetViewController().getThemeImageUrl("hd-poster.jpg")
            metaData.SDPosterUrl = GetViewController().getThemeImageUrl("sd-poster.jpg")
        end if

    end if
	
    FillUserDataFromItem(metaData, i)
	FillActorsFromItem(metaData, i)
	FillCategoriesFromGenres(metaData, i)

	addVideoDisplayInfo(metaData, i)

    return metaData

End Function

Function getCurrentLiveTvPrograms() As Object
    ' URL
    url = GetServerBaseUrl() + "/LiveTv/Programs/Recommended"

    ' Query
    query = {
        UserId: getGlobalVar("user").Id
        limit: "30"
        IsAiring: "true"
    }

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
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
            metaData = getMetadataFromLiveTvProgramItem(i)

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

        return getMetadataFromLiveTvProgramItem(i)

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
    if response <> invalid

        contentList = CreateObject("roArray", 25, true)
		
		fixedResponse = normalizeJson(response)
        jsonObj     = ParseJSON(fixedResponse)

        if jsonObj = invalid
            return invalid
        end if

        totalRecordCount  = jsonObj.TotalRecordCount

        for each i in jsonObj.Items
            metaData = getMetadataFromLiveTvProgramItem(i)

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
'** getLiveTvRecordings
'**********************************************************

Function getLiveTvRecordings() As Object

    ' URL
    url = GetServerBaseUrl() + "/LiveTv/Recordings"

    ' Query
    query = {
        UserId: getGlobalVar("user").Id
        IsInProgress: "false"
    }

    query.AddReplace("Limit", "20")

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

        return parseLiveTvRecordingsResponse(response)
    end if

    return invalid
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

'**********************************************************
'** getProgramDisplayTime
'**********************************************************

Function getProgramDisplayTime(dateString As String) As String

    dateTime = CreateObject("roDateTime")
    dateTime.FromISO8601String(dateString)
    return GetTimeString(dateTime, true)
	
End Function