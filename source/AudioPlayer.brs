'*****************************************************************
'**  Media Browser Roku Client - Audio Player
'*****************************************************************


Function CreateAudioPlayer(port=invalid) As Object

    ' Setup Player
    o = CreateObject("roAssociativeArray")

    ' If Port is not set, create a new one
    If port=invalid Or type(port)<>"roMessagePort" Then
        port = CreateObject("roMessagePort")
    End If

    audioPlayer = CreateObject("roAudioPlayer")
    audioPlayer.SetMessagePort(port)

    ' Setup Common Items
    o.audioPlayer    = audioPlayer
    o.Port           = port
    o.AddTrack       = AddAudioTrack
    o.AddPlaylist    = AddAudioPlaylist
    o.ClearContent   = ClearAudioContent
    o.Repeat         = RepeatAudio
    o.Play           = PlayAudio
    o.Stop           = StopAudio
    o.Pause          = PauseAudio
    o.Resume         = ResumeAudio
    o.PrevTrack      = PreviousAudioTrack
    o.NextTrack      = NextAudioTrack
	o.MessageHandler = AudioMessageHandler

    o.CurrentIndex   = invalid
    o.TrackCount     = 0

    o.IsPlaying      = false
    o.IsPaused       = false

    Return o
End Function

Function AddAudioTrack(songUrl As string, format as string)
    m.TrackCount = m.TrackCount + 1

	song = CreateObject("roAssociativeArray")
	song.Url = songUrl
	song.StreamFormat = format

	m.audioPlayer.AddContent(song)
End Function

Function AddAudioPlaylist(songs As Object)
    ' Add Each Song
    For each songData in songs
        m.AddTrack(songData.url, songData.format)
    End For
End Function

Function ClearAudioContent()
	m.audioPlayer.ClearContent()
End Function

Function RepeatAudio(repeat As Boolean)
	m.audioPlayer.SetLoop(repeat)
End Function

Function PlayAudio(track As Integer)
    m.IsPlaying = true

	m.audioPlayer.Stop()
    m.CurrentIndex = track
	m.audioPlayer.SetNext(track)
	m.audioPlayer.Play()
End Function

Function StopAudio()
    m.IsPlaying = false
	m.audioPlayer.Stop()
End Function

Function PauseAudio()
    m.IsPlaying = false
    m.IsPaused  = true
	m.audioPlayer.Pause()
End Function

Function ResumeAudio()
    m.IsPlaying = true
    m.IsPaused  = false
	m.audioPlayer.Resume()
End Function

Function PreviousAudioTrack()
    prevIndex = m.CurrentIndex - 1
    If prevIndex < 0 Then
        prevIndex = 0
    End If

	m.audioPlayer.Stop()
    m.CurrentIndex = prevIndex
	m.audioPlayer.SetNext(prevIndex)
	m.audioPlayer.Play()
End Function

Function NextAudioTrack()
    nextIndex = m.CurrentIndex + 1
    If nextIndex > m.TrackCount-1 Then
        Return 0
        'nextIndex = m.TrackCount-1
    End If

	m.audioPlayer.Stop()
    m.CurrentIndex = nextIndex
	m.audioPlayer.SetNext(nextIndex)
	m.audioPlayer.Play()
End Function



Function AudioMessageHandler(timeout as Integer, escape as String) As Object
	'print "In audioPlayer get selection - Waiting for msg escape=" ; escape
	while true
	    msg = wait(timeout, m.Port)
	    'print "Got msg = "; type(msg)
	    if type(msg) = "roAudioPlayerEvent" return msg
	    if type(msg) = escape return msg
	    if type(msg) = "Invalid" return msg
	    ' eat all other messages
	end while
End Function



Function SetupAudioStream(audioId As String, audioPath As String) As Object

    ' Get Extension
    extension = getFileExtension(audioPath)

	stream = CreateObject("roAssociativeArray")

    ' Direct Playback mp3 and wma
    If (extension = "mp3") 
        stream.url = GetServerBaseUrl() + "/Audio/" + audioId + "/stream.mp3?static=true"
        stream.format = "mp3"
    Else If (extension = "wma") 
        stream.url = GetServerBaseUrl() + "/Audio/" + audioId + "/stream.wma?static=true"
        stream.format = "wma"
    Else
        ' Transcode Play
        stream.url = GetServerBaseUrl() + "/Audio/" + audioId + "/stream.mp3"
        stream.format = "mp3"
    End If

    Return stream
End Function