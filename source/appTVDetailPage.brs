'*****************************************************************
'**  Media Browser Roku Client - TV Detail Page
'*****************************************************************


'**********************************************************
'** Show TV Details Page
'**********************************************************

Function ShowTVDetailPage(showId As String, list=invalid) As Integer

    if validateParam(showId, "roString", "ShowTVDetailPage") = false return -1

    ' Setup Screen
    port   = CreateObject("roMessagePort")
    screen = CreateObject("roSpringboardScreen")
    screen.SetMessagePort(port)

    screen.SetBreadcrumbText("", "TV")
    screen.SetDescriptionStyle("movie")
    screen.SetPosterStyle("rounded-rect-16x9-generic")

    ' Get Data
    tvDetails = GetTVDetails(showId)

    ' Show Screen
    screen.ClearButtons()

    'If regread(show.contentid) <> invalid and regread(show.contentid).toint() >=30 Then
        'screen.AddButton(1, "Resume playing")    
        'screen.AddButton(2, "Play from beginning")    
    'Else
       screen.AddButton(2, "Play")
    'End If
    screen.SetContent(tvDetails)
    screen.Show()

    ' Hide Star Rating
    screen.SetStaticRatingEnabled(false)

    ' Remote key id's for left/right navigation
    remoteKeyLeft  = 4
    remoteKeyRight = 5
 
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
                '    PlayStart = RegRead(showList[showIndex].ContentId)
                '    if PlayStart <> invalid then
                '        showList[showIndex].PlayStart = PlayStart.ToInt()
                '    endif
                '    showVideoScreen(showList[showIndex])
                '    refreshShowDetail(screen,showList,showIndex)
                End If
                If msg.GetIndex() = 2

                    ' Hide Playback Buttons If Invalid Or Blank - Should be temporary call
                    If tvDetails.DoesExist("streamFormat")=false
                        ShowDialog("Playback Error", "That video type Is Not playable yet.", "Back")
                    Else 
                        showVideoScreen(tvDetails)
                    End If

                    'showList[showIndex].PlayStart = 0
                    'showVideoScreen(showList[showIndex])
                    'refreshShowDetail(screen,showList,showIndex)
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
'** Get TV Details From Server
'**********************************************************

Function GetTVDetails(showId As String) As Object

    if validateParam(showId, "roString", "GetTVDetails") = false return -1

    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/Users/" + m.curUserProfile.Id + "/Items/" + showId)

    if (request.AsyncGetToString())
        while (true)
            msg = wait(0, request.GetPort())

            if (type(msg) = "roUrlEvent")
                code = msg.GetResponseCode()

                if (code = 200)
                    ' Fixes bug within BRS Json Parser
                    regex = CreateObject("roRegex", Chr(34) + "RunTimeTicks" + Chr(34) + ":([0-9]+),", "i")
                    fixedString = regex.ReplaceAll(msg.GetString(), Chr(34) + "RunTimeTicks" + Chr(34) + ":" + Chr(34) + "\1" + Chr(34) + ",")

                    itemData = ParseJSON(fixedString)

                    ' Convert Data For Page
                    episodeData = {
                        Id: itemData.Id
                        ContentId: itemData.Id
                        ContentType: "episode"
                        Title: itemData.Name
                        Description: itemData.Overview 
                        Rating: itemData.OfficialRating
                    }

                    ' Use Actor Area For Series / Season / Episode
                    episodeData.Actors = itemData.SeriesName + " / Season " + Stri(itemData.ParentIndexNumber) + " / Episode "  + Stri(itemData.IndexNumber)

                    ' Check For Production Year
                    If Type(itemData.ProductionYear) = "Integer" Then
                        episodeData.ReleaseDate = Stri(itemData.ProductionYear)
                    End if

                    ' Check For Run Time
                    itemRunTime = itemData.RunTimeTicks
                    If itemRunTime<>"" And itemRunTime<>invalid
                        episodeData.Length = Int(((itemRunTime).ToFloat() / 10000) / 1000)
                    End If

                    ' Check If Item has Image, otherwise use default
                    If itemData.ImageTags.Primary<>"" And itemData.ImageTags.Primary<>invalid
                        episodeData.HDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Primary/0?height=152&width=&tag=" + itemData.ImageTags.Primary
                        episodeData.SDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Primary/0?height=90&width=&tag=" + itemData.ImageTags.Primary
                    Else 
                        episodeData.HDPosterUrl = "pkg://images/items/collection.png"
                        episodeData.SDPosterUrl = "pkg://images/items/collection.png"
                    End If

                    ' Check Media Streams For HD Video And Surround Sound Audio
                    streamInfo = GetStreamInfo(itemData.MediaStreams)

                    episodeData.HDBranded = streamInfo.isHDVideo

                    If streamInfo.isSSAudio=true
                        episodeData.AudioFormat = "dolby-digital"
                    End If

                    ' Setup Video Player
                    streamData = SetupVideoStreams(showId, itemData.VideoType, itemData.Path)

                    If streamData<>invalid
                        episodeData.streamFormat = streamData.streamFormat
                        episodeData.StreamBitrates = streamData.StreamBitrates
                        episodeData.StreamUrls = streamData.StreamUrls
                        episodeData.StreamQualities = streamData.StreamQualities
                    End If

                    return episodeData
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
Function refreshShowDetail3(screen As Object, showList As Object, showIndex as Integer) As Integer

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
Function getNextShow3(showList As Object, showIndex As Integer) As Integer
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
Function getPrevShow3(showList As Object, showIndex As Integer) As Integer
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

