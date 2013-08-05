'*****************************************************************
'**  Media Browser Roku Client - Music List Page
'*****************************************************************


'**********************************************************
'** Show Music List Page
'**********************************************************


Function ShowMusicListPage() As Integer

    ' Create Poster Screen
    screen = CreatePosterScreen("", "Music", "arced-square")

    ' Setup Jump List
    m.jumpList = {}

    ' Get Data Functions
    musicDataFunctions = [
        GetMusicAlbums,
        GetMusicArtists,
        GetMusicGenres
    ]

    ' Get Default Data
    musicData = musicDataFunctions[0]()

    screen.Categories(["Albums","Artists","Genres"])

    screen.Screen.SetContentList(musicData)

    ' Show Screen
    screen.Show()

    while true
        msg = wait(0, screen.Screen.GetMessagePort())

        if type(msg) = "roPosterScreenEvent" Then
            If msg.isListFocused() Then
                category = msg.GetIndex()

                ' Setup Message
                screen.Screen.SetContentList([])
                screen.Screen.SetFocusedListItem(0)
                screen.Screen.ShowMessage("Retrieving")

                ' Fetch Category
                musicData = musicDataFunctions[category]()
                screen.Screen.SetContentList(musicData)

                screen.Screen.ClearMessage()
            Else If msg.isListItemSelected() Then
                selection = msg.GetIndex()

                If musicData[selection].ContentType = "Album" Then
                    ShowMusicSongPage(musicData[selection])

                Else If musicData[selection].ContentType = "Artist" Then
                    ShowMusicAlbumPage(musicData[selection])

                Else If musicData[selection].ContentType = "Genre" Then
                    ShowMusicGenrePage(musicData[selection].Id)

                Else 
                    Print "Unknown Type found"
                End If

            Else If msg.isScreenClosed() then
                return -1
            End If
        end if
    end while

    return 0
End Function

'**********************************************************
'** Get Music Albums From Server
'**********************************************************

Function GetMusicAlbums() As Object

    ' Clean Fields
    fields = HttpEncode("ItemCounts,DateCreated,UserData,AudioInfo,ParentId,SortName")

    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/Users/" + m.curUserProfile.Id + "/Items?Recursive=true&IncludeItemTypes=MusicAlbum&Fields=" + fields + "&SortBy=SortName&SortOrder=Ascending", true)

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
                            musicData.HDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Primary/0?quality=90&height=300&width=300&EnableImageEnhancers=false&tag=" + itemData.ImageTags.Primary
                            musicData.SDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Primary/0?quality=90&height=145&width=285&EnableImageEnhancers=false&tag=" + itemData.ImageTags.Primary
                        Else 
                            musicData.HDPosterUrl = "pkg://images/items/collection.png"
                            musicData.SDPosterUrl = "pkg://images/items/collection.png"
                        End If

                        ' Check For Artist Name
                        If itemData.AlbumArtist<>"" And itemData.AlbumArtist<>invalid
                            musicData.Artist = itemData.AlbumArtist
                        Else If itemData.Artists[0]<>"" And itemData.Artists[0]<>invalid
                            musicData.Artist = itemData.Artists[0]
                        Else
                            musicData.Artist = ""
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
                        If itemData.ImageTags.Primary<>"" And itemData.ImageTags.Primary<>invalid
                            musicData.HDPosterUrl = GetServerBaseUrl() + "/Artists/" + artistName + "/Images/Primary/0?quality=90&height=300&width=300&EnableImageEnhancers=false&tag=" + itemData.ImageTags.Primary
                            musicData.SDPosterUrl = GetServerBaseUrl() + "/Artists/" + artistName + "/Images/Primary/0?quality=90&height=145&width=285&EnableImageEnhancers=false&tag=" + itemData.ImageTags.Primary
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
                            musicData.HDPosterUrl = GetServerBaseUrl() + "/MusicGenres/" + genreName + "/Images/Primary/0?quality=90&height=150&width=&tag=" + itemData.ImageTags.Primary
                            musicData.SDPosterUrl = GetServerBaseUrl() + "/MusicGenres/" + genreName + "/Images/Primary/0?quality=90&height=94&width=&tag=" + itemData.ImageTags.Primary
                        Else If itemData.BackdropImageTags[0]<>"" And itemData.BackdropImageTags[0]<>invalid
                            musicData.HDPosterUrl = GetServerBaseUrl() + "/MusicGenres/" + genreName + "/Images/Backdrop/0?quality=90&height=150&width=&tag=" + itemData.BackdropImageTags[0]
                            musicData.SDPosterUrl = GetServerBaseUrl() + "/MusicGenres/" + genreName + "/Images/Backdrop/0?quality=90&height=94&width=&tag=" + itemData.BackdropImageTags[0]
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
