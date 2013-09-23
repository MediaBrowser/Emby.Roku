'*****************************************************************
'**  Media Browser Roku Client - Video Metadata Class
'*****************************************************************


Function ClassVideoMetadata()
    ' initializes static members once
    this = m.ClassVideoMetadata

    if this = invalid
        this = CreateObject("roAssociativeArray")

        ' constants
        this.class = "VideoMetadata"

        'variables


        ' functions
        this.GetDetails = videometadata_details

        ' singleton
        m.ClassVideoMetadata = this
    end if
    
    return this
End Function


Function InitVideoMetadata()
    this = ClassVideoMetadata()
    return this
End Function


'**********************************************************
'** Get Video Details
'**********************************************************

Function videometadata_details(videoId As String) As Object
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
            Debug("Error while parsing JSON response for Video Details")
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

        ' Set the Movie star rating
        if i.CriticRating <> invalid
            metaData.StarRating = i.CriticRating
        end if

        ' Set the Run Time
        if i.RunTimeTicks <> "" And i.RunTimeTicks <> invalid
            metaData.Length = Int(((i.RunTimeTicks).ToFloat() / 10000) / 1000)
        end if

        ' Set the Playback Position
        if i.UserData.PlaybackPositionTicks <> "" And i.UserData.PlaybackPositionTicks <> invalid
            metaData.PlaybackPosition = i.UserData.PlaybackPositionTicks
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
                    chapterData.ShortDescriptionLine2 = FormatChapterTime(c.StartPositionTicks)
                    chapterData.StartPositionTicks = c.StartPositionTicks
                end if

                ' Get Image Sizes
                sizes = GetImageSizes("flat-episodic-16x9")

                ' Check if Chapter has Image, otherwise use default
                if c.ImageTag <> "" And c.ImageTag <> invalid
                    imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.Id) + "/Images/Chapter/" + itostr(chapterCount)

                    chapterData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, c.ImageTag)
                    chapterData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, c.ImageTag)

                else 
                    chapterData.HDPosterUrl = "pkg://images/items/collection.png"
                    chapterData.SDPosterUrl = "pkg://images/items/collection.png"

                end if

                ' Increment Count
                chapterCount = chapterCount + 1

                metaData.Chapters.push( chapterData )
            end for

        end if

        ' Check Media Streams For HD Video And Surround Sound Audio
        ' Improve this
        streamInfo = GetStreamInfo(i.MediaStreams)

        metaData.HDBranded = streamInfo.isHDVideo
        metaData.IsHD = streamInfo.isHDVideo

        if streamInfo.isSSAudio = true
            metaData.AudioFormat = "dolby-digital"
        end if

        ' Setup Video Player
        ' Improve this
        streamData = SetupVideoStreams(movieId, i.VideoType, i.Path)

        if streamData <> invalid
            metaData.StreamData = streamData

            ' Determine Direct Play
            if StreamData.Stream <> invalid
                metaData.IsDirectPlay = true
            else
                metaData.IsDirectPlay = false
            end if
        end if

        ' Get Image Sizes
        if i.Type = "Episode"
            sizes = GetImageSizes("rounded-rect-16x9-generic")
        else
            sizes = GetImageSizes("movie")
        end if
        
        ' Check if Item has Image, otherwise use default
        if i.ImageTags.Primary <> "" And i.ImageTags.Primary <> invalid
            imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.Id) + "/Images/Primary/0"

            metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ImageTags.Primary)
            metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ImageTags.Primary)

        else 
            metaData.HDPosterUrl = "pkg://images/items/collection.png"
            metaData.SDPosterUrl = "pkg://images/items/collection.png"

        end if
        
        return metaData
    else
        Debug("Failed to Get Video Details")
    end if

    return invalid
End Function
