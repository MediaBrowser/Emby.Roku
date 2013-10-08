'**********************************************************
'**  Media Browser Roku Client - General Dialogs
'**********************************************************


'******************************************************
' Create Audio And Subtitle Dialog Boxes
'******************************************************

Function createAudioAndSubtitleDialog(audioStreams, subtitleStreams, playbackPosition, hidePlaybackDialog = false) As Object

    ' Set defaults
    audioIndex = false
    subIndex   = false
    playStart  = playbackPosition

    if audioStreams.Count() > 0
        audioIndex = createStreamSelectionDialog("Audio", audioStreams)    
        if audioIndex = -1 then return invalid ' Check for cancel
    end if

    if subtitleStreams.Count() > 0
        subIndex = createStreamSelectionDialog("Subtitle", subtitleStreams, 0, true)
        if subIndex = -1 then return invalid ' Check for Cancel
        if subIndex = 0 then subIndex = false ' Check for None
    end if

    if playbackPosition <> 0 And Not hidePlaybackDialog
        playStart = createPlaybackOptionsDialog(playbackPosition)
        if playStart = -1 then return invalid ' Check for Cancel
    end if

    return {
        audio: audioIndex
        subtitle: subIndex
        playstart: playStart
    }
End Function


'******************************************************
' Create Audio Or Subtitle Streams Dialog Box
'******************************************************

Function createStreamSelectionDialog(title, streams, startIndex = 0, showNone = false) As Integer
    port   = CreateObject("roMessagePort")
    dialog = CreateObject("roMessageDialog")
    dialog.SetMessagePort(port)

    dialog.SetMenuTopLeft(true)
    dialog.EnableOverlay(true)

    ' Set Title
    dialog.SetTitle("Select " + title)

    ' Setup Variables
    maxPerPage = 6 ' subtract 1 from what we want to show
    indexCount = 0
    foundMore  = false
    nextStartIndex   = startIndex
    totalStreamCount = streams.Count()-1

    if showNone then dialog.AddButton(0, "None")

    ' Setup Buttons
    for i = startIndex to totalStreamCount
        if streams[i] <> invalid
            dialog.AddButton(streams[i].Index, streams[i].Title)
            indexCount = indexCount + 1
        end if

        if indexCount > maxPerPage And i <> totalStreamCount then
            foundMore = true
            nextStartIndex = i + 1
            exit for
        end if
    end for

    dialog.AddButtonSeparator()

    if foundMore then dialog.AddButton(-2, "More " + title + " Selections")
    dialog.AddButton(-1, "Cancel")
    dialog.Show()

    while true
        msg = wait(0, dialog.GetMessagePort())

        if type(msg) = "roMessageDialogEvent"
            if msg.isScreenClosed()
                return 0
            else if msg.isButtonPressed()
                if msg.GetIndex() = -2
                    dialog.Close()
                    return createStreamSelectionDialog(title, streams, nextStartIndex)
                else
                    return msg.GetIndex()
                end if
            end if
        end if
    end while
End Function


'******************************************************
' Create Playback Options Dialog
'******************************************************

Function createPlaybackOptionsDialog(playbackPosition As Integer) As Integer
    port   = CreateObject("roMessagePort")
    dialog = CreateObject("roMessageDialog")
    dialog.SetMessagePort(port)

    dialog.SetMenuTopLeft(true)
    dialog.EnableOverlay(true)

    ' Set Title
    dialog.SetTitle("Select Playback")

    ' Setup Buttons
    dialog.AddButton(1, "Resume playing")
    dialog.AddButton(2, "Play from beginning")
    dialog.AddButtonSeparator()
    dialog.AddButton(-1, "Cancel")

    dialog.Show()

    while true
        msg = wait(0, dialog.GetMessagePort())

        if type(msg) = "roMessageDialogEvent"
            if msg.isScreenClosed()
                return 1
            else if msg.isButtonPressed()
                if msg.GetIndex() = -1
                    return -1
                else if msg.GetIndex() = 1
                    return playbackPosition
                else
                    return 0
                end if
            end if
        end if
    end while
End Function


'******************************************************
' Create Loading Error Dialog
'******************************************************

Function createLoadingErrorDialog()

    createDialog("Error Loading", "There was an error while loading. Please Try again.", "Back")

End Function


Function createContextMenuDialog() As Integer
    port   = CreateObject("roMessagePort")
    dialog = CreateObject("roMessageDialog")
    dialog.SetMessagePort(port)

    dialog.SetMenuTopLeft(true)
    dialog.EnableOverlay(true)

    ' Set Title
    dialog.SetTitle("Options")

    ' Setup Buttons
    dialog.AddButton(1, "Filter by: None")
    dialog.AddButton(2, "Sort by: Name")
    dialog.AddButton(3, "Direction: Ascending")
    dialog.AddButton(4, "View Menu")

    dialog.AddButtonSeparator()

    dialog.AddButton(5, "Search")
    dialog.AddButton(6, "Home")

    dialog.AddButtonSeparator()

    dialog.AddButton(7, "Close")

    dialog.Show()

    while true
        msg = wait(0, dialog.GetMessagePort())

        if type(msg) = "roMessageDialogEvent"
            if msg.isScreenClosed()
                return 1
            else if msg.isButtonPressed()
                if msg.GetIndex() = 1
                    dialog.Close()
                    returned = createContextOptionsDialog("Filter Options")
                    createContextMenuDialog() ' Re-create self
                else if msg.GetIndex() = 2
                    dialog.Close()
                    returned = createContextOptionsDialog("Sort Options")
                    createContextMenuDialog() ' Re-create self

                end if
                
                return 1
            end if
        end if
    end while
End Function


Function createContextOptionsDialog(title As String) As Integer
    port   = CreateObject("roMessagePort")
    dialog = CreateObject("roMessageDialog")
    dialog.SetMessagePort(port)

    dialog.SetMenuTopLeft(true)
    dialog.EnableOverlay(true)

    ' Set Title
    dialog.SetTitle(title)

    ' Setup Buttons
    dialog.AddButton(0, "None")
    dialog.AddButton(1, "Un-Watched")

    dialog.Show()

    while true
        msg = wait(0, dialog.GetMessagePort())

        if type(msg) = "roMessageDialogEvent"
            if msg.isScreenClosed()
                return 1
            else if msg.isButtonPressed()
                return msg.GetIndex()
            end if
        end if
    end while
End Function


'******************************************************
' Show Dialog Box
'******************************************************

Function createDialog(title As Dynamic, text As Dynamic, buttonText As String) As Integer
    if Not isstr(title) title = ""
    if Not isstr(text) text = ""

    port   = CreateObject("roMessagePort")
    screen = CreateObject("roMessageDialog")
    screen.SetMessagePort(port)

    screen.SetTitle(title)
    screen.SetText(text)
    screen.AddButton(0, buttonText)
    screen.Show()

    while true
        msg = wait(0, screen.GetMessagePort())

        if type(msg) = "roMessageDialogEvent"
            if msg.isScreenClosed()
                return 1
            else if msg.isButtonPressed()
                return 1
            end if
        end if
    end while
End Function

