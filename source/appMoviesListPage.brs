'*****************************************************************
'**  Media Browser Roku Client - Movies List Page
'*****************************************************************


'**********************************************************
'** Show Movies List Page
'**********************************************************

Function ShowMoviesListPage() As Integer

    ' Create Grid Screen
    If RegRead("prefMovieImageType") = "poster" Then
        screen = CreateGridScreen("", "Movies", "mixed-aspect-ratio")
    Else
        screen = CreateGridScreen("", "Movies", "two-row-flat-landscape-custom")
    End If

    screen.AddRow("Movies", "portrait")
    screen.AddRow("Box Sets", "portrait")
    screen.AddRow("Genres", "portrait")

    screen.ShowNames()

    If RegRead("prefMovieImageType") = "poster" Then
        screen.SetListPosterStyles(screen.rowStyles)
    End If

    ' Show Loading Dialog
    dialogBox = ShowPleaseWait("Loading...","")

    ' Initialize Movie Metadata
    MovieMetadata = InitMovieMetadata()

    ' Get Data
    moviesAll     = MovieMetadata.GetMovieList()
    moviesBoxsets = GetMoviesBoxsets()
    moviesGenres  = MovieMetadata.GetGenres()

    screen.AddRowContent(moviesAll)
    screen.AddRowContent(moviesBoxsets)
    screen.AddRowContent(moviesGenres)

    ' Show Screen
    screen.Show()

    ' Close Loading Dialog
    dialogBox.Close()

    ' Show/Hide Description Popup
    If RegRead("prefMovieDisplayPopup") = "no" Or RegRead("prefMovieDisplayPopup") = invalid Then
        screen.SetDescriptionVisible(false)
    End If

    ' Remote key id's for navigation
    remoteKeyStar = 10

    while true
        msg = wait(0, screen.Port)

        if type(msg) = "roGridScreenEvent" Then
            if msg.isListItemFocused() Then
                ' Show/Hide Description Popup
                If RegRead("prefMovieDisplayPopup") = "yes" Then
                    screen.SetDescriptionVisible(true) ' Work around for bug in mixed-aspect-ratio
                End If
            else if msg.isListItemSelected() Then
                row = msg.GetIndex()
                selection = msg.getData()

                If screen.rowContent[row][selection].ContentType = "Movie" Then
                    movieIndex = ShowMoviesDetailPage(screen.rowContent[row][selection].Id, moviesAll, selection)
                    screen.SetFocusedListItem(row, movieIndex)
                Else If screen.rowContent[row][selection].ContentType = "Genre" Then
                    ShowMoviesGenrePage(screen.rowContent[row][selection].Id)
                Else If screen.rowContent[row][selection].ContentType = "BoxSet" Then
                    ShowMoviesBoxsetPage(screen.rowContent[row][selection].Id, screen.rowContent[row][selection].Title)
                Else 
                    Debug("Unknown Type found")
                End If

            else if msg.isRemoteKeyPressed() then
                index = msg.GetIndex()

                If index = remoteKeyStar Then
                    letterSelected = CreateJumpListDialog()

                    If letterSelected <> invalid Then
                        letter = FindClosestLetter(letterSelected, MovieMetadata)
                        screen.SetFocusedListItem(0, MovieMetadata.jumpList.Lookup(letter))
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
'** Get Movie Boxsets From Server
'**********************************************************

Function GetMoviesBoxsets() As Object

    ' Clean Fields
    fields = HttpEncode("Overview,UserData,ItemCounts")

    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/Users/" + m.curUserProfile.Id + "/Items?Recursive=true&IncludeItemTypes=BoxSet&Fields=" + fields + "&SortBy=SortName&SortOrder=Ascending", true)

    'Debug("Movie Boxset List URL: " + request.GetUrl())

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

                        ' Get Image Type From Preference
                        If RegRead("prefMovieImageType") = "poster" Then

                            ' Check If Item has Image, otherwise use default
                            If itemData.ImageTags.Primary<>"" And itemData.ImageTags.Primary<>invalid
                                movieData.HDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Primary/0?quality=90&height=274&width=192&EnableImageEnhancers=false&tag=" + itemData.ImageTags.Primary
                                movieData.SDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Primary/0?quality=90&height=180&width=140&EnableImageEnhancers=false&tag=" + itemData.ImageTags.Primary
                            Else 
                                movieData.HDPosterUrl = "pkg://images/items/collection.png"
                                movieData.SDPosterUrl = "pkg://images/items/collection.png"
                            End If

                        Else If RegRead("prefMovieImageType") = "thumb" Then

                            ' Check If Item has Image, otherwise use default
                            If itemData.ImageTags.Thumb<>"" And itemData.ImageTags.Thumb<>invalid
                                movieData.HDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Thumb/0?quality=90&height=150&width=&EnableImageEnhancers=false&tag=" + itemData.ImageTags.Thumb
                                movieData.SDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Thumb/0?quality=90&height=94&width=&EnableImageEnhancers=false&tag=" + itemData.ImageTags.Thumb
                            Else 
                                movieData.HDPosterUrl = "pkg://images/items/collection.png"
                                movieData.SDPosterUrl = "pkg://images/items/collection.png"
                            End If

                        Else

                            ' Check If Item has Image, otherwise use default
                            If itemData.BackdropImageTags[0]<>"" And itemData.BackdropImageTags[0]<>invalid
                                movieData.HDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Backdrop/0?quality=90&height=150&width=&tag=" + itemData.BackdropImageTags[0]
                                movieData.SDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Backdrop/0?quality=90&height=94&width=&tag=" + itemData.BackdropImageTags[0]
                            Else 
                                movieData.HDPosterUrl = "pkg://images/items/collection.png"
                                movieData.SDPosterUrl = "pkg://images/items/collection.png"
                            End If

                        End If

                        ' Movie Count
                        If itemData.ChildCount<>invalid
                            'movieData.Description = itostr(itemData.ChildCount) + " movies"
                            movieData.ShortDescriptionLine2 = itostr(itemData.ChildCount) + " movies"
                        End If

                        ' Overview
                        If itemData.Overview<>invalid
                            movieData.Description = itemData.Overview
                        End If

                        ' Movie Rating
                        If itemData.OfficialRating<>invalid
                            movieData.Rating = itemData.OfficialRating
                        End If

                        list.push( movieData )
                    end for
                    return list
                else
                    Debug("Failed to Get Boxsets for Movies")
                    return invalid
                end if
            else if (event = invalid)
                request.AsyncCancel()
            end if
        end while
    end if

    Return invalid
End Function
