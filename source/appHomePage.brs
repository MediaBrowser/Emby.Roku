'*****************************************************************
'**  Media Browser Roku Client - Home Page
'*****************************************************************


'**********************************************************
'** Show Home Page
'**********************************************************

Function ShowHomePage()

    ' Create Grid Screen
    screen = CreateGridScreen("", m.curUserProfile.Title, "two-row-flat-landscape-custom")

    ' Get Item Counts
    itemCounts = GetItemCounts()

    If itemCounts=invalid Then
        ShowError("Error", "Could Not Get Data From Server")
        return false
    End If

    ' Setup Globals
    m.movieToggle = ""
    m.tvToggle    = ""

    ' Setup Row Data
    screen.rowNames   = CreateObject("roArray", 3, true)
    screen.rowStyles  = CreateObject("roArray", 3, true)
    screen.rowContent = CreateObject("roArray", 3, true)

    If itemCounts.MovieCount > 0 Then
        AddGridRow(screen, "Movies", "landscape")
    End If

    If itemCounts.SeriesCount > 0 Then
        AddGridRow(screen, "TV", "landscape")
    End If

    AddGridRow(screen, "Options", "landscape")

    ShowGridNames(screen)

    ' Get Data
    If itemCounts.MovieCount > 0 Then
        moviesButtons = GetMoviesButtons()
        AddGridRowContent(screen, moviesButtons)
    End If

    If itemCounts.SeriesCount > 0 Then
        tvButtons = GetTVButtons()
        AddGridRowContent(screen, tvButtons)
    End If

    optionButtons = GetOptionsButtons()
    AddGridRowContent(screen, optionButtons)

    ' Show Screen
    screen.Screen.Show()

    ' Hide Description Popup
    screen.Screen.SetDescriptionVisible(false)

    while true
        msg = wait(0, screen.Screen.GetMessagePort())

        if type(msg) = "roGridScreenEvent" Then
            if msg.isListFocused() then
                print "list focused | index = "; msg.GetIndex(); " | category = "; 'm.curCategory
            else if msg.isListItemSelected() Then
                row = msg.GetIndex()
                selection = msg.getData()

                Print "Content type: "; screen.rowContent[row][selection].ContentType

                If screen.rowContent[row][selection].ContentType = "MovieLibrary" Then
                    ShowMoviesListPage()
                Else If screen.rowContent[row][selection].ContentType = "MovieToggle" Then
                    ' Toggle Movie Display
                    GetNextMovieToggle()
                    moviesButtons = GetMoviesButtons()
                    UpdateGridRowContent(screen, row, moviesButtons)
                Else If screen.rowContent[row][selection].ContentType = "Movie" Then
                    ShowMoviesDetailPage(screen.rowContent[row][selection].Id)
                Else If screen.rowContent[row][selection].ContentType = "TVLibrary" Then
                    ShowTVShowListPage()
                Else If screen.rowContent[row][selection].ContentType = "TVToggle" Then
                    ' Toggle TV Display
                    GetNextTVToggle()
                    tvButtons = GetTVButtons()
                    UpdateGridRowContent(screen, row, tvButtons)
                Else If screen.rowContent[row][selection].ContentType = "Episode" Then
                    ShowTVDetailPage(screen.rowContent[row][selection].Id)
                Else If screen.rowContent[row][selection].ContentType = "SwitchUser" Then
                    RegDelete("userId")
                    Print "Switch User"
                    return true
                Else If screen.rowContent[row][selection].ContentType = "Preferences" Then
                    ShowPreferencesPage()
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
'** Get Item Counts From Server
'**********************************************************

Function GetItemCounts() As Object
    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/Items/Counts?UserId=" + m.curUserProfile.Id, true)

    if (request.AsyncGetToString())
        while (true)
            msg = wait(0, request.GetPort())

            if (type(msg) = "roUrlEvent")
                code = msg.GetResponseCode()

                if (code = 200)
                    jsonData = ParseJSON(msg.GetString())
                    return jsonData
                else
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

    switchButton = [
        {
            Title: "Toggle Movie"
            ContentType: "MovieToggle"
            ShortDescriptionLine1: "Toggle Display"
        }
    ]

    If m.movieToggle = "latest" Then
        switchButton[0].HDPosterUrl = ""
        switchButton[0].SDPosterUrl = ""

        ' Get Latest Unwatched Movies
        recentMovies = GetMoviesRecentAdded()
        If recentMovies<>invalid
            buttons.Append( switchButton )
            buttons.Append( recentMovies )
        End if

    Else If m.movieToggle = "favorite" Then
        switchButton[0].HDPosterUrl = ""
        switchButton[0].SDPosterUrl = ""

        buttons.Append( switchButton )

    Else

        switchButton[0].HDPosterUrl = ""
        switchButton[0].SDPosterUrl = ""

        ' Check For Resumable Movies
        resumeMovies = GetMoviesResumable()
        If resumeMovies<>invalid And resumeMovies.Count() > 0
            buttons.Append( switchButton )
            buttons.Append( resumeMovies )
        Else
            buttons.Append( switchButton )
        End if

    End If

    Return buttons
End Function


'**********************************************************
'** Get Next Movie Toggle
'**********************************************************

Function GetNextMovieToggle()
    If m.movieToggle = "latest" Then
        m.movieToggle = "favorite"
    Else If m.movieToggle = "favorite" Then
        m.movieToggle = "resume"
    Else
        m.movieToggle = "latest"
    End If
End Function

'**********************************************************
'** Get Recently Added Movies From Server
'**********************************************************

Function GetMoviesRecentAdded() As Object
    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/Users/" + m.curUserProfile.Id + "/Items?Limit=5&Recursive=true&IncludeItemTypes=Movie&SortBy=DateCreated&SortOrder=Descending&Filters=IsUnplayed", true)

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
                            Title: itemData.Name
                            ContentType: "Movie"
                            ShortDescriptionLine1: itemData.Name
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
'** Get Resumable Movies From Server
'**********************************************************

Function GetMoviesResumable() As Object
    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/Users/" + m.curUserProfile.Id + "/Items?Limit=7&Recursive=true&IncludeItemTypes=Movie&SortBy=DatePlayed&SortOrder=Descending&Filters=IsResumable", true)

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
                            Title: "Resume"
                            ContentType: "Movie"
                            ShortDescriptionLine1: "Resume"
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

    switchButton = [
        {
            Title: "Toggle TV"
            ContentType: "TVToggle"
            ShortDescriptionLine1: "Toggle Display"
        }
    ]

    If m.tvToggle = "latest" Then
        switchButton[0].HDPosterUrl = ""
        switchButton[0].SDPosterUrl = ""

        ' Get Latest Unwatched TV
        recentTV = GetTVRecentAdded()
        If recentTV<>invalid
            buttons.Append( switchButton )
            buttons.Append( recentTV )
        End if

    Else If m.tvToggle = "favorite" Then
        switchButton[0].HDPosterUrl = ""
        switchButton[0].SDPosterUrl = ""

        buttons.Append( switchButton )

    Else

        switchButton[0].HDPosterUrl = ""
        switchButton[0].SDPosterUrl = ""

        ' Check For Resumable TV
        resumeTV = GetTVResumable()
        If resumeTV<>invalid And resumeTV.Count() > 0
            buttons.Append( switchButton )
            buttons.Append( resumeTV )
        Else
            buttons.Append( switchButton )
        End if

    End If

    Return buttons
End Function


'**********************************************************
'** Get Next TV Toggle
'**********************************************************

Function GetNextTVToggle()
    If m.tvToggle = "latest" Then
        m.tvToggle = "favorite"
    Else If m.tvToggle = "favorite" Then
        m.tvToggle = "resume"
    Else
        m.tvToggle = "latest"
    End If
End Function

'**********************************************************
'** Get Recently Added TV Episodes From Server
'**********************************************************

Function GetTVRecentAdded() As Object
    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/Users/" + m.curUserProfile.Id + "/Items?Limit=5&Recursive=true&IncludeItemTypes=Episode&Fields=SeriesInfo%2CUserData&SortBy=DateCreated&SortOrder=Descending&Filters=IsUnplayed", true)

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
                            ShortDescriptionLine1: itemData.SeriesName
                            ShortDescriptionLine2: itostr(itemData.ParentIndexNumber) + "x"  + ZeroPad(itostr(itemData.IndexNumber)) + " - " + itemData.Name
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
                            Title: itemData.SeriesName
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
'** Get Resumable TV From Server
'**********************************************************

Function GetTVResumable() As Object
    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/Users/" + m.curUserProfile.Id + "/Items?Limit=5&Recursive=true&IncludeItemTypes=Episode&Fields=SeriesInfo&SortBy=DatePlayed&SortOrder=Descending&Filters=IsResumable", true)

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
                            Title: itemData.SeriesName
                            ContentType: "Episode"
                            ShortDescriptionLine1: itemData.SeriesName
                            ShortDescriptionLine2: itostr(itemData.ParentIndexNumber) + "x"  + ZeroPad(itostr(itemData.IndexNumber)) + " - " + itemData.Name
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
            Title: "Preferences"
            ContentType: "Preferences"
            ShortDescriptionLine1: "Preferences"
            HDPosterUrl: "pkg://images/items/Default_Preferences_HD.png"
            SDPosterUrl: "pkg://images/items/Default_Preferences_SD.png"
        },
        {
            Title: "About"
            ContentType: "About"
            ShortDescriptionLine1: "Version 1.11"
            'HDPosterUrl: "pkg://images/Default_SwitchUser_HD.png"
            'SDPosterUrl: "pkg://images/Default_SwitchUser_SD.png"
        }
    ]

    Return buttons
End Function
