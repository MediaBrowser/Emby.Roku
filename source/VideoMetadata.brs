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

        ' Fixes bug within BRS Json Parser
        regex         = CreateObject("roRegex", Chr(34) + "(RunTimeTicks|PlaybackPositionTicks|StartPositionTicks)" + Chr(34) + ":(-?[0-9]+),", "i")
        fixedResponse = regex.ReplaceAll(response, Chr(34) + "\1" + Chr(34) + ":" + Chr(34) + "\2" + Chr(34) + ",")

        i = ParseJSON(fixedResponse)

        if i = invalid
            Debug("Error Parsing Video Metadata")
            return invalid
        end if

        if i.Type = invalid
            Debug("No Content Type Set for Video")
            return invalid
        end if
        
        metaData = {}

        ' Set the Content Type
        metaData.ContentType = i.Type

        ' Set the Id
        metaData.Id = i.Id

        ' Set the Title
        metaData.Title = firstOf(i.Name, "Unknown")

        ' Set the Series Title
        if i.SeriesName <> invalid
            metaData.SeriesTitle = i.SeriesName
        end if

        ' Set the Overview
        if i.Overview <> invalid
            metaData.Description = i.Overview
        end if

        ' Set the Official Rating
        if i.OfficialRating <> invalid
            metaData.Rating = i.OfficialRating
        end if

        ' Set the Release Date
        if isInt(i.ProductionYear)
            metaData.ReleaseDate = itostr(i.ProductionYear)
        end if

        ' Set the Star Rating
        if i.CommunityRating <> invalid
            metaData.UserStarRating = Int(i.CommunityRating) * 10
        end if

        ' Set the Run Time
        if i.RunTimeTicks <> "" And i.RunTimeTicks <> invalid
            metaData.Length = Int(((i.RunTimeTicks).ToFloat() / 10000) / 1000)
        end if

        ' Set the Playback Position
        if i.UserData.PlaybackPositionTicks <> "" And i.UserData.PlaybackPositionTicks <> invalid
            positionSeconds = Int(((i.UserData.PlaybackPositionTicks).ToFloat() / 10000) / 1000)
            metaData.PlaybackPosition = positionSeconds
        else
            metaData.PlaybackPosition = 0
        end if

        if i.Type = "Movie"

            ' Check For People, Grab First 3 If Exists
            if i.People <> invalid And i.People.Count() > 0
                metaData.Actors = CreateObject("roArray", 3, true)

                ' Set Max People to grab Size of people array
                maxPeople = i.People.Count()-1

                ' Check To Max sure there are 3 people
                if maxPeople > 3
                    maxPeople = 2
                end if

                for actorCount = 0 to maxPeople
                    if i.People[actorCount].Name <> "" And i.People[actorCount].Name <> invalid
                        metaData.Actors.Push(i.People[actorCount].Name)
                    end if
                end for
            end if

        else if i.Type = "Episode"

            ' Build Episode Information
            episodeInfo = ""

            ' Add Series Name
            if i.SeriesName <> invalid
                episodeInfo = i.SeriesName
            end if

            ' Add Season Number
            if i.ParentIndexNumber <> invalid
                if episodeInfo <> ""
                    episodeInfo = episodeInfo + " / "
                end if

                episodeInfo = episodeInfo + "Season " + itostr(i.ParentIndexNumber)
            end if

            ' Add Episode Number
            if i.IndexNumber <> invalid
                if episodeInfo <> ""
                    episodeInfo = episodeInfo + " / "
                end if
                
                episodeInfo = episodeInfo + "Episode " + itostr(i.IndexNumber)

                ' Add Double Episode Number
                if i.IndexNumberEnd <> invalid
                    episodeInfo = episodeInfo + "-" + itostr(i.IndexNumberEnd)
                end if
            end if

            ' Use Actors Area for Series / Season / Episode
            metaData.Actors = episodeInfo

        end if

        ' Setup Watched Status In Category Area
        if i.UserData.Played <> invalid And i.UserData.Played = true
            if i.UserData.LastPlayedDate <> invalid
                metaData.Categories = "Watched on " + formatDateStamp(i.UserData.LastPlayedDate)
            else
                metaData.Categories = "Watched"
            end if
        end if

        ' Setup Chapters
        if i.Chapters <> invalid

            metaData.Chapters = CreateObject("roArray", 5, true)
            chapterCount = 0

            for each c in i.Chapters
                chapterData = {}

                ' Set the chapter display title
                chapterData.Title = firstOf(c.Name, "Unknown")
                chapterData.ShortDescriptionLine1 = firstOf(c.Name, "Unknown")

                ' Set chapter time
                if c.StartPositionTicks <> invalid
                    chapterPositionSeconds = Int(((c.StartPositionTicks).ToFloat() / 10000) / 1000)

                    chapterData.StartPosition = chapterPositionSeconds
                    chapterData.ShortDescriptionLine2 = formatTime(chapterPositionSeconds)
                end if

                ' Set Advanced Play
                'chapterData.Description = "* for advanced playback"

                ' Get Image Sizes
                sizes = GetImageSizes("flat-episodic-16x9")

                ' Check if Chapter has Image, otherwise use default
                if c.ImageTag <> "" And c.ImageTag <> invalid
                    imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.Id) + "/Images/Chapter/" + itostr(chapterCount)

                    chapterData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, c.ImageTag, false, 0, true)
                    chapterData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, c.ImageTag, false, 0, true)

                else 
                    chapterData.HDPosterUrl = "pkg://images/items/collection.png"
                    chapterData.SDPosterUrl = "pkg://images/items/collection.png"

                end if

                ' Increment Count
                chapterCount = chapterCount + 1

                metaData.Chapters.push( chapterData )
            end for

        end if

        ' Setup Video Location / Type Information
        if i.VideoType <> invalid
            metaData.VideoType = i.VideoType
        end If

        if i.Path <> invalid
            metaData.VideoPath = i.Path
        end If

        if i.LocationType <> invalid
            metaData.LocationType = i.LocationType
        end If

        ' Set HD Flags
        if i.IsHd <> invalid
            metaData.HDBranded = i.IsHd
            metaData.IsHD = i.IsHd
        end if

        ' Parse Media Info
        metaData = parseVideoMediaInfo(metaData, i)

        ' Get Image Sizes
        if i.Type = "Episode"
            sizes = GetImageSizes("rounded-rect-16x9-generic")
        else
            sizes = GetImageSizes("movie")
        end if
        
        ' Check if Item has Image, otherwise use default
        if i.ImageTags.Primary <> "" And i.ImageTags.Primary <> invalid
            imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.Id) + "/Images/Primary/0"

            metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ImageTags.Primary, false, 0, true)
            metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ImageTags.Primary, false, 0, true)

        else 
            metaData.HDPosterUrl = "pkg://images/items/collection.png"
            metaData.SDPosterUrl = "pkg://images/items/collection.png"

        end if

        return metaData
    else
        Debug("Failed to Get Video Metadata")
    end if

    return invalid
End Function


'**********************************************************
'** Parse Media Information
'**********************************************************

Function parseVideoMediaInfo(metaData As Object, video As Object) As Object

    ' Setup Video / Audio / Subtitle Streams
    metaData.videoStream     = CreateObject("roAssociativeArray")
    metaData.audioStreams    = CreateObject("roArray", 2, true)
    metaData.subtitleStreams = CreateObject("roArray", 2, true)

    ' Determine Media Compatibility
    compatibleVideo      = false
    compatibleAudio      = false
    foundVideo           = false
    foundDefaultAudio    = false
    firstAudio           = true
    firstAudioChannels   = 0
    defaultAudioChannels = 0

    for each stream in video.MediaStreams

        if stream.Type = "Video" And foundVideo = false
            foundVideo = true
            streamBitrate = Int(stream.BitRate / 1000)

            if (stream.Codec = "h264" Or stream.Codec = "AVC") And stream.Level <= 41 And streamBitrate < 20000
                compatibleVideo = true
            end if

            ' Determine Full 1080p
            if stream.Height = 1080
                metaData.videoStream.FullHD = true
            end if

            ' Determine Frame Rate
            if stream.RealFrameRate <> invalid
                if stream.RealFrameRate >= 29
                    metaData.videoStream.FrameRate = 30
                else
                    metaData.videoStream.FrameRate = 24
                end if

            else if stream.AverageFrameRate <> invalid
                if stream.RealFrameRate >= 29
                    metaData.videoStream.FrameRate = 30
                else
                    metaData.videoStream.FrameRate = 24
                end if

            end if

        else if stream.Type = "Audio" 

            if firstAudio
                firstAudio = false
                firstAudioChannels = firstOf(stream.Channels, 2)

                ' Determine Compatible Audio (Default audio will override)
                if stream.Codec = "aac" Or (stream.Codec = "ac3" And getGlobalVar("audioOutput51")) Or (stream.Codec = "dca" And getGlobalVar("audioOutput51") And getGlobalVar("audioDTS"))
                    compatibleAudio = true
                end if
            end if

            ' Use Default To Determine Surround Sound
            if stream.IsDefault
                foundDefaultAudio = true

                channels = firstOf(stream.Channels, 2)
                defaultAudioChannels = channels
                if channels > 5
                    metaData.AudioFormat = "dolby-digital"
                end if
                
                ' Determine Compatible Audio
                if stream.Codec = "aac" Or (stream.Codec = "ac3" And getGlobalVar("audioOutput51")) Or (stream.Codec = "dca" And getGlobalVar("audioOutput51") And getGlobalVar("audioDTS"))
                    compatibleAudio = true
                else
                    compatibleAudio = false
                end if
            end if

            audioData = {}
            audioData.Title = ""

            ' Set Index
            audioData.Index = stream.Index

            ' Set Language
            if stream.Language <> invalid
                audioData.Title = formatLanguage(stream.Language)
            end if

            ' Set Description
            if stream.Profile <> invalid
                audioData.Title = audioData.Title + ", " + stream.Profile
            else if stream.Codec <> invalid
                audioData.Title = audioData.Title + ", " + stream.Codec
            end if

            ' Set Channels
            if stream.Channels <> invalid
                audioData.Title = audioData.Title + ", Channels: " + itostr(stream.Channels)
            end if

            metaData.audioStreams.push( audioData )

        else if stream.Type = "Subtitle" 

            subtitleData = {}
            subtitleData.Title = ""

            ' Set Index
            subtitleData.Index = stream.Index

            ' Set Language
            if stream.Language <> invalid
                subtitleData.Title = formatLanguage(stream.Language)
            end if

            metaData.subtitleStreams.push( subtitleData )

        end if

    end for

    ' If no default audio was found, use first audio stream
    if Not foundDefaultAudio
        defaultAudioChannels = firstAudioChannels
        if firstAudioChannels > 5
            metaData.AudioFormat = "dolby-digital"
        end if
    end if

    ' Set Video Compatibility And Direct Play
    metaData.CompatVideo = compatibleVideo
    metaData.CompatAudio = compatibleAudio

    ' Set the Default Audio Channels
    metaData.DefaultAudioChannels = defaultAudioChannels

    return metaData
End Function


'**********************************************************
'** Setup Video Playback
'**********************************************************

Function setupVideoPlayback(metadata As Object, options = invalid As Object) As Object

    ' Setup Video Playback
    videoType     = LCase(metadata.VideoType)
    locationType  = LCase(metadata.LocationType)
    rokuVersion   = getGlobalVar("rokuVersion")
    audioOutput51 = getGlobalVar("audioOutput51")
    supportsSurroundSound = getGlobalVar("surroundSound")

    ' Set Playback Options
    if options <> invalid
        audioStream    = firstOf(options.audio, false)
        subtitleStream = firstOf(options.subtitle, false)
        playStart      = firstOf(options.playstart, false)
    else
        audioStream    = false
        subtitleStream = false
        playStart      = false
    end if

    Print "Play Start: "; playStart
    Print "Audio Stream: "; audioStream
    Print "Subtitle Stream: "; subtitleStream

    if videoType = "videofile"
        extension = getFileExtension(metaData.VideoPath)

        if locationType = "remote"
            action = "transcode"

        else if locationType = "filesystem"

            if metadata.CompatVideo And ( (extension = "mp4" Or extension = "mpv") Or (extension = "mkv" And (rokuVersion[0] > 5 Or (rokuVersion[0] = 5 And rokuVersion[1] >= 1) ) ) )
                if Not audioOutput51 And metaData.DefaultAudioChannels > 2 Or (audioStream Or subtitleStream)
                    action = "streamcopy"
                else
                    if metadata.CompatAudio
                        action = "direct"
                    else
                        action = "streamcopy"
                    end if
                end if

            else
                if metadata.CompatVideo
                    action = "streamcopy"
                else
                    action = "transcode"
                end if
            end if

        end if

    else
        action = "transcode"
    end if

    Debug("Action For Video (" + metadata.Title + "): " + action)

    ' Get Video Bitrate
    videoBitrate = firstOf(RegRead("prefVideoQuality"), "3200")
    videoBitrate = videoBitrate.ToInt()

    streamParams = {}

    ' Direct Stream
    if action = "direct"
        streamParams.url = GetServerBaseUrl() + "/Videos/" + metadata.Id + "/stream." + extension + "?static=true"
        streamParams.bitrate = 0
        streamParams.quality = true
        streamParams.contentid = "x-direct"

        if extension = "mkv"
            metaData.videoStream.StreamFormat = "mkv"
        else
            metaData.videoStream.StreamFormat = "mp4"
        end if
        metaData.videoStream.Stream = streamParams

        ' Add Play Start
        if playStart
            metaData.videoStream.PlayStart = playStart
        end if

        ' Set Direct Play Flag
        metaData.DirectPlay = true

    ' Stream Copy
    else if action = "streamcopy"
        ' Base URL
        url = GetServerBaseUrl() + "/Videos/" + HttpEncode(metadata.Id) + "/stream.m3u8"

        ' Default Settings
        query = {
            VideoCodec: "copy"
            AudioCodec: "aac"
            AudioBitRate: "128000"
            AudioChannels: "2"
            AudioSampleRate: "44100"
            TimeStampOffsetMs: "0"
            DeviceId: getGlobalVar("rokuUniqueId", "Unknown")
        }

        ' Prepare Url
        request = HttpRequest(url)
        request.BuildQuery(query)

        ' Add Play Start
        if playStart
            playStartTicks = itostr(playStart) + "0000000"
            request.AddParam("StartTimeTicks", playStartTicks)
            metaData.videoStream.PlayStart = playStart
        end if

        ' Add Audio Stream
        if audioStream then request.AddParam("AudioStreamIndex", itostr(audioStream))

        ' Add Subtitle Stream
        if subtitleStream then request.AddParam("SubtitleStreamIndex", itostr(subtitleStream))

        ' Prepare Stream
        streamParams.url = request.GetUrl()
        streamParams.bitrate = 0
        streamParams.quality = true
        streamParams.contentid = "x-streamcopy"

        metaData.videoStream.StreamFormat = "hls"
        metaData.videoStream.Stream = streamParams

    ' Transcode
    else
        ' Base URL
        url = GetServerBaseUrl() + "/Videos/" + HttpEncode(metadata.Id) + "/stream.m3u8"

        ' Default Settings
        query = {
            VideoCodec: "h264"
            AudioCodec: "aac"
            AudioBitRate: "128000"
            AudioChannels: "2"
            AudioSampleRate: "44100"
            TimeStampOffsetMs: "0"
            DeviceId: getGlobalVar("rokuUniqueId", "Unknown")
        }

        ' Get Video Settings
        videoSettings = getVideoBitrateSettings(videoBitrate)
        query = AddToQuery(query, videoSettings)

        ' Prepare Url
        request = HttpRequest(url)
        request.BuildQuery(query)

        ' Add Play Start
        if playStart
            playStartTicks = itostr(playStart) + "0000000"
            request.AddParam("StartTimeTicks", playStartTicks)
            metaData.videoStream.PlayStart = playStart
        end if

        ' Add Audio Stream
        if audioStream then request.AddParam("AudioStreamIndex", itostr(audioStream))

        ' Add Subtitle Stream
        if subtitleStream then request.AddParam("SubtitleStreamIndex", itostr(subtitleStream))

        ' Prepare Stream
        streamParams.url = request.GetUrl()
        streamParams.bitrate = videoBitrate

        if videoBitrate > 700
            streamParams.quality = true
        else
            streamParams.quality = false
        end if

        streamParams.contentid = "x-transcode"

        metaData.videoStream.StreamFormat = "hls"
        metaData.videoStream.Stream = streamParams

    end if

    Print streamParams.url

    return metaData
End Function


'**********************************************************
'** Post Video Playback
'**********************************************************

Function postVideoPlayback(videoId As String, action As String, position = invalid) As Boolean

    ' Format Position Seconds into Ticks
    if position <> invalid
        positionTicks =  itostr(position) + "0000000"
    end if

    if action = "start"
        ' URL
        url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/PlayingItems/" + HttpEncode(videoId)

        ' Prepare Request
        request = HttpRequest(url)
        request.AddAuthorization()
    else if action = "progress"
        ' URL
        url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/PlayingItems/" + HttpEncode(videoId) + "/Progress?PositionTicks=" + positionTicks

        ' Prepare Request
        request = HttpRequest(url)
        request.AddAuthorization()
    else if action = "stop"
        ' URL
        url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/PlayingItems/" + HttpEncode(videoId) + "?PositionTicks=" + positionTicks

        ' Prepare Request
        request = HttpRequest(url)
        request.AddAuthorization()
        request.SetRequest("DELETE")
    end if

    ' Execute Request
    response = request.PostFromStringWithTimeout("", 5)
    if response <> invalid
        return true
    else
        Debug("Failed to Post Video Playback Progress")
    end if

    return false
End Function
