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
'** Get File Extension
'**********************************************************

Function getFileExtension(filename as String) as String
    list = filename.tokenize(".")
    if list.count() > 0 then return LCase(list.GetTail()) else return ""
End Function






















'**********************************************************
'** Get HD Video And SS Audio Information From  (deprecated)
'** Media Streams
'**********************************************************

Function GetStreamInfo(streams As Object) As Object

    if validateParam(streams, "roArray", "GetStreamInfo") = false return -1

    Print "stream info"

    videoFound = false
    isHD = false

    audioFound = false
    isSurroundSound = false

    ' Loop through streams, looking for video and audio information
    For each itemData in streams
        If itemData.Type="Video" And videoFound=false
            videoFound = true
            ' Check for HD Video
            If itemData.Height > 718
                isHD = true
            End If
        Else If itemData.Type="Audio" And audioFound=false
            audioFound = true
            ' Check for Surround Sound Audio
            If itemData.Channels > 5
                isSurroundSound = true
            End If
        End If
    End For

    return {
        isHDVideo: isHD
        isSSAudio: isSurroundSound
    }
End Function


'**********************************************************
'** Setup Video Streams (deprecated)
'**********************************************************

Function SetupVideoStreams(videoId As String, videoType As String, videoPath As String) As Object

    if validateParam(videoId, "roString", "SetupVideoStreams") = false return -1
    if validateParam(videoType, "roString", "SetupVideoStreams") = false return -1
    if validateParam(videoPath, "roString", "SetupVideoStreams") = false return -1

    Print "setup video streams old"

    ' Lowercase the video type string
    videoType = LCase(videoType)

    ' Setup array    
    streamData = {}

    ' Setup the selected video quality
    If RegRead("prefVideoQuality") <> invalid Then
        videoBitrate = RegRead("prefVideoQuality")
    Else
        videoBitrate = "3200"
    End If

    ' Setup video url bitrates and video sizes
    urlBitrates = {}
    urlBitrates.AddReplace("664",  "&VideoBitRate=664000&MaxWidth=640&MaxHeight=360&Profile=high&Level=4.0")
    urlBitrates.AddReplace("996",  "&VideoBitRate=996000&MaxWidth=1280&MaxHeight=720&Profile=high&Level=4.0")
    urlBitrates.AddReplace("1320", "&VideoBitRate=1320000&MaxWidth=1280&MaxHeight=720&Profile=high&Level=4.0")
    urlBitrates.AddReplace("2600", "&VideoBitRate=2600000&MaxWidth=1920&MaxHeight=1080&Profile=high&Level=4.0")
    urlBitrates.AddReplace("3200", "&VideoBitRate=3200000&MaxWidth=1920&MaxHeight=1080&Profile=high&Level=4.0")

    If videoType="videofile"
        ' Determine Direct Play / Transcode By Extension
        extension = GetExtension(videoPath)

        print "file type: "; extension

        If (extension = "asf" Or extension = "avi" Or extension = "mpeg" Or extension = "m2ts" Or extension = "ogv" Or extension = "ts" Or extension = "webm" Or extension = "wmv" Or extension = "wtv")
            ' Transcode Play
            stream = {}
            stream.url = GetServerBaseUrl() + "/Videos/" + videoId + "/stream.m3u8?VideoCodec=h264" + urlBitrates.Lookup(videoBitrate) + "&AudioCodec=aac&AudioBitRate=128000&AudioChannels=2&AudioSampleRate=44100&TimeStampOffsetMs=0"
            stream.bitrate = videoBitrate.ToInt()

            If videoBitrate.ToInt() > 700 Then
                stream.quality = true
            Else
                stream.quality = false
            End If

            stream.contentid = "x-" + videoBitrate

            streamData = {
                StreamFormat: "hls"
                Streams: [stream]
            }

        Else If (extension = "mkv")
            directPlay = false

            If directPlay Then
                ' Direct Play
                stream = {}
                stream.url = GetServerBaseUrl() + "/Videos/" + videoId + "/stream.mkv?static=true"
                stream.bitrate = 0
                stream.quality = true
                stream.contentid = "x-direct"

                streamData = {
                    StreamFormat: "mkv"
                    Stream: stream
                }
            Else
                ' Transcode Play
                stream = {}
                stream.url = GetServerBaseUrl() + "/Videos/" + videoId + "/stream.m3u8?VideoCodec=h264" + urlBitrates.Lookup(videoBitrate) + "&AudioCodec=aac&AudioBitRate=128000&AudioChannels=2&AudioSampleRate=44100&TimeStampOffsetMs=0"
                stream.bitrate = videoBitrate.ToInt()

                If videoBitrate.ToInt() > 700 Then
                    stream.quality = true
                Else
                    stream.quality = false
                End If

                stream.contentid = "x-" + videoBitrate

                streamData = {
                    StreamFormat: "hls"
                    Streams: [stream]
                }
            End If

        Else If (extension = "mp4") 
            ' Direct Play
            stream = {}
            stream.url = GetServerBaseUrl() + "/Videos/" + videoId + "/stream.mp4?static=true"
            stream.bitrate = 0
            stream.quality = true
            stream.contentid = "x-direct"

            streamData = {
                StreamFormat: "mp4"
                Stream: stream
            }

        Else If (extension = "m4v")
            ' Direct Play
            stream = {}
            stream.url = GetServerBaseUrl() + "/Videos/" + videoId + "/stream.m4v?static=true"
            stream.bitrate = 0
            stream.quality = true
            stream.contentid = "x-direct"

            streamData = {
                StreamFormat: "mp4"
                Stream: stream
            }

        Else 

            Print "unknown file type"
            Return invalid

        End If

    Else If videoType="dvd" Or videoType="bluray" Or videoType="iso" Or videoType="hddvd"

        Print "DVD/BluRay/HDDVD/Iso file"
        ' Transcode Play
        stream = {}
        stream.url = GetServerBaseUrl() + "/Videos/" + videoId + "/stream.m3u8?VideoCodec=h264" + urlBitrates.Lookup(videoBitrate) + "&AudioCodec=aac&AudioBitRate=128000&AudioChannels=2&AudioSampleRate=44100&TimeStampOffsetMs=0"
        stream.bitrate = videoBitrate.ToInt()

        If videoBitrate.ToInt() > 700 Then
            stream.quality = true
        Else
            stream.quality = false
        End If

        stream.contentid = "x-" + videoBitrate

        streamData = {
            StreamFormat: "hls"
            Streams: [stream]
        }

    End If

    Return streamData
End Function
