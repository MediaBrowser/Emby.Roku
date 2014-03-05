'*****************************************************************
'**  Media Browser Roku Client - TV Show List Page
'*****************************************************************


'**********************************************************
'** Show TV Show Alphabetical List Page
'**********************************************************

Function ShowTVAlphaPage(letter As String) As Integer

    ' Create Facade Screen
    facade = CreateObject("roGridScreen")
    facade.Show()

    ' Create Grid Screen
    If RegRead("prefTVImageType") = "poster" Then
        screen = CreateGridScreen("TV", UCase(letter), "mixed-aspect-ratio")
    Else
        screen = CreateGridScreen("TV", UCase(letter), "two-row-flat-landscape-custom")
    End If

    screen.AddRow("Shows", "portrait")

    ' Filter
    filters = {
        NameStartsWithOrGreater: letter
    }

    ' Get Data
    tvShowList = getTvShowList(0, screen.rowPageSize, filters)
    if tvShowList = invalid
        createDialog("Problem Loading TV", "There was an problem while attempting to get the television shows list from server. Please make sure your server is running and try again.", "Back")
        return 0
    end if

    ' Setup Row Names
    screen.ShowNames()

    ' Setup Row Styles
    if RegRead("prefTVImageType") = "poster" then
        screen.SetListPosterStyles(screen.rowStyles)
    end if

    screen.LoadRowContent(0, tvShowList, 0, screen.rowPageSize)

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
                                        tvShowList = getTvShowList(screen.rowLoadedCount[row], screen.rowPageSize, filters)
                                        screen.LoadRowContent(row, tvShowList, screen.rowLoadedCount[row], screen.rowPageSize)

                                    end if

                                end for

                            ' Otherwise Load As Selection Reaches Edge
                            else

                                if row = 0
                                    tvShowList = getTvShowList(screen.rowLoadedCount[row], screen.rowPageSize, filters)
                                    screen.LoadRowContent(row, tvShowList, screen.rowLoadedCount[row], screen.rowPageSize)

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
