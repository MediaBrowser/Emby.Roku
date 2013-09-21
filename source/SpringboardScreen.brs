'**********************************************************
'**  Media Browser Roku Client - Springboard Screen
'**********************************************************


Function CreateSpringboardScreen(lastLocation As String, currentLocation As String, style As String, posterStyle = invalid As Dynamic) As Object

    ' Setup Screen
    o = CreateObject("roAssociativeArray")

    port = CreateObject("roMessagePort")
    springboard = CreateObject("roSpringboardScreen")
    springboard.SetMessagePort(port)

    ' Setup Common Items
    o.Screen            = springboard
    o.Port              = Port
    o.Show              = ShowSpringboardScreen
    o.SetContent        = springboardSetContent
    o.AddButton         = springboardAddButton
    o.AddButtons        = springboardAddButtons
    o.AddRatingButton   = springboardAddRatingButton
    o.ClearButtons      = springboardClearButtons
    o.AllowUpdates      = springboardAllowUpdates
    o.SetBreadcrumbText = springboardSetBreadcrumbText
    o.SetStaticRatingEnabled = springboardSetStaticRatingEnabled

    ' Set Breadcrumbs
    o.Screen.SetBreadcrumbText(lastLocation, currentLocation)

    ' Setup Display Style
    o.Screen.SetDescriptionStyle(style)

    if posterStyle <> invalid
        o.Screen.SetPosterStyle(posterStyle)
    end if

    Return o
End Function


'**********************************************************
'** Show Springboard Screen
'**********************************************************

Function ShowSpringboardScreen()
    m.screen.Show()
End Function


'**********************************************************
'** Set Content for Springboard Screen
'**********************************************************

Function springboardSetContent(contentList As Object)
    m.screen.SetContent(contentList)
End Function


'**********************************************************
'** Add Button for Springboard Screen
'**********************************************************

Function springboardAddButton(buttonId as Integer, title as String)
    m.screen.AddButton(buttonId, title)
End Function


'**********************************************************
'** Add Buttons for Springboard Screen
'**********************************************************

Function springboardAddButtons(buttons as Object)
    ' Add Each Button
    for each button in buttons
        m.AddButton(button.Id, button.Title)
    end for
End Function


'**********************************************************
'** Add Rating Button for Springboard Screen
'**********************************************************

Function springboardAddRatingButton(buttonId as Integer, userRating as Integer, aggregateRating as Integer)
    m.screen.AddRatingButton(buttonId, userRating, aggregateRating)
End Function


'**********************************************************
'** Clear Buttons for Springboard Screen
'**********************************************************

Function springboardClearButtons()
    m.screen.ClearButtons()
End Function


'**********************************************************
'** Allow Updates for Springboard Screen
'**********************************************************

Function springboardAllowUpdates(allow as Boolean)
    m.screen.AllowUpdates(allow)
End Function


'**********************************************************
'** Set Breadcrumb Text for Springboard Screen
'**********************************************************

Function springboardSetBreadcrumbText(lastLocation As String, currentLocation As String)
    m.screen.SetBreadcrumbText(lastLocation, currentLocation)
End Function


'**********************************************************
'** Set Static Rating Enabled for Springboard Screen
'**********************************************************

Function springboardSetStaticRatingEnabled(enable as Boolean)
    m.screen.SetStaticRatingEnabled(enable)
End Function
