'*****************************************************************
'**  Media Browser Roku Client - Video Details Page
'*****************************************************************


'**********************************************************
'** Show Video Details Page
'**********************************************************

Function ShowVideoDetails(videoId As String, videoList = invalid, videoIndex = invalid, audioPlayer = invalid) As Integer
    ' Validate Parameter
    if validateParam(videoId, "roString", "ShowVideoDetails") = false return -1

    ' Handle Direct Access
    if videoIndex = invalid
        videoIndex = 0
    end if

    ' Fetch Video Details
    video = RefreshVideoMetadata(videoId)

    ' Setup Screen
    if video.ContentType = "Episode"
        if video.SeriesTitle <> invalid
            screen = CreateSpringboardScreen("TV", video.SeriesTitle, "movie", "rounded-rect-16x9-generic")
        else
            screen = CreateSpringboardScreen("TV", video.Title, "movie", "rounded-rect-16x9-generic")
        end If
        
    else if video.ContentType = "Movie"
        screen = CreateSpringboardScreen("Movies", video.Title, "movie")

    else if video.ContentType = "Video" Or video.ContentType = "Trailer" Or video.ContentType = "MusicVideo"
        screen = CreateSpringboardScreen("", video.Title, "movie")

    end if

    ' Hide Star Rating
    screen.SetStaticRatingEnabled(false)

    ' Refresh Buttons
    RefreshVideoDetails(screen, video)

    ' Remote key id's for left/right navigation
    remoteKeyLeft  = 4
    remoteKeyRight = 5
 
    while true
        msg = wait(0, screen.Port)

        if type(msg) = "roSpringboardScreenEvent" then
            if msg.isRemoteKeyPressed() 
                ' Only allow left/right navigation if videoList provided
                if videoList <> invalid then
                    if msg.GetIndex() = remoteKeyLeft then
                        ' Get Previous Video

                    else if msg.GetIndex() = remoteKeyRight
                        ' Get Next Video

                    end if
                end If

            else if msg.isButtonPressed()
                ' Resume Playing
                if msg.GetIndex() = 1
                    ' Stop Audio before Playing Video
                    if audioPlayer <> invalid And audioPlayer.IsPlaying
                        Debug("Stop theme music")
                        audioPlayer.Stop()
                        sleep(300) ' Give enough time to stop music
                    end if

                    ' Warn for Folder Rips
                    if video.videoType <> "videofile" And RegRead("warnFolderRips") = invalid
                        RegWrite("warnFolderRips", "1")
                        createFolderRipWarningDialog()
                    end if

                    options = {}
                    options.playstart = video.PlaybackPosition

                    ' Create Video Screen
                    createVideoScreen(video, options)

                    ' Refresh Details
                    video = RefreshVideoMetadata(videoId)
                    RefreshVideoDetails(screen, video)

                ' Start Playinng From Beginning
                else if msg.GetIndex() = 2
                    ' Stop Audio before Playing Video
                    if audioPlayer <> invalid And audioPlayer.IsPlaying
                        Debug("Stop theme music")
                        audioPlayer.Stop()
                        sleep(300) ' Give enough time to stop music
                    end if

                    ' Warn for Folder Rips
                    if video.videoType <> "videofile" And RegRead("warnFolderRips") = invalid
                        RegWrite("warnFolderRips", "1")
                        createFolderRipWarningDialog()
                    end if

                    options = {}
                    options.playstart = 0

                    ' Create Video Screen
                    createVideoScreen(video, options)

                    ' Refresh Details
                    video = RefreshVideoMetadata(videoId)
                    RefreshVideoDetails(screen, video)

                ' View Chapters
                else if msg.GetIndex() = 3
                    createVideoChapters(video, audioPlayer)

                    ' Refresh Details
                    video = RefreshVideoMetadata(videoId)
                    RefreshVideoDetails(screen, video)

                ' Audio & Subtitles
                else if msg.GetIndex() = 4

                    ' Create the Audio and Subtitle dialogs
                    options = createAudioAndSubtitleDialog(video.audioStreams, video.subtitleStreams, video.PlaybackPosition)

                    ' Check for cancel
                    If options <> invalid

                        ' Stop Audio before Playing Video
                        if audioPlayer <> invalid And audioPlayer.IsPlaying
                            Debug("Stop theme music")
                            audioPlayer.Stop()
                            sleep(300) ' Give enough time to stop music
                        end if

                        ' Warn for Folder Rips
                        if video.videoType <> "videofile" And RegRead("warnFolderRips") = invalid
                            RegWrite("warnFolderRips", "1")
                            createFolderRipWarningDialog()
                        end if

                        ' Create Video Screen
                        createVideoScreen(video, options)

                        ' Refresh Details
                        video = RefreshVideoMetadata(videoId)
                        RefreshVideoDetails(screen, video)

                    end if

                ' More
                else if msg.GetIndex() = 5

                    ' Create More Video Options Dialog
                    optionSelected = createMoreVideoOptionsDialog(video)

                    ' Select action from the more options dialog
                    if optionSelected = 1
                        postWatchedStatus(videoId, true) ' Mark Played

                    else if optionSelected = 2
                        postWatchedStatus(videoId, false) ' Mark Unplayed

                    else if optionSelected = 3
                        postFavoriteStatus(videoId, true) ' Add Favorite

                    else if optionSelected = 4
                        postFavoriteStatus(videoId, false) ' Remove Favorite

                    end if

                    ' Refresh Details on Action
                    if optionSelected <> -1
                        video = RefreshVideoMetadata(videoId)
                        RefreshVideoDetails(screen, video)
                    end if

                end if

            else if msg.isScreenClosed()
                Debug("Close Video Details Screen")
                exit while
            end if
        else
            Debug("Unexpected message class: " + type(msg))
        end if
    end while

    return videoIndex
End Function


'**************************************************************
'** Refresh the video details page
'**************************************************************

Sub RefreshVideoDetails(screen As Object, video As Object)
    ' Clear Buttons
    screen.ClearButtons()

    ' Only Setup Buttons For Types we recognize
    if video.LocationType = "filesystem" Or video.LocationType = "remote"

        if video.ContentType = "Episode" Or video.ContentType = "Movie"
            if video.PlaybackPosition <> 0 then
                screen.AddButton(1, "Resume playing")
                screen.AddButton(2, "Play from beginning")
            else
                screen.AddButton(2, "Play")
            end if

            screen.AddButton(3, "View Chapters")

            if video.audioStreams.Count() > 1 Or video.subtitleStreams.Count() > 0
                screen.AddButton(4, "Audio & Subtitles")
            end if

            screen.AddButton(5, "More...")

        else if video.ContentType = "Video" Or video.ContentType = "MusicVideo" Or video.ContentType = "AdultVideo"
            if video.PlaybackPosition <> 0 then
                screen.AddButton(1, "Resume playing")
                screen.AddButton(2, "Play from beginning")
            else
                screen.AddButton(2, "Play")
            end if

        else if video.ContentType = "Trailer"
            screen.AddButton(2, "Play")

        end if

    end if

    ' Show Screen
    screen.SetContent(video)
    screen.Show()
End Sub


'**************************************************************
'** Refresh the metadata for the video
'**************************************************************


Function RefreshVideoMetadata(videoId As String) As Object
    ' Validate Parameter
    if validateParam(videoId, "roString", "RefreshVideoMetadata") = false return -1

    ' Fetch Metadata
    metadata = getVideoMetadata(videoId)

    ' Validate Metadata
    if metadata = invalid return -1

    return metadata
End Function


'**********************************************************
'** Get Next Video from List
'**********************************************************

Function getNextVideo(videoList As Object, videoIndex As Integer) As Integer
    ' Validate Parameter
    if validateParam(videoList, "roArray", "getNextVideo") = false return -1

    ' Get the Next Video Index
    nextIndex = videoIndex + 1
    if nextIndex >= videoList.Count() Or nextIndex < 0 then
       nextIndex = 0 
    end if

    video = videoList[nextIndex]

    ' Check to make sure it is loaded
    if video.Id = invalid return -1

    return nextIndex
End Function


'**********************************************************
'** Get Previous Video from List
'**********************************************************

Function getPreviousVideo(videoList As Object, videoIndex As Integer) As Integer
    ' Validate Parameter
    if validateParam(videoList, "roArray", "getPreviousVideo") = false return -1 

    ' Get the Previous Video Index
    prevIndex = videoIndex - 1
    if prevIndex < 0 or prevIndex >= videoList.Count() then
        if videoList.Count() > 0 then
            prevIndex = videoList.Count() - 1
        else
            return -1
        end if
    end if

    video = videoList[prevIndex]

    ' Check to make sure it is loaded
    if video.Id = invalid return -1

    return prevIndex
End Function


'**********************************************************
'** Create Video Chapters Screen
'**********************************************************

Function createVideoChapters(video As Object, audioPlayer = invalid) As Integer

    ' Create Poster Screen
    screen = CreatePosterScreen(video.Title, "Chapters", "flat-episodic-16x9")

    ' Set Content
    screen.SetContent(video.Chapters)

    ' Show Screen
    screen.Show()

    while true
        msg = wait(0, screen.Port)

        if type(msg) = "roPosterScreenEvent" then
            if msg.isListFocused() then
                ' Focused Item
            else if msg.isListItemSelected() then
                selection = msg.GetIndex()

                ' Create the Audio and Subtitle dialogs
                options = createAudioAndSubtitleDialog(video.audioStreams, video.subtitleStreams, video.Chapters[selection].StartPosition, true)

                ' Check for cancel
                If options <> invalid

                    ' Stop Audio before Playing Video
                    if audioPlayer <> invalid And audioPlayer.IsPlaying
                        Debug("Stop theme music")
                        audioPlayer.Stop()
                        sleep(300) ' Give enough time to stop music
                    end if

                    ' Create Video Screen
                    createVideoScreen(video, options)

                    return 1
                end if

            else if msg.isScreenClosed() then
                return 1
            end if
        end if
    end while

    return 0
End Function
