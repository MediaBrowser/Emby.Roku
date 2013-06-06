'**********************************************************
'**  Media Browser Roku Client - MB Video Utils
'**********************************************************


'**********************************************************
'** Format Chapter Time From Position Ticks
'**********************************************************

Function FormatChapterTime(positionTicks As Object) As String
    seconds = Int(((positionTicks).ToFloat() / 10000) / 1000)
    chapterTime = FormatTime(seconds)

    return chapterTime
End Function


'**********************************************************
'** Format Time From Seconds
'**********************************************************

Function FormatTime(seconds As Integer) As String

    if validateParam(seconds, "roInt", "FormatTime") = false return -1

    textTime = ""
    hasHours = false

    ' Special Check For Zero
    If seconds < 60
        Return "0:" + PadTime(itostr(seconds))
    End If
    
    ' Hours
    If seconds >= 3600
        textTime = textTime + itostr(seconds / 3600) + ":"
        hasHours = true
        seconds = seconds Mod 3600
    End If
    
    ' Minutes
    If seconds >= 60
        If hasHours
            textTime = textTime + PadTime(itostr(seconds / 60)) + ":"
        Else
            textTime = textTime + itostr(seconds / 60) + ":"
        End If
        
        seconds = seconds Mod 60
    Else
        If hasHours
            textTime = textTime + "00:"
        End If
    End If

    ' Seconds
    textTime = textTime + PadTime(itostr(seconds))

    return textTime
End Function


'**********************************************************
'** Pad Time with Zero
'**********************************************************

Function PadTime(timeText As String) As String

    If timeText.Len() < 2
        timeText = "0" + timeText
    End If
    
    Return timeText
End Function


'**********************************************************
'** Get HD Video And SS Audio Information From 
'** Media Streams
'**********************************************************

Function GetStreamInfo(streams As Object) As Object

    if validateParam(streams, "roArray", "GetStreamInfo") = false return -1

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
'** Setup Video Streams
'**********************************************************

Function SetupVideoStreams(videoId As String, videoType As String, videoPath As String) As Object

    if validateParam(videoId, "roString", "SetupVideoStreams") = false return -1
    if validateParam(videoType, "roString", "SetupVideoStreams") = false return -1
    if validateParam(videoPath, "roString", "SetupVideoStreams") = false return -1

    ' Setup array    
    streamData = {}

    ' Setup 5 Different Bitrates
    videoBitrates = [664, 996, 1320, 2600, 3200]

    ' Setup video url bitrates and video sizes
    urlBitrates = CreateObject("roArray", 5, true)
    urlBitrates.push("&VideoBitRate=664000&MaxWidth=640&MaxHeight=360&Profile=high&Level=4.0")
    urlBitrates.push("&VideoBitRate=996000&MaxWidth=1280&MaxHeight=720&Profile=high&Level=4.0")
    urlBitrates.push("&VideoBitRate=1320000&MaxWidth=1280&MaxHeight=720&Profile=high&Level=4.0")
    urlBitrates.push("&VideoBitRate=2600000&MaxWidth=1920&MaxHeight=1080&Profile=high&Level=4.0")
    urlBitrates.push("&VideoBitRate=3200000&MaxWidth=1920&MaxHeight=1080&Profile=high&Level=4.0")

    If videoType="VideoFile"
        regex = CreateObject("roRegex", "^.+\.(?:asf|ogv|ts|webm|wmv|mp4|m4v|mkv|mpeg|avi|m2ts)$", "i")
        If (regex = invalid)
            print "Error creating Regex:"
        End If

        If regex.isMatch(videoPath)=false
            Print "Unsupported file type"
        End If

        ' Determine Direct Play / Transcode By Extension
        extension = right(videoPath, 4)

        If (extension = ".asf" Or extension = ".ogv" Or extension = ".wmv" Or extension = ".mkv" Or extension = ".avi")
            ' Transcode Play
            streamList = CreateObject("roArray", 5, true)

            For i = 0 to 4
                stream = {}
                stream.url = GetServerBaseUrl() + "/Videos/" + videoId + "/stream.m3u8?VideoCodec=h264" + urlBitrates[i] + "&AudioCodec=aac&AudioBitRate=128000&AudioChannels=2&AudioSampleRate=44100"
                stream.bitrate = videoBitrates[i]

                If videoBitrates[i] > 700 Then
                    stream.quality = true
                Else
                    stream.quality = false
                End If

                stream.contentid = "x-" + itostr(videoBitrates[i])

                streamList.push( stream )
            End For

            streamData = {
                StreamFormat: "hls"
                Streams: streamList
            }

        Else If (extension = ".mp4") 
            Print ".mp4 file"
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

        Else If (extension = ".m4v") 
            Print ".m4v file"
            ' Direct Play
            stream = {}
            stream.url = GetServerBaseUrl() + "/Videos/" + videoId + "/stream.m4v?static=true"
            stream.bitrate = 0
            stream.quality = true
            stream.contentid = "x-direct"

            streamData = {
                StreamFormat: "m4v"
                Stream: stream
            }

        Else 
            ' Check For Other Types
            If right(videoPath, 3) = ".ts"
                Print ".ts file"
                ' Transcode Play
                streamList = CreateObject("roArray", 5, true)

                For i = 0 to 4
                    stream = {}
                    stream.url = GetServerBaseUrl() + "/Videos/" + videoId + "/stream.m3u8?VideoCodec=h264" + urlBitrates[i] + "&AudioCodec=aac&AudioBitRate=128000&AudioChannels=2&AudioSampleRate=44100"
                    stream.bitrate = videoBitrates[i]

                    If videoBitrates[i] > 700 Then
                        stream.quality = true
                    Else
                        stream.quality = false
                    End If

                    stream.contentid = "x-" + itostr(videoBitrates[i])

                    streamList.push( stream )
                End For

                streamData = {
                    StreamFormat: "hls"
                    Streams: streamList
                }

            Else If right(videoPath, 5) = ".webm" Or right(videoPath, 5) = ".mpeg" Or right(videoPath, 5) = ".m2ts"
                Return invalid

            Else
                Print "unknown file type"
                Return invalid

            End If
        End If

    Else If videoType="Dvd" Or videoType="BluRay" Or videoType="Iso" Or videoType="HdDvd"

        Print "DVD/BluRay/HDDVD/Iso file"
        ' Transcode Play
        streamList = CreateObject("roArray", 5, true)

        For i = 0 to 4
            stream = {}
            stream.url = GetServerBaseUrl() + "/Videos/" + videoId + "/stream.m3u8?VideoCodec=h264" + urlBitrates[i] + "&AudioCodec=aac&AudioBitRate=128000&AudioChannels=2&AudioSampleRate=44100"
            stream.bitrate = videoBitrates[i]

            If videoBitrates[i] > 700 Then
                stream.quality = true
            Else
                stream.quality = false
            End If

            stream.contentid = "x-" + itostr(videoBitrates[i])

            streamList.push( stream )
        End For

        streamData = {
            StreamFormat: "hls"
            Streams: streamList
        }

    End If

    Return streamData
End Function


'**********************************************************
'** Append Resume Time To Stream URLs
'**********************************************************

Function AddResumeOffset(StreamData As Object, offset As String) As Object

    if validateParam(StreamData, "roAssociativeArray", "AddResumeOffset") = false return -1
    if validateParam(offset, "roString", "AddResumeOffset") = false return -1

    If StreamData.Streams<>invalid Then
        ' Loop through urls, adding offset
        For each stream in StreamData.Streams
            stream.url = stream.url + "&StartTimeTicks=" + offset
        End For
    Else
        StreamData.Stream.url = StreamData.Stream.url + "&StartTimeTicks=" + offset
    End If

    Return StreamData

End Function
