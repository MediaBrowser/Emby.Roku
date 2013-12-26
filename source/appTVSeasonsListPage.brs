'*****************************************************************
'**  Media Browser Roku Client - TV Show Seasons List Page
'*****************************************************************


'**********************************************************
'** Show TV Show Seasons List Page
'**********************************************************

Function ShowTVSeasonsListPage(seriesInfo As Object) As Integer
    ' Setup Screen
    port   = CreateObject("roMessagePort")
    screen = CreateObject("roPosterScreen")
    screen.SetMessagePort(port)

    screen.SetBreadcrumbText("TV", seriesInfo.Title)
    screen.SetListStyle("flat-episodic-16x9")
    screen.SetListDisplayMode("scale-to-fill")

    ' Initialize TV Metadata
    TvMetadata = InitTvMetadata()

    ' Get Data
    seasonData = TvMetadata.GetSeasons(seriesInfo.Id)

    if seasonData = invalid
        createDialog("Problem Loading TV Seasons", "There was an problem while attempting to get the television seasons list from server. Please make sure your server is running and try again.", "Back")
        return 0
    end if

    seasonIds   = seasonData[0]
    seasonNames = seasonData[1]

    ' Set Season Names
    screen.SetListNames(seasonNames)

    ' Fetch Season 1/Specials
    episodeData = TvMetadata.GetEpisodes(seasonIds[0])
    screen.SetContentList(episodeData.Items)
    screen.SetFocusedList(0)

    ' Fetch Next Unplayed Episode
    nextEpisode = TvMetadata.GetNextEpisode(seriesInfo.Id)

    if nextEpisode <> invalid And nextEpisode.Season <> invalid
        if nextEpisode.Season = 0
            screen.SetFocusedList(nextEpisode.Season)
        else
            screen.SetFocusedList(nextEpisode.Season - 1)
        end if
    end if

    if nextEpisode <> invalid And nextEpisode.Episode <> invalid
        screen.SetFocusedListItem(nextEpisode.Episode - 1)
    else
        screen.SetFocusedListItem(0)
    end if

    ' Set First Load
    firstLoad = true

    ' Set Focus To Episodes
    screen.SetFocusToFilterBanner(false)

    ' Set Loading Message
    loadingMsg = "Loading " + seriesInfo.Title

    ' Show Screen
    screen.Show()

    ' Only fetch theme music if turned on
    If RegRead("prefTVMusic") = "yes" Then
        ' Fetch Theme Music
        themeMusic = TvMetadata.GetThemeMusic(seriesInfo.Id)

        If themeMusic<>invalid And themeMusic.Count() <> 0 Then
            Debug("playing theme music")
            ' Create Audio Player
            player = CreateAudioPlayer()

            ' Add Theme Music To Playlist
            player.AddPlaylist(themeMusic)

            ' Repeat Playlist if turned on
            If RegRead("prefTVMusicLoop") = "yes" Then
                ' Loop
                player.Repeat(true)
            Else
                ' Only Playthrough Once
                player.Repeat(false)
            End If

            ' Start Playing
            player.Play(0)
        Else
            player = invalid
        End If

    Else
        player = invalid
    End If

    while true
        msg = wait(0, screen.GetMessagePort())

        if type(msg) = "roPosterScreenEvent" then
            if msg.isListFocused() then
                ' Set Loading Screen
                screen.SetContentList([])
                if Not firstLoad then screen.SetFocusedListItem(0)
                screen.ShowMessage(loadingMsg + " " + seasonNames[msg.GetIndex()] + "...")

                ' Fetch New Season
                episodeData = TvMetadata.GetEpisodes(seasonIds[msg.GetIndex()])
                screen.SetContentList(episodeData.Items)

                screen.ClearMessage()

            else if msg.isListItemFocused() then
                ' Set First Load
                firstLoad = false

            else if msg.isListItemSelected() then
                selection = msg.GetIndex()

                ShowVideoDetails(episodeData.Items[selection].Id, episodeData.Items, selection, player)
                'episodeIndex = ShowTVDetailPage(episodeData.Items[msg.GetIndex()].Id, episodeData.Items, selection, player)
                'screen.SetFocusedListItem(episodeIndex)

            else if msg.isScreenClosed() then
                return -1
            end if
        end if
    end while

    return 0
End Function
