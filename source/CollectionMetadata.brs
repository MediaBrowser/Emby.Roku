'*****************************************************************
'**  Media Browser Roku Client - Collection Metadata Class
'*****************************************************************


Function ClassCollectionMetadata()
    ' initializes static members once
    this = m.ClassCollectionMetadata

    if this = invalid
        this = CreateObject("roAssociativeArray")

        ' constants
        this.class        = "CollectionMetadata"

        'variables
        this.jumpList     = {}

        ' functions
        this.GetCollectionList  = collectionmetadata_collection_list
        this.GetCollectionItems = collectionmetadata_collection_items

        ' singleton
        m.ClassMovieMetadata = this
    end if
    
    return this
End Function


Function InitCollectionMetadata()
    this = ClassCollectionMetadata()
    return this
End Function


'**********************************************************
'** Get All Collections
'**********************************************************

Function collectionmetadata_collection_list() As Object
    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items"

    ' Query
    query = {
        includeitemtypes: "CollectionFolder,TrailerCollectionFolder"
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
        jsonObj     = ParseJSON(response)

        if jsonObj = invalid
            Debug("Error while parsing JSON response for Collection List")
            return invalid
        end if

        for each i in jsonObj.Items
            metaData = {}

            ' Set the Content Type
            metaData.ContentType = "Collection"

            ' Set the Id
            metaData.Id = i.Id

            ' Set the display title
            metaData.ShortDescriptionLine1 = firstOf(i.Name, "Unknown")

            ' Get Image Sizes
            sizes = GetImageSizes("two-row-flat-landscape-custom")

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
        Debug("Failed to Get Collection List")
    end if

    return invalid
End Function


'**********************************************************
'** Get Items within Collection
'**********************************************************

Function collectionmetadata_collection_items(parentId As String) As Object
    ' Validate Parameter
    if validateParam(parentId, "roString", "collectionmetadata_collection_items") = false return invalid

    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items"

    ' Query
    query = {
        parentid: parentId
        includeitemtypes: "Movie,Boxset,Series,Episode"
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
        jsonObj     = ParseJSON(response)

        if jsonObj = invalid
            Debug("Error while parsing JSON response for Collection Items")
            return invalid
        end if

        for each i in jsonObj.Items
            metaData = {}

            ' Set the Content Type
            metaData.ContentType = "Collection"

            ' Set the Id
            metaData.Id = i.Id




            contentList.push( metaData )
        end for

        return contentList
    else
        Debug("Failed to Get Collection Items")
    end if

    return invalid
End Function
