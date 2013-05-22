'*****************************************************************
'**  Media Browser Roku Client - Login Page
'*****************************************************************


'**********************************************************
'** Show Login Page
'**********************************************************

Function ShowLoginPage()

    ' Setup Screen
    port   = CreateObject("roMessagePort")
    screen = CreateObject("roPosterScreen")
    screen.SetMessagePort(port)

    screen.SetBreadcrumbText("", "")
    screen.SetListStyle("flat-category")

    ' Get Data
    list = GetUserProfiles()
    screen.SetContentList(list)

    ' Show Screen
    screen.Show()

    while true
        msg = wait(0, screen.GetMessagePort())

        if type(msg) = "roPosterScreenEvent" then
            if msg.isListItemSelected() Then
                userProfile = list[msg.GetIndex()]

                If userProfile.HasPassword=true
                    Print "Check password"
                    m.curUserProfile = userProfile
                    RegWrite("userId", m.curUserProfile.Id)
                    result = true
                    exit while
                Else
                    m.curUserProfile = userProfile
                    RegWrite("userId", m.curUserProfile.Id)
                    result = true
                    exit while
                End if
            else if msg.isScreenClosed() Then
                Print "Close login screen"
                result = false
                exit while
            end if
        end If
    end while

    screen.Close()
    return result
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


'**********************************************************
'** Get User Profile From Server
'**********************************************************

Function GetUserProfile(userId As String) As Object

    if validateParam(userId, "roString", "GetUserProfile") = false return -1

    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/Users/" + userId)

    if (request.AsyncGetToString())
        while (true)
            msg = wait(0, request.GetPort())

            if (type(msg) = "roUrlEvent")
                code = msg.GetResponseCode()

                if (code = 200)
                    userProfile = ParseJSON(msg.GetString())

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
                    return userData
                endif
            else if (event = invalid)
                request.AsyncCancel()
            endif
        end while
    endif

    return invalid
End Function
