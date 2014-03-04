'*****************************************************************
'**  Media Browser Roku Client - TV Show Genre Page
'*****************************************************************


'**********************************************************
'** Show TV Show Genre Page
'**********************************************************

Function ShowTVShowGenrePage(genre As String) As Integer

    if validateParam(genre, "roString", "ShowTVShowGenrePage") = false return -1

    ' Create Grid Screen
    if RegRead("prefTVImageType") = "poster" then
        screen = CreateGridScreen("TV", genre, "mixed-aspect-ratio")
    else
        screen = CreateGridScreen("TV", genre, "two-row-flat-landscape-custom")
    end if

    screen.AddRow("Shows", "portrait")

    screen.ShowNames()

    if RegRead("prefTVImageType") = "poster" then
        screen.SetListPosterStyles(screen.rowStyles)
    end if

    ' Get Data
    showsAll = GetTvGenreShowList(genre)

    if showsAll <> invalid
        screen.AddRowContent(showsAll.Items)
    end if

    ' Show Screen
    screen.Show()

    ' Show/Hide Description Popup
    if RegRead("prefTVDisplayPopup") = "no" Or RegRead("prefTVDisplayPopup") = invalid then
        screen.SetDescriptionVisible(false)
    end if

    while true
        msg = wait(0, screen.Port)

        if type(msg) = "roGridScreenEvent" then
            if msg.isListItemFocused() then
                ' Show/Hide Description Popup
                if RegRead("prefTVDisplayPopup") = "yes" then
                    screen.SetDescriptionVisible(true) ' Work around for bug in mixed-aspect-ratio
                end if
            else if msg.isListItemSelected() then
                row = msg.GetIndex()
                selection = msg.getData()

                if screen.rowContent[row][selection].ContentType = "Series" Then
                    ShowTVSeasonsListPage(screen.rowContent[row][selection])
                else 
                    Debug("Unknown Type found")
                end if
                
            else if msg.isScreenClosed() then
                return -1
            end if
        end if
    end while

    return 0
End Function
