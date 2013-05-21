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

    screen.SetPositionNotificationPeriod(20)
    screen.SetContent(episode)
    screen.Show()

    'Uncomment his line to dump the contents of the episode to be played
    'PrintAA(episode)

    while true
        msg = wait(0, port)

        if type(msg) = "roVideoScreenEvent" then
            print "showHomeScreen | msg = "; msg.getMessage() " | index = "; msg.GetIndex()
            If msg.isScreenClosed() Then
                print "Screen closed"
                exit while
            Else If msg.isRequestFailed() Then
                print "Video request failure: "; msg.GetIndex(); " " msg.GetData() 
            Else If msg.isStatusMessage() Then
                print "Video status: "; msg.GetIndex(); " " msg.GetData() 
            Else If msg.isButtonPressed()
                print "Button pressed: "; msg.GetIndex(); " " msg.GetData()
            Else If msg.isPartialResult() Then
                Print "partial result"
                nowPosition = msg.GetIndex()
                'RegWrite(episode.ContentId, nowPosition.toStr())
                exit while
            Else If msg.isFullResult() Then
                RegDelete(episode.ContentId)
                exit while
            Else If msg.isPlaybackPosition() Then
                nowPosition = msg.GetIndex()
                RegWrite(episode.ContentId, nowPosition.toStr())
            Else
                print "Unexpected event type: "; msg.GetType()
            End If
        else
            print "Unexpected message class: "; type(msg)
        end if
    end while

End Function
