'*****************************************************************
'**  Emby Roku Client - Video Metadata
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
            if firstOf(stream.Height, 0) >= 1080
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

Sub addVideoPlaybackInfo(item, mediaSource, options)


	if streamInfo.IsDirectStream Then

		item.Stream = {
			url: GetServerBaseUrl() + "/Videos/" + item.Id + "/stream?static=true&mediaSourceId=" + mediaSourceId + "&api_key=" + accessToken,
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
		
	else

		url = GetServerBaseUrl() + "/Videos/" + item.Id + "/master.m3u8?mediaSourceId=" + mediaSourceId + "&api_key=" + accessToken

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
		
		url = url + "&ClientTime=" + CreateObject("roDateTime").asSeconds().tostr()
		url = url + "&MaxVideoBitDepth=8"
		
		maxRefFrames = firstOf(getGlobalVar("maxRefFrames"), 0)
		
		if maxRefFrames > 0 then
			url = url + "&MaxRefFrames=" + maxRefFrames.tostr()
		end if
		
		url = url + "&AudioCodec=" + streamInfo.AudioCodec
		url = url + "&MaxAudioChannels=" + tostr(streamInfo.MaxAudioChannels)

		if streamInfo.AudioStreamIndex <> invalid then
			url = url + "&AudioStreamIndex=" + tostr(streamInfo.AudioStreamIndex)
		end if

		if streamInfo.SubtitleStream <> invalid then
		
			if streamInfo.SubtitleStream.IsTextSubtitleStream <> true OR shouldUseSoftSubs(streamInfo.SubtitleStream) <> true then
				url = url + "&SubtitleStreamIndex=" + tostr(streamInfo.SubtitleStreamIndex)
				enableSelectableSubtitleTracks = false
			else
				item.SubtitleUrl = GetServerBaseUrl()  + "/Videos/" + item.Id + "/" + mediaSourceId + "/Subtitles/" + tostr(streamInfo.SubtitleStreamIndex) + "/Stream.srt?api_key=" + accessToken
								
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
		
			subUrl = GetServerBaseUrl()  + "/Videos/" + item.Id + "/" + mediaSourceId + "/Subtitles/" + tostr(stream.Index) + "/Stream.srt?api_key=" + accessToken
								
			subtitleInfo = {
				Language: stream.Language
				TrackName: subUrl
				Description: stream.Codec
			}
			
			if subtitleInfo.Language = invalid then subtitleInfo.Language = "und"
			
			item.SubtitleTracks.push(subtitleInfo)
			
		end if
	end for

End Sub

Function getStreamInfo(mediaSource as Object, options as Object) as Object

	audioStream = getMediaStream(mediaSource.MediaStreams, "Audio", options.AudioStreamIndex, mediaSource.DefaultAudioStreamIndex)
	videoStream = getMediaStream(mediaSource.MediaStreams, "Video", invalid, invalid)
	subtitleStream = getMediaStream(mediaSource.MediaStreams, "Subtitle", options.SubtitleStreamIndex, mediaSource.DefaultSubtitleStreamIndex)

	streamInfo = {
		MediaSource: mediaSource,
		VideoStream: videoStream,
		AudioStream: audioStream,
		SubtitleStream: subtitleStream,
		LiveStreamId: mediaSource.LiveStreamId,
		CanSeek: mediaSource.RunTimeTicks <> "" And mediaSource.RunTimeTicks <> invalid
	}

	if audioStream <> invalid then 
		streamInfo.AudioStreamIndex = audioStream.Index
	else
		streamInfo.AudioStreamIndex = mediaSource.DefaultAudioStreamIndex
	end if
	
	if subtitleStream <> invalid then 
		streamInfo.SubtitleStreamIndex = subtitleStream.Index
	else
		streamInfo.SubtitleStreamIndex = mediaSource.DefaultSubtitleStreamIndex
	end if
	
	if mediaSource.enableDirectPlay = true then
	
		streamInfo.PlayMethod = "DirectPlay"
		streamInfo.Bitrate = mediaSource.Bitrate
		
	else if mediaSource.SupportsDirectStream = true then

		streamInfo.PlayMethod = "DirectStream"
		streamInfo.Bitrate = mediaSource.Bitrate

	else
	
		streamInfo.PlayMethod = "Transcode"
		maxVideoBitrate = firstOf(RegRead("prefVideoQuality"), "3200")
		maxVideoBitrate = maxVideoBitrate.ToInt()
	
		streamInfo.Bitrate = maxVideoBitrate * 1000

	end if

	return streamInfo

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

'**********************************************************
'** reportPlayback
'**********************************************************

Sub reportPlayback(id As String, mediaType as String, action As String, playMethod as String, isPaused as Boolean, canSeek as Boolean, position as Integer, mediaSourceId as String, liveStreamId = invalid, audioStreamIndex = invalid, subtitleStreamIndex = invalid)

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
	
    if liveStreamId <> invalid
		url = url + "&LiveStreamId=" + tostr(liveStreamId)
    end if
	
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
