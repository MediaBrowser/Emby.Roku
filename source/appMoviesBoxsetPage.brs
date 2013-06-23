'*****************************************************************
'**  Media Browser Roku Client - Movies Boxset Page
'*****************************************************************


'**********************************************************
'** Show Movies Boxset Page
'**********************************************************

Function ShowMoviesBoxsetPage(boxsetId As String, boxsetName As String) As Integer

    if validateParam(boxsetId, "roString", "ShowMoviesBoxsetPage") = false return -1

    ' Create Grid Screen
    If RegRead("prefMovieImageType") = "poster" Then
        screen = CreateGridScreen(boxsetName, "Movies", "flat-movie")
    Else
        screen = CreateGridScreen(boxsetName, "Movies", "two-row-flat-landscape-custom")
    End If

    ' Setup Row Data
    screen.rowNames   = CreateObject("roArray", 1, true)
    screen.rowStyles  = CreateObject("roArray", 1, true)
    screen.rowContent = CreateObject("roArray", 1, true)

    AddGridRow(screen, "Movies", "portrait")

    ShowGridNames(screen)

    ' Get Data
    moviesAll = GetMoviesInBoxset(boxsetId)

    AddGridRowContent(screen, moviesAll)

    ' Show Screen
    screen.Screen.Show()

    ' Hide Description Popup
    screen.Screen.SetDescriptionVisible(false)

    while true
        msg = wait(0, screen.Screen.GetMessagePort())

        if type(msg) = "roGridScreenEvent" Then
            if msg.isListItemFocused() then

            else if msg.isListItemSelected() Then
                row = msg.GetIndex()
                selection = msg.getData()

                If screen.rowContent[row][selection].ContentType = "Movie" Then
                    movieIndex = ShowMoviesDetailPage(screen.rowContent[row][selection].Id, moviesAll, selection)
                    screen.Screen.SetFocusedListItem(row, movieIndex)
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
                                movieData.HDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Primary/0?height=270&width=210&EnableImageEnhancers=false&tag=" + itemData.ImageTags.Primary
                                movieData.SDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Primary/0?height=150&width=110&EnableImageEnhancers=false&tag=" + itemData.ImageTags.Primary
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
