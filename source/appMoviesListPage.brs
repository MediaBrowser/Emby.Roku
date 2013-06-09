'*****************************************************************
'**  Media Browser Roku Client - Movies List Page
'*****************************************************************


'**********************************************************
'** Show Movies List Page
'**********************************************************

Function ShowMoviesListPage() As Integer

    ' Setup Screen
    port   = CreateObject("roMessagePort")
    screen = CreateObject("roGridScreen")
    screen.SetMessagePort(port)

    screen.SetBreadcrumbText("", "Movies")
    screen.SetGridStyle("two-row-flat-landscape-custom")
    screen.SetDisplayMode("scale-to-fit")

    ' Get Data
    sectionNames = CreateObject("roArray", 3, true)
    sectionIndex = 1

    rowData = CreateObject("roArray", 3, true)

    ' Movies
    moviesAll = GetMoviesAll()
    sectionNames.push( "Movies A-Z" )
    movieIndex = 0

    ' Box Sets
    moviesBoxsets = GetMoviesBoxsets()

    If moviesBoxsets.Count() > 0 Then
        sectionNames.push( "Box Sets" )
        boxsetIndex  = sectionIndex
        sectionIndex = sectionIndex + 1
    End If

    ' Genres
    moviesGenres = GetMoviesGenres()

    If moviesGenres.Count() > 0 Then
        sectionNames.push( "Genres" )
        genreIndex = sectionIndex
        sectionIndex = sectionIndex + 1
    End If

    screen.SetupLists(sectionNames.Count())
    screen.SetListNames(sectionNames)

    ' Movie data
    rowData[movieIndex] = moviesAll
    screen.SetContentList(movieIndex, moviesAll)

    ' Box Sets Data
    If moviesBoxsets.Count() > 0 Then
        rowData[boxsetIndex] = moviesBoxsets
        screen.SetContentList(boxsetIndex, moviesBoxsets)
    End If

    ' Genres Data
    If moviesGenres.Count() > 0 Then
        rowData[genreIndex] = moviesGenres
        screen.SetContentList(genreIndex, moviesGenres)
    End If

    ' Show Screen
    screen.Show()

    ' Hide Description Popup
    screen.SetDescriptionVisible(false)

    while true
        msg = wait(0, screen.GetMessagePort())

        if type(msg) = "roGridScreenEvent" Then
            if msg.isListItemFocused() then
                'print "list focused | index = "; msg.GetIndex(); " | category = "; 'm.curCategory
            else if msg.isListItemSelected() Then
                row = msg.GetIndex()
                selection = msg.getData()

                If rowData[row][selection].ContentType = "Movie" Then
                    movieIndex = ShowMoviesDetailPage(rowData[row][selection].Id, moviesAll, selection)
                    screen.SetFocusedListItem(row, movieIndex)
                Else If rowData[row][selection].ContentType = "Genre" Then
                    ShowMoviesGenrePage(rowData[row][selection].Id)
                Else If rowData[row][selection].ContentType = "BoxSet" Then
                    ShowMoviesBoxsetPage(rowData[row][selection].Id, rowData[row][selection].Title)
                Else 
                    Print "Unknown Type found"
                End If

            else if msg.isScreenClosed() then
                return -1
            end if
        end if
    end while

    return 0
End Function


'**********************************************************
'** Get All Movies From Server
'**********************************************************

Function GetMoviesAll() As Object
    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/Users/" + m.curUserProfile.Id + "/Items?Recursive=true&IncludeItemTypes=Movie&Fields=UserData%2CMediaStreams&SortBy=SortName&SortOrder=Ascending", true)

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
                            Watched: itemData.UserData.Played
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
                end if
            else if (event = invalid)
                request.AsyncCancel()
            endif
        end while
    endif

    Return invalid
End Function


'**********************************************************
'** Get Movie Genres From Server
'**********************************************************

Function GetMoviesGenres() As Object
    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/Genres?UserId=" + m.curUserProfile.Id + "&Recursive=true&IncludeItemTypes=Movie&Fields=ItemCounts&SortBy=SortName&SortOrder=Ascending", true)

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
                            Id: itemData.Name
                            Title: itemData.Name
                            ContentType: "Genre"
                            ShortDescriptionLine1: itemData.Name
                            ShortDescriptionLine2: Stri(itemData.ChildCount) + " movies"
                        }

                        ' Check If Item has Image, otherwise use default
                        If itemData.ImageTags.Primary<>"" And itemData.ImageTags.Primary<>invalid
                            movieData.HDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Primary/0?height=150&width=&tag=" + itemData.ImageTags.Primary
                            movieData.SDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Primary/0?height=94&width=&tag=" + itemData.ImageTags.Primary
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
'** Get Movie Boxsets From Server
'**********************************************************

Function GetMoviesBoxsets() As Object

    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/Users/" + m.curUserProfile.Id + "/Items?Recursive=true&IncludeItemTypes=BoxSet&Fields=UserData%2CItemCounts&SortBy=SortName&SortOrder=Ascending", true)

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
                            ContentType: "BoxSet"
                            ShortDescriptionLine1: itemData.Name
                            Watched: itemData.UserData.Played
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
