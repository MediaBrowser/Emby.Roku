'*****************************************************************
'**  Media Browser Roku Client - Movies List Page
'*****************************************************************


'**********************************************************
'** Show Movies Alphabetical List Page
'**********************************************************

Function ShowMoviesAlphaPage(letter As String) As Integer

    pageTimer = CreateObject("roTimespan")
    pageTimer.Mark()

    ' Create Facade Screen
    facade = CreateObject("roGridScreen")
    facade.Show()

    ' Create Grid Screen
    if RegRead("prefMovieImageType") = "poster" then
        screen = CreateGridScreen("", "Movies", "mixed-aspect-ratio")
    else
        screen = CreateGridScreen("", "Movies", "two-row-flat-landscape-custom")
    end if

    screen.AddRow("Movies", "portrait")

    ' Initialize Movie Metadata
    MovieMetadata = InitMovieMetadata()

    ' Filter
    filters = {
        NameStartsWithOrGreater: letter
    }

    ' Get Data
    moviesList = MovieMetadata.GetMovieList(0, screen.rowPageSize, filters)
    if moviesList = invalid
        createDialog("Problem Loading Movies", "There was an problem while attempting to get the movies list from server. Please make sure your server is running and try again.", "Back")
        return 0
    end if

    ' Setup Row Names
    screen.ShowNames()

    ' Setup Row Styles
    if RegRead("prefMovieImageType") = "poster" then
        screen.SetListPosterStyles(screen.rowStyles)
    end if

    screen.LoadRowContent(0, moviesList, 0, screen.rowPageSize)

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

    Print "Loaded Page (ms): " + itostr(pageTimer.TotalMilliseconds()) 

    while true
        msg = wait(0, screen.Port)

        if type(msg) = "roGridScreenEvent" then
            if msg.isListItemFocused() then
                ' Load More Content
                row = msg.GetIndex()
                selection = msg.getData()

                if screen.rowFinishedLoading[row] <> invalid

                    if Not screen.rowFinishedLoading[row]

                        if selection > screen.rowLoadedCount[row] - screen.rowPageEdge
                            ' Queue multiple loads to Catch up to Current Selection
                            if selection > screen.rowLoadedCount[row] + screen.rowPageSize
                                queue = Int((selection - screen.rowLoadedCount[row]) / screen.rowPageSize) + 1

                                queueTimer = CreateObject("roTimespan")
                                queueTimer.Mark()

                                for i = 1 to queue

                                    if row = 0
                                        moviesList = MovieMetadata.GetMovieList(screen.rowLoadedCount[row], screen.rowPageSize, filters)
                                        screen.LoadRowContent(row, moviesList, screen.rowLoadedCount[row], screen.rowPageSize)

                                    end if

                                end for

                                Print "Loaded Queued Items (ms): " + itostr(queueTimer.TotalMilliseconds()) 

                            ' Otherwise Load As Selection Reaches Edge
                            else

                                nextPageTimer = CreateObject("roTimespan")
                                nextPageTimer.Mark()

                                if row = 0
                                    moviesList = MovieMetadata.GetMovieList(screen.rowLoadedCount[row], screen.rowPageSize, filters)
                                    screen.LoadRowContent(row, moviesList, screen.rowLoadedCount[row], screen.rowPageSize)

                                end if

                                Print "Loaded Next Page (ms): " + itostr(nextPageTimer.TotalMilliseconds()) 

                            end if

                        end if

                    end if

                    ' Show/Hide Description Popup
                    if RegRead("prefMovieDisplayPopup") = "yes" then
                        screen.SetDescriptionVisible(true) ' Work around for bug in mixed-aspect-ratio
                    end if

                end if

            else if msg.isListItemSelected() then
                row = msg.GetIndex()
                selection = msg.getData()

                if screen.rowContent[row][selection].ContentType = "Movie" then
                    ShowVideoDetails(screen.rowContent[row][selection].Id)
                    'movieIndex = ShowMoviesDetailPage(screen.rowContent[row][selection].Id, moviesList, selection)
                    'screen.SetFocusedListItem(row, movieIndex)

                else 
                    Debug("Unknown Type found")
                end if

            else if msg.isRemoteKeyPressed() then
                index = msg.GetIndex()

                if index = remoteKeyStar then
                    'createContextMenuDialog()
                end if

            else if msg.isScreenClosed() then
                return -1
            end if
        end if
    end while

    return 0
End Function
