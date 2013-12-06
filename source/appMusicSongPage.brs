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

    ' Initialize Music Metadata
    MusicMetadata = InitMusicMetadata()

    ' Get Data
    musicData = MusicMetadata.GetAlbumSongs(artistInfo.Id)

    ' Get Total Duration
    totalDuration = GetTotalDuration(musicData.SongInfo)

    screen.SetHeader("Tracks (" + itostr(musicData.SongInfo.Count()) + ") - " + totalDuration)

    ' Back Button For Legacy Devices
    if getGlobalVar("legacyDevice")
        backButton = {
            Title: ">> Back <<",
            ContentType: "exit",
        }

        musicData.SongInfo.Unshift( backButton )
    end if

    screen.SetContent(musicData.SongInfo)

    ' Show Screen
    screen.Show()

    ' Add Album To Playlist
    player.AddPlaylist(musicData.SongStreams)

    ' Only Playthrough Once
    player.Repeat(false)

    ' Previous Icon Location
    prevIconIndex = invalid

    ' Focused Item Index
    focusedItemIndex = 0

    ' Remote key id's for navigation
    remoteKeyOK     = 6
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
                postAudioPlayback(musicData.SongInfo[player.CurrentIndex].Id, "start")

                ' Display Speaker Icon
                If prevIconIndex<>invalid HideSpeakerIcon(screen, prevIconIndex, musicData.SongInfo)
                prevIconIndex = ShowSpeakerIcon(screen, player.CurrentIndex, musicData.SongInfo)

                ' Refocus Item
                screen.SetFocusedItem(focusedItemIndex)

            Else If msg.isRequestSucceeded()
                Print "End Song"
                postAudioPlayback(musicData.SongInfo[player.CurrentIndex].Id, "stop")
                player.CurrentIndex = player.CurrentIndex + 1

            Else If msg.isFullResult() Then
                Print "End Playlist"
                player.IsPlaying = false
                HideSpeakerIcon(screen, prevIconIndex, musicData.SongInfo, true)

            Else If msg.isPartialResult() Then

            Else If msg.isPaused()
                print "Paused"

                ' Display Pause Icon
                 ShowPauseIcon(screen, player.CurrentIndex, musicData.SongInfo)

                ' Refocus Item
                screen.SetFocusedItem(focusedItemIndex)

            Else If msg.isResumed()
                print "Resume"

                ' Display Speaker Icon
                ShowSpeakerIcon(screen, player.CurrentIndex, musicData.SongInfo)

                ' Refocus Item
                screen.SetFocusedItem(focusedItemIndex)

            End If
        Else If type(msg) = "roListScreenEvent" Then
            If msg.isListItemFocused() Then
                focusedItemIndex = msg.GetIndex()

            Else If msg.isListItemSelected() Then
                if musicData.SongInfo[msg.GetIndex()].ContentType = "exit"
                    Debug("Close Music Album Screen")
                    If player.IsPlaying Then
                        player.Stop()
                        postAudioPlayback(musicData.SongInfo[player.CurrentIndex].Id, "stop")
                    End If

                    return -1
                else
                    player.Play(msg.GetIndex())
                end if

            Else If msg.isScreenClosed() Then
                Debug("Close Music Album Screen")
                If player.IsPlaying Then
                    player.Stop()
                    postAudioPlayback(musicData.SongInfo[player.CurrentIndex].Id, "stop")
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
'** Show Speaker Icon
'**********************************************************

Function ShowSpeakerIcon(screen As Object, index As Integer, musicData As Object) As Integer
    musicData[index].HDSmallIconUrl = "pkg://images/items/SpeakerIcon.png"
    musicData[index].SDSmallIconUrl = "pkg://images/items/SpeakerIcon.png"

    screen.SetContent(musicData)
    screen.Show()

    Return index
End Function


'**********************************************************
'** Show Pause Icon
'**********************************************************

Function ShowPauseIcon(screen As Object, index As Integer, musicData As Object)
    musicData[index].HDSmallIconUrl = "pkg://images/items/PauseIcon.png"
    musicData[index].SDSmallIconUrl = "pkg://images/items/PauseIcon.png"

    screen.SetContent(musicData)
    screen.Show()
End Function


'**********************************************************
'** Hide Speaker Icon
'**********************************************************

Function HideSpeakerIcon(screen As Object, index As Integer, musicData As Object, refreshScreen=invalid)
    musicData[index].HDSmallIconUrl = false
    musicData[index].SDSmallIconUrl = false

    If refreshScreen<>invalid Then
        screen.SetContent(musicData)
        screen.Show()
    End If
End Function


'**********************************************************
'** Get the total duration for all tracks
'**********************************************************

Function GetTotalDuration(songs As Object) As String
    ' Add total time in seconds
    total = 0
    For each songData in songs
        total = total + songData.Length
    End For

    Return FormatTime(total)
End Function


