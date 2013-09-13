'*****************************************************************
'**  Media Browser Roku Client - Music Genre Page
'*****************************************************************


'**********************************************************
'** Show Music Genre Page
'**********************************************************

Function ShowMusicGenrePage(genre As String) As Integer

    if validateParam(genre, "roString", "ShowMusicGenrePage") = false return -1

    ' Create Poster Screen
    screen = CreatePosterScreen("Music", genre, "arced-square")

    ' Initialize Music Metadata
    MusicMetadata = InitMusicMetadata()

    ' Get Default Data
    musicData = MusicMetadata.GetGenreAlbums(genre)

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
