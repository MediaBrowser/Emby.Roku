'**********************************************************
'**  Media Browser Roku Client - Poster Screen
'**********************************************************


Function CreatePosterScreen(lastLocation As String, currentLocation As String, style As String) As Object

    ' Setup Screen
    screen = CreateObject("roAssociativeArray")

    port   = CreateObject("roMessagePort")
    poster = CreateObject("roPosterScreen")
    poster.SetMessagePort(port)

    ' Setup Common Items
    screen.Screen     = poster
    screen.Port       = port
    screen.Categories = SetPosterCategories
    screen.Show       = ShowPosterScreen

    ' Set Breadcrumbs
    screen.Screen.SetBreadcrumbText(lastLocation, currentLocation)

    ' Setup Display Style
    screen.Screen.SetListStyle(style)
    screen.Screen.SetDisplayMode("scale-to-fit")

    Return screen
End Function


'**********************************************************
'** Set Categories for Poster Screen
'**********************************************************

Function SetPosterCategories(categories As Object) As Integer
    m.screen.SetListNames(categories)

    Return 0
End Function


'**********************************************************
'** Show Poster Screen
'**********************************************************

Function ShowPosterScreen() As Integer
    m.screen.Show()

    Return 0
End Function