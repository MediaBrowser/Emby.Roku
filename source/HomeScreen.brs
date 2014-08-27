'**********************************************************
'** createHomeScreen
'**********************************************************

Function createHomeScreen(viewController as Object) as Object

	names = []
	keys = []
	
	views = getUserViews()
	
	for each view in views
	
		names.push(view.Title)
		
		key = view.CollectionType + "|" + view.Id + "|" + firstOf(view.HDPosterUrl, "")
		
		keys.push(key)
		
	end for
	
	If RegRead("prefCollectionsFirstRow") <> "yes"
        names.push("Media Folders")
		keys.push("folders")
    End If
	
	names.push("Options")
	keys.push("options")

	loader = CreateObject("roAssociativeArray")
	loader.getUrl = getHomeScreenRowUrl
	loader.parsePagedResult = parseHomeScreenResult
	loader.getLocalData = getHomeScreenLocalData

    screen = createPaginatedGridScreen(viewController, names, keys, loader, "two-row-flat-landscape-custom", 8, 75)

	screen.baseHandleMessage = screen.HandleMessage
	screen.HandleMessage = handleHomeScreenMessage

    screen.OnTimerExpired = homeScreenOnTimerExpired
    screen.SuperActivate = screen.Activate
    screen.Activate = homeScreenActivate

	screen.refreshBreadcrumb = homeRefreshBreadcrumb
	
	screen.baseShow = screen.Show
	screen.Show = showHomeScreen

    screen.clockTimer = createTimer()
    screen.clockTimer.Name = "clock"
    screen.clockTimer.SetDuration(20000, true) ' A little lag is fine here
    viewController.AddTimer(screen.clockTimer, screen)
	
	sendWolToAllServers(m)

    screen.SetDescriptionVisible(false)

	return screen
End Function

Function getUserViews() as Object

	views = []
	
	if getGlobalVar("user") = invalid then return views
	
	url = GetServerBaseUrl() + "/Users/" + getGlobalVar("user").Id + "/Views?fields=PrimaryImageAspectRatio"
	
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()

    response = request.GetToStringWithTimeout(10)
    if response <> invalid
	
        result = parseItemsResponse(response, 0, "two-row-flat-landscape-custom")

		for each i in result.Items
		
			viewType = firstOf(i.CollectionType, "")
			
			' Filter out unsupported views
			if viewType = "movies" or viewType = "music" or viewType = "tvshows" or viewType = "livetv" or viewType = "channels" or viewType = "folders" or viewType = "playlists" then
				views.push(i)
			
			' Treat all other types as folders for now
			else if i.ContentType <> "Channel" then
				viewType = "folders"
				views.push(i)
			end if
		
			' Normalize this
			i.CollectionType = viewType
			
		end for
		
	end if	
	
	return views

End Function

Function getHomeScreenLocalData(row as Integer, id as String, startItem as Integer, count as Integer) as Object

	viewController = GetViewController()
	
	parts = id.tokenize("|")
	id = parts[0]
	parentId = firstOf(parts[1], "")
	viewTileImageUrl = parts[2]
	
	if id = "options" then
		return GetOptionButtons(viewController)
		
	else if id = "movies" 
	
		movieToggle  = (firstOf(RegUserRead("movieToggle"), "2")).ToInt()
		
		' Jump list
		if movieToggle = 3 then
		
			return GetMovieButtons(viewController, movieToggle, parentId, viewTileImageUrl)
		end if
		
	else if id = "tvshows" 
	
		tvToggle  = (firstOf(RegUserRead("tvToggle"), "1")).ToInt()
		
		' Jump list
		if tvToggle = 3 then
		
			return GetTVButtons(viewController, tvToggle, parentId, viewTileImageUrl)
		end if
		
	end If
	
	return invalid

End Function

Function getHomeScreenRowUrl(row as Integer, id as String) as String

    parts = id.tokenize("|")
	id = parts[0]
	parentId = firstOf(parts[1], "")
	
	url = GetServerBaseUrl()

    query = {}

	if id = "folders"
	
		url = url  + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?sortby=sortname"
		query.AddReplace("Fields", "PrimaryImageAspectRatio")
		
	else if id = "playlists"
	
		url = url  + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?sortby=sortname"
		
	else if id = "channels"
	
		url = url  + "/Channels?userid=" + HttpEncode(getGlobalVar("user").Id)

	else if id = "movies"
	
		movieToggle  = (firstOf(RegUserRead("movieToggle"), "1")).ToInt()

		' Next Up
		if movieToggle = 1 then
			
			url = url + "/Movies/Recommendations?userId=" + HttpEncode(getGlobalVar("user").Id)
			
			query = {
				ItemLimit: "20"
				CategoryLimit: "1"
				fields: "PrimaryImageAspectRatio"
			}
			
		' Latest
		else if movieToggle = 2 then
			
			url = url + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?IncludeItemTypes=Movie"
			query = {
				recursive: "true"
				ExcludeLocationTypes: "Virtual"
				fields: "PrimaryImageAspectRatio"
				sortby: "DateCreated"
				sortorder: "Descending"
				filters: "IsUnplayed"
			}
			
		' Resume
		else if movieToggle = 4 then
			
			url = url + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?includeitemtypes=Movie"
			query = {
				recursive: "true"
				fields: "PrimaryImageAspectRatio"
				sortby: "DatePlayed"
				sortorder: "Descending"
				filters: "IsResumable"
			}
			
		' Favorites
		else if movieToggle = 5 then
			
			url = url + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?includeitemtypes=Movie"
			query = {
				recursive: "true"
				fields: "PrimaryImageAspectRatio"
				sortby: "SortName"
				sortorder: "Ascending"
				filters: "IsFavorite"
			}
			
		' Genres
		else if movieToggle = 6 then
			
			url = url + "/Genres?Recursive=true"
			query = {
				userid: getGlobalVar("user").Id
				includeitemtypes: "Movie"
				fields: "PrimaryImageAspectRatio"
				sortby: "SortName"
				sortorder: "Ascending"
			}
			
		end if		
		
	else if id = "tvshows"
	
		tvToggle  = (firstOf(RegUserRead("tvToggle"), "1")).ToInt()

		' Next Up
		if tvToggle = 1 then
			
			url = url + "/Shows/NextUp?userId=" + HttpEncode(getGlobalVar("user").Id)
			
			query = {
				fields: "PrimaryImageAspectRatio,Overview"
			}
			
		' Latest
		else if tvToggle = 2 then
			
			url = url + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?IncludeItemTypes=Episode"
			query = {
				recursive: "true"
				ExcludeLocationTypes: "Virtual"
				fields: "PrimaryImageAspectRatio"
				sortby: "DateCreated"
				sortorder: "Descending"
				filters: "IsUnplayed"
			}
			
		' Resume
		else if tvToggle = 4 then
			
			url = url + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?includeitemtypes=Episode"
			query = {
				recursive: "true"
				fields: "PrimaryImageAspectRatio"
				sortby: "DatePlayed"
				sortorder: "Descending"
				filters: "IsResumable"
			}
			
		' Favorites
		else if tvToggle = 5 then
			
			url = url + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?includeitemtypes=Series"
			query = {
				recursive: "true"
				fields: "PrimaryImageAspectRatio"
				sortby: "SortName"
				sortorder: "Ascending"
				filters: "IsFavorite"
			}
			
		' Genres
		else if tvToggle = 6 then
			
			url = url + "/Genres?Recursive=true"
			query = {
				userid: getGlobalVar("user").Id
				includeitemtypes: "Series"
				fields: "PrimaryImageAspectRatio"
				sortby: "SortName"
				sortorder: "Ascending"
			}
			
		end if		
		
	else if id = "livetv"
	
		liveTvToggle = (firstOf(RegUserRead("liveTvToggle"), "1")).ToInt()

		' Suggested
		if liveTvToggle = 1 then
			
			url = url + "/LiveTv/Programs/Recommended?userId=" + HttpEncode(getGlobalVar("user").Id)
			query = {
				IsAiring: "true"
			}
			
		' Favorites
		else if liveTvToggle = 2 then
			
			url = url + "/LiveTv/Channels?userId=" + HttpEncode(getGlobalVar("user").Id)
			query = {
				IsFavorite: "true"
			}
			
		' Resume
		else if liveTvToggle = 3 then
			
			url = url + "/LiveTv/Recordings?userId=" + HttpEncode(getGlobalVar("user").Id)
			query = {
				IsInProgress: "false"
			}
			
		end if		
		
	else if id = "music"
	
		musicToggle  = (firstOf(RegUserRead("musicToggle"), "1")).ToInt()

		' Latest
		if musicToggle = 1 then
			
			url = url + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?includeitemtypes=MusicAlbum"		
			query = {
				recursive: "true"
				fields: "PrimaryImageAspectRatio"
				sortby: "DateCreated"
				sortorder: "Descending"
			}
		
		else
		
			' Not going to use the output, just checking to see if the user has music in their library
			url = url + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?includeitemtypes=Audio"		
			query = {
				recursive: "true"
				fields: "PrimaryImageAspectRatio"
				sortby: "DateCreated"
				sortorder: "Descending"
			}
		
			
		end if		
		
	end If
	
	if id <> "channels" and id <> "livetv" and parentId <> "" then
		
		query.AddReplace("ParentId", parentId)
	end if

	for each key in query
		url = url + "&" + key +"=" + HttpEncode(query[key])
	end for

    return url

End Function

Function parseHomeScreenResult(row as Integer, id as string, startIndex as Integer, json as String) as Object

	viewController = GetViewController()
	maxListSize = 60
	
	parts = id.tokenize("|")
	id = parts[0]
	parentId = firstOf(parts[1], "")
	viewTileImageUrl = parts[2]
	
	if id = "folders" then
		return parseItemsResponse(json, 0, "two-row-flat-landscape-custom")
	else if id = "playlists" then
		return parseItemsResponse(json, 1, "two-row-flat-landscape-custom")
	else if id = "channels" then
		return parseItemsResponse(json, 1, "two-row-flat-landscape-custom")
		
	else if id = "movies" then
	
		movieToggle  = (firstOf(RegUserRead("movieToggle"), "1")).ToInt()		
		
		if movieToggle = 1 then
			response = parseSuggestedMoviesResponse(json)
		else if movieToggle = 6 then
			response = parseItemsResponse(json, 1, "mixed-aspect-ratio-portrait", "moviegenre")
		else
			response = parseItemsResponse(json, 1, "two-row-flat-landscape-custom")
		end if
		
		buttons = GetBaseMovieButtons(viewController, movieToggle, parentId, viewTileImageUrl, response)
		buttonCount = buttons.Count()
		minTotalRecordCount = buttonCount + response.Items.Count()
		
		' Only insert buttons if startIndex = 0
		if startIndex = 0 then						
			buttons.Append(response.Items)		
			response.Items = buttons
		end if
		
		if response.TotalCount > maxListSize then response.TotalCount = maxListSize	
		if response.TotalCount < minTotalRecordCount then response.TotalCount = minTotalRecordCount	
		return response
		
	else if id = "tvshows" then
	
		tvToggle  = (firstOf(RegUserRead("tvToggle"), "1")).ToInt()		
		
		if tvToggle = 5 then
			response = parseItemsResponse(json, 1, "two-row-flat-landscape-custom")
		else if tvToggle = 6 then
			response = parseItemsResponse(json, 1, "mixed-aspect-ratio-portrait", "tvgenre")
		else
			response = parseItemsResponse(json, 0, "two-row-flat-landscape-custom")
		end if
		
		buttons = GetBaseTVButtons(viewController, tvToggle, parentId, viewTileImageUrl)
		buttonCount = buttons.Count()
		minTotalRecordCount = buttonCount + response.Items.Count()
		
		' Only insert buttons if startIndex = 0
		if startIndex = 0 then						
			buttons.Append(response.Items)		
			response.Items = buttons
		end if
		
		if response.TotalCount > maxListSize then response.TotalCount = maxListSize	
		if response.TotalCount < minTotalRecordCount then response.TotalCount = minTotalRecordCount	
		return response
		
	else if id = "livetv" then
	
		liveTvToggle = (firstOf(RegUserRead("liveTvToggle"), "1")).ToInt()
		
		if liveTvToggle = 1 then
			response = parseLiveTvProgramsResponse(json)
		else if liveTvToggle = 2 then
			response = parseLiveTvChannelsResult(json)
		else
			response = parseLiveTvRecordingsResponse(json)
		end if
		
		buttons = GetBaseLiveTVButtons(viewController, liveTvToggle)
		buttonCount = buttons.Count()
		minTotalRecordCount = buttonCount + response.Items.Count()
		
		' Only insert buttons if startIndex = 0
		if startIndex = 0 then						
			buttons.Append(response.Items)		
			response.Items = buttons
		end if
		
		if response.TotalCount > maxListSize then response.TotalCount = maxListSize	
		if response.TotalCount < minTotalRecordCount then response.TotalCount = minTotalRecordCount	
		return response
		
	else if id = "music" then
	
		response = parseItemsResponse(json, 0, "mixed-aspect-ratio-square")
		
		if response.TotalCount = 0 then
			Return {
				Items: []
				TotalCount: 0
			}
		end if    
	
		musicToggle  = (firstOf(RegUserRead("musicToggle"), "1")).ToInt()		
		
		if musicToggle <> 1 then
			return GetMusicButtons(viewController, musicToggle, parentId, viewTileImageUrl)
		end if
		
		buttons = GetBaseMusicButtons(viewController, musicToggle, parentId, viewTileImageUrl)
		buttonCount = buttons.Count()
		minTotalRecordCount = buttonCount + response.Items.Count()
		
		' Only insert buttons if startIndex = 0
		if startIndex = 0 then
			buttons.Append(response.Items)		
			response.Items = buttons
		end if
		
		if response.TotalCount > maxListSize then response.TotalCount = maxListSize	
		if response.TotalCount < minTotalRecordCount then response.TotalCount = minTotalRecordCount	
		return response
		
	end if

	return parseItemsResponse(json, 0, "two-row-flat-landscape-custom")
	
End Function

'**********************************************************
'** handleHomeScreenMessage
'**********************************************************

Sub showHomeScreen()

	m.baseShow()
	
	if firstOf(RegRead("prefServerUpdates"), "yes") = "yes" then
	
    serverInfo = getServerInfo()
		if serverInfo <> invalid
		
			if serverInfo.HasPendingRestart And serverInfo.CanSelfRestart
			
				showServerUpdateDialog()
				
			end if
			
		end if
	end if
	
	
End Sub

Function handleHomeScreenMessage(msg) as Boolean

	handled = false

	viewController = m.ViewController

	if type(msg) = "roGridScreenEvent" Then

        if msg.isListItemSelected() Then
			
			rowIndex = msg.GetIndex()
			context = m.contentArray[rowIndex]           
            index = msg.GetData()
            item = context[index]

            if item = invalid then

            Else If item.ContentType = "MovieToggle" Then

				handled = true
                GetNextMovieToggle()
                m.loader.RefreshRow(rowIndex)

            Else If item.ContentType = "MovieRefreshSuggested" Then
				
                handled = true
                m.loader.RefreshRow(rowIndex)

            Else If item.ContentType = "TVToggle" Then
				
                handled = true

                GetNextTVToggle()
                m.loader.RefreshRow(rowIndex)

            Else If item.ContentType = "LiveTVToggle" Then
				
                handled = true

                GetNextLiveTVToggle()
                m.loader.RefreshRow(rowIndex)

            Else If item.ContentType = "MusicToggle" Then
				
                handled = true

                GetNextMusicToggle()
                m.loader.RefreshRow(rowIndex)

            End If
				
        End If
			
    End If

	return handled or m.baseHandleMessage(msg)

End Function

'**********************************************************
'** GetNextMovieToggle
'**********************************************************

Function GetNextMovieToggle()

	movieToggle  = (firstOf(RegUserRead("movieToggle"), "2")).ToInt()
	
    movieToggle = movieToggle + 1

    if movieToggle = 7 then
        movieToggle = 1
    end if

    RegUserWrite("movieToggle", movieToggle)
	
End Function

'**********************************************************
'** Get GetMovieButtons
'**********************************************************

Function GetBaseMovieButtons(viewController as Object, movieToggle as Integer, parentId as String, allTileImageUrl = invalid, movieResponse = invalid) As Object

	if firstOf(allTileImageUrl, "") = "" then
		allTileImageUrl = viewController.getThemeImageUrl("hd-movies.jpg")
	end if
	
	buttons = [
        {
            Title: "Movie Library"
            ContentType: "MovieLibrary"
            ShortDescriptionLine1: "Library"
            HDPosterUrl: allTileImageUrl
            SDPosterUrl: allTileImageUrl,
			Id: parentId
        }
    ]

    switchButton = [
        {
            ContentType: "MovieToggle"
        }
    ]

    if movieToggle = 1 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-1.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-1.jpg")
        buttons.Append( switchButton )

        suggestedButton = [
                {
                    ContentType: "MovieRefreshSuggested"
                    ShortDescriptionLine1: "Similar To"
                    ShortDescriptionLine2: movieResponse.BaselineItemName
                    HDPosterUrl: viewController.getThemeImageUrl("hd-similar-to.jpg")
                    SDPosterUrl: viewController.getThemeImageUrl("hd-similar-to.jpg")
                }
            ]

        buttons.Append( suggestedButton )

    else if movieToggle = 2 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-2.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-2.jpg")
		buttons.Append( switchButton )

    else if movieToggle = 3 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-3.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-3.jpg")
		buttons.Append( switchButton )

    else if movieToggle = 4 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-4.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-4.jpg")
		buttons.Append( switchButton )

    else if movieToggle = 5 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-5.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-5.jpg")
		buttons.Append( switchButton )

    else if movieToggle = 6 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-6.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-6.jpg")
		buttons.Append( switchButton )

    end if
	
	return buttons
    
End Function

Function GetMovieButtons(viewController as Object, movieToggle as Integer, parentId as String, allTileImageUrl = invalid) As Object

    buttons = GetBaseMovieButtons(viewController, movieToggle, parentId, allTileImageUrl)

    if movieToggle = 3 then
	
        alphaMovies = getAlphabetList("MovieAlphabet", parentId)
        if alphaMovies <> invalid
            buttons.Append( alphaMovies.Items )
        end if

    end if

    Return {
		Items: buttons
		TotalCount: buttons.Count()
	}
	
End Function

'**********************************************************
'** Get Next TV Toggle
'**********************************************************

Function GetNextTVToggle()

	tvToggle     = (firstOf(RegUserRead("tvToggle"), "1")).ToInt()
	
    tvToggle = tvToggle + 1

    if tvToggle = 7 then
        tvToggle = 1
    end if

    RegUserWrite("tvToggle", tvToggle)
	
End Function

'**********************************************************
'** Get TV Buttons Row
'**********************************************************

Function GetBaseTVButtons(viewController as Object, tvToggle as Integer, parentId as String, allTileImageUrl = invalid) As Object

    if firstOf(allTileImageUrl, "") = "" then
		allTileImageUrl = viewController.getThemeImageUrl("hd-tv.jpg")
	end if
	
	buttons = [
        {
            Title: "TV Library"
            ContentType: "TVLibrary"
            ShortDescriptionLine1: "Library"
            HDPosterUrl: allTileImageUrl
            SDPosterUrl: allTileImageUrl,
			Id: parentId
        }
    ]

	switchButton = [
        {
            ContentType: "TVToggle"
        }
    ]

    if tvToggle = 1 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-1.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-1.jpg")

    else if tvToggle = 2 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-2.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-2.jpg")

    else if tvToggle = 3 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-3.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-3.jpg")

    else if tvToggle = 4 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-4.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-4.jpg")

    else if tvToggle = 5 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-5.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-5.jpg")

    else if tvToggle = 6 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-6.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-6.jpg")

    end if

    buttons.Append( switchButton )
	
	return buttons
	
End Function

Function GetTVButtons(viewController as Object, tvToggle as Integer, parentId as String, allTileImageUrl = invalid) As Object

    buttons = GetBaseTVButtons(viewController, tvToggle, parentId, allTileImageUrl)

    if tvToggle = 3 then
	
        alphaTV = getAlphabetList("TvAlphabet", parentId)
        if alphaTV <> invalid
            buttons.Append( alphaTV.Items )
        end if

    end if

    Return {
		Items: buttons
		TotalCount: buttons.Count()
	}
	
End Function

'**********************************************************
'** Get Next Live TV Toggle
'**********************************************************

Function GetNextLiveTVToggle()

	liveTvToggle = (firstOf(RegUserRead("liveTvToggle"), "1")).ToInt()
    liveTvToggle = liveTvToggle + 1

    if liveTvToggle = 4 then
        liveTvToggle = 1
    end if

    RegUserWrite("liveTvToggle", liveTvToggle)
	
End Function

'**********************************************************
'** Get Live TV Buttons Row
'**********************************************************

Function GetBaseLiveTVButtons(viewController as Object, liveTvToggle as Integer) As Object

	buttons = [
        {
            Title: "Channels"
            ContentType: "LiveTVChannels"
            ShortDescriptionLine1: "Channels"
            HDPosterUrl: viewController.getThemeImageUrl("hd-tv.jpg")
            SDPosterUrl: viewController.getThemeImageUrl("hd-tv.jpg")
        },
        {
            Title: "Recordings"
            ContentType: "LiveTVRecordings"
            ShortDescriptionLine1: "Recordings"
            HDPosterUrl: viewController.getThemeImageUrl("hd-tv.jpg")
            SDPosterUrl: viewController.getThemeImageUrl("hd-tv.jpg")
        }
    ]

    switchButton = [
        {
            ContentType: "LiveTVToggle"
        }
    ]
	
    if liveTvToggle = 1 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-10.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-10.jpg")

        buttons.Append( switchButton )

    else if liveTvToggle = 2 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-11.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-11.jpg")

        buttons.Append( switchButton )

    else if liveTvToggle = 3 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-12.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-12.jpg")

        buttons.Append( switchButton )

    end if

	return buttons
	
End Function

'**********************************************************
'** GetNextMusicToggle
'**********************************************************

Function GetNextMusicToggle()

	musicToggle  = (firstOf(RegUserRead("musicToggle"), "1")).ToInt()
	
    musicToggle = musicToggle + 1

    if musicToggle = 4 then
        musicToggle = 1
    end if

    ' Update Registry
    RegUserWrite("musicToggle", musicToggle)
	
End Function

'**********************************************************
'** GetMusicButtons
'**********************************************************

Function GetBaseMusicButtons(viewController as Object, musicToggle as Integer, parentId as String, allTileImageUrl = invalid) As Object

    if firstOf(allTileImageUrl, "") = "" then
		allTileImageUrl = viewController.getThemeImageUrl("hd-music.jpg")
	end if
	
	buttons = [
        {
            Title: "Music Library"
            ContentType: "MusicLibrary"
            ShortDescriptionLine1: "Library"
            HDPosterUrl: allTileImageUrl
            SDPosterUrl: allTileImageUrl,
			Id: parentId
        }
    ]

	switchButton = {
            ContentType: "MusicToggle"
        }

    ' Latest
    if musicToggle = 1 then
	
        switchButton.HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-7.jpg")
        switchButton.SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-7.jpg")

    ' Jump In Album
    else if musicToggle = 2 then
	
        switchButton.HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-8.jpg")
        switchButton.SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-8.jpg")

    ' Jump In Artist
    else if musicToggle = 3 then
        switchButton.HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-9.jpg")
        switchButton.SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-9.jpg")

    end if

    buttons.Push( switchButton )
	
	return buttons
End Function

Function GetMusicButtons(viewController as Object, musicToggle as Integer, parentId as String, allTileImageUrl = invalid) As Object

	buttons = GetBaseMusicButtons(viewController, musicToggle, parentId, allTileImageUrl)

    ' Jump In Album
    if musicToggle = 2 then
        
		alphaMusicAlbum = getAlphabetList("MusicAlbumAlphabet", parentId)
        if alphaMusicAlbum <> invalid
            buttons.Append( alphaMusicAlbum.Items )
        end if

    ' Jump In Artist
    else if musicToggle = 3 then
        
		alphaMusicArtist = getAlphabetList("MusicArtistAlphabet", parentId)
        if alphaMusicArtist <> invalid
            buttons.Append( alphaMusicArtist.Items )
        end if

    end if

    Return {
		Items: buttons
		TotalCount: buttons.Count()
	}
	
End Function

'**********************************************************
'** GetOptionButtons
'**********************************************************

Function GetOptionButtons(viewController as Object) As Object
    
	buttons = []
	
	if AudioPlayer().IsPlaying then
		buttons.push({
				Title: "Now Playing"
				ContentType: "NowPlaying"
				ShortDescriptionLine1: "Now Playing"
				HDPosterUrl: viewController.getThemeImageUrl("hd-music.jpg")
				SDPosterUrl: viewController.getThemeImageUrl("hd-music.jpg")
			})
	end if
	
	buttons.push({
            Title: "Search"
            ContentType: "Search"
            ShortDescriptionLine1: "Search"
            HDPosterUrl: viewController.getThemeImageUrl("hd-search.jpg")
            SDPosterUrl: viewController.getThemeImageUrl("hd-search.jpg")
        })
	
	buttons.push({
            Title: "Switch User"
            ContentType: "SwitchUser"
            ShortDescriptionLine1: "Switch User"
            HDPosterUrl: viewController.getThemeImageUrl("hd-switch-user.jpg")
            SDPosterUrl: viewController.getThemeImageUrl("hd-switch-user.jpg")
        })
	
	buttons.push({
            Title: "Preferences"
            ContentType: "Preferences"
            ShortDescriptionLine1: "Preferences"
            ShortDescriptionLine2: "Version " + getGlobalVar("channelVersion", "Unknown")
            HDPosterUrl: viewController.getThemeImageUrl("hd-preferences.jpg")
            SDPosterUrl: viewController.getThemeImageUrl("hd-preferences.jpg")
        })

    Return {
		Items: buttons
		TotalCount: buttons.Count()
	}
	
End Function

Sub homeScreenOnTimerExpired(timer)

    ' if WOL packets were sent, we should reload the homescreen ( send the request again )
    if timer.Name = "WOLsent" then

        if timer.keepAlive = invalid then 
            Debug("WOL packets were sent -- create request to refresh/load data ( only for servers with WOL macs )")
        end if
     
        if timer.keepAlive = true then 
            if GetViewController().genIdleTime <> invalid and GetViewController().genIdleTime.RemainingSeconds() = 0 then 
                Debug("roku is idle: NOT sending keepalive WOL packets")
            else 
                Debug("keepalive WOL packets being sent.")
                sendWolToAllServers(m)
            end if
        'else if server.online and timer.keepAlive = invalid then 
            'Debug("WOL " + tostr(server.name) + " is already online")
        else 
			' Refresh home page data
        end if 

        ' recurring or not, we will make it active until we complete X requests
        timer.active = true
        if timer.count = invalid then timer.count = 0
        timer.count = timer.count+1
        timer.mark()

        ' deactivate after third attempt ( 3 x 3 = 9 seconds after all inital WOL requests )
        if timer.count > 2 then 
            ' convert wolTimer to a keepAlive timer ( 5 minutes )
            timer.keepalive = true
            timer.SetDuration(5*60*1000, false) ' reset timer to 5 minutes - send a WOL request
            timer.mark()
        end if

    end if

    if timer.Name = "clock" AND m.ViewController.IsActiveScreen(m) then
        m.refreshBreadcrumb()
    end if
End Sub

Sub homeScreenActivate(priorScreen)
    m.refreshBreadcrumb()
    m.SuperActivate(priorScreen)
End Sub

Sub homeRefreshBreadcrumb()

	username = ""
	user = getGlobalVar("user")

	if user <> invalid then username = user.Title

	showClock = firstOf(RegRead("prefShowClock"), "yes")

	if showClock = "yes" then
		m.Screen.SetBreadcrumbText(username, CurrentTimeAsString())
	else
		m.Screen.SetBreadcrumbText(username, "")
	end if

End Sub