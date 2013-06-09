'*****************************************************************
'**  Media Browser Roku Client - Movies Boxset Page
'*****************************************************************


'**********************************************************
'** Show Movies Boxset Page
'**********************************************************

Function ShowMoviesBoxsetPage(boxsetId As String, boxsetName As String) As Integer

    if validateParam(boxsetId, "roString", "ShowMoviesBoxsetPage") = false return -1

    ' Setup Screen
    port   = CreateObject("roMessagePort")
    screen = CreateObject("roGridScreen")
    screen.SetMessagePort(port)

    screen.SetBreadcrumbText(boxsetName, "Movies")

    ' Determine Display Type
    If RegRead("prefMovieImageType") = "poster" Then
        screen.SetGridStyle("flat-movie")
    Else
        screen.SetGridStyle("two-row-flat-landscape-custom")
    End If

    screen.SetDisplayMode("scale-to-fill")

    screen.SetupLists(1)
    screen.SetListNames([boxsetName])

    rowData = CreateObject("roArray", 1, true)

    ' Get Data
    moviesAll = GetMoviesInBoxset(boxsetId)
    rowData[0] = moviesAll
    screen.SetContentList(0, moviesAll)

    ' Show Screen
    screen.Show()

    ' Hide Description Popup
    screen.SetDescriptionVisible(false)

    while true
        msg = wait(0, screen.GetMessagePort())

        if type(msg) = "roGridScreenEvent" Then
            if msg.isListItemFocused() then

            else if msg.isListItemSelected() Then
                row = msg.GetIndex()
                selection = msg.getData()

                If rowData[row][selection].ContentType = "Movie" Then
                    movieIndex = ShowMoviesDetailPage(rowData[row][selection].Id, moviesAll, selection)
                    screen.SetFocusedListItem(row, movieIndex)
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
'** Get Movies From a Specific Boxset From Server
'**********************************************************

Function GetMoviesInBoxset(boxsetId As String) As Object

    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/Users/" + m.curUserProfile.Id + "/Items?Recursive=true&IncludeItemTypes=Movie&ParentId=" + boxsetId + "&Fields=UserData&SortBy=ProductionYear%2CSortName&SortOrder=Ascending", true)

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
                            Watched: itemData.UserData.Played
                        }

                        ' Get Image Type From Preference
                        If RegRead("prefMovieImageType") = "poster" Then

                            ' Check If Item has Image, otherwise use default
                            If itemData.ImageTags.Primary<>"" And itemData.ImageTags.Primary<>invalid
                                movieData.HDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Primary/0?height=192&width=&EnableImageEnhancers=false&tag=" + itemData.ImageTags.Primary
                                movieData.SDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Primary/0?height=140&width=&EnableImageEnhancers=false&tag=" + itemData.ImageTags.Primary
                            Else 
                                movieData.HDPosterUrl = "pkg://images/items/collection.png"
                                movieData.SDPosterUrl = "pkg://images/items/collection.png"
                            End If

                        Else If RegRead("prefMovieImageType") = "thumb" Then

                            ' Check If Item has Image, otherwise use default
                            If itemData.ImageTags.Thumb<>"" And itemData.ImageTags.Thumb<>invalid
                                movieData.HDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Thumb/0?height=150&width=&EnableImageEnhancers=false&tag=" + itemData.ImageTags.Thumb
                                movieData.SDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Thumb/0?height=94&width=&EnableImageEnhancers=false&tag=" + itemData.ImageTags.Thumb
                            Else 
                                movieData.HDPosterUrl = "pkg://images/items/collection.png"
                                movieData.SDPosterUrl = "pkg://images/items/collection.png"
                            End If

                        Else

                            ' Check If Item has Image, otherwise use default
                            If itemData.BackdropImageTags[0]<>"" And itemData.BackdropImageTags[0]<>invalid
                                movieData.HDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Backdrop/0?height=150&width=&tag=" + itemData.BackdropImageTags[0]
                                movieData.SDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Backdrop/0?height=94&width=&tag=" + itemData.BackdropImageTags[0]
                            Else 
                                movieData.HDPosterUrl = "pkg://images/items/collection.png"
                                movieData.SDPosterUrl = "pkg://images/items/collection.png"
                            End If

                        End If

                        ' Show / Hide Series Name
                        If RegRead("prefMovieTitle") = "show" Then
                            movieData.ShortDescriptionLine1 = itemData.Name
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
