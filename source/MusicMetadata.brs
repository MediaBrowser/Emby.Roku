'*****************************************************************
'**  Media Browser Roku Client - Music Metadata Class
'*****************************************************************


Function ClassMusicMetadata()
    ' initializes static members once
    this = m.ClassMusicMetadata

    if this = invalid
        this = CreateObject("roAssociativeArray")

        ' constants
        this.class        = "MusicMetadata"

        'variables
        this.jumpList     = {}

        ' functions
        this.GetAlbums       = musicmetadata_albums
        this.GetArtists      = musicmetadata_artists
        this.GetGenres       = musicmetadata_genres
        this.GetArtistAlbums = musicmetadata_artist_albums
        this.GetGenreAlbums  = musicmetadata_genre_albums
        this.GetAlbumSongs   = musicmetadata_album_songs

        ' singleton
        m.ClassMusicMetadata = this
    end if
    
    return this
End Function


Function InitMusicMetadata()
    this = ClassMusicMetadata()
    return this
End Function


'**********************************************************
'** Get Music Albums
'**********************************************************

Function musicmetadata_albums() As Object
    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items"

    ' Query
    query = {
        recursive: "true"
        includeitemtypes: "MusicAlbum"
        fields: "ItemCounts,DateCreated,UserData,AudioInfo,ParentId,SortName"
        sortby: "SortName"
        sortorder: "Ascending"
    }

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

        contentList = CreateObject("roArray", 15, true)
        jsonObj     = ParseJSON(response)

        if jsonObj = invalid
            Debug("Error while parsing JSON response for Music Albums")
            return invalid
        end if

        for each i in jsonObj.Items
            metaData = {}

            ' Set the Content Type
            metaData.ContentType = "Album"

            ' Set the Id
            metaData.Id = i.Id

            ' Set the display title
            metaData.Title = firstOf(i.Name, "Unknown")
            metaData.ShortDescriptionLine1 = firstOf(i.Name, "Unknown")

            ' Set the Song Count as Line 2 Display
            if i.ChildCount <> invalid
                metaData.ShortDescriptionLine2 = Pluralize(i.ChildCount, "song")
            end if

            ' Set the Artist Name
            if i.AlbumArtist <> "" And i.AlbumArtist <> invalid
                metaData.Artist = i.AlbumArtist
            else if i.Artists[0] <> "" And i.Artists[0] <> invalid
                metaData.Artist = i.Artists[0]
            else
                metaData.Artist = ""
            end if

            ' Get Image Sizes
            sizes = GetImageSizes("arced-square")

            ' Check if Item has Image, otherwise use default
            if i.ImageTags.Primary <> "" And i.ImageTags.Primary <> invalid
                imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.Id) + "/Images/Primary/0"

                metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ImageTags.Primary)
                metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ImageTags.Primary)

            else 
                metaData.HDPosterUrl = "pkg://images/items/collection.png"
                metaData.SDPosterUrl = "pkg://images/items/collection.png"

            end if

            contentList.push( metaData )
        end for
        
        return contentList
    else
        Debug("Failed to Get Music Albums")
    end if

    return invalid
End Function


'**********************************************************
'** Get Music Artists
'**********************************************************

Function musicmetadata_artists() As Object
    ' URL
    url = GetServerBaseUrl() + "/Artists"

    ' Query
    query = {
        userid: getGlobalVar("user").Id
        recursive: "true"
        fields: "ItemCounts,UserData,SortName"
        sortby: "SortName"
        sortorder: "Ascending"
    }

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

        contentList = CreateObject("roArray", 15, true)
        jsonObj     = ParseJSON(response)

        if jsonObj = invalid
            Debug("Error while parsing JSON response for Music Artists")
            return invalid
        end if

        for each i in jsonObj.Items
            metaData = {}

            ' Set the Content Type
            metaData.ContentType = "Artist"

            ' Set the Id
            metaData.Id = i.Id

            ' Set the display title
            metaData.Title = firstOf(i.Name, "Unknown")
            metaData.ShortDescriptionLine1 = firstOf(i.Name, "Unknown")

            ' Set the Song Count as Line 2 Display
            if i.ChildCount <> invalid
                metaData.ShortDescriptionLine2 = Pluralize(i.ChildCount, "song")
            end if

            ' Get Image Sizes
            sizes = GetImageSizes("arced-square")

            ' Check if Item has Image, otherwise use default
            if i.ImageTags.Primary <> "" And i.ImageTags.Primary <> invalid
                imageUrl = GetServerBaseUrl() + "/Artists/" + HttpEncode(i.Name) + "/Images/Primary/0"

                metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ImageTags.Primary)
                metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ImageTags.Primary)

            else 
                metaData.HDPosterUrl = "pkg://images/items/collection.png"
                metaData.SDPosterUrl = "pkg://images/items/collection.png"

            end if

            contentList.push( metaData )
        end for
        
        return contentList
    else
        Debug("Failed to Get Music Artists")
    end if

    return invalid
End Function


'**********************************************************
'** Get Music Genres
'**********************************************************

Function musicmetadata_genres() As Object
    ' URL
    url = GetServerBaseUrl() + "/MusicGenres"

    ' Query
    query = {
        userid: getGlobalVar("user").Id
        recursive: "true"
        includeitemtypes: "Audio"
        fields: "ItemCounts"
        sortby: "SortName"
        sortorder: "Ascending"
    }

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

        contentList = CreateObject("roArray", 10, true)
        jsonObj     = ParseJSON(response)

        if jsonObj = invalid
            Debug("Error while parsing JSON response for Genres for Music")
            return invalid
        end if

        for each i in jsonObj.Items
            metaData = {}

            ' Set the Content Type
            metaData.ContentType = "Genre"

            ' Set the Id
            ' Genres Use Name as Id
            metaData.Id = firstOf(i.Name, "Unknown")

            ' Set the display title
            metaData.Title = firstOf(i.Name, "Unknown")
            metaData.ShortDescriptionLine1 = firstOf(i.Name, "Unknown")

            ' Set Song Count
            if i.ChildCount <> invalid
                metaData.ShortDescriptionLine2 = Pluralize(i.ChildCount, "song")
            end if

            ' Get Image Sizes
            sizes = GetImageSizes("arced-square")

            ' Use Primary Or Backdrop Image
            if i.ImageTags.Primary <> "" And i.ImageTags.Primary <> invalid
                imageUrl = GetServerBaseUrl() + "/MusicGenres/" + HttpEncode(i.Name) + "/Images/Primary/0"

                metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ImageTags.Primary)
                metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ImageTags.Primary)

            else if i.BackdropImageTags[0] <> "" And i.BackdropImageTags[0] <> invalid
                imageUrl = GetServerBaseUrl() + "/MusicGenres/" + HttpEncode(i.Name) + "/Images/Backdrop/0"

                metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.BackdropImageTags[0])
                metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.BackdropImageTags[0])

            else 
                metaData.HDPosterUrl = "pkg://images/items/collection.png"
                metaData.SDPosterUrl = "pkg://images/items/collection.png"

            end if

            contentList.push( metaData )
        end for
        
        return contentList
    else
        Debug("Failed to Get Genres for Music")
    end if

    return invalid
End Function


'**********************************************************
'** Get Albums by Artist
'**********************************************************

Function musicmetadata_artist_albums(artistName As String) As Object
    ' Validate Parameter
    if validateParam(artistName, "roString", "musicmetadata_artist_albums") = false return invalid

    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items"

    ' Query
    query = {
        artists: artistName
        recursive: "true"
        includeitemtypes: "MusicAlbum"
        fields: "ItemCounts,DateCreated,UserData,AudioInfo,ParentId"
        sortby: "SortName"
        sortorder: "Ascending"
    }

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

        contentList = CreateObject("roArray", 10, true)
        jsonObj     = ParseJSON(response)

        if jsonObj = invalid
            Debug("Error while parsing JSON response for Albums by Artist")
            return invalid
        end if

        for each i in jsonObj.Items
            metaData = {}

            ' Set the Content Type
            metaData.ContentType = "Album"

            ' Set the Id
            metaData.Id = i.Id

            ' Set the display title
            metaData.Title = firstOf(i.Name, "Unknown")
            metaData.ShortDescriptionLine1 = firstOf(i.Name, "Unknown")

            ' Set the Song Count as Line 2 Display
            if i.ChildCount <> invalid
                metaData.ShortDescriptionLine2 = Pluralize(i.ChildCount, "song")
            end if

            ' Set the Artist Name
            if i.AlbumArtist <> "" And i.AlbumArtist <> invalid
                metaData.Artist = i.AlbumArtist
            else if i.Artists[0] <> "" And i.Artists[0] <> invalid
                metaData.Artist = i.Artists[0]
            else
                metaData.Artist = ""
            end if

            ' Get Image Sizes
            sizes = GetImageSizes("arced-square")

            ' Check if Item has Image, otherwise use default
            if i.ImageTags.Primary <> "" And i.ImageTags.Primary <> invalid
                imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.Id) + "/Images/Primary/0"

                metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ImageTags.Primary)
                metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ImageTags.Primary)

            else 
                metaData.HDPosterUrl = "pkg://images/items/collection.png"
                metaData.SDPosterUrl = "pkg://images/items/collection.png"

            end if

            contentList.push( metaData )
        end for
        
        return contentList
    else
        Debug("Failed to Get Albums by an Artist")
    end if

    return invalid
End Function


'**********************************************************
'** Get Albums by Genre
'**********************************************************

Function musicmetadata_genre_albums(genreName As String) As Object
    ' Validate Parameter
    if validateParam(genreName, "roString", "musicmetadata_genre_albums") = false return invalid

    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items"

    ' Query
    query = {
        genres: genreName
        recursive: "true"
        includeitemtypes: "MusicAlbum"
        fields: "ItemCounts,DateCreated,UserData,AudioInfo,ParentId"
        sortby: "SortName"
        sortorder: "Ascending"
    }

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

        contentList = CreateObject("roArray", 10, true)
        jsonObj     = ParseJSON(response)

        if jsonObj = invalid
            Debug("Error while parsing JSON response for Albums by Genre")
            return invalid
        end if

        for each i in jsonObj.Items
            metaData = {}

            ' Set the Content Type
            metaData.ContentType = "Album"

            ' Set the Id
            metaData.Id = i.Id

            ' Set the display title
            metaData.Title = firstOf(i.Name, "Unknown")
            metaData.ShortDescriptionLine1 = firstOf(i.Name, "Unknown")

            ' Set the Song Count as Line 2 Display
            if i.ChildCount <> invalid
                metaData.ShortDescriptionLine2 = Pluralize(i.ChildCount, "song")
            end if

            ' Set the Artist Name
            if i.AlbumArtist <> "" And i.AlbumArtist <> invalid
                metaData.Artist = i.AlbumArtist
            else if i.Artists[0] <> "" And i.Artists[0] <> invalid
                metaData.Artist = i.Artists[0]
            else
                metaData.Artist = ""
            end if

            ' Get Image Sizes
            sizes = GetImageSizes("arced-square")

            ' Check if Item has Image, otherwise use default
            if i.ImageTags.Primary <> "" And i.ImageTags.Primary <> invalid
                imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.Id) + "/Images/Primary/0"

                metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ImageTags.Primary)
                metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ImageTags.Primary)

            else 
                metaData.HDPosterUrl = "pkg://images/items/collection.png"
                metaData.SDPosterUrl = "pkg://images/items/collection.png"

            end if

            contentList.push( metaData )
        end for
        
        return contentList
    else
        Debug("Failed to Get Albums by Genre")
    end if

    return invalid
End Function


'**********************************************************
'** Get Songs within an Album
'**********************************************************

Function musicmetadata_album_songs(artistId As String) As Object
    ' Validate Parameter
    if validateParam(artistId, "roString", "musicmetadata_album_songs") = false return invalid

    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items"

    ' Query
    query = {
        parentid: artistId
        recursive: "true"
        includeitemtypes: "Audio"
        fields: "ItemCounts,DateCreated,UserData,AudioInfo,ParentId,Path,MediaStreams"
        sortby: "SortName"
        sortorder: "Ascending"
    }

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

        ' Fixes bug within BRS Json Parser
        regex         = CreateObject("roRegex", Chr(34) + "(RunTimeTicks)" + Chr(34) + ":(-?[0-9]+),", "i")
        fixedResponse = regex.ReplaceAll(response, Chr(34) + "\1" + Chr(34) + ":" + Chr(34) + "\2" + Chr(34) + ",")

        songListCount = 1
        contentList = CreateObject("roArray", 10, true)
        streamList  = CreateObject("roArray", 10, true)
        jsonObj     = ParseJSON(fixedResponse)

        if jsonObj = invalid
            Debug("Error while parsing JSON response for Songs within an Album")
            return invalid
        end if

        for each i in jsonObj.Items
            metaData = {}

            ' Set the Content Type
            metaData.ContentType = "Audio"

            ' Set the Id
            metaData.Id = i.Id

            ' Set the Run Time
            if i.RunTimeTicks <> "" And i.RunTimeTicks <> invalid
                metaData.Length = Int(((i.RunTimeTicks).ToFloat() / 10000) / 1000)
            end if

            ' Build Song Information for Title Display
            songInfo = itostr(index) + "."

            ' Add Song Name
            if i.Name <> invalid
                songInfo = songInfo + " " + i.Name
            end if

            ' Add Song Time
            if i.RunTimeTicks <> "" And i.RunTimeTicks <> invalid
                songInfo = songInfo + " - " + FormatChapterTime(i.RunTimeTicks)
            end if

            ' Set the Title with song info
            metaData.Title = songInfo

            ' Setup Song; Improve this
            streamData = SetupAudioStream(i.Id, i.Path)

            ' Get Image Sizes
            sizes = GetImageSizes("list")

            ' Check if Item has Image, otherwise use default
            if i.ImageTags.Primary <> "" And i.ImageTags.Primary <> invalid
                imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.ParentId) + "/Images/Primary/0"

                metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ImageTags.Primary)
                metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ImageTags.Primary)

            else 
                metaData.HDPosterUrl = "pkg://images/items/collection.png"
                metaData.SDPosterUrl = "pkg://images/items/collection.png"

            end if

            ' Increment Count
            songListCount = songListCount + 1

            contentList.push( metaData )
            streamList.push( streamData )
        end for

        ' Improve this
        return {
            SongInfo: contentList
            SongStreams: streamList
        }
    else
        Debug("Failed to Get Songs within an Album")
    end if

    return invalid
End Function
