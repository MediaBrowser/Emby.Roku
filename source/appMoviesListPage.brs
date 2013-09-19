'*****************************************************************
'**  Media Browser Roku Client - Movies List Page
'*****************************************************************


'**********************************************************
'** Show Movies List Page
'**********************************************************

Function ShowMoviesListPage() As Integer

    ' Create Facade Screen
    facade = CreateObject("roGridScreen")
    facade.Show()

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

    ' Initialize Movie Metadata
    MovieMetadata = InitMovieMetadata()

    ' Get Data
    moviesList    = MovieMetadata.GetMovieList(0, screen.rowPageSize)
    moviesBoxsets = MovieMetadata.GetBoxsets(0, screen.rowPageSize)
    moviesGenres  = MovieMetadata.GetGenres(0, screen.rowPageSize)

    screen.LoadRowContent(0, moviesList, 0, screen.rowPageSize)
    screen.LoadRowContent(1, moviesBoxsets, 0, screen.rowPageSize)
    screen.LoadRowContent(2, moviesGenres, 0, screen.rowPageSize)

    ' Show Screen
    screen.Show()

    ' Close Facade Screen
    facade.Close()

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
                ' Load More Content
                row = msg.GetIndex()
                selection = msg.getData()

                if Not screen.rowFinishedLoading[row]

                    if selection > screen.rowLoadedCount[row] - screen.rowPageEdge
                        ' Queue multiple loads to Catch up to Current Selection
                        if selection > screen.rowLoadedCount[row] + screen.rowPageSize
                            queue = Int((selection - screen.rowLoadedCount[row]) / screen.rowPageSize) + 1

                            for i = 1 to queue

                                if row = 0
                                    moviesList = MovieMetadata.GetMovieList(screen.rowLoadedCount[row], screen.rowPageSize)
                                    screen.LoadRowContent(row, moviesList, screen.rowLoadedCount[row], screen.rowPageSize)

                                else if row = 1
                                    moviesBoxsets = MovieMetadata.GetBoxsets(screen.rowLoadedCount[row], screen.rowPageSize)
                                    screen.LoadRowContent(row, moviesBoxsets, screen.rowLoadedCount[row], screen.rowPageSize)

                                else if row = 2
                                    moviesGenres  = MovieMetadata.GetGenres(screen.rowLoadedCount[row], screen.rowPageSize)
                                    screen.LoadRowContent(row, moviesGenres, screen.rowLoadedCount[row], screen.rowPageSize)

                                end if

                            end for

                        ' Otherwise Load As Selection Reaches Edge
                        else

                            if row = 0
                                moviesList = MovieMetadata.GetMovieList(screen.rowLoadedCount[row], screen.rowPageSize)
                                screen.LoadRowContent(row, moviesList, screen.rowLoadedCount[row], screen.rowPageSize)

                            else if row = 1
                                moviesBoxsets = MovieMetadata.GetBoxsets(screen.rowLoadedCount[row], screen.rowPageSize)
                                screen.LoadRowContent(row, moviesBoxsets, screen.rowLoadedCount[row], screen.rowPageSize)

                            else if row = 2
                                moviesGenres  = MovieMetadata.GetGenres(screen.rowLoadedCount[row], screen.rowPageSize)
                                screen.LoadRowContent(row, moviesGenres, screen.rowLoadedCount[row], screen.rowPageSize)

                            end if

                        end if

                    end if

                end if

                ' Show/Hide Description Popup
                if RegRead("prefMovieDisplayPopup") = "yes" then
                    screen.SetDescriptionVisible(true) ' Work around for bug in mixed-aspect-ratio
                end if
            else if msg.isListItemSelected() then
                row = msg.GetIndex()
                selection = msg.getData()

                if screen.rowContent[row][selection].ContentType = "Movie" then
                    movieIndex = ShowMoviesDetailPage(screen.rowContent[row][selection].Id, moviesList, selection)
                    screen.SetFocusedListItem(row, movieIndex)

                else if screen.rowContent[row][selection].ContentType = "Genre" then
                    ShowMoviesGenrePage(screen.rowContent[row][selection].Id)

                else if screen.rowContent[row][selection].ContentType = "BoxSet" then
                    ShowMoviesBoxsetPage(screen.rowContent[row][selection].Id, screen.rowContent[row][selection].Title)

                else 
                    Debug("Unknown Type found")
                end if

            else if msg.isRemoteKeyPressed() then
                index = msg.GetIndex()

                if index = remoteKeyStar then
                    'letterSelected = CreateJumpListDialog()

                    'if letterSelected <> invalid then
                    '    letter = FindClosestLetter(letterSelected, MovieMetadata)
                    '    screen.SetFocusedListItem(0, MovieMetadata.jumpList.Lookup(letter))
                    'end if
                end if

            else if msg.isScreenClosed() then
                return -1
            end if
        end if
    end while

    return 0
End Function
