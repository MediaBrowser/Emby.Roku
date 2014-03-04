'*****************************************************************
'**  Media Browser Roku Client - Home Page
'*****************************************************************


'**********************************************************
'** Show Home Page
'**********************************************************

Function ShowHomePage()

    'port = CreateObject("roMessagePort")
    'v = createHomeView(port)
    'v.Show()

    'controller = createController()
    'controller.startUp()
    'controller.eventLoop()
    'Print "after Event loop"

    'return false

    ' Create Grid Screen
    screen = CreateGridScreen("", getGlobalVar("user").Title, "two-row-flat-landscape-custom")

    ' Get Item Counts
    mediaItemCounts = getMediaItemCounts()

    if mediaItemCounts = invalid
        createDialog("Problem Loading", "There was an problem while attempting to get media items from server. Please make sure your server is running and try again.", "Exit")
        return false
    end if

    ' Setup Globals
    m.movieToggle = GetSavedToggle("movie")
    m.tvToggle    = GetSavedToggle("tv")
    m.musicToggle = ""

    If RegRead("prefCollectionsFirstRow") = "yes"
        screen.AddRow("Media Folders", "landscape")
    End If
    
    If mediaItemCounts.MovieCount > 0 Then
        screen.AddRow("Movies", "landscape")
    End If

    If mediaItemCounts.SeriesCount > 0 Then
        screen.AddRow("TV", "landscape")
    End If

    If mediaItemCounts.SongCount > 0 Then
        screen.AddRow("Music", "landscape")
    End If

    If RegRead("prefCollectionsFirstRow") = "no" Or RegRead("prefCollectionsFirstRow") = invalid
        screen.AddRow("Media Folders", "landscape")
    End If

    screen.AddRow("Options", "landscape")

    screen.ShowNames()

    ' Get Data
    If RegRead("prefCollectionsFirstRow") = "yes"
        collectionButtons = GetCollectionButtons()
        screen.AddRowContent(collectionButtons)
    End If

    If mediaItemCounts.MovieCount > 0 Then
        moviesButtons = GetMoviesButtons()
        screen.AddRowContent(moviesButtons)
    End If

    If mediaItemCounts.SeriesCount > 0 Then
        tvButtons = GetTVButtons()
        screen.AddRowContent(tvButtons)
    End If

    If mediaItemCounts.SongCount > 0 Then
        musicButtons = GetMusicButtons()
        screen.AddRowContent(musicButtons)
    End If

    If RegRead("prefCollectionsFirstRow") = "no" Or RegRead("prefCollectionsFirstRow") = invalid
        collectionButtons = GetCollectionButtons()
        screen.AddRowContent(collectionButtons)
    End If

    optionButtons = GetOptionsButtons()
    screen.AddRowContent(optionButtons)

    ' Show Screen
    screen.Show()

    ' Hide Description Popup
    screen.SetDescriptionVisible(false)

    ' Recreate Screen Index
    recreateIndex = 0

    ' Check For Server Restart
    serverInfo = getServerInfo()

    if serverInfo <> invalid
        if serverInfo.HasPendingRestart And serverInfo.CanSelfRestart And (RegRead("prefServerUpdates") = "yes" Or RegRead("prefServerUpdates") = invalid)
            Debug("Checking For Media Browser Server Update")
            if createServerUpdateDialog()
                return false
            end if
        end if
    end if

    while true
        msg = wait(0, screen.Port)

        if type(msg) = "roGridScreenEvent" Then
            if msg.isListFocused() then

            else if msg.isListItemSelected() Then
                row = msg.GetIndex()
                selection = msg.getData()

                Debug("Content type: " + screen.rowContent[row][selection].ContentType)

                If screen.rowContent[row][selection].ContentType = "MovieLibrary" Then
                    ShowMoviesListPage()

                Else If screen.rowContent[row][selection].ContentType = "MovieToggle" Then
                    ' Toggle Movie Display
                    GetNextMovieToggle()
                    moviesButtons = GetMoviesButtons()
                    screen.UpdateRowContent(row, moviesButtons)

                Else If screen.rowContent[row][selection].ContentType = "Movie" Then
                    ShowVideoDetails(screen.rowContent[row][selection].Id)

                Else If screen.rowContent[row][selection].ContentType = "MovieGenre" Then
                    ShowMoviesGenrePage(screen.rowContent[row][selection].Id)

                Else If screen.rowContent[row][selection].ContentType = "TVLibrary" Then
                    ShowTVShowListPage()

                Else If screen.rowContent[row][selection].ContentType = "TVToggle" Then
                    ' Toggle TV Display
                    GetNextTVToggle()
                    tvButtons = GetTVButtons()
                    screen.UpdateRowContent(row, tvButtons)

                Else If screen.rowContent[row][selection].ContentType = "Episode" Then
                    ShowVideoDetails(screen.rowContent[row][selection].Id)

                Else If screen.rowContent[row][selection].ContentType = "Series" Then
                    ShowTVSeasonsListPage(screen.rowContent[row][selection])

                Else If screen.rowContent[row][selection].ContentType = "TvGenre" Then
                    ShowTVShowGenrePage(screen.rowContent[row][selection].Id)

                Else If screen.rowContent[row][selection].ContentType = "MusicLibrary" Then
                    ShowMusicListPage()

                Else If screen.rowContent[row][selection].ContentType = "Collection" Then
                    recreateHomeCollectionPage:
                    recreateIndex = ShowCollectionPage(screen.rowContent[row][selection].Id, screen.rowContent[row][selection].Title, recreateIndex)
                    if recreateIndex >= 0
                        Goto recreateHomeCollectionPage
                    end if

                Else If screen.rowContent[row][selection].ContentType = "SwitchUser" Then
                    RegDelete("userId")
                    Debug("Switch User")
                    return true

                Else If screen.rowContent[row][selection].ContentType = "Preferences" Then
                    ShowPreferencesPage()

                Else 
                    Debug("Unknown Type found")
                End If
            Else If msg.isScreenClosed() Then
                Debug("Close home screen")
                return false
            End If
        end if
    end while

    return false
End Function


'**********************************************************
'** Get Movie Buttons Row
'**********************************************************

Function GetMoviesButtons() As Object
    ' Set the Default movie library button
    buttons = [
        {
            Title: "Movie Library"
            ContentType: "MovieLibrary"
            ShortDescriptionLine1: "Movie Library"
            HDPosterUrl: "pkg://images/tiles/hd-movies.jpg"
            SDPosterUrl: "pkg://images/tiles/sd-movies.jpg"
        }
    ]

    switchButton = [
        {
            Title: "Toggle Movie"
            ContentType: "MovieToggle"
            ShortDescriptionLine1: "Toggle Display"
        }
    ]

    ' Suggested
    if m.movieToggle = 1 then
        switchButton[0].HDPosterUrl = "pkg://images/tiles/hd-toggle-1.jpg"
        switchButton[0].SDPosterUrl = "pkg://images/tiles/sd-toggle-1.jpg"

        buttons.Append( switchButton )

        ''  TODO '''''''''''''''''''''''''''''''''''''''''''

    ' Latest
    else if m.movieToggle = 2 then
        switchButton[0].HDPosterUrl = "pkg://images/tiles/hd-toggle-2.jpg"
        switchButton[0].SDPosterUrl = "pkg://images/tiles/sd-toggle-2.jpg"

        buttons.Append( switchButton )

        ' Get Latest Unwatched Movies
        recentMovies = getMovieLatest()
        if recentMovies <> invalid
            buttons.Append( recentMovies.Items )
        end if

    ' Jump In
    else if m.movieToggle = 3 then
        switchButton[0].HDPosterUrl = "pkg://images/tiles/hd-toggle-3.jpg"
        switchButton[0].SDPosterUrl = "pkg://images/tiles/sd-toggle-3.jpg"

        buttons.Append( switchButton )

        ''  TODO '''''''''''''''''''''''''''''''''''''''''''

    ' Resume
    else if m.movieToggle = 4 then
        switchButton[0].HDPosterUrl = "pkg://images/tiles/hd-toggle-4.jpg"
        switchButton[0].SDPosterUrl = "pkg://images/tiles/sd-toggle-4.jpg"

        buttons.Append( switchButton )

        ' Get Resumable Movies
        resumeMovies = getMovieResumable()
        if resumeMovies <> invalid
            buttons.Append( resumeMovies.Items )
        end if

    ' Favorites
    else if m.movieToggle = 5 then
        switchButton[0].HDPosterUrl = "pkg://images/tiles/hd-toggle-5.jpg"
        switchButton[0].SDPosterUrl = "pkg://images/tiles/sd-toggle-5.jpg"

        buttons.Append( switchButton )

        ' Get Favorite Movies
        favoriteMovies = getMovieFavorites()
        if favoriteMovies <> invalid
            buttons.Append( favoriteMovies.Items )
        end if

    ' Genre
    else if m.movieToggle = 6 then
        switchButton[0].HDPosterUrl = "pkg://images/tiles/hd-toggle-6.jpg"
        switchButton[0].SDPosterUrl = "pkg://images/tiles/sd-toggle-6.jpg"

        buttons.Append( switchButton )

        ' Get Movie Genres
        genresMovies = getMovieGenres(invalid, invalid, true)
        if genresMovies <> invalid
            buttons.Append( genresMovies.Items )
        end if

    end if

    Return buttons
End Function


'**********************************************************
'** Get Next Movie Toggle
'**********************************************************

Function GetNextMovieToggle()
    m.movieToggle = m.movieToggle + 1

    if m.movieToggle = 7 then
        m.movieToggle = 1
    end if

    ' Update Registry
    SaveToggle("movie", m.movieToggle)
End Function


'**********************************************************
'** Get TV Buttons Row
'**********************************************************

Function GetTVButtons() As Object
    ' Set the Default movie library button
    buttons = [
        {
            Title: "TV Library"
            ContentType: "TVLibrary"
            ShortDescriptionLine1: "TV Library"
            HDPosterUrl: "pkg://images/tiles/hd-tv.jpg"
            SDPosterUrl: "pkg://images/tiles/sd-tv.jpg"
        }
    ]

    switchButton = [
        {
            Title: "Toggle TV"
            ContentType: "TVToggle"
            ShortDescriptionLine1: "Toggle Display"
        }
    ]

    ' Suggested
    if m.tvToggle = 1 then
        switchButton[0].HDPosterUrl = "pkg://images/tiles/hd-toggle-1.jpg"
        switchButton[0].SDPosterUrl = "pkg://images/tiles/sd-toggle-1.jpg"

        buttons.Append( switchButton )

        ' Get Next Episodes To Watch
        nextUpTV = getTvNextUp(invalid, invalid, true)
        if nextUpTV <> invalid
            buttons.Append( nextUpTV.Items )
        end if

    ' Latest
    else if m.tvToggle = 2 then
        switchButton[0].HDPosterUrl = "pkg://images/tiles/hd-toggle-2.jpg"
        switchButton[0].SDPosterUrl = "pkg://images/tiles/sd-toggle-2.jpg"

        buttons.Append( switchButton )

        ' Get Latest Unwatched TV
        recentTV = getTvLatest()
        if recentTV <> invalid
            buttons.Append( recentTV.Items )
        end if

    ' Jump In
    else if m.tvToggle = 3 then
        switchButton[0].HDPosterUrl = "pkg://images/tiles/hd-toggle-3.jpg"
        switchButton[0].SDPosterUrl = "pkg://images/tiles/sd-toggle-3.jpg"

        buttons.Append( switchButton )

        ''  TODO '''''''''''''''''''''''''''''''''''''''''''

    ' Resume
    else if m.tvToggle = 4 then
        switchButton[0].HDPosterUrl = "pkg://images/tiles/hd-toggle-4.jpg"
        switchButton[0].SDPosterUrl = "pkg://images/tiles/sd-toggle-4.jpg"

        buttons.Append( switchButton )

        ' Get Resumable TV
        resumeTV = getTvResumable()
        if resumeTV <> invalid
            buttons.Append( resumeTV.Items )
        end if

    ' Favorites
    else if m.tvToggle = 5 then
        switchButton[0].HDPosterUrl = "pkg://images/tiles/hd-toggle-5.jpg"
        switchButton[0].SDPosterUrl = "pkg://images/tiles/sd-toggle-5.jpg"

        buttons.Append( switchButton )

        ' Get Favorite TV Shows
        favoriteShows = getTvFavorites()
        if favoriteShows <> invalid
            buttons.Append( favoriteShows.Items )
        end if

    ' Genre
    else if m.tvToggle = 6 then
        switchButton[0].HDPosterUrl = "pkg://images/tiles/hd-toggle-6.jpg"
        switchButton[0].SDPosterUrl = "pkg://images/tiles/sd-toggle-6.jpg"

        buttons.Append( switchButton )

        ' Get TV Show Genres
        genresTV = getTvGenres(invalid, invalid, true)
        if genresTV <> invalid
            buttons.Append( genresTV.Items )
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

    ' Update Registry
    SaveToggle("tv", m.tvToggle)
End Function


'**********************************************************
'** Get Music Buttons Row
'**********************************************************

Function GetMusicButtons() As Object
    ' Set the Default Music library button
    buttons = [
        {
            Title: "Music Library"
            ContentType: "MusicLibrary"
            ShortDescriptionLine1: "Music Library"
            HDPosterUrl: "pkg://images/tiles/hd-music.jpg"
            SDPosterUrl: "pkg://images/tiles/sd-music.jpg"
        }
    ]

    switchButton = [
        {
            Title: "Toggle Music"
            ContentType: "MusicToggle"
            ShortDescriptionLine1: "Toggle Display"
        }
    ]

    Return buttons
End Function


'**********************************************************
'** Get Collection Buttons Row
'**********************************************************

Function GetCollectionButtons() As Object

    ' Set the collection library button
    buttons = []

    ' Initialize Collection Metadata
    CollectionMetadata = InitCollectionMetadata()

    ' Get Collection List
    collectionList = CollectionMetadata.GetCollectionList()
    If collectionList <> invalid
        buttons.Append( collectionList )
    End if

    Return buttons
End Function


'**********************************************************
'** Get Options Buttons Row
'**********************************************************

Function GetOptionsButtons() As Object
    ' Set the Options buttons
    buttons = [
        {
            Title: "Switch User"
            ContentType: "SwitchUser"
            ShortDescriptionLine1: "Switch User"
            HDPosterUrl: "pkg://images/tiles/hd-switch-user.jpg"
            SDPosterUrl: "pkg://images/tiles/sd-switch-user.jpg"
        },
        {
            Title: "Preferences"
            ContentType: "Preferences"
            ShortDescriptionLine1: "Preferences"
            ShortDescriptionLine2: "Version " + getGlobalVar("channelVersion", "Unknown")
            HDPosterUrl: "pkg://images/tiles/hd-preferences.jpg"
            SDPosterUrl: "pkg://images/tiles/sd-preferences.jpg"
        }
    ]

    Return buttons
End Function

'**********************************************************
'** Get Saved Toggle
'**********************************************************

Function GetSavedToggle(toggle As String) As Integer

    if toggle = "movie"
        regToggle = RegRead("movieToggle")
    else if toggle = "tv"
        regToggle = RegRead("tvToggle")
    end if

    ' Check For Empty
    if regToggle = invalid then return 1

    ' Convert To Array
    savedToggles = RegistryStringToArray(regToggle)

    if savedToggles.DoesExist(getGlobalVar("user").Id)
        toggleValue = (savedToggles[getGlobalVar("user").Id]).ToInt()
    else
        toggleValue = 1
    end if

    return toggleValue
End Function

'**********************************************************
'** Save Toggle Value
'**********************************************************

Function SaveToggle(toggle As String, toggleValue = Integer) As Boolean

    if toggle = "movie"
        regToggle = RegRead("movieToggle")
    else if toggle = "tv"
        regToggle = RegRead("tvToggle")
    end if

    ' Check For Empty
    if regToggle = invalid then regToggle = ""

    ' Convert To Array
    savedToggles = RegistryStringToArray(regToggle)

    ' Update Array
    savedToggles.AddReplace(getGlobalVar("user").Id, toggleValue)

    ' Convert To String
    str = RegistryArrayToString(savedToggles)

    if toggle = "movie"
        RegWrite("movieToggle", str)
    else if toggle = "tv"
        RegWrite("tvToggle", str)
    end if

    return true
End Function
