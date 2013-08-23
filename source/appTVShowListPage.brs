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

    ' Setup Jump List
    m.jumpList = {}

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

    ' Get Data
    tvShowAll    = GetTVShowAll()
    tvShowNextUp = GetTVShowNextUp()
    tvShowGenres = GetTVShowGenres()

    AddGridRowContent(screen, tvShowAll)
    AddGridRowContent(screen, tvShowNextUp)
    AddGridRowContent(screen, tvShowGenres)

    ' Show Screen
    screen.Screen.Show()

    ' Close Loading Dialog
    dialogBox.Close()

    ' Hide Description Popup
    'screen.Screen.SetDescriptionVisible(false)

    ' Remote key id's for navigation
    remoteKeyStar = 10

    while true
        msg = wait(0, screen.Screen.GetMessagePort())

        if type(msg) = "roGridScreenEvent" Then
            if msg.isListItemFocused() Then
                screen.Screen.SetDescriptionVisible(true) ' Work around for bug in mixed-aspect-ratio
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
                    Print "Unknown Type found"
                End If

            else if msg.isRemoteKeyPressed() then
                index = msg.GetIndex()

                If index = remoteKeyStar Then
                    letterSelected = CreateJumpListDialog()

                    If letterSelected <> invalid Then
                        letter = FindClosestLetter(letterSelected)
                        screen.Screen.SetFocusedListItem(0, m.jumpList.Lookup(letter))
                    End If
                End If

            else if msg.isScreenClosed() Then
                Print "Close tv screen"
                return -1
            end if
        end if
    end while

    return 0
End Function


'**********************************************************
'** Get All TV Shows From Server
'**********************************************************

Function GetTVShowAll() As Object

    ' Clean Fields
    fields = HttpEncode("ItemCounts,SortName,Overview")

    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/Users/" + m.curUserProfile.Id + "/Items?Recursive=true&IncludeItemTypes=Series&Fields=" + fields + "&SortBy=SortName&SortOrder=Ascending", true)

    if (request.AsyncGetToString())
        while (true)
            msg = wait(0, request.GetPort())

            if (type(msg) = "roUrlEvent")
                code = msg.GetResponseCode()

                if (code = 200)
                    index    = 0
                    list     = CreateObject("roArray", 2, true)
                    jsonData = ParseJSON(msg.GetString())
                    for each itemData in jsonData.Items
                        seriesData = {
                            Id: itemData.Id
                            Title: itemData.Name
                            ContentType: "Series"
                            ShortDescriptionLine2: Pluralize(itemData.ChildCount, "season")
                        }

                        ' Get Image Type From Preference
                        If RegRead("prefTVImageType") = "poster" Then

                            ' Check If Item has Image, otherwise use default
                            If itemData.ImageTags.Primary<>"" And itemData.ImageTags.Primary<>invalid
                                seriesData.HDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Primary/0?quality=90&height=192&width=&EnableImageEnhancers=false&tag=" + itemData.ImageTags.Primary
                                seriesData.SDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Primary/0?quality=90&height=140&width=&EnableImageEnhancers=false&tag=" + itemData.ImageTags.Primary
                            Else 
                                seriesData.HDPosterUrl = "pkg://images/items/collection.png"
                                seriesData.SDPosterUrl = "pkg://images/items/collection.png"
                            End If

                        Else If RegRead("prefTVImageType") = "thumb" Then

                            ' Check If Item has Image, otherwise use default
                            If itemData.ImageTags.Thumb<>"" And itemData.ImageTags.Thumb<>invalid
                                seriesData.HDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Thumb/0?quality=90&height=150&width=266&EnableImageEnhancers=false&tag=" + itemData.ImageTags.Thumb
                                seriesData.SDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Thumb/0?quality=90&height=94&width=140&EnableImageEnhancers=false&tag=" + itemData.ImageTags.Thumb
                            Else 
                                seriesData.HDPosterUrl = "pkg://images/items/collection.png"
                                seriesData.SDPosterUrl = "pkg://images/items/collection.png"
                            End If

                        Else

                            ' Check If Item has Image, otherwise use default
                            If itemData.BackdropImageTags[0]<>"" And itemData.BackdropImageTags[0]<>invalid
                                seriesData.HDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Backdrop/0?quality=90&height=150&width=266&tag=" + itemData.BackdropImageTags[0]
                                seriesData.SDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Backdrop/0?quality=90&height=94&width=140&tag=" + itemData.BackdropImageTags[0]
                            Else 
                                seriesData.HDPosterUrl = "pkg://images/items/collection.png"
                                seriesData.SDPosterUrl = "pkg://images/items/collection.png"
                            End If

                        End If

                        ' Show / Hide Series Name
                        If RegRead("prefTVTitle") = "show" Or RegRead("prefTVTitle") = invalid Then
                            seriesData.ShortDescriptionLine1 = itemData.Name
                        End If

                        ' Episode Count
                        If itemData.RecursiveItemCount<>invalid
                            seriesData.NumEpisodes = itemData.RecursiveItemCount
                        End If

                        If itemData.Overview<>invalid
                            seriesData.Description = itemData.Overview
                        End If

                        ' Series Rating
                        If itemData.OfficialRating<>invalid
                            seriesData.Rating = itemData.OfficialRating
                        End If

                        ' Star Rating
                        If itemData.CommunityRating<>invalid
                            seriesData.UserStarRating = Int(itemData.CommunityRating) * 10
                        End If

                        ' Build Jump List
                        firstChar = Left(itemData.SortName, 1)
                        If Not m.jumpList.DoesExist(firstChar) Then
                            m.jumpList.AddReplace(firstChar, index)
                        End If

                        ' Increment Count
                        index = index + 1

                        list.push( seriesData )
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

                        ' Get Image Type From Preference
                        If RegRead("prefTVImageType") = "poster" Then
                            tvData.Title = itemData.SeriesName + ": " + episodeExtraInfo
                        End If

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
                endif
            else if (event = invalid)
                request.AsyncCancel()
            endif
        end while
    endif

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
                endif
            else if (event = invalid)
                request.AsyncCancel()
            endif
        end while
    endif

    Return invalid
End Function
