'**********************************************************
'**  Media Browser Roku Client - Video Utils
'**********************************************************


'**********************************************************
'** Format Time From Seconds
'**********************************************************

Function formatTime(seconds As Integer) As String
    if validateParam(seconds, "roInt", "formatTime") = false return -1

    textTime = ""
    hasHours = false

    ' Special Check For Zero
    if seconds < 60
        return "0:" + ZeroPad(itostr(seconds))
    end if
    
    ' Hours
    if seconds >= 3600
        textTime = textTime + itostr(seconds / 3600) + ":"
        hasHours = true
        seconds = seconds Mod 3600
    end if
    
    ' Minutes
    if seconds >= 60
        if hasHours
            textTime = textTime + ZeroPad(itostr(seconds / 60)) + ":"
        else
            textTime = textTime + itostr(seconds / 60) + ":"
        end if
        
        seconds = seconds Mod 60
    else
        if hasHours
            textTime = textTime + "00:"
        end if
    end if

    ' Seconds
    textTime = textTime + ZeroPad(itostr(seconds))

    return textTime
End Function


'**********************************************************
'** Format Some Common Languages
'**********************************************************

Function formatLanguage(abbr As String) As String
    languages = {}
    languages["en"]  = "English"
    languages["eng"] = "English"
    languages["fr"]  = "French"
    languages["fra"] = "French"
    languages["de"]  = "German"
    languages["deu"] = "German"
    languages["it"]  = "Italian"
    languages["ita"] = "Italian"
    languages["ja"]  = "Japanese"
    languages["jpn"] = "Japanese"
    languages["pl"]  = "Polish"
    languages["pol"] = "Polish"
    languages["pt"]  = "Portuguese"
    languages["por"] = "Portuguese"
    languages["ru"]  = "Russian"
    languages["rus"] = "Russian"
    languages["es"]  = "Spanish"
    languages["spa"] = "Spanish"
    languages["sv"]  = "Swedish"
    languages["swe"] = "Swedish"

    if languages.DoesExist(abbr) then
        languageName = languages[abbr]
    else
        languageName = abbr
    end if

    return languageName
End Function


'**********************************************************
'** Get Video Bitrate Settings
'**********************************************************

Function getVideoBitrateSettings(bitrate As Integer) As Object
    ' Get Bitrate Settings
    if bitrate = 664
        settings = {
            videobitrate: "664000"
            maxwidth: "640"
            maxheight: "360"
            profile: "high"
            level: "4.0"
        }

    else if bitrate = 996
        settings = {
            videobitrate: "996000"
            maxwidth: "1280"
            maxheight: "720"
            profile: "high"
            level: "4.0"
        }

    else if bitrate = 1320
        settings = {
            videobitrate: "1320000"
            maxwidth: "1280"
            maxheight: "720"
            profile: "high"
            level: "4.0"
        }

    else if bitrate = 2600
        settings = {
            videobitrate: "2600000"
            maxwidth: "1920"
            maxheight: "1080"
            profile: "high"
            level: "4.0"
        }

    else if bitrate = 3200
        settings = {
            videobitrate: "3200000"
            maxwidth: "1920"
            maxheight: "1080"
            profile: "high"
            level: "4.0"
        }

    else if bitrate = 4700
        settings = {
            videobitrate: "4700000"
            maxwidth: "1920"
            maxheight: "1080"
            profile: "high"
            level: "4.0"
        }

    else if bitrate = 6200
        settings = {
            videobitrate: "6200000"
            maxwidth: "1920"
            maxheight: "1080"
            profile: "high"
            level: "4.0"
        }

    else if bitrate = 7700
        settings = {
            videobitrate: "7700000"
            maxwidth: "1920"
            maxheight: "1080"
            profile: "high"
            level: "4.0"
        }

    else if bitrate = 9200
        settings = {
            videobitrate: "9200000"
            maxwidth: "1920"
            maxheight: "1080"
            profile: "high"
            level: "4.0"
        }

    else if bitrate = 10700
        settings = {
            videobitrate: "10700000"
            maxwidth: "1920"
            maxheight: "1080"
            profile: "high"
            level: "4.0"
        }

    else if bitrate = 12200
        settings = {
            videobitrate: "12200000"
            maxwidth: "1920"
            maxheight: "1080"
            profile: "high"
            level: "4.0"
        }

    else if bitrate = 13700
        settings = {
            videobitrate: "13700000"
            maxwidth: "1920"
            maxheight: "1080"
            profile: "high"
            level: "4.0"
        }

    else if bitrate = 15200
        settings = {
            videobitrate: "15200000"
            maxwidth: "1920"
            maxheight: "1080"
            profile: "high"
            level: "4.0"
        }

    else if bitrate = 16700
        settings = {
            videobitrate: "16700000"
            maxwidth: "1920"
            maxheight: "1080"
            profile: "high"
            level: "4.0"
        }

    else if bitrate = 18200
        settings = {
            videobitrate: "18200000"
            maxwidth: "1920"
            maxheight: "1080"
            profile: "high"
            level: "4.0"
        }

    else if bitrate = 20000
        settings = {
            videobitrate: "20000000"
            maxwidth: "1920"
            maxheight: "1080"
            profile: "high"
            level: "4.0"
        }

    end if
    
    return settings
End Function


'**********************************************************
'** Get File Extension
'**********************************************************

Function getFileExtension(filename as String) as String
    list = filename.tokenize(".")
    if list.count() > 0 then return LCase(list.GetTail()) else return ""
End Function


'**********************************************************
'** Play video
'**********************************************************

Sub playVideo(video As Object, options as Object) 

    if AudioPlayer().IsPlaying
        Debug("Stop audio player")
        AudioPlayer().Stop()
    end if

	list = []

    if options.playstart = 0 and options.intros <> false

        intros = getVideoIntros(video.Id)

        if intros <> invalid
		
            for each i in intros.Items	

				list.push(i)
            end for
			
        end if

    end if

	list.push(video)
	playVideoList(list, options)
	
End Sub

Sub playVideoList(list As Object, options as Object) 

    if AudioPlayer().IsPlaying
        Debug("Stop audio player")
        AudioPlayer().Stop()
    end if

	GetViewController().CreateVideoPlayer(list[0], options, true)
	
End Sub