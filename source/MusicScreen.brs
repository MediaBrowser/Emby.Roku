'**********************************************************
'** createMusicLibraryScreen
'**********************************************************

Function createMusicLibraryScreen(viewController as Object, parentId as String) As Object

	names = ["Albums", "Artists", "Jump Into Albums", "Jump Into Artists", "Genres"]
	keys = ["0", "1", "2", "3", "4"]

	loader = CreateObject("roAssociativeArray")
	loader.getUrl = getMusicLibraryRowScreenUrl
	loader.parsePagedResult = parseMusicLibraryScreenResult
	loader.getLocalData = getMusicLibraryScreenLocalData
	loader.parentId = parentId

    screen = createPaginatedGridScreen(viewController, names, keys, loader, "two-row-flat-landscape-custom")

    return screen
End Function

Function getMusicLibraryScreenLocalData(row as Integer, id as String, startItem as Integer, count as Integer) as Object

	if row = 2 then
		return getAlphabetList("MusicAlbumAlphabet", m.parentId)
	else if row = 3 then
		return getAlphabetList("MusicArtistAlphabet", m.parentId)
	end If

    return invalid

End Function

Function getMusicLibraryRowScreenUrl(row as Integer, id as String) as String

    ' URL
    url = GetServerBaseUrl()

    ' Query
    query = {}

	if row = 0
		url = url  + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"

		query = {
			IncludeItemTypes: "MusicAlbum"
			fields: "Overview"
			sortby: "AlbumArtist,SortName"
			sortorder: "Ascending",
			parentId: m.parentId
		}
	else if row = 1
		url = url  + "/Artists/AlbumArtists?recursive=true"

		query = {
			fields: "Overview"
			sortby: "SortName"
			sortorder: "Ascending",
			parentId: m.parentId,
			UserId: getGlobalVar("user").Id
		}
	else if row = 2
		' Music album alphabet - should never get in here
	else if row = 3
		' Music artist alphabet - should never get in here
	else if row = 4
		url = url  + "/MusicGenres?recursive=true"

		query = {
			userid: getGlobalVar("user").Id
			recursive: "true"
			sortby: "SortName"
			sortorder: "Ascending",
			parentId: m.parentId
		}
	end If

	for each key in query
		url = url + "&" + key +"=" + HttpEncode(query[key])
	end for

    return url

End Function

Function parseMusicLibraryScreenResult(row as Integer, id as string, startIndex as Integer, json as String) as Object

	imageType      = 1
	primaryImageStyle = "two-row-flat-landscape-custom"
	mode = ""

	if row <> 4 then primaryImageStyle = "arced-square"

    return parseItemsResponse(json, imageType, primaryImageStyle, mode)

End Function

'**********************************************************
'** createMusicAlbumsScreen
'**********************************************************

Function createMusicAlbumsScreen(viewController as Object, artistInfo As Object) As Object

    screen = CreatePosterScreen(viewController, artistInfo, "arced-square")

	screen.GetDataContainer = getMusicAlbumsDataContainer

    return screen

End Function

Function getMusicAlbumsDataContainer(viewController as Object, item as Object) as Object

    MusicMetadata = InitMusicMetadata()

    musicData = MusicMetadata.GetArtistAlbums(item.Title)

    if musicData = invalid
        return invalid
    end if

	obj = CreateObject("roAssociativeArray")
	obj.names = []
	obj.keys = []
	obj.items = musicData.Items

	return obj

End Function

'**********************************************************
'** createMusicArtistsAlphabetScreen
'**********************************************************

Function createMusicArtistsAlphabetScreen(viewController as Object, letter As String, parentId = invalid) As Object

	' Dummy up an item
	item = CreateObject("roAssociativeArray")
	item.Title = letter

    screen = CreatePosterScreen(viewController, item, "arced-square")

	screen.ParentId = parentId
	screen.GetDataContainer = getMusicArtistsAlphabetDataContainer

    return screen
End Function

Function getMusicArtistsAlphabetDataContainer(viewController as Object, item as Object) as Object

    letter = item.Title

    if letter = "#" then
        filters = {
            NameLessThan: "a"
        }
    else
        filters = {
            NameStartsWith: letter
        }
    end if
	
	if m.ParentId <> invalid then filters.ParentId = m.ParentId

    musicData = getMusicArtists(invalid, invalid, filters)
    if musicData = invalid
        return invalid
    end if

	obj = CreateObject("roAssociativeArray")
	obj.names = []
	obj.keys = []
	obj.items = musicData.Items

	return obj

End Function


'**********************************************************
'** createMusicAlbumsAlphabetScreen
'**********************************************************

Function createMusicAlbumsAlphabetScreen(viewController as Object, letter As String, parentId = invalid) As Object

	' Dummy up an item
	item = CreateObject("roAssociativeArray")
	item.Title = letter

    screen = CreatePosterScreen(viewController, item, "arced-square")

	screen.ParentId = parentId
	screen.GetDataContainer = getMusicAlbumsAlphabetDataContainer

    return screen

End Function

Function getMusicAlbumsAlphabetDataContainer(viewController as Object, item as Object) as Object

    letter = item.Title

    if letter = "#" then
        filters = {
            NameLessThan: "a"
        }
    else
        filters = {
            NameStartsWith: letter
        }
    end if
	
	if m.ParentId <> invalid then filters.ParentId = m.ParentId

    musicData = getMusicAlbums(invalid, invalid, filters)
    if musicData = invalid
        return invalid
    end if

	obj = CreateObject("roAssociativeArray")
	obj.names = []
	obj.keys = []
	obj.items = musicData.Items

	return obj

End Function

'**********************************************************
'** createMusicGenresScreen
'**********************************************************

Function createMusicGenresScreen(viewController as Object, genre As String) As Object

    if validateParam(genre, "roString", "createMusicGenresScreen") = false return -1

	' Dummy up an item
	item = CreateObject("roAssociativeArray")
	item.Title = genre

    screen = CreatePosterScreen(viewController, item, "arced-square")

 	screen.GetDataContainer = getMusicGenreDataContainer

    return screen

End Function

Function getMusicGenreDataContainer(viewController as Object, item as Object) as Object

    genre = item.Title

    MusicMetadata = InitMusicMetadata()

    musicData = MusicMetadata.GetGenreAlbums(genre)
    if musicData = invalid
        return invalid
    end if

	obj = CreateObject("roAssociativeArray")
	obj.names = []
	obj.keys = []
	obj.items = musicData.Items

	return obj

End Function

'**********************************************************
'** createMusicSongsScreen
'**********************************************************

Function createMusicSongsScreen(viewController as Object, artistInfo As Object) As Object

    screen = CreateListScreen(viewController)

	screen.baseHandleMessage = screen.HandleMessage
	screen.HandleMessage = musicSongsHandleMessage

    player = AudioPlayer()

    MusicMetadata = InitMusicMetadata()

    musicData = MusicMetadata.GetAlbumSongs(artistInfo.Id)

    totalDuration = GetTotalDuration(musicData.Items)

    screen.SetHeader("Tracks (" + itostr(musicData.Items.Count()) + ") - " + totalDuration)

    if getGlobalVar("legacyDevice")
        backButton = {
            Title: ">> Back <<",
            ContentType: "exit",
        }

        musicData.Items.Unshift( backButton )
    end if

    screen.SetContent(musicData.Items)

    player.SetRepeat(0)

    screen.prevIconIndex = invalid
    screen.focusedItemIndex = 0
	screen.audioItems = musicData.Items

	screen.IsShuffled = false
	
	screen.playFromIndex = musicSongsPlayFromIndex

    return screen

End Function

Sub musicSongsPlayFromIndex(index)

	player = AudioPlayer()
	
	player.SetContextFromItems(m.audioItems, index, m, true)
	player.Play()
				
End Sub

Function musicSongsHandleMessage(msg) As Boolean
    handled = false

	viewController = m.ViewController

    player = AudioPlayer()

    remoteKeyOK     = 6
    remoteKeyRev    = 8
    remoteKeyFwd    = 9
    remoteKeyStar   = 10
    remoteKeyPause  = 13

    If type(msg) = "roAudioPlayerEvent" Then

        If msg.isListItemSelected() Then

            If m.prevIconIndex<>invalid HideSpeakerIcon(m, m.prevIconIndex)
            m.prevIconIndex = ShowSpeakerIcon(m, player.CurIndex)

            m.SetFocusedItem(m.focusedItemIndex)

        Else If msg.isPaused()

            ShowPauseIcon(m, player.CurIndex)

            m.SetFocusedItem(m.focusedItemIndex)

        Else If msg.isFullResult() Then
                
            HideSpeakerIcon(m, m.prevIconIndex, true)

        Else If msg.isResumed()

            ShowSpeakerIcon(m, player.CurIndex)

            m.SetFocusedItem(m.focusedItemIndex)

        End If

    Else If type(msg) = "roListScreenEvent" Then

        If msg.isListItemFocused() Then

            handled = true

            m.focusedItemIndex = msg.GetIndex()

        Else If msg.isListItemSelected() Then

            handled = true

            if m.audioItems[msg.GetIndex()].ContentType = "exit"

                Debug("Close Music Album Screen")
                If player.IsPlaying Then
                    player.Stop()
                End If

				m.Screen.Close()

            else

				player.SetContextFromItems(m.audioItems, msg.GetIndex(), m, true)
				player.Play()
            end if

        Else If msg.isScreenClosed() Then

            Debug("Close Music Album Screen")
            If player.IsPlaying Then
                player.Stop()
            End If

        Else If msg.isRemoteKeyPressed()

            handled = true

            index = msg.GetIndex()

            If index = remoteKeyPause Then
                If player.IsPaused player.Resume() Else player.Pause()

            Else If index = remoteKeyRev Then
                Print "Previous Song"
                If player.IsPlaying player.Prev()

            Else If index = remoteKeyFwd Then
                Print "Next Song"
                If player.IsPlaying player.Next()

            End If

        End If

    End If

	if handled = false then
		handled = m.baseHandleMessage(msg)
	end if

    return handled
End Function


'**********************************************************
'** GetTotalDuration
'**********************************************************

Function GetTotalDuration(songs As Object) As String
    
	total = 0
    For each songData in songs
        total = total + songData.Length
    End For

    Return FormatTime(total)
End Function

'**********************************************************
'** ShowSpeakerIcon
'**********************************************************

Function ShowSpeakerIcon(screen As Object, index As Integer) As Integer

	items = screen.audioItems

    items[index].HDSmallIconUrl = GetViewController().getThemeImageUrl("SpeakerIcon.png")
    items[index].SDSmallIconUrl = GetViewController().getThemeImageUrl("SpeakerIcon.png")

    screen.SetContent(items)
    screen.Show()

    Return index
End Function

'**********************************************************
'** ShowPauseIcon
'**********************************************************

Function ShowPauseIcon(screen As Object, index As Integer)

	items = screen.audioItems

    items[index].HDSmallIconUrl = GetViewController().getThemeImageUrl("PauseIcon.png")
    items[index].SDSmallIconUrl = GetViewController().getThemeImageUrl("PauseIcon.png")

    screen.SetContent(items)
End Function

'**********************************************************
'** HideSpeakerIcon
'**********************************************************

Function HideSpeakerIcon(screen As Object, index As Integer, refreshScreen=invalid)
	items = screen.audioItems

    items[index].HDSmallIconUrl = false
    items[index].SDSmallIconUrl = false

    If refreshScreen<>invalid Then
		screen.SetContent(items)
    End If
End Function