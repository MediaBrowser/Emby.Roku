'**********************************************************
'**  Media Browser Roku Client - EHS
'**********************************************************


Function CreateEhsScreen() As Object

    ' Setup Screen
    o = CreateObject("roAssociativeArray")

    port   = CreateObject("roMessagePort")
    drawing = CreateObject("roScreen", true)
    drawing.SetMessagePort(port)

    ' Setup Common Items
    o.Screen          = drawing
    o.Port            = port
    o.DrawText        = DrawEhsText
    o.DrawObject      = DrawEhsObject
    o.RenderScreen    = RenderEhsScreen
    o.ClearScreen     = ClearEhsScreen
    o.GetWidth        = GetEhsScreenWidth
    o.GetHeight       = GetEhsScreenHeight
    o.DrawTile        = DrawEhsTile

    o.EhsTileOverlay  = false

    ' Create a single font registry
    o.FontRegistry = CreateObject("roFontRegistry")

    Return o
End Function

Function DrawEhsText(text as String, x as Integer, y as Integer, rgba as Integer, font as Object)
    m.screen.DrawText(text, x, y, rgba, font)
End Function

Function DrawEhsObject(x as Integer, y as Integer, src as Object)
    m.screen.DrawObject(x, y, src)
End Function

Function RenderEhsScreen()
    m.screen.SwapBuffers()
End Function

Function ClearEhsScreen(color)
    m.screen.Clear(color)
End Function


Function GetEhsScreenWidth()
    Return m.screen.GetWidth()
End Function

Function GetEhsScreenHeight()
    Return m.screen.GetHeight()
End Function


Function DrawEhsTile(region, imageUrl, imageX, imageY, overlayText)

    fontSmall = m.FontRegistry.getDefaultFont(16, false, false)
    white = &hFFFFFFFF	'RGBA

    ' Cache Overlay
    If type(m.EhsTileOverlay) = "roBitmap"
        overlayImage = m.EhsTileOverlay
    Else
        overlayImage = CreateObject("roBitmap", "pkg:/images/ehs/OverlayBG2.png")
        m.EhsTileOverlay = overlayImage
    End If

    ' Create Tile Image
    tileImage = CreateObject("roBitmap", imageUrl)

    ' Get Height of Image
    tileHeight = tileImage.GetHeight()

    ' Draw Image
    region.DrawObject(imageX, imageY, tileImage)

    ' Draw Overlay
    region.DrawObject(imageX, imageY+tileHeight-25, overlayImage)

    ' Draw Text
    region.DrawText(overlayText, imageX + 5, imageY+tileHeight-20, white, fontSmall)

End Function
