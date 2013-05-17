'*****************************************************************
'**  Media Browser Roku Client - Login Page
'*****************************************************************

'**********************************************************
'** Create Login Page
'**********************************************************

Function CreateLoginPage(breadA=invalid, breadB=invalid) As Object

    if validateParam(breadA, "roString", "CreateLoginPage", true) = false return -1
    if validateParam(breadA, "roString", "CreateLoginPage", true) = false return -1

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
'** Show Login Page
'**********************************************************

Function ShowLoginPage(screen As Object) As Integer

    if validateParam(screen, "roPosterScreen", "ShowLoginPage") = false return -1

    list = GetUserProfiles()
    screen.SetContentList(list)
    screen.Show()

    while true
        msg = wait(0, screen.GetMessagePort())

        if type(msg) = "roPosterScreenEvent" then
            if msg.isListFocused() then
                print "list focused | index = "; msg.GetIndex(); " | category = "; 'm.curCategory
            else if msg.isListItemSelected() then
                m.curUserProfile = list[msg.GetIndex()]
                If m.curUserProfile.HasPassword=true
                    Print "Check password"
                End if
                DisplayHomePage()
            else if msg.isScreenClosed() then
                return -1
            end if
        end If
    end while

    return 0
End Function

'**********************************************************
'** Create And Display the Home page
'**********************************************************

Function DisplayHomePage() As Dynamic
    screen = CreateHomePage(m.curUserProfile.Title, "")
    ShowHomePage(screen)

    return 0
End Function


'**********************************************************
'** Get List of User Profiles From Server
'**********************************************************

Function GetUserProfiles() As Object
    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/Users")

    if (request.AsyncGetToString())
        while (true)
            msg = wait(0, request.GetPort())

            if (type(msg) = "roUrlEvent")
                code = msg.GetResponseCode()

                if (code = 200)
                    userList = CreateObject("roArray", 10, true)
                    json = ParseJSON(msg.GetString())
                    for each userProfile in json
                        userData = {
                            Id: userProfile.Id
                            Title: userProfile.Name
                            ShortDescriptionLine1: userProfile.Name
                            HasPassword: userProfile.HasPassword
                        }

                        ' Check If Profile has Image, otherwise use default
                        If userProfile.PrimaryImageTag<>"" And userProfile.PrimaryImageTag<>invalid
                            userData.HDPosterUrl = GetServerBaseUrl() + "/Users/" + userProfile.Id + "/Images/Primary/0?height=200&width=&tag=" + userProfile.PrimaryImageTag
                            userData.SDPosterUrl = GetServerBaseUrl() + "/Users/" + userProfile.Id + "/Images/Primary/0?height=200&width=&tag=" + userProfile.PrimaryImageTag
                        Else 
                            userData.HDPosterUrl = "pkg://images/userdefault.png"
                            userData.SDPosterUrl = "pkg://images/userdefault.png"
                        End If
                        
                        userList.push( userData )
                    end for
                    return userList
                endif
            else if (event = invalid)
                request.AsyncCancel()
            endif
        end while
    endif

    return invalid
End Function
