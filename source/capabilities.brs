'******************************************************
' Creates the capabilities object that is reported to Emby servers
'******************************************************

Function getDirectPlayProfiles()

	profiles = []
	
	versionArr = getGlobalVar("rokuVersion")
	audioContainers = "mp3,wma"
	
	surroundSound = SupportsSurroundSound(false, false)

	audioOutput51 = getGlobalVar("audioOutput51")
    surroundSoundDCA = surroundSound AND audioOutput51 'AND (RegRead("fivepointoneDCA", "preferences", "1") = "1")
    surroundSound = surroundSound AND audioOutput51 'AND (RegRead("fivepointone", "preferences", "1") = "1")
  
	if CheckMinimumVersion(versionArr, [5, 3]) then
		audioContainers = audioContainers + ",flac"
	end if
	
	profiles.push({
		Type: "Audio"
		Container: audioContainers
	})
	
	mp4Audio = "aac"
	
	if surroundSound then
		mp4Audio = mp4Audio + ",ac3"
	end if
	
	profiles.push({
		Type: "Video"
		Container: "mp4,mov,m4v"
		VideoCodec: "h264,mpeg4"
		AudioCodec: mp4Audio
	})
	
	mkvAudio = "aac,mp3"
	
	if CheckMinimumVersion(versionArr, [5, 1]) then
	
		if surroundSound then
            mkvAudio = mkvAudio + ",ac3"
        end if

        if surroundSoundDCA then
            mkvAudio = mkvAudio + ",dca"
        end if

        profiles.push({
			Type: "Video"
			Container: "mkv"
			VideoCodec: "h264,mpeg4"
			AudioCodec: mkvAudio
		})
		
	end if

	return profiles

End Function

Function getTranscodingProfiles()

	profiles = []
	
	profiles.push({
		Type: "Audio"
		Container: "mp3"
		AudioCodec: "mp3"
		Context: "Streaming"
		Protocol: "Http"
	})
	
	profiles.push({
		Type: "Video"
		Container: "ts"
		AudioCodec: "aac"
		VideoCodec: "h264"
		Context: "Streaming"
		Protocol: "Hls"
	})

	return profiles

End Function

Function getCodecProfiles()

	profiles = []

	maxRefFrames = firstOf(getGlobalVar("maxRefFrames"), 100)
	
	h264Conditions = []
	h264Conditions.push({
		Condition: "LessThanEqual"
		Property: "RefFrames"
		Value: maxRefFrames
		IsRequired: false
	})
	h264Conditions.push({
		Condition: "LessThanEqual"
		Property: "VideoBitDepth"
		Value: "8"
		IsRequired: false
	})
	h264Conditions.push({
		Condition: "LessThanEqual"
		Property: "Height"
		Value: "1080"
	})
	h264Conditions.push({
		Condition: "LessThanEqual"
		Property: "VideoFramerate"
		Value: "30"
		IsRequired: false
	})
	h264Conditions.push({
		Condition: "Equals"
		Property: "IsAnamorphic"
		Value: "false"
		IsRequired: false
	})
	
	profiles.push({
		Type: "Video"
		Codec: "h264,mpeg4"
		Conditions: h264Conditions
	})
	
	return profiles

End Function

Function getContainerProfiles()

	profiles = []

	return profiles

End Function

Function getSubtitleProfiles()

	profiles = []

	return profiles

End Function

Function getDeviceProfile() 

	maxVideoBitrate = firstOf(RegRead("prefVideoQuality"), "3200")
	maxVideoBitrate = maxVideoBitrate.ToInt() * 1000
	
	profile = {
		MaxStaticBitrate: 40000000
		MaxStreamingBitrate: maxVideoBitrate
		MusicStreamingTranscodingBitrate: 192000
		
		DirectPlayProfiles: getDirectPlayProfiles()
		TranscodingProfiles: getTranscodingProfiles()
		CodecProfiles: getCodecProfiles()
		ContainerProfiles: getContainerProfiles()
		SubtitleProfiles: getSubtitleProfiles()
	}
	
	return profile
	
End Function

Function getCapabilities() 

	caps = {
		PlayableMediaTypes: ["Audio","Video","Photo"]
		SupportsMediaControl: true
		SupportedCommands: ["MoveUp","MoveDown","MoveLeft","MoveRight","Select","Back","GoHome","SendString","GoToSearch","GoToSettings","DisplayContent","SetAudioStreamIndex","SetSubtitleStreamIndex"]
		MessageCallbackUrl: ":8324/emby/message"
		DeviceProfile: getDeviceProfile()
	}
	
	return caps
	
End Function