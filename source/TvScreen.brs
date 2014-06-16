'******************************************************
' createTvLibraryScreen
'******************************************************

Function createTvLibraryScreen(viewController as Object) As Object

    imageType      = (firstOf(RegUserRead("tvImageType"), "0")).ToInt()

	names = ["Shows", "Jump In", "Next Up", "Genres"]
	keys = ["0", "1", "2", "3"]

	loader = CreateObject("roAssociativeArray")
	loader.getUrl = getTvLibraryRowScreenUrl
	loader.parsePagedResult = parseTvLibraryScreenResult
	loader.getLocalData = getTvLibraryScreenLocalData

    if imageType = 0 then
        screen = createPaginatedGridScreen(viewController, names, keys, loader, "mixed-aspect-ratio")
    Else
        screen = createPaginatedGridScreen(viewController, names, keys, loader, "two-row-flat-landscape-custom")
    End If

	screen.baseActivate = screen.Activate
	screen.Activate = tvScreenActivate

    screen.displayDescription = (firstOf(RegUserRead("tvDescription"), "0")).ToInt()

	screen.createContextMenu = tvScreenCreateContextMenu

    return screen

End Function

Sub tvScreenActivate(priorScreen)

    imageType      = (firstOf(RegUserRead("tvImageType"), "0")).ToInt()
	displayDescription = (firstOf(RegUserRead("tvDescription"), "0")).ToInt()
	
    if imageType = 0 then
		gridStyle = "mixed-aspect-ratio"
    Else
		gridStyle = "two-row-flat-landscape-custom"
    End If

	m.baseActivate(priorScreen)

	if gridStyle <> m.gridStyle or displayDescription <> m.displayDescription then
		
		m.displayDescription = displayDescription
		m.gridStyle = gridStyle
		m.DestroyAndRecreate()

	end if

End Sub

Function tvScreenCreateContextMenu()
	
	options = {
		settingsPrefix: "tv"
		sortOptions: ["Name", "Date Added", "Premiere Date"]
		filterOptions: ["None", "Continuing", "Ended"]
		showSortOrder: true
	}
	createContextMenuDialog(options)

	return true

End Function

Function getTvLibraryScreenLocalData(row as Integer, id as String, startItem as Integer, count as Integer) as Object

	if row = 1 then
		return getAlphabetList("TvAlphabet")
	end If

    return invalid

End Function

Function getTvLibraryRowScreenUrl(row as Integer, id as String) as String

    filterBy       = (firstOf(RegUserRead("tvFilterBy"), "0")).ToInt()
    sortBy         = (firstOf(RegUserRead("tvSortBy"), "0")).ToInt()
    sortOrder      = (firstOf(RegUserRead("tvSortOrder"), "0")).ToInt()

    ' URL
    url = GetServerBaseUrl()

    query = {}

	if row = 0
		' Tv genres
		url = url  + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"

		query.AddReplace("IncludeItemTypes", "Series")
		query.AddReplace("fields", "Overview")

		if filterBy = 1
			query.AddReplace("SeriesStatus", "Continuing")
		else if filterBy = 2
			query.AddReplace("SeriesStatus", "Ended")
		end if

		if sortBy = 1
			query.AddReplace("SortBy", "DateCreated,SortName")
		else if sortBy = 2
			query.AddReplace("SortBy", "PremiereDate,SortName")
		else
			query.AddReplace("SortBy", "SortName")
		end if

		if sortOrder = 1
			query.AddReplace("SortOrder", "Descending")
		end if


	else if row = 1
		' Alphabet - should never get in here
		
	else if row = 2
		' Tv next up
		url = url  + "/Shows/NextUp?fields=Overview"

		query.AddReplace("userid", getGlobalVar("user").Id)
		query.AddReplace("SortBy", "SortName")
	else if row = 3
		' Tv genres
		url = url  + "/Genres?recursive=true"

		query.AddReplace("userid", getGlobalVar("user").Id)
		query.AddReplace("IncludeItemTypes", "Series")
		query.AddReplace("SortBy", "SortName")
	end If

	for each key in query
		url = url + "&" + key +"=" + HttpEncode(query[key])
	end for

    return url

End Function

Function parseTvLibraryScreenResult(row as Integer, id as string, startIndex as Integer, json as String) as Object

	imageType      = (firstOf(RegUserRead("tvImageType"), "0")).ToInt()
	primaryImageStyle = "mixed-aspect-ratio-portrait"
	mode = ""

	if row = 2 
		mode = "seriesimageasprimary" 
	else if row = 3
		mode = "tvgenre"
	end if

    return parseItemsResponse(json, imageType, primaryImageStyle, mode)

End Function


'******************************************************
' createTvSeasonsScreen
'******************************************************

Function createTvSeasonsScreen(viewController as Object, seriesInfo As Object) As Object
    
	obj = CreatePosterScreen(viewController, seriesInfo, "flat-episodic-16x9")

	obj.seriesInfo = seriesInfo
	obj.GetDataContainer = getTvSeasonsDataContainer
	obj.dataLoaderHttpHandler = getTvSeasonsPagedDataLoader(seriesInfo.Id)

    return obj

End Function

Function getTvSeasonsPagedDataLoader(seriesId as String) as Object

	obj = CreateObject("roAssociativeArray")

	obj.seriesId = seriesId
	obj.getUrl = getTvSeasonUrl
	obj.parsePagedResult = parseTvEpisodesResponse

	return obj

End Function

'**********************************************************
'** parseTvEpisodesResponse
'**********************************************************
Function parseTvEpisodesResponse(row as Integer, id as string, startIndex as Integer, json as String) as Object

	return parseItemsResponse(json, 0, "flat-episodic-16x9", "episodedetails")

End Function

Function getTvSeasonUrl(row as Integer, seasonId as String) as String

	seriesId = m.seriesId

    ' URL
    url = GetServerBaseUrl() + "/Shows/" + HttpEncode(seriesId) + "/Episodes?SeasonId=" + seasonId

	userId = getGlobalVar("user").Id

	url = url + "&userId=" + userId

	return url

End Function


Function getTvSeasonsDataContainer(viewController as Object, item as Object) as Object

    seasonData = getTvSeasons(item.Id)

    if seasonData = invalid
        return invalid
    end if

    seasonIds   = seasonData[0]
    seasonNames = seasonData[1]
	seasonNumbers = seasonData[2]

	obj = CreateObject("roAssociativeArray")
	obj.names = seasonNames
	obj.keys = seasonIds
	obj.items = []

	nextEpisode = getTvNextEpisode(item.Id)

	if nextEpisode <> invalid And nextEpisode.Season <> invalid

		index = 0

		for each i in seasonNumbers
			if nextEpisode.Season = i then 
				
				exit for
			end if
		
			index = index + 1
		end for

		obj.focusedIndex = index

	end if

	return obj

End Function

'******************************************************
' createTvGenreScreen
'******************************************************

Function createTvGenreScreen(viewController as Object, genre As String) As Object

    imageType      = (firstOf(RegUserRead("tvImageType"), "0")).ToInt()

	names = ["Shows"]
	keys = [genre]

	loader = CreateObject("roAssociativeArray")
	loader.getUrl = getTvGenreScreenUrl
	loader.parsePagedResult = parseTvGenreScreenResult

    if imageType = 0 then
        screen = createPaginatedGridScreen(viewController, names, keys, loader, "mixed-aspect-ratio")
    Else
        screen = createPaginatedGridScreen(viewController, names, keys, loader, "two-row-flat-landscape-custom")
    End If

    screen.displayDescription = (firstOf(RegUserRead("tvDescription"), "0")).ToInt()

    return screen

End Function

Function getTvGenreScreenUrl(row as Integer, id as String) as String

	genre = id

    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"

    ' Query
    query = {
        IncludeItemTypes: "Series"
        fields: "Overview"
        sortby: "SortName"
        sortorder: "Ascending",
		genres: genre
    }

	for each key in query
		url = url + "&" + key +"=" + HttpEncode(query[key])
	end for

    return url

End Function

Function parseTvGenreScreenResult(row as Integer, id as string, startIndex as Integer, json as String) as Object

	imageType      = (firstOf(RegUserRead("tvImageType"), "0")).ToInt()

    return parseItemsResponse(json, imageType, "mixed-aspect-ratio-portrait")

End Function

'******************************************************
' createTvAlphabetScreen
'******************************************************

Function createTvAlphabetScreen(viewController as Object, letter As String) As Object

    imageType      = (firstOf(RegUserRead("tvImageType"), "0")).ToInt()

	names = ["Shows"]
	keys = [letter]

	loader = CreateObject("roAssociativeArray")
	loader.getUrl = getTvAlphabetScreenUrl
	loader.parsePagedResult = parseTvAlphabetScreenResult

    if imageType = 0 then
        screen = createPaginatedGridScreen(viewController, names, keys, loader, "mixed-aspect-ratio")
    Else
        screen = createPaginatedGridScreen(viewController, names, keys, loader, "two-row-flat-landscape-custom")
    End If

	screen.displayDescription = (firstOf(RegUserRead("tvDescription"), "0")).ToInt()

    return screen

End Function

Function getTvAlphabetScreenUrl(row as Integer, id as String) as String

	letter = id

    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"

    ' Query
    query = {
        IncludeItemTypes: "Series"
        fields: "Overview"
        sortby: "SortName"
        sortorder: "Ascending"
    }

    if letter = "#" then
        filters = {
            NameLessThan: "a"
        }
    else
        filters = {
            NameStartsWith: letter
        }
    end if

    if filters <> invalid
        query = AddToQuery(query, filters)
    end if

	for each key in query
		url = url + "&" + key +"=" + HttpEncode(query[key])
	end for

    return url

End Function

Function parseTvAlphabetScreenResult(row as Integer, id as string, startIndex as Integer, json as String) as Object

	imageType      = (firstOf(RegUserRead("tvImageType"), "0")).ToInt()

    return parseItemsResponse(json, imageType, "mixed-aspect-ratio-portrait")

End Function