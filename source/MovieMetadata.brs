'*****************************************************************
'**  Media Browser Roku Client - Movie Metadata Class
'*****************************************************************


Function ClassMovieMetadata()
    ' initializes static members once
    this = m.ClassMovieMetadata

    if this = invalid
        this = CreateObject("roAssociativeArray")

        ' constants
        this.class        = "MovieMetadata"

        'variables
        this.jumpList     = {}

        ' functions
        this.GetMovieList       = moviemetadata_movie_list
        this.GetBoxsets         = moviemetadata_boxsets
        this.GetBoxsetMovieList = moviemetadata_boxset_movie_list

        ' singleton
        m.ClassMovieMetadata = this
    end if
    
    return this
End Function


Function InitMovieMetadata()
    this = ClassMovieMetadata()
    return this
End Function


'**********************************************************
'** Get All Movies
'**********************************************************

Function moviemetadata_movie_list(offset = invalid As Dynamic, limit = invalid As Dynamic, filters = invalid As Object) As Object
    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items"

    ' Query
    query = {
        recursive: "true"
        includeitemtypes: "Movie"
        fields: "Overview,PrimaryImageAspectRatio"
        sortby: "SortName"
        sortorder: "Ascending"
		CollapseBoxSetItems: "false"
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

		imageType      = (firstOf(RegUserRead("movieImageType"), "0")).ToInt()

        return parseItemsResponse(response, imageType, "mixed-aspect-ratio-portrait")
    end if

    return invalid
End Function


'**********************************************************
'** Get Movie Boxsets
'**********************************************************

Function moviemetadata_boxsets(offset = invalid As Dynamic, limit = invalid As Dynamic) As Object

    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items"

    ' Query
    query = {
        recursive: "true"
        includeitemtypes: "BoxSet"
        fields: "Overview,PrimaryImageAspectRatio"
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

		imageType      = (firstOf(RegUserRead("movieImageType"), "0")).ToInt()

        return parseItemsResponse(response, imageType, "mixed-aspect-ratio-portrait")
    end if

    return invalid
End Function


'**********************************************************
'** Get Movies in a Boxset
'**********************************************************

Function moviemetadata_boxset_movie_list(boxsetId As String) As Object

    ' Validate Parameter
    if validateParam(boxsetId, "roString", "moviemetadata_boxset_movie_list") = false return invalid

    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items"

    ' Query
    query = {
        parentid: boxsetId
        recursive: "true"
        fields: "Overview,PrimaryImageAspectRatio"
        sortby: "ProductionYear,SortName"
        sortorder: "Ascending"
    }

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

		imageType      = (firstOf(RegUserRead("movieImageType"), "0")).ToInt()

        return parseItemsResponse(response, imageType, "mixed-aspect-ratio-portrait")
    end if

    return invalid
End Function


'**********************************************************
'** Get Resumable Movies
'**********************************************************

Function getMovieResumable() As Object
    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items"

    ' Query
    query = {
        limit: "10"
        recursive: "true"
        includeitemtypes: "Movie"
		fields: "PrimaryImageAspectRatio"
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

        return parseItemsResponse(response, 1, "mixed-aspect-ratio-portrait")
    end if

    return invalid
End Function


'**********************************************************
'** Get Suggested Movies
'**********************************************************

Function getSuggestedMovies() As Object
    ' URL
    url = GetServerBaseUrl() + "/Movies/Recommendations"

    ' Query
    query = {
        UserId: getGlobalVar("user").Id
        ItemLimit: "20"
        CategoryLimit: "1"
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

        contentList = CreateObject("roArray", 20, true)
        fixedResponse = normalizeJson(response)
        jsonObj     = ParseJSON(fixedResponse)

        if jsonObj = invalid
            Debug("Error while parsing JSON response for Recently Added Movies")
            return invalid
        end if

        ' Only Grab 1 Category
        jsonObj = jsonObj[0]

        ' Recommended Because
        recommendationType = jsonObj.RecommendationType
        baselineItemName = jsonObj.BaselineItemName

        for each i in jsonObj.Items
            metaData = getMetadataFromServerItem(i, 1, "mixed-aspect-ratio-portrait")

            contentList.push( metaData )
        end for

        return {
            Items: contentList
            RecommendationType: recommendationType
            BaselineItemName: baselineItemName
        }
    end if

    return invalid
End Function


'**********************************************************
'** Get Latest Unwatched Movies
'**********************************************************

Function getMovieLatest() As Object
    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items"

    ' Query
    query = {
        limit: "20"
        recursive: "true"
        includeitemtypes: "Movie"
        sortby: "DateCreated"
        sortorder: "Descending"
        filters: "IsUnplayed"
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

		imageType      = (firstOf(RegUserRead("movieImageType"), "0")).ToInt()

        return parseItemsResponse(response, 1, "mixed-aspect-ratio-portrait")

    end if

    return invalid
End Function


'**********************************************************
'** Get Favorite Movies
'**********************************************************

Function getMovieFavorites() As Object
    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items"

    ' Query
    query = {
        limit: "10"
        recursive: "true"
        includeitemtypes: "Movie"
        sortby: "SortName"
        sortorder: "Ascending"
        filters: "IsFavorite"
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

		imageType      = (firstOf(RegUserRead("movieImageType"), "0")).ToInt()

        return parseItemsResponse(response, 1, "mixed-aspect-ratio-portrait")
    end if

    return invalid
End Function


'**********************************************************
'** Get Movie Genres
'**********************************************************

Function getMovieGenres(offset = invalid As Dynamic, limit = invalid As Dynamic, homePage = false) As Object
    ' URL
    url = GetServerBaseUrl() + "/Genres"

    ' Query
    query = {
        userid: getGlobalVar("user").Id
        recursive: "true"
        includeitemtypes: "Movie"
        fields: "PrimaryImageAspectRatio"
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

		imageType      = (firstOf(RegUserRead("movieImageType"), "0")).ToInt()

		if homePage = true then imageType = 1

        return parseItemsResponse(response, imageType, "mixed-aspect-ratio-portrait", "moviegenre")
    end if

    return invalid
End Function


'**********************************************************
'** Get Movies in a Genre
'**********************************************************

Function getMovieGenreList(genreName As String, offset = invalid As Dynamic, limit = invalid As Dynamic, searchPage = false) As Object

    ' Validate Parameter
    if validateParam(genreName, "roString", "getMovieGenreList") = false return invalid

    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items"

    ' Query
    query = {
        genres: genreName
        recursive: "true"
        includeitemtypes: "Movie"
        fields: "PrimaryImageAspectRatio,Overview"
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

		imageType      = (firstOf(RegUserRead("movieImageType"), "0")).ToInt()

		if searchPage = true then imageType = 1

        return parseItemsResponse(response, imageType, "mixed-aspect-ratio-portrait")
    end if

    return invalid
End Function
