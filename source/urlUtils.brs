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
    If authorized<>invalid Then
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
    If authorized<>invalid Then
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
