'*****************************************************************
'**  Media Browser Roku Client - Collection Pages
'*****************************************************************


'**********************************************************
'** Show Movies List Page
'**********************************************************

Function ShowCollectionPage(parentId As String, title As String) As Integer

    ' Create Facade Screen
    facade = CreateObject("roGridScreen")
    facade.Show()

    ' Create Grid Screen
    if RegRead("prefCollectionView") = "poster" then
        screen = CreateGridScreen("", title, "mixed-aspect-ratio")
    Else
        screen = CreateGridScreen("", title, "two-row-flat-landscape-custom")
    end if

    screen.AddRow(title, "portrait")

    screen.ShowNames()

    if RegRead("prefCollectionView") = "poster" then
        screen.SetListPosterStyles(screen.rowStyles)
    end if

    ' Initialize Collection Metadata
    CollectionMetadata = InitCollectionMetadata()

    ' Get Data
    collectionItems = CollectionMetadata.GetCollectionItems(parentId, 0, screen.rowPageSize)

    ' Load Paginated Data
    screen.LoadRowContent(0, collectionItems, 0, screen.rowPageSize)

    ' Show Screen
    screen.Show()

    ' Close Facade Screen
    facade.Close()

    ' Show/Hide Description Popup
    if RegRead("prefCollectionPopup") = "no" Or RegRead("prefCollectionPopup") = invalid then
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

                                collectionItems = CollectionMetadata.GetCollectionItems(parentId, screen.rowLoadedCount[row], screen.rowPageSize)
                                screen.LoadRowContent(row, collectionItems, screen.rowLoadedCount[row], screen.rowPageSize)

                            end for

                        ' Otherwise Load As Selection Reaches Edge
                        else

                            collectionItems = CollectionMetadata.GetCollectionItems(parentId, screen.rowLoadedCount[row], screen.rowPageSize)
                            screen.LoadRowContent(row, collectionItems, screen.rowLoadedCount[row], screen.rowPageSize)

                        end if

                    end if

                end if

                ' Show/Hide Description Popup
                if RegRead("prefCollectionPopup") = "yes" then
                    screen.SetDescriptionVisible(true) ' Work around for bug in mixed-aspect-ratio
                end if
            else if msg.isListItemSelected() then
                row = msg.GetIndex()
                selection = msg.getData()

                Debug("Content type: " + screen.rowContent[row][selection].ContentType)

                ' Movie Content Types

                if screen.rowContent[row][selection].ContentType = "Movie" then
                    ShowVideoDetails(screen.rowContent[row][selection].Id)

                else if screen.rowContent[row][selection].ContentType = "BoxSet" then
                    ShowMoviesBoxsetPage(screen.rowContent[row][selection].Id, screen.rowContent[row][selection].Title)

                ' TV Content Types

                else if screen.rowContent[row][selection].ContentType = "Series" then
                    ShowTVSeasonsListPage(screen.rowContent[row][selection])

                else if screen.rowContent[row][selection].ContentType = "Episode" then
                    ShowVideoDetails(screen.rowContent[row][selection].Id)

                ' Music Content Types

                else if screen.rowContent[row][selection].ContentType = "MusicArtist" then
                    ShowMusicAlbumPage(screen.rowContent[row][selection])

                ' Folder Content Type

                else if screen.rowContent[row][selection].ContentType = "Folder" then
                    ShowCollectionPage(screen.rowContent[row][selection].Id, screen.rowContent[row][selection].Title)

                ' Video Content Type
                else if screen.rowContent[row][selection].ContentType = "Video" then
                    ShowVideoDetails(screen.rowContent[row][selection].Id)

                ' Trailer Content Type

                else if screen.rowContent[row][selection].ContentType = "Trailer" then
                    ShowVideoDetails(screen.rowContent[row][selection].Id)

                else 
                    Debug("Unknown Type found")
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

    return 0
End Function
