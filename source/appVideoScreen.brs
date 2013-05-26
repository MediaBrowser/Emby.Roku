'*****************************************************************
'**  Media Browser Roku Client - Video Screen
'*****************************************************************


'**********************************************************
'** Show Video Screen
'**********************************************************

Function showVideoScreen(episode As Object, PlayStart As Dynamic)

    If type(episode) <> "roAssociativeArray" then
        print "invalid data passed to showVideoScreen"
        return -1
    End if

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
