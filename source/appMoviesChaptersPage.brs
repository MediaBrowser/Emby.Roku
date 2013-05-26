'*****************************************************************
'**  Media Browser Roku Client - Movies Chapters Page
'*****************************************************************


'**********************************************************
'** Show Movies Chapters Page
'**********************************************************

Function ShowMoviesChaptersPage(movieInfo As Object) As Integer
    ' Setup Screen
    port   = CreateObject("roMessagePort")
    screen = CreateObject("roPosterScreen")
    screen.SetMessagePort(port)

    screen.SetBreadcrumbText(movieInfo.Title, "Movies")
    screen.SetListStyle("flat-episodic-16x9")
    screen.SetListDisplayMode("scale-to-fill")

    ' Get Data
    screen.SetContentList(movieInfo.Chapters)

    ' Show Screen
    screen.Show()

    while true
        msg = wait(0, screen.GetMessagePort())

        if type(msg) = "roPosterScreenEvent" Then
            If msg.isListFocused() Then

            Else If msg.isListItemSelected() Then
                selection = msg.GetIndex()

                ' Set Play Status
                PlayStart = (movieInfo.Chapters[selection].StartPositionTicks).ToFloat()

                ' Original Stream URLs
                originalUrls = movieInfo.StreamUrls

                ' Update URLs for Resume
                movieInfo.StreamUrls = AddResumeOffset(movieInfo.StreamUrls, movieInfo.Chapters[selection].StartPositionTicks)

                ' Show Video
                showVideoScreen(movieInfo, PlayStart)

                ' Restore URLs
                movieInfo.StreamUrls = originalUrls
            Else If msg.isScreenClosed() then
                return -1
            End If
        end if
    end while

    return 0
End Function


'**********************************************************
'** Get Chapter Time From Position Ticks
'**********************************************************

Function GetChapterTime(positionTicks As Object) As String
    seconds = Int(((positionTicks).ToFloat() / 10000) / 1000)
    textTime = ""
    hasHours = false

    Print "seconds - "; seconds

    ' Special Check For Zero
    If seconds = 0
        Return "0:00"
    End If
    
    ' Hours
    If seconds >= 3600
        textTime = textTime + itostr(seconds / 3600) + ":"
        hasHours = true
        seconds = seconds Mod 3600
    End If
    
    ' Minutes
    If seconds >= 60
        If hasHours
            textTime = textTime + PadChapterTime(itostr(seconds / 60)) + ":"
        Else
            textTime = textTime + itostr(seconds / 60) + ":"
        End If
        
        seconds = seconds Mod 60
    Else
        If hasHours
            textTime = textTime + "00:"
        End If
    End If

    ' Seconds
    textTime = textTime + PadChapterTime(itostr(seconds))

    return textTime
End Function


'**********************************************************
'** Pad Chapter Time with Zero
'**********************************************************

Function PadChapterTime(timeText As String) As String

    If timeText.Len() < 2
        timeText = "0" + timeText
    End If
    
    Return timeText
End Function
