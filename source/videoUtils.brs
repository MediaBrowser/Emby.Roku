'**********************************************************
'**  Media Browser Roku Client - MB Video Utils
'**********************************************************

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
    bitrates = [664, 996, 1320, 2600, 3800]
    urlBitrates = CreateObject("roArray", 5, true)
    urlBitrates.push("&VideoBitRate=664000&MaxWidth=640&MaxHeight=360&Profile=high&Level=4.0")
    urlBitrates.push("&VideoBitRate=996000&MaxWidth=1280&MaxHeight=720&Profile=high&Level=4.0")
    urlBitrates.push("&VideoBitRate=1320000&MaxWidth=1280&MaxHeight=720&Profile=high&Level=4.0")
    urlBitrates.push("&VideoBitRate=2600000&MaxWidth=1920&MaxHeight=1080&Profile=high&Level=4.0")
    urlBitrates.push("&VideoBitRate=3800000&MaxWidth=1920&MaxHeight=1080&Profile=high&Level=4.0")

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

        If (extension = ".asf")
            Print ".asf file"
            ' Transcode Play
            asfUrls = CreateObject("roArray", 5, true)
            asfUrls.push( GetServerBaseUrl() + "/Videos/" + videoId + "/stream.ts?VideoCodec=h264" + urlBitrates[0] + "&AudioCodec=aac&AudioBitRate=128000&AudioChannels=2&AudioSampleRate=44100" )
            asfUrls.push( GetServerBaseUrl() + "/Videos/" + videoId + "/stream.ts?VideoCodec=h264" + urlBitrates[1] + "&AudioCodec=aac&AudioBitRate=128000&AudioChannels=2&AudioSampleRate=44100" )
            asfUrls.push( GetServerBaseUrl() + "/Videos/" + videoId + "/stream.ts?VideoCodec=h264" + urlBitrates[2] + "&AudioCodec=aac&AudioBitRate=128000&AudioChannels=2&AudioSampleRate=44100" )
            asfUrls.push( GetServerBaseUrl() + "/Videos/" + videoId + "/stream.ts?VideoCodec=h264" + urlBitrates[3] + "&AudioCodec=aac&AudioBitRate=128000&AudioChannels=2&AudioSampleRate=44100" )
            asfUrls.push( GetServerBaseUrl() + "/Videos/" + videoId + "/stream.ts?VideoCodec=h264" + urlBitrates[4] + "&AudioCodec=aac&AudioBitRate=128000&AudioChannels=2&AudioSampleRate=44100" )

            streamData = {
                streamFormat: "ts"
                StreamBitrates: bitrates
                StreamUrls: asfUrls
                StreamQualities: ["SD","HD","HD","HD","HD"]
            }

        Else If (extension = ".ogv") 
            Print ".ogv file"
            ' Transcode Play
            ogvUrls = CreateObject("roArray", 5, true)
            ogvUrls.push( GetServerBaseUrl() + "/Videos/" + videoId + "/stream.ts?VideoCodec=h264" + urlBitrates[0] + "&AudioCodec=aac&AudioBitRate=128000&AudioChannels=2&AudioSampleRate=44100" )
            ogvUrls.push( GetServerBaseUrl() + "/Videos/" + videoId + "/stream.ts?VideoCodec=h264" + urlBitrates[1] + "&AudioCodec=aac&AudioBitRate=128000&AudioChannels=2&AudioSampleRate=44100" )
            ogvUrls.push( GetServerBaseUrl() + "/Videos/" + videoId + "/stream.ts?VideoCodec=h264" + urlBitrates[2] + "&AudioCodec=aac&AudioBitRate=128000&AudioChannels=2&AudioSampleRate=44100" )
            ogvUrls.push( GetServerBaseUrl() + "/Videos/" + videoId + "/stream.ts?VideoCodec=h264" + urlBitrates[3] + "&AudioCodec=aac&AudioBitRate=128000&AudioChannels=2&AudioSampleRate=44100" )
            ogvUrls.push( GetServerBaseUrl() + "/Videos/" + videoId + "/stream.ts?VideoCodec=h264" + urlBitrates[4] + "&AudioCodec=aac&AudioBitRate=128000&AudioChannels=2&AudioSampleRate=44100" )

            streamData = {
                streamFormat: "ts"
                StreamBitrates: bitrates
                StreamUrls: ogvUrls
                StreamQualities: ["SD","HD","HD","HD","HD"]
            }

        Else If (extension = ".wmv") 
            Print ".wmv file"
            ' Transcode Play
            wmvUrls = CreateObject("roArray", 5, true)
            wmvUrls.push( GetServerBaseUrl() + "/Videos/" + videoId + "/stream.ts?VideoCodec=h264" + urlBitrates[0] + "&AudioCodec=aac&AudioBitRate=128000&AudioChannels=2&AudioSampleRate=44100" )
            wmvUrls.push( GetServerBaseUrl() + "/Videos/" + videoId + "/stream.ts?VideoCodec=h264" + urlBitrates[1] + "&AudioCodec=aac&AudioBitRate=128000&AudioChannels=2&AudioSampleRate=44100" )
            wmvUrls.push( GetServerBaseUrl() + "/Videos/" + videoId + "/stream.ts?VideoCodec=h264" + urlBitrates[2] + "&AudioCodec=aac&AudioBitRate=128000&AudioChannels=2&AudioSampleRate=44100" )
            wmvUrls.push( GetServerBaseUrl() + "/Videos/" + videoId + "/stream.ts?VideoCodec=h264" + urlBitrates[3] + "&AudioCodec=aac&AudioBitRate=128000&AudioChannels=2&AudioSampleRate=44100" )
            wmvUrls.push( GetServerBaseUrl() + "/Videos/" + videoId + "/stream.ts?VideoCodec=h264" + urlBitrates[4] + "&AudioCodec=aac&AudioBitRate=128000&AudioChannels=2&AudioSampleRate=44100" )

            streamData = {
                streamFormat: "ts"
                StreamBitrates: bitrates
                StreamUrls: wmvUrls
                StreamQualities: ["SD","HD","HD","HD","HD"]
            }

        Else If (extension = ".mp4") 
            Print ".mp4 file"
            ' Direct Play
            streamData = {
                streamFormat: "mp4"
                StreamBitrates: [0]
                StreamUrls: [GetServerBaseUrl() + "/Videos/" + videoId + "/stream.mp4?static=true"]
                StreamQualities: ["HD"]
            }

        Else If (extension = ".m4v") 
            Print ".m4v file"
            ' Direct Play
            streamData = {
                streamFormat: "m4v"
                StreamBitrates: [0]
                StreamUrls: [GetServerBaseUrl() + "/Videos/" + videoId + "/stream.m4v?static=true"]
                StreamQualities: ["HD"]
            }

        Else If (extension = ".mkv")
            Print ".mkv file"
            ' Transcode Play
            mkvUrls = CreateObject("roArray", 5, true)
            mkvUrls.push( GetServerBaseUrl() + "/Videos/" + videoId + "/stream.ts?VideoCodec=h264" + urlBitrates[0] + "&AudioCodec=aac&AudioBitRate=128000&AudioChannels=2&AudioSampleRate=44100" )
            mkvUrls.push( GetServerBaseUrl() + "/Videos/" + videoId + "/stream.ts?VideoCodec=h264" + urlBitrates[1] + "&AudioCodec=aac&AudioBitRate=128000&AudioChannels=2&AudioSampleRate=44100" )
            mkvUrls.push( GetServerBaseUrl() + "/Videos/" + videoId + "/stream.ts?VideoCodec=h264" + urlBitrates[2] + "&AudioCodec=aac&AudioBitRate=128000&AudioChannels=2&AudioSampleRate=44100" )
            mkvUrls.push( GetServerBaseUrl() + "/Videos/" + videoId + "/stream.ts?VideoCodec=h264" + urlBitrates[3] + "&AudioCodec=aac&AudioBitRate=128000&AudioChannels=2&AudioSampleRate=44100" )
            mkvUrls.push( GetServerBaseUrl() + "/Videos/" + videoId + "/stream.ts?VideoCodec=h264" + urlBitrates[4] + "&AudioCodec=aac&AudioBitRate=128000&AudioChannels=2&AudioSampleRate=44100" )

            streamData = {
                streamFormat: "ts"
                StreamBitrates: bitrates
                StreamUrls: mkvUrls
                StreamQualities: ["SD","HD","HD","HD","HD"]
            }

        Else If (extension = ".avi") 
            Print ".avi file"
            ' Transcode Play
            aviUrls = CreateObject("roArray", 5, true)
            aviUrls.push( GetServerBaseUrl() + "/Videos/" + videoId + "/stream.ts?VideoCodec=h264" + urlBitrates[0] + "&AudioCodec=aac&AudioBitRate=128000&AudioChannels=2&AudioSampleRate=44100" )
            aviUrls.push( GetServerBaseUrl() + "/Videos/" + videoId + "/stream.ts?VideoCodec=h264" + urlBitrates[1] + "&AudioCodec=aac&AudioBitRate=128000&AudioChannels=2&AudioSampleRate=44100" )
            aviUrls.push( GetServerBaseUrl() + "/Videos/" + videoId + "/stream.ts?VideoCodec=h264" + urlBitrates[2] + "&AudioCodec=aac&AudioBitRate=128000&AudioChannels=2&AudioSampleRate=44100" )
            aviUrls.push( GetServerBaseUrl() + "/Videos/" + videoId + "/stream.ts?VideoCodec=h264" + urlBitrates[3] + "&AudioCodec=aac&AudioBitRate=128000&AudioChannels=2&AudioSampleRate=44100" )
            aviUrls.push( GetServerBaseUrl() + "/Videos/" + videoId + "/stream.ts?VideoCodec=h264" + urlBitrates[4] + "&AudioCodec=aac&AudioBitRate=128000&AudioChannels=2&AudioSampleRate=44100" )

            streamData = {
                streamFormat: "ts"
                StreamBitrates: bitrates
                StreamUrls: aviUrls
                StreamQualities: ["SD","HD","HD","HD","HD"]
            }

        Else 
            ' Check For Other Types
            If right(videoPath, 3) = ".ts"
                Print ".ts file"
                ' Transcode Play
                tsUrls = CreateObject("roArray", 5, true)
                tsUrls.push( GetServerBaseUrl() + "/Videos/" + videoId + "/stream.ts?VideoCodec=h264" + urlBitrates[0] + "&AudioCodec=aac&AudioBitRate=128000&AudioChannels=2&AudioSampleRate=44100" )
                tsUrls.push( GetServerBaseUrl() + "/Videos/" + videoId + "/stream.ts?VideoCodec=h264" + urlBitrates[1] + "&AudioCodec=aac&AudioBitRate=128000&AudioChannels=2&AudioSampleRate=44100" )
                tsUrls.push( GetServerBaseUrl() + "/Videos/" + videoId + "/stream.ts?VideoCodec=h264" + urlBitrates[2] + "&AudioCodec=aac&AudioBitRate=128000&AudioChannels=2&AudioSampleRate=44100" )
                tsUrls.push( GetServerBaseUrl() + "/Videos/" + videoId + "/stream.ts?VideoCodec=h264" + urlBitrates[3] + "&AudioCodec=aac&AudioBitRate=128000&AudioChannels=2&AudioSampleRate=44100" )
                tsUrls.push( GetServerBaseUrl() + "/Videos/" + videoId + "/stream.ts?VideoCodec=h264" + urlBitrates[4] + "&AudioCodec=aac&AudioBitRate=128000&AudioChannels=2&AudioSampleRate=44100" )

                streamData = {
                    streamFormat: "ts"
                    StreamBitrates: bitrates
                    StreamUrls: tsUrls
                    StreamQualities: ["SD","HD","HD","HD","HD"]
                }

            Else If right(videoPath, 5) = ".webm"
                Print ".webm file"
                Return invalid


            Else If right(videoPath, 5) = ".mpeg"
                Print ".mpeg file"
                Return invalid

            Else If right(videoPath, 5) = ".m2ts"
                Print ".m2ts file"
                Return invalid

            Else
                Print "unknown file type"
                Return invalid

            End If
        End If

    Else If videoType="Dvd" Or videoType="BluRay" Or videoType="Iso"

        Print "DVD/BluRay/Iso file"
        ' Transcode Play
        tsUrls = CreateObject("roArray", 5, true)
        tsUrls.push( GetServerBaseUrl() + "/Videos/" + videoId + "/stream.ts?VideoCodec=h264" + urlBitrates[0] + "&AudioCodec=aac&AudioBitRate=128000&AudioChannels=2&AudioSampleRate=44100" )
        tsUrls.push( GetServerBaseUrl() + "/Videos/" + videoId + "/stream.ts?VideoCodec=h264" + urlBitrates[1] + "&AudioCodec=aac&AudioBitRate=128000&AudioChannels=2&AudioSampleRate=44100" )
        tsUrls.push( GetServerBaseUrl() + "/Videos/" + videoId + "/stream.ts?VideoCodec=h264" + urlBitrates[2] + "&AudioCodec=aac&AudioBitRate=128000&AudioChannels=2&AudioSampleRate=44100" )
        tsUrls.push( GetServerBaseUrl() + "/Videos/" + videoId + "/stream.ts?VideoCodec=h264" + urlBitrates[3] + "&AudioCodec=aac&AudioBitRate=128000&AudioChannels=2&AudioSampleRate=44100" )
        tsUrls.push( GetServerBaseUrl() + "/Videos/" + videoId + "/stream.ts?VideoCodec=h264" + urlBitrates[4] + "&AudioCodec=aac&AudioBitRate=128000&AudioChannels=2&AudioSampleRate=44100" )

        streamData = {
            streamFormat: "ts"
            StreamBitrates: bitrates
            StreamUrls: tsUrls
            StreamQualities: ["SD","HD","HD","HD","HD"]
        }

    End If

    Return streamData
End Function


'**********************************************************
'** Append Resume Time To Stream URLs
'**********************************************************

Function AddResumeOffset(StreamUrls As Object, offset As String) As Object

    if validateParam(StreamUrls, "roArray", "AddResumeOffset") = false return -1
    if validateParam(offset, "roString", "AddResumeOffset") = false return -1

    newUrls = CreateObject("roArray", 5, true)

    ' Loop through urls, adding offset
    For each url in StreamUrls
        newUrls.push(url + "&StartTimeTicks=" + offset)
    End For

    Return newUrls

End Function
