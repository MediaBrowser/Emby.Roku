'*****************************************************************
'**  Media Browser Roku Client - Video Metadata
'*****************************************************************


'**********************************************************
'** Get Video Details
'**********************************************************

Function getVideoMetadata(videoId As String) As Object
    ' Validate Parameter
    if validateParam(videoId, "roString", "videometadata_details") = false return invalid

    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items/" + HttpEncode(videoId)

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

        fixedResponse = normalizeJson(response)

        i = ParseJSON(fixedResponse)

        ' Get Image Sizes
        if i.Type = "Episode"
            imageStyle = "rounded-rect-16x9-generic"
        else
            imageStyle = "movie"
        end if

		return getMetadataFromServerItem(i, 0, imageStyle, "springboard")
    else
        Debug("Failed to Get Video Metadata")
    end if

    return invalid
End Function

'**********************************************************
'** addVideoDisplayInfo
'**********************************************************

Sub addVideoDisplayInfo(metaData as Object, item as Object)

	mediaStreams = invalid

	if item.MediaSources <> invalid and item.MediaSources.Count() > 0 then
		mediaStreams = item.MediaSources[0].MediaStreams
	end if

	if mediaStreams = invalid then mediaStreams = item.MediaStreams

	' Can't continue at this point
	if mediaStreams = invalid then return

    foundVideo             = false

    for each stream in mediaStreams

        if stream.Type = "Video" And foundVideo = false
            foundVideo = true

            ' Determine Full 1080p
            if stream.Height >= 1080
                metaData.FullHD = true
            end if

            ' Determine Frame Rate
            if stream.RealFrameRate <> invalid
                if stream.RealFrameRate >= 29
                    metaData.FrameRate = 30
                else
                    metaData.FrameRate = 24
                end if

            else if stream.AverageFrameRate <> invalid
                if stream.RealFrameRate >= 29
                    metaData.FrameRate = 30
                else
                    metaData.FrameRate = 24
                end if

            end if

        else if stream.Type = "Audio" 

            channels = firstOf(stream.Channels, 2)
            if channels > 5
                metaData.AudioFormat = "dolby-digital"
            end if

        end if

    end for

End Sub

'**********************************************************
'** addVideoPlaybackInfo
'**********************************************************

Sub addVideoPlaybackInfo(item, options)

	streamInfo = getPlaybackStreamInfo(item, options) 

	if streamInfo = invalid then return

	item.StreamInfo = streamInfo

	' Setup Roku Stream
	' http://sdkdocs.roku.com/display/sdkdoc/Content+Meta-Data

	mediaSource = streamInfo.MediaSource
	mediaSourceId = mediaSource.Id
	
	isDisplayHd = getGlobalVar("displayType") = "HDTV"
	
	enableSelectableSubtitleTracks = true

	if streamInfo.IsDirectStream Then

		item.Stream = {
			url: GetServerBaseUrl() + "/Videos/" + item.Id + "/stream?static=true&mediaSourceId=" + mediaSourceId,
			contentid: "x-directstream",
			bitrate: streamInfo.Bitrate / 1000,
			quality: false
		}

		' http://sdkdocs.roku.com/display/sdkdoc/Content+Meta-Data
		if mediaSource.Container = "mov" or mediaSource.Container = "m4v" then
			item.StreamFormat = "mp4"
		else
			item.StreamFormat = mediaSource.Container
		end if
		
		'item.HDBifUrl = GetServerBaseUrl() + "/Videos/" + item.Id + "/index.bif?maxWidth=320&mediaSourceId=" + mediaSourceId
		'item.SDBifUrl = GetServerBaseUrl() + "/Videos/" + item.Id + "/index.bif?maxWidth=240&mediaSourceId=" + mediaSourceId
		
	else

		url = GetServerBaseUrl() + "/Videos/" + item.Id + "/master.m3u8?mediaSourceId=" + mediaSourceId

		if isDisplayHd then
			url = url + "&maxWidth=1920"
			url = url + "&maxHeight=1080"
		else		
			url = url + "&maxWidth=1280"
			url = url + "&maxHeight=720"
		end if
		
		url = url + "&videoCodec=h264"
		url = url + "&profile=high"
		url = url + "&level=41"
		url = url + "&deviceId=" + getGlobalVar("rokuUniqueId", "Unknown")

		url = url + "&AudioCodec=" + streamInfo.AudioCodec
		url = url + "&MaxAudioChannels=" + tostr(streamInfo.MaxAudioChannels)

		if options.PlayStart <> invalid then
			'url = url + "&StartTimeTicks="+ tostr(options.PlayStart) + "0000000"
		end if

		if streamInfo.AudioStreamIndex <> invalid then
			url = url + "&AudioStreamIndex=" + tostr(streamInfo.AudioStreamIndex)
		end if

		if streamInfo.SubtitleStream <> invalid then
		
			if streamInfo.SubtitleStream.IsTextSubtitleStream <> true OR shouldUseSoftSubs(streamInfo.SubtitleStream) <> true then
				url = url + "&SubtitleStreamIndex=" + tostr(streamInfo.SubtitleStreamIndex)
				enableSelectableSubtitleTracks = false
			else
				item.SubtitleUrl = GetServerBaseUrl()  + "/Videos/" + item.Id + "/" + mediaSourceId + "/Subtitles/" + tostr(streamInfo.SubtitleStreamIndex) + "/Stream.srt"
								
				if options.PlayStart <> invalid then
					'item.SubtitleUrl = item.SubtitleUrl + "?StartPositionTicks="+ tostr(options.PlayStart) + "0000000"
				end if
					
				item.SubtitleConfig = {
					ShowSubtitle: 1
					TrackName: item.SubtitleUrl
				}
			end if
		end if

		if streamInfo.AudioBitrate <> invalid then
			url = url + "&AudioBitrate=" + tostr(streamInfo.AudioBitrate)
		end if

		if streamInfo.VideoBitrate <> invalid then
			url = url + "&VideoBitrate=" + tostr(streamInfo.VideoBitrate)
		end if

		if streamInfo.MaxFramerate <> invalid then
			url = url + "&MaxFramerate=" + tostr(streamInfo.MaxFramerate)
		end if

		item.Stream = {
			url: url,
			contentid: "x-hls",
			bitrate: streamInfo.Bitrate / 1000,
			quality: false
		}

        item.StreamFormat = "hls"
        item.SwitchingStrategy = "full-adaptation"

	end If

	if item.IsHD = true And isDisplayHd then item.Stream.quality = true
	
	item.SubtitleTracks = []
	
	for each stream in mediaSource.MediaStreams
		if enableSelectableSubtitleTracks AND stream.IsTextSubtitleStream = true AND shouldUseSoftSubs(stream) = true then
		
			subUrl = GetServerBaseUrl()  + "/Videos/" + item.Id + "/" + mediaSourceId + "/Subtitles/" + tostr(stream.Index) + "/Stream.srt"
								
			if options.PlayStart <> invalid then
				'subUrl = subUrl + "?StartPositionTicks="+ tostr(options.PlayStart) + "0000000"
			end if
			
			subtitleInfo = {
				Language: stream.Language
				TrackName: subUrl
				Description: stream.Codec
			}
			
			if subtitleInfo.Language = invalid then subtitleInfo.Language = "Unknown language"
			
			item.SubtitleTracks.push(subtitleInfo)
			
		end if
	end for

End Sub

Function getPlaybackStreamInfo(item, options) as Object

	streams = []

	' Create streams for each media source
	for each source in item.MediaSources
		if options.MediaSourceId = invalid OR source.Id = options.MediaSourceId then

			streams.push(getStreamInfo(source, options))
		end if

	end for

	' If a specific media source was requested
	if options.MediaSourceId <> invalid then
		for each stream in streams
			if stream.MediaSource.Id = options.MediaSourceId then
			
				if options.AudioStreamIndex = -1 then
					stream.AudioStreamIndex = invalid
				else if options.AudioStreamIndex <> invalid then
					stream.AudioStreamIndex = options.AudioStreamIndex
				end if
				
				if options.SubtitleStreamIndex = -1 then
					stream.SubtitleStreamIndex = invalid
				else if options.SubtitleStreamIndex <> invalid then
					stream.SubtitleStreamIndex = options.SubtitleStreamIndex
				end if
				
				return stream
			end if
		end for
	end if

	' Now choose the optimal one
	for each stream in streams
		if stream.IsDirectStream = true then
			return stream
		end if
	end for

	for each stream in streams
		if stream.IsNativeVideo = true then
			return stream
		end if
	end for

	' No direct play or native video stream. Just take the first one
	return streams[0]
	
End Function

Function getStreamInfo(mediaSource as Object, options as Object) as Object

	audioStream = getMediaStream(mediaSource.MediaStreams, "Audio", options.AudioStreamIndex, mediaSource.DefaultAudioStreamIndex)
	videoStream = getMediaStream(mediaSource.MediaStreams, "Video", invalid, invalid)
	subtitleStream = getMediaStream(mediaSource.MediaStreams, "Subtitle", options.SubtitleStreamIndex, mediaSource.DefaultSubtitleStreamIndex)

	streamInfo = {
		MediaSource: mediaSource,
		VideoStream: videoStream,
		AudioStream: audioStream,
		SubtitleStream: subtitleStream,
		CanSeek: mediaSource.RunTimeTicks <> "" And mediaSource.RunTimeTicks <> invalid
	}

	if audioStream <> invalid then streamInfo.AudioStreamIndex = audioStream.Index
	if subtitleStream <> invalid then streamInfo.SubtitleStreamIndex = subtitleStream.Index

	if videoCanDirectPlay(mediaSource, audioStream, videoStream, subtitleStream, options) then

		streamInfo.IsDirectStream = true
		streamInfo.Bitrate = mediaSource.Bitrate

	else
		streamInfo.IsDirectStream = false

		maxVideoBitrate = firstOf(RegRead("prefVideoQuality"), "3200")
		maxVideoBitrate = maxVideoBitrate.ToInt()
	
		streamInfo.VideoBitrate = maxVideoBitrate * 1000

		streamInfo.AudioStreamIndex = mediaSource.DefaultAudioStreamIndex
		streamInfo.SubtitleStreamIndex = mediaSource.DefaultSubtitleStreamIndex

		' TODO: Support audio stream copy when possible
		sourceAudioChannels = 2
		if audioStream <> invalid and audioStream.Channels <> invalid then 
			sourceAudioChannels = audioStream.Channels
		end If

		surroundSound = SupportsSurroundSound(false, false)
		audioOutput51 = getGlobalVar("audioOutput51")

		if sourceAudioChannels > 2 then
			streamInfo.AudioCodec = "aac"
			streamInfo.MaxAudioChannels = 2
			streamInfo.AudioBitrate = 128000
			
		else if surroundSound and audioOutput51
			streamInfo.AudioCodec = "ac3"
			streamInfo.MaxAudioChannels = 5
			streamInfo.AudioBitrate = 256000
			
		else
			streamInfo.AudioCodec = "aac"
			streamInfo.MaxAudioChannels = 2
			streamInfo.AudioBitrate = 128000
		end if

		streamInfo.Bitrate = streamInfo.AudioBitrate + streamInfo.VideoBitrate

		' If over 30, encode at 24fps - but don't force transcoding if between 24 and 30
		if videoStream <> invalid and videoStream.AverageFrameRate <> invalid and videoStream.AverageFrameRate > 30 then
			streamInfo.MaxFramerate = mediaSource.MaxFramerate
		end if

		' if stream.Codec = "aac" Or (stream.Codec = "ac3" And getGlobalVar("audioOutput51")) Or (stream.Codec = "dca" And getGlobalVar("audioOutput51") And getGlobalVar("audioDTS"))

	end if

	return streamInfo

End Function

Function videoCanDirectPlay(mediaSource, audioStream, videoStream, subtitleStream, options) As Boolean

	if videoStream = invalid then 
		Debug("videoCanDirectPlay: Unknown videoStream")
		return false
	end if

	if mediaSource.Bitrate = invalid then
		Debug("videoCanDirectPlay: Unknown source bitrate")
		return false
	else
		maxVideoBitrate = firstOf(RegRead("prefVideoQuality"), "3200")
		maxVideoBitrate = maxVideoBitrate.ToInt() * 1000

		if maxVideoBitrate < mediaSource.Bitrate Then
			Debug("videoCanDirectPlay: bitrate too high")
			return false
		end If

	end If

    ' With the Roku 3, the surround sound support may have changed because of
    ' the headphones in the remote. If we have a cached direct play decision,
    ' we need to make sure the surround sound support hasn't changed and
    ' possibly reevaluate.
    surroundSound = SupportsSurroundSound(false, false)

	audioOutput51 = getGlobalVar("audioOutput51")
    surroundSoundDCA = surroundSound AND audioOutput51 'AND (RegRead("fivepointoneDCA", "preferences", "1") = "1")
    surroundSound = surroundSound AND audioOutput51 'AND (RegRead("fivepointone", "preferences", "1") = "1")

    ' There doesn't seem to be a great way to do this, but we need to see if
    ' the audio streams will support direct play. We'll assume that if there
    ' are audio streams with different numbers of channels, they're probably
    ' the same audio; if there are multiple streams with the same number of
    ' channels, they're probably something like commentary or another language.
    ' So if the selected stream is the first stream with that number of
    ' channels, it might be chosen by the Roku when Direct Playing. We don't
    ' just check the selected stream though, because if the 5.1 AC3 stream is
    ' selected and there's also a stereo AAC stream, we can direct play.
    ' But if there's a surround AAC stream before a stereo AAC stream, that
    ' doesn't work.

    stereoCodec = invalid
    surroundCodec = invalid
    secondaryStreamSelected = false
    surroundStreamFirst = false
    numAudioStreams = 0
    numVideoStreams = 0
    for each stream in mediaSource.MediaStreams
        if stream.Type = "Audio" then
            numAudioStreams = numAudioStreams + 1
            numChannels = firstOf(stream.Channels, 0)
            if numChannels <= 2 then
                if stereoCodec = invalid then
                    stereoCodec = stream.Codec
                    surroundStreamFirst = (surroundCodec <> invalid)
                else if stream.Index = audioStream.Index then
                    secondaryStreamSelected = true
                end if
            else if numChannels >= 6 then
                ' The Roku is just passing through the surround sound, so
                ' it theoretically doesn't care whether there were 6 channels
                ' or 60.
                if surroundCodec = invalid then
                    surroundCodec = stream.codec
                else if stream.Index = audioStream.Index then
                    secondaryStreamSelected = true
                end if
            else
                Debug("Unexpected channels on audio stream: " + tostr(stream.channels))
            end if
        else if stream.Type = "Video" then
            numVideoStreams = numVideoStreams + 1
        end if
    next
	
	container = mediaSource.Container
	videoCodec = invalid
	if videoStream <> invalid then videoCodec = videoStream.Codec
	audioCodec = invalid
	if audioStream <> invalid then audioCodec = audioStream.Codec
	subtitleCodec = invalid
	if subtitleStream <> invalid then subtitleCodec = subtitleStream.Codec

    Debug("Media item container: " + tostr(container))
    Debug("Media item video codec: " + tostr(videoCodec))
    Debug("Media item audio codec: " + tostr(audioCodec))
    Debug("Media item subtitles: " + tostr(subtitleCodec))
    Debug("Media item stereo codec: " + tostr(stereoCodec))
    Debug("Media item surround codec: " + tostr(surroundCodec))
    Debug("Secondary audio stream selected: " + tostr(secondaryStreamSelected))

    ' If no streams are provided, treat the Media audio codec as stereo.
    if numAudioStreams = 0 then
        stereoCodec = audioCodec
    end if

    ' Multiple video streams aren't supported, regardless of type.
    if numVideoStreams > 1 then
        Debug("videoCanDirectPlay: multiple video streams")
        return false
    end if

    versionArr = getGlobalVar("rokuVersion")
    major = versionArr[0]

    if subtitleStream <> invalid then
		if subtitleStream.IsTextSubtitleStream <> true OR shouldUseSoftSubs(subtitleStream) <> true then
			Debug("videoCanDirectPlay: need to burn in subtitles")
			return false
		end if
    end if

    if secondaryStreamSelected then
        Debug("videoCanDirectPlay: audio stream selected")
        return false
    end if

	' TODO: Add this information to server output, along with RefFrames
    if (videoStream <> invalid AND videoStream.IsAnamorphic = true) AND NOT firstOf(getGlobalVar("playsAnamorphic"), false) then
        Debug("videoCanDirectPlay: anamorphic videos not supported")
        return false
    end if

    if videoStream <> invalid and videoStream.Height <> invalid and videoStream.Height > 1080 then
        Debug("videoCanDirectPlay: height is greater than 1080: " + tostr(videoStream.Height))
        return false
    end if

    if container = "mp4" OR container = "mov" OR container = "m4v" then

        if (videoCodec <> "h264" AND videoCodec <> "mpeg4") then
            Debug("videoCanDirectPlay: vc not h264/mpeg4")
            return false
        end if

        if videoStream <> invalid and videoStream.RefFrames <> invalid AND firstOf(videoStream.RefFrames, 0) > firstOf(GetGlobalAA("maxRefFrames"), 0) then
            ' Not only can we not Direct Play, but we want to make sure we
            ' don't try to Direct Stream.
            'mediaItem.forceTranscode = true
            Debug("videoCanDirectPlay: too many ReFrames: " + tostr(videoStream.RefFrames))
            return false
        end if

        if surroundSound AND (surroundCodec = "ac3" OR stereoCodec = "ac3") then
            'mediaItem.canDirectPlay = true
            return true
        end if

        if surroundStreamFirst then
            Debug("videoCanDirectPlay: first audio stream is unsupported 5.1")
            return false
        end if

        if stereoCodec = "aac" then
            'mediaItem.canDirectPlay = true
            return true
        end if

        if stereoCodec = invalid AND numAudioStreams = 0 AND major >= 4 then
            ' If everything else looks ok and there are no audio streams, that's
            ' fine on Roku 2+.
            'mediaItem.canDirectPlay = true
            return true
        end if

        Debug("videoCanDirectPlay: ac not aac/ac3")
        return false
    end if

    if container = "wmv" then

		' Apparently deprecated since 4.1:
		' http://sdkdocs.roku.com/display/sdkdoc/Content+Meta-Data
		return False

        ' TODO: What exactly should we check here?
        if major > 3 then
            Debug("videoCanDirectPlay: wmv not supported by version " + tostr(major))
            return false
        end if

        ' Based on docs, only WMA9.2 is supported for audio
        if stereoCodec = invalid OR Left(stereoCodec, 3) <> "wma" then
            Debug("videoCanDirectPlay: ac not stereo wmav2")
            return false
        end if

        ' Video support is less obvious. WMV9 up to 480p, VC-1 up to 1080p?
        if videoCodec <> "wmv3" AND videoCodec <> "vc1" then
            Debug("videoCanDirectPlay: vc not wmv3/vc1")
            return false
        end if

        'mediaItem.canDirectPlay = true
        return true
    end if

    if container = "mkv" then
        if NOT CheckMinimumVersion(versionArr, [5, 1]) then
            Debug("videoCanDirectPlay: mkv not supported by version " + tostr(major))
            return false
        end if

        if (videoCodec <> "h264" AND videoCodec <> "mpeg4") then
            Debug("videoCanDirectPlay: vc not h264/mpeg4")
            return false
        end if

        if videoStream <> invalid and videoStream.RefFrames <> invalid then
            if firstOf(videoStream.RefFrames, 0) > firstOf(GetGlobalAA("maxRefFrames"), 0) then
                ' Not only can we not Direct Play, but we want to make sure we
                ' don't try to Direct Stream.
                'mediaItem.forceTranscode = true
                Debug("videoCanDirectPlay: too many ReFrames: " + tostr(videoStream.RefFrames))
                return false
            end if

            if firstOf(videoStream.BitDepth, 0) > 8 then
                'mediaItem.forceTranscode = true
                Debug("videoCanDirectPlay: bitDepth too high: " + tostr(videoStream.BitDepth))
                return false
            end if
        end if

        if surroundSound AND (surroundCodec = "ac3" OR stereoCodec = "ac3") then
            'mediaItem.canDirectPlay = true
            return true
        end if

        if surroundSoundDCA AND (surroundCodec = "dca" OR stereoCodec = "dca") then
            'mediaItem.canDirectPlay = true
            return true
        end if

        if surroundStreamFirst then
            Debug("videoCanDirectPlay: first audio stream is unsupported 5.1")
            return false
        end if

        if stereoCodec <> invalid AND (stereoCodec = "aac" OR stereoCodec = "mp3") then
            'mediaItem.canDirectPlay = true
            return true
        end if

        Debug("videoCanDirectPlay: ac not aac/ac3/mp3")
        return false
    end if

    return false
End Function

Function getMediaStream(mediaStreams, streamType, optionIndex, defaultIndex) as Object

	if optionIndex <> invalid then
		for each stream in mediaStreams
			if stream.Index = optionIndex and stream.Type = streamType then return stream
		end for
	end if

	if defaultIndex <> invalid then
		for each stream in mediaStreams
			if stream.Index = defaultIndex and stream.Type = streamType then return stream
		end for
	end if

	' We have to return something
	if streamType = "Video" or streamType = "Audio" then
		for each stream in mediaStreams
			if stream.Type = streamType then return stream
		end for
	end if

	return invalid

End Function

Function shouldUseSoftSubs(stream) As Boolean

	'if RegRead("softsubtitles", "preferences", "1") = "0" then return false
    'if stream.codec <> "srt" or stream.key = invalid then return false

    ' TODO(schuyler) If Roku adds support for non-Latin characters, remove
    ' this hackery. To the extent that we continue using this hackery, it
    ' seems that the Roku requires UTF-8 subtitles but only supports characters
    ' from Windows-1252. This should be the full set of languages that are
    ' completely representable in Windows-1252. PMS should specifically be
    ' returning ISO 639-2/B language codes.

    if m.SoftSubLanguages = invalid then
        m.SoftSubLanguages = {
            afr: 1,
            alb: 1,
            baq: 1,
            bre: 1,
            cat: 1,
            dan: 1,
            eng: 1,
            fao: 1,
            glg: 1,
            ger: 1,
            ice: 1,
            may: 1,
            gle: 1,
            ita: 1,
            lat: 1,
            ltz: 1,
            nor: 1,
            oci: 1,
            por: 1,
            roh: 1,
            gla: 1,
            spa: 1,
            swa: 1,
            swe: 1,
            wln: 1,
            est: 1,
            fin: 1,
            fre: 1,
            dut: 1
        }
    end if

    if stream.Language = invalid OR m.SoftSubLanguages.DoesExist(stream.Language) then return true

    return false
End Function


'**********************************************************
'** reportPlayback
'**********************************************************

Sub reportPlayback(id As String, mediaType as String, action As String, playMethod as String, isPaused as Boolean, canSeek as Boolean, position as Integer, mediaSourceId as String, audioStreamIndex = invalid, subtitleStreamIndex = invalid)

    ' Format Position Seconds into Ticks
	positionTicks = invalid
	
    if position <> invalid
        positionTicks =  itostr(position) + "0000000"
    end if

	url = ""
	
    if action = "start"
        ' URL
        url = GetServerBaseUrl() + "/Sessions/Playing"
		
    else if action = "progress"
	
        ' URL
        url = GetServerBaseUrl() + "/Sessions/Playing/Progress"
		
    else if action = "stop"
	
        ' URL
        url = GetServerBaseUrl() + "/Sessions/Playing/Stopped"
		
    end if

	url = url + "?itemId=" + id

    if positionTicks <> invalid
		url = url + "&PositionTicks=" + tostr(positionTicks)
    end if

	url = url + "&isPaused=" + tostr(isPaused)
	url = url + "&canSeek=" + tostr(canSeek)
	url = url + "&PlayMethod=" + playMethod
	url = url + "&QueueableMediaTypes=" + mediaType
	url = url + "&MediaSourceId=" + tostr(mediaSourceId)
	
    if audioStreamIndex <> invalid
		url = url + "&AudioStreamIndex=" + tostr(audioStreamIndex)
    end if

    if subtitleStreamIndex <> invalid
		url = url + "&SubtitleStreamIndex=" + tostr(subtitleStreamIndex)
    end if

	' Prepare Request
    request = HttpRequest(url)
    request.AddAuthorization()

	context = CreateObject("roAssociativeArray")
	GetViewController().StartRequest(request.Http, invalid, context, "", "post")

End Sub


'**********************************************************
'** Post Manual Watched Status
'**********************************************************

Function postWatchedStatus(videoId As String, markWatched As Boolean) As Boolean
    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/PlayedItems/" + HttpEncode(videoId)

    ' Prepare Request
    request = HttpRequest(url)
    request.AddAuthorization()

    ' If marking as unwatched
    if Not markWatched
        request.SetRequest("DELETE")
    end if

    ' Execute Request
    response = request.PostFromStringWithTimeout("", 5)
    if response <> invalid
        Debug("Mark Played/Unplayed")
        return true
    else
        Debug("Failed to Post Manual Watched Status")
    end if

    return false
End Function


'**********************************************************
'** Post Favorite Status
'**********************************************************

Function postFavoriteStatus(videoId As String, markFavorite As Boolean) As Boolean
    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/FavoriteItems/" + HttpEncode(videoId)

    ' Prepare Request
    request = HttpRequest(url)
    request.AddAuthorization()

    ' If marking as un-favorite
    if Not markFavorite
        request.SetRequest("DELETE")
    end if

    ' Execute Request
    response = request.PostFromStringWithTimeout("", 5)
    if response <> invalid
        Debug("Add/Remove Favorite")
        return true
    else
        Debug("Failed to Post Favorite Status")
    end if

    return false
End Function


'**********************************************************
'** Get Local Trailers
'**********************************************************

Function getLocalTrailers(videoId As String) As Object
    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items/" + HttpEncode(videoId) + "/LocalTrailers"

    return getSpecialFeaturesFromUrl(url)
End Function


'**********************************************************
'** Get Special Features
'**********************************************************

Function getSpecialFeatures(videoId As String) As Object
    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items/" + HttpEncode(videoId) + "/SpecialFeatures"

    return getSpecialFeaturesFromUrl(url)
End Function

Function getSpecialFeaturesFromUrl(url As String) As Object
    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

        fixedResponse = normalizeJson(response)

        contentList = CreateObject("roArray", 25, true)
        jsonObj     = ParseJSON(fixedResponse)

        if jsonObj = invalid
            Debug("Error while parsing JSON response")
            return invalid
        end if

        for each i in jsonObj
            
			metaData = getMetadataFromServerItem(i, 0, "flat-episodic-16x9")

            contentList.push( metaData )
        end for

        return contentList
    end if

    return invalid
End Function


'**********************************************************
'** Get Video Intros
'**********************************************************

Function getVideoIntros(videoId As String) As Object
    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items/" + HttpEncode(videoId) + "/Intros"

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

		return parseItemsResponse(response, 0, "flat-episodic-16x9")
    end if

    return invalid
End Function
