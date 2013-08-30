'*****************************************************************
'**  Media Browser Roku Client - Video Screen
'*****************************************************************


'**********************************************************
'** Show Video Screen
'**********************************************************

Function showVideoScreen(episode As Object, PlayStart As Dynamic)

    if validateParam(episode, "roAssociativeArray", "showVideoScreen") = false return -1

    'PrintAA(episode)

    m.videoInfo = episode ' All the information about the video

    m.progress = 0 'buffering progress
    m.position = 0 'playback position (in seconds)
    m.runtime  = episode.Length 'runtime (in seconds)

    m.playbackPosition    = 0 ' (in seconds)
    m.paused   = false 'is the video currently paused?
    m.moreinfo = false 'more information about video

    port = CreateObject("roMessagePort")

    m.canvas = CreateObject("roImageCanvas")
    m.canvas.SetMessagePort(port)
    m.canvas.SetLayer(0, { Color: "#000000" })
    m.canvas.Show()

    m.player = CreateObject("roVideoPlayer")
    m.player.SetMessagePort(port)
    m.player.SetPositionNotificationPeriod(1)
    m.player.SetDestinationRect(0,0,0,0)
    m.player.AddContent(episode.StreamData)
    m.player.Play()

    m.canvas.AllowUpdates(false)
    PaintFullscreenCanvas()
    m.canvas.AllowUpdates(true)

    ' Stream Started
    streamStarted = false

    ' Currently Seeking
    currentSeeking = false

    ' PlayStart in seconds
    PlayStartSeconds = Int((PlayStart / 10000) / 1000)

    ' Direct Play Offset
    If episode.IsDirectPlay And PlayStartSeconds<>0 Then
        Debug("Seek To: " + itostr(PlayStartSeconds * 1000))
        m.player.Seek(PlayStartSeconds * 1000)
    End If

    ' Remote key id's for navigation
    remoteKeyBack   = 0
    remoteKeyUp     = 2
    remoteKeyDown   = 3
    remoteKeyLeft   = 4
    remoteKeyRight  = 5
    remoteKeyOK     = 6
    remoteKeyReplay = 7
    remoteKeyRev    = 8
    remoteKeyFwd    = 9
    remoteKeyStar   = 10
    remoteKeyPause  = 13

    while true
        msg = wait(0, port)

        If type(msg) = "roVideoPlayerEvent" Then

            If msg.isFullResult() Then
                Debug("full result")
                PostPlayback(episode.Id, "stop", DoubleToString(nowPosition))
                exit while

            Else If msg.isPartialResult() Then
                Debug("partial result")
                PostPlayback(episode.Id, "stop", DoubleToString(nowPosition))
                exit while

            Else If msg.isRequestFailed() Then
                Debug("Video request failure: " + itostr(msg.GetIndex()) + " " + itostr(msg.GetData()) + " " + msg.GetMessage())
                exit While
                
            Else If msg.isScreenClosed() Then
                Debug("Screen closed")
                exit while

            Else If msg.isStreamStarted() Then
                Debug("--- started stream ---")
                PostPlayback(episode.Id, "start")

            Else If msg.isStatusMessage() and msg.GetMessage() = "startup progress"
                ' Extra Check to Prevent Playback Loop
                If streamStarted Then
                    Debug("--- 2nd attempt at stream started, exit loop ---")
                    'PostPlayback(episode.Id, "stop", DoubleToString(nowPosition))
                    'exit while
                End If

                paused = false
                progress% = msg.GetIndex() / 10
                If m.progress <> progress%
                    m.progress = progress%
                    PaintFullscreenCanvas()
                End If

            Else If msg.isPlaybackPosition() Then
                ' Direct Play does not need offset added
                If episode.IsDirectPlay Then
                    nowPositionSec = msg.GetIndex()
                    nowPositionMs# = msg.GetIndex() * 1000
                    nowPositionTicks# = nowPositionMs# * 10000
                    nowPosition = nowPositionTicks#

                    m.position = msg.GetIndex()
                Else 
                    nowPositionSec = msg.GetIndex() + PlayStartSeconds
                    nowPositionMs# = msg.GetIndex() * 1000
                    nowPositionTicks# = nowPositionMs# * 10000
                    nowPosition = nowPositionTicks# + PlayStart

                    m.position = msg.GetIndex() + PlayStartSeconds
                End If

                PaintFullscreenCanvas()

                ' Stream Started - doing flag here because isStreamStarted()
                ' gets fired before startup progress completes
                streamStarted = true

                ' Playback restart, so no longer seeking
                currentSeeking = false

                'Debug("Time: " + FormatTime(nowPositionSec) + " / " + FormatTime(episode.Length))
                'Debug("Seconds: " + DoubleToString(nowPositionSec))
                'Debug("MS: " + DoubleToString(nowPositionMs#))
                'Debug("Ticks: " + DoubleToString(nowPositionTicks#))
                'Debug("Position:" + DoubleToString(nowPosition))

                ' Only Post Playback every 10 seconds
                If msg.GetIndex() Mod 10 = 0
                    PostPlayback(episode.Id, "progress", DoubleToString(nowPosition))
                End If

            Else If msg.isPaused() Then
                Debug("Paused Position: " + DoubleToString(nowPositionSec))

                m.paused = true
                m.moreinfo = false ' Hide more info on pause

                PaintFullscreenCanvas()

            Else If msg.isResumed() Then
                Debug("Resume Position: " + DoubleToString(nowPositionSec))

                m.paused = false
                PaintFullscreenCanvas()

            'Else If msg.isStatusMessage() Then
            '    Debug("Video status: " + itostr(msg.GetIndex()) + " " + itostr(msg.GetData()))
            '    Debug("Video message: " + itostr(msg.GetMessage()))

            End If

        Else If type(msg) = "roImageCanvasEvent" Then

            If msg.isRemoteKeyPressed()
                index = msg.GetIndex()

                If index = remoteKeyUp or index = remoteKeyBack Then
                    PostPlayback(episode.Id, "stop", DoubleToString(nowPosition))
                    exit while

                Else If index = remoteKeyDown Then
                    If Not m.paused Then
                        If m.moreinfo Then
                            m.moreinfo = false
                        Else
                            m.moreinfo = true
                        End If
                    End If
                    PaintFullscreenCanvas()
                    
                Else If index = remoteKeyLeft or index = remoteKeyRev Then
                    ' Direct Play can Seek
                    If episode.IsDirectPlay Then
                        streamStarted = false ' Seeking, so reset stream started
                        m.paused = false ' Seeking so, un-pause

                        m.position = m.position - 60

                        ' Can't Seek below start
                        If m.position < 0 Then m.position = 0

                        If Not currentSeeking Then
                            currentSeeking = true
                            m.player.Seek(m.position * 1000)
                        End If

                    Else
                    End If

                Else If index = remoteKeyReplay Then
                    ' Direct Play can Seek
                    If episode.IsDirectPlay Then
                        streamStarted = false ' Seeking, so reset stream started
                        m.paused = false ' Seeking so, un-pause

                        m.position = m.position - 8

                        ' Can't Seek below start
                        If m.position < 0 Then m.position = 0

                        If Not currentSeeking Then
                            currentSeeking = true
                            m.player.Seek(m.position * 1000)
                        End If

                    Else
                    End If

                Else If index = remoteKeyRight or index = remoteKeyFwd Then

                    ' Direct Play can Seek
                    If episode.IsDirectPlay Then
                        streamStarted = false ' Seeking, so reset stream started
                        m.paused = false ' Seeking so, un-pause

                        m.position = m.position + 60

                        ' Can't Seek after end
                        If m.position > m.runtime Then m.position = m.runtime-1

                        If Not currentSeeking Then
                            currentSeeking = true
                            m.player.Seek(m.position * 1000)
                        End If

                    Else

                    End If

                Else If index = remoteKeyPause or index = remoteKeyOK Then
                    If m.paused m.player.Resume() Else m.player.Pause()

                End if

            End If

        End If
        
        'Output events for debug
        'Debug(msg.GetType() + "," + itostr(msg.GetIndex()) + ": " + msg.GetMessage())
        'if msg.GetInfo() <> invalid Debug(msg.GetInfo())

    end while

    m.player.Stop()
    m.canvas.Close()

    return true
End Function


'**********************************************************
'** Post Playback to Server
'**********************************************************

Function PostPlayback(videoId As String, action As String, position=invalid) As Boolean

    If action = "start"
        request = CreateURLTransferObject(GetServerBaseUrl() + "/Users/" + m.curUserProfile.Id + "/PlayingItems/" + videoId, true)
    Else If action = "progress"
        request = CreateURLTransferObject(GetServerBaseUrl() + "/Users/" + m.curUserProfile.Id + "/PlayingItems/" + videoId + "/Progress?PositionTicks=" + position, true)
    Else If action = "stop"
        request = CreateURLTransferObject(GetServerBaseUrl() + "/Users/" + m.curUserProfile.Id + "/PlayingItems/" + videoId + "?PositionTicks=" + position, true)
        request.SetRequest("DELETE")
    End If
    
    if (request.AsyncPostFromString(""))
        while (true)
            msg = wait(0, request.GetPort())

            if (type(msg) = "roUrlEvent")
                code = msg.GetResponseCode()

                if (code = 200)
                    return true
                else
                    Debug("Failed to Post Playback Progress")
                    return false
                end if
            else if (event = invalid)
                request.AsyncCancel()
                exit while
            end if
        end while
    end if

    return false
End Function


'**********************************************************
'** Paint Canvas
'**********************************************************

Sub PaintFullscreenCanvas()
    list = []
    progress_bar = invalid
    more_info = invalid

    If m.progress < 100
        color = "#000000" 'opaque black
        list.Push({
            Text: "Loading..." + m.progress.tostr() + "%"
            TargetRect: { x:0, y:0, w:0, h:0 }
        })

    Else If m.paused
        color = "#80000000" 'semi-transparent black
        list.Push({
            Text: "Paused"
            TargetRect: { x:0, y:0, w:0, h:0 }
        })

        progress_bar = BuildProgressBar()

    Else If m.moreinfo
        color = "#00000000" 'fully transparent

        more_info = BuildMoreInfo()

    Else
        color = "#00000000" 'fully transparent
        m.canvas.ClearLayer(2) 'hide progress bar
        m.canvas.ClearLayer(3) 'hide more info

    End If

    m.canvas.SetLayer(0, { Color: color, CompositionMode: "Source" })
    m.canvas.SetLayer(1, list)

    ' Only Show Progress Bar If Paused
    If progress_bar<>invalid Then
        m.canvas.SetLayer(2, progress_bar)
    End If

    ' Only Show More Info If Button Pressed
    If more_info<>invalid Then
        m.canvas.SetLayer(3, more_info)
    End If
End Sub


'**********************************************************
'** Build Progress Bar for Canvas
'**********************************************************

Function BuildProgressBar() As Object
    progress_bar = []

    mode = CreateObject("roDeviceInfo").GetDisplayMode()

    If mode = "720p"
        If m.position < 10
            barWidth = 1
        Else
            barWidth = Int((m.position / m.runtime) * 600)
        End If
        
        'overlay       = {TargetRect: {x: 250, y: 600, w: 800, h: 150}, Color: "#80000000" }
        barBackground = {TargetRect: {x: 350, y: 650, w: 600, h: 18}, url: "pkg:/images/progressbar/background.png"}
        barPosition   = {TargetRect: {x: 351, y: 651, w: barWidth, h: 16}, url: "pkg:/images/progressbar/bar.png"}

        'progress_bar.Push(overlay)
        progress_bar.Push(barBackground)
        progress_bar.Push(barPosition)

        ' Current Progress
        progress_bar.Push({
            Text: FormatTime(m.position)
            TextAttrs: { font: "small", color: "#FFFFFF" }
            TargetRect: { x: 250, y: 642, w: 100, h: 37 }
        })

        ' Run Time
        progress_bar.Push({
            Text: FormatTime(m.runtime)
            TextAttrs: { font: "small", color: "#FFFFFF" }
            TargetRect: { x: 952, y: 642, w: 100, h: 37 }
        })
    Else

    End If

    return progress_bar
End Function


'**********************************************************
'** Build More Information for Canvas
'**********************************************************

Function BuildMoreInfo() As Object
    more_info = []

    mode = CreateObject("roDeviceInfo").GetDisplayMode()

    If mode = "720p"
        overlay = {TargetRect: {x: 0, y: 460, w: 1280, h: 200}, Color: "#80000000" }
        more_info.Push(overlay)

        If m.videoInfo.ContentType = "movie" Or m.videoInfo.ContentType = "Movie"

            ' Show Title
            more_info.Push({
                Text: m.videoInfo.Title
                TextAttrs: { font: "medium", color: "#FFFFFF", halign: "left", valign: "top" }
                TargetRect: { x: 250, y: 475, w: 750, h: 35 }
            })

            ' Episode Description
            more_info.Push({
                Text:  Truncate(m.videoInfo.Description, 250, true)
                TextAttrs: { font: "small", color: "#FFFFFF", halign: "left", valign: "top" }
                TargetRect: { x: 250, y: 515, w: 750, h: 40 }
            })

        Else If m.videoInfo.ContentType = "episode" Or m.videoInfo.ContentType = "Episode"

            ' Show Title
            more_info.Push({
                Text: m.videoInfo.SeriesTitle
                TextAttrs: { font: "medium", color: "#FFFFFF", halign: "left", valign: "top" }
                TargetRect: { x: 250, y: 475, w: 750, h: 35 }
            })

            ' Episode Title
            more_info.Push({
                Text:  m.videoInfo.Title
                TextAttrs: { font: "small", color: "#FFFFFF", halign: "left", valign: "top" }
                TargetRect: { x: 250, y: 515, w: 750, h: 35 }
            })

            ' Episode Description
            more_info.Push({
                Text:  Truncate(m.videoInfo.Description, 250, true)
                TextAttrs: { font: "small", color: "#FFFFFF", halign: "left", valign: "top" }
                TargetRect: { x: 250, y: 555, w: 750, h: 40 }
            })

        Else
            Return invalid

        End If
    Else

    End If

    return more_info
End Function
