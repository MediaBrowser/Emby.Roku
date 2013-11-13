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

    ' Add Server Tile (eventually move this)
    switchServer = {
        Title: "Select Server"
        ContentType: "server"
        ShortDescriptionLine1: "Select Server"
        HDPosterUrl: "pkg://images/hd-switch-server.png",
        SDPosterUrl: "pkg://images/sd-switch-server.png"
    }

    profiles.Push( switchServer )

    ' Set Content
    screen.SetContent(profiles)

    ' Show Screen
    screen.Show()

    while true
        msg = wait(0, screen.Port)

        if type(msg) = "roPosterScreenEvent" then
            if msg.isListItemSelected() then
                selectedProfile = profiles[msg.GetIndex()]

                if selectedProfile.ContentType = "user"

                    if selectedProfile.HasPassword
                        ' Check User Password
                        userPassed = ShowPasswordBox(selectedProfile.Id)

                        if userPassed = 1
                            RegWrite("userId", selectedProfile.Id)
                            return 1

                        else if userPassed = 2
                            ShowPasswordFailed()

                        end if

                    else
                        RegWrite("userId", selectedProfile.Id)
                        return 1
                    end if

                else
                    return 2

                end if

            else if msg.isScreenClosed() then
                Debug("Close login screen")
                return 0
            end if
        end if
    end while

    return 0
End Function
