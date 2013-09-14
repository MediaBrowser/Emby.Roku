'*****************************************************************
'**  Media Browser Roku Client - TV Show Genre Page
'*****************************************************************


'**********************************************************
'** Show TV Show Genre Page
'**********************************************************

Function ShowTVShowGenrePage(genre As String) As Integer

    if validateParam(genre, "roString", "ShowTVShowGenrePage") = false return -1

    ' Setup Screen
    port   = CreateObject("roMessagePort")
    screen = CreateObject("roGridScreen")
    screen.SetMessagePort(port)

    screen.SetBreadcrumbText("TV", genre)

    ' Determine Display Type
    If RegRead("prefTVImageType") = "poster" Then
        screen.SetGridStyle("mixed-aspect-ratio")
    Else
        screen.SetGridStyle("two-row-flat-landscape-custom")
    End If

    screen.SetDisplayMode("scale-to-fill")

    ' Show Screen
    screen.SetupLists(1)
    screen.SetListNames(["Shows"])

    rowData = CreateObject("roArray", 2, true)

    ' Initialize TV Metadata
    TvMetadata = InitTvMetadata()

    ' Get Data
    tvShowAll = TvMetadata.GetGenreShowList(genre)
    rowData[0] = tvShowAll
    screen.SetContentList(0, tvShowAll)

    screen.Show()

    ' Hide Description Popup
    screen.SetDescriptionVisible(false)

    while true
        msg = wait(0, screen.GetMessagePort())

        if type(msg) = "roGridScreenEvent" Then
            if msg.isListItemFocused() then
                ' Show/Hide Description Popup
                If RegRead("prefTVDisplayPopup") = "yes" Then
                    screen.SetDescriptionVisible(true) ' Work around for bug in mixed-aspect-ratio
                End If
            else if msg.isListItemSelected() Then
                row = msg.GetIndex()
                selection = msg.getData()

                If rowData[row][selection].ContentType = "Series" Then
                    ShowTVSeasonsListPage(rowData[row][selection])
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
