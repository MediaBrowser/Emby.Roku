'*****************************************************************
'**  Media Browser Roku Client - Home Page
'*****************************************************************

'**********************************************************
'** Create Home Page
'**********************************************************

Function CreateHomePage(breadA=invalid, breadB=invalid) As Object

    if validateParam(breadA, "roString", "CreateHomePage", true) = false return -1
    if validateParam(breadA, "roString", "CreateHomePage", true) = false return -1

    port   = CreateObject("roMessagePort")
    screen = CreateObject("roGridScreen")
    screen.SetMessagePort(port)
    if breadA<>invalid and breadB<>invalid then
        screen.SetBreadcrumbText(breadA, breadB)
    end if

    screen.SetGridStyle("two-row-flat-landscape-custom")
    screen.SetDisplayMode("scale-to-fit")
    return screen
End Function


'**********************************************************
'** Show Home Page
'**********************************************************

Function ShowHomePage(screen As Object) As Integer

    if validateParam(screen, "roGridScreen", "ShowHomePage") = false return -1

    screen.SetupLists(2)
    screen.SetListNames(["Movies","TV"])

    movieButtons = GetMovieButtons()
    screen.SetContentList(0, movieButtons)

    tvButtons = GetTVButtons()
    screen.SetContentList(1, tvButtons)

    screen.Show()

    ' Hide Description Popup
    screen.SetDescriptionVisible(false)

    while true
        msg = wait(0, screen.GetMessagePort())

        if type(msg) = "roGridScreenEvent" Then
            if msg.isListFocused() then
                print "list focused | index = "; msg.GetIndex(); " | category = "; 'm.curCategory
            else if msg.isListItemSelected() then
                m.curParent = list[msg.GetIndex()]
                DisplayListPage()
            else if msg.isScreenClosed() then
                return -1
            end if
        end if
    end while

    return 0
End Function


'**********************************************************
'** Create And Display the List Page
'**********************************************************

Function DisplayListPage() As Dynamic
    screen = CreateListPage("", m.curParent.Title)
    ShowListPage(screen)

    return 0
End Function


'**********************************************************
'** Get Movie Buttons Row
'**********************************************************

Function GetMovieButtons() As Object
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

    recentMovies = GetMovieRecentAdded()
    If recentMovies<>invalid
        buttons.Append( recentMovies )
    End if

    Return buttons
End Function


'**********************************************************
'** Get Recently Added Movies From Server
'**********************************************************

Function GetMovieRecentAdded() As Object
    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/Users/" + m.curUserProfile.Id + "/Items?Limit=1&Recursive=true&IncludeItemTypes=Movie&SortBy=DateCreated&SortOrder=Descending&Filters=IsNotFolder")

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

    recentShows = GetTVRecentAdded()
    If recentShows<>invalid
        buttons.Append( recentShows )
    End if

    Return buttons
End Function


'**********************************************************
'** Get Recently Added TV Episodes From Server
'**********************************************************

Function GetTVRecentAdded() As Object
    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/Users/" + m.curUserProfile.Id + "/Items?Limit=1&Recursive=true&IncludeItemTypes=Episode&Fields=SeriesInfo&SortBy=DateCreated&SortOrder=Descending&Filters=IsNotFolder")

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
                            ShortDescriptionLine2: itemData.SeriesName
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
