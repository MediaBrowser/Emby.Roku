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

    options = ["Connect to Server", "Remove Server"]
	
	return createOptionsDialog("Select Action", options, 1)
	
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

    options = ["Scan Network", "Manually Add Server"]
	
	return createOptionsDialog("Select Action", options, 1)
	
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

    if menuType = "tv"
        filterByOptions  = ["None", "Continuing", "Ended"]
        sortByOptions    = ["Name", "Date Added", "Premiere Date"]
    else 
        filterByOptions  = ["None", "Unplayed", "Played"]
        sortByOptions    = ["Name", "Date Added", "Date Played", "Release Date"]
    end if
	
	sortOrderOptions = ["Ascending", "Descending"]

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
        returned = createOptionsDialog("Filter Options", filterByOptions)
        if returned <> invalid then RegUserWrite(menuType + "FilterBy", returned)

        createContextMenuDialog(menuType, false)
		return

    else if returned = "sortby"
        returned = createOptionsDialog("Sort By", sortByOptions)
        if returned <> invalid then RegUserWrite(menuType + "SortBy", returned)

        createContextMenuDialog(menuType, false)
		return

    else if returned = "sortorder"
        returned = createOptionsDialog("Sort Order", sortOrderOptions)
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


Function createOptionsDialog(title, options, startIndex = 0)

    dlg = createBaseDialog()
    dlg.Title = title

    index = startIndex
	for each option in options
		dlg.SetButton(tostr(index), option)
		index = index + 1
	end for

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
	displayDescription    = (firstOf(RegUserRead(menuType + "Description"), "0")).ToInt()

    ' Setup Buttons
    dlg.SetButton("image", "Image Style: " + imageStyleOptions[imageType])
    dlg.SetButton("info", "Display Info Box: " + displayOptions[displayDescription])

    dlg.SetButton("close", "Close")

    dlg.Show(true)

	result = dlg.Result

    if result = "image"
        result = createOptionsDialog("Image Style", imageStyleOptions)
        if result <> invalid then RegUserWrite(menuType + "ImageType", result)

        createContextViewMenuDialog(menuType)
		
    else if result = "info"
        result = showContextViewMenuYesNoDialog("Display Info Box")
        if result <> invalid then RegUserWrite(menuType + "Description", result)

        createContextViewMenuDialog(menuType)
    end if
End Sub

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