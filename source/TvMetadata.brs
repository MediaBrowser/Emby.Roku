'*****************************************************************
'**  Emby Roku Client - TV Metadata
'*****************************************************************

'**********************************************************
'** Get TV Seasons for Show
'**********************************************************

Function getTvSeasons(seriesId As String) As Object

    ' Validate Parameter
    if validateParam(seriesId, "roString", "getTvSeasons") = false return invalid

    ' URL
    url = GetServerBaseUrl() + "/Shows/" + HttpEncode(seriesId) + "/Seasons"

    ' Query
    query = {
        UserId: getGlobalVar("user").Id
        IsMissing: "false"
        IsVirtualUnaired: "false"
		fields: "PrimaryImageAspectRatio"
    }

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

        listIds   = CreateObject("roArray", 7, true)
        listNames = CreateObject("roArray", 7, true)
        listNumbers = CreateObject("roArray", 7, true)
		
		response = normalizeJson(response)
        jsonObj   = ParseJSON(response)

        if jsonObj = invalid
            Debug("Error while parsing JSON response for TV Seasons List for Show")
            return invalid
        end if

        for each i in jsonObj.Items
            ' Exclude empty seasons
            itemCount = firstOf(i.RecursiveItemCount, 0)
            if itemCount > 0
                ' Set the Id
                listIds.push( i.Id )

                ' Set the Name
                listNames.push( firstOf(i.Name, "Unknown") )
				
				listNumbers.push(firstOf(i.IndexNumber, -1))
            end if
        end for
        
        return [listIds, listNames, listNumbers]
    end if

    return invalid
End Function


'**********************************************************
'** Get TV Show Next Unplayed Episode
'**********************************************************

Function getTvNextEpisode(seriesId As String) As Object

    ' Validate Parameter
    if validateParam(seriesId, "roString", "getTvNextEpisode") = false return invalid

    ' URL
    url = GetServerBaseUrl() + "/Shows/NextUp"

    ' Query
    query = {
        UserId: getGlobalVar("user").Id
        SeriesId: seriesId
    }

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

        response = normalizeJson(response)
        jsonObj = ParseJSON(response)

        if jsonObj = invalid
            Debug("Error while parsing JSON response for TV Show Next Unplayed Episode")
            return invalid
        end if

        if jsonObj.TotalRecordCount = 0
            return invalid
        end if
        
        i = jsonObj.Items[0]

        metaData = {}

        ' Set Season Number
        if i.ParentIndexNumber <> invalid
            metaData.Season = i.ParentIndexNumber
        end if

        ' Set Episode Number
        if i.IndexNumber <> invalid
            metaData.Episode = i.IndexNumber
        end if

        return metaData
    end if

    return invalid
End Function
