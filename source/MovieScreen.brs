'**********************************************************
'** createMovieLibraryScreen
'**********************************************************

Function createMovieLibraryScreen(viewController as Object) As Object

    imageType      = (firstOf(RegUserRead("movieImageType"), "0")).ToInt()

	names = ["Movies", "Jump In", "Collections", "Genres"]
	keys = ["0", "1", "2", "3"]

	loader = CreateObject("roAssociativeArray")
	loader.getUrl = getMovieLibraryRowScreenUrl
	loader.parsePagedResult = parseMovieLibraryScreenResult
	loader.getLocalData = getMovieLibraryScreenLocalData

    if imageType = 0 then
        screen = createPaginatedGridScreen(viewController, names, keys, loader, "mixed-aspect-ratio")
    Else
        screen = createPaginatedGridScreen(viewController, names, keys, loader, "two-row-flat-landscape-custom")
    End If

	screen.baseActivate = screen.Activate
	screen.Activate = movieScreenActivate

	screen.recreateOnActivate = true

    screen.displayDescription = (firstOf(RegUserRead("movieDescription"), "0")).ToInt()

	screen.createContextMenu = movieScreenCreateContextMenu

    return screen

End Function

Sub movieScreenActivate(priorScreen)

    imageType      = (firstOf(RegUserRead("movieImageType"), "0")).ToInt()
	displayDescription = (firstOf(RegUserRead("movieDescription"), "0")).ToInt()
	
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

Function getMovieLibraryScreenLocalData(row as Integer, id as String, startItem as Integer, count as Integer) as Object

	if row = 1 then
		return getAlphabetList("MovieAlphabet")
	end If

    return invalid

End Function

Function getMovieLibraryRowScreenUrl(row as Integer, id as String) as String

    filterBy       = (firstOf(RegUserRead("movieFilterBy"), "0")).ToInt()
    sortBy         = (firstOf(RegUserRead("movieSortBy"), "0")).ToInt()
    sortOrder      = (firstOf(RegUserRead("movieSortOrder"), "0")).ToInt()
    imageType      = (firstOf(RegUserRead("movieImageType"), "0")).ToInt()

    filterByOptions = ["None", "Unwatched", "Watched"]
    sortByOptions   = ["Name", "Date Added", "Date Played", "Release Date"]

    movieFilter = {}

    ' URL
    url = GetServerBaseUrl()

    ' Query
    query = {}

	if row = 0
		url = url  + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"

		if filterBy = 1
			movieFilter.AddReplace("Filters", "IsUnPlayed")
		else if filterBy = 2
			movieFilter.AddReplace("Filters", "IsPlayed")
		end if

		if sortBy = 1
			movieFilter.AddReplace("SortBy", "DateCreated,SortName")
		else if sortBy = 2
			movieFilter.AddReplace("SortBy", "DatePlayed,SortName")
		else if sortBy = 3
			movieFilter.AddReplace("SortBy", "PremiereDate,SortName")
		else
			movieFilter.AddReplace("SortBy", "SortName")
		end if

		if sortOrder = 1
			movieFilter.AddReplace("SortOrder", "Descending")
		end if

		movieFilter.AddReplace("IncludeItemTypes", "Movie")
		movieFilter.AddReplace("Fields", "Overview")

	else if row = 1
		' Alphabet - should never get in here

	else if row = 2
		url = url  + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"

		movieFilter.AddReplace("IncludeItemTypes", "BoxSet")
		movieFilter.AddReplace("Fields", "Overview")
		movieFilter.AddReplace("SortBy", "SortName")

	else if row = 3
		url = url  + "/Genres?recursive=true"

		movieFilter.AddReplace("SortBy", "SortName")
		movieFilter.AddReplace("userid", getGlobalVar("user").Id)
		movieFilter.AddReplace("IncludeItemTypes", "Movie")
	end If

	for each key in movieFilter
		url = url + "&" + key +"=" + HttpEncode(movieFilter[key])
	end for

    return url

End Function

Function parseMovieLibraryScreenResult(row as Integer, json as String) as Object

	imageType      = (firstOf(RegUserRead("movieImageType"), "0")).ToInt()
	primaryImageStyle = "mixed-aspect-ratio-portrait"
	mode = ""

	if row = 3
		mode = "moviegenre"
	end if

    return parseItemsResponse(json, imageType, primaryImageStyle, mode)

End Function

Function movieScreenCreateContextMenu()
	
	createContextMenuDialog("movie")

	return true

End Function

'**********************************************************
'** createMovieAlphabetScreen
'**********************************************************

Function createMovieAlphabetScreen(viewController as Object, letter As String) As Object

    imageType      = (firstOf(RegUserRead("movieImageType"), "0")).ToInt()

	names = ["Movies"]
	keys = [letter]

	loader = CreateObject("roAssociativeArray")
	loader.getUrl = getMovieAlphabetScreenUrl
	loader.parsePagedResult = parseMovieAlphabetScreenResult

    if imageType = 0 then
        screen = createPaginatedGridScreen(viewController, names, keys, loader, "mixed-aspect-ratio")
    Else
        screen = createPaginatedGridScreen(viewController, names, keys, loader, "two-row-flat-landscape-custom")
    End If

	screen.displayDescription = (firstOf(RegUserRead("movieDescription"), "0")).ToInt()

    if screen.displayDescription = 0 then
        screen.SetDescriptionVisible(false)
    end if

    return screen

End Function

Function getMovieAlphabetScreenUrl(row as Integer, id as String) as String

	letter = id

    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"

    ' Query
    query = {
        IncludeItemTypes: "Movie"
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

Function parseMovieAlphabetScreenResult(row as Integer, json as String) as Object

	imageType      = (firstOf(RegUserRead("movieImageType"), "0")).ToInt()

    return parseItemsResponse(json, imageType, "mixed-aspect-ratio-portrait")

End Function


'**********************************************************
'** createMovieGenreScreen
'**********************************************************

Function createMovieGenreScreen(viewController as Object, genre As String) As Object

    imageType      = (firstOf(RegUserRead("movieImageType"), "0")).ToInt()

	names = ["Movies"]
	keys = [genre]

	loader = CreateObject("roAssociativeArray")
	loader.getUrl = getMovieGenreScreenUrl
	loader.parsePagedResult = parseMovieGenreScreenResult

    if imageType = 0 then
        screen = createPaginatedGridScreen(viewController, names, keys, loader, "mixed-aspect-ratio")
    Else
        screen = createPaginatedGridScreen(viewController, names, keys, loader, "two-row-flat-landscape-custom")
    End If

    screen.displayDescription = (firstOf(RegUserRead("movieDescription"), "0")).ToInt()

    if screen.displayDescription = 0 then
        screen.SetDescriptionVisible(false)
    end if

    return screen

End Function

Function getMovieGenreScreenUrl(row as Integer, id as String) as String

	genre = id

    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"

    ' Query
    query = {
        IncludeItemTypes: "Movie"
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

Function parseMovieGenreScreenResult(row as Integer, json as String) as Object

	imageType      = (firstOf(RegUserRead("movieImageType"), "0")).ToInt()

    return parseItemsResponse(json, imageType, "mixed-aspect-ratio-portrait")

End Function