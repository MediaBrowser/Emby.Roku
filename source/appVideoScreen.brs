'*****************************************************************
'**  Media Browser Roku Client - Video Screen
'*****************************************************************


'**********************************************************
'** Show Video Screen
'**********************************************************

Function showVideoScreen(episode As Object)

    If type(episode) <> "roAssociativeArray" then
        print "invalid data passed to showVideoScreen"
        return -1
    End if

    port = CreateObject("roMessagePort")
    screen = CreateObject("roVideoScreen")
    screen.SetMessagePort(port)

    episode.PlayStart=245
    episode.StreamStartTimeOffset=245
    screen.SetPositionNotificationPeriod(20)
    screen.SetContent(episode)
    screen.Show()


    'Uncomment his line to dump the contents of the episode to be played
    'PrintAA(episode)

    ' Set Offset For Index
    'If episode.PlayStart >= 30
    '    offset = episode.PlayStart-1
    'Else
        offset = 0
    'End If
    
    while true
        msg = wait(0, port)

        if type(msg) = "roVideoScreenEvent" then
            print "showHomeScreen | msg = "; msg.getMessage() " | index = "; msg.GetIndex()

            If msg.isRequestFailed() Then
                print "Video request failure: "; msg.GetIndex(); " " msg.GetData()

            Else If msg.isStatusMessage() Then
                print "Video status: "; msg.GetIndex(); " " msg.GetData()

            Else If msg.isButtonPressed()
                print "Button pressed: "; msg.GetIndex(); " " msg.GetData()

            Else If msg.isStreamStarted() Then
                Print "started stream"
                PostPlaybackStarted(episode.Id)

            Else If msg.isPartialResult() Then
                Print "partial result"

                nowPosition = msg.GetIndex()
                'RegWrite(episode.ContentId, nowPosition.toStr())
                exit While
                
            Else If msg.isFullResult() Then
                Print "full result"

                'RegDelete(episode.ContentId)
                exit While
                
            Else If msg.isPlaybackPosition() Then
                nowPosition = msg.GetIndex() + offset
                Print "Now Position:"; nowPosition

            Else If msg.isPaused() Then
                print "paused video"

            Else If msg.isResumed() Then
                print "resume video"

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
'** Post Playback Started to Server
'**********************************************************

Function PostPlaybackStarted(videoId As String) As Boolean

    request = CreateURLTransferObject(GetServerBaseUrl() + "/Users/" + m.curUserProfile.Id + "/PlayingItems/" + videoId, true)

    'request.SetRequest("DELETE")

    if (request.AsyncPostFromString(""))
        while (true)
            msg = wait(0, request.GetPort())

            if (type(msg) = "roUrlEvent")
                code = msg.GetResponseCode()

                If (code = 200)
                    Print "playback startup success"
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
'** Post Playback Stopped to Server
'**********************************************************

Function PostPlaybackStopped(videoId As String) As Boolean

    request = CreateURLTransferObject(GetServerBaseUrl() + "/Users/" + m.curUserProfile.Id + "/PlayingItems/" + videoId, true)

    request.SetRequest("DELETE")

    if (request.AsyncPostFromString(""))
        while (true)
            msg = wait(0, request.GetPort())

            if (type(msg) = "roUrlEvent")
                code = msg.GetResponseCode()

                If (code = 200)
                    Print "playback stopped success"
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