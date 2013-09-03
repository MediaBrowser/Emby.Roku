'**********************************************************
'**  Media Browser Roku Client - URL Utilities
'**********************************************************

'**********************************************************
'**  Video Player Example Application - URL Utilities 
'**  November 2009
'**  Copyright (c) 2009 Roku Inc. All Rights Reserved.
'**********************************************************


'**********************************************************
'** Creates URL Transfer Object
'**********************************************************

Function CreateURLTransferObject(url As String, authorized=invalid) as Object

    obj = CreateObject("roUrlTransfer")
    obj.SetPort(CreateObject("roMessagePort"))
    obj.SetUrl(url)
    obj.AddHeader("Content-Type", "application/x-www-form-urlencoded")
    obj.EnableEncodings(true)

    ' If authorized, add checkin header
    If authorized <> invalid Then
        authString = "MediaBrowser UserId=" + Quote() + m.curUserProfile.Id + Quote() + ", Client=" + Quote() + "Roku" + Quote() + ", Device=" + Quote() + getGlobalVar("rokuModelName", "Unknown") + Quote() + ", DeviceId=" + Quote() + getGlobalVar("rokuUniqueId", "Unknown") + Quote() + ", Version=" + Quote() + getGlobalVar("channelVersion", "Unknown") + Quote()
        obj.AddHeader("Authorization", authString)
    End If

    return obj
End Function


'**********************************************************
'** Creates JSON URL Transfer Object
'**********************************************************

Function CreateURLTransferObjectJson(url As String, authorized=invalid) as Object
   
    obj = CreateObject("roUrlTransfer")
    obj.SetPort(CreateObject("roMessagePort"))
    obj.SetUrl(url)
    obj.AddHeader("Content-Type", "application/json")
    obj.EnableEncodings(true)

    ' If authorized, add checkin header
    If authorized <> invalid Then
        authString = "MediaBrowser UserId=" + Quote() + m.curUserProfile.Id + Quote() + ", Client=" + Quote() + "Roku" + Quote() + ", Device=" + Quote() + getGlobalVar("rokuModelName", "Unknown") + Quote() + ", DeviceId=" + Quote() + getGlobalVar("rokuUniqueId", "Unknown") + Quote() + ", Version=" + Quote() + getGlobalVar("channelVersion", "Unknown") + Quote()
        obj.AddHeader("Authorization", authString)
    End If

    return obj
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

    obj.Http                        = CreateURLTransferObject2(url)
    obj.ContentType                 = http_content_type
    obj.AddAuthorization            = http_authorization
    obj.FirstParam                  = true
    obj.AddParam                    = http_add_param
    obj.RemoveParam                 = http_remove_param
    obj.BuildQuery                  = http_build_query
    obj.AddRawQuery                 = http_add_raw_query
    obj.PrepareUrlForQuery          = http_prepare_url_for_query
    obj.GetToStringWithTimeout      = http_get_to_string_with_timeout
    obj.PostFromStringWithTimeout   = http_post_from_string_with_timeout

    if Instr(1, url, "?") > 0 then obj.FirstParam = false

    return obj
End Function


'**********************************************************
'** Creates URL Transfer Object
'**********************************************************

Function CreateURLTransferObject2(url As String) as Object

    obj = CreateObject("roUrlTransfer")
    obj.SetPort(CreateObject("roMessagePort"))
    obj.SetUrl(url)
    obj.EnableEncodings(true)

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
    authString = "MediaBrowser UserId=" + Quote() + HttpEncode(getGlobalVar("user").Id) + Quote() + ", Client=" + Quote() + "Roku" + Quote() + ", Device=" + Quote() + getGlobalVar("rokuModelName", "Unknown") + Quote() + ", DeviceId=" + Quote() + getGlobalVar("rokuUniqueId", "Unknown") + Quote() + ", Version=" + Quote() + getGlobalVar("channelVersion", "Unknown") + Quote()
    m.Http.AddHeader("Authorization", authString)
End Function


'**********************************************************
'** Prepare the current url for adding query parameters
'** Automatically add a '?' or '&' as necessary
'**********************************************************

Function http_prepare_url_for_query() As String
    url = m.Http.GetUrl()
    if m.FirstParam then
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
End Function


'**********************************************************
'** Remove a query parameter
'**********************************************************

Function http_remove_param(name As String) as Void
    param = m.Http.Escape(name)
    url   = m.Http.GetUrl()
    regex   = CreateObject("roRegex", "&" + param + "(\=[^&]*)?(?=&|$)|^" + param + "(\=[^&]*)?(&|$)", "i")
    new_url = regex.Replace(url, "")
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
                m.Http = CreateURLTransferObject2(m.Http.GetUrl())
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
            else
                Debug("Failed Response with Error: " + itostr(code))
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
