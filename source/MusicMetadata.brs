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

Function getMusicAlbums(offset = invalid As Dynamic, limit = invalid As Dynamic, filters = invalid As Object) As Object
    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items"

    ' Query
    query = {
        recursive: "true"
        includeitemtypes: "MusicAlbum"
        fields: "Overview,PrimaryImageAspectRatio"
        sortby: "AlbumArtist,SortName"
        sortorder: "Ascending"
    }

    ' Filter/Sort Query
    if filters <> invalid
        query = AddToQuery(query, filters)
    end if

    ' Paging
    if limit <> invalid And offset <> invalid
        query.AddReplace("StartIndex", itostr(offset))
        query.AddReplace("Limit", itostr(limit))
    end if    

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

        return parseItemsResponse(response, 0, "mixed-aspect-ratio-square")
    end if

    return invalid
End Function


'**********************************************************
'** Get Music Artists
'**********************************************************

Function getMusicArtists(offset = invalid As Dynamic, limit = invalid As Dynamic, filters = invalid As Object) As Object
    ' URL
    url = GetServerBaseUrl() + "/Artists/AlbumArtists"

    ' Query
    query = {
        userid: getGlobalVar("user").Id
        recursive: "true"
        fields: "PrimaryImageAspectRatio"
        sortby: "SortName"
        sortorder: "Ascending"
    }

    if filters <> invalid
        query = AddToQuery(query, filters)
    end if

    if limit <> invalid And offset <> invalid
        query.AddReplace("StartIndex", itostr(offset))
        query.AddReplace("Limit", itostr(limit))
    end if    

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)

    if response <> invalid
        return parseItemsResponse(response, 0, "mixed-aspect-ratio-square")
    end if

	return invalid

End Function


'**********************************************************
'** Get Music Genres
'**********************************************************

Function getMusicGenres() As Object
    ' URL
    url = GetServerBaseUrl() + "/MusicGenres"

    ' Query
    query = {
        userid: getGlobalVar("user").Id
        recursive: "true"
        includeitemtypes: "Audio,MusicVideo"
        fields: "PrimaryImageAspectRatio"
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

        return parseItemsResponse(response, 0, "mixed-aspect-ratio-portrait")
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
        fields: "PrimaryImageAspectRatio,DateCreated"
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

        return parseItemsResponse(response, 0, "arced-square")
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
        fields: "PrimaryImageAspectRatio,DateCreated"
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

        return parseItemsResponse(response, 0, "arced-square")
    end if

    return invalid
End Function


'**********************************************************
'** Get Songs within an Album
'**********************************************************

Function musicmetadata_album_songs(albumId As String) As Object
    ' Validate Parameter
    if validateParam(albumId, "roString", "musicmetadata_album_songs") = false return invalid

    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items"

    ' Query
    query = {
        parentid: albumId
        recursive: "true"
        includeitemtypes: "Audio"
        fields: "PrimaryImageAspectRatio,MediaSources"
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
		return parseItemsResponse(response, 0, "list")
    end if

    return invalid
End Function
