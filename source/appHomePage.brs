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
    m.movieToggle = ""
    m.tvToggle    = ""
    m.musicToggle = ""

    If RegRead("prefCollectionsFirstRow") = "yes"
        screen.AddRow("Media Collections", "landscape")
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
        screen.AddRow("Media Collections", "landscape")
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

    ' Initialize Movie Metadata
    MovieMetadata = InitMovieMetadata()

    If m.movieToggle = "latest" Then
        switchButton[0].HDPosterUrl = "pkg://images/tiles/hd-toggle-latest.png"
        switchButton[0].SDPosterUrl = "pkg://images/tiles/sd-toggle-latest.png"

        ' Get Latest Unwatched Movies
        recentMovies = MovieMetadata.GetLatest()
        If recentMovies<>invalid
            buttons.Append( switchButton )
            buttons.Append( recentMovies.Items )
        End if

    Else If m.movieToggle = "favorite" Then
        switchButton[0].HDPosterUrl = "pkg://images/tiles/hd-toggle-favorites.png"
        switchButton[0].SDPosterUrl = "pkg://images/tiles/sd-toggle-favorites.png"

        buttons.Append( switchButton )

        ' Get Favorite Movies
        favoriteMovies = MovieMetadata.GetFavorites()
        If favoriteMovies<>invalid
            buttons.Append( favoriteMovies.Items )
        End if

    Else
        switchButton[0].HDPosterUrl = "pkg://images/tiles/hd-toggle-resume.png"
        switchButton[0].SDPosterUrl = "pkg://images/tiles/sd-toggle-resume.png"

        ' Check For Resumable Movies, otherwise default to latest
        resumeMovies = MovieMetadata.GetResumable()
        If resumeMovies<>invalid And resumeMovies.Items.Count() > 0
            buttons.Append( switchButton )
            buttons.Append( resumeMovies.Items )
        Else
            m.movieToggle = "latest"

            ' Override Image
            switchButton[0].HDPosterUrl = "pkg://images/tiles/hd-toggle-latest.png"
            switchButton[0].SDPosterUrl = "pkg://images/tiles/sd-toggle-latest.png"

            ' Get Latest Unwatched Movies
            recentMovies = MovieMetadata.GetLatest()
            If recentMovies<>invalid
                buttons.Append( switchButton )
                buttons.Append( recentMovies.Items )
            End if
        End if

    End If

    Return buttons
End Function


'**********************************************************
'** Get Next Movie Toggle
'**********************************************************

Function GetNextMovieToggle()
    If m.movieToggle = "latest" Then
        m.movieToggle = "favorite"
    Else If m.movieToggle = "favorite" Then
        m.movieToggle = "resume"
    Else
        m.movieToggle = "latest"
    End If
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

    ' Initialize TV Metadata
    TvMetadata = InitTvMetadata()

    If m.tvToggle = "latest" Then
        switchButton[0].HDPosterUrl = "pkg://images/tiles/hd-toggle-latest.png"
        switchButton[0].SDPosterUrl = "pkg://images/tiles/sd-toggle-latest.png"

        ' Get Latest Unwatched TV
        recentTV = TvMetadata.GetLatest()
        If recentTV<>invalid
            buttons.Append( switchButton )
            buttons.Append( recentTV.Items )
        End if

    Else If m.tvToggle = "favorite" Then
        switchButton[0].HDPosterUrl = "pkg://images/tiles/hd-toggle-favorites.png"
        switchButton[0].SDPosterUrl = "pkg://images/tiles/sd-toggle-favorites.png"

        buttons.Append( switchButton )

        ' Get Favorite TV Shows
        favoriteShows = TvMetadata.GetFavorites()
        If favoriteShows<>invalid
            buttons.Append( favoriteShows.Items )
        End if

    Else

        switchButton[0].HDPosterUrl = "pkg://images/tiles/hd-toggle-resume.png"
        switchButton[0].SDPosterUrl = "pkg://images/tiles/sd-toggle-resume.png"

        ' Check For Resumable TV, otherwise default to latest
        resumeTV = TvMetadata.GetResumable()
        If resumeTV<>invalid And resumeTV.Items.Count() > 0
            buttons.Append( switchButton )
            buttons.Append( resumeTV.Items )
        Else
            m.tvToggle = "latest"

            ' Override Image
            switchButton[0].HDPosterUrl = "pkg://images/tiles/hd-toggle-latest.png"
            switchButton[0].SDPosterUrl = "pkg://images/tiles/sd-toggle-latest.png"

            ' Get Latest Unwatched TV
            recentTV = TvMetadata.GetLatest()
            If recentTV<>invalid
                buttons.Append( switchButton )
                buttons.Append( recentTV.Items )
            End if
        End if

    End If

    Return buttons
End Function


'**********************************************************
'** Get Next TV Toggle
'**********************************************************

Function GetNextTVToggle()
    If m.tvToggle = "latest" Then
        m.tvToggle = "favorite"
    Else If m.tvToggle = "favorite" Then
        m.tvToggle = "resume"
    Else
        m.tvToggle = "latest"
    End If
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
