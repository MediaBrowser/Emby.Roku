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
			parentId: m.parentId,
			ImageTypeLimit: "1"
		}
	else if row = 1
		url = url  + "/Artists/AlbumArtists?recursive=true"

		query = {
			fields: "Overview"
			sortby: "SortName"
			sortorder: "Ascending",
			parentId: m.parentId,
			UserId: getGlobalVar("user").Id,
			ImageTypeLimit: "1"
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
'** createMusicItemSpringboardScreen
'**********************************************************

Function createMusicItemSpringboardScreen(context, index, viewController) As Dynamic

    obj = createBaseSpringboardScreen(context, index, viewController)

    obj.SetupButtons = musicItemSpringboardSetupButtons
	
    obj.superHandleMessage = obj.HandleMessage
    obj.HandleMessage = musicItemSpringboardHandleMessage
	
	obj.GetMediaDetails = audioGetMediaDetails
	
	obj.itemInfo = context[index]

	if (obj.itemInfo.ContentType <> "MusicAlbum") then
		obj.screen.SetPosterStyle("rounded-rect-16x9-generic")
	end if
	
    return obj
End Function

Sub musicItemSpringboardSetupButtons()
    m.ClearButtons()
	
	if (m.itemInfo.ContentType = "MusicAlbum")
		m.AddButton("Track List", "tracklist")
	else
		m.AddButton("Album List", "albumlist")
	end if
	
	m.AddButton("Play All", "playall")
	m.AddButton("Shuffle", "shuffle")
	m.AddButton("Instant Mix", "instantmix")	
End Sub

'**********************************************************
'** musicGetSongsForItem
'**********************************************************

Function musicGetSongsForItem(item) As Object
	
	songs = []
	albums = []
	
	MusicMetadata = InitMusicMetadata()
	
	if (item.ContentType = "MusicArtist")
		albumData = MusicMetadata.GetArtistAlbums(item.Title)
		albums = albumData.Items
	else if (item.ContentType = "MusicGenre")
		albumData = MusicMetadata.GetGenreAlbums(item.Title)
		albums = albumData.Items
	else if (item.ContentType = "MusicAlbum")
		albums = [item]
	end if

	for each a in albums	
		aData = MusicMetadata.GetAlbumSongs(a.Id)
		songs.Append(aData.Items)
	end for	
		
	return songs	
		
End Function

'**********************************************************
'** musicGetInstantMixForItem
'**********************************************************

Function musicGetInstantMixForItem(item) As Object

	mixItems = []
		
	url = GetServerBaseUrl()
	userId = HttpEncode(getGlobalVar("user").Id)
	fieldsString = "&fields=" + HttpEncode("PrimaryImageAspectRatio,MediaSources")
	
	if (item.ContentType = "MusicAlbum")
		url = url + "/Albums/" + HttpEncode(item.id)
	else if (item.ContentType = "MusicArtist")
		url = url + "/Artists/" + HttpEncode(item.Title)
	else if (item.ContentType = "MusicGenre")
		url = url + "/MusicGenres/" + HttpEncode(item.Title)
	end if
	
	url = url + "/InstantMix?UserId=" + userId + fieldsString + "&Limit=100"
	
    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
	
    ' Execute Request
    response = request.GetToStringWithTimeout(10)
	
	if response <> invalid	
		container = parseItemsResponse(response, 0, "list")
		mixItems = container.items
	end if	
	
	return mixItems
End Function

'**********************************************************
'** createMusicListScreen
'**********************************************************

Function createMusicListScreen(viewController as Object, tracks As Object) As Object

    screen = CreateListScreen(viewController)

	screen.baseHandleMessage = screen.HandleMessage
	screen.HandleMessage = musicSongsHandleMessage

    player = AudioPlayer()

    totalDuration = GetTotalDuration(tracks)

    screen.SetHeader("Tracks (" + itostr(tracks.Count()) + ") - " + totalDuration)

    if getGlobalVar("legacyDevice")
        backButton = {
            Title: ">> Back <<",
            ContentType: "exit",
        }

        musicData.Items.Unshift( backButton )
    end if

    screen.SetContent(tracks)

    player.SetRepeat(0)

    screen.prevIconIndex = invalid
    screen.focusedItemIndex = 0
	screen.audioItems = tracks

	screen.IsShuffled = false
	
	screen.playFromIndex = musicSongsPlayFromIndex

    return screen

End Function

'**********************************************************
'** createMusicSongsScreen
'**********************************************************

Function createMusicSongsScreen(viewController as Object, artistInfo As Object) As Object
    MusicMetadata = InitMusicMetadata()
    musicData = MusicMetadata.GetAlbumSongs(artistInfo.Id)
	return createMusicListScreen(viewController, musicData.Items)
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
'** musicItemSpringboardHandleMessage
'**********************************************************
	
Function musicItemSpringboardHandleMessage(msg) As Boolean
    handled = false

    if type(msg) = "roSpringboardScreenEvent" then
        if msg.isButtonPressed() then
            handled = true
            buttonCommand = m.buttonCommands[str(msg.getIndex())]
            Debug("Button command: " + tostr(buttonCommand))
			
		breadcrumbText = m.itemInfo.Title
		screenName = tostr(buttonCommand) + " " + tostr(m.itemInfo.id)
		startPlaying = true
		busyDialog = invalid
		
		if (buttonCommand = "albumlist") then
			if (m.itemInfo.ContentType = "MusicArtist")
				listScreen = createMusicAlbumsScreen(m.ViewController, m.itemInfo)
			else if (m.itemInfo.ContentType = "MusicGenre")
				listScreen = createMusicGenresScreen(m.ViewController, m.itemInfo.Title)
			end if
			
			startPlaying = false
		else
		
			if (buttonCommand = "instantmix") then
			
				' This might take a few seconds.  
				' Show dialog to keep the user informed.
				
				busyDialog = CreateObject("roMessageDialog")
				busyDialog.SetTitle("Creating Playlist")
				busyDialog.ShowBusyAnimation()
				busyDialog.Show()
				
				tracks = musicGetInstantMixForItem(m.itemInfo)
				breadcrumbText = "Instant Mix For " + breadcrumbText
				screenName = "instantmix " + screenName
			else
				tracks = musicGetSongsForItem(m.itemInfo)
				
				if (buttonCommand = "shuffle") AND (tracks.Count() > 1) then 
					startIndex = rnd(tracks.Count()) - 1
					ShuffleArray(tracks, startIndex)
				end if
				
				if (buttonCommand = "tracklist") then startPlaying = false
				
				if (m.itemInfo.ContentType = "MusicAlbum") AND (m.itemInfo.Artist <> invalid) AND (m.itemInfo.Artist <> "") then
						breadcrumbText = m.itemInfo.Artist + " - " + breadcrumbText
				end if	
			end if	
						
			listScreen = createMusicListScreen(m.ViewController, tracks)
		end if
		
		m.ViewController.AddBreadcrumbs(listScreen, [breadcrumbText])
		m.ViewController.UpdateScreenProperties(listScreen)
		m.ViewController.PushScreen(listScreen)
		if (busyDialog <> invalid) then busyDialog.Close()
		listScreen.Show()
		
		if (startPlaying) then listScreen.PlayFromIndex(0)
							            
		end if
	end if

	return handled OR m.superHandleMessage(msg)
end Function	

'**********************************************************
'** GetTotalDuration
'**********************************************************

Function GetTotalDuration(songs As Object) As String
    
	total = 0
    For each songData in songs
		songLength = songData.Length
        total = total + firstOf(songLength, 0)
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
