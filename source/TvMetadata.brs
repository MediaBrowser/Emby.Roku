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

        ' functions
        this.GetResumable = tvmetadata_resumable
        this.GetLatest    = tvmetadata_latest

        ' singleton
        m.ClassTvMetadata = this
    end If
    
    return this
End Function


Function InitTvMetadata()
    this = ClassTvMetadata()
    return this
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

            ' Append Title If Season Or Episode Number have been added
            if episodeInfo <> ""
                episodeInfo = episodeInfo + " - " + i.Name
            else
                episodeInfo = i.Name
            end if

            ' Set the Line 2 display
            metaData.ShortDescriptionLine2 = episodeInfo

            ' Get Image Sizes
            sizes = GetImageSizes("two-row-flat-landscape-custom")

            ' Check If Item has Image, Check If Parent Item has Image, otherwise use default
            If i.BackdropImageTags[0]<>"" And i.BackdropImageTags[0]<>invalid
                imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.Id) + "/Images/Backdrop/0"

                metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.BackdropImageTags[0])
                metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.BackdropImageTags[0])
            Else If i.ImageTags.Primary<>"" And i.ImageTags.Primary<>invalid
                imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.Id) + "/Images/Primary/0"

                metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ImageTags.Primary)
                metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ImageTags.Primary)
            Else 
                metaData.HDPosterUrl = "pkg://images/items/collection.png"
                metaData.SDPosterUrl = "pkg://images/items/collection.png"
            End If

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

            ' Append Title If Season Or Episode Number have been added
            if episodeInfo <> ""
                episodeInfo = episodeInfo + " - " + i.Name
            else
                episodeInfo = i.Name
            end if

            ' Set the Line 2 display
            metaData.ShortDescriptionLine2 = episodeInfo

            ' Get Image Sizes
            sizes = GetImageSizes("two-row-flat-landscape-custom")

            ' Check If Item has Image, Check If Parent Item has Image, otherwise use default
            If i.BackdropImageTags[0]<>"" And i.BackdropImageTags[0]<>invalid
                imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.Id) + "/Images/Backdrop/0"

                metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.BackdropImageTags[0])
                metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.BackdropImageTags[0])
            Else If i.ImageTags.Primary<>"" And i.ImageTags.Primary<>invalid
                imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.Id) + "/Images/Primary/0"

                metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ImageTags.Primary)
                metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ImageTags.Primary)
            Else 
                metaData.HDPosterUrl = "pkg://images/items/collection.png"
                metaData.SDPosterUrl = "pkg://images/items/collection.png"
            End If

            contentList.push( metaData )
        end for
        
        return contentList
    else
        Debug("Failed to Get Recently Added TV Shows")
    end if

    return invalid
End Function
