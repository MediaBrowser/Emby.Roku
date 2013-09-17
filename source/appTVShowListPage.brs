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

    screen.ShowNames()

    If RegRead("prefTVImageType") = "poster" Then
        screen.SetListPosterStyles(screen.rowStyles)
    End If

    ' Initialize TV Metadata
    TvMetadata = InitTvMetadata()

    ' Filter (example)
    'filters = {
    '    sortby: "PremiereDate"
    '}

    ' Get Data
    'tvShowAll    = TvMetadata.GetShowList(filters)
    tvShowList   = TvMetadata.GetShowList(0, screen.rowPageSize)
    tvShowNextUp = TvMetadata.GetNextUp(0, screen.rowPageSize)
    tvShowGenres = TvMetadata.GetGenres(0, screen.rowPageSize)

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

                if selection > screen.rowLoadedCount[row] - screen.rowPageEdge And Not screen.rowFinishedLoading[row]
                    if row = 0
                        tvShowList = TvMetadata.GetShowList(screen.rowLoadedCount[row], screen.rowPageSize)
                        screen.LoadRowContent(row, tvShowList, screen.rowLoadedCount[row], screen.rowPageSize)

                    else if row = 1
                        tvShowNextUp = TvMetadata.GetNextUp(screen.rowLoadedCount[row], screen.rowPageSize)
                        screen.LoadRowContent(row, tvShowNextUp, screen.rowLoadedCount[row], screen.rowPageSize)

                    else if row = 2
                        tvShowGenres = TvMetadata.GetGenres(screen.rowLoadedCount[row], screen.rowPageSize)
                        screen.LoadRowContent(row, tvShowGenres, screen.rowLoadedCount[row], screen.rowPageSize)

                    end if
                end if

                ' Show/Hide Description Popup
                If RegRead("prefTVDisplayPopup") = "yes" Then
                    screen.SetDescriptionVisible(true) ' Work around for bug in mixed-aspect-ratio
                End If
            else if msg.isListItemSelected() Then
                row = msg.GetIndex()
                selection = msg.getData()

                if screen.rowContent[row][selection].ContentType = "Series" then
                    ShowTVSeasonsListPage(screen.rowContent[row][selection])

                else if screen.rowContent[row][selection].ContentType = "Episode" then
                    ShowTVDetailPage(screen.rowContent[row][selection].Id)
                    ' Refresh Next Up Data
                    tvShowNextUp = TvMetadata.GetNextUp()
                    screen.UpdateRowContent(row, tvShowNextUp)

                else if screen.rowContent[row][selection].ContentType = "Genre" then
                    ShowTVShowGenrePage(screen.rowContent[row][selection].Id)

                else 
                    Debug("Unknown Type found")

                end if

            else if msg.isRemoteKeyPressed() then
                index = msg.GetIndex()

                'If index = remoteKeyStar Then
                '    letterSelected = CreateJumpListDialog()

                '    If letterSelected <> invalid Then
                '        letter = FindClosestLetter(letterSelected, TvMetadata)
                '        screen.SetFocusedListItem(0, TvMetadata.jumpList.Lookup(letter))
                '    End If
                'End If

            else if msg.isScreenClosed() Then
                Debug("Close tv screen")
                return -1
            end if
        end if
    end while

    return 0
End Function
