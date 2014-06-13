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