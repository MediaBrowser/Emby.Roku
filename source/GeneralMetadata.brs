'*****************************************************************
'**  Media Browser Roku Client - General Metadata
'*****************************************************************


'******************************************************
' Get Media Item Counts
'******************************************************

Function getMediaItemCounts() As Object
    ' URL
    url = GetServerBaseUrl() + "/Items/Counts"

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

        metaData = ParseJSON(response)

        if metaData = invalid
            Debug("Error Parsing Media Item Counts")
            return invalid
        end if

        return metaData
    else
        Debug("Failed To Get Media Item Counts")
    end if

    return invalid
End Function


'******************************************************
' Get All User Profiles
'******************************************************

Function getAllUserProfiles() As Object
    ' URL
    url = GetServerBaseUrl() + "/Users"

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

        contentList   = CreateObject("roArray", 25, true)
        jsonObj       = ParseJSON(response)

        if jsonObj = invalid
            Debug("Error while parsing JSON response for All User Profiles")
            return invalid
        end if

        for each i in jsonObj
            metaData = {}

            ' Set the Id
            metaData.Id = i.Id

            ' Set the Content Type
            metaData.ContentType = "user"

            ' Set the Username
            metaData.Title = firstOf(i.Name, "Unknown")
            metaData.ShortDescriptionLine1 = firstOf(i.Name, "Unknown")

            ' Set the Has Password Flag
            metaData.HasPassword = firstOf(i.HasPassword, false)

            ' Get Image Sizes
            sizes = GetImageSizes("flat-category")

            ' Check if Item has Image, otherwise use default
            if i.PrimaryImageTag <> "" And i.PrimaryImageTag <> invalid
                imageUrl = GetServerBaseUrl() + "/Users/" + HttpEncode(i.Id) + "/Images/Primary/0"

                metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.PrimaryImageTag, false, 0, true)
                metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.PrimaryImageTag, false, 0, true)

            else 
                metaData.HDPosterUrl = "pkg://images/hd-default-user.png"
                metaData.SDPosterUrl = "pkg://images/sd-default-user.png"

            end if

            contentList.push( metaData )
        end for

        return contentList
    else
        Debug("Failed To Get All User Profiles")
    end if

    return invalid
End Function


'******************************************************
' Get User Profile
'******************************************************

Function getUserProfile(userId As String) As Object
    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(userId)

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

        i = ParseJSON(response)

        if i = invalid
            Debug("Error Parsing User Profile")
            return invalid
        end if
        
        metaData = {}

        ' Set the Id
        metaData.Id = i.Id

        ' Set the Username
        metaData.Title = firstOf(i.Name, "Unknown")
        metaData.ShortDescriptionLine1 = firstOf(i.Name, "Unknown")

        return metaData
    else
        Debug("Failed To Get User Profile")
    end if

    return invalid
End Function
