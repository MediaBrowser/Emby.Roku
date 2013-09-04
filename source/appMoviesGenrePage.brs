'*****************************************************************
'**  Media Browser Roku Client - Movies Genre Page
'*****************************************************************


'**********************************************************
'** Show Movies Genre Page
'**********************************************************

Function ShowMoviesGenrePage(genre As String) As Integer

    if validateParam(genre, "roString", "ShowMoviesGenrePage") = false return -1

    ' Setup Screen
    port   = CreateObject("roMessagePort")
    screen = CreateObject("roGridScreen")
    screen.SetMessagePort(port)

    screen.SetBreadcrumbText(genre, "Movies")

    ' Determine Display Type
    If RegRead("prefMovieImageType") = "poster" Then
        screen.SetGridStyle("mixed-aspect-ratio")
    Else
        screen.SetGridStyle("two-row-flat-landscape-custom")
    End If

    screen.SetDisplayMode("scale-to-fill")

    screen.SetupLists(1)
    screen.SetListNames(["Movies"])

    rowData = CreateObject("roArray", 1, true)

    ' Initialize Movie Metadata
    MovieMetadata = InitMovieMetadata()

    ' Get Data
    moviesAll = MovieMetadata.GetGenreMovieList(genre)
    rowData[0] = moviesAll
    screen.SetContentList(0, moviesAll)

    ' Show Screen
    screen.Show()

    ' Hide Description Popup
    screen.SetDescriptionVisible(false)

    while true
        msg = wait(0, screen.GetMessagePort())

        if type(msg) = "roGridScreenEvent" Then
            if msg.isListItemFocused() then
                ' Show/Hide Description Popup
                If RegRead("prefMovieDisplayPopup") = "yes" Then
                    screen.SetDescriptionVisible(true) ' Work around for bug in mixed-aspect-ratio
                End If
            else if msg.isListItemSelected() Then
                row = msg.GetIndex()
                selection = msg.getData()

                If rowData[row][selection].ContentType = "Movie" Then
                    movieIndex = ShowMoviesDetailPage(rowData[row][selection].Id, moviesAll, selection)
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
