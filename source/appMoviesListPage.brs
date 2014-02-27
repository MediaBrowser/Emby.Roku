'*****************************************************************
'**  Media Browser Roku Client - Movies List Page
'*****************************************************************


'**********************************************************
'** Show Movies List Page
'**********************************************************

Function ShowMoviesListPage() As Integer

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
    
    ' Get Item Counts
    mediaItemCounts = getMediaItemCounts()

    screen.AddRow("Movies", "portrait")
    screen.AddRow("Box Sets", "portrait")
    if mediaItemCounts.TrailerCount > 0
        screen.AddRow("Trailers", "portrait")
    end if
    screen.AddRow("Genres", "portrait")

    ' Initialize Movie Metadata
    MovieMetadata = InitMovieMetadata()
    ' Initialize Trailers Metadata
    TrailersMetadata = InitTrailersMetadata()
    
    ' Get Data
    moviesList = MovieMetadata.GetMovieList(0, screen.rowPageSize)
    if moviesList = invalid
        createDialog("Problem Loading Movies", "There was a problem while attempting to get the movies list from server. Please make sure your server is running and try again.", "Back")
        return 0
    end if

    moviesBoxsets = MovieMetadata.GetBoxsets(0, screen.rowPageSize)
    if moviesBoxsets = invalid
        createDialog("Problem Loading Boxsets", "There was a problem while attempting to get the list of boxset movies from the server.", "Continue")
    end if
    
    if mediaItemCounts.TrailerCount > 0
        trailers = TrailersMetadata.GetTrailersList(0, screen.rowPageSize)
        if trailers = invalid
            createDialog("Problem Loading Trailers", "There was a problem while attempting to get the list of trailers from the server.", "Continue")
        end if
    end if

    moviesGenres = MovieMetadata.GetGenres(0, screen.rowPageSize)
    if moviesGenres = invalid
        createDialog("Problem Loading Movie Genres", "There was an problem while attempting to get the list of movie genres from the server.", "Continue")
    end if

    ' Setup Row Names
    screen.ShowNames()

    ' Setup Row Styles
    if RegRead("prefMovieImageType") = "poster" then
        screen.SetListPosterStyles(screen.rowStyles)
    end if

    screen.LoadRowContent(0, moviesList, 0, screen.rowPageSize)
    screen.LoadRowContent(1, moviesBoxsets, 0, screen.rowPageSize)
    if mediaItemCounts.TrailerCount > 0
        screen.LoadRowContent(2, trailers, 0, screen.rowPageSize)
        screen.LoadRowContent(3, moviesGenres, 0, screen.rowPageSize)
    else 
        screen.LoadRowContent(2, moviesGenres, 0, screen.rowPageSize)
    end if

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
                                        moviesList = MovieMetadata.GetMovieList(screen.rowLoadedCount[row], screen.rowPageSize)
                                        screen.LoadRowContent(row, moviesList, screen.rowLoadedCount[row], screen.rowPageSize)

                                    else if row = 1
                                        moviesBoxsets = MovieMetadata.GetBoxsets(screen.rowLoadedCount[row], screen.rowPageSize)
                                        screen.LoadRowContent(row, moviesBoxsets, screen.rowLoadedCount[row], screen.rowPageSize)

                                    else if row = 2 and mediaItemCounts.TrailerCount > 0
                                        trailers  = TrailersMetadata.GetTrailersList(screen.rowLoadedCount[row], screen.rowPageSize)
                                        screen.LoadRowContent(row, trailers, screen.rowLoadedCount[row], screen.rowPageSize)
                                    
                                    else if row = 2 and mediaItemCounts.TrailerCount <= 0
                                        moviesGenres  = MovieMetadata.GetGenres(screen.rowLoadedCount[row], screen.rowPageSize)
                                        screen.LoadRowContent(row, moviesGenres, screen.rowLoadedCount[row], screen.rowPageSize)
                                    
                                    else if row = 3 and mediaItemCounts.TrailerCount > 0
                                        moviesGenres  = MovieMetadata.GetGenres(screen.rowLoadedCount[row], screen.rowPageSize)
                                        screen.LoadRowContent(row, moviesGenres, screen.rowLoadedCount[row], screen.rowPageSize)

                                    end if

                                end for

                                Print "Loaded Queued Items (ms): " + itostr(queueTimer.TotalMilliseconds()) 

                            ' Otherwise Load As Selection Reaches Edge
                            else

                                nextPageTimer = CreateObject("roTimespan")
                                nextPageTimer.Mark()

                                if row = 0
                                    moviesList = MovieMetadata.GetMovieList(screen.rowLoadedCount[row], screen.rowPageSize)
                                    screen.LoadRowContent(row, moviesList, screen.rowLoadedCount[row], screen.rowPageSize)

                                else if row = 1
                                    moviesBoxsets = MovieMetadata.GetBoxsets(screen.rowLoadedCount[row], screen.rowPageSize)
                                    screen.LoadRowContent(row, moviesBoxsets, screen.rowLoadedCount[row], screen.rowPageSize)

                                else if row = 2 and mediaItemCounts.TrailerCount > 0
                                    trailers  = TrailersMetadata.GetTrailersList(screen.rowLoadedCount[row], screen.rowPageSize)
                                    screen.LoadRowContent(row, trailers, screen.rowLoadedCount[row], screen.rowPageSize)
                                
                                else if row = 2 and mediaItemCounts.TrailerCount <= 0
                                    moviesGenres  = MovieMetadata.GetGenres(screen.rowLoadedCount[row], screen.rowPageSize)
                                    screen.LoadRowContent(row, moviesGenres, screen.rowLoadedCount[row], screen.rowPageSize)
                       
                                else if row = 3 and mediaItemCounts.TrailerCount > 0
                                    moviesGenres  = MovieMetadata.GetGenres(screen.rowLoadedCount[row], screen.rowPageSize)
                                    screen.LoadRowContent(row, moviesGenres, screen.rowLoadedCount[row], screen.rowPageSize)

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

                else if screen.rowContent[row][selection].ContentType = "Genre" then
                    ShowMoviesGenrePage(screen.rowContent[row][selection].Id)

                else if screen.rowContent[row][selection].ContentType = "BoxSet" then
                    ShowMoviesBoxsetPage(screen.rowContent[row][selection].Id, screen.rowContent[row][selection].Title)

                else if screen.rowContent[row][selection].ContentType = "Trailer" Then
                    ShowVideoDetails(screen.rowContent[row][selection].Id)
                    
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
