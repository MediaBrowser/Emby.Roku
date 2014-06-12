'**********************************************************
'** createHomeScreen
'**********************************************************

Function createHomeScreen(viewController as Object) as Object

    screen = CreateGridScreen(viewController, "two-row-flat-landscape-custom")

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

    mediaItemCounts = getMediaItemCounts()

    if mediaItemCounts = invalid
		createErrorDialog("Exit")
        return invalid
    end if

    showLiveTv = isLiveTvEnabled()

    m.movieToggle  = (firstOf(RegUserRead("movieToggle"), "2")).ToInt()
    m.tvToggle     = (firstOf(RegUserRead("tvToggle"), "1")).ToInt()
    m.musicToggle  = (firstOf(RegUserRead("musicToggle"), "1")).ToInt()
    m.liveTvToggle = (firstOf(RegUserRead("liveTvToggle"), "1")).ToInt()

    If RegRead("prefCollectionsFirstRow") = "yes"
        screen.AddRow("Media Folders", "landscape")
    End If
    
    If mediaItemCounts.MovieCount > 0 Then
        screen.AddRow("Movies", "landscape")
    End If

    If mediaItemCounts.SeriesCount > 0 Then
        screen.AddRow("TV", "landscape")
    End If

    If showLiveTv Then
        screen.AddRow("Live TV", "landscape")
    End If

    If mediaItemCounts.SongCount > 0 Then
        screen.AddRow("Music", "landscape")
    End If

    screen.AddRow("Channels", "landscape")

    If RegRead("prefCollectionsFirstRow") = "no" Or RegRead("prefCollectionsFirstRow") = invalid
        screen.AddRow("Media Folders", "landscape")
    End If

    screen.AddRow("Options", "landscape")

    screen.ShowNames()

    If RegRead("prefCollectionsFirstRow") = "yes"
        mediaFolderButtons = GetMediaFolderButtons()
        screen.AddRowContent(mediaFolderButtons)
    End If

    If mediaItemCounts.MovieCount > 0 Then
        moviesButtons = GetMovieButtons(viewController)
        screen.AddRowContent(moviesButtons)
    End If

    If mediaItemCounts.SeriesCount > 0 Then
        tvButtons = GetTVButtons(viewController)
        screen.AddRowContent(tvButtons)
    End If

    If showLiveTv Then
        liveTvButtons = GetLiveTVButtons(viewController)
        screen.AddRowContent(liveTvButtons)
    End If

    If mediaItemCounts.SongCount > 0 Then
        musicButtons = GetMusicButtons(viewController)
        screen.AddRowContent(musicButtons)
    End If

    ' Need to validate
    channelButtons = GetChannelButtons(viewController)
    screen.AddRowContent(channelButtons)

    If firstOf(RegRead("prefCollectionsFirstRow"), "no")  = "no"
	
        mediaFolderButtons = GetMediaFolderButtons()
        screen.AddRowContent(mediaFolderButtons)
		
    End If

    optionButtons = GetOptionButtons(viewController)
    screen.AddRowContent(optionButtons)

    screen.SetDescriptionVisible(false)

	return screen
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

        if msg.isListFocused() then

        else if msg.isListItemSelected() Then
			
			context = m.rowContent[msg.GetIndex()]
            row = msg.GetIndex()
            selection = msg.getData()
			item = context[selection]

			if item = invalid then

            Else If item.ContentType = "MovieToggle" Then

				handled = true

                GetNextMovieToggle()
                moviesButtons = GetMovieButtons(viewController)
                m.UpdateRowContent(row, moviesButtons)

            Else If item.ContentType = "MovieRefreshSuggested" Then
				
                handled = true

                moviesButtons = GetMovieButtons(viewController)
                m.UpdateRowContent(row, moviesButtons)

            Else If item.ContentType = "TVToggle" Then
				
                handled = true

                GetNextTVToggle()
                tvButtons = GetTVButtons(viewController)
                m.UpdateRowContent(row, tvButtons)

            Else If item.ContentType = "LiveTVToggle" Then
				
                handled = true

                GetNextLiveTVToggle()
                liveTvButtons = GetLiveTVButtons(viewController)
                m.UpdateRowContent(row, liveTvButtons)

            Else If item.ContentType = "MusicToggle" Then
				
                handled = true

                GetNextMusicToggle()
                musicButtons = GetMusicButtons(viewController)
                m.UpdateRowContent(row, musicButtons)

            End If
				
        End If
			
    End If


	if handled = false then
		handled = m.baseHandleMessage(msg)
	end If

	return handled

End Function

'**********************************************************
'** GetNextMovieToggle
'**********************************************************

Function GetNextMovieToggle()

    m.movieToggle = m.movieToggle + 1

    if m.movieToggle = 7 then
        m.movieToggle = 1
    end if

    RegUserWrite("movieToggle", m.movieToggle)
	
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

    if m.movieToggle = 1 then
	
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

    else if m.movieToggle = 2 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-2.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-2.jpg")

        buttons.Append( switchButton )

        recentMovies = getMovieLatest()
		
        if recentMovies <> invalid
            buttons.Append( recentMovies.Items )
        end if

    else if m.movieToggle = 3 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-3.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-3.jpg")

        buttons.Append( switchButton )

        alphaMovies = getAlphabetList("MovieAlphabet")
        if alphaMovies <> invalid
            buttons.Append( alphaMovies.Items )
        end if

    else if m.movieToggle = 4 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-4.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-4.jpg")

        buttons.Append( switchButton )

        resumeMovies = getMovieResumable()
        if resumeMovies <> invalid
            buttons.Append( resumeMovies.Items )
        end if

    else if m.movieToggle = 5 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-5.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-5.jpg")

        buttons.Append( switchButton )

        favoriteMovies = getMovieFavorites()
        if favoriteMovies <> invalid
            buttons.Append( favoriteMovies.Items )
        end if

    else if m.movieToggle = 6 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-6.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-6.jpg")

        buttons.Append( switchButton )

        genresMovies = getMovieGenres(invalid, invalid, true)
        if genresMovies <> invalid
            buttons.Append( genresMovies.Items )
        end if

    end if

    Return buttons
	
End Function

'**********************************************************
'** Get Next TV Toggle
'**********************************************************

Function GetNextTVToggle()

    m.tvToggle = m.tvToggle + 1

    if m.tvToggle = 7 then
        m.tvToggle = 1
    end if

    RegUserWrite("tvToggle", m.tvToggle)
	
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

    if m.tvToggle = 1 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-1.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-1.jpg")

        buttons.Append( switchButton )

        nextUpTV = getTvNextUp(invalid, invalid, true)
        if nextUpTV <> invalid
            buttons.Append( nextUpTV.Items )
        end if

    else if m.tvToggle = 2 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-2.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-2.jpg")

        buttons.Append( switchButton )

        recentTV = getTvLatest()
        if recentTV <> invalid
            buttons.Append( recentTV.Items )
        end if

    else if m.tvToggle = 3 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-3.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-3.jpg")

        buttons.Append( switchButton )

        alphaTV = getAlphabetList("TvAlphabet")
        if alphaTV <> invalid
            buttons.Append( alphaTV.Items )
        end if

    else if m.tvToggle = 4 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-4.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-4.jpg")

        buttons.Append( switchButton )

        resumeTV = getTvResumable()
        if resumeTV <> invalid
            buttons.Append( resumeTV.Items )
        end if

    else if m.tvToggle = 5 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-5.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-5.jpg")

        buttons.Append( switchButton )

        favoriteShows = getTvFavorites()
        if favoriteShows <> invalid
            buttons.Append( favoriteShows.Items )
        end if

    else if m.tvToggle = 6 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-6.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-6.jpg")

        buttons.Append( switchButton )

        genresTV = getTvGenres(invalid, invalid, true)
        if genresTV <> invalid
            buttons.Append( genresTV.Items )
        end if

    end if

    Return buttons
	
End Function

'**********************************************************
'** Get Next Live TV Toggle
'**********************************************************

Function GetNextLiveTVToggle()

    m.liveTvToggle = m.liveTvToggle + 1

    if m.liveTvToggle = 4 then
        m.liveTvToggle = 1
    end if

    RegUserWrite("liveTvToggle", m.liveTvToggle)
	
End Function

'**********************************************************
'** Get Live TV Buttons Row
'**********************************************************

Function GetLiveTVButtons(viewController as Object) As Object

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

    if m.liveTvToggle = 1 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-10.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-10.jpg")

        buttons.Append( switchButton )

        whatsOnLiveTv = getCurrentLiveTvPrograms()
		
        if whatsOnLiveTv <> invalid
            buttons.Append( whatsOnLiveTv.Items )
        end if

    else if m.liveTvToggle = 2 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-11.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-11.jpg")

        buttons.Append( switchButton )

    else if m.liveTvToggle = 3 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-12.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-12.jpg")

        buttons.Append( switchButton )

        recordingsLiveTv = getLiveTvRecordings()
        if recordingsLiveTv <> invalid
            buttons.Append( recordingsLiveTv.Items )
        end if

    end if

    Return buttons
	
End Function

'**********************************************************
'** GetNextMusicToggle
'**********************************************************

Function GetNextMusicToggle()

    m.musicToggle = m.musicToggle + 1

    if m.musicToggle = 4 then
        m.musicToggle = 1
    end if

    ' Update Registry
    RegUserWrite("musicToggle", m.musicToggle)
	
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

    ' Latest
    if m.musicToggle = 1 then
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-7.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-7.jpg")

        buttons.Append( switchButton )

        latestMusic = getMusicLatest()
        if latestMusic <> invalid
            buttons.Append( latestMusic.Items )
        end if

    ' Jump In Album
    else if m.musicToggle = 2 then
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-8.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-8.jpg")

        buttons.Append( switchButton )

        alphaMusicAlbum = getAlphabetList("MusicAlbumAlphabet")
        if alphaMusicAlbum <> invalid
            buttons.Append( alphaMusicAlbum.Items )
        end if

    ' Jump In Artist
    else if m.musicToggle = 3 then
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-9.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-9.jpg")

        buttons.Append( switchButton )

        alphaMusicArtist = getAlphabetList("MusicArtistAlphabet")
        if alphaMusicArtist <> invalid
            buttons.Append( alphaMusicArtist.Items )
        end if

    end if

    Return buttons
	
End Function

'**********************************************************
'** GetChannelButtons
'**********************************************************

Function GetChannelButtons(viewController as Object) As Object

    buttons = []

    Channels = GetChannels()
    if Channels <> invalid
        buttons.Append( Channels.Items )
    end if
    
    Return buttons
    
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

    Return buttons
	
End Function

'**********************************************************
'** Get Media Folder Buttons Row
'**********************************************************

Function GetMediaFolderButtons() As Object

    buttons = []

    mediaFoldersList = getMediaFolders()
    If mediaFoldersList <> invalid
        buttons.Append( mediaFoldersList.Items )
    End if

    Return buttons
	
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