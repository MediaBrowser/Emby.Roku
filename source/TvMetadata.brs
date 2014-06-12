'*****************************************************************
'**  Media Browser Roku Client - TV Metadata
'*****************************************************************


'**********************************************************
'** Get All TV Shows
'**********************************************************

Function getTvShowList(offset = invalid As Dynamic, limit = invalid As Dynamic, filters = invalid As Object) As Object

    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items"

    ' Query
    query = {
        recursive: "true"
        IncludeItemTypes: "Series"
        fields: "Overview"
        sortby: "SortName"
        sortorder: "Ascending"
    }

    ' Filter/Sort Query
    if filters <> invalid
        query = AddToQuery(query, filters)
    end if

    ' Paging
    if limit <> invalid And offset <> invalid
        query.AddReplace("startindex", itostr(offset))
        query.AddReplace("limit", itostr(limit))
    end if    

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

		imageType      = (firstOf(RegUserRead("tvImageType"), "0")).ToInt()

        return parseItemsResponse(response, imageType, "mixed-aspect-ratio-portrait")
    else
        Debug("Failed to Get TV Shows List")
    end if

    return invalid
End Function


'**********************************************************
'** Get Resumable TV
'**********************************************************

Function getTvResumable() As Object
    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items"

    ' Query
    query = {
        limit: "20"
        recursive: "true"
        includeitemtypes: "Episode"
        fields: "SeriesInfo,PlayedPercentage,UserData"
        sortby: "DatePlayed"
        sortorder: "Descending"
        filters: "IsResumable"
    }

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

        return parseItemsResponse(response, 0, "two-row-flat-landscape-custom")
    else
        Debug("Failed to Get Resumable TV Shows")
    end if

    return invalid
End Function


'**********************************************************
'** Get Latest Unwatched TV Episodes
'**********************************************************

Function getTvLatest() As Object
    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items"

    ' Query
    query = {
        limit: "20"
        recursive: "true"
        IncludeItemTypes: "Episode"
        ExcludeLocationTypes: "Virtual"
        fields: "SeriesInfo,UserData"
        sortby: "DateCreated"
        sortorder: "Descending"
        filters: "IsUnplayed"
    }

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

        return parseItemsResponse(response, 0, "two-row-flat-landscape-custom")
    else
        Debug("Failed to Get Recently Added TV Shows")
    end if

    return invalid
End Function


'**********************************************************
'** Get Favorite TV Shows
'**********************************************************

Function getTvFavorites() As Object
    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items"

    ' Query
    query = {
        recursive: "true"
        IncludeItemTypes: "Series"
        sortby: "SortName"
        sortorder: "Ascending"
        filters: "IsFavorite"
    }

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

        return parseItemsResponse(response, 1, "two-row-flat-landscape-custom")
    else
        Debug("Failed to Get Favorite TV Shows")
    end if

    return invalid
End Function


'**********************************************************
'** Get Next Unwatched TV Episodes
'**********************************************************

Function getTvNextUp(offset = invalid As Dynamic, limit = invalid As Dynamic, homePage = false, mode = "" as string) As Object
    ' URL
    url = GetServerBaseUrl() + "/Shows/NextUp"

    ' Query
    query = {
        userid: getGlobalVar("user").Id
        fields: "SeriesInfo,DateCreated,Overview"
    }

    ' Paging
    if limit <> invalid And offset <> invalid
        query.AddReplace("startindex", itostr(offset))
        query.AddReplace("limit", itostr(limit))
    end if    

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid
	
		imageType      = (firstOf(RegUserRead("tvImageType"), "0")).ToInt()
		imageStyle = "two-row-flat-landscape-custom"

		if mode = "seriesimageasprimary" then imageStyle = "mixed-aspect-ratio-portrait"
		
		return parseItemsResponse(response, imageType, imageStyle, mode)
    else
        Debug("Failed to Get Next Episodes to Watch for TV Shows")
    end if

    return invalid
End Function


'**********************************************************
'** Get TV Genres
'**********************************************************

Function getTvGenres(offset = invalid As Dynamic, limit = invalid As Dynamic, homePage = false) As Object
    ' URL
    url = GetServerBaseUrl() + "/Genres"

    ' Query
    query = {
        userid: getGlobalVar("user").Id
        recursive: "true"
        includeitemtypes: "Series"
        fields: "ItemCounts"
        sortby: "SortName"
        sortorder: "Ascending"
    }

    ' Paging
    if limit <> invalid And offset <> invalid
        query.AddReplace("startindex", itostr(offset))
        query.AddReplace("limit", itostr(limit))
    end if    

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

		imageType      = (firstOf(RegUserRead("tvImageType"), "0")).ToInt()

		if homePage = true then imageType = 1

        return parseItemsResponse(response, imageType, "mixed-aspect-ratio-portrait", "tvgenre")
    else
        Debug("Failed to Get Genres for TV Shows")
    end if

    return invalid
End Function


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
    else
        Debug("Failed to Get TV Seasons List for Show")
    end if

    return invalid
End Function


'**********************************************************
'** Get TV Shows in a Genre
'**********************************************************

Function getTvGenreShowList(genreName As String, offset = invalid As Dynamic, limit = invalid As Dynamic, searchPage = false) As Object
    ' Validate Parameter
    if validateParam(genreName, "roString", "GetTvGenreShowList") = false return invalid

    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items"

    ' Query
    query = {
        genres: genreName
        recursive: "true"
        includeitemtypes: "Series"
        fields: "ItemCounts,SortName,Overview"
        sortby: "SortName"
        sortorder: "Ascending"
    }

    ' Paging
    if limit <> invalid And offset <> invalid
        query.AddReplace("StartIndex", itostr(offset))
        query.AddReplace("Limit", itostr(limit))
    end if    

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

		imageType      = (firstOf(RegUserRead("tvImageType"), "0")).ToInt()

		if searchPage = true then imageType = 1

        return parseItemsResponse(response, imageType, "mixed-aspect-ratio-portrait")
    else
        Debug("Failed to Get TV Shows List In Genre")
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
    else
        Debug("Failed to Get TV Show Next Unplayed Episode")
    end if

    return invalid
End Function
