'*****************************************************************
'**  Media Browser Roku Client - TV Show List Page
'*****************************************************************


'**********************************************************
'** Show TV Show List Page
'**********************************************************

Function ShowTVShowListPage() As Integer

    ' Create Grid Screen
    If RegRead("prefTVImageType") = "poster" Then
        screen = CreateGridScreen("", "TV", "mixed-aspect-ratio")
    Else
        screen = CreateGridScreen("", "TV", "two-row-flat-landscape-custom")
    End If

    ' Setup Row Data
    screen.rowNames   = CreateObject("roArray", 2, true)
    screen.rowStyles  = CreateObject("roArray", 2, true)
    screen.rowContent = CreateObject("roArray", 2, true)

    AddGridRow(screen, "Shows", "portrait")
    AddGridRow(screen, "Next Episodes to Watch", "landscape")
    AddGridRow(screen, "Genres", "landscape")

    ShowGridNames(screen)

    If RegRead("prefTVImageType") = "poster" Then
        screen.Screen.SetListPosterStyles(screen.rowStyles)
    End If

    ' Show Loading Dialog
    dialogBox = ShowPleaseWait("Loading...","")

    ' Initialize TV Metadata
    TvMetadata = InitTvMetadata()

    ' Get Data
    tvShowAll    = TvMetadata.GetShowList()
    tvShowNextUp = TvMetadata.GetNextUp()
    tvShowGenres = TvMetadata.GetGenres()

    AddGridRowContent(screen, tvShowAll)
    AddGridRowContent(screen, tvShowNextUp)
    AddGridRowContent(screen, tvShowGenres)

    ' Show Screen
    screen.Screen.Show()

    ' Close Loading Dialog
    dialogBox.Close()

    ' Show/Hide Description Popup
    If RegRead("prefTVDisplayPopup") = "no" Or RegRead("prefTVDisplayPopup") = invalid Then
        screen.Screen.SetDescriptionVisible(false)
    End If

    ' Remote key id's for navigation
    remoteKeyStar = 10

    while true
        msg = wait(0, screen.Screen.GetMessagePort())

        if type(msg) = "roGridScreenEvent" Then
            if msg.isListItemFocused() Then
                ' Show/Hide Description Popup
                If RegRead("prefTVDisplayPopup") = "yes" Then
                    screen.Screen.SetDescriptionVisible(true) ' Work around for bug in mixed-aspect-ratio
                End If
            else if msg.isListItemSelected() Then
                row = msg.GetIndex()
                selection = msg.getData()

                If screen.rowContent[row][selection].ContentType = "Series" Then
                    ShowTVSeasonsListPage(screen.rowContent[row][selection])
                Else If screen.rowContent[row][selection].ContentType = "Episode" Then
                    ShowTVDetailPage(screen.rowContent[row][selection].Id)
                    ' Refresh Next Up Data
                    tvShowNextUp = TvMetadata.GetNextUp()
                    UpdateGridRowContent(screen, row, tvShowNextUp)
                Else If screen.rowContent[row][selection].ContentType = "Genre" Then
                    ShowTVShowGenrePage(screen.rowContent[row][selection].Id)
                Else 
                    Debug("Unknown Type found")
                End If

            else if msg.isRemoteKeyPressed() then
                index = msg.GetIndex()

                If index = remoteKeyStar Then
                    letterSelected = CreateJumpListDialog()

                    If letterSelected <> invalid Then
                        letter = FindClosestLetter(letterSelected, TvMetadata)
                        screen.Screen.SetFocusedListItem(0, TvMetadata.jumpList.Lookup(letter))
                    End If
                End If

            else if msg.isScreenClosed() Then
                Debug("Close tv screen")
                return -1
            end if
        end if
    end while

    return 0
End Function
