'******************************************************
' createErrorDialog
'******************************************************

Sub createErrorDialog(button = "Back") As Object

    createDialog("Error Loading Data", "There was an error loading data from the server. Please make sure your server is running and try again.", button)
	
End Sub

'******************************************************
' Create Server Update Dialog
'******************************************************

Sub showServerUpdateDialog()

	dlg = createContextViewMenuYesNoDialog("Server Restart", "Media Browser Server needs to restart to apply updates. Restart now? Please note if restarting server, please wait a minute to relaunch channel.")
	dlg.HandleButton = handleServerUpdateDialogButton
	dlg.Show()
	
End Sub

Function handleServerUpdateDialogButton(command, data) As Boolean

    if command = "2" then
		postServerRestart()
        return true
    end if
	
    return false
End Function

'******************************************************
' Create Server Selection Dialog
'******************************************************

Function createServerSelectionDialog()

    dlg = createBaseDialog()
    dlg.Title = "Select Action"
    dlg.SetButton("1", "Connect to Server")
    dlg.SetButton("2", "Remove Server")
    dlg.Show(true)

	return dlg.Result
End Function


'******************************************************
' Create Server Remove Dialog
'******************************************************

Function createServerRemoveDialog() as String

    return showContextViewMenuYesNoDialog("Confirm Action", "Are you sure you wish to remove this server from the list?")
End Function


'******************************************************
' Create Server Add Dialog
'******************************************************

Function createServerAddDialog()

    dlg = createBaseDialog()
    dlg.Title = "Select Action"
    dlg.SetButton("1", "Scan Network")
    dlg.SetButton("2", "Manually Add Server")
    dlg.Show(true)
	return dlg.Result
End Function

'******************************************************
' Create Context Menu Dialog
'******************************************************

Sub createContextMenuDialog(menuType As String, useFacade = true) 

	facade = invalid

	if useFacade = true then
		facade = CreateObject("roGridScreen")
		facade.Show()
	end if

    dlg = createBaseDialog()
    dlg.Title = "Options"

    ' Option Arrays
    if menuType = "movie"
        filterByOptions  = ["None", "Unwatched", "Watched"]
        sortByOptions    = ["Name", "Date Added", "Date Played", "Release Date"]
        sortOrderOptions = ["Ascending", "Descending"]
    else if menuType = "tv"
        filterByOptions  = ["None", "Continuing", "Ended"]
        sortByOptions    = ["Name", "Date Added", "Premiere Date"]
        sortOrderOptions = ["Ascending", "Descending"]
    else if menuType = "folders"
        filterByOptions  = ["None", "Unplayed", "Played"]
        sortByOptions    = ["Name", "Date Added", "Date Played", "Release Date"]
        sortOrderOptions = ["Ascending", "Descending"]
    end if

    ' Get Saved Options
    filterBy  = (firstOf(RegUserRead(menuType + "FilterBy"), "0")).ToInt()
    sortBy    = (firstOf(RegUserRead(menuType + "SortBy"), "0")).ToInt()
    sortOrder = (firstOf(RegUserRead(menuType + "SortOrder"), "0")).ToInt()

    ' Setup Buttons
    dlg.SetButton("filter", "Filter by: " + filterByOptions[filterBy])
    dlg.SetButton("sortby", "Sort by: " + sortByOptions[sortBy])
    dlg.SetButton("sortorder", "Sort order: " + sortOrderOptions[sortOrder])
    dlg.SetButton("view", "View Menu")
    dlg.SetButton("close", "Close")

    dlg.Show(true)

	returned = dlg.Result

    if returned = "filter"
        returned = createContextFilterByOptionsDialog(menuType)
        if returned <> invalid then RegUserWrite(menuType + "FilterBy", returned)

        createContextMenuDialog(menuType, false)
		return

    else if returned = "sortby"
        returned = createContextSortByOptionsDialog(menuType)
        if returned <> invalid then RegUserWrite(menuType + "SortBy", returned)

        createContextMenuDialog(menuType, false)
		return

    else if returned = "sortorder"
        returned = createContextSortOrderOptionsDialog()
        if returned <> invalid then RegUserWrite(menuType + "SortOrder", returned)

        createContextMenuDialog(menuType, false)
		return

    else if returned = "view"
        createContextViewMenuDialog(menuType)

        createContextMenuDialog(menuType, false)
		return

    end if

	if facade <> invalid then
		facade.Close()
	end if

End Sub


Function createContextFilterByOptionsDialog(menuType As String)
    dlg = createBaseDialog()
    dlg.Title = "Filter Options"

    ' Setup Buttons
    dlg.SetButton("0", "None")

    if menuType = "movie" or menuType = "folders"
        dlg.SetButton("1", "Unplayed")
        dlg.SetButton("2", "Played")
    else if menuType = "tv"
        dlg.SetButton("1", "Continuing")
        dlg.SetButton("2", "Ended")
    end if

    dlg.Show(true)
	return dlg.Result
End Function


Function createContextSortByOptionsDialog(menuType As String)
    dlg = createBaseDialog()
    dlg.Title = "Sort By"

    ' Setup Buttons
    dlg.SetButton("0", "Name")
	dlg.SetButton("1", "Date Added")
	
    if menuType = "movie" or menuType = "folders"
        dlg.SetButton("2", "Date Played")
        dlg.SetButton("3", "Release Date")
    else if menuType = "tv"
        dlg.SetButton("2", "Premiere Date")
    end if

    dlg.Show(true)
	return dlg.Result
End Function


Function createContextSortOrderOptionsDialog()
    dlg = createBaseDialog()
    dlg.Title = "Sort Order"
    dlg.SetButton("0", "Ascending")
    dlg.SetButton("1", "Descending")
    dlg.Show(true)
	return dlg.Result
End Function


Sub createContextViewMenuDialog(menuType As String)
    dlg = createBaseDialog()
    dlg.Title = "View Menu"

    ' Get Saved Options
    imageStyleOptions = ["Poster", "Thumb", "Backdrop"]
    displayOptions    = ["No", "Yes"]
    imageType         = (firstOf(RegUserRead(menuType + "ImageType"), "0")).ToInt()
	displayInfoBox    = (firstOf(RegUserRead(menuType + "InfoBox"), "0")).ToInt()

    ' Setup Buttons
    dlg.SetButton("image", "Image Style: " + imageStyleOptions[imageType])
    dlg.SetButton("info", "Display Info Box: " + displayOptions[displayInfoBox])

    dlg.SetButton("close", "Close")

    dlg.Show(true)

	returned = dlg.Result

    if returned = "image"
        returned = createContextViewMenuImageStyleDialog()
        if returned <> invalid then RegUserWrite(menuType + "ImageType", returned)

        createContextViewMenuDialog(menuType)
		
    else if returned = "info"
        returned = showContextViewMenuYesNoDialog("Display Info Box")
        if returned <> invalid then RegUserWrite(menuType + "InfoBox", returned)

        createContextViewMenuDialog(menuType)
    end if
End Sub


Function createContextViewMenuImageStyleDialog()

    dlg = createBaseDialog()
	dlg.enableOverlay = false
    dlg.Title = "Image Style"
    dlg.SetButton("0", "Poster")
    dlg.SetButton("1", "Thumb")
    dlg.SetButton("2", "Backdrop")
    dlg.Show(true)
	return dlg.Result
End Function


Function createContextViewMenuYesNoDialog(title As String, text = "" as String)

    dlg = createBaseDialog()
    dlg.Title = title
	dlg.Text = text
    dlg.SetButton("1", "Yes")
    dlg.SetButton("0", "No")
	return dlg
	
End Function

Function showContextViewMenuYesNoDialog(title As String, text = "" as String)

    dlg = createContextViewMenuYesNoDialog(title, text)
    dlg.Show(true)
    return dlg.Result
	
End Function

'******************************************************
' Create Dialog Box
'******************************************************

Function createDialog(title As Dynamic, text As Dynamic, buttonText As String, blocking = false)
    if Not isstr(title) title = ""
    if Not isstr(text) text = ""

    dlg = createBaseDialog()
    dlg.Title = title
	dlg.Text = text
    dlg.SetButton(buttonText, buttonText)
	
	dlg.Show(blocking)

End Function