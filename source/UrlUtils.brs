'**********************************************************
'**  Emby Roku Client - URL Utilities
'**********************************************************

'**********************************************************
'**  Video Player Example Application - URL Utilities 
'**  November 2009
'**  Copyright (c) 2009 Roku Inc. All Rights Reserved.
'**********************************************************


'**********************************************************
'** Add to Query Array
'**********************************************************

Function AddToQuery(query As Object, fields As Object) As Object
    for each key in fields
        query.AddReplace(key, fields[key])
    end for
    
    return query
End Function


'**********************************************************
'** HTTP Encode a String
'**********************************************************

Function HttpEncode(str As String) As String
    obj= CreateObject("roUrlTransfer")
    return obj.Escape(str)
End Function


'**********************************************************
'** Create HTTP Request
'**********************************************************

Function HttpRequest(url As String) as Object
    obj = CreateObject("roAssociativeArray")

    obj.Http                        = CreateURLTransferObject(url)
    obj.ContentType                 = http_content_type
    obj.AddAuthorization            = http_authorization
    obj.GetUrl                      = http_get_url
	obj.GetRequest = http_get_request
    obj.SetRequest                  = http_set_request
    obj.FirstParam                  = true
    obj.CountParams                 = 0
    obj.AddParam                    = http_add_param
    obj.UpdateParam                 = http_update_param
    obj.RemoveParam                 = http_remove_param
    obj.BuildQuery                  = http_build_query
    obj.AddRawQuery                 = http_add_raw_query
    obj.PrepareUrlForQuery          = http_prepare_url_for_query
    obj.GetToStringWithTimeout      = http_get_to_string_with_timeout
    obj.PostFromStringWithTimeout   = http_post_from_string_with_timeout

    if Instr(1, url, "?") > 0 then
        r = CreateObject("roRegex", "&", "")
        obj.CountParams = r.Split(url).Count()
        obj.FirstParam = false
    end if

    return obj
End Function

Function http_get_request() As Object
    
	return m.Http
End Function

'**********************************************************
'** Creates URL Transfer Object
'**********************************************************

Function CreateURLTransferObject(url As String) as Object

    obj = CreateObject("roUrlTransfer")
    obj.SetPort(CreateObject("roMessagePort"))
    obj.SetUrl(url)
    obj.EnableEncodings(true)
	
	if url.instr("https") > -1 then 
		obj.SetCertificatesFile("common:/certs/ca-bundle.crt")
		obj.InitClientCertificates()
	end if

    return obj
End Function


'**********************************************************
'** Add a Content-Type Header
'**********************************************************

Function http_content_type(contentType As String) As Void
    if contentType = "json"
        m.Http.AddHeader("Content-Type", "application/json")
    else
        ' Fallback to standard content type
        m.Http.AddHeader("Content-Type", "application/x-www-form-urlencoded")
    end if
End Function


'**********************************************************
'** Add a Authorization Header
'**********************************************************

Function http_authorization() As Void

	authString = "MediaBrowser"

	authString = authString + " Client=" + Quote() + "Roku" + Quote()
	authString = authString + ", Device=" + Quote() + firstOf(regRead("prefDisplayName"), getGlobalVar("rokuModelName", "Unknown")) + Quote()
	authString = authString + ", DeviceId=" + Quote() + getGlobalVar("rokuUniqueId", "Unknown") + Quote()
	authString = authString + ", Version=" + Quote() + HttpEncode(getGlobalVar("channelVersion", "Unknown")) + Quote()

    if getGlobalVar("user") <> invalid
        authString = authString + ", UserId=" + Quote() + HttpEncode(getGlobalVar("user").Id) + Quote()
    end if

    m.Http.AddHeader("X-Emby-Authorization", authString)
	
	activeServerId = RegRead("currentServerId")
	
	if activeServerId <> invalid and activeServerId <> "" then
	
		accessToken = ConnectionManager().GetServerData(activeServerId, "AccessToken")
		
		if firstOf(accessToken, "") <> "" then
			m.Http.AddHeader("X-MediaBrowser-Token", accessToken)
		end if		
	end if
	
	currentUrl = firstOf(m.GetUrl(), "")
	
End Function


'**********************************************************
'** Get Url
'**********************************************************

Function http_get_url() As String
    return m.Http.GetUrl()
End Function


'**********************************************************
'** Set Request Method
'**********************************************************

Function http_set_request(request as String) As Void
    m.Http.SetRequest(request)
End Function


'**********************************************************
'** Prepare the current url for adding query parameters
'** Automatically add a '?' or '&' as necessary
'**********************************************************

Function http_prepare_url_for_query() As String
    url = m.Http.GetUrl()
    if m.FirstParam Or m.CountParams = 0 then
        url = url + "?"
        m.FirstParam = false
    else
        url = url + "&"
    end if
    m.Http.SetUrl(url)
    return url
End Function


'**********************************************************
'** Percent encode a name/value parameter pair and add the
'** the query portion of the current url
'** Automatically add a '?' or '&' as necessary
'** Prevent duplicate parameters
'**********************************************************

Function http_add_param(name As String, val As String) as Void
    q = m.Http.Escape(name)
    q = q + "="
    url = m.Http.GetUrl()
    if Instr(1, url, q) > 0 return    'Parameter already present
    q = q + m.Http.Escape(val)
    m.AddRawQuery(q)
    m.CountParams = m.CountParams + 1
End Function


'**********************************************************
'** Update a query parameter
'**********************************************************

Function http_update_param(name As String, val As String) as Void

End Function


'**********************************************************
'** Remove a query parameter
'**********************************************************

Function http_remove_param(name As String) as Void
    p = m.Http.Escape(name)
    r = CreateObject("roRegex", "&" + p + "(\=[^&]*)?(?=&|$)", "i")
    url = m.Http.GetUrl()
    if r.IsMatch(url)
        new_url = r.Replace(url, "")
    else
        r = CreateObject("roRegex", "\?" + p + "(\=[^&]*)?(?=&|$)&?", "i")
        if m.CountParams = 1 ' Removing last parameter
            new_url = r.Replace(url, "")
        else
            new_url = r.Replace(url, "?")
        End if
    end If
    m.CountParams = m.CountParams - 1
    m.Http.SetUrl(new_url)
End Function


'**********************************************************
'** Build a query string from array
'**********************************************************

Function http_build_query(query As Object) as Void
    for each key in query
        m.AddParam(key, query[key])
    end for
End Function


'**********************************************************
'** Tack a raw query string onto the end of the current url
'** Automatically add a '?' or '&' as necessary
'**********************************************************

Function http_add_raw_query(query As String) as Void
    url = m.PrepareUrlForQuery()
    url = url + query
    m.Http.SetUrl(url)
End Function


'**********************************************************
'** Performs Http.AsyncGetToString() in a retry loop
'** with exponential backoff. To the outside
'** world this appears as a synchronous API.
'**********************************************************

Function http_get_to_string_with_retry() As Dynamic
    timeout%         = 1500
    num_retries%     = 5

    str = invalid
    while num_retries% > 0
        'print "httpget try " + itostr(num_retries%)
        if (m.Http.AsyncGetToString())
            event = wait(timeout%, m.Http.GetPort())
            if type(event) = "roUrlEvent"
                code = event.GetResponseCode()
                if code = 200
                    str = event.GetString()
                else
                    Debug("Failed Response with Error: " + itostr(code))
                end if
                exit while        
            else if event = invalid
                m.Http.AsyncCancel()
                ' reset the connection on timeouts
                m.Http = CreateURLTransferObject(m.Http.GetUrl())
                timeout% = 2 * timeout%
            else
                Debug("AsyncGetToString Unknown Event: " + event)
            end if
        end if

        num_retries% = num_retries% - 1
    end while

    return str
End Function


'**********************************************************
'** Performs Http.AsyncGetToString() with a single timeout in seconds
'** To the outside world this appears as a synchronous API.
'**********************************************************

Function http_get_to_string_with_timeout(seconds as Integer) As Dynamic
    timeout% = 1000 * seconds

    str = invalid
    m.Http.EnableFreshConnection(true) 'Don't reuse existing connections
    if (m.Http.AsyncGetToString())
        event = wait(timeout%, m.Http.GetPort())
        if type(event) = "roUrlEvent"
            code = event.GetResponseCode()
            if code = 200
                str = event.GetString()
            else
                Debug("Failed Response with Error: " + itostr(code))
            end if
        else if event = invalid
            Debug("AsyncGetToString timeout")
            m.Http.AsyncCancel()
        else
            Debug("AsyncGetToString Unknown Event: " + event)
        end if
    end if

    return str
End Function


'**********************************************************
'** Performs Http.AsyncPostFromString() with a single timeout in seconds
'** To the outside world this appears as a synchronous API.
'**********************************************************

Function http_post_from_string_with_timeout(val As String, seconds as Integer) As Dynamic
    timeout% = 1000 * seconds

    str = invalid
    'm.Http.EnableFreshConnection(true) 'Don't reuse existing connections
    if (m.Http.AsyncPostFromString(val))
        event = wait(timeout%, m.Http.GetPort())
        if type(event) = "roUrlEvent"
            code = event.GetResponseCode()
            if code = 200
                str = event.GetString()
            else if code = 204
                str = ""
            else
                Debug("Failed Response with Error: (" + itostr(code) + ") " + event.GetFailureReason())
            end if
        else if event = invalid
            Debug("AsyncPostFromString timeout")
            m.Http.AsyncCancel()
        else
            Debug("AsyncPostFromString Unknown Event: " + event)
        end if
    end if

    return str
End Function
