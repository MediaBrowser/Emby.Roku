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
        this.GetShowList       = tvmetadata_show_list
        this.GetNextUp         = tvmetadata_nextup
        this.GetGenres         = tvmetadata_genres
        this.GetGenreShowList  = tvmetadata_genre_show_list
        this.GetSeasons        = tvmetadata_seasons
        this.GetEpisodes       = tvmetadata_episodes
        this.GetEpisodeDetails = tvmetadata_episode_details
        this.GetResumable      = tvmetadata_resumable
        this.GetLatest         = tvmetadata_latest
        this.GetThemeMusic     = tvmetadata_theme_music
        this.GetNextEpisode    = tvmetadata_episodes_next_unplayed

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
'** Get All TV Shows
'**********************************************************

Function tvmetadata_show_list(offset = invalid As Dynamic, limit = invalid As Dynamic, filters = invalid As Object) As Object
    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items"

    ' Query
    query = {
        recursive: "true"
        includeitemtypes: "Series"
        fields: "SeriesInfo,ItemCounts,Overview"
        sortby: "SortName"
        sortorder: "Ascending"
    }

    ' Filter/Sort Query
    if filters <> invalid
        query = AddToQuery(query, filters)
    end if

    ' Paging
    if limit <> invalid And offset <> invalid
        query.AddReplace("startindex", itostr(offset))
        query.AddReplace("limit", itostr(limit))
    end if    

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

        contentList   = CreateObject("roArray", 25, true)
        jsonObj       = ParseJSON(response)

        if jsonObj = invalid
            Debug("Error while parsing JSON response for TV Shows List")
            return invalid
        end if

        totalRecordCount = jsonObj.TotalRecordCount

        for each i in jsonObj.Items
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
            if i.SeasonCount <> invalid
                metaData.ShortDescriptionLine2 = Pluralize(i.SeasonCount, "season")
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

            ' Get Image Type From Preference
            if RegRead("prefTVImageType") = "poster"

                ' Get Image Sizes
                sizes = GetImageSizes("mixed-aspect-ratio-portrait")

                ' Check if Item has Image, otherwise use default
                if i.ImageTags.Primary <> "" And i.ImageTags.Primary <> invalid
                    imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.Id) + "/Images/Primary/0"

                    if i.UserData.Played = true
                        metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ImageTags.Primary, i.UserData.Played)
                        metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ImageTags.Primary, i.UserData.Played)
                    else if i.UserData.Played = false And i.PlayedPercentage <> 100 
                        metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ImageTags.Primary, i.UserData.Played, i.PlayedPercentage)
                        metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ImageTags.Primary, i.UserData.Played, i.PlayedPercentage)
                    else
                        metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ImageTags.Primary)
                        metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ImageTags.Primary)
                    end if

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

                    if i.UserData.Played = true
                        metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ImageTags.Thumb, i.UserData.Played)
                        metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ImageTags.Thumb, i.UserData.Played)
                    else if i.UserData.Played = false And i.PlayedPercentage <> 100 
                        metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ImageTags.Thumb, i.UserData.Played, i.PlayedPercentage)
                        metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ImageTags.Thumb, i.UserData.Played, i.PlayedPercentage)
                    else
                        metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ImageTags.Thumb)
                        metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ImageTags.Thumb)
                    end if

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

                    if i.UserData.Played = true
                        metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.BackdropImageTags[0], i.UserData.Played)
                        metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.BackdropImageTags[0], i.UserData.Played)
                    else if i.UserData.Played = false And i.PlayedPercentage <> 100 
                        metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.BackdropImageTags[0], i.UserData.Played, i.PlayedPercentage)
                        metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.BackdropImageTags[0], i.UserData.Played, i.PlayedPercentage)
                    else
                        metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.BackdropImageTags[0])
                        metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.BackdropImageTags[0])
                    end if

                else 
                    metaData.HDPosterUrl = "pkg://images/items/collection.png"
                    metaData.SDPosterUrl = "pkg://images/items/collection.png"

                end if

            end if

            contentList.push( metaData )
        end for

        return {
            Items: contentList
            TotalCount: totalRecordCount
        }
    else
        Debug("Failed to Get TV Shows List")
    end if

    return invalid
End Function


'**********************************************************
'** Get Resumable TV
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
        jsonObj     = ParseJSON(response)

        if jsonObj = invalid
            Debug("Error while parsing JSON response for Resumable TV Shows")
            return invalid
        end if

        totalRecordCount = jsonObj.TotalRecordCount

        for each i in jsonObj.Items
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

        return {
            Items: contentList
            TotalCount: totalRecordCount
        }
    else
        Debug("Failed to Get Resumable TV Shows")
    end if

    return invalid
End Function


'**********************************************************
'** Get Latest Unwatched TV Episodes
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
        jsonObj     = ParseJSON(response)

        if jsonObj = invalid
            Debug("Error while parsing JSON response for Recently Added TV Shows")
            return invalid
        end if

        totalRecordCount = jsonObj.TotalRecordCount

        for each i in jsonObj.Items
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

        return {
            Items: contentList
            TotalCount: totalRecordCount
        }
    else
        Debug("Failed to Get Recently Added TV Shows")
    end if

    return invalid
End Function


'**********************************************************
'** Get Next Unwatched TV Episodes
'**********************************************************

Function tvmetadata_nextup(offset = invalid As Dynamic, limit = invalid As Dynamic) As Object
    ' URL
    url = GetServerBaseUrl() + "/Shows/NextUp"

    ' Query
    query = {
        userid: getGlobalVar("user").Id
        fields: "SeriesInfo,DateCreated,Overview"
    }

    ' Paging
    if limit <> invalid And offset <> invalid
        query.AddReplace("startindex", itostr(offset))
        query.AddReplace("limit", itostr(limit))
    end if    

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
        jsonObj     = ParseJSON(fixedResponse)

        if jsonObj = invalid
            Debug("Error while parsing JSON response for Next Episodes to Watch for TV Shows")
            return invalid
        end if

        totalRecordCount = jsonObj.TotalRecordCount

        for each i in jsonObj.Items
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
                sizes = GetImageSizes("mixed-aspect-ratio-portrait")

                if i.ParentArtItemId <> "" And i.ParentArtItemId <> invalid
                    imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.ParentArtItemId) + "/Images/Primary/0"

                    metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ParentArtItemId)
                    metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ParentArtItemId)

                else 
                    metaData.HDPosterUrl = "pkg://images/items/collection.png"
                    metaData.SDPosterUrl = "pkg://images/items/collection.png"

                end if

            else
                ' Get Image Sizes
                sizes = GetImageSizes("two-row-flat-landscape-custom")

                if i.ImageTags.Primary <> "" And i.ImageTags.Primary <> invalid
                    imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.Id) + "/Images/Primary/0"

                    metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ImageTags.Primary)
                    metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ImageTags.Primary)

                else 
                    metaData.HDPosterUrl = "pkg://images/items/collection.png"
                    metaData.SDPosterUrl = "pkg://images/items/collection.png"

                end if

            end if

            contentList.push( metaData )
        end for

        return {
            Items: contentList
            TotalCount: totalRecordCount
        }
    else
        Debug("Failed to Get Next Episodes to Watch for TV Shows")
    end if

    return invalid
End Function


'**********************************************************
'** Get TV Genres
'**********************************************************

Function tvmetadata_genres(offset = invalid As Dynamic, limit = invalid As Dynamic) As Object
    ' URL
    url = GetServerBaseUrl() + "/Genres"

    ' Query
    query = {
        userid: getGlobalVar("user").Id
        recursive: "true"
        includeitemtypes: "Series"
        fields: "ItemCounts"
        sortby: "SortName"
        sortorder: "Ascending"
    }

    ' Paging
    if limit <> invalid And offset <> invalid
        query.AddReplace("startindex", itostr(offset))
        query.AddReplace("limit", itostr(limit))
    end if    

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

        contentList = CreateObject("roArray", 10, true)
        jsonObj     = ParseJSON(response)

        if jsonObj = invalid
            Debug("Error while parsing JSON response for Genres for TV Shows")
            return invalid
        end if

        totalRecordCount = jsonObj.TotalRecordCount

        for each i in jsonObj.Items
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
            if i.SeriesCount <> invalid
                metaData.ShortDescriptionLine2 = Pluralize(i.SeriesCount, "show")
                metaData.Description = Pluralize(i.SeriesCount, "show")
            end if

            ' Get Image Type From Preference
            if RegRead("prefTVImageType") = "poster"
                ' Get Image Sizes
                sizes = GetImageSizes("mixed-aspect-ratio-portrait")

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


                ' Use Backdrop Image Or Primary
                if i.BackdropImageTags[0] <> "" And i.BackdropImageTags[0] <> invalid
                    imageUrl = GetServerBaseUrl() + "/Genres/" + HttpEncode(i.Name) + "/Images/Backdrop/0"

                    metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.BackdropImageTags[0])
                    metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.BackdropImageTags[0])

                else if i.ImageTags.Primary <> "" And i.ImageTags.Primary <> invalid
                    imageUrl = GetServerBaseUrl() + "/Genres/" + HttpEncode(i.Name) + "/Images/Primary/0"

                    metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ImageTags.Primary)
                    metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ImageTags.Primary)

                else 
                    metaData.HDPosterUrl = "pkg://images/items/collection.png"
                    metaData.SDPosterUrl = "pkg://images/items/collection.png"

                end if

            end if

            contentList.push( metaData )
        end for

        return {
            Items: contentList
            TotalCount: totalRecordCount
        }
    else
        Debug("Failed to Get Genres for TV Shows")
    end if

    return invalid
End Function


'**********************************************************
'** Get TV Seasons for Show
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
        jsonObj   = ParseJSON(response)

        if jsonObj = invalid
            Debug("Error while parsing JSON response for TV Seasons List for Show")
            return invalid
        end if

        for each i in jsonObj.Items
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
'** Get TV Episodes in a Season
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
        jsonObj     = ParseJSON(fixedResponse)

        if jsonObj = invalid
            Debug("Error while parsing JSON response for TV Episodes List For Season")
            return invalid
        end if

        totalRecordCount = jsonObj.TotalRecordCount

        for each i in jsonObj.Items
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
                
                episodeInfo = episodeInfo + "Ep " + itostr(i.IndexNumber)

                ' Add Double Episode Number
                if i.IndexNumberEnd <> invalid
                    episodeInfo = episodeInfo + "-" + itostr(i.IndexNumberEnd)
                end if
            end if

            ' Set the Episode rating
            if i.OfficialRating <> "" And i.OfficialRating <> invalid
                if episodeInfo <> ""
                    episodeInfo = episodeInfo + " | "
                end if

                episodeInfo = episodeInfo + firstOf(i.OfficialRating, "")
            end if

            ' Set HD Video Flag
            if i.IsHd <> invalid
                if i.IsHd then episodeInfo = episodeInfo + " | HD" 
            end if

            ' Set Surround Sound Flag    
            'if streamInfo.isSSAudio = true
            '    episodeInfo = episodeInfo + " | 5.1" 
            'end if

            ' Set the Line 2 display
            metaData.ShortDescriptionLine2 = episodeInfo

            ' Get Image Sizes
            sizes = GetImageSizes("flat-episodic-16x9")

            ' Check if Item has Image, otherwise use default
            if i.ImageTags.Primary <> "" And i.ImageTags.Primary <> invalid
                imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.Id) + "/Images/Primary/0"

                if i.UserData.Played <> invalid
                    metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ImageTags.Primary, i.UserData.Played)
                    metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ImageTags.Primary, i.UserData.Played)
                else
                    metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ImageTags.Primary)
                    metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ImageTags.Primary)
                end if

            else 
                metaData.HDPosterUrl = "pkg://images/items/collection.png"
                metaData.SDPosterUrl = "pkg://images/items/collection.png"

            end if

            contentList.push( metaData )
        end for

        return {
            Items: contentList
            TotalCount: totalRecordCount
        }
    else
        Debug("Failed to Get TV Episodes List For Season")
    end if

    return invalid
End Function


'**********************************************************
'** Get TV Shows in a Genre
'**********************************************************

Function tvmetadata_genre_show_list(genreName As String) As Object
    ' Validate Parameter
    if validateParam(genreName, "roString", "tvmetadata_genre_show_list") = false return invalid

    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items"

    ' Query
    query = {
        genres: genreName
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

        contentList = CreateObject("roArray", 25, true)
        jsonObj     = ParseJSON(response)

        if jsonObj = invalid
            Debug("Error while parsing JSON response for TV Shows List In Genre")
            return invalid
        end if

        totalRecordCount = jsonObj.TotalRecordCount

        for each i in jsonObj.Items
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
            if i.SeasonCount <> invalid
                metaData.ShortDescriptionLine2 = Pluralize(i.SeasonCount, "season")
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

        return {
            Items: contentList
            TotalCount: totalRecordCount
        }
    else
        Debug("Failed to Get TV Shows List In Genre")
    end if

    return invalid
End Function


'**********************************************************
'** Get TV Episode Details (deprecated)
'**********************************************************

Function tvmetadata_episode_details(episodeId As String) As Object
    ' Validate Parameter
    if validateParam(episodeId, "roString", "tvmetadata_episode_details") = false return invalid

    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items/" + HttpEncode(episodeId)

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
            Debug("Error while parsing JSON response for TV Episode Details")
            return invalid
        end if

        metaData = {}

        ' Set the Content Type
        metaData.ContentType = "Episode"

        ' Set the Id
        metaData.Id = i.Id

        'metaData.ContentId = i.Id ' Not sure it Is needed

        ' Set the display title
        metaData.Title = firstOf(i.Name, "Unknown")

        ' Set the display series title
        if i.SeriesName <> invalid
            metaData.SeriesTitle = i.SeriesName
        end if

        ' Set the Overview
        if i.Overview <> invalid
            metaData.Description = i.Overview
        end if

        ' Set the Episode Rating
        if i.OfficialRating <> invalid
            metaData.Rating = i.OfficialRating
        end if

        ' Set the Release Date
        if isInt(i.ProductionYear)
            metaData.ReleaseDate = itostr(i.ProductionYear)
        end if

        ' Set the Run Time
        if i.RunTimeTicks <> "" And i.RunTimeTicks <> invalid
            metaData.Length = Int(((i.RunTimeTicks).ToFloat() / 10000) / 1000)
        end if

        ' Set the Playback Position
        if i.UserData.PlaybackPositionTicks <> "" And i.UserData.PlaybackPositionTicks <> invalid
            metaData.PlaybackPosition = i.UserData.PlaybackPositionTicks
        end if

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
        streamData = SetupVideoStreams(episodeId, i.VideoType, i.Path)

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
        sizes = GetImageSizes("rounded-rect-16x9-generic")

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
        Debug("Failed to Get TV Episode Details")
    end if

    return invalid
End Function


'**********************************************************
'** Get TV Show Theme Music
'**********************************************************

Function tvmetadata_theme_music(seriesId As String) As Object
    ' Validate Parameter
    if validateParam(seriesId, "roString", "tvmetadata_theme_music") = false return invalid

    ' URL
    url = GetServerBaseUrl() + "/Items/" + HttpEncode(seriesId) + "/ThemeSongs"

    ' Query
    query = {
        userid: getGlobalVar("user").Id
    }

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

        contentList = CreateObject("roArray", 2, true)
        jsonObj     = ParseJSON(response)

        if jsonObj = invalid
            Debug("Error while parsing JSON response for TV Show Theme Music")
            return invalid
        end if

        for each i in jsonObj.Items
            metaData = {}

            ' Set Theme Songs
            if i.Id <> invalid And i.Path <> invalid
                metaData = SetupAudioStream(i.Id, i.Path)
            end if

            contentList.push( metaData )
        end for
        
        return contentList
    else
        Debug("Failed to Get TV Show Theme Music")
    end if

    return invalid
End Function


'**********************************************************
'** Get TV Show Next Unplayed Episode
'**********************************************************

Function tvmetadata_episodes_next_unplayed(seriesId As String) As Object
    ' Validate Parameter
    if validateParam(seriesId, "roString", "tvmetadata_episodes_next_unplayed") = false return invalid

    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items"

    ' Query
    query = {
        parentid: seriesId
        recursive: "true"
        includeitemtypes: "Episode"
        sortby: "SortName"
        sortorder: "Ascending"
        filters: "IsUnplayed"
        limit: "1"
    }

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

        jsonObj = ParseJSON(response)

        if jsonObj = invalid
            Debug("Error while parsing JSON response for TV Show Next Unplayed Episode")
            return invalid
        end if

        if jsonObj.TotalRecordCount = 0
            return invalid
        end if
        
        i = jsonObj.Items[0]

        metaData = {}

        ' Set Season Number
        if i.ParentIndexNumber <> invalid
            metaData.Season = i.ParentIndexNumber
        end if

        ' Set Episode Number
        if i.IndexNumber <> invalid
            metaData.Episode = i.IndexNumber
        end if

        return metaData
    else
        Debug("Failed to Get TV Show Next Unplayed Episode")
    end if

    return invalid
End Function
