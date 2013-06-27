'**********************************************************
'**  Media Browser Roku Client - List Screen
'**********************************************************


Function CreateListScreen(lastLocation As String, currentLocation As String) As Object

    ' Setup Screen
    screen = CreateObject("roAssociativeArray")

    port = CreateObject("roMessagePort")
    list = CreateObject("roListScreen")
    list.SetMessagePort(port)

    ' Setup Common Items
    screen.Screen     = list
    screen.Port       = port
    screen.SetHeader  = SetListHeader
    screen.SetTitle   = SetListTitle
    screen.SetContent = SetListContent
    screen.Show       = ShowListScreen

    ' Set Breadcrumbs
    screen.Screen.SetBreadcrumbText(lastLocation, currentLocation)

    Return screen
End Function


'**********************************************************
'** Set Header for List Screen
'**********************************************************

Function SetListHeader(text As String) As Integer
    m.screen.SetHeader(text)

    Return 0
End Function


'**********************************************************
'** Set Title for List Screen
'**********************************************************

Function SetListTitle(text As String) As Integer
    m.screen.SetTitle(text)

    Return 0
End Function


'**********************************************************
'** Set Content for List Screen
'**********************************************************

Function SetListContent(contentList As Object)
    m.screen.SetContent(contentList)
End Function


'**********************************************************
'** Show List Screen
'**********************************************************

Function ShowListScreen()
    m.screen.Show()
End Function