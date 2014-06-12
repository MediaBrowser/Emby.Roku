'**********************************************************
'** Show Channel List Page
'**********************************************************

Function ShowChannelPage(viewController as Object, parentId As String, title As String, index As Integer) As Integer

    ' Create Facade Screen
    facade = CreateObject("roGridScreen")
	facade.Show()

    ' Create Grid Screen
    screen = CreateGridScreen(viewController, "mixed-aspect-ratio")

    screen.AddRow(title, "portrait")

    ' Get Data
    channelItems = GetChannelItems(parentId, 0, screen.rowPageSize)

    ' Check to see if Data Loaded
    if channelItems = invalid
        createErrorDialog()
        return -1
    end if

    ' Check to see if there are entries
    if channelItems.TotalCount = 0
        createDialog("No Items", "There were no items found in this channel.", "Back")
        return -1
    end if

    ' Setup Row Names
    screen.ShowNames()

    ' Setup Row Styles
    screen.SetListPosterStyles(screen.rowStyles)

    ' Set total count
    screen.TotalCounts[0] = channelItems.TotalCount

    ' Load Paginated Data
    screen.LoadRowContent(0, channelItems, 0, screen.rowPageSize)

    ' Show Screen
    screen.Show()

    ' Close Facade Screen
    facade.Close()

    if index <> 0
        recreateIndex = index
    else
        recreateIndex = 0
    end if

    ' Show/Hide Description Popup
    if RegRead("prefChannelPopup") = "no" Or RegRead("prefChannelPopup") = invalid then
        screen.SetDescriptionVisible(false)
    end if

    ' Remote key id's for navigation
    remoteKeyStar = 10

    ' Refocus Item
    screen.SetFocusedListItem(0, recreateIndex)

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

                                for i = 1 to queue

                                    channelItems = GetChannelItems(parentId, screen.rowLoadedCount[row], screen.rowPageSize)
                                    screen.LoadRowContent(row, channelItems, screen.rowLoadedCount[row], screen.rowPageSize)

                                end for

                            ' Otherwise Load As Selection Reaches Edge
                            else

                                channelItems = GetChannelItems(parentId, screen.rowLoadedCount[row], screen.rowPageSize)
                                screen.LoadRowContent(row, channelItems, screen.rowLoadedCount[row], screen.rowPageSize)

                            end if

                        end if

                    end if

                    ' Show/Hide Description Popup
                    if RegRead("prefChannelPopup") = "yes" then
                        screen.SetDescriptionVisible(true) ' Work around for bug in mixed-aspect-ratio
                    end if

                end if

            else if msg.isRemoteKeyPressed() then
                index = msg.GetIndex()

                if index = remoteKeyStar then
                    ' Context Menu
                end if

            else if msg.isScreenClosed() then
                return -1
            end if
        end if
    end while

    return -1
End Function
