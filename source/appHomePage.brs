'*****************************************************************
'**  Media Browser Roku Client - Home Page
'*****************************************************************


'**********************************************************
'** Show Home Page
'**********************************************************

Function ShowHomePage()

    ' Create Grid Screen
    screen = CreateGridScreen("", m.curUserProfile.Title, "two-row-flat-landscape-custom")

    ' Get Item Counts
    itemCounts = GetItemCounts()

    If itemCounts=invalid Then
        ShowError("Error", "Could Not Get Data From Server")
        return false
    End If

    ' Setup Globals
    m.movieToggle = ""
    m.tvToggle    = ""
    m.musicToggle = ""

    If itemCounts.MovieCount > 0 Then
        screen.AddRow("Movies", "landscape")
    End If

    If itemCounts.SeriesCount > 0 Then
        screen.AddRow("TV", "landscape")
    End If

    If itemCounts.SongCount > 0 Then
        screen.AddRow("Music", "landscape")
    End If

    screen.AddRow("Options", "landscape")

    screen.ShowNames()

    ' Get Data
    If itemCounts.MovieCount > 0 Then
        moviesButtons = GetMoviesButtons()
        screen.AddRowContent(moviesButtons)
    End If

    If itemCounts.SeriesCount > 0 Then
        tvButtons = GetTVButtons()
        screen.AddRowContent(tvButtons)
    End If

    If itemCounts.SongCount > 0 Then
        musicButtons = GetMusicButtons()
        screen.AddRowContent(musicButtons)
    End If

    optionButtons = GetOptionsButtons()
    screen.AddRowContent(optionButtons)

    ' Show Screen
    screen.Show()

    ' Hide Description Popup
    screen.SetDescriptionVisible(false)

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
                    ShowMoviesDetailPage(screen.rowContent[row][selection].Id)

                Else If screen.rowContent[row][selection].ContentType = "TVLibrary" Then
                    ShowTVShowListPage()

                Else If screen.rowContent[row][selection].ContentType = "TVToggle" Then
                    ' Toggle TV Display
                    GetNextTVToggle()
                    tvButtons = GetTVButtons()
                    screen.UpdateRowContent(row, tvButtons)

                Else If screen.rowContent[row][selection].ContentType = "Episode" Then
                    ShowTVDetailPage(screen.rowContent[row][selection].Id)

                Else If screen.rowContent[row][selection].ContentType = "MusicLibrary" Then
                    ShowMusicListPage()

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
'** Get Item Counts From Server
'**********************************************************

Function GetItemCounts() As Object
    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/Items/Counts?UserId=" + m.curUserProfile.Id, true)

    if (request.AsyncGetToString())
        while (true)
            msg = wait(0, request.GetPort())

            if (type(msg) = "roUrlEvent")
                code = msg.GetResponseCode()

                if (code = 200)
                    jsonData = ParseJSON(msg.GetString())
                    return jsonData
                else
                    Debug("Failed to Get Item Counts")
                    return invalid
                end if
            else if (event = invalid)
                request.AsyncCancel()
            end if
        end while
    end if

    Return invalid
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
            HDPosterUrl: "pkg://images/items/MovieTile_HD.png"
            SDPosterUrl: "pkg://images/items/MovieTile_SD.png"
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
            buttons.Append( recentMovies )
        End if

    Else If m.movieToggle = "favorite" Then
        switchButton[0].HDPosterUrl = "pkg://images/tiles/hd-toggle-favorites.png"
        switchButton[0].SDPosterUrl = "pkg://images/tiles/sd-toggle-favorites.png"

        buttons.Append( switchButton )

    Else
        switchButton[0].HDPosterUrl = "pkg://images/tiles/hd-toggle-resume.png"
        switchButton[0].SDPosterUrl = "pkg://images/tiles/sd-toggle-resume.png"

        ' Check For Resumable Movies, otherwise default to latest
        resumeMovies = MovieMetadata.GetResumable()
        If resumeMovies<>invalid And resumeMovies.Count() > 0
            buttons.Append( switchButton )
            buttons.Append( resumeMovies )
        Else
            m.movieToggle = "latest"

            ' Override Image
            switchButton[0].HDPosterUrl = "pkg://images/tiles/hd-toggle-latest.png"
            switchButton[0].SDPosterUrl = "pkg://images/tiles/sd-toggle-latest.png"

            ' Get Latest Unwatched Movies
            recentMovies = MovieMetadata.GetLatest()
            If recentMovies<>invalid
                buttons.Append( switchButton )
                buttons.Append( recentMovies )
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
            HDPosterUrl: "pkg://images/tiles/hd-tv.png"
            SDPosterUrl: "pkg://images/tiles/sd-tv.png"
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
            buttons.Append( recentTV )
        End if

    Else If m.tvToggle = "favorite" Then
        switchButton[0].HDPosterUrl = "pkg://images/tiles/hd-toggle-favorites.png"
        switchButton[0].SDPosterUrl = "pkg://images/tiles/sd-toggle-favorites.png"

        buttons.Append( switchButton )

    Else

        switchButton[0].HDPosterUrl = "pkg://images/tiles/hd-toggle-resume.png"
        switchButton[0].SDPosterUrl = "pkg://images/tiles/sd-toggle-resume.png"

        ' Check For Resumable TV, otherwise default to latest
        resumeTV = TvMetadata.GetResumable()
        If resumeTV<>invalid And resumeTV.Count() > 0
            buttons.Append( switchButton )
            buttons.Append( resumeTV )
        Else
            m.tvToggle = "latest"

            ' Override Image
            switchButton[0].HDPosterUrl = "pkg://images/tiles/hd-toggle-latest.png"
            switchButton[0].SDPosterUrl = "pkg://images/tiles/sd-toggle-latest.png"

            ' Get Latest Unwatched TV
            recentTV = TvMetadata.GetLatest()
            If recentTV<>invalid
                buttons.Append( switchButton )
                buttons.Append( recentTV )
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
            HDPosterUrl: "pkg://images/items/MusicTile_HD.png"
            SDPosterUrl: "pkg://images/items/MusicTile_SD.png"
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
'** Get Options Buttons Row
'**********************************************************

Function GetOptionsButtons() As Object
    ' Set the Options buttons
    buttons = [
        {
            Title: "Switch User"
            ContentType: "SwitchUser"
            ShortDescriptionLine1: "Switch User"
            HDPosterUrl: "pkg://images/items/SwitchUsersTile_HD.png"
            SDPosterUrl: "pkg://images/items/SwitchUsersTile_SD.png"
        },
        {
            Title: "Preferences"
            ContentType: "Preferences"
            ShortDescriptionLine1: "Preferences"
            ShortDescriptionLine2: "Version " + getGlobalVar("channelVersion", "Unknown")
            HDPosterUrl: "pkg://images/items/PreferencesTile_HD.png"
            SDPosterUrl: "pkg://images/items/PreferencesTile_SD.png"
        }
    ]

    Return buttons
End Function
