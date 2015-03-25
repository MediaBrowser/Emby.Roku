'**********************************************************
'** createVideoSpringboardScreen
'** Credit: Plex Roku https://github.com/plexinc/roku-client-public
'**********************************************************

Function createVideoSpringboardScreen(context, index, viewController) As Object

    obj = createBaseSpringboardScreen(context, index, viewController)

    obj.SetupButtons = videoSetupButtons
    obj.GetMediaDetails = videoGetMediaDetails
    obj.baseHandleMessage = obj.HandleMessage
    obj.HandleMessage = handleVideoSpringboardScreenMessage

	obj.ContinuousPlay = false

    obj.checkChangesOnActivate = false
    obj.refreshOnActivate = false
    obj.closeOnActivate = false
    obj.Activate = videoActivate

	obj.DeleteLiveTvRecording = springboardDeleteRecording
	obj.CancelLiveTvTimer = springboardCancelTimer
	obj.RecordLiveTvProgram = springboardRecordProgram
	obj.ShowStreamsDialog = springboardShowStreamsDialog
	obj.ShowMoreDialog = springboardShowMoreDialog
	obj.ShowFilmography = springboardShowFilmography
	
	obj.PlayOptions = {}

    obj.Screen.SetDescriptionStyle("movie")

    if NOT AudioPlayer().IsPlaying AND firstOf(RegRead("prefThemeMusic"), "yes") = "yes" then
        AudioPlayer().PlayThemeMusic(obj.Item)
        obj.Cleanup = baseStopAudioPlayer

    end if

    return obj

End Function

'**************************************************************
'** videoSetupButtons
'**************************************************************

Sub videoSetupButtons()
    m.ClearButtons()

	video = m.metadata

    if video.ContentType = "Program" And video.PlayAccess = "Full"
	
        if canPlayProgram(video)
			m.AddButton("Play", "play")
        end if

        if video.TimerId <> invalid
			m.AddButton("Cancel recording", "cancelrecording")
			
        else if canRecordProgram(video)
			m.AddButton("Schedule recording", "record")
        end if

    else if video.LocationType <> "Virtual" And video.PlayAccess = "Full"

		' This screen is also used for books and games, so don't show a play button
		if video.MediaType = "Video" then
			if video.BookmarkPosition <> 0 then
		
				m.AddButton("Resume", "resume")
				m.AddButton("Play from beginning", "play")
			else
				m.AddButton("Play", "play")
			end if
		end if

        if video.Chapters <> invalid and video.Chapters.Count() > 0
			m.AddButton("Play from scene", "scenes")
        end if

        if video.LocalTrailerCount <> invalid and video.LocalTrailerCount > 0
            if video.LocalTrailerCount > 1
				m.AddButton("Trailers", "trailers")
            else
				m.AddButton("Trailer", "trailer")
            end if
        end if

		audioStreams = []
		subtitleStreams = []

		if video.StreamInfo <> invalid then
			for each stream in video.StreamInfo.MediaSource.MediaStreams
				if stream.Type = "Audio" then audioStreams.push(stream)
				if stream.Type = "Subtitle" then subtitleStreams.push(stream)
			end For
		end if

        if audioStreams.Count() > 1 Or subtitleStreams.Count() > 0
            m.AddButton("Audio & Subtitles", "streams")
        end if

		m.audioStreams = audioStreams
		m.subtitleStreams = subtitleStreams

    end if

    if video.ContentType = "Recording"
        m.AddButton("Delete", "delete")
    end if
	
	if video.ContentType = "Person"
		m.AddButton("Filmography", "filmography")
	end if
	
    ' rewster: TV Program recording does not need a more button, and displaying it stops the back button from appearing on programmes that have past
	if video.ContentType <> "Program"
		m.AddButton("More...", "more")
	end if

    if m.buttonCount = 0
		m.AddButton("Back", "back")
    end if

End Sub

'**********************************************************
'** canPlayProgram
'**********************************************************

Function canPlayProgram(item as Object) As Boolean

	startDateString = item.StartDate
	endDateString = item.EndDate
	
	if startDateString = invalid or endDateString = invalid then return false
	
    ' Current Time
    nowTime = CreateObject("roDateTime")
    nowTime.ToLocalTime()
    nowTimeSeconds = nowTime.AsSeconds()

    ' Start Time
    startTime = CreateObject("roDateTime")
    startTime.FromISO8601String(startDateString)
    startTime.ToLocalTime()

    ' End Time
    endTime = CreateObject("roDateTime")
    endTime.FromISO8601String(endDateString)
    endTime.ToLocalTime()

    return nowTimeSeconds >= startTime.AsSeconds() And nowTimeSeconds < endTime.AsSeconds()
	
End Function

'**********************************************************
'** canRecordProgram
'**********************************************************

Function canRecordProgram(item as Object) As Boolean

	endDateString = item.EndDate
	
	if endDateString = invalid then return false
	
    ' Current Time
    nowTime = CreateObject("roDateTime")
    nowTime.ToLocalTime()

    ' End Time
    endTime = CreateObject("roDateTime")
    endTime.FromISO8601String(endDateString)
    endTime.ToLocalTime()

    return nowTime.AsSeconds() < endTime.AsSeconds()
	
End Function

'**************************************************************
'** videoGetMediaDetails
'**************************************************************

Sub videoGetMediaDetails(content)

    m.metadata = GetFullItemMetadata(content, false, {})
	
	streamInfo = m.metadata.StreamInfo
	
	if streamInfo <> invalid then
		m.PlayOptions.SubtitleStreamIndex = streamInfo.SubtitleStreamIndex
		m.PlayOptions.AudioStreamIndex = streamInfo.AudioStreamIndex
		m.PlayOptions.MediaSourceId = streamInfo.MediaSource.Id
	end if

End Sub

'**************************************************************
'** videoActivate
'**************************************************************

Sub videoActivate(priorScreen)

    if m.closeOnActivate then
        m.Screen.Close()
        return
    end if

    if m.checkChangesOnActivate AND priorScreen.Changes <> invalid then

        m.checkChangesOnActivate = false

        if priorScreen.Changes.DoesExist("continuous_play") then
            m.ContinuousPlay = (priorScreen.Changes["continuous_play"] = "1")
            priorScreen.Changes.Delete("continuous_play")
        end if

        if NOT priorScreen.Changes.IsEmpty() then
            m.Refresh(true)
        end if
    end if

    if m.refreshOnActivate then
	
		m.refreshOnActivate = false
		
        if m.ContinuousPlay AND (priorScreen.isPlayed = true) then
            m.GotoNextItem()

			m.PlayOptions.PlayStart = 0
            
			m.ViewController.CreatePlayerForItem([m.metadata], 0, m.PlayOptions)
        else
            m.Refresh(true)

			m.refreshOnActivate = false
        end if
    end if
End Sub

'**************************************************************
'** handleVideoSpringboardScreenMessage
'**************************************************************

Function handleVideoSpringboardScreenMessage(msg) As Boolean

    handled = false

    if type(msg) = "roSpringboardScreenEvent" then

		item = m.metadata
		itemId = item.Id
		viewController = m.ViewController

        if msg.isButtonPressed() then

            handled = true
            buttonCommand = m.buttonCommands[str(msg.getIndex())]
            Debug("Button command: " + tostr(buttonCommand))

            if buttonCommand = "play" then

                m.PlayOptions.PlayStart = 0
				m.ViewController.CreatePlayerForItem([item], 0, m.PlayOptions)

                ' Refresh play data after playing.
                m.refreshOnActivate = true

            else if buttonCommand = "resume" then

				m.PlayOptions.PlayStart = item.BookmarkPosition
				m.ViewController.CreatePlayerForItem([item], 0, m.PlayOptions)

                ' Refresh play data after playing.
                m.refreshOnActivate = true

            else if buttonCommand = "scenes" then
                newScreen = createVideoChaptersScreen(viewController, item, m.PlayOptions)
				newScreen.ScreenName = "Chapters" + itemId
                viewController.InitializeOtherScreen(newScreen, [item.Title, "Scenes"])
				newScreen.Show()

            else if buttonCommand = "trailer" then
                options = {
					PlayStart: 0
					intros: false
				}
				m.ViewController.CreatePlayerForItem(getLocalTrailers(item.Id), 0, options)

            else if buttonCommand = "trailers" then
                newScreen = createLocalTrailersScreen(viewController, item)
				newScreen.ScreenName = "Trailers" + itemId
                viewController.InitializeOtherScreen(newScreen, [item.Title, "Trailers"])
				newScreen.Show()
				
            else if buttonCommand = "cancelrecording" then
                
				m.CancelLiveTvTimer(item)

            else if buttonCommand = "delete" then
				m.DeleteLiveTvRecording(item)

            else if buttonCommand = "streams" then
                m.ShowStreamsDialog(item)

            else if buttonCommand = "record" then
                m.RecordLiveTvProgram(item)

            else if buttonCommand = "filmography" then
                m.ShowFilmography(item)
				
            else if buttonCommand = "more" then
                m.ShowMoreDialog(item)

			' rewster: handle the back button
			else if buttonCommand = "back" then
				m.ViewController.PopScreen(m)

            else
                handled = false
            end if
        end if
    end if

	return handled OR m.baseHandleMessage(msg)

End Function

'**********************************************************
'** createVideoChaptersScreen
'**********************************************************

Function createVideoChaptersScreen(viewController as Object, video As Object, playOptions) As Object

	' Dummy up an item
    obj = CreatePosterScreen(viewController, video, "flat-episodic-16x9")
	obj.GetDataContainer = getChaptersDataContainer

	obj.baseHandleMessage = obj.HandleMessage
	obj.HandleMessage = handleChaptersScreenMessage

    return obj
	
End Function

Function handleChaptersScreenMessage(msg) as Boolean

	handled = false

    if type(msg) = "roPosterScreenEvent" then

        if msg.isListItemSelected() then

            index = msg.GetIndex()
            content = m.contentArray[m.focusedList].content
            selected = content[index]

			item = m.Item

			startPosition = selected.StartPosition

			playOptions = {
				PlayStart: startPosition,
				intros: false
			}

            m.ViewController.CreatePlayerForItem([item], 0, playOptions)

        end if
			
    end if

	return handled or m.baseHandleMessage(msg)

End Function

Function getChaptersDataContainer(viewController as Object, item as Object) as Object

	obj = CreateObject("roAssociativeArray")
	obj.names = []
	obj.keys = []
	obj.items = item.Chapters

	return obj

End Function

'**********************************************************
'** createSpecialFeaturesScreen
'**********************************************************

Function createSpecialFeaturesScreen(viewController as Object, item As Object) As Object

	' TODO: Add option to poster screen to play item directly when selected

    obj = CreatePosterScreen(viewController, item, "flat-episodic-16x9")
	obj.GetDataContainer = getSpecialFeaturesDataContainer

	obj.playOnSelection = true

    return obj
	
End Function

Function getSpecialFeaturesDataContainer(viewController as Object, item as Object) as Object

    items = getSpecialFeatures(item.Id)

    if items = invalid
        return invalid
    end if

	obj = CreateObject("roAssociativeArray")
	obj.names = []
	obj.keys = []
	obj.items = items

	return obj

End Function

'**********************************************************
'** createLocalTrailersScreen
'**********************************************************

Function createLocalTrailersScreen(viewController as Object, item As Object) As Object

	' TODO: Add option to poster screen to play item directly when selected

    obj = CreatePosterScreen(viewController, item, "flat-episodic-16x9")

	obj.GetDataContainer = getLocalTrailersDataContainer

	obj.playOnSelection = true

    return obj

End Function


Function getLocalTrailersDataContainer(viewController as Object, item as Object) as Object

    items = getLocalTrailers(item.Id)

    if items = invalid
        return invalid
    end if

	obj = CreateObject("roAssociativeArray")
	obj.names = []
	obj.keys = []
	obj.items = items

	return obj

End Function

'**********************************************************
'** createPeopleScreen
'**********************************************************

function createPeopleScreen(viewController as Object, item as Object) as Object

    obj = CreatePosterScreen(viewController, item, "arced-poster")

	obj.GetDataContainer = getItemPeopleDataContainer

    return obj
end function

Function getItemPeopleDataContainer(viewController as Object, item as Object) as Object

    items = convertItemPeopleToMetadata(item.People)

    if items = invalid
        return invalid
    end if

	obj = CreateObject("roAssociativeArray")
	obj.names = []
	obj.keys = []
	obj.items = items

	return obj

End Function

Sub springboardShowFilmography(item)
	newScreen = createFilmographyScreen(m.viewController, item)
	newScreen.ScreenName = "Filmography" + item.Id		
	m.ViewController.InitializeOtherScreen(newScreen, [item.Title, "Filmography"])
	newScreen.Show()
End Sub

Sub springboardShowMoreDialog(item)

    dlg = createBaseDialog()
    dlg.Title = "More Options"

	if item.MediaType = "Video" or item.MediaType = "Game" then 
		if item.Watched
			dlg.SetButton("markunplayed", "Mark unplayed")
		else
			dlg.SetButton("markplayed", "Mark played")
		end if
	end if

    if item.IsFavorite
        dlg.SetButton("removefavorite", "Remove favorite")
    else
        dlg.SetButton("markfavorite", "Mark as favorite")
    end if

    ' Check for special features
    if item.People <> invalid and item.People.Count() > 0

		if item.MediaType = "Video" then
			dlg.SetButton("cast", "Cast & Crew")
		else
			dlg.SetButton("people", "People")
		end If

    end if

    ' Check for special features
    if item.SpecialFeatureCount <> invalid and item.SpecialFeatureCount > 0
        dlg.SetButton("specials", "Special features")
    end if

	dlg.item = item
	dlg.parentScreen = m

	dlg.HandleButton = handleMoreOptionsButton

    dlg.SetButton("close", "Close")
    dlg.Show()

End Sub

Function handleMoreOptionsButton(command, data) As Boolean

	item = m.item
	itemId = item.Id
	screen = m.parentScreen

    if command = "markunplayed" then
		screen.refreshOnActivate = true
		postWatchedStatus(itemId, false)
        return true
    else if command = "markplayed" then
		screen.refreshOnActivate = true
		postWatchedStatus(itemId, true)
        return true
    else if command = "removefavorite" then
		screen.refreshOnActivate = true
		postFavoriteStatus(itemId, false)
        return true
    else if command = "markfavorite" then
		screen.refreshOnActivate = true
		postFavoriteStatus(itemId, true)
        return true
    else if command = "specials" then
        newScreen = createSpecialFeaturesScreen(m.ViewController, item)
		newScreen.ScreenName = "Chapters" + itemId
        m.ViewController.InitializeOtherScreen(newScreen, [item.Title, "Special Features"])
		newScreen.Show()
        return true
    else if command = "cast" then
        newScreen = createPeopleScreen(m.ViewController, item)
		newScreen.ScreenName = "People" + itemId
        m.ViewController.InitializeOtherScreen(newScreen, [item.Title, "Cast & Crew"])
		newScreen.Show()
        return true
    else if command = "people" then
        newScreen = createPeopleScreen(m.ViewController, item)
		newScreen.ScreenName = "People" + itemId
        m.ViewController.InitializeOtherScreen(newScreen, [item.Title, "People"])
		newScreen.Show()
        return true
    else if command = "close" then
		m.Screen.Close()
        return true
    end if
	
    return false

End Function

Sub springboardShowStreamsDialog(item)

    createAudioAndSubtitleDialog(m.audioStreams, m.subtitleStreams, m.PlayOptions)
End Sub

'******************************************************
' createAudioAndSubtitleDialog
'******************************************************

Sub createAudioAndSubtitleDialog(audioStreams, subtitleStreams, playOptions)

    Debug ("createAudioAndSubtitleDialog")
	Debug ("Current AudioStreamIndex: " + tostr(playOptions.AudioStreamIndex))
	Debug ("Current SubtitleStreamIndex: " + tostr(playOptions.SubtitleStreamIndex))
	
    if audioStreams.Count() > 1 or subtitleStreams.Count() > 0
		dlg = createBaseDialog()
		dlg.Title = "Audio & Subtitles"

		dlg.HandleButton = handleAudioAndSubtitlesButton

		dlg.audioStreams = audioStreams
		dlg.subtitleStreams = subtitleStreams
		dlg.playOptions = playOptions

		dlg.SetButton("audio", "Audio")
		dlg.SetButton("subtitles", "Subtitles")
		dlg.SetButton("close", "Close")

		dlg.Show(true)

    end if

End Sub

Function handleAudioAndSubtitlesButton(command, data) As Boolean

	if command = "audio" then

		createStreamSelectionDialog("Audio", m.audioStreams, m.subtitleStreams, m.playOptions, true)
        return true

    else if command = "subtitles" then

		createStreamSelectionDialog("Subtitle", m.audioStreams, m.subtitleStreams, m.playOptions, true)
        return true

    else if command = "close" then

		return true

    end if

    return true
End Function

Sub createStreamSelectionDialog(streamType, audioStreams, subtitleStreams, playOptions, openParentDialog)

    dlg = createBaseDialog()
    dlg.Title = "Select " + streamType

	dlg.HandleButton = handleStreamSelectionButton

	dlg.streamType = streamType
	dlg.audioStreams = audioStreams
	dlg.subtitleStreams = subtitleStreams
	dlg.playOptions = playOptions
	dlg.openParentDialog = openParentDialog

    if streamType = "Subtitle" then 
		streams = subtitleStreams
		currentIndex = playOptions.SubtitleStreamIndex
	else
		streams = audioStreams
		currentIndex = playOptions.AudioStreamIndex
	end If
	
	if streamType = "Subtitle" then 
	
		title = "None"
		
		if currentIndex = invalid or currentIndex = -1 then title = title + " [Selected]"
		dlg.SetButton("none", title)
	end If
	
	for each stream in streams

		if dlg.Buttons.Count() < 5 then

			title = firstOf(stream.Language, "Unknown language")

			if currentIndex = stream.Index then title = title + " [Selected]"

			dlg.SetButton(tostr(stream.Index), title)
		end if

	end For

    dlg.SetButton("close", "Cancel")
    dlg.Show(true)
End Sub

Function handleStreamSelectionButton(command, data) As Boolean

    if command = "none" then

		if m.streamType = "Audio" then
			m.playOptions.AudioStreamIndex = -1
		else
			m.playOptions.SubtitleStreamIndex = -1
		end If

		if m.openParentDialog = true then createAudioAndSubtitleDialog(m.audioStreams, m.subtitleStreams, m.playOptions)

        return true
    else if command = "close" or command = invalid then

		if m.openParentDialog = true then createAudioAndSubtitleDialog(m.audioStreams, m.subtitleStreams, m.playOptions)
        return true

	else if command <> invalid then

		if m.streamType = "Audio" then
			m.playOptions.AudioStreamIndex = command.ToInt()
		else
			m.playOptions.SubtitleStreamIndex = command.ToInt()
		end If

		if m.openParentDialog = true then createAudioAndSubtitleDialog(m.audioStreams, m.subtitleStreams, m.playOptions)

		return true
    end if

    return false
End Function

'******************************************************
' Cancel Timer Dialog
'******************************************************

Function showCancelLiveTvTimerDialog()
	return showContextViewMenuYesNoDialog("Confirm Action", "Are you sure you wish to cancel this recording?")
End Function


'******************************************************
' Delete Recording Dialog
'******************************************************

Function showDeleteRecordingDialog()
	return showContextViewMenuYesNoDialog("Confirm Action", "Are you sure you wish to delete this recording?")
End Function

Sub springboardDeleteRecording (item)
	if showDeleteRecordingDialog() = "1" then
        deleteLiveTvRecording(item.Id)
		m.Screen.Close()
	end if
End Sub

Sub springboardCancelTimer (item)
	m.refreshOnActivate = true

	if showCancelLiveTvTimerDialog() = "1" then
        cancelLiveTvTimer(item.TimerId)
		m.Refresh(true)
	end if
End Sub

Sub springboardRecordProgram(item)
	m.refreshOnActivate = true

    timerInfo = getDefaultLiveTvTimer(item.Id)
    createLiveTvTimer(timerInfo)
	
	m.Refresh(true)
End Sub