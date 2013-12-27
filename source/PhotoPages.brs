'*****************************************************************
'**  Media Browser Roku Client - Photo Pages
'*****************************************************************


'**********************************************************
'** Show Photo Page
'**********************************************************

Function ShowPhotoPage(photoId As String, parentId As String) As Boolean

    ' Create Facade Screen
    facade = CreateObject("roPosterScreen")
    facade.Show()

    ' Create Slideshow Screen
    screen = CreateSlideshowScreen()

    ' Get Data
    photos = getPhotosInFolder(parentId,  photoId)

    ' Check to make sure Data iv valid
    if photos = invalid
        createDialog("Problem Loading Photos", "There was an problem while attempting to get the photos from server. Please make sure your server is running and try again.", "Back")
        return 0
    end if

    ' Set Content
    screen.SetContentList(photos.Items) 

    ' Set current photo to be shown
    screen.SetNext(photos.SelectedIndex, true)

    ' Show Screen
    screen.Show() 

    ' Close Facade Screen
    facade.Close()

    while true
        msg = wait(0, screen.Port)

        if type(msg) = "roSlideShowEvent"

            if msg.isButtonPressed()

            else if msg.isScreenClosed()
                Debug("Close Photo Screen")
                return false
            end if

        end if
    end while

    return false
End Function
