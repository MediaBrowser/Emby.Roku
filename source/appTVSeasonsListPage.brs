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

    screen.SetBreadcrumbText(seriesInfo.Title, "TV")
    screen.SetListStyle("flat-episodic-16x9")
    screen.SetListDisplayMode("scale-to-fill")

    ' Get Data
    seasonData = GetTVSeasons(seriesInfo.Id)
    screen.SetListNames(seasonData.seasonNames)

    ' Fetch Season 1
    episodeData = GetTVEpisodes(seasonData.seasonIds[0])
    screen.SetContentList(episodeData)

    ' Show Screen
    screen.Show()

    ' Fetch Theme Music
    themeMusic = GetTVThemeMusic(seriesInfo.Id)

    If themeMusic<>invalid And themeMusic.Count() <> 0 Then
        Print "playing theme music"
        ' Create Audio Player
        player = CreateAudioPlayer()

        ' Add Theme Music To Playlist
        player.AddPlaylist(themeMusic)

        ' Only Playthrough Once
        player.Repeat(false)

        ' Start Playing
        player.Play(0)
    Else
        player = invalid
    End If

    while true
        msg = wait(0, screen.GetMessagePort())

        if type(msg) = "roPosterScreenEvent" Then
            If msg.isListFocused() Then
                m.curSeason = msg.GetIndex()
                m.curShow   = 0

                screen.SetContentList([])
                screen.SetFocusedListItem(m.curShow)
                screen.ShowMessage("Retrieving")

                ' Fetch New Season
                episodeData = GetTVEpisodes(seasonData.seasonIds[Msg.GetIndex()])
                screen.SetContentList(episodeData)

                screen.ClearMessage()
            Else If msg.isListItemSelected() Then
                selection = msg.GetIndex()

                episodeIndex = ShowTVDetailPage(episodeData[msg.GetIndex()].Id, episodeData, selection, player)
                screen.SetFocusedListItem(episodeIndex)

            Else If msg.isScreenClosed() then
                return -1
            End If
        end if
    end while

    return 0
End Function


'**********************************************************
'** Get All TV Episodes From Server
'**********************************************************

Function GetTVSeasons(seriesId As String) As Object
    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/Users/" + m.curUserProfile.Id + "/Items?ParentId=" + seriesId + "&Recursive=true&IncludeItemTypes=Season&SortBy=SortName&SortOrder=Ascending", true)

    if (request.AsyncGetToString())
        while (true)
            msg = wait(0, request.GetPort())

            if (type(msg) = "roUrlEvent")
                code = msg.GetResponseCode()

                if (code = 200)
                    list     = CreateObject("roArray", 10, true)
                    names    = CreateObject("roArray", 10, true)
                    jsonData = ParseJSON(msg.GetString())
                    for each itemData in jsonData.Items
                        list.push( itemData.Id )
                        names.push( itemData.Name )
                    end for
                    return {
                        seasonNames: names
                        seasonIds: list
                    }
                endif
            else if (event = invalid)
                request.AsyncCancel()
            endif
        end while
    endif

    Return invalid
End Function


'**********************************************************
'** Get All TV Episodes From Server
'**********************************************************

Function GetTVEpisodes(seasonId As String) As Object
    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/Users/" + m.curUserProfile.Id + "/Items?ParentId=" + seasonId + "&Recursive=true&IncludeItemTypes=Episode&Fields=SeriesInfo%2COverview%2CMediaStreams%2CUserData&SortBy=SortName&SortOrder=Ascending", true)

    if (request.AsyncGetToString())
        while (true)
            msg = wait(0, request.GetPort())

            if (type(msg) = "roUrlEvent")
                code = msg.GetResponseCode()

                if (code = 200)
                    list     = CreateObject("roArray", 2, true)

                    ' Fixes bug within BRS Json Parser
                    regex = CreateObject("roRegex", Chr(34) + "RunTimeTicks" + Chr(34) + ":([0-9]+),", "i")
                    fixedString = regex.ReplaceAll(msg.GetString(), Chr(34) + "RunTimeTicks" + Chr(34) + ":" + Chr(34) + "\1" + Chr(34) + ",")

                    regex = CreateObject("roRegex", Chr(34) + "PlaybackPositionTicks" + Chr(34) + ":([0-9]+),", "i")
                    fixedString = regex.ReplaceAll(fixedString, Chr(34) + "PlaybackPositionTicks" + Chr(34) + ":" + Chr(34) + "\1" + Chr(34) + ",")

                    jsonData = ParseJSON(fixedString)
                    for each itemData in jsonData.Items
                        episodeData = {
                            Id: itemData.Id
                            Title: itemData.Name
                            ContentType: "Episode"
                            ShortDescriptionLine1: itemData.Name
                            Description: itemData.Overview
                        }

                        ' Check If Item has Image, otherwise use default
                        If itemData.ImageTags.Primary<>"" And itemData.ImageTags.Primary<>invalid
                            episodeData.HDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Primary/0?height=141&width=&EnableImageEnhancers=false&tag=" + itemData.ImageTags.Primary
                            episodeData.SDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Primary/0?height=94&width=&EnableImageEnhancers=false&tag=" + itemData.ImageTags.Primary
                        Else 
                            episodeData.HDPosterUrl = "pkg://images/items/collection.png"
                            episodeData.SDPosterUrl = "pkg://images/items/collection.png"
                        End If

                        ' Check For Run Time
                        itemRunTime = itemData.RunTimeTicks
                        If itemRunTime<>"" And itemRunTime<>invalid
                            episodeData.Length = Int(((itemRunTime).ToFloat() / 10000) / 1000)
                        End If

                        ' Check For Playback Position Time
                        itemPlaybackPositionTime = itemData.UserData.PlaybackPositionTicks
                        If itemPlaybackPositionTime<>"" And itemPlaybackPositionTime<>invalid
                            episodeData.BookmarkPosition = Int(((itemPlaybackPositionTime).ToFloat() / 10000) / 1000)
                        End If


                        ' Check Media Streams For HD Video And Surround Sound Audio
                        streamInfo = GetStreamInfo(itemData.MediaStreams)

                        ' Build Extra Information Line
                        episodeExtraInfo = "Sn " + Stri(itemData.ParentIndexNumber) + " / Ep "  + Stri(itemData.IndexNumber)

                        episodeExtraInfo = episodeExtraInfo + "  |  " + itemData.OfficialRating

                        If streamInfo.isHDVideo=true
                            episodeExtraInfo = episodeExtraInfo + "  |  HD" 
                        End If

                        If streamInfo.isSSAudio=true
                            episodeExtraInfo = episodeExtraInfo + "  |  5.1" 
                        End If

                        episodeData.ShortDescriptionLine2 = episodeExtraInfo

                        list.push( episodeData )
                    end for
                    return list
                endif
            else if (event = invalid)
                request.AsyncCancel()
            endif
        end while
    endif

    Return invalid
End Function


'**********************************************************
'** Get TV Theme Music From Server
'**********************************************************

Function GetTVThemeMusic(seriesId As String) As Object
    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/Items/" + seriesId + "/ThemeSongs?UserId=" + m.curUserProfile.Id, true)

    if (request.AsyncGetToString())
        while (true)
            msg = wait(0, request.GetPort())

            if (type(msg) = "roUrlEvent")
                code = msg.GetResponseCode()

                if (code = 200)
                    list     = CreateObject("roArray", 10, true)
                    jsonData = ParseJSON(msg.GetString())
                    for each itemData in jsonData.Items
                        ' Setup Song
                        streamData = SetupAudioStream(itemData.Id, itemData.Path)

                        list.push( streamData )
                    end for
                    return list
                endif
            else if (event = invalid)
                request.AsyncCancel()
            endif
        end while
    endif

    Return invalid
End Function
