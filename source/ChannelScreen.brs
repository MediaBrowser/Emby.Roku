'**********************************************************
'** Show Channel List Page
'**********************************************************
Function createChannelScreen(viewController as Object, channel As Object) As Object

    names = [channel.title]
    keys = [channel.id]
  
    loader = CreateObject("roAssociativeArray")
    loader.getUrl = getChannelScreenUrl
    loader.parsePagedResult = parseChannelScreenResult
    loader.channel = channel
    
    screen = createPaginatedGridScreen(viewController, names, keys, loader, "mixed-aspect-ratio")

    screen.displayDescription = (firstOf(RegUserRead("channelDescription"), "0")).ToInt()

    return screen

End Function


Function parseChannelScreenResult(row as Integer, json as String) as Object

    return parseItemsResponse(json, 0, "mixed-aspect-ratio-portrait")

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
            fields: "Overview,PrimaryImageAspectRatio"
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
