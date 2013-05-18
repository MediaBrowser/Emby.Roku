'*****************************************************************
'**  Media Browser Roku Client - List Page
'*****************************************************************

'**********************************************************
'** Create List Page
'**********************************************************

Function CreateListPage(breadA=invalid, breadB=invalid) As Object

    if validateParam(breadA, "roString", "CreateListPage", true) = false return -1
    if validateParam(breadA, "roString", "CreateListPage", true) = false return -1

    port   = CreateObject("roMessagePort")
    screen = CreateObject("roGridScreen")
    screen.SetMessagePort(port)
    if breadA<>invalid and breadB<>invalid then
        screen.SetBreadcrumbText(breadA, breadB)
    end if

    screen.SetGridStyle("two-row-flat-landscape-custom")
    screen.SetDisplayMode("scale-to-fit")
    return screen
End Function


'**********************************************************
'** Show List Page
'**********************************************************

Function ShowListPage(screen As Object) As Integer

    if validateParam(screen, "roGridScreen", "ShowListPage") = false return -1

    dataObj = GetLibraryItems()
    list = dataObj.Data
    
    'GetItemCategories(list)

    screen.SetupLists(1)
    screen.SetListNames(["All"])
    screen.SetContentList(0, list)
    'screen.SetContentList(1, list)
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
                selectedItem = list[selection]

                m.curItem = list[msg.GetIndex()]
                m.curItemIndex = msg.GetIndex()

                ' Check Content Type
                If selectedItem.ContentType = "Movie"
                    Print "movie found"
                    'If selectedItem.IsFolder = true
                    '    m.curParent = selectedItem
                    '    DisplayListPage()
                    'Else
                        DisplayDetailPage(list)
                    'End If
                Else If selectedItem.ContentType = "BoxSet"
                    Print "boxset found"

                        m.curParent = selectedItem
                        DisplayListPage()

                Else If selectedItem.ContentType = "Series"
                    Print "tv series found"

                Else
                    Print "unknown found"

                End If
                
                print "list item selected row= "; row; " selection= "; Selection
                

                'DisplayDetailPage(list)
            else if msg.isScreenClosed() then
                return -1
            end if
        end if
    end while

    return 0
End Function


'**********************************************************
'** Create And Display the Detail Page
'**********************************************************
Function DisplayDetailPage(list) As Dynamic
    if validateParam(list, "roArray", "DisplayDetailPage") = false return -1

    screen = CreateDetailPage(m.curParent.Title, "")
    ShowDetailPage(screen, list)

    return 0
End Function




Function GetItemCategories(items) As Dynamic

    categories = CreateObject("roArray", 10, true)

    For each dataItems in items
        

    End For

End Function


'**********************************************************
'** Get Library Items From Server
'**********************************************************

Function GetLibraryItems() As Object
    Print "current Parent Id "; m.curParent.Id
    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/Users/" + m.curUserProfile.Id + "/Items?ParentId=" + m.curParent.Id + "&SortBy=SortName&SortOrder=Ascending")

    if (request.AsyncGetToString())
        while (true)
            msg = wait(0, request.GetPort())

            if (type(msg) = "roUrlEvent")
                code = msg.GetResponseCode()

                if (code = 200)
                    itemList = CreateObject("roArray", 10, true)

                    'json = ParseJSON(msg.GetString())

                    ' Fixes bug within BRS Json Parser
                    regex = CreateObject("roRegex", Chr(34) + "RunTimeTicks" + Chr(34) + ":([0-9]+),", "i")
                    fixedString = regex.ReplaceAll(msg.GetString(), Chr(34) + "RunTimeTicks" + Chr(34) + ":" + Chr(34) + "\1" + Chr(34) + ",")

                    json = ParseJSON(fixedString)
                    for each itemObj in json.Items
                        itemData = {
                            ID: itemObj.Id
                            Title: itemObj.Name
                            ShortDescriptionLine1: itemObj.Name
                            ContentType: itemObj.Type
                            IsFolder: itemObj.IsFolder
                            Rating: itemObj.OfficialRating
                            StarRating: itemObj.CriticRating
                           ' PremiereDate: itemObj.PremiereDate
                           ' VideoType: itemObj.VideoType
                           ' CommunityRating: itemObj.CommunityRating
                        }

                        ' Check For Production Year
                        If Type(itemObj.ProductionYear) = "Integer" Then
                            itemData.ReleaseDate = Stri(itemObj.ProductionYear)
                        End if

                        ' Check For Run Time
                        itemRunTime = itemObj.RunTimeTicks
                        If itemRunTime<>"" And itemRunTime<>invalid
                            itemData.Length = Int(((itemRunTime).ToFloat() / 10000) / 1000)
                        End If
                        
                            'If itemObj.ImageTags.Thumb<>"" And itemObj.ImageTags.Thumb<>invalid
                            'itemData.HDPosterUrl = GetServerBaseUrl() + "/Items/" + itemObj.Id + "/Images/Primary/0?height=270&width=&tag=" + itemObj.ImageTags.Primary
                            'itemData.SDPosterUrl = GetServerBaseUrl() + "/Items/" + itemObj.Id + "/Images/Primary/0?height=150&width=&tag=" + itemObj.ImageTags.Primary
                            'itemData.HDPosterUrl = GetServerBaseUrl() + "/Items/" + itemObj.Id + "/Images/Thumb/0?height=150&width=&tag=" + itemObj.ImageTags.Thumb
                            'itemData.SDPosterUrl = GetServerBaseUrl() + "/Items/" + itemObj.Id + "/Images/Thumb/0?height=94&width=&tag=" + itemObj.ImageTags.Thumb

                        ' Check If Item has Image, otherwise use default
                        If itemObj.BackdropImageTags[0]<>"" And itemObj.BackdropImageTags[0]<>invalid
                            itemData.HDPosterUrl = GetServerBaseUrl() + "/Items/" + itemObj.Id + "/Images/Backdrop/0?height=150&width=&tag=" + itemObj.BackdropImageTags[0]
                            itemData.SDPosterUrl = GetServerBaseUrl() + "/Items/" + itemObj.Id + "/Images/Backdrop/0?height=94&width=&tag=" + itemObj.BackdropImageTags[0]
                        Else 
                            itemData.HDPosterUrl = "pkg://images/items/collection.png"
                            itemData.SDPosterUrl = "pkg://images/items/collection.png"
                        End If

                        itemList.push( itemData )
                    end For

                    return {
                        data: itemList
                        count: json.TotalRecordCount
                    }
                endif
            else if (event = invalid)
                request.AsyncCancel()
            endif
        end while
    endif

    return invalid
End Function
