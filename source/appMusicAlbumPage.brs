'*****************************************************************
'**  Media Browser Roku Client - Music Album Page
'*****************************************************************


'**********************************************************
'** Show Music Album Page
'**********************************************************

Function ShowMusicAlbumPage(artistInfo As Object) As Integer

    ' Create Poster Screen
    screen = CreatePosterScreen("Music", artistInfo.Title, "arced-square")

    ' Get Default Data
    musicData = GetMusicAlbumsByArtist(artistInfo.Title)

    screen.Screen.SetContentList(musicData)

    ' Show Screen
    screen.Show()

    while true
        msg = wait(0, screen.Port)

        if type(msg) = "roPosterScreenEvent" Then
            If msg.isListFocused() Then

            Else If msg.isListItemSelected() Then
                selection = msg.GetIndex()
                ShowMusicSongPage(musicData[selection])

            Else If msg.isScreenClosed() then
                return -1
            End If
        end if
    end while

    return 0
End Function

'**********************************************************
'** Get Music Albums By Artist From Server
'**********************************************************

Function GetMusicAlbumsByArtist(artistName As String) As Object

    ' Clean Artist Name and Fields
    artistName = HttpEncode(artistName)
    fields     = HttpEncode("ItemCounts,DateCreated,UserData,AudioInfo,ParentId")

    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/Users/" + m.curUserProfile.Id + "/Items?Artists=" + artistName + "&Recursive=true&IncludeItemTypes=MusicAlbum&Fields=" + fields + "&SortBy=SortName&SortOrder=Ascending", true)

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
                            ContentType: "Album"
                            ShortDescriptionLine1: itemData.Name
                            ShortDescriptionLine2: Pluralize(itemData.ChildCount, "song")
                        }

                        ' Check If Item has Image, otherwise use default
                        If itemData.ImageTags.Primary<>"" And itemData.ImageTags.Primary<>invalid
                            musicData.HDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Primary/0?height=300&width=300&EnableImageEnhancers=false&tag=" + itemData.ImageTags.Primary
                            musicData.SDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Primary/0?height=145&width=285&EnableImageEnhancers=false&tag=" + itemData.ImageTags.Primary
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
