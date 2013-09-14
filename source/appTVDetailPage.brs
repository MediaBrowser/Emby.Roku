'*****************************************************************
'**  Media Browser Roku Client - TV Detail Page
'*****************************************************************


'**********************************************************
'** Show TV Details Page
'**********************************************************

Function ShowTVDetailPage(episodeId As String, episodeList=invalid, episodeIndex=invalid, audioPlayer=invalid) As Integer

    if validateParam(episodeId, "roString", "ShowTVDetailPage") = false return -1

    ' Handle Direct Access from Home
    If episodeIndex=invalid Then
        episodeIndex = 0
    End If

    ' Setup Screen
    port   = CreateObject("roMessagePort")
    screen = CreateObject("roSpringboardScreen")
    screen.SetMessagePort(port)

    screen.SetDescriptionStyle("movie")
    screen.SetPosterStyle("rounded-rect-16x9-generic")

    ' Fetch / Refresh Screen Details
    tvDetails = RefreshTVDetailPage(screen, episodeId)

    ' Set Breadcrumbs
    if tvDetails.SeriesTitle <> invalid
        screen.SetBreadcrumbText("TV", tvDetails.SeriesTitle)
    else
        screen.SetBreadcrumbText("TV", tvDetails.Title)
    end if

    ' Hide Star Rating
    screen.SetStaticRatingEnabled(false)

    ' Remote key id's for left/right navigation
    remoteKeyLeft  = 4
    remoteKeyRight = 5
 
    while true
        msg = wait(0, screen.GetMessagePort())

        if type(msg) = "roSpringboardScreenEvent" then
            If msg.isRemoteKeyPressed() 
                ' Only allow left/right navigation if episodeList provided
                If episodeList<>invalid Then
                    If msg.GetIndex() = remoteKeyLeft Then
                        episodeIndex = getPreviousEpisode(episodeList, episodeIndex)

                        If episodeIndex <> -1
                            episodeId = episodeList[episodeIndex].Id
                            tvDetails = RefreshTVDetailPage(screen, episodeId)
                        End If
                    Else If msg.GetIndex() = remoteKeyRight
                        episodeIndex = getNextEpisode(episodeList, episodeIndex)

                        If episodeIndex <> -1
                            episodeId = episodeList[episodeIndex].Id
                            tvDetails = RefreshTVDetailPage(screen, episodeId)
                        End If
                    End If
                End If
            Else If msg.isButtonPressed() 
                If msg.GetIndex() = 1
                    ' Stop Audio before playing video
                    If audioPlayer<>invalid And audioPlayer.IsPlaying Then
                        Debug("stop theme music")
                        audioPlayer.Stop()
                        sleep(300) ' Give enough time to stop music
                    End If

                    ' Set Saved Play Status
                    If tvDetails.PlaybackPosition<>"" And tvDetails.PlaybackPosition<>"0" Then
                        PlayStart = (tvDetails.PlaybackPosition).ToFloat()

                        ' Only update URLs if not direct play
                        If Not tvDetails.IsDirectPlay Then
                            ' Update URLs for Resume
                            tvDetails.StreamData = AddResumeOffset(tvDetails.StreamData, tvDetails.PlaybackPosition)
                        End If
                    Else
                        PlayStart = 0
                    End If

                    showVideoScreen(tvDetails, PlayStart)
                    tvDetails = RefreshTVDetailPage(screen, episodeId)
                End If
                If msg.GetIndex() = 2
                    ' Stop Audio before playing video
                    If audioPlayer<>invalid And audioPlayer.IsPlaying Then
                        Debug("stop theme music")
                        audioPlayer.Stop()
                        sleep(300) ' Give enough time to stop music
                    End If

                    ' Show Error Dialog For Unsupported video types - Should be temporary call
                    If tvDetails.DoesExist("StreamData")=false
                        ShowDialog("Playback Error", "That video type is not playable yet.", "Back")
                    Else
                        PlayStart = 0
                        showVideoScreen(tvDetails, PlayStart)
                        tvDetails = RefreshTVDetailPage(screen, episodeId)
                    End If
                End If
                If msg.GetIndex() = 3
                    ShowTVChaptersPage(tvDetails, audioPlayer)
                    tvDetails = RefreshTVDetailPage(screen, episodeId)
                End If
            Else If msg.isScreenClosed()
                Debug("tv detail screen closed")
                Exit While
            End If
        Else
            Debug("Unexpected message class: " + type(msg))
        End If
    end while

    return episodeIndex
End Function


'**************************************************************
'** Refresh the Contents of the TV Detail Page
'**************************************************************

Function RefreshTVDetailPage(screen As Object, episodeId As String) As Object

    if validateParam(screen, "roSpringboardScreen", "RefreshTVDetailPage") = false return -1
    if validateParam(episodeId, "roString", "RefreshTVDetailPage") = false return -1

    ' Initialize TV Metadata
    TvMetadata = InitTvMetadata()

    ' Get Data
    tvDetails = TvMetadata.GetEpisodeDetails(episodeId)

    ' Setup Buttons
    screen.ClearButtons()

    If tvDetails.PlaybackPosition<>"" And tvDetails.PlaybackPosition<>"0" Then
        screen.AddButton(1, "Resume playing")    
        screen.AddButton(2, "Play from beginning")    
    Else
        screen.AddButton(2, "Play")
    End If

    screen.AddButton(3, "View Chapters")

    ' Show Screen
    screen.SetContent(tvDetails)
    screen.Show()

    Return tvDetails
End Function


'**********************************************************
'** Get Next Episode from List
'**********************************************************

Function getNextEpisode(episodeList As Object, episodeIndex As Integer) As Integer

    if validateParam(episodeList, "roArray", "getNextEpisode") = false return -1

    nextIndex = episodeIndex + 1
    if nextIndex >= episodeList.Count() Or nextIndex < 0 then
       nextIndex = 0 
    end if

    episode = episodeList[nextIndex]

    if validateParam(episode, "roAssociativeArray", "getNextEpisode") = false return -1 

    return nextIndex

End Function


'**********************************************************
'** Get Previous Episode from List
'**********************************************************

Function getPreviousEpisode(episodeList As Object, episodeIndex As Integer) As Integer

    if validateParam(episodeList, "roArray", "getPreviousEpisode") = false return -1 

    prevIndex = episodeIndex - 1
    if prevIndex < 0 or prevIndex >= episodeList.Count() then
        if episodeList.Count() > 0 then
            prevIndex = episodeList.Count() - 1 
        else
            return -1
        end if
    end if

    episode = episodeList[prevIndex]

    if validateParam(episode, "roAssociativeArray", "getPreviousEpisode") = false return -1 

    return prevIndex

End Function
