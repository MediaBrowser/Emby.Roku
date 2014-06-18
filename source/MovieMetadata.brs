'**********************************************************
'** parseSuggestedMoviesResponse
'**********************************************************

Function parseSuggestedMoviesResponse(response) As Object
    
	if response <> invalid

        contentList = CreateObject("roArray", 20, true)
        fixedResponse = normalizeJson(response)
        result     = ParseJSON(fixedResponse)

        if result = invalid
            Debug("Error in parseSuggestedMoviesResponse")
            return invalid
        end if

        ' Only Grab 1 Category
        category = result[0]
		
		' Results are empty
		if category = invalid then
            return {
				Items: contentList
				TotalCount: contentList.Count()
			}
		end if

        for each i in category.Items
            metaData = getMetadataFromServerItem(i, 1, "mixed-aspect-ratio-portrait")

            contentList.push( metaData )
        end for

        return {
            Items: contentList
            RecommendationType: category.RecommendationType
            BaselineItemName: category.BaselineItemName
			TotalCount: contentList.Count()
        }
    end if

    return invalid
End Function