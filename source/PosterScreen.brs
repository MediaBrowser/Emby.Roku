'**********************************************************
'**  Media Browser Roku Client - Poster Screen
'** Credit: Plex Roku https://github.com/plexinc/roku-client-public
'**********************************************************

Function CreatePosterScreen(viewController as Object, item as Object, style As String) As Object

    ' Setup Screen
    obj = CreateObject("roAssociativeArray")

	initBaseScreen(obj, viewController)	
	port = obj.Port

    screen = CreateObject("roPosterScreen")
    screen.SetMessagePort(port)

    ' Setup Common Items
	obj.Item = item
    obj.Screen         = screen
    obj.Port           = port
    obj.SetContent     = SetPosterContent
    obj.SetFocusedItem = SetPosterFocusedItem
    obj.ShowMessage    = ShowPosterMessage
    obj.ClearMessage   = ClearPosterMessage
	obj.GetDataContainer = getPosterScreenDataContainer

	obj.Show = showPosterScreen
    obj.ShowList = posterShowContentList
    obj.HandleMessage = posterHandleMessage
    obj.SetListStyle = posterSetListStyle

    obj.UseDefaultStyles = true
    obj.ListStyle = invalid
    obj.ListDisplayMode = invalid
    obj.FilterMode = invalid
    obj.Facade = invalid

	m.dataLoaderHttpHandler = invalid

	obj.OnDataLoaded = posterOnDataLoaded

	obj.contentArray = []
	obj.focusedList = 0
	obj.names = []

	obj.playOnSelection = false

    ' Setup Display Style
    obj.Screen.SetListStyle(style)
    obj.Screen.SetDisplayMode("scale-to-fit")

	obj.SeriesOptionsDialog = posterSeriesOptionsDialog
	
    if NOT AudioPlayer().IsPlaying AND firstOf(RegRead("prefThemeMusic"), "yes") = "yes" then
        AudioPlayer().PlayThemeMusic(item)
        obj.Cleanup = baseStopAudioPlayer

    end if

    Return obj
	
End Function

'**********************************************************
'** Set Content for Poster Screen
'**********************************************************

Function SetPosterContent(contentList As Object)

	m.contentArray = contentList

    m.screen.SetContentList(contentList)

End Function


'**********************************************************
'** Set Focused Item for Poster Screen
'**********************************************************

Function SetPosterFocusedItem(index as Integer)
    m.screen.SetFocusedListItem(index)
End Function


'**********************************************************
'** Show Message for Poster Screen
'**********************************************************

Function ShowPosterMessage(message as String)
    m.screen.ShowMessage(message)
End Function


'**********************************************************
'** Clear Message for Poster Screen
'**********************************************************

Function ClearPosterMessage(clear as Boolean)
    m.screen.ClearMessage(clear)
End Function


'**********************************************************
'** Show Poster Screen
'**********************************************************

Function getPosterScreenDataContainer(viewController as Object, item as Object) as Object

	obj = CreateObject("roAssociativeArray")
	obj.names = []
	obj.keys = []
	obj.items = []

	return obj

End Function

Function showPosterScreen() As Integer

    ' Show a facade immediately to get the background 'retrieving' instead of
    ' using a one line dialog.
    m.Facade = CreateObject("roPosterScreen")
    m.Facade.Show()

    content = m.Item

    container = m.GetDataContainer(m.ViewController, content)

    if container = invalid then
        dialog = createBaseDialog()
        dialog.Title = "Content Unavailable"
        dialog.Text = "An error occurred while trying to load this content, make sure the server is running."
        dialog.Facade = m.Facade
        dialog.Show()
        m.closeOnActivate = true
        m.Facade = invalid
        return 0
    end if

    m.names = container.names
    keys = container.keys

    m.FilterMode = m.names.Count() > 0

    if m.FilterMode then

        m.Loader = createPaginatedLoader(container, m.dataLoaderHttpHandler, 25, 25)
        m.Loader.Listener = m

        m.Screen.SetListNames(m.names)

		focusedIndex = 0
		if container.focusedIndex <> invalid then focusedIndex = container.focusedIndex
        m.Screen.SetFocusedList(focusedIndex)

        for index = 0 to keys.Count() - 1
            status = CreateObject("roAssociativeArray")
            status.listDisplayMode = invalid
            status.focusedIndex = 0
            status.content = []
            status.lastUpdatedSize = 0
            m.contentArray[index] = status
        next

        m.Loader.LoadMoreContent(0, 0)

		m.Screen.SetFocusToFilterBanner(false)
    else

        ' We already grabbed the full list, no need to bother with loading
        ' in chunks.

        status = CreateObject("roAssociativeArray")
        status.content = container.items

        m.Loader = createDummyLoader()

        'if container.Count() > 0 then
            'contentType = container.GetMetadata()[0].ContentType
        'else
            'contentType = invalid
        'end if

        if m.UseDefaultStyles then
            'aa = getDefaultListStyle(container.ViewGroup, contentType)
            'status.listStyle = aa.style
            'status.listDisplayMode = aa.display
        else
            status.listStyle = m.ListStyle
            status.listDisplayMode = m.ListDisplayMode
        end if

        status.focusedIndex = 0
        status.lastUpdatedSize = status.content.Count()

        m.contentArray[0] = status

    end if

    m.focusedList = 0
    m.ShowList(0)
    if m.Facade <> invalid then m.Facade.Close()

    return 0
End Function

'**********************************************************
'** posterShowContentList
'**********************************************************

Sub posterShowContentList(index)

    status = m.contentArray[index]
    if status = invalid then return
    m.Screen.SetContentList(status.content)

    if status.listStyle <> invalid then
        m.Screen.SetListStyle(status.listStyle)
    end if
    if status.listDisplayMode <> invalid then
        m.Screen.SetListDisplayMode(status.listDisplayMode)
    end if

    Debug("Showing screen with " + tostr(status.content.Count()) + " elements")

    if status.content.Count() = 0 AND NOT m.FilterMode then
        dialog = createBaseDialog()
        dialog.Facade = m.Facade
        dialog.Title = "No items to display"
        dialog.Text = "This directory appears to be empty."
        dialog.Show()
        m.Facade = invalid
        m.closeOnActivate = true
    else
        m.Screen.Show()
        m.Screen.SetFocusedListItem(status.focusedIndex)
    end if
End Sub



'**********************************************************
'** posterSeriesShowOptionsDialog
'**********************************************************

Sub posterSeriesOptionsDialog()

    dlg = createBaseDialog()
    dlg.Title = "Series Options"

	dlg.SetButton("cast", "Cast & Crew")

	dlg.item = m.Item
	dlg.parentScreen = m

	dlg.HandleButton = handleSeriesOptionsButton

    dlg.SetButton("close", "Close")
    dlg.Show()

End Sub

'**********************************************************
'** handleSeriesOptionsButton
'**********************************************************

Function handleSeriesOptionsButton(command, data) As Boolean

	item = GetFullItemMetadata(m.item, false, {})
	itemId = m.item.Id
	screen = m.parentScreen

	if command = "cast" then
		newScreen = CreatePosterScreen(m.ViewController, item, "arced-poster")
		newScreen.GetDataContainer = getSeriesPeopleDataContainer
		newScreen.ScreenName = "People" + itemId
        m.ViewController.InitializeOtherScreen(newScreen, [item.Title, "Cast & Crew"])
		newScreen.Show()
        return true
    else if command = "close" then
		m.Screen.Close()
        return true
    end if
	
    return false

End Function

Function getSeriesPeopleDataContainer(viewController as Object, item as Object) as Object

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

'**********************************************************
'** posterHandleMessage
'**********************************************************

Function posterHandleMessage(msg) As Boolean
    handled = false

    if type(msg) = "roPosterScreenEvent" then
        handled = true

        '* Focus change on the filter bar causes content change
        if msg.isListFocused() then

            m.focusedList = msg.GetIndex()
            m.ShowList(m.focusedList)
            m.Loader.LoadMoreContent(m.focusedList, 0)

        else if msg.isListItemSelected() then

            index = msg.GetIndex()
            content = m.contentArray[m.focusedList].content
            selected = content[index]

            if selected <> invalid then

                contentType = selected.ContentType

                Debug("Content type in poster screen: " + tostr(contentType))

				if m.playOnSelection = true then

					m.ViewController.CreatePlayerForItem(content, index, {})

				else
					if contentType = "Series" or m.names.Count() = 0 then
						breadcrumbs = [selected.Title]
					else
						breadcrumbs = [m.names[m.focusedList], selected.Title]
					end if

					m.ViewController.CreateScreenForItem(content, index, breadcrumbs)
				end If

            end if

        else if msg.isScreenClosed() then
            m.ViewController.PopScreen(m)

        else if msg.isListItemFocused() then

            ' We don't immediately update the screen's content list when
            ' we get more data because the poster screen doesn't perform
            ' as well as the grid screen (which has an actual method for
            ' refreshing part of the list). Instead, if the user has
            ' focused toward the end of the list, update the content.

            status = m.contentArray[m.focusedList]
            status.focusedIndex = msg.GetIndex()

            if status.focusedIndex + 10 > status.lastUpdatedSize AND status.content.Count() > status.lastUpdatedSize then
                m.Screen.SetContentList(status.content)
                status.lastUpdatedSize = status.content.Count()
            end if
        
		else if msg.isRemoteKeyPressed() then

			if msg.GetIndex() = 10 then
				m.SeriesOptionsDialog()
				
            else if msg.GetIndex() = 13 then

                Debug("Playing item directly from poster screen")
                status = m.contentArray[m.focusedList]
                m.ViewController.CreatePlayerForItem(status.content, status.focusedIndex, {})

            end if
        end if
    end If

    return handled
End Function

'**********************************************************
'** posterOnDataLoaded
'**********************************************************

Sub posterOnDataLoaded(row As Integer, data As Object, startItem as Integer, count As Integer, finished As Boolean)
    status = m.contentArray[row]
    status.content = data

    ' If this was the first content we loaded, set up the styles
    if startItem = 0 AND count > 0 then
        if m.UseDefaultStyles then
            if data.Count() > 0 then
                'aa = getDefaultListStyle(data[0].ViewGroup, data[0].contentType)
                'status.listStyle = aa.style
                'status.listDisplayMode = aa.display
            end if
        else
            status.listStyle = m.ListStyle
            status.listDisplayMode = m.ListDisplayMode
        end if
    end if

    if row = m.focusedList AND (finished OR startItem = 0 OR status.focusedIndex + 10 > status.lastUpdatedSize) then
        m.ShowList(row)
        status.lastUpdatedSize = status.content.Count()
    end if

    ' Continue loading this row
    m.Loader.LoadMoreContent(row, 0)
End Sub

'**********************************************************
'** posterSetListStyle
'**********************************************************

Sub posterSetListStyle(style, displayMode)
    m.ListStyle = style
    m.ListDisplayMode = displayMode
    m.UseDefaultStyles = false
End Sub