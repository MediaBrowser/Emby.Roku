'*****************************************************************
'**  Media Browser Roku Client - TV Show List Page
'*****************************************************************


'**********************************************************
'** Show TV Show List Page
'**********************************************************

Function ShowTVShowListPage() As Integer

    ' Create Grid Screen
    If RegRead("prefTVImageType") = "poster" Then
        screen = CreateGridScreen("", "TV", "mixed-aspect-ratio")
    Else
        screen = CreateGridScreen("", "TV", "two-row-flat-landscape-custom")
    End If

    ' Setup Row Data
    screen.rowNames   = CreateObject("roArray", 2, true)
    screen.rowStyles  = CreateObject("roArray", 2, true)
    screen.rowContent = CreateObject("roArray", 2, true)

    AddGridRow(screen, "Shows", "portrait")
    AddGridRow(screen, "Next Episodes to Watch", "landscape")
    AddGridRow(screen, "Genres", "landscape")

    ShowGridNames(screen)

    If RegRead("prefTVImageType") = "poster" Then
        screen.Screen.SetListPosterStyles(screen.rowStyles)
    End If

    ' Show Loading Dialog
    dialogBox = ShowPleaseWait("Loading...","")

    ' Initialize TV Metadata
    TvMetadata = InitTvMetadata()

    ' Get Data
    tvShowAll    = TvMetadata.GetShowList()
    tvShowNextUp = GetTVShowNextUp()
    tvShowGenres = GetTVShowGenres()

    AddGridRowContent(screen, tvShowAll)
    AddGridRowContent(screen, tvShowNextUp)
    AddGridRowContent(screen, tvShowGenres)

    ' Show Screen
    screen.Screen.Show()

    ' Close Loading Dialog
    dialogBox.Close()

    ' Show/Hide Description Popup
    If RegRead("prefTVDisplayPopup") = "no" Or RegRead("prefTVDisplayPopup") = invalid Then
        screen.Screen.SetDescriptionVisible(false)
    End If

    ' Remote key id's for navigation
    remoteKeyStar = 10

    while true
        msg = wait(0, screen.Screen.GetMessagePort())

        if type(msg) = "roGridScreenEvent" Then
            if msg.isListItemFocused() Then
                ' Show/Hide Description Popup
                If RegRead("prefTVDisplayPopup") = "yes" Then
                    screen.Screen.SetDescriptionVisible(true) ' Work around for bug in mixed-aspect-ratio
                End If
            else if msg.isListItemSelected() Then
                row = msg.GetIndex()
                selection = msg.getData()

                If screen.rowContent[row][selection].ContentType = "Series" Then
                    ShowTVSeasonsListPage(screen.rowContent[row][selection])
                Else If screen.rowContent[row][selection].ContentType = "Episode" Then
                    ShowTVDetailPage(screen.rowContent[row][selection].Id)
                    ' Refresh Next Up Data
                    tvShowNextUp = GetTVShowNextUp()
                    UpdateGridRowContent(screen, row, tvShowNextUp)
                Else If screen.rowContent[row][selection].ContentType = "Genre" Then
                    ShowTVShowGenrePage(screen.rowContent[row][selection].Id)
                Else 
                    Debug("Unknown Type found")
                End If

            else if msg.isRemoteKeyPressed() then
                index = msg.GetIndex()

                If index = remoteKeyStar Then
                    letterSelected = CreateJumpListDialog()

                    If letterSelected <> invalid Then
                        letter = FindClosestLetter(letterSelected, TvMetadata)
                        screen.Screen.SetFocusedListItem(0, TvMetadata.jumpList.Lookup(letter))
                    End If
                End If

            else if msg.isScreenClosed() Then
                Debug("Close tv screen")
                return -1
            end if
        end if
    end while

    return 0
End Function


'**********************************************************
'** Get Next Up TV Episodes From Server
'**********************************************************

Function GetTVShowNextUp() As Object

    ' Clean Fields
    fields = HttpEncode("SeriesInfo,DateCreated,Overview")

    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/Shows/NextUp?UserId=" + m.curUserProfile.Id + "&Limit=10&Fields=" + fields, true)

    if (request.AsyncGetToString())
        while (true)
            msg = wait(0, request.GetPort())

            if (type(msg) = "roUrlEvent")
                code = msg.GetResponseCode()

                if (code = 200)
                    ' Fixes bug within BRS Json Parser
                    regex = CreateObject("roRegex", Chr(34) + "(RunTimeTicks)" + Chr(34) + ":([0-9]+),", "i")
                    fixedString = regex.ReplaceAll(msg.GetString(), Chr(34) + "\1" + Chr(34) + ":" + Chr(34) + "\2" + Chr(34) + ",")

                    list     = CreateObject("roArray", 2, true)
                    jsonData = ParseJSON(fixedString)
                    for each itemData in jsonData.Items
                        tvData = {
                            Id: itemData.Id
                            ContentType: "Episode"
                            ShortDescriptionLine1: itemData.SeriesName
                        }

                        ' Check For Season/Episode Numbers
                        episodeExtraInfo = ""

                        If itemData.ParentIndexNumber<>invalid
                            episodeExtraInfo = itostr(itemData.ParentIndexNumber)
                        End If

                        If itemData.IndexNumber<>invalid
                            episodeExtraInfo = episodeExtraInfo + "x" + ZeroPad(itostr(itemData.IndexNumber))
                        End If

                        episodeExtraInfo = episodeExtraInfo + " - " + itemData.Name

                        ' Show Season/Episode Numbers and Title
                        tvData.ShortDescriptionLine2 = episodeExtraInfo

                        ' Title
                        tvData.Title = itemData.SeriesName + ": " + episodeExtraInfo

                        If Type(itemData.ProductionYear) = "Integer" Then
                            tvData.ReleaseDate = itostr(itemData.ProductionYear)
                        End If

                        ' Check For Run Time
                        itemRunTime = itemData.RunTimeTicks
                        If itemRunTime<>"" And itemRunTime<>invalid
                            tvData.Length = Int(((itemRunTime).ToFloat() / 10000) / 1000)
                        End If

                        ' Overview of Episode
                        If itemData.Overview<>invalid
                            tvData.Description = itemData.Overview
                        End If

                        ' Check If Item has Image, Check If Parent Item has Image, otherwise use default
                        If itemData.BackdropImageTags[0]<>"" And itemData.BackdropImageTags[0]<>invalid
                            tvData.HDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Backdrop/0?quality=90&height=150&width=&tag=" + itemData.BackdropImageTags[0]
                            tvData.SDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Backdrop/0?quality=90&height=94&width=&tag=" + itemData.BackdropImageTags[0]
                        Else If itemData.ImageTags.Primary<>"" And itemData.ImageTags.Primary<>invalid
                            tvData.HDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Primary/0?quality=90&height=150&width=&EnableImageEnhancers=false&tag=" + itemData.ImageTags.Primary
                            tvData.SDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Primary/0?quality=90&height=94&width=&EnableImageEnhancers=false&tag=" + itemData.ImageTags.Primary
                        Else 
                            tvData.HDPosterUrl = "pkg://images/items/collection.png"
                            tvData.SDPosterUrl = "pkg://images/items/collection.png"
                        End If

                        list.push( tvData )
                    end for
                    return list
                else
                    Debug("Failed to Get Next Episodes to Watch for TV Shows")
                    return invalid
                end if
            else if (event = invalid)
                request.AsyncCancel()
            end if
        end while
    end if

    Return invalid
End Function


'**********************************************************
'** Get TV Shows Genres From Server
'**********************************************************

Function GetTVShowGenres() As Object
    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/Genres?UserId=" + m.curUserProfile.Id + "&Recursive=true&IncludeItemTypes=Series&Fields=ItemCounts&SortBy=SortName&SortOrder=Ascending", true)

    if (request.AsyncGetToString())
        while (true)
            msg = wait(0, request.GetPort())

            if (type(msg) = "roUrlEvent")
                code = msg.GetResponseCode()

                if (code = 200)
                    list     = CreateObject("roArray", 2, true)
                    jsonData = ParseJSON(msg.GetString())
                    for each itemData in jsonData.Items
                        seriesData = {
                            Id: itemData.Name
                            Title: itemData.Name
                            ContentType: "Genre"
                            ShortDescriptionLine1: itemData.Name
                            ShortDescriptionLine2: Stri(itemData.ChildCount) + " shows"
                        }

                        ' Clean Genre Name
                        genreName = HttpEncode(itemData.Name)

                        ' Get Image Type From Preference
                        If RegRead("prefTVImageType") = "poster" Then

                            ' Check If Item has Image, otherwise use default
                            If itemData.ImageTags.Primary<>"" And itemData.ImageTags.Primary<>invalid
                                seriesData.HDPosterUrl = GetServerBaseUrl() + "/Genres/" + genreName + "/Images/Primary/0?quality=90&height=192&width=&EnableImageEnhancers=false&tag=" + itemData.ImageTags.Primary
                                seriesData.SDPosterUrl = GetServerBaseUrl() + "/Genres/" + genreName + "/Images/Primary/0?quality=90&height=94&width=&EnableImageEnhancers=false&tag=" + itemData.ImageTags.Primary
                            Else 
                                seriesData.HDPosterUrl = "pkg://images/items/collection.png"
                                seriesData.SDPosterUrl = "pkg://images/items/collection.png"
                            End If

                        Else

                            ' Check If Item has Image, otherwise use default
                            If itemData.ImageTags.Primary<>"" And itemData.ImageTags.Primary<>invalid
                                seriesData.HDPosterUrl = GetServerBaseUrl() + "/Genres/" + genreName + "/Images/Primary/0?quality=90&height=150&width=&EnableImageEnhancers=false&tag=" + itemData.ImageTags.Primary
                                seriesData.SDPosterUrl = GetServerBaseUrl() + "/Genres/" + genreName + "/Images/Primary/0?quality=90&height=94&width=&EnableImageEnhancers=false&tag=" + itemData.ImageTags.Primary
                            Else If itemData.BackdropImageTags[0]<>"" And itemData.BackdropImageTags[0]<>invalid
                                seriesData.HDPosterUrl = GetServerBaseUrl() + "/Genres/" + genreName + "/Images/Backdrop/0?quality=90&height=150&width=&tag=" + itemData.BackdropImageTags[0]
                                seriesData.SDPosterUrl = GetServerBaseUrl() + "/Genres/" + genreName + "/Images/Backdrop/0?quality=90&height=94&width=&tag=" + itemData.BackdropImageTags[0]
                            Else 
                                seriesData.HDPosterUrl = "pkg://images/items/collection.png"
                                seriesData.SDPosterUrl = "pkg://images/items/collection.png"
                            End If

                        End If

                        list.push( seriesData )
                    end for
                    return list
                else
                    Debug("Failed to Get Genres for TV Shows")
                    return invalid
                end if
            else if (event = invalid)
                request.AsyncCancel()
            end if
        end while
    end if

    Return invalid
End Function
