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

    ' Get Data
    moviesDetails = GetMoviesDetails(movieId)

    ' Show Screen
    screen.ClearButtons()

    'If regread(show.contentid) <> invalid and regread(show.contentid).toint() >=30 Then
        'screen.AddButton(1, "Resume playing")    
        'screen.AddButton(2, "Play from beginning")    
    'Else
       screen.addbutton(2, "Play")
    'End If
    screen.SetContent(moviesDetails)
    screen.Show()

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
                'if msg.GetIndex() = 1
                '    PlayStart = RegRead(showList[showIndex].ContentId)
                '    if PlayStart <> invalid then
                '        showList[showIndex].PlayStart = PlayStart.ToInt()
                '    endif
                '    showVideoScreen(showList[showIndex])
                '    refreshShowDetail(screen,showList,showIndex)
                'endif
                'if msg.GetIndex() = 2
                '    showList[showIndex].PlayStart = 0
                '    showVideoScreen(showList[showIndex])
                '    refreshShowDetail(screen,showList,showIndex)
                'endif
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
                        ContentType: "portrait"
                        Title: itemData.Name
                        Description: itemData.Overview
                        Rating: itemData.OfficialRating
                        StarRating: itemData.CriticRating
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

                        For i = 0 to 2
                            movieData.Actors.Push(itemData.People[i].Name)
                        End For
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
'** Refresh the contents of the show detail screen. This may be
'** required on initial entry to the screen or as the user moves
'** left/right on the springboard.  When the user is on the
'** springboard, we generally let them press left/right arrow keys
'** to navigate to the previous/next show in a circular manner.
'** When leaving the screen, the should be positioned on the 
'** corresponding item in the poster screen matching the current show
'**************************************************************
Function refreshShowDetail2(screen As Object, showList As Object, showIndex as Integer) As Integer

    if validateParam(screen, "roSpringboardScreen", "refreshShowDetail") = false return -1
    if validateParam(showList, "roArray", "refreshShowDetail") = false return -1

    show = showList[showIndex]

    'Uncomment this statement to dump the details for each show
    'PrintAA(show)

    screen.ClearButtons()
    'if regread(show.contentid) <> invalid and regread(show.contentid).toint() >=30 then
        'screen.AddButton(1, "Resume playing")    
        'screen.AddButton(2, "Play from beginning")    
    'else
        screen.addbutton(2, "Play")
    'end if
    screen.SetContent(show)
    screen.Show()

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

