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
' Create Context Menu Dialog
'******************************************************

Sub createContextMenuDialog(options as Object, useFacade = true) 

	facade = invalid

	if useFacade = true then
		facade = CreateObject("roGridScreen")
		facade.Show()
	end if

    dlg = createBaseDialog()
    dlg.Title = "Options"

    sortOrderOptions = ["Ascending", "Descending"]

    ' Get Saved Options
    filterBy  = (firstOf(RegUserRead(options.settingsPrefix + "FilterBy"), "0")).ToInt()
    sortBy    = (firstOf(RegUserRead(options.settingsPrefix + "SortBy"), "0")).ToInt()
    sortOrder = (firstOf(RegUserRead(options.settingsPrefix + "SortOrder"), "0")).ToInt()

    ' Setup Buttons
	if options.filterOptions <> invalid then
		dlg.SetButton("filter", "Filter by: " + options.filterOptions[filterBy])
	end if
	
	if options.sortOptions <> invalid then
		dlg.SetButton("sortby", "Sort by: " + options.sortOptions[sortBy])
	end if
	
	if options.showSortOrder = true then
		dlg.SetButton("sortorder", "Sort order: " + sortOrderOptions[sortOrder])
	end if
    
    dlg.SetButton("view", "View Menu")
    dlg.SetButton("close", "Close")

    dlg.Show(true)

	returned = dlg.Result

    if returned = "filter"
        returned = createOptionsDialog("Filter Options", options.filterOptions)
        if returned <> invalid then RegUserWrite(options.settingsPrefix + "FilterBy", returned)

        createContextMenuDialog(options, false)
		return

    else if returned = "sortby"
        returned = createOptionsDialog("Sort By", options.sortOptions)
        if returned <> invalid then RegUserWrite(options.settingsPrefix + "SortBy", returned)

        createContextMenuDialog(options, false)
		return

    else if returned = "sortorder"
        returned = createOptionsDialog("Sort Order", sortOrderOptions)
        if returned <> invalid then RegUserWrite(options.settingsPrefix + "SortOrder", returned)

        createContextMenuDialog(options, false)
		return

    else if returned = "view"
        createContextViewMenuDialog(options)

        createContextMenuDialog(options, false)
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

Sub createContextViewMenuDialog(options as Object)
    dlg = createBaseDialog()
    dlg.Title = "View Menu"

    ' Get Saved Options
    imageStyleOptions = ["Poster", "Thumb", "Backdrop"]
    displayOptions    = ["No", "Yes"]
    imageType         = (firstOf(RegUserRead(options.settingsPrefix + "ImageType"), "0")).ToInt()
	displayDescription    = (firstOf(RegUserRead(options.settingsPrefix + "Description"), "1")).ToInt()

    ' Setup Buttons
    dlg.SetButton("image", "Image Style: " + imageStyleOptions[imageType])
    dlg.SetButton("info", "Display Info Box: " + displayOptions[displayDescription])

    dlg.SetButton("close", "Close")

    dlg.Show(true)

	result = dlg.Result

    if result = "image"
        result = createOptionsDialog("Image Style", imageStyleOptions)
        if result <> invalid then RegUserWrite(options.settingsPrefix + "ImageType", result)

        createContextViewMenuDialog(options)
		
    else if result = "info"
        result = showContextViewMenuYesNoDialog("Display Info Box")
        if result <> invalid then RegUserWrite(options.settingsPrefix + "Description", result)

        createContextViewMenuDialog(options)
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