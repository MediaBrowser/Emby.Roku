'*****************************************************************
'**  Media Browser Roku Client - Movie Metadata Class
'*****************************************************************

'**********************************************************
'** parseSuggestedMoviesResponse
'**********************************************************

Function parseSuggestedMoviesResponse(response) As Object
    
	if response <> invalid

        contentList = CreateObject("roArray", 20, true)
        fixedResponse = normalizeJson(response)
        jsonObj     = ParseJSON(fixedResponse)

        if jsonObj = invalid
            Debug("Error while parsing JSON response for Recently Added Movies")
            return invalid
        end if

        ' Only Grab 1 Category
        jsonObj = jsonObj[0]

        ' Recommended Because
        recommendationType = jsonObj.RecommendationType
        baselineItemName = jsonObj.BaselineItemName

        for each i in jsonObj.Items
            metaData = getMetadataFromServerItem(i, 1, "mixed-aspect-ratio-portrait")

            contentList.push( metaData )
        end for

        return {
            Items: contentList
            RecommendationType: recommendationType
            BaselineItemName: baselineItemName
			TotalCount: contentList.Count()
        }
    end if

    return invalid
End Function