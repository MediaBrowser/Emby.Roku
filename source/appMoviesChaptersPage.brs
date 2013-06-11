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
                'originalUrls = movieInfo.StreamUrls

                ' Only update URLs if not direct play
                If Not movieInfo.IsDirectPlay Then
                    ' Update URLs for Resume
                    movieInfo.StreamData = AddResumeOffset(movieInfo.StreamData, movieInfo.Chapters[selection].StartPositionTicks)
                End If

                ' Show Video
                showVideoScreen(movieInfo, PlayStart)

                ' Restore URLs
                'movieInfo.StreamUrls = originalUrls

                return -1
            Else If msg.isScreenClosed() then
                return -1
            End If
        end if
    end while

    return 0
End Function

