'*****************************************************************
'**  Media Browser Roku Client - Music Song Page
'*****************************************************************


'**********************************************************
'** Show Music Song Page
'**********************************************************

Function ShowMusicSongPage(artistInfo As Object) As Integer

    ' Create List Screen
    screen = CreateListScreen(artistInfo.Artist, artistInfo.Title)

    ' Get Data
    musicData = GetMusicSongsInAlbum(artistInfo.Id)

    screen.SetHeader(Pluralize(musicData.Count(), "Track"))
    screen.SetContent(musicData)

    ' Show Screen
    screen.Show()

    while true
        msg = wait(0, screen.Port)

        if type(msg) = "roListScreenEvent" Then
            If msg.isListItemFocused() Then

            Else If msg.isListItemSelected() Then
                selection = msg.GetIndex()

                'episodeIndex = ShowTVDetailPage(episodeData[msg.GetIndex()].Id, episodeData, selection)
                'screen.SetFocusedListItem(episodeIndex)               

            Else If msg.isScreenClosed() then
                return -1
            End If
        end if
    end while

    return 0
End Function

'**********************************************************
'** Get Music Songs in Album From Server
'**********************************************************

Function GetMusicSongsInAlbum(artistId As String) As Object

    ' Clean Artist Id and Fields
    artistId = HttpEncode(artistId)
    fields   = HttpEncode("ItemCounts,DateCreated,UserData,AudioInfo,ParentId")

    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/Users/" + m.curUserProfile.Id + "/Items?ParentId=" + artistId + "&Recursive=true&IncludeItemTypes=Audio&Fields=" + fields + "&SortBy=SortName&SortOrder=Ascending", true)

    if (request.AsyncGetToString())
        while (true)
            msg = wait(0, request.GetPort())

            if (type(msg) = "roUrlEvent")
                code = msg.GetResponseCode()

                if (code = 200)
                    index    = 1
                    list     = CreateObject("roArray", 2, true)

                    ' Fixes bug within BRS Json Parser
                    regex = CreateObject("roRegex", Chr(34) + "RunTimeTicks" + Chr(34) + ":([0-9]+),", "i")
                    fixedString = regex.ReplaceAll(msg.GetString(), Chr(34) + "RunTimeTicks" + Chr(34) + ":" + Chr(34) + "\1" + Chr(34) + ",")

                    jsonData = ParseJSON(fixedString)
                    for each itemData in jsonData.Items
                        musicData = {
                            Id: itemData.Id
                            ContentType: "Song"
                            'ShortDescriptionLine1: itemData.Name
                        }

                        ' Check If Item has Image, otherwise use default
                        If itemData.ImageTags.Primary<>"" And itemData.ImageTags.Primary<>invalid
                            musicData.HDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.ParentId + "/Images/Primary/0?height=250&width=250&EnableImageEnhancers=false&tag=" + itemData.ImageTags.Primary
                            musicData.SDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.ParentId + "/Images/Primary/0?height=124&width=136&EnableImageEnhancers=false&tag=" + itemData.ImageTags.Primary
                        Else 
                            musicData.HDPosterUrl = "pkg://images/items/collection.png"
                            musicData.SDPosterUrl = "pkg://images/items/collection.png"
                        End If

                        ' Check For Run Time
                        itemRunTime = itemData.RunTimeTicks
                        If itemRunTime<>"" And itemRunTime<>invalid
                            musicData.Length = Int(((itemRunTime).ToFloat() / 10000) / 1000)
                        End If

                        ' Set Title With Extra Info
                        musicData.Title = itostr(index) + ". " + itemData.Name + " - " + FormatChapterTime(itemRunTime)

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
