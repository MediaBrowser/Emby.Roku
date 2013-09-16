'*****************************************************************
'**  Media Browser Roku Client - Movies Boxset Page
'*****************************************************************


'**********************************************************
'** Show Movies Boxset Page
'**********************************************************

Function ShowMoviesBoxsetPage(boxsetId As String, boxsetName As String) As Integer

    if validateParam(boxsetId, "roString", "ShowMoviesBoxsetPage") = false return -1

    ' Create Grid Screen
    If RegRead("prefMovieImageType") = "poster" Then
        screen = CreateGridScreen("Movies", boxsetName, "mixed-aspect-ratio")
    Else
        screen = CreateGridScreen("Movies", boxsetName, "two-row-flat-landscape-custom")
    End If

    screen.AddRow("Movies", "portrait")

    screen.ShowNames()

    if RegRead("prefMovieImageType") = "poster" then
        screen.SetListPosterStyles(screen.rowStyles)
    end if

    ' Initialize Movie Metadata
    MovieMetadata = InitMovieMetadata()

    ' Get Data
    moviesAll = MovieMetadata.GetBoxsetMovieList(boxsetId)

    if moviesAll <> invalid
        screen.AddRowContent(moviesAll.Items)
    end if
    
    ' Show Screen
    screen.Show()

    ' Show/Hide Description Popup
    If RegRead("prefMovieDisplayPopup") = "no" Or RegRead("prefMovieDisplayPopup") = invalid Then
        screen.SetDescriptionVisible(false)
    End If

    while true
        msg = wait(0, screen.Port)

        if type(msg) = "roGridScreenEvent" Then
            if msg.isListItemFocused() then
                ' Show/Hide Description Popup
                If RegRead("prefMovieDisplayPopup") = "yes" Then
                    screen.SetDescriptionVisible(true) ' Work around for bug in mixed-aspect-ratio
                End If
            else if msg.isListItemSelected() Then
                row = msg.GetIndex()
                selection = msg.getData()

                If screen.rowContent[row][selection].ContentType = "Movie" Then
                    movieIndex = ShowMoviesDetailPage(screen.rowContent[row][selection].Id, moviesAll, selection)
                    screen.SetFocusedListItem(row, movieIndex)
                Else 
                    Debug("Unknown Type found")
                End If
                
            else if msg.isScreenClosed() then
                return -1
            end if
        end if
    end while

    return 0
End Function
