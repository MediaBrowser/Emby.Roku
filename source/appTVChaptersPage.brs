'*****************************************************************
'**  Media Browser Roku Client - TV Chapters Page
'*****************************************************************


'**********************************************************
'** Show TV Chapters Page
'**********************************************************

Function ShowTVChaptersPage(episodeInfo As Object, audioPlayer=invalid) As Integer
    ' Setup Screen
    port   = CreateObject("roMessagePort")
    screen = CreateObject("roPosterScreen")
    screen.SetMessagePort(port)

    screen.SetBreadcrumbText(episodeInfo.Title, "TV")
    screen.SetListStyle("flat-episodic-16x9")
    screen.SetListDisplayMode("scale-to-fill")

    ' Get Data
    screen.SetContentList(episodeInfo.Chapters)

    ' Show Screen
    screen.Show()

    while true
        msg = wait(0, screen.GetMessagePort())

        if type(msg) = "roPosterScreenEvent" Then
            If msg.isListFocused() Then

            Else If msg.isListItemSelected() Then
                selection = msg.GetIndex()

                ' Stop Audio before playing video
                If audioPlayer<>invalid And audioPlayer.IsPlaying Then
                    Print "stop theme music"
                    audioPlayer.Stop()
                    sleep(300) ' Give enough time to stop music
                End If

                ' Set Play Status
				if IsNumeric(episodeInfo.Chapters[selection].StartPositionTicks) then
					PlayStart = episodeInfo.Chapters[selection].StartPositionTicks
				else
					PlayStart = (episodeInfo.Chapters[selection].StartPositionTicks).ToFloat()
				end if				
                

                ' Original Stream URLs
                'originalUrls = episodeInfo.StreamUrls

                ' Only update URLs if not direct play
                If Not episodeInfo.IsDirectPlay Then
                    ' Update URLs for Resume
                    episodeInfo.StreamData = AddResumeOffset(episodeInfo.StreamData, episodeInfo.Chapters[selection].StartPositionTicks)
                End If

                ' Show Video
                showVideoScreen(episodeInfo, PlayStart)

                ' Restore URLs
                'episodeInfo.StreamUrls = originalUrls

                return -1
            Else If msg.isScreenClosed() then
                return -1
            End If
        end if
    end while

    return 0
End Function

