'*****************************************************************
'**  Media Browser Roku Client - Home Page
'*****************************************************************


'**********************************************************
'** Show Home Page
'**********************************************************

Function ShowHomePage()

    ' Setup Screen
    port   = CreateObject("roMessagePort")
    screen = CreateObject("roGridScreen")
    screen.SetMessagePort(port)

    screen.SetBreadcrumbText("", m.curUserProfile.Title)
    screen.SetGridStyle("two-row-flat-landscape-custom")
    screen.SetDisplayMode("scale-to-fill")

    ' Get Data
    screen.SetupLists(3)
    screen.SetListNames(["Movies","TV","Options"])

    rowData = CreateObject("roArray", 3, true)

    moviesButtons = GetMoviesButtons()
    rowData[0] = moviesButtons
    screen.SetContentList(0, moviesButtons)

    tvButtons = GetTVButtons()
    rowData[1] = tvButtons
    screen.SetContentList(1, tvButtons)

    optionButtons = GetOptionsButtons()
    rowData[2] = optionButtons
    screen.SetContentList(2, optionButtons)

    ' Show Screen
    screen.Show()

    ' Hide Description Popup
    screen.SetDescriptionVisible(false)

    while true
        msg = wait(0, screen.GetMessagePort())

        if type(msg) = "roGridScreenEvent" Then
            if msg.isListFocused() then
                print "list focused | index = "; msg.GetIndex(); " | category = "; 'm.curCategory
            else if msg.isListItemSelected() Then
                row = msg.GetIndex()
                selection = msg.getData()

                If rowData[row][selection].ContentType = "MovieLibrary" Then
                    ShowMoviesListPage()
                Else If rowData[row][selection].ContentType = "Movie" Then
                    ShowMoviesDetailPage(rowData[row][selection].Id)
                Else If rowData[row][selection].ContentType = "TVLibrary" Then
                    ShowTVShowListPage()
                Else If rowData[row][selection].ContentType = "Episode" Then
                    ShowTVDetailPage(rowData[row][selection].Id)
                Else If rowData[row][selection].ContentType = "SwitchUser" Then
                    RegDelete("userId")
                    Print "Switch User"
                    return true
                Else 
                    Print "Unknown Type found"
                End If
            Else If msg.isScreenClosed() Then
                Print "Close home screen"
                return false
            End If
        end if
    end while

    return false
End Function


'**********************************************************
'** Create And Display the List Page
'**********************************************************

Function DisplayListPage(mediaType As String) As Dynamic

    if validateParam(mediaType, "roString", "DisplayListPage") = false return -1

    ShowMoviesListPage()

    return 0
End Function


'**********************************************************
'** Get Movie Buttons Row
'**********************************************************

Function GetMoviesButtons() As Object
    ' Set the Default movie library button
    buttons = [
        {
            Title: "Movie Library"
            ContentType: "MovieLibrary"
            ShortDescriptionLine1: "Movie Library"
            HDPosterUrl: "pkg://images/items/Default_Movie_Collection_HD.png"
            SDPosterUrl: "pkg://images/items/Default_Movie_Collection_SD.png"
        }
    ]

    recentMovies = GetMoviesRecentAdded()
    If recentMovies<>invalid
        buttons.Append( recentMovies )
    End if

    Return buttons
End Function


'**********************************************************
'** Get Recently Added Movies From Server
'**********************************************************

Function GetMoviesRecentAdded() As Object
    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/Users/" + m.curUserProfile.Id + "/Items?Limit=1&Recursive=true&IncludeItemTypes=Movie&SortBy=DateCreated&SortOrder=Descending&Filters=IsNotFolder", true)

    if (request.AsyncGetToString())
        while (true)
            msg = wait(0, request.GetPort())

            if (type(msg) = "roUrlEvent")
                code = msg.GetResponseCode()

                if (code = 200)
                    list     = CreateObject("roArray", 2, true)
                    jsonData = ParseJSON(msg.GetString())
                    for each itemData in jsonData.Items
                        movieData = {
                            Id: itemData.Id
                            Title: "Recently Added"
                            ContentType: "Movie"
                            ShortDescriptionLine1: "Recently Added"
                            ShortDescriptionLine2: itemData.Name
                        }

                        ' Check If Item has Image, otherwise use default
                        If itemData.BackdropImageTags[0]<>"" And itemData.BackdropImageTags[0]<>invalid
                            movieData.HDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Backdrop/0?height=150&width=&tag=" + itemData.BackdropImageTags[0]
                            movieData.SDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Backdrop/0?height=94&width=&tag=" + itemData.BackdropImageTags[0]
                        Else 
                            movieData.HDPosterUrl = "pkg://images/items/collection.png"
                            movieData.SDPosterUrl = "pkg://images/items/collection.png"
                        End If

                        list.push( movieData )
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
'** Get TV Buttons Row
'**********************************************************

Function GetTVButtons() As Object
    ' Set the Default movie library button
    buttons = [
        {
            Title: "TV Library"
            ContentType: "TVLibrary"
            ShortDescriptionLine1: "TV Library"
            HDPosterUrl: "pkg://images/items/Default_Tv_Collection_HD.png"
            SDPosterUrl: "pkg://images/items/Default_Tv_Collection_SD.png"
        }
    ]

    recentTVAdded = GetTVRecentAdded()
    If recentTVAdded<>invalid
        buttons.Append( recentTVAdded )
    End If

    recentTVPlayed = GetTVRecentPlayed()
    If recentTVPlayed<>invalid
        buttons.Append( recentTVPlayed )
    End If

    Return buttons
End Function


'**********************************************************
'** Get Recently Added TV Episodes From Server
'**********************************************************

Function GetTVRecentAdded() As Object
    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/Users/" + m.curUserProfile.Id + "/Items?Limit=1&Recursive=true&IncludeItemTypes=Episode&Fields=SeriesInfo&SortBy=DateCreated&SortOrder=Descending&Filters=IsNotFolder", true)

    if (request.AsyncGetToString())
        while (true)
            msg = wait(0, request.GetPort())

            if (type(msg) = "roUrlEvent")
                code = msg.GetResponseCode()

                if (code = 200)
                    list     = CreateObject("roArray", 2, true)
                    jsonData = ParseJSON(msg.GetString())
                    for each itemData in jsonData.Items
                        tvData = {
                            Id: itemData.Id
                            Title: "Recently Added"
                            ContentType: "Episode"
                            ShortDescriptionLine1: "Recently Added"
                            ShortDescriptionLine2: itemData.SeriesName + " - Sn " + Stri(itemData.ParentIndexNumber) + " / Ep "  + Stri(itemData.IndexNumber)
                        }

                        ' Check If Item has Image, Check If Parent Item has Image, otherwise use default
                        If itemData.BackdropImageTags[0]<>"" And itemData.BackdropImageTags[0]<>invalid
                            tvData.HDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Backdrop/0?height=150&width=&tag=" + itemData.BackdropImageTags[0]
                            tvData.SDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Backdrop/0?height=94&width=&tag=" + itemData.BackdropImageTags[0]
                        Else If itemData.ImageTags.Primary<>"" And itemData.ImageTags.Primary<>invalid
                            tvData.HDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Primary/0?height=150&width=&tag=" + itemData.ImageTags.Primary
                            tvData.SDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Primary/0?height=94&width=&tag=" + itemData.ImageTags.Primary
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
'** Get Recently Played TV Episodes From Server
'**********************************************************

Function GetTVRecentPlayed() As Object
    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/Users/" + m.curUserProfile.Id + "/Items?Limit=1&Recursive=true&IncludeItemTypes=Episode&Fields=SeriesInfo&SortBy=DatePlayed&SortOrder=Descending", true)

    if (request.AsyncGetToString())
        while (true)
            msg = wait(0, request.GetPort())

            if (type(msg) = "roUrlEvent")
                code = msg.GetResponseCode()

                if (code = 200)
                    list     = CreateObject("roArray", 2, true)
                    jsonData = ParseJSON(msg.GetString())
                    for each itemData in jsonData.Items
                        tvData = {
                            Id: itemData.Id
                            Title: "Recently Played"
                            ContentType: "Episode"
                            ShortDescriptionLine1: "Recently Played"
                            ShortDescriptionLine2: itemData.SeriesName + " - Sn " + Stri(itemData.ParentIndexNumber) + " / Ep "  + Stri(itemData.IndexNumber)
                        }

                        ' Check If Item has Image, Check If Parent Item has Image, otherwise use default
                        If itemData.BackdropImageTags[0]<>"" And itemData.BackdropImageTags[0]<>invalid
                            tvData.HDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Backdrop/0?height=150&width=&tag=" + itemData.BackdropImageTags[0]
                            tvData.SDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Backdrop/0?height=94&width=&tag=" + itemData.BackdropImageTags[0]
                        Else If itemData.ImageTags.Primary<>"" And itemData.ImageTags.Primary<>invalid
                            tvData.HDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Primary/0?height=150&width=&tag=" + itemData.ImageTags.Primary
                            tvData.SDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Primary/0?height=94&width=&tag=" + itemData.ImageTags.Primary
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
'** Get Options Buttons Row
'**********************************************************

Function GetOptionsButtons() As Object
    ' Set the Options buttons
    buttons = [
        {
            Title: "Switch User"
            ContentType: "SwitchUser"
            ShortDescriptionLine1: "Switch User"
            HDPosterUrl: "pkg://images/items/Default_SwitchUser_HD.png"
            SDPosterUrl: "pkg://images/items/Default_SwitchUser_SD.png"
        },
        {
            Title: "About"
            ContentType: "About"
            ShortDescriptionLine1: "Version 1.2"
            'HDPosterUrl: "pkg://images/Default_SwitchUser_HD.png"
            'SDPosterUrl: "pkg://images/Default_SwitchUser_SD.png"
        }
    ]

    Return buttons
End Function
