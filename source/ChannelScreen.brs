'**********************************************************
'** Show Channel List Page
'**********************************************************
Function createChannelScreen(viewController as Object, item As Object) As Object

    names = [item.Title]
    keys = [item.Id]
  
    loader = CreateObject("roAssociativeArray")
    loader.getUrl = getChannelScreenUrl
    loader.parsePagedResult = parseChannelScreenResult
    loader.channel = item
    
    screen = createPaginatedGridScreen(viewController, names, keys, loader, "two-row-flat-landscape-custom", 20)

    screen.displayDescription = 0

    return screen

End Function

Function parseChannelScreenResult(row as Integer, id as string, json as String) as Object

    return parseItemsResponse(json, 0, "mixed-aspect-ratio-portrait", "autosize")

End Function

Function getChannelScreenUrl(row as Integer, id as String) as String

    channel = m.channel

     ' URL
    url = GetServerBaseUrl()

    ' Query
    query = {}

    if row = 0
        if channel.ChannelId <> invalid
            url = url  + "/Channels/" + HttpEncode(channel.ChannelId) + "/Items?userId=" + getGlobalVar("user").Id
        else
            url = url  + "/Channels/" + HttpEncode(channel.Id) + "/Items?userId=" + getGlobalVar("user").Id
        end if
        
        ' Query
        query = {
            fields: "Overview,PrimaryImageAspectRatio"
        }

        if channel.ChannelId <> invalid
            q = { folderid: channel.Id }
            query.Append(q)
        end if
    end If
    
    for each key in query
        url = url + "&" + key +"=" + HttpEncode(query[key])
    end for
    
    print "Channel url: " + url

    return url

End Function
