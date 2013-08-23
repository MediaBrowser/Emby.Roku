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

    ' Setup Jump List
    m.jumpList = {}

    ' Setup Row Data
    screen.rowNames   = CreateObject("roArray", 3, true)
    screen.rowStyles  = CreateObject("roArray", 3, true)
    screen.rowContent = CreateObject("roArray", 3, true)

    AddGridRow(screen, "Movies", "portrait")
    AddGridRow(screen, "Box Sets", "portrait")
    AddGridRow(screen, "Genres", "landscape")

    ShowGridNames(screen)

    If RegRead("prefMovieImageType") = "poster" Then
        screen.Screen.SetListPosterStyles(screen.rowStyles)
    End If

    ' Show Loading Dialog
    dialogBox = ShowPleaseWait("Loading...","")

    ' Get Data
    moviesAll     = GetMoviesAll()
    moviesBoxsets = GetMoviesBoxsets()
    moviesGenres  = GetMoviesGenres()

    AddGridRowContent(screen, moviesAll)
    AddGridRowContent(screen, moviesBoxsets)
    AddGridRowContent(screen, moviesGenres)

    ' Show Screen
    screen.Screen.Show()

    ' Close Loading Dialog
    dialogBox.Close()

    ' Show/Hide Description Popup
    If RegRead("prefMovieDisplayPopup") = "no" Or RegRead("prefMovieDisplayPopup") = invalid Then
        screen.Screen.SetDescriptionVisible(false)
    End If

    ' Remote key id's for navigation
    remoteKeyStar = 10

    while true
        msg = wait(0, screen.Screen.GetMessagePort())

        if type(msg) = "roGridScreenEvent" Then
            if msg.isListItemFocused() Then
                ' Show/Hide Description Popup
                If RegRead("prefMovieDisplayPopup") = "yes" Then
                    screen.Screen.SetDescriptionVisible(true) ' Work around for bug in mixed-aspect-ratio
                End If
            else if msg.isListItemSelected() Then
                row = msg.GetIndex()
                selection = msg.getData()

                If screen.rowContent[row][selection].ContentType = "Movie" Then
                    movieIndex = ShowMoviesDetailPage(screen.rowContent[row][selection].Id, moviesAll, selection)
                    screen.Screen.SetFocusedListItem(row, movieIndex)
                Else If screen.rowContent[row][selection].ContentType = "Genre" Then
                    ShowMoviesGenrePage(screen.rowContent[row][selection].Id)
                Else If screen.rowContent[row][selection].ContentType = "BoxSet" Then
                    ShowMoviesBoxsetPage(screen.rowContent[row][selection].Id, screen.rowContent[row][selection].Title)
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

    ' Clean Fields
    fields = HttpEncode("Overview,UserData,MediaStreams,SortName")

    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/Users/" + m.curUserProfile.Id + "/Items?Recursive=true&IncludeItemTypes=Movie&Fields=" + fields + "&SortBy=SortName&SortOrder=Ascending", true)

    'Print "Movie List URL: " + request.GetUrl()

    if (request.AsyncGetToString())
        while (true)
            msg = wait(0, request.GetPort())

            if (type(msg) = "roUrlEvent")
                code = msg.GetResponseCode()

                if (code = 200)
                    ' Fixes bug within BRS Json Parser
                    regex = CreateObject("roRegex", Chr(34) + "(RunTimeTicks)" + Chr(34) + ":([0-9]+),", "i")
                    fixedString = regex.ReplaceAll(msg.GetString(), Chr(34) + "\1" + Chr(34) + ":" + Chr(34) + "\2" + Chr(34) + ",")

                    index    = 0
                    list     = CreateObject("roArray", 2, true)
                    jsonData = ParseJSON(fixedString)

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

                        ' Check For Run Time
                        itemRunTime = itemData.RunTimeTicks
                        If itemRunTime<>"" And itemRunTime<>invalid
                            movieData.Length = Int(((itemRunTime).ToFloat() / 10000) / 1000)
                        End If

                        If itemData.Overview<>invalid
                            movieData.Description = itemData.Overview
                        End If

                        If itemData.OfficialRating<>invalid
                            movieData.Rating = itemData.OfficialRating
                        End If

                        If Type(itemData.ProductionYear) = "Integer" Then
                            movieData.ReleaseDate = itostr(itemData.ProductionYear)
                        End If

                        If itemData.CriticRating<>invalid
                            movieData.StarRating = itemData.CriticRating
                        End If

                        movieData.HDBranded = true

                        ' Show / Hide Movie Name
                        If RegRead("prefMovieTitle") = "show" Or RegRead("prefMovieTitle") = invalid Then
                            movieData.ShortDescriptionLine1 = itemData.Name
                        End If

                        ' Build Jump List
                        firstChar = Left(itemData.SortName, 1)
                        If Not m.jumpList.DoesExist(firstChar) Then
                            m.jumpList.AddReplace(firstChar, index)
                        End If

                        ' Increment Count
                        index = index + 1

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

    'Print "Movie Genre List URL: " + request.GetUrl()

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

                        ' Clean Genre Name
                        genreName = HttpEncode(itemData.Name)

                        ' Get Image Type From Preference
                        If RegRead("prefMovieImageType") = "poster" Then

                            ' Check If Item has Image, otherwise use default
                            If itemData.ImageTags.Primary<>"" And itemData.ImageTags.Primary<>invalid
                                movieData.HDPosterUrl = GetServerBaseUrl() + "/Genres/" + genreName + "/Images/Primary/0?quality=90&height=192&width=192&tag=" + itemData.ImageTags.Primary
                                movieData.SDPosterUrl = GetServerBaseUrl() + "/Genres/" + genreName + "/Images/Primary/0?quality=90&height=126&width=140&tag=" + itemData.ImageTags.Primary
                            Else 
                                movieData.HDPosterUrl = "pkg://images/items/collection.png"
                                movieData.SDPosterUrl = "pkg://images/items/collection.png"
                            End If

                        Else

                            ' Check If Item has Image, otherwise use default
                            If itemData.ImageTags.Primary<>"" And itemData.ImageTags.Primary<>invalid
                                movieData.HDPosterUrl = GetServerBaseUrl() + "/Genres/" + genreName + "/Images/Primary/0?quality=90&height=150&width=&tag=" + itemData.ImageTags.Primary
                                movieData.SDPosterUrl = GetServerBaseUrl() + "/Genres/" + genreName + "/Images/Primary/0?quality=90&height=94&width=&tag=" + itemData.ImageTags.Primary
                            Else If itemData.BackdropImageTags[0]<>"" And itemData.BackdropImageTags[0]<>invalid
                                movieData.HDPosterUrl = GetServerBaseUrl() + "/Genres/" + genreName + "/Images/Backdrop/0?quality=90&height=150&width=&tag=" + itemData.BackdropImageTags[0]
                                movieData.SDPosterUrl = GetServerBaseUrl() + "/Genres/" + genreName + "/Images/Backdrop/0?quality=90&height=94&width=&tag=" + itemData.BackdropImageTags[0]
                            Else 
                                movieData.HDPosterUrl = "pkg://images/items/collection.png"
                                movieData.SDPosterUrl = "pkg://images/items/collection.png"
                            End If

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

    ' Clean Fields
    fields = HttpEncode("Overview,UserData,ItemCounts")

    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/Users/" + m.curUserProfile.Id + "/Items?Recursive=true&IncludeItemTypes=BoxSet&Fields=" + fields + "&SortBy=SortName&SortOrder=Ascending", true)

    'Print "Movie Boxset List URL: " + request.GetUrl()

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
                endif
            else if (event = invalid)
                request.AsyncCancel()
            endif
        end while
    endif

    Return invalid
End Function

