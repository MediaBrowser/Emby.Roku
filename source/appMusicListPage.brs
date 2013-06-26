'*****************************************************************
'**  Media Browser Roku Client - Music List Page
'*****************************************************************


'**********************************************************
'** Show Music List Page
'**********************************************************

Function ShowMusicListPage() As Integer

    ' Create Grid Screen
    screen = CreateGridScreen("", "Music", "two-row-flat-landscape-custom")

    ' Setup Jump List
    m.jumpList = {}

    ' Setup Row Data
    screen.rowNames   = CreateObject("roArray", 3, true)
    screen.rowStyles  = CreateObject("roArray", 3, true)
    screen.rowContent = CreateObject("roArray", 3, true)

    AddGridRow(screen, "Albums", "landscape")
    AddGridRow(screen, "Artists", "landscape")
    AddGridRow(screen, "Genres", "landscape")

    ShowGridNames(screen)

    'screen.Screen.SetListPosterStyles(screen.rowStyles)

    ' Show Loading Dialog
    dialogBox = ShowPleaseWait("Loading...","")

    ' Get Data
    musicAlbums  = GetMusicAlbums()
    musicArtists = GetMusicArtists()
    musicGenres  = GetMusicGenres()

    AddGridRowContent(screen, musicAlbums)
    AddGridRowContent(screen, musicArtists)
    AddGridRowContent(screen, musicGenres)

    ' Show Screen
    screen.Screen.Show()

    ' Close Loading Dialog
    dialogBox.Close()

    ' Hide Description Popup
    screen.Screen.SetDescriptionVisible(false)

    ' Remote key id's for navigation
    remoteKeyStar = 10

    while true
        msg = wait(0, screen.Screen.GetMessagePort())

        if type(msg) = "roGridScreenEvent" Then
            if msg.isListItemFocused() then
                'print "list focused | index = "; msg.GetIndex(); " | category = "; 'm.curCategory
            else if msg.isListItemSelected() Then
                row = msg.GetIndex()
                selection = msg.getData()

                If screen.rowContent[row][selection].ContentType = "Album" Then
                    'movieIndex = ShowMoviesDetailPage(screen.rowContent[row][selection].Id, moviesAll, selection)
                    'screen.Screen.SetFocusedListItem(row, movieIndex)
                Else If screen.rowContent[row][selection].ContentType = "Artist" Then

                Else If screen.rowContent[row][selection].ContentType = "Genre" Then
                    'ShowMoviesGenrePage(screen.rowContent[row][selection].Id)
                Else 
                    Print "Unknown Type found"
                End If

            else if msg.isRemoteKeyPressed() then
                index = msg.GetIndex()

                If index = remoteKeyStar Then
                    letterSelected = CreateJumpListDialog()

                    If letterSelected <> invalid Then
                        letter = FindClosestLetter(letterSelected)
                        screen.Screen.SetFocusedListItem(0, m.jumpList.Lookup(letter))
                    End If
                End If

            else if msg.isScreenClosed() then
                return -1
            end if
        end if
    end while

    return 0
End Function


'**********************************************************
'** Get Music Albums From Server
'**********************************************************

Function GetMusicAlbums() As Object
    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/Users/" + m.curUserProfile.Id + "/Items?Recursive=true&IncludeItemTypes=MusicAlbum&Fields=UserData%2CItemCounts%2CSortName&SortBy=SortName&SortOrder=Ascending", true)

    if (request.AsyncGetToString())
        while (true)
            msg = wait(0, request.GetPort())

            if (type(msg) = "roUrlEvent")
                code = msg.GetResponseCode()

                if (code = 200)
                    index    = 0
                    list     = CreateObject("roArray", 2, true)
                    jsonData = ParseJSON(msg.GetString())
                    for each itemData in jsonData.Items
                        musicData = {
                            Id: itemData.Id
                            Title: itemData.Name
                            ContentType: "Album"
                            ShortDescriptionLine1: itemData.Name
                            ShortDescriptionLine2: Pluralize(itemData.ChildCount, "song")
                        }

                        ' Check If Item has Image, otherwise use default
                        If itemData.ImageTags.Primary<>"" And itemData.ImageTags.Primary<>invalid
                            musicData.HDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Primary/0?height=192&width=192&EnableImageEnhancers=false&tag=" + itemData.ImageTags.Primary
                            musicData.SDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Primary/0?height=86&width=96&EnableImageEnhancers=false&tag=" + itemData.ImageTags.Primary
                        Else 
                            musicData.HDPosterUrl = "pkg://images/items/collection.png"
                            musicData.SDPosterUrl = "pkg://images/items/collection.png"
                        End If

                        ' Build Jump List
                        firstChar = Left(itemData.SortName, 1)
                        If Not m.jumpList.DoesExist(firstChar) Then
                            m.jumpList.AddReplace(firstChar, index)
                        End If

                        ' Increment Count
                        index = index + 1

                        list.push( musicData )
                    end for
                    return list
                end if
            else if (event = invalid)
                request.AsyncCancel()
            endif
        end while
    endif

    Return invalid
End Function


'**********************************************************
'** Get Music Artists From Server
'**********************************************************

Function GetMusicArtists() As Object
    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/Artists?UserId=" + m.curUserProfile.Id + "&Recursive=true&Fields=UserData%2CItemCounts%2CSortName&SortBy=SortName&SortOrder=Ascending", true)

    if (request.AsyncGetToString())
        while (true)
            msg = wait(0, request.GetPort())

            if (type(msg) = "roUrlEvent")
                code = msg.GetResponseCode()

                if (code = 200)
                    list     = CreateObject("roArray", 2, true)
                    jsonData = ParseJSON(msg.GetString())
                    for each itemData in jsonData.Items
                        musicData = {
                            Id: itemData.Id
                            Title: itemData.Name
                            ContentType: "Artist"
                            ShortDescriptionLine1: itemData.Name
                            ShortDescriptionLine2: Pluralize(itemData.ChildCount, "song")
                        }

                        ' Clean Artist Name
                        artistName = HttpEncode(itemData.Name)

                        ' Check If Item has Image, otherwise use Default
                        If itemData.BackdropImageTags[0]<>"" And itemData.BackdropImageTags[0]<>invalid
                            musicData.HDPosterUrl = GetServerBaseUrl() + "/Artists/" + artistName + "/Images/Backdrop/0?height=150&width=&EnableImageEnhancers=false&tag=" + itemData.BackdropImageTags[0]
                            musicData.SDPosterUrl = GetServerBaseUrl() + "/Artists/" + artistName + "/Images/Backdrop/0?height=94&width=&EnableImageEnhancers=false&tag=" + itemData.BackdropImageTags[0]
                        Else 
                            musicData.HDPosterUrl = "pkg://images/items/collection.png"
                            musicData.SDPosterUrl = "pkg://images/items/collection.png"
                        End If

                        list.push( musicData )
                    end for
                    return list
                end if
            else if (event = invalid)
                request.AsyncCancel()
            endif
        end while
    endif

    Return invalid
End Function


'**********************************************************
'** Get Music Genres From Server
'**********************************************************

Function GetMusicGenres() As Object
    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/MusicGenres?UserId=" + m.curUserProfile.Id + "&Recursive=true&IncludeItemTypes=Audio&Fields=ItemCounts&SortBy=SortName&SortOrder=Ascending", true)

    if (request.AsyncGetToString())
        while (true)
            msg = wait(0, request.GetPort())

            if (type(msg) = "roUrlEvent")
                code = msg.GetResponseCode()

                if (code = 200)
                    list     = CreateObject("roArray", 2, true)
                    jsonData = ParseJSON(msg.GetString())
                    for each itemData in jsonData.Items
                        musicData = {
                            Id: itemData.Name
                            Title: itemData.Name
                            ContentType: "Genre"
                            ShortDescriptionLine1: itemData.Name
                            ShortDescriptionLine2: itostr(itemData.ChildCount) + " songs"
                        }

                        ' Clean Genre Name
                        genreName = HttpEncode(itemData.Name)

                        ' Check If Item has Image, otherwise use default
                        If itemData.ImageTags.Primary<>"" And itemData.ImageTags.Primary<>invalid
                            musicData.HDPosterUrl = GetServerBaseUrl() + "/MusicGenres/" + genreName + "/Images/Primary/0?height=150&width=&tag=" + itemData.ImageTags.Primary
                            musicData.SDPosterUrl = GetServerBaseUrl() + "/MusicGenres/" + genreName + "/Images/Primary/0?height=94&width=&tag=" + itemData.ImageTags.Primary
                        Else If itemData.BackdropImageTags[0]<>"" And itemData.BackdropImageTags[0]<>invalid
                            musicData.HDPosterUrl = GetServerBaseUrl() + "/MusicGenres/" + genreName + "/Images/Backdrop/0?height=150&width=&tag=" + itemData.BackdropImageTags[0]
                            musicData.SDPosterUrl = GetServerBaseUrl() + "/MusicGenres/" + genreName + "/Images/Backdrop/0?height=94&width=&tag=" + itemData.BackdropImageTags[0]
                        Else 
                            musicData.HDPosterUrl = "pkg://images/items/collection.png"
                            musicData.SDPosterUrl = "pkg://images/items/collection.png"
                        End If

                        list.push( musicData )
                    end for
                    return list
                endif
            else if (event = invalid)
                request.AsyncCancel()
            endif
        end while
    endif

    Return invalid
End Function
