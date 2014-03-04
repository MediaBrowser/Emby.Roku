'*****************************************************************
'**  Media Browser Roku Client - TV Show List Page
'*****************************************************************


'**********************************************************
'** Show TV Show List Page
'**********************************************************

Function ShowTVShowListPage() As Integer

    ' Create Facade Screen
    facade = CreateObject("roGridScreen")
    facade.Show()

    ' Create Grid Screen
    If RegRead("prefTVImageType") = "poster" Then
        screen = CreateGridScreen("", "TV", "mixed-aspect-ratio")
    Else
        screen = CreateGridScreen("", "TV", "two-row-flat-landscape-custom")
    End If

    screen.AddRow("Shows", "portrait")
    screen.AddRow("Next Episodes to Watch", "portrait")
    screen.AddRow("Genres", "portrait")

    ' Filter (example)
    'filters = {
    '    sortby: "PremiereDate"
    '}

    ' Get Data
    'tvShowAll    = getTvShowList(filters)
    tvShowList = getTvShowList(0, screen.rowPageSize)
    if tvShowList = invalid
        createDialog("Problem Loading TV", "There was an problem while attempting to get the television shows list from server. Please make sure your server is running and try again.", "Back")
        return 0
    end if

    tvShowNextUp = getTvNextUp(0, screen.rowPageSize)
    if tvShowNextUp = invalid
        createDialog("Problem Loading Next Up", "There was an problem while attempting to get the list of next television episodes to watch from the server.", "Continue")
    end if

    tvShowGenres = getTvGenres(0, screen.rowPageSize)
    if tvShowGenres = invalid
        createDialog("Problem Loading TV Genres", "There was an problem while attempting to get the list of television show genres from the server.", "Continue")
    end if

    ' Setup Row Names
    screen.ShowNames()

    ' Setup Row Styles
    if RegRead("prefTVImageType") = "poster" then
        screen.SetListPosterStyles(screen.rowStyles)
    end if

    screen.LoadRowContent(0, tvShowList, 0, screen.rowPageSize)
    screen.LoadRowContent(1, tvShowNextUp, 0, screen.rowPageSize)
    screen.LoadRowContent(2, tvShowGenres, 0, screen.rowPageSize)

    ' Show Screen
    screen.Show()

    ' Close Facade Screen
    facade.Close()

    ' Show/Hide Description Popup
    If RegRead("prefTVDisplayPopup") = "no" Or RegRead("prefTVDisplayPopup") = invalid Then
        screen.SetDescriptionVisible(false)
    End If

    ' Remote key id's for navigation
    remoteKeyStar = 10

    while true
        msg = wait(0, screen.Port)

        if type(msg) = "roGridScreenEvent" Then
            if msg.isListItemFocused() Then
                ' Load More Content
                row = msg.GetIndex()
                selection = msg.getData()

                if screen.rowFinishedLoading[row] <> invalid

                    if Not screen.rowFinishedLoading[row]

                        if selection > screen.rowLoadedCount[row] - screen.rowPageEdge
                            ' Queue multiple loads to Catch up to Current Selection
                            if selection > screen.rowLoadedCount[row] + screen.rowPageSize
                                queue = Int((selection - screen.rowLoadedCount[row]) / screen.rowPageSize) + 1

                                for i = 1 to queue

                                    if row = 0
                                        tvShowList = getTvShowList(screen.rowLoadedCount[row], screen.rowPageSize)
                                        screen.LoadRowContent(row, tvShowList, screen.rowLoadedCount[row], screen.rowPageSize)

                                    else if row = 1
                                        tvShowNextUp = getTvNextUp(screen.rowLoadedCount[row], screen.rowPageSize)
                                        screen.LoadRowContent(row, tvShowNextUp, screen.rowLoadedCount[row], screen.rowPageSize)

                                    else if row = 2
                                        tvShowGenres = getTvGenres(screen.rowLoadedCount[row], screen.rowPageSize)
                                        screen.LoadRowContent(row, tvShowGenres, screen.rowLoadedCount[row], screen.rowPageSize)

                                    end if

                                end for

                            ' Otherwise Load As Selection Reaches Edge
                            else

                                if row = 0
                                    tvShowList = getTvShowList(screen.rowLoadedCount[row], screen.rowPageSize)
                                    screen.LoadRowContent(row, tvShowList, screen.rowLoadedCount[row], screen.rowPageSize)

                                else if row = 1
                                    tvShowNextUp = getTvNextUp(screen.rowLoadedCount[row], screen.rowPageSize)
                                    screen.LoadRowContent(row, tvShowNextUp, screen.rowLoadedCount[row], screen.rowPageSize)

                                else if row = 2
                                    tvShowGenres = getTvGenres(screen.rowLoadedCount[row], screen.rowPageSize)
                                    screen.LoadRowContent(row, tvShowGenres, screen.rowLoadedCount[row], screen.rowPageSize)

                                end if

                            end if

                        end if

                    end if

                    ' Show/Hide Description Popup
                    if RegRead("prefTVDisplayPopup") = "yes" then
                        screen.SetDescriptionVisible(true) ' Work around for bug in mixed-aspect-ratio
                    end if

                end if

            else if msg.isListItemSelected() Then
                row = msg.GetIndex()
                selection = msg.getData()

                if screen.rowContent[row][selection].ContentType = "Series" then
                    ShowTVSeasonsListPage(screen.rowContent[row][selection])

                else if screen.rowContent[row][selection].ContentType = "Episode" Then
                    ShowVideoDetails(screen.rowContent[row][selection].Id)

                    ' Refresh Next Up Data
                    tvShowNextUp = getTvNextUp(0, screen.rowPageSize)
                    screen.UpdateRowContent(row, tvShowNextUp.Items)

                else if screen.rowContent[row][selection].ContentType = "TvGenre" then
                    ShowTVShowGenrePage(screen.rowContent[row][selection].Id)

                else 
                    Debug("Unknown Type found")

                end if

            else if msg.isRemoteKeyPressed() then
                index = msg.GetIndex()

                'If index = remoteKeyStar Then
                'End If

            else if msg.isScreenClosed() Then
                Debug("Close tv screen")
                return -1
            end if
        end if
    end while

    return 0
End Function
