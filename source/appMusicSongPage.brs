'*****************************************************************
'**  Media Browser Roku Client - Music Song Page
'*****************************************************************


'**********************************************************
'** Show Music Song Page
'**********************************************************

Function ShowMusicSongPage(artistInfo As Object) As Integer

    ' Create List Screen
    screen = CreateListScreen(artistInfo.Artist, artistInfo.Title)

    ' Create Audio Player
    player = CreateAudioPlayer(screen.Port)

    ' Get Data
    musicData = GetMusicSongsInAlbum(artistInfo.Id)

    screen.SetHeader("Tracks (" + itostr(musicData.SongInfo.Count()) + ")")
    'screen.SetHeader(Pluralize(musicData.Count(), "Track"))
    screen.SetContent(musicData.SongInfo)

    ' Show Screen
    screen.Show()

    ' Add Album To Playlist
    player.AddPlaylist(musicData.SongStreams)

    ' Remote key id's for navigation
    remoteKeyOK     = 6
    remoteKeyReplay = 7
    remoteKeyRev    = 8
    remoteKeyFwd    = 9
    remoteKeyStar   = 10
    remoteKeyPause  = 13

    while true
        msg = player.MessageHandler(0, "roListScreenEvent")
        'msg = wait(0, screen.Port)

        If type(msg) = "roAudioPlayerEvent" Then
            If msg.isRequestFailed() Then

            Else If msg.isListItemSelected() Then
                Print "Start Song"
                PostAudioPlayback(musicData.SongInfo[player.CurrentIndex].Id, "start")
            
            Else If msg.isRequestSucceeded()
                Print "End Song"
                PostAudioPlayback(musicData.SongInfo[player.CurrentIndex].Id, "stop")
                player.CurrentIndex = player.CurrentIndex + 1

            Else If msg.isFullResult() Then
                Print "End Playlist"
                player.IsPlaying = false

            Else If msg.isPartialResult() Then

            Else If msg.isPaused()
                print "Paused"

            Else If msg.isResumed()
                print "Resume"

            End If
        Else If type(msg) = "roListScreenEvent" Then
            If msg.isListItemFocused() Then

            Else If msg.isListItemSelected() Then
                player.Play(msg.GetIndex())

            Else If msg.isScreenClosed() Then
                Print "close screen"
                If player.IsPlaying Then
                    player.Stop()
                    PostAudioPlayback(musicData.SongInfo[player.CurrentIndex].Id, "stop")
                End If

                return -1

            Else If msg.isRemoteKeyPressed()
                index = msg.GetIndex()

                If index = remoteKeyPause Then
                    If player.IsPaused player.Resume() Else player.Pause()

                Else If index = remoteKeyRev Then
                    Print "Previous Song"
                    If player.IsPlaying player.PrevTrack()

                Else If index = remoteKeyFwd Then
                    Print "Next Song"
                    If player.IsPlaying player.NextTrack()

                End If

            End If

        End If
    end while

    return 0
End Function

'**********************************************************
'** Get Music Songs in Album From Server
'**********************************************************

Function GetMusicSongsInAlbum(artistId As String) As Object

    ' Clean Artist Id and Fields
    artistId = HttpEncode(artistId)
    fields   = HttpEncode("ItemCounts,DateCreated,UserData,AudioInfo,ParentId,Path,MediaStreams")

    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/Users/" + m.curUserProfile.Id + "/Items?ParentId=" + artistId + "&Recursive=true&IncludeItemTypes=Audio&Fields=" + fields + "&SortBy=SortName&SortOrder=Ascending", true)

    if (request.AsyncGetToString())
        while (true)
            msg = wait(0, request.GetPort())

            if (type(msg) = "roUrlEvent")
                code = msg.GetResponseCode()

                if (code = 200)
                    index    = 1
                    list     = CreateObject("roArray", 2, true)
                    streams  = CreateObject("roArray", 2, true)

                    ' Fixes bug within BRS Json Parser
                    regex = CreateObject("roRegex", Chr(34) + "RunTimeTicks" + Chr(34) + ":([0-9]+),", "i")
                    fixedString = regex.ReplaceAll(msg.GetString(), Chr(34) + "RunTimeTicks" + Chr(34) + ":" + Chr(34) + "\1" + Chr(34) + ",")

                    jsonData = ParseJSON(fixedString)
                    for each itemData in jsonData.Items
                        musicData = {
                            Id: itemData.Id
                            ContentType: "Audio"
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

                        ' Setup Song
                        streamData = SetupAudioStream(itemData.Id, itemData.Path)

                        ' Increment Count
                        index = index + 1

                        list.push( musicData )
                        streams.push( streamData )
                    End For
                    
                    return {
                        SongInfo: list
                        SongStreams: streams
                    }
                end if
            else if (event = invalid)
                request.AsyncCancel()
            endif
        end while
    endif

    Return invalid
End Function


'**********************************************************
'** Post Audio Playback to Server
'**********************************************************

Function PostAudioPlayback(audioId As String, action As String) As Boolean

    If action = "start"
        request = CreateURLTransferObject(GetServerBaseUrl() + "/Users/" + m.curUserProfile.Id + "/PlayingItems/" + audioId, true)
    Else If action = "stop"
        request = CreateURLTransferObject(GetServerBaseUrl() + "/Users/" + m.curUserProfile.Id + "/PlayingItems/" + audioId, true)
        request.SetRequest("DELETE")
    End If
    
    if (request.AsyncPostFromString(""))
        while (true)
            msg = wait(0, request.GetPort())

            if (type(msg) = "roUrlEvent")
                code = msg.GetResponseCode()

                If (code = 200)
                    Return true
                End if
            else if (event = invalid)
                request.AsyncCancel()
                exit while
            endif
        end while
    endif

    return false
End Function