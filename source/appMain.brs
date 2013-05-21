'********************************************************************
'**  Media Browser Roku Client - Main
'********************************************************************

Sub Main()

    'Initialize theme
    initTheme()

    'Create facade screen
    facade = CreateObject("roParagraphScreen")
    facade.Show()

    ' Goto Marker
    checkServerStatus:

    dialogBox = ShowPleaseWait("Please Wait...", "Connecting To MediaBrowser 3 Server")

    'Get MediaBrowser Server
    status = GetServerStatus()

    ' Check If Server Ping Failed
    If status = 0 Then
        dialogBox.Close()
        dialogBox = ShowPleaseWait("Please Wait...", "Could Not Find Server. Attempting Auto-Discovery")

        ' Refresh Server Call
        status = GetServerStatus(true)
    End If
    
    ' Check If Ping And Automated Discovery Failed
    If status = -1 Then
        dialogBox.Close()

        ' Server Not found even after refresh, Give Option To Type In IP Or Try again later
        buttonPress = ShowConnectionFailed()

        If buttonPress=0 Then
            Return
        Else
            savedConf = ShowManualServerConfiguration()
            If savedConf = 1 Then
                ' Retry Connection with manual entries
                Goto checkServerStatus
            Else
                ' Exit Application
                Return
            End if
        End If
    End if

    'Close Dialog Box
    dialogBox.Close()

    'prepare the screen for display and get ready to begin
    screen = CreateLoginPage("", "")
    if screen = invalid then
        print "Unexpected error in CreateLoginPage"
        return
    end if

    'set to go, time to get started
    ShowLoginPage(screen)

End Sub


'*************************************************************
'** Setup the theme for the application
'*************************************************************

Sub initTheme()
    app = CreateObject("roAppManager")
    
    listItemHighlight           = "#ffffff"
    listItemText                = "#707070"
    brandingWhite               = "#eeeeee"
    backgroundColor             = "#424242" '#c0c0c0
    breadcrumbText              = "#eeeeee"

    theme = {
        BackgroundColor: backgroundColor

        OverhangSliceHD: "pkg:/images/Overhang_Background_HD.png"
        OverhangSliceSD: "pkg:/images/Overhang_Background_SD.png"
        OverhangLogoHD: "pkg:/images/mblogowhite.png"
        OverhangLogoSD: "pkg:/images/mblogowhite.png"
        OverhangOffsetSD_X: "35"
        OverhangOffsetSD_Y: "25"
        OverhangOffsetHD_X: "35"
        OverhangOffsetHD_Y: "25"

        BreadcrumbTextLeft: breadcrumbText
        BreadcrumbTextRight: breadcrumbText
        BreadcrumbDelimiter: breadcrumbText
        
        PosterScreenLine1Text: "#ffffff"

        ListItemText: listItemText
        ListItemHighlightText: listItemHighlight
        ListScreenDescriptionText: listItemText
        ListItemHighlightHD: "pkg:/images/select_bkgnd.png"
        ListItemHighlightSD: "pkg:/images/select_bkgnd.png"

        CounterTextLeft: brandingWhite
        CounterTextRight: brandingWhite
        CounterSeparator: brandingWhite

        GridScreenBackgroundColor: backgroundColor
        GridScreenListNameColor: brandingWhite
        GridScreenDescriptionTitleColor: brandingWhite
        GridScreenDescriptionDateColor: brandingWhite
        GridScreenLogoHD: "pkg:/images/mblogowhite.png"
        GridScreenLogoSD: "pkg:/images/mblogowhite.png"
        GridScreenOverhangHeightHD: "124"
        GridScreenOverhangHeightSD: "83"
        GridScreenOverhangSliceHD: "pkg:/images/Overhang_Background_HD.png"
        GridScreenOverhangSliceSD: "pkg:/images/Overhang_Background_SD.png"
        GridScreenLogoOffsetHD_X: "35"
        GridScreenLogoOffsetHD_Y: "25"
        GridScreenLogoOffsetSD_X: "35"
        GridScreenLogoOffsetSD_Y: "25"

        'GridScreenFocusBorderSD: "pkg:/images/grid/GridCenter_Border_Movies_SD43.png"
        'GridScreenBorderOffsetSD: "(-26,-25)"
        'GridScreenFocusBorderHD: "pkg:/images/grid/GridCenter_Border_Movies_HD2.png"
        'GridScreenBorderOffsetHD: "(-15,-15)"

        'GridScreenDescriptionImageSD: "pkg:/images/grid/Grid_Description_Background_Portrait_SD43.png"
        'GridScreenDescriptionOffsetSD:"(125,170)"
        'GridScreenDescriptionImageHD: "pkg:/images/grid/Grid_Description_Background_Portrait_HD.png"
        'GridScreenDescriptionOffsetHD:"(150,205)"

        SpringboardActorColor: "#ffffff"

        SpringboardAlbumColor: "#ffffff"
        SpringboardAlbumLabel: "#ffffff"
        SpringboardAlbumLabelColor: "#ffffff"

        'SpringboardAllow6Buttons: false

        SpringboardArtistColor: "#ffffff"
        SpringboardArtistLabel: "#ffffff"
        SpringboardArtistLabelColor: "#ffffff"

        SpringboardDirectorColor: "#ffffff"
        SpringboardDirectorLabel: "#ffffff"
        SpringboardDirectorLabelColor: "#ffffff"
        SpringboardDirectorPrefixText: "#ffffff"

        SpringboardGenreColor: "#ffffff"
        SpringboardRuntimeColor: "#ffffff"
        SpringboardSynopsisColor: "#ffffff"
        SpringboardTitleText: "#ffffff"
    }

    app.SetTheme( theme )
End Sub


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
    Print "Setup Video Streams"

    regex = CreateObject("roRegex", "^.+\.(?:asf|ogv|ts|webm|wmv|mp4|m4v|mkv|mpeg|avi|m2ts)$", "i")
    If (regex = invalid)
        print "Error creating Regex:"
    End If

    If regex.isMatch(videoPath)=false
        Print "Unsupported file type"
    End If
    
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

        Return streamData

    End If

End Function
