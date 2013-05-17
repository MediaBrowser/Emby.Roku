'*****************************************************************
'**  Media Browser Roku Client - Detail Page
'*****************************************************************

Function CreateDetailPage(breadA=invalid, breadB=invalid) As Object

    if validateParam(breadA, "roString", "CreateDetailPage", true) = false return -1
    if validateParam(breadA, "roString", "CreateDetailPage", true) = false return -1

    port   = CreateObject("roMessagePort")
    screen = CreateObject("roSpringboardScreen")
    screen.SetMessagePort(port)
    if breadA<>invalid and breadB<>invalid then
        screen.SetBreadcrumbText(breadA, breadB)
    end if

    screen.SetDescriptionStyle("video")

    return screen
End Function

Function ShowDetailPage(screen As Object, showList As Object) As Integer

    if validateParam(screen, "roSpringboardScreen", "ShowDetailPage") = false return -1
    if validateParam(showList, "roArray", "ShowDetailPage") = false return -1

    ' m.curUserProfile, m.curCollection, m.curItem

    refreshShowDetail(screen, showList, m.curItemIndex)

    'remote key id's for left/right navigation
    remoteKeyLeft  = 4
    remoteKeyRight = 5
 
    while true
        msg = wait(0, screen.GetMessagePort())

        if type(msg) = "roSpringboardScreenEvent" then
            if msg.isScreenClosed()
                print "Screen closed"
                return -1
            else if msg.isRemoteKeyPressed() 
                print "Remote key pressed"
                if msg.GetIndex() = remoteKeyLeft then
                    showIndex = getPrevShow(showList, m.curItemIndex)
                    if showIndex <> -1
                        refreshShowDetail(screen, showList, showIndex)
                    end if
                else if msg.GetIndex() = remoteKeyRight
                    showIndex = getNextShow(showList, m.curItemIndex)
                    if showIndex <> -1
                       refreshShowDetail(screen, showList, showIndex)
                    end if
                endif
            else if msg.isButtonPressed() 
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
            end if
        else
            print "Unexpected message class: "; type(msg)
        end if
    end while

    return showIndex
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
Function refreshShowDetail(screen As Object, showList As Object, showIndex as Integer) As Integer

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
Function getNextShow(showList As Object, showIndex As Integer) As Integer
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
Function getPrevShow(showList As Object, showIndex As Integer) As Integer
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



'**********************************************************
'** Get Item Details From Server
'**********************************************************
Function GetItemDetails(user, cole, itemObj) As Object
    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/Users/" + user.Id + "/Items?ParentId=" + cole.Id + "&SortBy=SortName&SortOrder=Ascending")

    if (request.AsyncGetToString())
        while (true)
            msg = wait(0, request.GetPort())

            if (type(msg) = "roUrlEvent")
                code = msg.GetResponseCode()

                if (code = 200)
                    collectionList = CreateObject("roArray", 10, true)
                    json = ParseJSON(msg.GetString())
                    Print "Get data"
                    for each collection in json.Items
                        collectionData = {
                            ID: collection.Id
                            Title: collection.Name
                            ShortDescriptionLine1: collection.Name
                            HDPosterUrl: GetServerBaseUrl() + "/Items/" + collection.Id + "/Images/Primary/0?height=300&width=&tag=" + collection.ImageTags.Primary
                            'SDPosterUrl: GetServerBaseUrl() + "/Items/" + collection.Id + "/Images/Primary"
                        }

                        collectionList.push( collectionData )
                    end for
                    return collectionList
                endif
            else if (event = invalid)
                request.AsyncCancel()
            endif
        end while
    endif

    return invalid
End Function
