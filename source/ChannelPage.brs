'**********************************************************
'** Show Channel List Page
'**********************************************************
Function createChannelScreen(viewController as Object, channel As Object) As Object

    imageType      = (firstOf(RegUserRead("channelImageType"), "0")).ToInt()

    names = [channel.title]
    keys = [channel.id]
  
    loader = CreateObject("roAssociativeArray")
    loader.getUrl = getChannelScreenUrl
    loader.parsePagedResult = parseChannelScreenResult
    loader.channel = channel
    
    if imageType = 0 then
        screen = createPaginatedGridScreen(viewController, names, keys, loader, "mixed-aspect-ratio")
    Else
        screen = createPaginatedGridScreen(viewController, names, keys, loader, "two-row-flat-landscape-custom")
    End If

    screen.displayInfoBox = (firstOf(RegUserRead("channelInfoBox"), "0")).ToInt()

    if screen.displayInfoBox = 0 then
        screen.SetDescriptionVisible(false)
    end if

    return screen

End Function


Function parseChannelScreenResult(row as Integer, json as String) as Object

    imageType      = (firstOf(RegUserRead("channelImageType"), "0")).ToInt()

    return parseItemsResponse(json, imageType, "mixed-aspect-ratio-portrait")

End Function

Function getChannelScreenUrl(row as Integer, id as String) as String

    channel = m.channel

     ' URL
    url = GetServerBaseUrl()

    ' Query
    query = {}

    if row = 0
        if channel.channelid <> invalid
            url = url  + "/Channels/" + HttpEncode(channel.channelid) + "/Items?userId=" + getGlobalVar("user").Id
        else
            url = url  + "/Channels/" + HttpEncode(channel.id) + "/Items?userId=" + getGlobalVar("user").Id
        end if
        
        ' Query
        query = {
            fields: "Overview,UserData,ItemCounts"
            sortby: "SortName"
            sortorder: "Ascending"
        }

        if channel.channelid <> invalid
            q = { folderid: channel.id }
            query.Append(q)
        end if
    end If
    
    for each key in query
        url = url + "&" + key +"=" + HttpEncode(query[key])
    end for
    
    print "Channel url: " + url

    return url

End Function
