'**********************************************************
'**  Media Browser Roku Client - Poster Screen
'**********************************************************


Function CreatePosterScreen(lastLocation As String, currentLocation As String, style As String, port = invalid As Object) As Object

    ' Setup Screen
    o = CreateObject("roAssociativeArray")

    if port = invalid then
        port = CreateObject("roMessagePort")
    end if

    poster = CreateObject("roPosterScreen")
    poster.SetMessagePort(port)

    ' Setup Common Items
    o.Screen         = poster
    o.Port           = port
    o.Categories     = SetPosterCategories
    o.SetContent     = SetPosterContent
    o.SetFocusedItem = SetPosterFocusedItem
    o.ShowMessage    = ShowPosterMessage
    o.ClearMessage   = ClearPosterMessage
    o.Show           = ShowPosterScreen

    ' Set Breadcrumbs
    o.Screen.SetBreadcrumbText(lastLocation, currentLocation)

    ' Setup Display Style
    o.Screen.SetListStyle(style)
    o.Screen.SetDisplayMode("scale-to-fit")

    Return o
End Function


'**********************************************************
'** Set Categories for Poster Screen
'**********************************************************

Function SetPosterCategories(categories As Object)
    m.screen.SetListNames(categories)
End Function


'**********************************************************
'** Set Content for Poster Screen
'**********************************************************

Function SetPosterContent(contentList As Object)
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

Function ShowPosterScreen()
    m.screen.Show()
End Function
