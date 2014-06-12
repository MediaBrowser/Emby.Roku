'******************************************************
' getDefaultLiveTvTimer
'******************************************************

Function getDefaultLiveTvTimer(programId As String) As Object
    
	url = GetServerBaseUrl() + "/LiveTv/Timers/Defaults"

    query = {
        ProgramId: programId
    }

    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    response = request.GetToStringWithTimeout(10)
	
    if response <> invalid
	
        metaData = ParseJSON(response)

        if metaData = invalid
            return invalid
        end if

        return metaData
		
    end if

    return invalid
	
End Function



'**********************************************************
'** cancelLiveTvTimer
'**********************************************************

Function cancelLiveTvTimer(timerId As String) As Boolean
    
	url = GetServerBaseUrl() + "/LiveTv/Timers/" + HttpEncode(timerId)

    request = HttpRequest(url)
    request.AddAuthorization()
    request.SetRequest("DELETE")

    response = request.PostFromStringWithTimeout("", 5)
	
    if response <> invalid
        return true
    end if

    return false
	
End Function


'**********************************************************
'** deleteLiveTvRecording
'**********************************************************

Function deleteLiveTvRecording(recordingId As String) As Boolean

    url = GetServerBaseUrl() + "/LiveTv/Recordings/" + HttpEncode(recordingId)

    request = HttpRequest(url)
    request.AddAuthorization()
    request.SetRequest("DELETE")

    response = request.PostFromStringWithTimeout("", 5)
	
    if response <> invalid
        
		return true
		
    end if

    return false
	
End Function

'**********************************************************
'** createLiveTvTimer
'**********************************************************

Function createLiveTvTimer(timerObj As Object) As Boolean

    url = GetServerBaseUrl() + "/LiveTv/Timers"

    request = HttpRequest(url)
    request.AddAuthorization()
	request.ContentType("json")

	json = SimpleJSONBuilder(timerObj)
	
    response = request.PostFromStringWithTimeout(json, 5)
	
    if response <> invalid
        return true
    end if

    return false
	
End Function