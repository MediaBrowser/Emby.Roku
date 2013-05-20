'**********************************************************
'**  Media Browser Roku Client - General Dialogs
'**********************************************************


'******************************************************
' Show Basic Dialog message box
'******************************************************

Function ShowPleaseWait(title As dynamic, message As dynamic) As Object
    if not isstr(title) title = ""
    if not isstr(message) message = ""

    port = CreateObject("roMessagePort")
    dialog = invalid

    ' If no message text, only Create Single Line dialog
    if message = ""
        dialog = CreateObject("roOneLineDialog")
    else
        dialog = CreateObject("roMessageDialog")
        dialog.SetText(message)
    endif

    dialog.SetMessagePort(port)

    dialog.SetTitle(title)
    dialog.ShowBusyAnimation()
    dialog.Show()
    return dialog
End Function


'******************************************************
' Show Connection Failed. Give them option to
' exit application Or Try manual configuration
'******************************************************

Function ShowConnectionFailed() As Integer
    title = "Can't Find MediaBrowser 3 Server"
    message = "We were unable to find a MediaBrowser 3 Server running on the local network. Please make sure it is turned on. Try manual server configuration if the problem continues."

    port = CreateObject("roMessagePort")
    dialog = CreateObject("roMessageDialog")
    dialog.SetMessagePort(port)

    dialog.SetTitle(title)
    dialog.SetText(message)

    dialog.AddButton(0, "Try Again Later")
    dialog.AddButton(1, "Manual Server Configuration")

    dialog.Show()

    while true
        dlgMsg = wait(0, dialog.GetMessagePort())

        if type(dlgMsg) = "roMessageDialogEvent"
            if dlgMsg.isScreenClosed()
                dialog = invalid
                return 0
            else if dlgMsg.isButtonPressed()
                dialog = invalid
                return dlgMsg.GetIndex()
            endif
        endif
    end while
End Function


'******************************************************
' Show Manual Server Configuration Keyboard Screens
'******************************************************

Function ShowManualServerConfiguration() As Integer
    ' Show Keyboard For Both Fields
    serverAddress = ShowKeyboardScreen("Enter Server IP Address")
    If serverAddress <> ""
      portNumber = ShowKeyboardScreen("Enter Server Port #")
    End if

    ' If they filled them both out, save them To Memory And registry
    If serverAddress <> "" and portNumber <> ""
        m.serverURL = serverAddress + ":" + portNumber
        RegWrite("serverURL", m.serverURL)
        Return 1
    End if

    Return 0
End Function


'******************************************************
' Show Keyboard Screen
'******************************************************

Function ShowKeyboardScreen(prompt = "", secure = false)
    result = ""

    port = CreateObject("roMessagePort")
    screen = CreateObject("roKeyboardScreen")
    screen.SetMessagePort(port)

    screen.SetDisplayText(prompt)

    screen.AddButton(1, "Okay")
    screen.AddButton(2, "Cancel")

    ' if secure is true, the typed text will be obscured on the screen
    ' this is useful when the user is entering a password
    screen.SetSecureText(secure)

    ' display our keyboard screen
    screen.Show()

    while true
        msg = wait(0, port)

        if type(msg) = "roKeyboardScreenEvent" then
            if msg.isScreenClosed() then
                exit while
            else if msg.isButtonPressed()
                if msg.GetIndex() = 1
                    ' the user pressed the Okay button
                    ' close the screen and return the text they entered
                    result = screen.GetText()
                    exit while
                else if msg.GetIndex() = 2
                    ' the user pressed the Cancel button
                    ' close the screen and return an empty string
                    result = ""
                    exit while
                end if
            end if
        end if
    end while

    screen.Close()
    return result
End Function


'******************************************************
' Show Dialog Box
'******************************************************

Function ShowDialog(title As dynamic, text As dynamic, buttonText As String) As Integer
    if not isstr(title) title = ""
    if not isstr(text) text = ""

    port = CreateObject("roMessagePort")
    screen = CreateObject("roMessageDialog")
    screen.SetMessagePort(port)

    screen.SetTitle(title)
    screen.SetText(text)
    screen.AddButton(0, buttonText)
    screen.Show()

    while true
        msg = wait(0, screen.GetMessagePort())

        If type(msg) = "roMessageDialogEvent"
            If msg.isScreenClosed()
                print "Screen closed"
                Return 1
            Else If msg.isButtonPressed()
                print "Button pressed: "; msg.GetIndex(); " " msg.GetData()
                Return 1
            End If
        End If
    end while
End Function
