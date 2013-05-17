'*****************************************************************
'**  Media Browser Roku Client - Home Page
'*****************************************************************

'**********************************************************
'** Create Home Page
'**********************************************************

Function CreateHomePage(breadA=invalid, breadB=invalid) As Object

    if validateParam(breadA, "roString", "CreateHomePage", true) = false return -1
    if validateParam(breadA, "roString", "CreateHomePage", true) = false return -1

    port   = CreateObject("roMessagePort")
    screen = CreateObject("roPosterScreen")
    screen.SetMessagePort(port)
    if breadA<>invalid and breadB<>invalid then
        screen.SetBreadcrumbText(breadA, breadB)
    end if

    screen.SetListStyle("flat-category")
    return screen
End Function


'**********************************************************
'** Show Home Page
'**********************************************************

Function ShowHomePage(screen As Object) As Integer

    if validateParam(screen, "roPosterScreen", "ShowHomePage") = false return -1

    list = GetLibraryCollections()
    screen.SetContentList(list)
    screen.Show()

    while true
        msg = wait(0, screen.GetMessagePort())

        if type(msg) = "roPosterScreenEvent" Then
            if msg.isListFocused() then
                print "list focused | index = "; msg.GetIndex(); " | category = "; 'm.curCategory
            else if msg.isListItemSelected() then
                m.curCollection = list[msg.GetIndex()]
                DisplayListPage()
            else if msg.isScreenClosed() then
                return -1
            end if
        end if
    end while

    return 0
End Function


'**********************************************************
'** Create And Display the List Page
'**********************************************************

Function DisplayListPage() As Dynamic
    screen = CreateListPage("", m.curCollection.Title)
    ShowListPage(screen)

    return 0
End Function


'**********************************************************
'** Get Library Collections From Server
'**********************************************************
Function GetLibraryCollections() As Object
    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/Users/" + m.curUserProfile.Id + "/Items")

    if (request.AsyncGetToString())
        while (true)
            msg = wait(0, request.GetPort())

            if (type(msg) = "roUrlEvent")
                code = msg.GetResponseCode()

                if (code = 200)
                    collectionList = CreateObject("roArray", 10, true)
                    json = ParseJSON(msg.GetString())
                    for each collection in json.Items
                        collectionData = {
                            ID: collection.Id
                            Title: collection.Name
                            ShortDescriptionLine1: collection.Name
                            IsFolder: collection.IsFolder
                            CollectionType: collection.Type
                        }

                        ' Check If Collection has Image, otherwise use default
                        If collection.ImageTags.Primary<>"" And collection.ImageTags.Primary<>invalid
                            collectionData.HDPosterUrl = GetServerBaseUrl() + "/Items/" + collection.Id + "/Images/Primary/0?height=300&width=&tag=" + collection.ImageTags.Primary
                            collectionData.SDPosterUrl = GetServerBaseUrl() + "/Items/" + collection.Id + "/Images/Primary/0?height=300&width=&tag=" + collection.ImageTags.Primary
                        Else 
                            collectionData.HDPosterUrl = "pkg://images/items/collection.png"
                            collectionData.SDPosterUrl = "pkg://images/items/collection.png"
                        End If

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
