'*****************************************************************
'**  Media Browser Roku Client - Movies List Page
'*****************************************************************


'**********************************************************
'** Show Movies List Page
'**********************************************************

Function ShowMoviesListPage() As Integer

    ' Create Grid Screen
    if RegRead("prefMovieImageType") = "poster" then
        screen = CreateGridScreen("", "Movies", "mixed-aspect-ratio")
    Else
        screen = CreateGridScreen("", "Movies", "two-row-flat-landscape-custom")
    end if

    screen.AddRow("Movies", "portrait")
    screen.AddRow("Box Sets", "portrait")
    screen.AddRow("Genres", "portrait")

    screen.ShowNames()

    if RegRead("prefMovieImageType") = "poster" then
        screen.SetListPosterStyles(screen.rowStyles)
    end if

    ' Show Loading Dialog
    dialogBox = ShowPleaseWait("Loading...","")

    ' Initialize Movie Metadata
    MovieMetadata = InitMovieMetadata()

    ' Get Data
    moviesAll     = MovieMetadata.GetMovieList()
    moviesBoxsets = MovieMetadata.GetBoxsets()
    moviesGenres  = MovieMetadata.GetGenres()

    screen.AddRowContent(moviesAll)
    screen.AddRowContent(moviesBoxsets)
    screen.AddRowContent(moviesGenres)

    ' Show Screen
    screen.Show()

    ' Close Loading Dialog
    dialogBox.Close()

    ' Show/Hide Description Popup
    if RegRead("prefMovieDisplayPopup") = "no" Or RegRead("prefMovieDisplayPopup") = invalid then
        screen.SetDescriptionVisible(false)
    end if

    ' Remote key id's for navigation
    remoteKeyStar = 10

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
                Else if screen.rowContent[row][selection].ContentType = "Genre" then
                    ShowMoviesGenrePage(screen.rowContent[row][selection].Id)
                Else if screen.rowContent[row][selection].ContentType = "BoxSet" then
                    ShowMoviesBoxsetPage(screen.rowContent[row][selection].Id, screen.rowContent[row][selection].Title)
                Else 
                    Debug("Unknown Type found")
                end if

            else if msg.isRemoteKeyPressed() then
                index = msg.GetIndex()

                if index = remoteKeyStar then
                    letterSelected = CreateJumpListDialog()

                    if letterSelected <> invalid then
                        letter = FindClosestLetter(letterSelected, MovieMetadata)
                        screen.SetFocusedListItem(0, MovieMetadata.jumpList.Lookup(letter))
                    end if
                end if

            else if msg.isScreenClosed() then
                return -1
            end if
        end if
    end while

    return 0
End Function
