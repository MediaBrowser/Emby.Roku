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
