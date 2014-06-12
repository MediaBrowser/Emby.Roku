'**********************************************************
'** Get Top Level Media Folders
'**********************************************************

Function getMediaFolders() As Object

    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items"

    query = {
        sortby: "SortName"
        sortorder: "Ascending"
    }

    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    response = request.GetToStringWithTimeout(10)
    if response <> invalid
		return parseItemsResponse(response, 0, "two-row-flat-landscape-custom")
    end if

	Debug ("Error getting media folders")
    return invalid

End Function