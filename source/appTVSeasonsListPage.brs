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
                m.curShow = msg.GetIndex()

                print "list item selected | current show = "; m.curShow
                'm.curShow = displayShowDetailScreen(category, m.curShow)
                'screen.SetFocusedListItem(m.curShow)
                print "list item updated  | new show = "; m.curShow

                'If rowData[row][selection].ContentType = "Series" Then
                '    Print rowData[row][selection].Id

                'Else If rowData[row][selection].ContentType = "Genre" Then
                '    Print rowData[row][selection].Id

                    'm.curItem = rowData[row][selection]
                    'DisplayDetailPage()
                'Else 
                '    Print "Unknown Type found"
                'End If
                

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
    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/Users/" + m.curUserProfile.Id + "/Items?ParentId=" + seriesId + "&Recursive=true&IncludeItemTypes=Season&SortBy=SortName&SortOrder=Ascending")

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
    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/Users/" + m.curUserProfile.Id + "/Items?ParentId=" + seasonId + "&Recursive=true&IncludeItemTypes=Episode&Fields=SeriesInfo%2COverview&SortBy=SortName&SortOrder=Ascending")

    if (request.AsyncGetToString())
        while (true)
            msg = wait(0, request.GetPort())

            if (type(msg) = "roUrlEvent")
                code = msg.GetResponseCode()

                if (code = 200)
                    list     = CreateObject("roArray", 2, true)
                    jsonData = ParseJSON(msg.GetString())
                    for each itemData in jsonData.Items
                        episodeData = {
                            Id: itemData.Id
                            Title: itemData.Name
                            ContentType: "Episode"
                            ShortDescriptionLine1: itemData.Name
                            ShortDescriptionLine2: "Sn " + Stri(itemData.ParentIndexNumber) + " / Ep "  + Stri(itemData.IndexNumber)
                            Description: itemData.Overview
                        }

                        ' Check If Item has Image, otherwise use default
                        If itemData.ImageTags.Primary<>"" And itemData.ImageTags.Primary<>invalid
                            episodeData.HDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Primary/0?height=141&width=&tag=" + itemData.ImageTags.Primary
                            episodeData.SDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Primary/0?height=94&width=&tag=" + itemData.ImageTags.Primary
                        Else 
                            episodeData.HDPosterUrl = "pkg://images/items/collection.png"
                            episodeData.SDPosterUrl = "pkg://images/items/collection.png"
                        End If

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
