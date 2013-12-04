'*****************************************************************
'**  Media Browser Roku Client - Music Album Page
'*****************************************************************


'**********************************************************
'** Show Music Album Page
'**********************************************************

Function ShowMusicAlbumPage(artistInfo As Object) As Integer

    ' Create Poster Screen
    screen = CreatePosterScreen("Music", artistInfo.Title, "arced-square")

    ' Initialize Music Metadata
    MusicMetadata = InitMusicMetadata()

    ' Get Default Data
    musicData = MusicMetadata.GetArtistAlbums(artistInfo.Title)

    if musicData = invalid
        createDialog("Problem Loading Music Albums", "There was an problem while attempting to get the list of music albums from the server.", "Back")
        return 0
    end if

    ' Set Content
    screen.Screen.SetContentList(musicData)

    ' Show Screen
    screen.Show()

    while true
        msg = wait(0, screen.Port)

        if type(msg) = "roPosterScreenEvent" Then
            If msg.isListFocused() Then

            Else If msg.isListItemSelected() Then
                selection = msg.GetIndex()
                ShowMusicSongPage(musicData[selection])

            Else If msg.isScreenClosed() then
                return -1
            End If
        end if
    end while

    return 0
End Function
