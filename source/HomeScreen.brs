'**********************************************************
'** createHomeScreen
'**********************************************************

Function createHomeScreen(viewController as Object) as Object

	names = []
	keys = []
	
	If RegRead("prefCollectionsFirstRow") = "yes"
        names.push("Media Folders")
		keys.push("folders")
    End If
    
    names.push("Movies")
	keys.push("movies")
	
	names.push("TV")
	keys.push("tv")
	
	names.push("Live TV")
	keys.push("livetv")
	
	names.push("Music")
	keys.push("music")
	
	names.push("Channels")
	keys.push("channels")
	
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

    screen = createPaginatedGridScreen(viewController, names, keys, loader, "two-row-flat-landscape-custom")

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

Function getHomeScreenLocalData(row as Integer, id as String, startItem as Integer, count as Integer) as Object

	viewController = GetViewController()
	
	if id = "options" then
		return GetOptionButtons(viewController)
	else if id = "movies" 
		return GetMovieButtons(viewController)
	else if id = "tv" 
		return GetTVButtons(viewController)
	else if id = "music" 
		return GetMusicButtons(viewController)
	else if id = "livetv" 
		return GetLiveTVButtons(viewController)
	end If
	
	return invalid

End Function

Function getHomeScreenRowUrl(row as Integer, id as String) as String

    url = GetServerBaseUrl()

    query = {}

	if id = "folders"
	
		url = url  + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?sortby=sortname"
		query.AddReplace("Fields", "PrimaryImageAspectRatio")

	else if id = "channels"
	
		url = url  + "/Channels?userid=" + HttpEncode(getGlobalVar("user").Id)

	end If

	for each key in query
		url = url + "&" + key +"=" + HttpEncode(query[key])
	end for

    return url

End Function

Function parseHomeScreenResult(row as Integer, id as string, json as String) as Object

	if id = "folders" then
		return parseItemsResponse(json, 0, "two-row-flat-landscape-custom")
	else if id = "channels" then
		return parseItemsResponse(json, 1, "two-row-flat-landscape-custom")
		
	end if

	return parseItemsResponse(json, 0, "two-row-flat-landscape-custom")
	
End Function

Function isLiveTvEnabled() as Boolean
    liveTvInfo = getLiveTvInfo()
	
    if liveTvInfo <> invalid
	
        if liveTvInfo.IsEnabled
            if liveTvInfo.EnabledUsers <> invalid
			
                for each enabledUser in liveTvInfo.EnabledUsers
                    if enabledUser = getGlobalVar("user").Id
                        return true
                    end if
                end for
            end if
			
        end if
		
    end if
	
	return false
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
			
			context = m.contentArray[msg.GetIndex()]           
            index = msg.GetData()
            item = context[index]

            if item = invalid then

            Else If item.ContentType = "MovieToggle" Then

				handled = true
                GetNextMovieToggle()
                m.loader.RefreshData()

            Else If item.ContentType = "MovieRefreshSuggested" Then
				
                handled = true
                m.loader.RefreshData()

            Else If item.ContentType = "TVToggle" Then
				
                handled = true

                GetNextTVToggle()
                m.loader.RefreshData()

            Else If item.ContentType = "LiveTVToggle" Then
				
                handled = true

                GetNextLiveTVToggle()
                m.loader.RefreshData()

            Else If item.ContentType = "MusicToggle" Then
				
                handled = true

                GetNextMusicToggle()
                m.loader.RefreshData()

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

Function GetMovieButtons(viewController as Object) As Object

    buttons = [
        {
            Title: "Movie Library"
            ContentType: "MovieLibrary"
            ShortDescriptionLine1: "Movie Library"
            HDPosterUrl: viewController.getThemeImageUrl("hd-movies.jpg")
            SDPosterUrl: viewController.getThemeImageUrl("hd-movies.jpg")
        }
    ]

    switchButton = [
        {
            ContentType: "MovieToggle"
        }
    ]
	
	movieToggle  = (firstOf(RegUserRead("movieToggle"), "2")).ToInt()

    if movieToggle = 1 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-1.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-1.jpg")

        buttons.Append( switchButton )

        suggestedMovies = getSuggestedMovies()
		
        if suggestedMovies <> invalid

            suggestedButton = [
                {
                    ContentType: "MovieRefreshSuggested"
                    ShortDescriptionLine1: "Similar To"
                    ShortDescriptionLine2: suggestedMovies.BaselineItemName
                    HDPosterUrl: viewController.getThemeImageUrl("hd-similar-to.jpg")
                    SDPosterUrl: viewController.getThemeImageUrl("hd-similar-to.jpg")
                }
            ]

            buttons.Append( suggestedButton )
            buttons.Append( suggestedMovies.Items )
        end if

    else if movieToggle = 2 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-2.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-2.jpg")

        buttons.Append( switchButton )

        recentMovies = getMovieLatest()
		
        if recentMovies <> invalid
            buttons.Append( recentMovies.Items )
        end if

    else if movieToggle = 3 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-3.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-3.jpg")

        buttons.Append( switchButton )

        alphaMovies = getAlphabetList("MovieAlphabet")
        if alphaMovies <> invalid
            buttons.Append( alphaMovies.Items )
        end if

    else if movieToggle = 4 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-4.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-4.jpg")

        buttons.Append( switchButton )

        resumeMovies = getMovieResumable()
        if resumeMovies <> invalid
            buttons.Append( resumeMovies.Items )
        end if

    else if movieToggle = 5 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-5.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-5.jpg")

        buttons.Append( switchButton )

        favoriteMovies = getMovieFavorites()
        if favoriteMovies <> invalid
            buttons.Append( favoriteMovies.Items )
        end if

    else if movieToggle = 6 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-6.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-6.jpg")

        buttons.Append( switchButton )

        genresMovies = getMovieGenres(invalid, invalid, true)
        if genresMovies <> invalid
            buttons.Append( genresMovies.Items )
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

Function GetTVButtons(viewController as Object) As Object

    buttons = [
        {
            Title: "TV Library"
            ContentType: "TVLibrary"
            ShortDescriptionLine1: "TV Library"
            HDPosterUrl: viewController.getThemeImageUrl("hd-tv.jpg")
            SDPosterUrl: viewController.getThemeImageUrl("hd-tv.jpg")
        }
    ]

    switchButton = [
        {
            ContentType: "TVToggle"
        }
    ]
	
	tvToggle     = (firstOf(RegUserRead("tvToggle"), "1")).ToInt()

    if tvToggle = 1 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-1.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-1.jpg")

        buttons.Append( switchButton )

        nextUpTV = getTvNextUp(invalid, invalid, true)
        if nextUpTV <> invalid
            buttons.Append( nextUpTV.Items )
        end if

    else if tvToggle = 2 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-2.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-2.jpg")

        buttons.Append( switchButton )

        recentTV = getTvLatest()
        if recentTV <> invalid
            buttons.Append( recentTV.Items )
        end if

    else if tvToggle = 3 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-3.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-3.jpg")

        buttons.Append( switchButton )

        alphaTV = getAlphabetList("TvAlphabet")
        if alphaTV <> invalid
            buttons.Append( alphaTV.Items )
        end if

    else if tvToggle = 4 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-4.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-4.jpg")

        buttons.Append( switchButton )

        resumeTV = getTvResumable()
        if resumeTV <> invalid
            buttons.Append( resumeTV.Items )
        end if

    else if tvToggle = 5 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-5.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-5.jpg")

        buttons.Append( switchButton )

        favoriteShows = getTvFavorites()
        if favoriteShows <> invalid
            buttons.Append( favoriteShows.Items )
        end if

    else if tvToggle = 6 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-6.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-6.jpg")

        buttons.Append( switchButton )

        genresTV = getTvGenres(invalid, invalid, true)
        if genresTV <> invalid
            buttons.Append( genresTV.Items )
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

Function GetLiveTVButtons(viewController as Object) As Object

	if isLiveTvEnabled() <> true then
		Return {
			Items: []
			TotalCount: 0
		}
	end if
	
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
	
	liveTvToggle = (firstOf(RegUserRead("liveTvToggle"), "1")).ToInt()
	
    if liveTvToggle = 1 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-10.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-10.jpg")

        buttons.Append( switchButton )

        whatsOnLiveTv = getCurrentLiveTvPrograms()
		
        if whatsOnLiveTv <> invalid
            buttons.Append( whatsOnLiveTv.Items )
        end if

    else if liveTvToggle = 2 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-11.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-11.jpg")

        buttons.Append( switchButton )

    else if liveTvToggle = 3 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-12.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-12.jpg")

        buttons.Append( switchButton )

        recordingsLiveTv = getLiveTvRecordings()
        if recordingsLiveTv <> invalid
            buttons.Append( recordingsLiveTv.Items )
        end if

    end if

    Return {
		Items: buttons
		TotalCount: buttons.Count()
	}
	
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

Function GetMusicButtons(viewController as Object) As Object

    buttons = [
        {
            Title: "Music Library"
            ContentType: "MusicLibrary"
            ShortDescriptionLine1: "Music Library"
            HDPosterUrl: viewController.getThemeImageUrl("hd-music.jpg")
            SDPosterUrl: viewController.getThemeImageUrl("hd-music.jpg")
        }
    ]

    switchButton = [
        {
            ContentType: "MusicToggle"
        }
    ]
	
	musicToggle  = (firstOf(RegUserRead("musicToggle"), "1")).ToInt()

    ' Latest
    if musicToggle = 1 then
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-7.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-7.jpg")

        buttons.Append( switchButton )

        latestMusic = getMusicLatest()
        if latestMusic <> invalid
            buttons.Append( latestMusic.Items )
        end if

    ' Jump In Album
    else if musicToggle = 2 then
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-8.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-8.jpg")

        buttons.Append( switchButton )

        alphaMusicAlbum = getAlphabetList("MusicAlbumAlphabet")
        if alphaMusicAlbum <> invalid
            buttons.Append( alphaMusicAlbum.Items )
        end if

    ' Jump In Artist
    else if musicToggle = 3 then
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-9.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-9.jpg")

        buttons.Append( switchButton )

        alphaMusicArtist = getAlphabetList("MusicArtistAlphabet")
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
    
	buttons = [
        {
            Title: "Search"
            ContentType: "Search"
            ShortDescriptionLine1: "Search"
            HDPosterUrl: viewController.getThemeImageUrl("hd-search.jpg")
            SDPosterUrl: viewController.getThemeImageUrl("hd-search.jpg")
        },
        {
            Title: "Switch User"
            ContentType: "SwitchUser"
            ShortDescriptionLine1: "Switch User"
            HDPosterUrl: viewController.getThemeImageUrl("hd-switch-user.jpg")
            SDPosterUrl: viewController.getThemeImageUrl("hd-switch-user.jpg")
        },
        {
            Title: "Preferences"
            ContentType: "Preferences"
            ShortDescriptionLine1: "Preferences"
            ShortDescriptionLine2: "Version " + getGlobalVar("channelVersion", "Unknown")
            HDPosterUrl: viewController.getThemeImageUrl("hd-preferences.jpg")
            SDPosterUrl: viewController.getThemeImageUrl("hd-preferences.jpg")
        }
    ]

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

    m.Screen.SetBreadcrumbText(username, CurrentTimeAsString())

End Sub