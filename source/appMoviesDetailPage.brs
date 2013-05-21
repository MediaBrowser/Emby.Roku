'*****************************************************************
'**  Media Browser Roku Client - Movies Detail Page
'*****************************************************************


'**********************************************************
'** Show Movies Details Page
'**********************************************************

Function ShowMoviesDetailPage(movieId As String, list=invalid) As Integer

    if validateParam(movieId, "roString", "ShowMoviesDetailPage") = false return -1

    ' Setup Screen
    port   = CreateObject("roMessagePort")
    screen = CreateObject("roSpringboardScreen")
    screen.SetMessagePort(port)

    screen.SetBreadcrumbText("", "Movies")
    screen.SetDescriptionStyle("movie")

    ' Fetch / Refresh Screen Details
    moviesDetails = RefreshMoviesDetailPage(screen, movieId, list)

    ' Remote key id's for left/right navigation
    remoteKeyLeft  = 4
    remoteKeyRight = 5
 
    'if list<>invalid

    while true
        msg = wait(0, screen.GetMessagePort())

        if type(msg) = "roSpringboardScreenEvent" then
            If msg.isRemoteKeyPressed() 
                print "Remote key pressed"
                if msg.GetIndex() = remoteKeyLeft then
                    'showIndex = getPrevShow(showList, m.curItemIndex)
                    'if showIndex <> -1
                    '    refreshShowDetail(screen, showList, showIndex)
                    'end if
                else if msg.GetIndex() = remoteKeyRight
                    'showIndex = getNextShow(showList, m.curItemIndex)
                    'if showIndex <> -1
                    '   refreshShowDetail(screen, showList, showIndex)
                    'end if
                endif
            Else If msg.isButtonPressed()
                print "ButtonPressed"
                If msg.GetIndex() = 1
                    ' Get Saved Play Status
                    PlayStart = RegRead(moviesDetails.ContentId)

                    If PlayStart<>invalid Then
                        moviesDetails.PlayStart = PlayStart.ToInt()
                    End If

                    showVideoScreen(moviesDetails)
                    moviesDetails = RefreshMoviesDetailPage(screen, movieId, list)
                End If
                If msg.GetIndex() = 2
                    ' Reset Play To Beginning
                    moviesDetails.PlayStart = 0

                    ' Show Error Dialog For Unsupported video types - Should be temporary call
                    If moviesDetails.DoesExist("streamFormat")=false
                        ShowDialog("Playback Error", "That video type is not playable yet.", "Back")
                    Else
                        showVideoScreen(moviesDetails)
                        moviesDetails = RefreshMoviesDetailPage(screen, movieId, list)
                    End If
                End If
                'if msg.GetIndex() = 3
                'endif
                print "Button pressed: "; msg.GetIndex(); " " msg.GetData()
            Else If msg.isScreenClosed()
                print "Screen closed"
                return -1
            End If
        Else
            print "Unexpected message class: "; type(msg)
        End If
    end while

    return 0
End Function


'**********************************************************
'** Get Movie Details From Server
'**********************************************************

Function GetMoviesDetails(movieId As String) As Object

    if validateParam(movieId, "roString", "GetMoviesDetails") = false return -1

    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/Users/" + m.curUserProfile.Id + "/Items/" + movieId)

    if (request.AsyncGetToString())
        while (true)
            msg = wait(0, request.GetPort())

            if (type(msg) = "roUrlEvent")
                code = msg.GetResponseCode()

                if (code = 200)
                    list     = CreateObject("roArray", 2, true)

                    ' Fixes bug within BRS Json Parser
                    regex = CreateObject("roRegex", Chr(34) + "RunTimeTicks" + Chr(34) + ":([0-9]+),", "i")
                    fixedString = regex.ReplaceAll(msg.GetString(), Chr(34) + "RunTimeTicks" + Chr(34) + ":" + Chr(34) + "\1" + Chr(34) + ",")

                    itemData = ParseJSON(fixedString)

                    ' Convert Data For Page
                    movieData = {
                        Id: itemData.Id
                        ContentId: itemData.Id
                        ContentType: "movie"
                        Title: itemData.Name
                        Description: itemData.Overview
                        Rating: itemData.OfficialRating
                        StarRating: itemData.CriticRating
                        Watched: itemData.UserData.Played
                    }

                    ' Check For Production Year
                    If Type(itemData.ProductionYear) = "Integer" Then
                        movieData.ReleaseDate = Stri(itemData.ProductionYear)
                    End if

                    ' Check For Run Time
                    itemRunTime = itemData.RunTimeTicks
                    If itemRunTime<>"" And itemRunTime<>invalid
                        movieData.Length = Int(((itemRunTime).ToFloat() / 10000) / 1000)
                    End If

                    ' Check If Item has Image, otherwise use default
                    If itemData.ImageTags.Primary<>"" And itemData.ImageTags.Primary<>invalid
                        movieData.HDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Primary/0?height=212&width=&tag=" + itemData.ImageTags.Primary
                        movieData.SDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Primary/0?height=142&width=&tag=" + itemData.ImageTags.Primary
                    Else 
                        movieData.HDPosterUrl = "pkg://images/items/collection.png"
                        movieData.SDPosterUrl = "pkg://images/items/collection.png"
                    End If

                    ' Check For People, Grab First 3 If Exists
                    If itemData.People<>invalid And itemData.People.Count() > 0
                        movieData.Actors = CreateObject("roArray", 10, true)

                        maxPeople = itemData.People.Count()-1

                        ' Check To Max sure there are 3 people
                        If maxPeople > 3
                            maxPeople = 2
                        End If

                        For i = 0 to maxPeople
                            If itemData.People[i].Name<>"" And itemData.People[i].Name<>invalid
                                movieData.Actors.Push(itemData.People[i].Name)
                            End If
                        End For
                    End If

                    ' Check Media Streams For HD Video And Surround Sound Audio
                    streamInfo = GetStreamInfo(itemData.MediaStreams)

                    movieData.HDBranded = streamInfo.isHDVideo
                    movieData.IsHD = streamInfo.isHDVideo

                    If streamInfo.isSSAudio=true
                        movieData.AudioFormat = "dolby-digital"
                    End If

                    ' Setup Video Player
                    streamData = SetupVideoStreams(movieId, itemData.VideoType, itemData.Path)

                    If streamData<>invalid
                        movieData.StreamContentIDs = streamData.StreamContentIDs
                        movieData.streamFormat = streamData.streamFormat
                        movieData.StreamBitrates = streamData.StreamBitrates
                        movieData.StreamUrls = streamData.StreamUrls
                        movieData.StreamQualities = streamData.StreamQualities
                    End If
                    
                   ' o.Categories = CreateObject("roArray", 10, true) 
                   ' o.Categories.Push("[Category1]")
                   ' o.Categories.Push("[Category2]")
                   ' o.Categories.Push("[Category3]")
                   ' o.Director = "[Director]"
                   ' springBoard.SetContent(o)

                    return movieData
                endif
            else if (event = invalid)
                request.AsyncCancel()
            endif
        end while
    endif

    Return invalid
End Function


'**************************************************************
'** Refresh the Contents of the Movies Detail Page
'**************************************************************

Function RefreshMoviesDetailPage(screen As Object, movieId As String, list=invalid) As Object

    if validateParam(screen, "roSpringboardScreen", "RefreshMoviesDetailPage") = false return -1
    if validateParam(movieId, "roString", "RefreshMoviesDetailPage") = false return -1

    ' Get Data
    moviesDetails = GetMoviesDetails(movieId)

    ' Show Screen
    screen.ClearButtons()

    If RegRead(moviesDetails.ContentId)<>invalid and RegRead(moviesDetails.ContentId).toInt() >=30 Then
        screen.AddButton(1, "Resume playing")    
        screen.AddButton(2, "Play from beginning")    
    Else
        screen.AddButton(2, "Play")
    End If

    screen.SetContent(moviesDetails)
    screen.Show()

    Return moviesDetails
End Function














'********************************************************
'** Get the next item in the list and handle the wrap 
'** around case to implement a circular list for left/right 
'** navigation on the springboard screen
'********************************************************
Function getNextShow2(showList As Object, showIndex As Integer) As Integer
    if validateParam(showList, "roArray", "getNextShow") = false return -1

    nextIndex = showIndex + 1
    if nextIndex >= showList.Count() or nextIndex < 0 then
       nextIndex = 0 
    end if

    show = showList[nextIndex]
    if validateParam(show, "roAssociativeArray", "getNextShow") = false return -1 

    m.curItemIndex = nextIndex

    return nextIndex
End Function


'********************************************************
'** Get the previous item in the list and handle the wrap 
'** around case to implement a circular list for left/right 
'** navigation on the springboard screen
'********************************************************
Function getPrevShow2(showList As Object, showIndex As Integer) As Integer
    if validateParam(showList, "roArray", "getPrevShow") = false return -1 

    prevIndex = showIndex - 1
    if prevIndex < 0 or prevIndex >= showList.Count() then
        if showList.Count() > 0 then
            prevIndex = showList.Count() - 1 
        else
            return -1
        end if
    end if

    show = showList[prevIndex]
    if validateParam(show, "roAssociativeArray", "getPrevShow") = false return -1 

    m.curItemIndex = prevIndex

    return prevIndex
End Function

