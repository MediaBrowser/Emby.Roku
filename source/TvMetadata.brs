'*****************************************************************
'**  Media Browser Roku Client - TV Metadata Class
'*****************************************************************


Function ClassTvMetadata()
    ' initializes static members once
    this = m.ClassTvMetadata

    if this = invalid
        this = CreateObject("roAssociativeArray")

        ' constants
        this.class        = "TvMetadata"

        'variables
        this.jumpList     = {}

        ' functions
        this.GetShowList  = tvmetadata_show_list
        this.GetResumable = tvmetadata_resumable
        this.GetLatest    = tvmetadata_latest
        this.GetNextUp    = tvmetadata_nextup
        this.GetGenres    = tvmetadata_genres
        this.GetSeasons   = tvmetadata_seasons
        this.GetEpisodes  = tvmetadata_episodes

        ' singleton
        m.ClassTvMetadata = this
    end if
    
    return this
End Function


Function InitTvMetadata()
    this = ClassTvMetadata()
    return this
End Function


'**********************************************************
'** Get All TV Shows From Server
'**********************************************************

Function tvmetadata_show_list() As Object
    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items"

    ' Query
    query = {
        recursive: "true"
        includeitemtypes: "Series"
        fields: "ItemCounts,SortName,Overview"
        sortby: "SortName"
        sortorder: "Ascending"
    }

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

        jumpListCount = 0
        contentList   = CreateObject("roArray", 25, true)
        items         = ParseJSON(response).Items

        for each i in items
            metaData = {}

            ' Set the Content Type
            metaData.ContentType = "Series"

            ' Set the Id
            metaData.Id = i.Id

            ' Show / Hide display title
            if RegRead("prefTVTitle") = "show" Or RegRead("prefTVTitle") = invalid
                metaData.ShortDescriptionLine1 = firstOf(i.Name, "Unknown")
            end if
            
            ' Set the Season count
            if i.ChildCount <> invalid
                metaData.ShortDescriptionLine2 = Pluralize(i.ChildCount, "season")
            end if

            '** PopUp Metadata **

            ' Set the display title
            metaData.Title = firstOf(i.Name, "Unknown")

            ' Set the Episode count
            if i.RecursiveItemCount <> invalid
                metaData.NumEpisodes = i.RecursiveItemCount
            end if

            ' Set the Series overview
            if i.Overview <> invalid
                metaData.Description = i.Overview
            end if

            ' Set the Series rating
            if i.OfficialRating <> invalid
                metaData.Rating = i.OfficialRating
            end if

            ' Set the Series star rating
            if i.CommunityRating <> invalid
                metaData.UserStarRating = Int(i.CommunityRating) * 10
            end if

            ' Add Item to Jump List
            if i.SortName <> invalid
                firstChar = Left(i.SortName, 1)
                if Not m.jumpList.DoesExist(firstChar)
                    m.jumpList.AddReplace(firstChar, jumpListCount)
                end if

            end if

            ' Increment Count
            jumpListCount = jumpListCount + 1

            ' Get Image Type From Preference
            if RegRead("prefTVImageType") = "poster"

                ' Get Image Sizes
                sizes = GetImageSizes("mixed-aspect-ratio-portrait")

                ' Check if Item has Image, otherwise use default
                if i.ImageTags.Primary <> "" And i.ImageTags.Primary <> invalid
                    imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.Id) + "/Images/Primary/0"

                    metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ImageTags.Primary)
                    metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ImageTags.Primary)

                else 
                    metaData.HDPosterUrl = "pkg://images/items/collection.png"
                    metaData.SDPosterUrl = "pkg://images/items/collection.png"

                end if

            else if RegRead("prefTVImageType") = "thumb"

                ' Get Image Sizes
                sizes = GetImageSizes("two-row-flat-landscape-custom")

                ' Check if Item has Image, otherwise use default
                if i.ImageTags.Thumb <> "" And i.ImageTags.Thumb <> invalid
                    imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.Id) + "/Images/Thumb/0"

                    metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ImageTags.Thumb)
                    metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ImageTags.Thumb)

                else 
                    metaData.HDPosterUrl = "pkg://images/items/collection.png"
                    metaData.SDPosterUrl = "pkg://images/items/collection.png"

                end if

            else

                ' Get Image Sizes
                sizes = GetImageSizes("two-row-flat-landscape-custom")

                ' Check if Item has Image, otherwise use default
                if i.BackdropImageTags[0] <> "" And i.BackdropImageTags[0] <> invalid
                    imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.Id) + "/Images/Backdrop/0"

                    metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.BackdropImageTags[0])
                    metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.BackdropImageTags[0])

                else 
                    metaData.HDPosterUrl = "pkg://images/items/collection.png"
                    metaData.SDPosterUrl = "pkg://images/items/collection.png"

                end if

            end if

            contentList.push( metaData )
        end for
        
        return contentList
    else
        Debug("Failed to Get TV Shows List")
    end if

    return invalid
End Function


'**********************************************************
'** Get Resumable TV From Server
'**********************************************************

Function tvmetadata_resumable() As Object
    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items"

    ' Query
    query = {
        limit: "10"
        recursive: "true"
        includeitemtypes: "Episode"
        fields: "SeriesInfo"
        sortby: "DatePlayed"
        sortorder: "Descending"
        filters: "IsResumable"
    }

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

        contentList = CreateObject("roArray", 10, true)
        items       = ParseJSON(response).Items

        for each i in items
            metaData = {}

            ' Set the Content Type
            metaData.ContentType = "Episode"

            ' Set the Id
            metaData.Id = i.Id

            ' Set the display title
            metaData.Title = firstOf(i.SeriesName, i.Name) ' Not even used
            metaData.ShortDescriptionLine1 = firstOf(i.SeriesName, i.Name)

            ' Build Episode Information for Line 2 Display
            episodeInfo = ""

            ' Add Season Number
            if i.ParentIndexNumber <> invalid
                episodeInfo = itostr(i.ParentIndexNumber)
            end if

            ' Add Episode Number
            if i.IndexNumber <> invalid
                episodeInfo = episodeInfo + "x" + ZeroPad(itostr(i.IndexNumber))
            end if

            ' Append Title if Season Or Episode Number have been added
            if episodeInfo <> ""
                episodeInfo = episodeInfo + " - " + i.Name
            else
                episodeInfo = i.Name
            end if

            ' Set the Line 2 display
            metaData.ShortDescriptionLine2 = episodeInfo

            ' Get Image Sizes
            sizes = GetImageSizes("two-row-flat-landscape-custom")

            ' Check if Item has Image, Check if Parent Item has Image, otherwise use default
            if i.BackdropImageTags[0] <> "" And i.BackdropImageTags[0] <> invalid
                imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.Id) + "/Images/Backdrop/0"

                metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.BackdropImageTags[0])
                metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.BackdropImageTags[0])

            else if i.ImageTags.Primary <> "" And i.ImageTags.Primary <> invalid
                imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.Id) + "/Images/Primary/0"

                metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ImageTags.Primary)
                metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ImageTags.Primary)

            else 
                metaData.HDPosterUrl = "pkg://images/items/collection.png"
                metaData.SDPosterUrl = "pkg://images/items/collection.png"

            end if

            contentList.push( metaData )
        end for
        
        return contentList
    else
        Debug("Failed to Get Resumable TV Shows")
    end if

    return invalid
End Function


'**********************************************************
'** Get Latest Unwatched TV Episodes From Server
'**********************************************************

Function tvmetadata_latest() As Object
    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items"

    ' Query
    query = {
        limit: "10"
        recursive: "true"
        includeitemtypes: "Episode"
        fields: "SeriesInfo,UserData"
        sortby: "DateCreated"
        sortorder: "Descending"
        filters: "IsUnplayed"
    }

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

        contentList = CreateObject("roArray", 10, true)
        items       = ParseJSON(response).Items

        for each i in items
            metaData = {}

            ' Set the Content Type
            metaData.ContentType = "Episode"

            ' Set the Id
            metaData.Id = i.Id

            ' Set the display title
            metaData.Title = firstOf(i.SeriesName, i.Name) ' Not even used
            metaData.ShortDescriptionLine1 = firstOf(i.SeriesName, i.Name)

            ' Build Episode Information for Line 2 Display
            episodeInfo = ""

            ' Add Season Number
            if i.ParentIndexNumber <> invalid
                episodeInfo = itostr(i.ParentIndexNumber)
            end if

            ' Add Episode Number
            if i.IndexNumber <> invalid
                episodeInfo = episodeInfo + "x" + ZeroPad(itostr(i.IndexNumber))
            end if

            ' Append Title if Season Or Episode Number have been added
            if episodeInfo <> ""
                episodeInfo = episodeInfo + " - " + i.Name
            else
                episodeInfo = i.Name
            end if

            ' Set the Line 2 display
            metaData.ShortDescriptionLine2 = episodeInfo

            ' Get Image Sizes
            sizes = GetImageSizes("two-row-flat-landscape-custom")

            ' Check if Item has Image, Check if Parent Item has Image, otherwise use default
            if i.BackdropImageTags[0] <> "" And i.BackdropImageTags[0] <> invalid
                imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.Id) + "/Images/Backdrop/0"

                metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.BackdropImageTags[0])
                metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.BackdropImageTags[0])

            else if i.ImageTags.Primary <> "" And i.ImageTags.Primary <> invalid
                imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.Id) + "/Images/Primary/0"

                metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ImageTags.Primary)
                metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ImageTags.Primary)

            else 
                metaData.HDPosterUrl = "pkg://images/items/collection.png"
                metaData.SDPosterUrl = "pkg://images/items/collection.png"

            end if

            contentList.push( metaData )
        end for
        
        return contentList
    else
        Debug("Failed to Get Recently Added TV Shows")
    end if

    return invalid
End Function


'**********************************************************
'** Get Next Unwatched TV Episodes From Server
'**********************************************************

Function tvmetadata_nextup() As Object
    ' URL
    url = GetServerBaseUrl() + "/Shows/NextUp"

    ' Query
    query = {
        userid: HttpEncode(getGlobalVar("user").Id)
        limit: "10"
        fields: "SeriesInfo,DateCreated,Overview"
    }

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

        ' Fixes bug within BRS Json Parser
        regex         = CreateObject("roRegex", Chr(34) + "(RunTimeTicks)" + Chr(34) + ":(-?[0-9]+),", "i")
        fixedResponse = regex.ReplaceAll(response, Chr(34) + "\1" + Chr(34) + ":" + Chr(34) + "\2" + Chr(34) + ",")

        contentList = CreateObject("roArray", 10, true)
        items       = ParseJSON(fixedResponse).Items

        for each i in items
            metaData = {}

            ' Set the Content Type
            metaData.ContentType = "Episode"

            ' Set the Id
            metaData.Id = i.Id

            ' Set the display title
            metaData.ShortDescriptionLine1 = firstOf(i.SeriesName, i.Name)

            ' Build Episode Information for Line 2 Display
            episodeInfo = ""

            ' Add Season Number
            if i.ParentIndexNumber <> invalid
                episodeInfo = itostr(i.ParentIndexNumber)
            end if

            ' Add Episode Number
            if i.IndexNumber <> invalid
                episodeInfo = episodeInfo + "x" + ZeroPad(itostr(i.IndexNumber))
            end if

            ' Append Title if Season Or Episode Number have been added
            if episodeInfo <> ""
                episodeInfo = episodeInfo + " - " + i.Name
            else
                episodeInfo = i.Name
            end if

            ' Set the Line 2 display
            metaData.ShortDescriptionLine2 = episodeInfo

            '** PopUp Metadata **

            ' Set the display title
            metaData.Title = firstOf(i.SeriesName, i.Name, "Unknown") + ": " + episodeInfo

            ' Set the Release Date
            if isInt(i.ProductionYear)
                metaData.ReleaseDate = itostr(i.ProductionYear)
            end if

            ' Set the Run Time
            if i.RunTimeTicks <> "" And i.RunTimeTicks <> invalid
                metaData.Length = Int(((i.RunTimeTicks).ToFloat() / 10000) / 1000)
            end if

            ' Set the Episode overview
            if i.Overview <> invalid
                metaData.Description = i.Overview
            end if

            ' Get Image Type From Preference
            if RegRead("prefTVImageType") = "poster"
                ' Get Image Sizes
                sizes = GetImageSizes("mixed-aspect-ratio-landscape")

            else
                ' Get Image Sizes
                sizes = GetImageSizes("two-row-flat-landscape-custom")

            end if

            ' Check if Item has Image, Check if Parent Item has Image, otherwise use default
            if i.BackdropImageTags[0] <> "" And i.BackdropImageTags[0] <> invalid
                imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.Id) + "/Images/Backdrop/0"

                metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.BackdropImageTags[0])
                metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.BackdropImageTags[0])

            else if i.ImageTags.Primary <> "" And i.ImageTags.Primary <> invalid
                imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.Id) + "/Images/Primary/0"

                metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ImageTags.Primary)
                metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ImageTags.Primary)

            else 
                metaData.HDPosterUrl = "pkg://images/items/collection.png"
                metaData.SDPosterUrl = "pkg://images/items/collection.png"

            end if

            contentList.push( metaData )
        end for
        
        return contentList
    else
        Debug("Failed to Get Next Episodes to Watch for TV Shows")
    end if

    return invalid
End Function


'**********************************************************
'** Get TV Genres From Server
'**********************************************************

Function tvmetadata_genres() As Object
    ' URL
    url = GetServerBaseUrl() + "/Genres"

    ' Query
    query = {
        userid: HttpEncode(getGlobalVar("user").Id)
        recursive: "true"
        includeitemtypes: "Series"
        fields: "ItemCounts"
        sortby: "SortName"
        sortorder: "Ascending"
    }

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

        contentList = CreateObject("roArray", 10, true)
        items       = ParseJSON(response).Items

        for each i in items
            metaData = {}

            ' Set the Content Type
            metaData.ContentType = "Genre"

            ' Set the Id
            ' Genres Use Name as Id
            metaData.Id = firstOf(i.Name, "Unknown")

            ' Set the display title
            metaData.Title = firstOf(i.Name, "Unknown")
            metaData.ShortDescriptionLine1 = firstOf(i.Name, "Unknown")

            ' Set Series Count
            if i.ChildCount <> invalid
                metaData.ShortDescriptionLine2 = itostr(i.ChildCount) + " shows"
            end if

            ' Get Image Type From Preference
            if RegRead("prefTVImageType") = "poster"
                ' Get Image Sizes
                sizes = GetImageSizes("mixed-aspect-ratio-landscape")

                ' Check If Item has Image, otherwise use default
                if i.ImageTags.Primary <> "" And i.ImageTags.Primary <> invalid
                    imageUrl = GetServerBaseUrl() + "/Genres/" + HttpEncode(i.Name) + "/Images/Primary/0"

                    metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ImageTags.Primary)
                    metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ImageTags.Primary)

                else 
                    metaData.HDPosterUrl = "pkg://images/items/collection.png"
                    metaData.SDPosterUrl = "pkg://images/items/collection.png"

                end if

            else
                ' Get Image Sizes
                sizes = GetImageSizes("two-row-flat-landscape-custom")


                ' Check if Item has Image, Check if Parent Item has Image, otherwise use default
                if i.ImageTags.Primary <> "" And i.ImageTags.Primary <> invalid
                    imageUrl = GetServerBaseUrl() + "/Genres/" + HttpEncode(i.Name) + "/Images/Primary/0"

                    metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ImageTags.Primary)
                    metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ImageTags.Primary)

                else if i.BackdropImageTags[0] <> "" And i.BackdropImageTags[0] <> invalid
                    imageUrl = GetServerBaseUrl() + "/Genres/" + HttpEncode(i.Name) + "/Images/Backdrop/0"

                    metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.BackdropImageTags[0])
                    metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.BackdropImageTags[0])

                else 
                    metaData.HDPosterUrl = "pkg://images/items/collection.png"
                    metaData.SDPosterUrl = "pkg://images/items/collection.png"

                end if

            end if

            contentList.push( metaData )
        end for
        
        return contentList
    else
        Debug("Failed to Get Genres for TV Shows")
    end if

    return invalid
End Function


'**********************************************************
'** Get TV Seasons for Show From Server
'**********************************************************

Function tvmetadata_seasons(seriesId As String) As Object
    ' Validate Parameter
    if validateParam(seriesId, "roString", "tvmetadata_seasons") = false return invalid

    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items"

    ' Query
    query = {
        parentid: seriesId
        recursive: "true"
        includeitemtypes: "Season"
        sortby: "SortName"
        sortorder: "Ascending"
    }

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

        listIds   = CreateObject("roArray", 7, true)
        listNames = CreateObject("roArray", 7, true)
        items     = ParseJSON(response).Items

        for each i in items
            ' Set the Id
            listIds.push( i.Id )

            ' Set the Name
            listNames.push( firstOf(i.Name, "Unknown") )
        end for
        
        return [listIds, listNames]
    else
        Debug("Failed to Get TV Seasons List for Show")
    end if

    return invalid
End Function


'**********************************************************
'** Get TV Episodes in a Season From Server
'**********************************************************

Function tvmetadata_episodes(seasonId As String) As Object
    ' Validate Parameter
    if validateParam(seasonId, "roString", "tvmetadata_episodes") = false return invalid

    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items"

    ' Query
    query = {
        parentid: seasonId
        recursive: "true"
        includeitemtypes: "Episode"
        fields: "SeriesInfo,Overview,MediaStreams,UserData"
        sortby: "SortName"
        sortorder: "Ascending"
    }

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

        ' Fixes bug within BRS Json Parser
        regex         = CreateObject("roRegex", Chr(34) + "(RunTimeTicks|PlaybackPositionTicks)" + Chr(34) + ":(-?[0-9]+),", "i")
        fixedResponse = regex.ReplaceAll(response, Chr(34) + "\1" + Chr(34) + ":" + Chr(34) + "\2" + Chr(34) + ",")

        contentList = CreateObject("roArray", 10, true)
        items       = ParseJSON(fixedResponse).Items

        for each i in items
            metaData = {}

            ' Set the Content Type
            metaData.ContentType = "Episode"

            ' Set the Id
            metaData.Id = i.Id

            ' Set the display title
            metaData.Title = firstOf(i.Name, "Unknown")
            metaData.ShortDescriptionLine1 = firstOf(i.Name, "Unknown")

            ' Set the Run Time
            if i.RunTimeTicks <> "" And i.RunTimeTicks <> invalid
                metaData.Length = Int(((i.RunTimeTicks).ToFloat() / 10000) / 1000)
            end if

            ' Set the Playback Position
            if i.UserData.PlaybackPositionTicks <> "" And i.UserData.PlaybackPositionTicks <> invalid
                metaData.BookmarkPosition = Int(((i.UserData.PlaybackPositionTicks).ToFloat() / 10000) / 1000)
            end if

            ' Set the Overview
            if i.Overview <> invalid
                metaData.Description = i.Overview
            end if

            ' Build Episode Information for Line 2 Display
            episodeInfo = ""

            ' Add Season Number
            if i.ParentIndexNumber <> invalid
                episodeInfo = "Sn " + itostr(i.ParentIndexNumber)
            end if

            ' Add Episode Number
            if i.IndexNumber <> invalid
                if episodeInfo <> ""
                    episodeInfo = episodeInfo + " / "
                end if
                
                episodeInfo = episodeInfo + "Ep " + ZeroPad(itostr(i.IndexNumber))
            end if

            ' Set the Episode rating
            if i.OfficialRating <> "" And i.OfficialRating <> invalid
                if episodeInfo <> ""
                    episodeInfo = episodeInfo + " | "
                end if

                episodeInfo = episodeInfo + firstOf(i.OfficialRating, "")
            end if

            ' Check Media Streams For HD Video And Surround Sound Audio
            ' Fix me
            streamInfo = GetStreamInfo(i.MediaStreams)

            ' Set HD Video Flag
            if streamInfo.isHDVideo = true
                episodeInfo = episodeInfo + " | HD" 
            end if

            ' Set Surround Sound Flag    
            if streamInfo.isSSAudio = true
                episodeInfo = episodeInfo + " | 5.1" 
            end if

            ' Set the Line 2 display
            metaData.ShortDescriptionLine2 = episodeInfo

            ' Get Image Sizes
            sizes = GetImageSizes("flat-episodic-16x9")

            ' Check if Item has Image, otherwise use default
            if i.ImageTags.Primary <> "" And i.ImageTags.Primary <> invalid
                imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.Id) + "/Images/Primary/0"

                metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ImageTags.Primary)
                metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ImageTags.Primary)

            else 
                metaData.HDPosterUrl = "pkg://images/items/collection.png"
                metaData.SDPosterUrl = "pkg://images/items/collection.png"

            end if

            contentList.push( metaData )
        end for
        
        return contentList
    else
        Debug("Failed to Get TV Episodes List For Season")
    end if

    return invalid
End Function
