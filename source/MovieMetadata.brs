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
        this.GetMovieList = moviemetadata_movie_list
        this.GetResumable = moviemetadata_resumable
        this.GetLatest    = moviemetadata_latest

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

Function moviemetadata_movie_list() As Object
    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items"

    ' Query
    query = {
        recursive: "true"
        includeitemtypes: "Movie"
        fields: "Overview,UserData,MediaStreams,SortName"
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
        regex         = CreateObject("roRegex", Chr(34) + "(RunTimeTicks)" + Chr(34) + ":([0-9]+),", "i")
        fixedResponse = regex.ReplaceAll(response, Chr(34) + "\1" + Chr(34) + ":" + Chr(34) + "\2" + Chr(34) + ",")

        jumpListCount = 0
        contentList   = CreateObject("roArray", 25, true)
        items         = ParseJSON(fixedResponse).Items

        for each i in items
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
            if i.CriticRating <> invalid
                metaData.UserStarRating = i.CriticRating
            end if

            ' Set the Release Date
            if isInt(i.ProductionYear)
                metaData.ReleaseDate = itostr(i.ProductionYear)
            end if

            isHd = false ' Hide For now

            ' Set the HD Branding
            if isHD
                metaData.HDBranded = true
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
            if RegRead("prefMovieImageType") = "poster"

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

            else if RegRead("prefMovieImageType") = "thumb"

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
        Debug("Failed to Get Movies List")
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
        items       = ParseJSON(response).Items

        for each i in items
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
        
        return contentList
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
        items       = ParseJSON(response).Items

        for each i in items
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
        
        return contentList
    else
        Debug("Failed to Get Recently Added Movies")
    end if

    return invalid
End Function
