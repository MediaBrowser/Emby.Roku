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

    screen.SetBreadcrumbText("", "TV")
    screen.SetDescriptionStyle("movie")
    screen.SetPosterStyle("rounded-rect-16x9-generic")

    ' Fetch / Refresh Screen Details
    tvDetails = RefreshTVDetailPage(screen, episodeId)

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
                        Print "stop theme music"
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
                        Print "stop theme music"
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
                print "tv detail screen closed"
                Exit While
            End If
        Else
            print "Unexpected message class: "; type(msg)
        End If
    end while

    return episodeIndex
End Function


'**********************************************************
'** Get TV Details From Server
'**********************************************************

Function GetTVDetails(episodeId As String) As Object

    if validateParam(episodeId, "roString", "GetTVDetails") = false return -1

    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/Users/" + m.curUserProfile.Id + "/Items/" + episodeId, true)

    if (request.AsyncGetToString())
        while (true)
            msg = wait(0, request.GetPort())

            if (type(msg) = "roUrlEvent")
                code = msg.GetResponseCode()

                if (code = 200)
                    ' Fixes bug within BRS Json Parser
                    regex = CreateObject("roRegex", Chr(34) + "(RunTimeTicks|PlaybackPositionTicks|StartPositionTicks)" + Chr(34) + ":([0-9]+),", "i")
                    fixedString = regex.ReplaceAll(msg.GetString(), Chr(34) + "\1" + Chr(34) + ":" + Chr(34) + "\2" + Chr(34) + ",")

                    itemData = ParseJSON(fixedString)

                    ' Convert Data For Page
                    episodeData = {
                        Id: itemData.Id
                        ContentId: itemData.Id
                        ContentType: "episode"
                        Title: itemData.Name
                        SeriesTitle: itemData.SeriesName
                        Description: itemData.Overview 
                        Rating: itemData.OfficialRating
                        Watched: itemData.UserData.Played
                    }

                    ' Use Actor Area For Series / Season / Episode
                    episodeData.Actors = itemData.SeriesName + " / Season " + Stri(itemData.ParentIndexNumber) + " / Episode "  + Stri(itemData.IndexNumber)

                    ' Check For Production Year
                    If Type(itemData.ProductionYear) = "Integer" Then
                        episodeData.ReleaseDate = Stri(itemData.ProductionYear)
                    End if

                    ' Check For Run Time
                    itemRunTime = itemData.RunTimeTicks
                    If itemRunTime<>"" And itemRunTime<>invalid
                        episodeData.Length = Int(((itemRunTime).ToFloat() / 10000) / 1000)
                    End If

                    ' Check For Playback Position Time
                    itemPlaybackPositionTime = itemData.UserData.PlaybackPositionTicks
                    If itemPlaybackPositionTime<>"" And itemPlaybackPositionTime<>invalid
                        episodeData.PlaybackPosition = (itemPlaybackPositionTime) 'Int(((itemPlaybackPositionTime).ToFloat() / 10000) / 1000)
                    End If

                    ' Check If Item has Image, otherwise use default
                    If itemData.ImageTags.Primary<>"" And itemData.ImageTags.Primary<>invalid
                        episodeData.HDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Primary/0?quality=90&height=152&width=&EnableImageEnhancers=false&tag=" + itemData.ImageTags.Primary
                        episodeData.SDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Primary/0?quality=90&height=90&width=&EnableImageEnhancers=false&tag=" + itemData.ImageTags.Primary
                    Else 
                        episodeData.HDPosterUrl = "pkg://images/items/collection.png"
                        episodeData.SDPosterUrl = "pkg://images/items/collection.png"
                    End If

                    ' Check Media Streams For HD Video And Surround Sound Audio
                    streamInfo = GetStreamInfo(itemData.MediaStreams)

                    episodeData.HDBranded = streamInfo.isHDVideo
                    episodeData.IsHD = streamInfo.isHDVideo

                    If streamInfo.isSSAudio=true
                        episodeData.AudioFormat = "dolby-digital"
                    End If

                    ' Setup Video Player
                    streamData = SetupVideoStreams(episodeId, itemData.VideoType, itemData.Path)

                    If streamData<>invalid
                        episodeData.StreamData = streamData

                        ' Determine Direct Play
                        If StreamData.Stream<>invalid Then
                            episodeData.IsDirectPlay = true
                        Else
                            episodeData.IsDirectPlay = false
                        End If

                    End If

                    ' Setup Watched
                    If itemData.UserData.Played<>invalid And itemData.UserData.Played=true
                        If itemData.UserData.LastPlayedDate<>invalid
                            episodeData.Categories = "Watched on " + formatDateStamp(itemData.UserData.LastPlayedDate)
                        Else
                            episodeData.Categories = "Watched"
                        End If
                    End If

                    ' Setup Chapters
                    If itemData.Chapters<>invalid
                        episodeData.Chapters = CreateObject("roArray", 3, true)
                        chapterCount = 0
                        For each chapterData in itemData.Chapters
                            chapterList = {
                                Title: chapterData.Name
                                ShortDescriptionLine1: chapterData.Name
                                ShortDescriptionLine2: FormatChapterTime(chapterData.StartPositionTicks)
                                StartPositionTicks: chapterData.StartPositionTicks
                            }

                            ' Check If Chapter has Image, otherwise use default
                            If chapterData.ImageTag<>"" And chapterData.ImageTag<>invalid
                                chapterList.HDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Chapter/" + itostr(chapterCount) + "?quality=90&height=141&width=&EnableImageEnhancers=false&tag=" + chapterData.ImageTag
                                chapterList.SDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Chapter/" + itostr(chapterCount) + "?quality=90&height=94&width=&EnableImageEnhancers=false&tag=" + chapterData.ImageTag
                            Else 
                                chapterList.HDPosterUrl = "pkg://images/items/collection.png"
                                chapterList.SDPosterUrl = "pkg://images/items/collection.png"
                            End If

                            chapterCount = chapterCount + 1
                            episodeData.Chapters.push(chapterList)
                        End For
                    End If

                    return episodeData
                Else
                    Return invalid
                End If
            Else If (event = invalid)
                request.AsyncCancel()
            End If
        end while
    endif

    Return invalid
End Function


'**************************************************************
'** Refresh the Contents of the TV Detail Page
'**************************************************************

Function RefreshTVDetailPage(screen As Object, episodeId As String) As Object

    if validateParam(screen, "roSpringboardScreen", "RefreshTVDetailPage") = false return -1
    if validateParam(episodeId, "roString", "RefreshTVDetailPage") = false return -1

    ' Get Data
    tvDetails = GetTVDetails(episodeId)

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
