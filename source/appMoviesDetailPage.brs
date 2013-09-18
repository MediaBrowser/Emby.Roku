'*****************************************************************
'**  Media Browser Roku Client - Movies Detail Page
'*****************************************************************


'**********************************************************
'** Show Movies Details Page
'**********************************************************

Function ShowMoviesDetailPage(movieId As String, movieList=invalid, movieIndex=invalid) As Integer

    if validateParam(movieId, "roString", "ShowMoviesDetailPage") = false return -1

    ' Handle Direct Access from Home
    If movieIndex=invalid Then
        movieIndex = 0
    End If
    
    ' Setup Screen
    port   = CreateObject("roMessagePort")
    screen = CreateObject("roSpringboardScreen")
    screen.SetMessagePort(port)

    screen.SetBreadcrumbText("", "Movies")
    screen.SetDescriptionStyle("movie")
    screen.SetStaticRatingEnabled(false)

    ' Fetch / Refresh Screen Details
    moviesDetails = RefreshMoviesDetailPage(screen, movieId)

    ' Remote key id's for left/right navigation
    remoteKeyLeft  = 4
    remoteKeyRight = 5
 
    while true
        msg = wait(0, screen.GetMessagePort())

        if type(msg) = "roSpringboardScreenEvent" then
            If msg.isRemoteKeyPressed() 
                ' Only allow left/right navigation if movieList provided
                If movieList<>invalid Then
                    'If msg.GetIndex() = remoteKeyLeft Then
                    '    movieIndex = getPreviousMovie(movieList.Items, movieIndex)

                    '    If movieIndex <> -1
                    '        movieId = movieList.Items[movieIndex].Id
                    '        moviesDetails = RefreshMoviesDetailPage(screen, movieId)
                    '    End If
                    'Else If msg.GetIndex() = remoteKeyRight
                    '    movieIndex = getNextMovie(movieList.Items, movieIndex)

                    '    If movieIndex <> -1
                    '        movieId = movieList.Items[movieIndex].Id
                    '        moviesDetails = RefreshMoviesDetailPage(screen, movieId)
                    '    End If
                    'End If
                End If
            Else If msg.isButtonPressed()
                Debug("ButtonPressed")
                If msg.GetIndex() = 1
                    ' Set Saved Play Status
                    If moviesDetails.PlaybackPosition<>"" And moviesDetails.PlaybackPosition<>"0"  Then
                        if(moviesDetails.PlaybackPosition).ToFloat() > 0 then
                            PlayStart = (moviesDetails.PlaybackPosition).ToFloat()

                            ' Only update URLs if not direct play
                            If Not moviesDetails.IsDirectPlay Then
                                ' Update URLs for Resume
                                moviesDetails.StreamData = AddResumeOffset(moviesDetails.StreamData, moviesDetails.PlaybackPosition)
                            End If
                        else
                            PlayStart = 0
                        end if
                    Else
                        PlayStart = 0
                    End If

                    showVideoScreen(moviesDetails, PlayStart)
                    moviesDetails = RefreshMoviesDetailPage(screen, movieId)
                End If
                If msg.GetIndex() = 2
                    ' Show Error Dialog For Unsupported video types - Should be temporary call
                    If moviesDetails.DoesExist("StreamData")=false
                        ShowDialog("Playback Error", "That video type is not playable yet.", "Back")
                    Else
                        PlayStart = 0
                        showVideoScreen(moviesDetails, PlayStart)
                        moviesDetails = RefreshMoviesDetailPage(screen, movieId)
                    End If
                End If
                If msg.GetIndex() = 3
                    ShowMoviesChaptersPage(moviesDetails)
                    moviesDetails = RefreshMoviesDetailPage(screen, movieId)
                End If
            Else If msg.isScreenClosed()
                Debug("Screen closed")
                Exit While
            End If
        Else
            Debug("Unexpected message class: " + type(msg))
        End If
    end while

    return movieIndex
End Function


'**************************************************************
'** Refresh the Contents of the Movies Detail Page
'**************************************************************

Function RefreshMoviesDetailPage(screen As Object, movieId As String) As Object

    if validateParam(screen, "roSpringboardScreen", "RefreshMoviesDetailPage") = false return -1
    if validateParam(movieId, "roString", "RefreshMoviesDetailPage") = false return -1

    ' Initialize Movie Metadata
    MovieMetadata = InitMovieMetadata()

    ' Get Data
    moviesDetails = MovieMetadata.GetMovieDetails(movieId)

    ' Setup Buttons
    screen.ClearButtons()

    If moviesDetails.PlaybackPosition<>"" And moviesDetails.PlaybackPosition<>"0" Then
        screen.AddButton(1, "Resume playing")
        screen.AddButton(2, "Play from beginning")
    Else
        screen.AddButton(2, "Play")
    End If

    screen.AddButton(3, "View Chapters")

    ' Show Screen
    screen.SetContent(moviesDetails)
    screen.Show()

    Return moviesDetails
End Function


'**********************************************************
'** Get Next Movie from List
'**********************************************************

Function getNextMovie(movieList As Object, movieIndex As Integer) As Integer

    if validateParam(movieList, "roArray", "getNextMovie") = false return -1

    nextIndex = movieIndex + 1
    if nextIndex >= movieList.Count() Or nextIndex < 0 then
       nextIndex = 0 
    end if

    movie = movieList[nextIndex]

    if validateParam(movie, "roAssociativeArray", "getNextMovie") = false return -1 
    if movie.Id = invalid return -1

    return nextIndex

End Function


'**********************************************************
'** Get Previous Movie from List
'**********************************************************

Function getPreviousMovie(movieList As Object, movieIndex As Integer) As Integer

    if validateParam(movieList, "roArray", "getPreviousMovie") = false return -1 

    prevIndex = movieIndex - 1
    if prevIndex < 0 or prevIndex >= movieList.Count() then
        if movieList.Count() > 0 then
            prevIndex = movieList.Count() - 1 
        else
            return -1
        end if
    end if

    movie = movieList[prevIndex]

    if validateParam(movie, "roAssociativeArray", "getPreviousMovie") = false return -1 
    if movie.Id = invalid return -1

    return prevIndex

End Function
