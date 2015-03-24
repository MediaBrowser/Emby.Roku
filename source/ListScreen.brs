'**********************************************************
'**  Emby Roku Client - List Screen
'**********************************************************


Function CreateListScreen(viewController as Object) As Object

    ' Setup Screen
    obj = CreateObject("roAssociativeArray")
	initBaseScreen(obj, viewController)
	
	obj.HandleMessage = handleListScreenMessage

    screen = CreateObject("roListScreen")
    screen.SetMessagePort(obj.Port)

    ' Setup Common Items
    obj.Screen         = screen
    obj.SetHeader      = SetListHeader
    obj.SetContent     = SetListContent
    obj.SetItem        = SetListItem
    obj.SetFocusedItem = SetListFocusedItem
    obj.Show           = ShowListScreen

	obj.contentArray = []

    if getGlobalVar("legacyDevice")
        obj.Screen.SetUpBehaviorAtTopRow("exit")
    end if

    Return obj
End Function

'**********************************************************
'** Set Header for List Screen
'**********************************************************

Function handleListScreenMessage(msg) as Boolean

	handled = false

    ' Fetch / Refresh Preference Screen
    If type(msg) = "roListScreenEvent" Then

		if msg.isScreenClosed() then

			handled = true
			m.ViewController.PopScreen(m)
			
        Else If msg.isListItemSelected() Then

            handled = true

            index = msg.GetIndex()
            selected = m.contentArray[index]

			if selected <> invalid then

				contentType = selected.ContentType

				breadcrumbs = [selected.Title]

				m.ViewController.CreateScreenForItem(m.contentArray, index, breadcrumbs)
			end if
		end if
    End If

	return handled

End Function



'**********************************************************
'** Set Header for List Screen
'**********************************************************

Function SetListHeader(text As String) As Integer
    m.screen.SetHeader(text)

    Return 0
End Function


'**********************************************************
'** Set Content for List Screen
'**********************************************************

Function SetListContent(contentList As Object)

	m.contentArray = contentList
    m.screen.SetContent(contentList)
End Function


'**********************************************************
'** Set Item for List Screen
'**********************************************************

Function SetListItem(index as Integer, content as Object)
    m.screen.SetItem(index, content)
End Function


'**********************************************************
'** Set Focused Item for List Screen
'**********************************************************

Function SetListFocusedItem(index as Integer)
    m.screen.SetFocusedListItem(index)
End Function


'**********************************************************
'** Show List Screen
'**********************************************************

Function ShowListScreen()
    m.screen.Show()
End Function