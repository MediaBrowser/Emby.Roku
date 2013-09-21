'*****************************************************************
'**  Media Browser Roku Client - Movie Metadata Class
'*****************************************************************


Function ClassMovieMetadata()
    ' initializes static members once
    this = m.ClassMovieMetadata

    if this = invalid
        this = CreateObject("roAssociativeArray")

        ' constants
        this.class        = "MovieMetadata"

        'variables
        this.jumpList     = {}

        ' functions
        this.GetMovieList       = moviemetadata_movie_list
        this.GetBoxsets         = moviemetadata_boxsets
        this.GetBoxsetMovieList = moviemetadata_boxset_movie_list
        this.GetGenres          = moviemetadata_genres
        this.GetGenreMovieList  = moviemetadata_genre_movie_list
        this.GetResumable       = moviemetadata_resumable
        this.GetLatest          = moviemetadata_latest
        this.GetMovieDetails    = moviemetadata_movie_details

        ' singleton
        m.ClassMovieMetadata = this
    end if
    
    return this
End Function


Function InitMovieMetadata()
    this = ClassMovieMetadata()
    return this
End Function


'**********************************************************
'** Get All Movies
'**********************************************************

Function moviemetadata_movie_list(offset = invalid As Dynamic, limit = invalid As Dynamic, filters = invalid As Object) As Object
    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items"

    ' Query
    query = {
        recursive: "true"
        includeitemtypes: "Movie"
        fields: "Overview,UserData"
        sortby: "SortName"
        sortorder: "Ascending"
    }

    ' Filter/Sort Query
    if filters <> invalid
        query = FilterQuery(query, filters)
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

        ' Fixes bug within BRS Json Parser
        regex         = CreateObject("roRegex", Chr(34) + "(RunTimeTicks|PlaybackPositionTicks)" + Chr(34) + ":(-?[0-9]+),", "i")
        fixedResponse = regex.ReplaceAll(response, Chr(34) + "\1" + Chr(34) + ":" + Chr(34) + "\2" + Chr(34) + ",")

        contentList   = CreateObject("roArray", 25, true)
        jsonObj       = ParseJSON(fixedResponse)

        if jsonObj = invalid
            Debug("Error while parsing JSON response for Movies List")
            return invalid
        end if

        totalRecordCount = jsonObj.TotalRecordCount

        for each i in jsonObj.Items
            metaData = {}

            ' Set the Content Type
            metaData.ContentType = "Movie"

            ' Set the Id
            metaData.Id = i.Id

            ' Show / Hide display title
            if RegRead("prefMovieTitle") = "show" Or RegRead("prefMovieTitle") = invalid
                metaData.ShortDescriptionLine1 = firstOf(i.Name, "Unknown")
            end if

            '** PopUp Metadata **

            ' Set the display title
            metaData.Title = firstOf(i.Name, "Unknown")

            ' Set the Run Time
            if i.RunTimeTicks <> "" And i.RunTimeTicks <> invalid
                metaData.Length = Int(((i.RunTimeTicks).ToFloat() / 10000) / 1000)
            end if

            ' Set the Overview
            if i.Overview <> invalid
                metaData.Description = i.Overview
            end if

            ' Set the Official Rating
            if i.OfficialRating <> invalid
                metaData.Rating = i.OfficialRating
            end if

            ' Set the Star rating
            if i.CommunityRating <> invalid
                metaData.UserStarRating = Int(i.CommunityRating) * 10
            end if

            ' Set the Release Date
            if isInt(i.ProductionYear)
                metaData.ReleaseDate = itostr(i.ProductionYear)
            end if

            ' Set the HD Branding
            if i.IsHD <> invalid
                metaData.HDBranded = i.IsHD
            end If
            
            ' Set Played Percentage
            if i.PlayedPercentage <> invalid
                PlayedPercentage = i.PlayedPercentage
            else if i.UserData.PlaybackPositionTicks <> "" And i.UserData.PlaybackPositionTicks <> invalid
                if i.RunTimeTicks <> "" And i.RunTimeTicks <> invalid
                    currentPosition = Int(((i.UserData.PlaybackPositionTicks).ToFloat() / 10000) / 1000)
                    totalLength     = Int(((i.RunTimeTicks).ToFloat() / 10000) / 1000)
                    PlayedPercentage = Int((currentPosition / totalLength) * 100)
                else
                    PlayedPercentage = 0
                end If
            else
                PlayedPercentage = 0
            end if

            ' Get Image Type From Preference
            if RegRead("prefMovieImageType") = "poster"

                ' Get Image Sizes
                sizes = GetImageSizes("mixed-aspect-ratio-portrait")

                ' Check if Item has Image, otherwise use default
                if i.ImageTags.Primary <> "" And i.ImageTags.Primary <> invalid
                    imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.Id) + "/Images/Primary/0"

                    if i.UserData.Played = true
                        metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ImageTags.Primary, i.UserData.Played)
                        metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ImageTags.Primary, i.UserData.Played)
                    else if i.UserData.Played = false And PlayedPercentage <> 100 
                        metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ImageTags.Primary, i.UserData.Played, PlayedPercentage)
                        metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ImageTags.Primary, i.UserData.Played, PlayedPercentage)
                    else
                        metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ImageTags.Primary)
                        metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ImageTags.Primary)
                    end if

                else 
                    metaData.HDPosterUrl = "pkg://images/items/collection.png"
                    metaData.SDPosterUrl = "pkg://images/items/collection.png"

                end if

            else if RegRead("prefMovieImageType") = "thumb"

                ' Get Image Sizes
                sizes = GetImageSizes("two-row-flat-landscape-custom")

                ' Check if Item has Image, otherwise use default
                if i.ImageTags.Thumb <> "" And i.ImageTags.Thumb <> invalid
                    imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.Id) + "/Images/Thumb/0"

                    if i.UserData.Played = true
                        metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ImageTags.Thumb, i.UserData.Played)
                        metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ImageTags.Thumb, i.UserData.Played)
                    else if i.UserData.Played = false And PlayedPercentage <> 100 
                        metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ImageTags.Thumb, i.UserData.Played, PlayedPercentage)
                        metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ImageTags.Thumb, i.UserData.Played, PlayedPercentage)
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
                    else if i.UserData.Played = false And PlayedPercentage <> 100 
                        metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.BackdropImageTags[0], i.UserData.Played, PlayedPercentage)
                        metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.BackdropImageTags[0], i.UserData.Played, PlayedPercentage)
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
        Debug("Failed to Get Movies List")
    end if

    return invalid
End Function


'**********************************************************
'** Get Movie Boxsets
'**********************************************************

Function moviemetadata_boxsets(offset = invalid As Dynamic, limit = invalid As Dynamic) As Object
    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items"

    ' Query
    query = {
        recursive: "true"
        includeitemtypes: "BoxSet"
        fields: "Overview,UserData,ItemCounts"
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

        contentList = CreateObject("roArray", 15, true)
        jsonObj     = ParseJSON(response)

        if jsonObj = invalid
            Debug("Error while parsing JSON response for Movie Boxsets")
            return invalid
        end if

        totalRecordCount = jsonObj.TotalRecordCount

        for each i in jsonObj.Items
            metaData = {}

            ' Set the Content Type
            metaData.ContentType = "BoxSet"

            ' Set the Id
            metaData.Id = i.Id

            ' Show / Hide display title
            if RegRead("prefMovieTitle") = "show" Or RegRead("prefMovieTitle") = invalid
                metaData.ShortDescriptionLine1 = firstOf(i.Name, "Unknown")
            end if

            '** PopUp Metadata **

            ' Set the display title
            metaData.Title = firstOf(i.Name, "Unknown")

            ' Set the Overview
            if i.Overview <> invalid
                metaData.Description = i.Overview
            end if

            ' Set the Official Rating
            if i.OfficialRating <> invalid
                metaData.Rating = i.OfficialRating
            end if

            ' Set the Star rating
            if i.CommunityRating <> invalid
                metaData.UserStarRating = Int(i.CommunityRating) * 10
            end if

            ' Set the Release Date
            if isInt(i.ProductionYear)
                metaData.ReleaseDate = itostr(i.ProductionYear)
            end if

            ' Set the Movie Count
            if i.ChildCount <> invalid
                metaData.ShortDescriptionLine2 = Pluralize(i.ChildCount, "movie")
            end if

            ' Get Image Type From Preference
            if RegRead("prefMovieImageType") = "poster"

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

            else if RegRead("prefMovieImageType") = "thumb"

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
        Debug("Failed to Get Movie Boxsets")
    end if

    return invalid
End Function


'**********************************************************
'** Get Movies in a Boxset
'**********************************************************

Function moviemetadata_boxset_movie_list(boxsetId As String) As Object
    ' Validate Parameter
    if validateParam(boxsetId, "roString", "moviemetadata_boxset_movie_list") = false return invalid

    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items"

    ' Query
    query = {
        parentid: boxsetId
        recursive: "true"
        includeitemtypes: "Movie"
        fields: "Overview,UserData"
        sortby: "ProductionYear,SortName"
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
        regex         = CreateObject("roRegex", Chr(34) + "(RunTimeTicks)" + Chr(34) + ":(-?[0-9]+),", "i")
        fixedResponse = regex.ReplaceAll(response, Chr(34) + "\1" + Chr(34) + ":" + Chr(34) + "\2" + Chr(34) + ",")

        contentList   = CreateObject("roArray", 10, true)
        jsonObj       = ParseJSON(fixedResponse)

        if jsonObj = invalid
            Debug("Error while parsing JSON response for Movies in a Boxset")
            return invalid
        end if

        totalRecordCount = jsonObj.TotalRecordCount

        for each i in jsonObj.Items
            metaData = {}

            ' Set the Content Type
            metaData.ContentType = "Movie"

            ' Set the Id
            metaData.Id = i.Id

            ' Show / Hide display title
            if RegRead("prefMovieTitle") = "show" Or RegRead("prefMovieTitle") = invalid
                metaData.ShortDescriptionLine1 = firstOf(i.Name, "Unknown")
            end if

            '** PopUp Metadata **

            ' Set the display title
            metaData.Title = firstOf(i.Name, "Unknown")

            ' Set the Run Time
            if i.RunTimeTicks <> "" And i.RunTimeTicks <> invalid
                metaData.Length = Int(((i.RunTimeTicks).ToFloat() / 10000) / 1000)
            end if

            ' Set the Overview
            if i.Overview <> invalid
                metaData.Description = i.Overview
            end if

            ' Set the Official Rating
            if i.OfficialRating <> invalid
                metaData.Rating = i.OfficialRating
            end if

            ' Set the Star rating
            if i.CommunityRating <> invalid
                metaData.UserStarRating = Int(i.CommunityRating) * 10
            end if

            ' Set the Release Date
            if isInt(i.ProductionYear)
                metaData.ReleaseDate = itostr(i.ProductionYear)
            end if

            ' Set the HD Branding
            if i.IsHD <> invalid
                metaData.HDBranded = i.IsHD
            end if

            ' Get Image Type From Preference
            if RegRead("prefMovieImageType") = "poster"

                ' Get Image Sizes
                sizes = GetImageSizes("mixed-aspect-ratio-portrait")

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

            else if RegRead("prefMovieImageType") = "thumb"

                ' Get Image Sizes
                sizes = GetImageSizes("two-row-flat-landscape-custom")

                ' Check if Item has Image, otherwise use default
                if i.ImageTags.Thumb <> "" And i.ImageTags.Thumb <> invalid
                    imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.Id) + "/Images/Thumb/0"

                    if i.UserData.Played <> invalid
                        metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ImageTags.Thumb, i.UserData.Played)
                        metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ImageTags.Thumb, i.UserData.Played)
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

                    if i.UserData.Played <> invalid
                        metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.BackdropImageTags[0], i.UserData.Played)
                        metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.BackdropImageTags[0], i.UserData.Played)
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
        Debug("Failed to Get Movies in a Boxset")
    end if

    return invalid
End Function


'**********************************************************
'** Get Resumable Movies
'**********************************************************

Function moviemetadata_resumable() As Object
    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items"

    ' Query
    query = {
        limit: "10"
        recursive: "true"
        includeitemtypes: "Movie"
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
            Debug("Error while parsing JSON response for Resumable Movies")
            return invalid
        end if

        totalRecordCount = jsonObj.TotalRecordCount

        for each i in jsonObj.Items
            metaData = {}

            ' Set the Content Type
            metaData.ContentType = "Movie"

            ' Set the Id
            metaData.Id = i.Id

            ' Set the display title
            metaData.Title = firstOf(i.Name, "Unknown") ' Not even used
            metaData.ShortDescriptionLine1 = firstOf(i.Name, "Unknown")

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
        Debug("Failed to Get Resumable Movies")
    end if

    return invalid
End Function


'**********************************************************
'** Get Latest Unwatched Movies
'**********************************************************

Function moviemetadata_latest() As Object
    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items"

    ' Query
    query = {
        limit: "10"
        recursive: "true"
        includeitemtypes: "Movie"
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
            Debug("Error while parsing JSON response for Recently Added Movies")
            return invalid
        end if

        totalRecordCount = jsonObj.TotalRecordCount

        for each i in jsonObj.Items
            metaData = {}

            ' Set the Content Type
            metaData.ContentType = "Movie"

            ' Set the Id
            metaData.Id = i.Id

            ' Set the display title
            metaData.Title = firstOf(i.Name, "Unknown") ' Not even used
            metaData.ShortDescriptionLine1 = firstOf(i.Name, "Unknown")

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
        Debug("Failed to Get Recently Added Movies")
    end if

    return invalid
End Function


'**********************************************************
'** Get Movie Genres
'**********************************************************

Function moviemetadata_genres(offset = invalid As Dynamic, limit = invalid As Dynamic) As Object
    ' URL
    url = GetServerBaseUrl() + "/Genres"

    ' Query
    query = {
        userid: getGlobalVar("user").Id
        recursive: "true"
        includeitemtypes: "Movie"
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
            Debug("Error while parsing JSON response for Genres for Movies")
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

            ' Set Movie Count
            if i.MovieCount <> invalid
                metaData.ShortDescriptionLine2 = Pluralize(i.MovieCount, "movie")
                metaData.Description = Pluralize(i.MovieCount, "movie")
            end if

            ' Get Image Type From Preference
            if RegRead("prefMovieImageType") = "poster"
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
        Debug("Failed to Get Genres for Movies")
    end if

    return invalid
End Function


'**********************************************************
'** Get Movies in a Genre
'**********************************************************

Function moviemetadata_genre_movie_list(genreName As String) As Object
    ' Validate Parameter
    if validateParam(genreName, "roString", "moviemetadata_genre_movie_list") = false return invalid

    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items"

    ' Query
    query = {
        genres: genreName
        recursive: "true"
        includeitemtypes: "Movie"
        fields: "UserData,Overview"
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
        regex         = CreateObject("roRegex", Chr(34) + "(RunTimeTicks)" + Chr(34) + ":(-?[0-9]+),", "i")
        fixedResponse = regex.ReplaceAll(response, Chr(34) + "\1" + Chr(34) + ":" + Chr(34) + "\2" + Chr(34) + ",")

        contentList   = CreateObject("roArray", 25, true)
        jsonObj       = ParseJSON(fixedResponse)

        if jsonObj = invalid
            Debug("Error while parsing JSON response for Movies List In Genre")
            return invalid
        end if

        totalRecordCount = jsonObj.TotalRecordCount

        for each i in jsonObj.Items
            metaData = {}

            ' Set the Content Type
            metaData.ContentType = "Movie"

            ' Set the Id
            metaData.Id = i.Id

            ' Show / Hide display title
            if RegRead("prefMovieTitle") = "show" Or RegRead("prefMovieTitle") = invalid
                metaData.ShortDescriptionLine1 = firstOf(i.Name, "Unknown")
            end if

            '** PopUp Metadata **

            ' Set the display title
            metaData.Title = firstOf(i.Name, "Unknown")

            ' Set the Movie overview
            if i.Overview <> invalid
                metaData.Description = i.Overview
            end if

            ' Set the Movie rating
            if i.OfficialRating <> invalid
                metaData.Rating = i.OfficialRating
            end if

            ' Set the Star rating
            if i.CommunityRating <> invalid
                metaData.UserStarRating = Int(i.CommunityRating) * 10
            end if

            ' Set the Run Time
            if i.RunTimeTicks <> "" And i.RunTimeTicks <> invalid
                metaData.Length = Int(((i.RunTimeTicks).ToFloat() / 10000) / 1000)
            end if

            ' Set the Release Date
            if isInt(i.ProductionYear)
                metaData.ReleaseDate = itostr(i.ProductionYear)
            end if

            ' Set the HD Branding
            if i.IsHD <> invalid
                metaData.HDBranded = i.IsHD
            end if

            ' Get Image Type From Preference
            if RegRead("prefMovieImageType") = "poster"

                ' Get Image Sizes
                sizes = GetImageSizes("mixed-aspect-ratio-portrait")

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

            else if RegRead("prefMovieImageType") = "thumb"

                ' Get Image Sizes
                sizes = GetImageSizes("two-row-flat-landscape-custom")

                ' Check if Item has Image, otherwise use default
                if i.ImageTags.Thumb <> "" And i.ImageTags.Thumb <> invalid
                    imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.Id) + "/Images/Thumb/0"

                    if i.UserData.Played <> invalid
                        metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ImageTags.Thumb, i.UserData.Played)
                        metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ImageTags.Thumb, i.UserData.Played)
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

                    if i.UserData.Played <> invalid
                        metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.BackdropImageTags[0], i.UserData.Played)
                        metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.BackdropImageTags[0], i.UserData.Played)
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
        Debug("Failed to Get Movies List In Genre")
    end if

    return invalid
End Function


'**********************************************************
'** Get Movie Details
'**********************************************************

Function moviemetadata_movie_details(movieId As String) As Object
    ' Validate Parameter
    if validateParam(movieId, "roString", "moviemetadata_movie_details") = false return invalid

    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items/" + HttpEncode(movieId)

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
            Debug("Error while parsing JSON response for Movie Details")
            return invalid
        end if

        metaData = {}

        ' Set the Content Type
        metaData.ContentType = "Movie"

        ' Set the Id
        metaData.Id = i.Id

        'metaData.ContentId = i.Id ' Not sure it Is needed

        ' Set the display title
        metaData.Title = firstOf(i.Name, "Unknown")

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

        ' Set the Star rating
        if i.CommunityRating <> invalid
            metaData.UserStarRating = Int(i.CommunityRating) * 10
        end if

        ' Set the Run Time
        if i.RunTimeTicks <> "" And i.RunTimeTicks <> invalid
            metaData.Length = Int(((i.RunTimeTicks).ToFloat() / 10000) / 1000)
        end if

        ' Set the Playback Position
        if i.UserData.PlaybackPositionTicks <> "" And i.UserData.PlaybackPositionTicks <> invalid
            metaData.PlaybackPosition = i.UserData.PlaybackPositionTicks
        end if

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
        sizes = GetImageSizes("movie")

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
        Debug("Failed to Get Movie Details")
    end if

    return invalid
End Function
