'**********************************************************
'** Get All Channels
'**********************************************************

Function GetChannels() As Object
    ' URL
    url = GetServerBaseUrl() + "/Channels"

    ' Query
    query = {
        userid: HttpEncode(getGlobalVar("user").Id)
    }

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid
		return parseItemsResponse(response, 1, "two-row-flat-landscape-custom")
    end if

    return invalid
End Function


'**********************************************************
'** Get Items within Channel
'**********************************************************

Function GetChannelItems(id As String, offset = invalid As Dynamic, limit = invalid As Dynamic, filters = invalid As Object) As Object
    ' Validate Parameter
    if validateParam(id, "roString", "GetChannelItems") = false return invalid

    ' URL
    url = GetServerBaseUrl() + "/Channels/" + HttpEncode(id) + "/Items"

	print "Channel url: " + url

    ' Query
    query = {
        UserId: getGlobalVar("user").Id
        fields: "Overview,UserData,PrimaryImageAspectRatio"
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
    response = request.GetToStringWithTimeout(30)
    if response <> invalid

		return parseItemsResponse(response, 0, "two-row-flat-landscape-custom")
    else
        Debug("Failed to Get Channel Items")
    end if

    return invalid
End Function
