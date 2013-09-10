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
        screen = CreateGridScreen("Movies", boxsetName, "mixed-aspect-ratio")
    Else
        screen = CreateGridScreen("Movies", boxsetName, "two-row-flat-landscape-custom")
    End If

    screen.AddRow("Movies", "portrait")

    screen.ShowNames()

    ' Get Data
    moviesAll = GetMoviesInBoxset(boxsetId)

    screen.AddRowContent(moviesAll)

    ' Show Screen
    screen.Show()

    ' Show/Hide Description Popup
    If RegRead("prefMovieDisplayPopup") = "no" Or RegRead("prefMovieDisplayPopup") = invalid Then
        screen.SetDescriptionVisible(false)
    End If

    while true
        msg = wait(0, screen.Port)

        if type(msg) = "roGridScreenEvent" Then
            if msg.isListItemFocused() then
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
                Else 
                    Debug("Unknown Type found")
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

    ' Clean Fields
    fields = HttpEncode("Overview,UserData,MediaStreams,SortName")

    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/Users/" + m.curUserProfile.Id + "/Items?Recursive=true&IncludeItemTypes=Movie&ParentId=" + boxsetId + "&Fields=" + fields + "&SortBy=ProductionYear%2CSortName&SortOrder=Ascending", true)

    Debug("BoxSet URL: " + request.GetUrl())

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
						
                        ' Show / Hide Movie Name
                        If RegRead("prefMovieTitle") = "show" Or RegRead("prefMovieTitle") = invalid Then
                            movieData.ShortDescriptionLine1 = itemData.Name
                        End If

                        list.push( movieData )
                    end for
                    return list
                else
                    Debug("Failed to Get movies for the box set")
                    return invalid
                end if
            else if (event = invalid)
                request.AsyncCancel()
            endif
        end while
    endif

    Return invalid
End Function
