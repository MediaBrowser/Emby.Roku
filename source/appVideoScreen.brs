'*****************************************************************
'**  Media Browser Roku Client - Video Screen
'*****************************************************************


'**********************************************************
'** Show Video Screen
'**********************************************************

Function showVideoScreen(episode As Object, PlayStart As Dynamic)

    if validateParam(episode, "roAssociativeArray", "showVideoScreen") = false return -1
    
    showVideoScreen2(episode)
    return -1

    port = CreateObject("roMessagePort")
    screen = CreateObject("roVideoScreen")
    screen.SetMessagePort(port)

    screen.SetPositionNotificationPeriod(10)
    screen.SetContent(episode)
    screen.Show()

    'Uncomment his line to dump the contents of the episode to be played
    'PrintAA(episode)
    
    while true
        msg = wait(0, port)

        if type(msg) = "roVideoScreenEvent" then
            print "showHomeScreen | msg = "; msg.getMessage() " | index = "; msg.GetIndex()

            If msg.isRequestFailed() Then
                print "Video request failure: "; msg.GetIndex(); " " msg.GetData()
                exit while

            Else If msg.isStatusMessage() Then
                print "Video status: "; msg.GetIndex(); " " msg.GetData()

            Else If msg.isButtonPressed()
                print "Button pressed: "; msg.GetIndex(); " " msg.GetData()

            Else If msg.isStreamStarted() Then
                Print "started stream"
                PostPlayback(episode.Id, "start")

            Else If msg.isPartialResult() Then
                Print "partial result"

                PostPlayback(episode.Id, "stop", DoubleToString(nowPosition))
                exit while
                
            Else If msg.isFullResult() Then
                Print "full result"

                exit While
                
            Else If msg.isPlaybackPosition() Then
                nowPositionMs# = msg.GetIndex() * 1000
                nowPositionTicks# = nowPositionMs# * 10000
                nowPosition = nowPositionTicks# + PlayStart

                Print "MS: "; nowPositionMs#
                Print "Ticks: "; nowPositionTicks#
                Print "Position:"; nowPosition

                PostPlayback(episode.Id, "progress", DoubleToString(nowPosition))

            Else If msg.isPaused() Then
                nowPosition = msg.GetIndex()
                Print "Paused Position: "; nowPosition

                print "paused video"

            Else If msg.isResumed() Then
                nowPosition = msg.GetIndex()
                print "resume video"
                Print "Resume Position: "; nowPosition

            Else If msg.isScreenClosed() Then
                print "Screen closed"
                exit while


            Else If msg.isStreamSegmentInfo() Then
                print " Stream Seg: = "; msg.getMessage() " | index = "; msg.GetIndex()
                PrintAA(msg.GetInfo())

            Else
                print "Unexpected event type: "; msg.GetType()
            End If
        else
            print "Unexpected message class: "; type(msg)
        end if
    end while

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





'**********************************************************
'** Show Video Screen (Custom)
'**********************************************************

Function showVideoScreen2(episode As Object)

    m.progress = 0 'buffering progress
    m.position = 0 'playback position (in seconds)
    m.paused   = false 'is the video currently paused?

    port = CreateObject("roMessagePort")
    m.canvas = CreateObject("roImageCanvas")
    m.canvas.SetMessagePort(port)
    m.canvas.SetLayer(0, { Color: "#000000" })
    m.canvas.Show()
    m.canvas.AllowUpdates(true)

    m.player = CreateObject("roVideoPlayer")
    m.player.SetMessagePort(port)
    m.player.SetLoop(false)
    m.player.SetPositionNotificationPeriod(10)
    m.player.SetDestinationRect(0,0,0,0)
    m.player.SetContentList([episode.StreamData])
    m.player.Play()

    while true
        msg = wait(0, port)
        if msg <> invalid
            'If this is a startup progress status message, record progress
            'and update the UI accordingly:
            if msg.isStatusMessage() and msg.GetMessage() = "startup progress"
                paused = false
                progress% = msg.GetIndex() / 10
                if m.progress <> progress%
                    m.progress = progress%
                    PaintFullscreenCanvas()
                end if

            'Playback progress (in seconds):
            else if msg.isPlaybackPosition()
                m.position = msg.GetIndex()
                PaintFullscreenCanvas()

            'If the <UP> key is pressed, jump out of this context:
            else if msg.isRemoteKeyPressed()
                index = msg.GetIndex()
                print "Remote button pressed: " + index.tostr()
                if index = 2  '<UP>
                    m.player.Stop()
                    m.canvas.Close()
                    Return -1
                else if index = 3 '<DOWN> (toggle fullscreen)
                '    if m.paint = PaintFullscreenCanvas
                '        m.setup = SetupFramedCanvas
                '        m.paint = PaintFramedCanvas
                '        rect = m.layout.left
                '    else
                '        m.setup = SetupFullscreenCanvas
                '        m.paint = PaintFullscreenCanvas
                '        rect = { x:0, y:0, w:0, h:0 } 'fullscreen
                '        m.player.SetDestinationRect(0, 0, 0, 0) 'fullscreen
                '    end if
                '    m.setup()
                '    m.player.SetDestinationRect(rect)
                else if index = 4 or index = 8  '<LEFT> or <REV>
                    'm.position = m.position - 60
                    'm.player.Seek(m.position * 1000)
                else if index = 5 or index = 9  '<RIGHT> or <FWD>
                    'm.position = m.position + 60
                    'm.player.Seek(m.position * 1000)
                else if index = 13  '<PAUSE/PLAY>
                    if m.paused m.player.Resume() else m.player.Pause()
                end if

            else if msg.isPaused()
                m.paused = true
                PaintFullscreenCanvas()

            else if msg.isResumed()
                m.paused = false
                PaintFullscreenCanvas()

            end if
            'Output events for debug
            print msg.GetType(); ","; msg.GetIndex(); ": "; msg.GetMessage()
            if msg.GetInfo() <> invalid print msg.GetInfo();
        end if
    end while


End Function

Sub PaintFullscreenCanvas()
    list = []

    if m.progress < 100
        color = "#000000" 'opaque black
        list.Push({
            Text: "Loading..." + m.progress.tostr() + "%"
            TargetRect: { x:0, y:0, w:0, h:0 }
        })
    else if m.paused
        color = "#80000000" 'semi-transparent black
        list.Push({
            Text: "Paused"
            TargetRect: { x:0, y:0, w:0, h:0 }
        })
    else
        color = "#00000000" 'fully transparent
    end if

    m.canvas.SetLayer(0, { Color: color, CompositionMode: "Source" })
    m.canvas.SetLayer(1, list)
End Sub
