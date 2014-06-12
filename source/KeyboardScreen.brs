'*
'* A simple wrapper around a keyboard screen.
'*
'** Credit: Plex Roku https://github.com/plexinc/roku-client-public

Function createKeyboardScreen(viewController As Object, item=invalid, title=invalid, heading=invalid, initialValue="", secure=false) As Object
    obj = CreateObject("roAssociativeArray")
    initBaseScreen(obj, viewController)

    screen = CreateObject("roKeyboardScreen")
    screen.SetMessagePort(obj.Port)

    screen.AddButton(1, "done")
    screen.AddButton(2, "back")

    ' Set Title
    if title <> invalid
        screen.SetTitle(title)
    end if

    if heading <> invalid then
        screen.SetDisplayText(heading)
    end if
    screen.SetText(initialValue)
    screen.SetSecureText(secure)

    ' Standard properties for all our screen types
    obj.Screen = screen
    obj.Item = item

    obj.Show = showKeyboardScreen
    obj.HandleMessage = kbHandleMessage
    obj.ValidateText = invalid

    ' If the user enters this text, as opposed to just exiting the screen,
    ' this will be set.
    obj.Text = invalid

    obj.SetText = kbSetText

    NowPlayingManager().SetFocusedTextField(firstOf(heading, "Field"), initialValue, secure)

    return obj
End Function

Sub showKeyboardScreen(blocking=false)

    if m.Text <> invalid then
        m.Screen.SetText(m.Text)
    end if

    ' We'd prefer to always use the global message port, but there are some
    ' places where we use dialogs that it would be incredibly difficult to
    ' have dialog.Show() return immediately. In those cases, we'll create
    ' our own message port and show the dialog in a blocking fashion.

    if blocking then
		port = CreateObject("roMessagePort")
        m.Port = port
		m.Screen.SetMessagePort(port)
    end if

    m.Screen.Show()

    if blocking then
		Debug ("Starting blocking loop for keyboard screen")
        while m.ScreenID = m.ViewController.Screens.Peek().ScreenID
            msg = wait(0, m.Port)
            m.HandleMessage(msg)
        end while
    end if
	
End Sub

Function kbHandleMessage(msg) As Boolean
    handled = false

    if type(msg) = "roKeyboardScreenEvent" then
        handled = true
		
		Debug ("roKeyboardScreenEvent")
		
        if msg.isScreenClosed() then
            Debug("Exiting keyboard screen - ID: " + tostr(m.ScreenID))
            m.ViewController.PopScreen(m)
            NowPlayingManager().SetFocusedTextField(invalid, invalid, false)
			
        else if msg.isButtonPressed() then
            if msg.GetIndex() = 1 then
                m.SetText(m.Screen.GetText(), true)
            else if msg.GetIndex() = 2 then
                m.Screen.Close()
            end if
        end if
		
    end if

    return handled
End Function

Sub kbSetText(text, isComplete)
    if isComplete then
        if m.ValidateText = invalid OR m.ValidateText(text) then
            m.Text = text
            if m.Listener <> invalid then
                m.Listener.OnUserInput(m.Text, m)
            else if m.Item <> invalid then
                callback = CreateObject("roAssociativeArray")
                callback.Heading = m.Text
                callback.Item = CreateObject("roAssociativeArray")
                callback.Item.server = m.Item.server
                callback.Item.Title = m.Text
                callback.Item.sourceUrl = m.Item.sourceUrl
                callback.Item.viewGroup = m.Item.viewGroup

                if instr(1, m.Item.Key, "?") > 0 then
                    callback.Item.Key = m.Item.Key + "&query=" + HttpEncode(m.Text)
                else
                    callback.Item.Key = m.Item.Key + "?query=" + HttpEncode(m.Text)
                end if

                callback.OnAfterClose = createScreenForItemCallback
                m.ViewController.afterCloseCallback = callback
            end if
            m.Screen.Close()
        else
            m.Screen.SetText(text)
        end if
    else
        m.Screen.SetText(text)
    end if
End Sub