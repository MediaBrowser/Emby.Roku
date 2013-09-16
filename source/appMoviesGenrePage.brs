'*****************************************************************
'**  Media Browser Roku Client - Movies Genre Page
'*****************************************************************


'**********************************************************
'** Show Movies Genre Page
'**********************************************************

Function ShowMoviesGenrePage(genre As String) As Integer

    if validateParam(genre, "roString", "ShowMoviesGenrePage") = false return -1

    ' Create Grid Screen
    if RegRead("prefMovieImageType") = "poster" then
        screen = CreateGridScreen("Movies", genre, "mixed-aspect-ratio")
    else
        screen = CreateGridScreen("Movies", genre, "two-row-flat-landscape-custom")
    end if

    screen.AddRow("Movies", "portrait")

    screen.ShowNames()

    if RegRead("prefMovieImageType") = "poster" then
        screen.SetListPosterStyles(screen.rowStyles)
    end if

    ' Initialize Movie Metadata
    MovieMetadata = InitMovieMetadata()

    ' Get Data
    moviesAll = MovieMetadata.GetGenreMovieList(genre)

    if moviesAll <> invalid
        screen.AddRowContent(moviesAll.Items)
    end if

    ' Show Screen
    screen.Show()

    ' Show/Hide Description Popup
    if RegRead("prefMovieDisplayPopup") = "no" Or RegRead("prefMovieDisplayPopup") = invalid then
        screen.SetDescriptionVisible(false)
    end if

    while true
        msg = wait(0, screen.Port)

        if type(msg) = "roGridScreenEvent" then
            if msg.isListItemFocused() then
                ' Show/Hide Description Popup
                if RegRead("prefMovieDisplayPopup") = "yes" then
                    screen.SetDescriptionVisible(true) ' Work around for bug in mixed-aspect-ratio
                end if
            else if msg.isListItemSelected() then
                row = msg.GetIndex()
                selection = msg.getData()

                if screen.rowContent[row][selection].ContentType = "Movie" then
                    movieIndex = ShowMoviesDetailPage(screen.rowContent[row][selection].Id, moviesAll, selection)
                    screen.SetFocusedListItem(row, movieIndex)
                else 
                    Debug("Unknown Type found")
                end if
                
            else if msg.isScreenClosed() then
                return -1
            end if
        end if
    end while

    return 0
End Function
