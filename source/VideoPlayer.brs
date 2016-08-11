'*
'* A wrapper around a video player that implements our screen interface.
'*

'** Credit: Plex Roku https://github.com/plexinc/roku-client-public

'**********************************************************
'** getPlayConfiguration
'**********************************************************

Function getPlayConfiguration(context, contextIndex, playOptions) 

    list = []
	
	initialItem = context[contextIndex]
	initialItem.PlayOptions = playOptions
	
    if playOptions.PlayStart = 0 and playOptions.intros <> false

        intros = getVideoIntros(initialItem.Id)
		'intros = getLocalTrailers(initialItem.Id)
		
        if intros <> invalid
		
            for each i in intros.Items	
			'for each i in intros	

				i.PlayOptions = {}
				list.push(i)
            end for
			
        end if

    end if

	currentIndex = 0
	for each i in context	
		if currentIndex >= contextIndex then list.push(i)		
		currentIndex = currentIndex + 1
	end for
	
        if initialItem.partCount <> invalid and initialItem.partCount > 1 then
		additional = getAdditionalParts(initialItem.Id)

        	if additional <> invalid
		
			for each i in additional.Items		
				i.PlayOptions = {}
				list.push(i)
			end for
			
		end if
	end if
	
	return {
		Context: list
		CurIndex: 0
	}
	
End Function

Function createVideoPlayerScreen(context, contextIndex, playOptions, viewController)

	obj = CreateObject("roAssociativeArray")
    initBaseScreen(obj, viewController)

	playConfig = getPlayConfiguration(context, contextIndex, playOptions)
	
    obj.Context = playConfig.Context
    obj.CurIndex = playConfig.CurIndex

    obj.Show = videoPlayerShow
    obj.HandleMessage = videoPlayerHandleMessage
    obj.OnTimerExpired = videoPlayerOnTimerExpired

    obj.CreateVideoPlayer = videoPlayerCreateVideoPlayer

	obj.StartTranscodeSessionRequest = videoPlayerStartTranscodeSessionRequest
	obj.OnUrlEvent = videoPlayerOnUrlEvent

    obj.pingTimer = invalid
    obj.lastPosition = 0
	obj.isPlayed = false
    obj.playbackError = false
	obj.changeStream = false
    obj.underrunCount = 0
    obj.timelineTimer = invalid
    obj.progressTimer = invalid
    obj.playState = "buffering"
    obj.bufferingTimer = createTimer()
	obj.LastProgressReportTime = 0

    obj.ShowPlaybackError = videoPlayerShowPlaybackError
    obj.UpdateNowPlaying = videoPlayerUpdateNowPlaying

    obj.Pause = videoPlayerPause
    obj.Resume = videoPlayerResume
    obj.Next = videoPlayerNext
    obj.Prev = videoPlayerPrev
    obj.Stop = videoPlayerStop
    obj.Seek = videoPlayerSeek
	obj.SetAudioStreamIndex = videoPlayerSetAudioStreamIndex
	obj.SetSubtitleStreamIndex = videoPlayerSetSubtitleStreamIndex

	obj.ReportPlayback = videoPlayerReportPlayback

	obj.ConstructVideoItem = videoPlayerConstructVideoItem
	obj.StopTranscoding = videoPlayerStopTranscoding

    return obj
End Function

Function VideoPlayer()
    ' If the active screen is a slideshow, return it. Otherwise, invalid.
    screen = GetViewController().screens.Peek()
    if type(screen.Screen) = "roVideoScreen" then
        return screen
    else
        return invalid
    end if
End Function

Sub videoPlayerShow()
    ' We only fall back automatically if we originally tried to Direct Play
    ' and the preference allows fallback. One potential quirk is that we do
    ' fall back if there was progress on the Direct Play attempt. This should
    ' be quite uncommon, but if something happens part way through the file
    ' that the device can't handle, we at least give transcoding (from there)
    ' a shot.

    if m.playbackError then
	
        Debug("Error while playing video, nothing left to fall back to")
        m.ShowPlaybackError("")
        m.Screen = invalid
        m.popOnActivate = true

	else
		item = m.Context[m.CurIndex]
		if item.PlayOptions <> invalid
			m.PlayOptions = item.PlayOptions
			if m.PlayOptions = invalid
				m.PlayOptions = {}
			end if
		else
			m.PlayOptions = {}
		end if
		m.Screen = m.CreateVideoPlayer(item, m.PlayOptions)
    end if

	m.changeStream = false
	
    if m.Screen <> invalid then
	
        if m.IsTranscoded then
            Debug("Starting to play transcoded video")
        else
            Debug("Starting to direct play video")
        end if
		
		Debug("Playback url: " + m.VideoItem.Stream.Url)

        m.timelineTimer = createTimer()
        m.timelineTimer.Name = "timeline"
        m.timelineTimer.SetDuration(15000, true)
        m.ViewController.AddTimer(m.timelineTimer, m)

        m.progressTimer = createTimer()
        m.progressTimer.Name = "progress"
        m.progressTimer.SetDuration(2000, true)
		m.progressTimer.Active = false
        m.ViewController.AddTimer(m.progressTimer, m)
		
        m.Screen.Show()
        NowPlayingManager().location = "fullScreenVideo"
    else
        m.ViewController.PopScreen(m)
        NowPlayingManager().location = "navigation"
    end if
End Sub

Function videoPlayerCreateVideoPlayer(item, playOptions)

    Debug("MediaPlayer::playVideo: Displaying video: " + tostr(item.title))

	if item.IsPlaceHolder = true then
		m.ShowPlaybackError("PlaceHolder")
		return invalid
	end if
	
    videoItem = m.ConstructVideoItem(item, playOptions)

	if videoItem = invalid or videoItem.Stream = invalid then
		return invalid
	end if

    player = CreateObject("roVideoScreen")
    player.SetMessagePort(m.Port)

    player.SetPositionNotificationPeriod(1)

	' Reset these
	m.isPlayed = false
    m.lastPosition = 0
    m.playbackError = false
	m.changeStream = false
    m.underrunCount = 0
    m.timelineTimer = invalid
    m.progressTimer = invalid
    m.playState = "buffering"
    
	m.IsTranscoded = videoItem.StreamInfo.PlayMethod = "Transcode"
    m.videoItem = videoItem

	if m.IsTranscoded then
		m.playMethod = "Transcode"	
	else
		m.playMethod = "DirectStream"
	end if

	addBifInfo(videoItem)
	
	m.canSeek = videoItem.StreamInfo.CanSeek
	
	Debug ("Setting PlayStart to " + tostr(playOptions.PlayStart))
	videoItem.PlayStart = playOptions.PlayStart

	if Instr(0, videoItem.Stream.Url, "https:") <> 0 then 
		player.setCertificatesFile("common:/certs/ca-bundle.crt")
	end if
	
	player.SetContent(videoItem)

	versionArr = getGlobalVar("rokuVersion")
	
    if CheckMinimumVersion(versionArr, [4, 9]) AND videoItem.SubtitleUrl <> invalid then
        player.ShowSubtitle(true)
    end if
	
	return player
End Function

Sub addBifInfo(item)
	
	itemId = item.Id
	mediaSourceId = item.StreamInfo.MediaSource.Id
	
	if IsBifServiceAvailable(item) = true then
		item.HDBifUrl = GetServerBaseUrl() + "/Videos/" + itemId + "/index.bif?width=320&mediaSourceId=" + mediaSourceId
		item.SDBifUrl = GetServerBaseUrl() + "/Videos/" + itemId + "/index.bif?width=240&mediaSourceId=" + mediaSourceId
	end if
		
End Sub

Function IsBifServiceAvailable(item)

	if item.ServerId = invalid then
		return false
	end if
	
	viewController = GetViewController()
	
	if viewController.serverPlugins = invalid then
		viewController.serverPlugins = CreateObject("roAssociativeArray")
	end if
	
	if viewController.serverPlugins[item.ServerId] = invalid then
		viewController.serverPlugins[item.ServerId] = getInstalledPlugins()
	end if
	
	for each serverPlugin in viewController.serverPlugins[item.ServerId]
		if serverPlugin.Name = "Roku Thumbnails" then
			return true
		end if
	end for
	
	return false
	
End Function

Sub videoPlayerShowPlaybackError(code)
    dialog = createBaseDialog()

    dialog.Title = "Video Unavailable"
	
	if code = "PlaceHolder" then
		dialog.Text = "The content chosen is not playable from this device."
	else
		dialog.Text = "We're unable to play this video, make sure the server is running and has access to this video."
	end if
	
    dialog.Show()
End Sub

Function videoPlayerHandleMessage(msg) As Boolean

    handled = false

    if type(msg) = "roVideoScreenEvent" then

        handled = true

        if msg.isScreenClosed() then

            m.timelineTimer.Active = false
            m.progressTimer.Active = false
            m.playState = "stopped"
            Debug("MediaPlayer::playVideo::VideoScreenEvent::isScreenClosed: position -> " + tostr(m.lastPosition))
            NowPlayingManager().location = "navigation"

			m.ReportPlayback("stop")
            m.UpdateNowPlaying()

            if m.isPlayed = true AND m.Context.Count() > (m.CurIndex + 1) then
				m.CurIndex = m.CurIndex + 1
                m.Show()
            else if m.changeStream
				m.changeStream = false
                m.Show()
            else
                m.ViewController.PopScreen(m)
            end if

        else if msg.isStatusMessage() then
            print "Video status: "; msg.GetIndex(); " " msg.GetData()

        else if msg.isButtonPressed()
            print "Button pressed: "; msg.GetIndex(); " " msg.GetData()

        else if msg.isStreamStarted() then
            Debug("MediaPlayer::playVideo::VideoScreenEvent::isStreamStarted: position -> " + tostr(m.lastPosition))
            Debug("Message data -> " + tostr(msg.GetInfo()))

            if msg.GetInfo().IsUnderrun = true then
                m.underrunCount = m.underrunCount + 1
                if m.underrunCount = 4 then
                    Debug ("Video is underrun")
                end if
            end if

			m.ReportPlayback("start")

			m.StartTranscodeSessionRequest()

        else if msg.isPlaybackPosition() then

            if m.bufferingTimer <> invalid then
                m.bufferingTimer = invalid
            end if

            m.lastPosition = msg.GetIndex()

            Debug("MediaPlayer::playVideo::VideoScreenEvent::isPlaybackPosition: set progress -> " + tostr(m.lastPosition))

            m.playState = "playing"
			m.progressTimer.Active = true
			m.ReportPlayback("progress")
            m.UpdateNowPlaying(true)

        else if msg.isRequestFailed() then
            Debug("MediaPlayer::playVideo::VideoScreenEvent::isRequestFailed - message = " + tostr(msg.GetMessage()))
            Debug("MediaPlayer::playVideo::VideoScreenEvent::isRequestFailed - data = " + tostr(msg.GetData()))
            Debug("MediaPlayer::playVideo::VideoScreenEvent::isRequestFailed - index = " + tostr(msg.GetIndex()))
            m.playbackError = true

        else if msg.isPaused() then
            Debug("MediaPlayer::playVideo::VideoScreenEvent::isPaused: position -> " + tostr(m.lastPosition))
            m.playState = "paused"
			m.progressTimer.Active = true
			m.ReportPlayback("progress", true)
            m.UpdateNowPlaying("progress")

        else if msg.isResumed() then
            Debug("MediaPlayer::playVideo::VideoScreenEvent::isResumed")
            m.playState = "playing"
			m.progressTimer.Active = true
			m.ReportPlayback("progress", true)
            m.UpdateNowPlaying()

        else if msg.isPartialResult() then
		
            Debug("MediaPlayer::playVideo::VideoScreenEvent::isPartialResult: position -> " + tostr(m.lastPosition))
			
			m.progressTimer.Active = false
			
			if m.changeStream = false then 
				m.playState = "stopped"
				m.ReportPlayback("stop")
				m.UpdateNowPlaying()
			else
				if m.IsTranscoded then m.StopTranscoding()
			end if

        else if msg.isStreamSegmentInfo() then
            Debug("HLS Segment info: " + tostr(msg.GetType()) + " msg: " + tostr(msg.GetMessage()))

        else if msg.isFullResult() then
            Debug("MediaPlayer::playVideo::VideoScreenEvent::isFullResult: position -> " + tostr(m.lastPosition))
            m.progressTimer.Active = false
			m.playState = "stopped"
			m.ReportPlayback("stop")
            m.UpdateNowPlaying()
			m.isPlayed = true

        else if msg.GetType() = 31 then
            ' TODO(schuyler): DownloadDuration is completely incomprehensible to me.
            ' It doesn't seem like it could be seconds or milliseconds, and I couldn't
            ' seem to do anything to artificially affect it by tweaking PMS.
            segInfo = msg.GetInfo()
            Debug("Downloaded segment " + tostr(segInfo.Sequence) + " in " + tostr(segInfo.DownloadDuration) + "?s (" + tostr(segInfo.SegSize) + " bytes, buffer is now " + tostr(segInfo.BufferLevel) + "/" + tostr(segInfo.BufferSize))

        else if msg.GetType() = 27 then
            ' This is an HLS Segment Info event. We don't really need to do
            ' anything with it. It includes info like the stream bandwidth,
            ' sequence, URL, and start time.
			Debug("HLS Segment info: " + tostr(msg.GetType()) + " msg: " + tostr(msg.GetMessage()))
        else
            'Debug("Unknown event: " + tostr(msg.GetType()) + " msg: " + tostr(msg.GetMessage()))
        end if
    end if

    return handled
End Function

Sub videoPlayerReportPlayback(action as String, forceReport = false)

	m.progressTimer.Mark()

	isPaused = false

	if m.playState = "paused" then 
		isPaused = true
	end if
	
	position = m.lastPosition
	playOptions = m.PlayOptions	
	
	nowSeconds = CreateObject("roDateTime").AsSeconds()
	
	if action = "progress" and forceReport = false then
		secondsSinceLastProgressReport = nowSeconds - m.LastProgressReportTime
		
		if secondsSinceLastProgressReport < 3
			Debug ("Skipping progress report")
			return
		end if
		
	end if

	m.LastProgressReportTime = nowSeconds
	reportPlayback(m.videoItem.Id, "Video", action, m.playMethod, isPaused, m.canSeek, position, m.videoItem.StreamInfo.MediaSource.Id, m.videoItem.StreamInfo.PlaySessionId, m.videoItem.StreamInfo.LiveStreamId, m.videoItem.StreamInfo.AudioStreamIndex, m.videoItem.StreamInfo.SubtitleStreamIndex)
	
End Sub

Sub videoPlayerPause()
    if m.Screen <> invalid then
        m.Screen.Pause()
    end if
End Sub

Sub videoPlayerResume()
    if m.Screen <> invalid then
        m.Screen.Resume()
    end if
End Sub

Sub videoPlayerNext()
End Sub

Sub videoPlayerPrev()
End Sub

Sub videoPlayerSetAudioStreamIndex(index)
    if m.Screen <> invalid then
        
		item = m.Context[m.CurIndex]
		item.PlayOptions.AudioStreamIndex = index
		
		position = m.lastPosition
		playOptions = m.PlayOptions	

		item.PlayOptions.PlayStart = position
		
		m.changeStream = true
        m.Screen.Close()
    end if
End Sub

Sub videoPlayerSetSubtitleStreamIndex(index)
    if m.Screen <> invalid then
	
		item = m.Context[m.CurIndex]
		item.PlayOptions.SubtitleStreamIndex = index
		
		position = m.lastPosition
		playOptions = m.PlayOptions	

		item.PlayOptions.PlayStart = position
		
		m.changeStream = true
        m.Screen.Close()
    end if
End Sub

Sub videoPlayerStop()
    if m.Screen <> invalid then
        m.Screen.Close()
    end if
End Sub

Sub videoPlayerSeek(offset, relative=false)

    if m.Screen <> invalid then

        if relative then
            offset = offset + (1000 * m.lastPosition)
            if offset < 0 then offset = 0
        end if

        if m.playState = "paused" then
            m.Screen.Resume()
            m.Screen.Seek(offset)
        else
            m.Screen.Seek(offset)
        end if
    end if

End Sub

Sub videoPlayerStartTranscodeSessionRequest()

    if m.IsTranscoded then

        context = CreateObject("roAssociativeArray")
        context.requestType = "transcode"

		request = HttpRequest(GetServerBaseUrl() + "/Sessions?deviceId=" + getGlobalVar("rokuUniqueId", "Unknown"))
		request.AddAuthorization()
		request.ContentType("json")

		m.ViewController.StartRequest(request.Http, m, context)

    end if

End Sub

Sub videoPlayerOnUrlEvent(msg, requestContext)

    if requestContext.requestType = "transcode" then
        if msg.GetResponseCode() = 200 then

			response = normalizeJson(msg.GetString())

			sessions     = ParseJSON(response)

			DisplayTranscodingInfo(m.Screen, m.videoItem, sessions)
		end if
    end if

End Sub

Sub DisplayTranscodingInfo(screen, item, sessions)

	for each i in sessions
		
		if i.TranscodingInfo <> invalid then

			transcodingInfo = i.TranscodingInfo

			item.ReleaseDate = item.OrigReleaseDate + "   Transcoded"

			if transcodingInfo.Width <> invalid or transcodingInfo.Height <> invalid or transcodingInfo.AudioChannels <> invalid then

				item.ReleaseDate = item.ReleaseDate + " ("

				if transcodingInfo.Width <> invalid and transcodingInfo.Height <> invalid then  item.ReleaseDate = item.ReleaseDate + tostr(transcodingInfo.Width) + "x" + tostr(transcodingInfo.Height)
				if transcodingInfo.AudioChannels <> invalid then item.ReleaseDate = item.ReleaseDate + " " + tostr(transcodingInfo.AudioChannels) + "ch"
				item.ReleaseDate = item.ReleaseDate + ")"
			end if

			item.ReleaseDate = item.ReleaseDate + chr(10)

			item.length = tostr(item.Length)

			if transcodingInfo.VideoCodec <> invalid then item.ReleaseDate = item.ReleaseDate + "    video: " + tostr(transcodingInfo.VideoCodec)
			if transcodingInfo.AudioCodec <> invalid then item.ReleaseDate = item.ReleaseDate + "    audio: " + tostr(transcodingInfo.AudioCodec)

			screen.SetContent(item)

			exit for
		end if

	end for

End Sub

Sub videoPlayerOnTimerExpired(timer)
    
	if timer.Name = "timeline"
        m.UpdateNowPlaying(true)
    else if timer.Name = "progress"
        m.ReportPlayback("progress")
    end if

End Sub

Sub videoPlayerUpdateNowPlaying(force=false)

    ' Avoid duplicates
    if m.playState = m.lastTimelineState AND NOT force then return

    m.lastTimelineState = m.playState
    m.timelineTimer.Mark()

	item = m.Context[m.CurIndex]
	
    NowPlayingManager().UpdatePlaybackState("video", item, m.playState, m.lastPosition)
End Sub

Function videoPlayerConstructVideoItem(item, options) as Object

	item = GetFullItemMetadata(item, true, options)

    'if mediaItem <> invalid then videoItem.Duration = mediaItem.duration ' set duration - used for EndTime/TimeLeft on HUD  - ljunkie

    if item.ReleaseDate = invalid then  item.ReleaseDate = "" ' we never want to display invalid
    item.OrigReleaseDate = item.ReleaseDate

	releaseDate = item.ReleaseDate
	serverStreamInfo = item.StreamInfo

	if serverStreamInfo.PlayMethod <> "Transcode" then

       audioCh = ""
	   audioStream = serverStreamInfo.AudioStream

       if audioStream <> invalid and audioStream.Channels <> invalid then
           if (audioStream.Channels = 6) then
               audioCh = "5.1"
           else
              audioCh = tostr(audioStream.Channels) + "ch"
           end if
       end if

	   audioCodec = ""

	   if audioStream <> invalid then
		   if (tostr(audioStream.Codec) = "dca") then
       			audioCodec = "DTS"
		   else
       			audioCodec = tostr(audioStream.Codec)
		   end if
	   end if

	   resolution = ""
	   ' Change the VideoStream.Width to Height, shows 1920p instead of 1080p and 1280p instead of 720p in Direct Play Info
	   if serverStreamInfo.VideoStream <> invalid and serverStreamInfo.VideoStream.Height <> invalid then resolution = tostr(serverStreamInfo.VideoStream.Height) + "p "

        item.ReleaseDate = releaseDate + "   Direct Play (" + resolution + audioCh + " " + audioCodec + " " + tostr(item.StreamFormat) + ")"
	else

        item.ReleaseDate = releaseDate + "   Transcoded"
	end if

	return item

End Function

Sub videoPlayerStopTranscoding()

	Debug ("Sending message to server to stop transcoding")

    ' URL
    url = GetServerBaseUrl() + "/Videos/ActiveEncodings"

    ' Prepare Request
    request = HttpRequest(url)
    request.AddAuthorization()
    request.AddParam("DeviceId", getGlobalVar("rokuUniqueId", "Unknown"))
    request.SetRequest("DELETE")

    ' Execute Request
    response = request.PostFromStringWithTimeout("", 5)

    if response = invalid
        Debug("Error stopping server transcoding")
    end if

End Sub
