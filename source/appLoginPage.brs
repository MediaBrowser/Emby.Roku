'*****************************************************************
'**  Media Browser Roku Client - Login Page
'*****************************************************************


'**********************************************************
'** Show Login Page
'**********************************************************

Function ShowLoginPage()

    ' Create Poster Screen
    screen = CreatePosterScreen("", "Login", "flat-category")

    ' Get Data
    profiles = getAllUserProfiles()

    if profiles = invalid
        createDialog("Problem Loading", "There was an problem while attempting to get the list of user profiles from the server. Please make sure your server is running and try again.", "Exit")
        return false
    end if

    ' Set Content
    screen.SetContent(profiles)

    ' Show Screen
    screen.Show()

    while true
        msg = wait(0, screen.Port)

        if type(msg) = "roPosterScreenEvent" then
            if msg.isListItemSelected() then
                selectedProfile = profiles[msg.GetIndex()]

                if selectedProfile.HasPassword
                    ' Check User Password
                    userPassed = ShowPasswordBox(selectedProfile.Id)

                    if userPassed = 1
                        RegWrite("userId", selectedProfile.Id)
                        return true

                    else if userPassed = 2
                        ShowPasswordFailed()

                    end if

                else
                    RegWrite("userId", selectedProfile.Id)
                    return true
                end if

            else if msg.isScreenClosed() then
                Debug("Close login screen")
                return false
            end if
        end if
    end while

    return false
End Function
