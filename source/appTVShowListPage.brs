'*****************************************************************
'**  Media Browser Roku Client - TV Show List Page
'*****************************************************************


'**********************************************************
'** Show TV Show List Page
'**********************************************************

Function ShowTVShowListPage() As Integer
    ' Setup Screen
    port   = CreateObject("roMessagePort")
    screen = CreateObject("roGridScreen")
    screen.SetMessagePort(port)

    screen.SetBreadcrumbText("", "TV")

    ' Determine Display Type
    If RegRead("prefTVImageType") = "poster" Then
        screen.SetGridStyle("mixed-aspect-ratio")
    Else
        screen.SetGridStyle("two-row-flat-landscape-custom")
    End If
    
    screen.SetDisplayMode("scale-to-fill")

    ' Show Screen
    screen.SetupLists(2)
    screen.SetListNames(["TV Shows A-Z","Genres"])

    If RegRead("prefTVImageType") = "poster" Then
        screen.SetListPosterStyles(["portrait", "landscape"])
    End If

    ' Setup Jump List
    m.jumpList = {}

    rowData = CreateObject("roArray", 2, true)

    tvShowAll = GetTVShowAll()
    rowData[0] = tvShowAll
    screen.SetContentList(0, tvShowAll)

    tvShowGenres = GetTVShowGenres()
    rowData[1] = tvShowGenres
    screen.SetContentList(1, tvShowGenres)

    screen.Show()

    ' Hide Description Popup
    screen.SetDescriptionVisible(false)

    ' Remote key id's for navigation
    remoteKeyStar = 10

    while true
        msg = wait(0, screen.GetMessagePort())

        if type(msg) = "roGridScreenEvent" Then
            if msg.isListItemFocused() then
                'print "list focused | index = "; msg.GetIndex(); " | category = "; 'm.curCategory
            else if msg.isListItemSelected() Then
                row = msg.GetIndex()
                selection = msg.getData()

                If rowData[row][selection].ContentType = "Series" Then
                    ShowTVSeasonsListPage(rowData[row][selection])
                Else If rowData[row][selection].ContentType = "Genre" Then
                    ShowTVShowGenrePage(rowData[row][selection].Id)
                Else 
                    Print "Unknown Type found"
                End If

            else if msg.isRemoteKeyPressed() then
                index = msg.GetIndex()

                If index = remoteKeyStar Then
                    letterSelected = CreateJumpListDialog()

                    If letterSelected <> invalid Then
                        letter = FindClosestLetter(letterSelected)
                        screen.SetFocusedListItem(0, m.jumpList.Lookup(letter))
                    End If
                End If

            else if msg.isScreenClosed() then
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
    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/Users/" + m.curUserProfile.Id + "/Items?Recursive=true&IncludeItemTypes=Series&Fields=ItemCounts%2CSortName&SortBy=SortName&SortOrder=Ascending", true)

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
                                seriesData.HDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Primary/0?height=192&width=&EnableImageEnhancers=false&tag=" + itemData.ImageTags.Primary
                                seriesData.SDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Primary/0?height=140&width=&EnableImageEnhancers=false&tag=" + itemData.ImageTags.Primary
                            Else 
                                seriesData.HDPosterUrl = "pkg://images/items/collection.png"
                                seriesData.SDPosterUrl = "pkg://images/items/collection.png"
                            End If

                        Else If RegRead("prefTVImageType") = "thumb" Then

                            ' Check If Item has Image, otherwise use default
                            If itemData.ImageTags.Thumb<>"" And itemData.ImageTags.Thumb<>invalid
                                seriesData.HDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Thumb/0?height=150&width=&EnableImageEnhancers=false&tag=" + itemData.ImageTags.Thumb
                                seriesData.SDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Thumb/0?height=94&width=&EnableImageEnhancers=false&tag=" + itemData.ImageTags.Thumb
                            Else 
                                seriesData.HDPosterUrl = "pkg://images/items/collection.png"
                                seriesData.SDPosterUrl = "pkg://images/items/collection.png"
                            End If

                        Else

                            ' Check If Item has Image, otherwise use default
                            If itemData.BackdropImageTags[0]<>"" And itemData.BackdropImageTags[0]<>invalid
                                seriesData.HDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Backdrop/0?height=150&width=&tag=" + itemData.BackdropImageTags[0]
                                seriesData.SDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Backdrop/0?height=94&width=&tag=" + itemData.BackdropImageTags[0]
                            Else 
                                seriesData.HDPosterUrl = "pkg://images/items/collection.png"
                                seriesData.SDPosterUrl = "pkg://images/items/collection.png"
                            End If

                        End If

                        ' Show / Hide Series Name
                        If RegRead("prefTVTitle") = "show" Then
                            seriesData.ShortDescriptionLine1 = itemData.Name
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

                        ' Get Image Type From Preference
                        If RegRead("prefTVImageType") = "poster" Then

                            ' Check If Item has Image, otherwise use default
                            If itemData.ImageTags.Primary<>"" And itemData.ImageTags.Primary<>invalid
                                seriesData.HDPosterUrl = GetServerBaseUrl() + "/Genres/" + itemData.Name + "/Images/Primary/0?height=192&width=&tag=" + itemData.ImageTags.Primary
                                seriesData.SDPosterUrl = GetServerBaseUrl() + "/Genres/" + itemData.Name + "/Images/Primary/0?height=94&width=&tag=" + itemData.ImageTags.Primary
                            Else 
                                seriesData.HDPosterUrl = "pkg://images/items/collection.png"
                                seriesData.SDPosterUrl = "pkg://images/items/collection.png"
                            End If

                        Else

                            ' Check If Item has Image, otherwise use default
                            If itemData.ImageTags.Primary<>"" And itemData.ImageTags.Primary<>invalid
                                seriesData.HDPosterUrl = GetServerBaseUrl() + "/Genres/" + itemData.Name + "/Images/Primary/0?height=150&width=&tag=" + itemData.ImageTags.Primary
                                seriesData.SDPosterUrl = GetServerBaseUrl() + "/Genres/" + itemData.Name + "/Images/Primary/0?height=94&width=&tag=" + itemData.ImageTags.Primary
                            Else If itemData.BackdropImageTags[0]<>"" And itemData.BackdropImageTags[0]<>invalid
                                seriesData.HDPosterUrl = GetServerBaseUrl() + "/Genres/" + itemData.Name + "/Images/Backdrop/0?height=150&width=&tag=" + itemData.BackdropImageTags[0]
                                seriesData.SDPosterUrl = GetServerBaseUrl() + "/Genres/" + itemData.Name + "/Images/Backdrop/0?height=94&width=&tag=" + itemData.BackdropImageTags[0]
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
