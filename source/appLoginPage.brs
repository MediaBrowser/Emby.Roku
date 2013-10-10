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
    list = getAllUserProfiles()
    screen.SetContentList(list)

    ' Show Screen
    screen.Show()

    while true
        msg = wait(0, screen.GetMessagePort())

        if type(msg) = "roPosterScreenEvent" then
            if msg.isListItemSelected() Then
                userProfile = list[msg.GetIndex()]

                If userProfile.HasPassword=true
                    ' Check User Password
                    userPassed = ShowPasswordBox(userProfile.Id)

                    If userPassed=1 Then
                        m.curUserProfile = userProfile
                        RegWrite("userId", m.curUserProfile.Id)
                        result = true
                        exit while
                    Else If userPassed=2 Then
                        ShowPasswordFailed()
                    End If

                    'result = false
                Else
                    m.curUserProfile = userProfile
                    RegWrite("userId", m.curUserProfile.Id)
                    result = true
                    exit while
                End if
            else if msg.isScreenClosed() Then
                Debug("Close login screen")
                result = false
                exit while
            end if
        end If
    end while

    screen.Close()
    return result
End Function
