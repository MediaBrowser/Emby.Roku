'**********************************************************
'**  Media Browser Roku Client - Grid Screen
'** Credit: Plex Roku https://github.com/plexinc/roku-client-public
'**********************************************************

Function CreateGridScreen(viewController as Object, style As String) As Object

    setGridTheme(viewController, style)

    screen = CreateObject("roAssociativeArray")

    initBaseScreen(screen, viewController)

    grid = CreateObject("roGridScreen")
    grid.SetMessagePort(screen.Port)

    ' Standard properties for all our Screen types
    screen.Screen = grid

    ' Check for legacy devices to provide exit when they have no back Button
    ' Setup loading poster for current devices
    if getGlobalVar("legacyDevice")
        upBehavior = "exit"
    else
		upBehavior = "stop"
        if style = "two-row-flat-landscape-custom" then
            screen.Screen.SetLoadingPoster(viewController.getThemeImageUrl("sd-loading-landscape.jpg"), viewController.getThemeImageUrl("hd-loading-landscape.jpg"))
        else if style = "mixed-aspect-ratio" then
            screen.Screen.SetLoadingPoster(viewController.getThemeImageUrl("sd-loading-poster.jpg"), viewController.getThemeImageUrl("hd-loading-poster.jpg"))
        end if
    end if

    ' If we don't know exactly what we're displaying, scale-to-fit looks the
    ' best. Anything else makes something look horrible when the grid has
    ' some combination of posters and video frames.
    grid.SetDisplayMode("scale-to-fit")
    grid.SetGridStyle(style)
    grid.SetUpBehaviorAtTopRow(upBehavior)

    screen.DestroyAndRecreate = gridDestroyAndRecreate
    screen.Show = ShowGridScreen
    screen.HandleMessage = gridHandleMessage
    screen.Activate = gridActivate
    screen.OnTimerExpired = gridOnTimerExpired

	screen.displayDescription = 0

    screen.timer = createTimer()
    screen.selectedRow = 0
    screen.focusedIndex = 0
    screen.contentArray = []
    screen.lastUpdatedSize = []
    screen.gridStyle = style
    screen.upBehavior = upBehavior
    screen.hasData = false
    screen.hasBeenFocused = false
    screen.ignoreNextFocus = false
    screen.recreating = false

    screen.OnDataLoaded = gridOnDataLoaded

    screen.SetDescriptionVisible = ShowGridDescriptionBox
    screen.SetFocusedListItem    = SetGridFocusedItem
    screen.Close                 = CloseGridScreen

    return screen

End Function

'* Convenience method to create a grid screen with a loader for the specified item
Function createPaginatedGridScreen(viewController as Object, names as Object, keys as Object, dataLoaderHttpHandler as Object, style As String, initialCount = 8, pageSize = 75) As Object

    obj = createGridScreen(viewController, style)

    container = CreateObject("roAssociativeArray")
	container.names = names
	container.keys = keys

    obj.Loader = createPaginatedLoader(container, dataLoaderHttpHandler, initialCount, pageSize)
    obj.Loader.Listener = obj

    return obj

End Function


Function gridHandleMessage(msg) As Boolean
    handled = false

    if type(msg) = "roGridScreenEvent" then
        handled = true
        if msg.isListItemSelected() then

			context = m.contentArray[msg.GetIndex()]
            
            index = msg.GetData()

            item = context[index]

            if item <> invalid then

                if item.ContentType = "Series" then
                    breadcrumbs = [item.Title]
                else

					breadcrumbs = [m.Loader.GetNames()[msg.GetIndex()], item.Title]
                end if

                m.Facade = CreateObject("roGridScreen")
                m.Facade.Show()

                m.ViewController.CreateScreenForItem(context, index, breadcrumbs)
            end if

        else if msg.isListItemFocused() then
            ' If the user is getting close to the limit of what we've
            ' preloaded, make sure we kick off another update.

            m.selectedRow = msg.GetIndex()
            m.focusedIndex = msg.GetData()

            if m.ignoreNextFocus then
                m.ignoreNextFocus = false
            else
                m.hasBeenFocused = true
            end if

			' TODO: Remove this check once all screens have loaders
			if m.Loader <> invalid then
				if m.selectedRow < 0 OR m.selectedRow >= m.contentArray.Count() then
					Debug("Ignoring grid ListItemFocused event for bogus row: " + tostr(msg.GetIndex()))
				else
					lastUpdatedSize = m.lastUpdatedSize[m.selectedRow]
					if m.focusedIndex + 10 > lastUpdatedSize AND m.contentArray[m.selectedRow].Count() > lastUpdatedSize then
						data = m.contentArray[m.selectedRow]
					   m.Screen.SetContentListSubset(m.selectedRow, data, lastUpdatedSize, data.Count() - lastUpdatedSize)
						m.lastUpdatedSize[m.selectedRow] = data.Count()
					end if

					m.Loader.LoadMoreContent(m.selectedRow, 2)
				end if
			end If
        
		else if msg.isRemoteKeyPressed() then

            if msg.GetIndex() = 13 then
                Debug("Playing item directly from grid")
                context = m.contentArray[m.selectedRow]
                m.ViewController.CreatePlayerForItem(context, m.focusedIndex)

            end if

        else if msg.isScreenClosed() then
            if m.recreating then
                Debug("Ignoring grid screen close, we should be recreating")
                m.recreating = false
            else
                m.ViewController.PopScreen(m)
            end if
        end if
    end if

    return handled
End Function

'**********************************************************
'** gridOnDataLoaded
'**********************************************************

Sub gridOnDataLoaded(row As Integer, data As Object, startItem As Integer, count As Integer, finished As Boolean)

    Debug("Loaded " + tostr(count) + " elements in row " + tostr(row) + ", now have " + tostr(data.Count()))

    m.contentArray[row] = data

    ' Don't bother showing empty rows
    if data.Count() = 0 then
        if m.Screen <> invalid then
            m.Screen.SetListVisible(row, false)
            m.Screen.SetContentList(row, data)
        end if

        if NOT m.hasData then
            pendingRows = (m.Loader.GetPendingRequestCount() > 0)

            if NOT pendingRows then
                for i = 0 to m.contentArray.Count() - 1
                    if m.Loader.GetLoadStatus(i) < 2 then
                        pendingRows = true
                        exit for
                    end if
                next
            end if

            if NOT pendingRows then
                Debug("Nothing in any grid rows")

                ' If there's no data, show a helpful dialog. But if there's no
                ' data on a refresh, it's a bit of a mess. The dialog is only
                ' marginally helpful, and there's some sort of race condition
                ' with the fact that we reset the content list for the current
                ' row when the screen came back. That can hang the app for
                ' non-obvious reasons. Even without showing the dialog, closing
                ' the screen has a bit of an ugly flash.

                if m.Refreshing <> true then
                    dialog = createBaseDialog()
                    dialog.Title = "Section Empty"
                    dialog.Text = "This section doesn't contain any items."
                    dialog.Show()
                    m.closeOnActivate = true
                else
                    m.Screen.Close()
                end if

                return
            end if
        end if

        ' Load the next row though. This is particularly important if all of
        ' the initial rows are empty, we need to keep loading until we find a
        ' row with data.
        if row < m.contentArray.Count() - 1 then
            m.Loader.LoadMoreContent(row + 1, 0)
        end if

        return
    else if count > 0 AND m.Screen <> invalid then
        m.Screen.SetListVisible(row, true)
    end if

    m.hasData = true

    ' It seems like you should be able to do this, but you have to pass in
    ' the full content list, not some other array you want to use to update
    ' the content list.
    ' m.Screen.SetContentListSubset(rowIndex, content, startItem, content.Count())

    lastUpdatedSize = m.lastUpdatedSize[row]

    if finished then
        if m.Screen <> invalid then m.Screen.SetContentList(row, data)
        m.lastUpdatedSize[row] = data.Count()
    else if startItem < lastUpdatedSize then
        if m.Screen <> invalid then m.Screen.SetContentListSubset(row, data, startItem, count)
        m.lastUpdatedSize[row] = data.Count()
    else if startItem = 0 OR (m.selectedRow = row AND m.focusedIndex + 10 > lastUpdatedSize) then
        if m.Screen <> invalid then m.Screen.SetContentListSubset(row, data, lastUpdatedSize, data.Count() - lastUpdatedSize)
        m.lastUpdatedSize[row] = data.Count()
    end if

    ' Continue loading this row
    extraRows = 2 - (m.selectedRow - row)
    if extraRows >= 0 AND extraRows <= 2 then
        m.Loader.LoadMoreContent(row, extraRows)
    end if
End Sub

'**********************************************************
'** setGridTheme
'**********************************************************

Sub setGridTheme(viewController as Object, style as String)
    ' This has to be done before the CreateObject call. Once the grid has
    ' been created you can change its style, but you can't change its theme.

    app = CreateObject("roAppManager")
    if style = "two-row-flat-landscape-custom" then
        app.SetThemeAttribute("GridScreenFocusBorderHD", viewController.getThemeImageUrl("hd-border-flat-landscape.png"))
        app.SetThemeAttribute("GridScreenBorderOffsetHD", "-34,-19")
        app.SetThemeAttribute("GridScreenDescriptionOffsetHD", "270,140")
    else if style = "mixed-aspect-ratio" then
        app.SetThemeAttribute("GridScreenFocusBorderHD", viewController.getThemeImageUrl("hd-border-portrait.png"))
        app.SetThemeAttribute("GridScreenBorderOffsetHD", "-25,-35")
        app.SetThemeAttribute("GridScreenDescriptionOffsetHD", "210,260")
    end if
End Sub

'**********************************************************
'** gridDestroyAndRecreate
'**********************************************************

Sub gridDestroyAndRecreate()
    ' Close our current grid and recreate it once we get back.
    ' Works around a weird glitch when certain screens (maybe just
    ' an audio player) are shown on top of grids.
    if m.Screen <> invalid then
        Debug("Destroying grid...")
        m.Screen.Close()
        m.Screen = invalid

        if m.ViewController.IsActiveScreen(m) then
            m.recreating = true

            timer = createTimer()
            timer.Name = "Reactivate"

            ' Pretty arbitrary, but too close to 0 won't work. This is obviously
            ' a hack, but we're working around an acknowledged bug that will
            ' never be fixed, so what can you do.
            timer.SetDuration(1500)

            m.ViewController.AddTimer(timer, m)
        end if
    end if
End Sub

'**********************************************************
'** gridActivate
'**********************************************************

Sub gridActivate(priorScreen)
    if m.popOnActivate then
        m.ViewController.PopScreen(m)
        return
    else if m.closeOnActivate then
        if m.Screen <> invalid then
            m.Screen.Close()
        else
            m.ViewController.PopScreen(m)
        end if
        return
    end if

    ' If our screen was destroyed by some child screen, recreate it now
    if m.Screen = invalid then

        Debug("Recreating grid...")
        setGridTheme(m.ViewController, m.gridStyle)
        m.Screen = CreateObject("roGridScreen")
        m.Screen.SetMessagePort(m.Port)
        m.Screen.SetDisplayMode("scale-to-fit")
        m.Screen.SetGridStyle(m.gridStyle)
        m.Screen.SetUpBehaviorAtTopRow(m.upBehavior)

        names = m.Loader.GetNames()
        m.Screen.SetupLists(names.Count())
        m.Screen.SetListNames(names)

		if m.displayDescription = 0 then
			m.SetDescriptionVisible(false)
		else
			m.SetDescriptionVisible(true)
		end if

        m.ViewController.UpdateScreenProperties(m)

        for row = 0 to names.Count() - 1
            m.Screen.SetContentList(row, m.contentArray[row])
            if m.contentArray[row].Count() = 0 AND m.Loader.GetLoadStatus(row) = 2 then
                m.Screen.SetListVisible(row, false)
            end if
        end for
        m.Screen.SetFocusedListItem(m.selectedRow, m.focusedIndex)

        m.Screen.Show()

    else
        ' Regardless, reset the current row in case the currently
        ' selected item had metadata changed that would affect its
        ' display in the grid.

		if m.contentArray <> invalid then
			m.Screen.SetContentList(m.selectedRow, m.contentArray[m.selectedRow])
		end if
        
    end if

    m.HasData = false
    m.Refreshing = true

	if m.Loader <> invalid then
		' TODO: Remove this check once all screens have loaders
		m.Loader.RefreshData()
	end if

    if m.Facade <> invalid then m.Facade.Close()
End Sub

Sub gridOnTimerExpired(timer)
    if timer.Name = "Reactivate" AND m.ViewController.IsActiveScreen(m) then
        m.Activate(invalid)
    end if
End Sub

'**********************************************************
'** Show Grid Description Box
'**********************************************************

Function ShowGridDescriptionBox(visible)
    m.screen.SetDescriptionVisible(visible)
End Function

'**********************************************************
'** Set Grid Focused List Item
'**********************************************************

Function SetGridFocusedItem(listIndex As Integer, itemIndex As Integer)
    m.screen.SetFocusedListItem(listIndex, itemIndex)
End Function


'**********************************************************
'** Show Grid Screen
'**********************************************************

Function ShowGridScreen()

	if m.Loader = invalid then
		m.Screen.Show()
		return 0
	end If

    facade = CreateObject("roGridScreen")
    facade.Show()

    totalTimer = createTimer()

    names = m.Loader.GetNames()

    if names.Count() = 0 then
        Debug("Nothing to load for grid")
        dialog = createBaseDialog()
        dialog.Facade = facade
        dialog.Title = "Content Unavailable"
        dialog.Text = "An error occurred while trying to load this content, make sure the server is running."
        dialog.Show()

        m.popOnActivate = true
        return -1
    end if

    m.Screen.SetupLists(names.Count())
    m.Screen.SetListNames(names)

    if m.displayDescription = 0 then
        m.SetDescriptionVisible(false)
	else
		m.SetDescriptionVisible(true)
    end if

    ' If we already "loaded" an empty row, we need to set the list visibility now
    ' that we've setup the lists.
    for row = 0 to names.Count() - 1
        if m.contentArray[row] = invalid then m.contentArray[row] = []
        m.lastUpdatedSize[row] = m.contentArray[row].Count()
        m.Screen.SetContentList(row, m.contentArray[row])
        if m.lastUpdatedSize[row] = 0 AND m.Loader.GetLoadStatus(row) = 2 then
            m.Screen.SetListVisible(row, false)
        end if
    end for

    m.Screen.Show()
    facade.Close()

    ' Only two rows and five items per row are visible on the screen, so
    ' don't load much more than we need to before initially showing the
    ' grid. Once we start the event loop we can load the rest of the
    ' content.

    maxRow = names.Count() - 1
    if maxRow > 1 then maxRow = 1

    for row = 0 to maxRow
        Debug("Loading beginning of row " + tostr(row) + ", " + tostr(names[row]))
        m.Loader.LoadMoreContent(row, 0)
    end for

    totalTimer.PrintElapsedTime("Total initial grid load")

    return 0
End Function


'**********************************************************
'** Close Grid Screen
'**********************************************************

Function CloseGridScreen()
    m.screen.Close()
End Function