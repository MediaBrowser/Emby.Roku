'**********************************************************
'**  Media Browser Roku Client - Slideshow Screen
'**********************************************************


Function CreateSlideshowScreen() As Object

    ' Setup Screen
    o = CreateObject("roAssociativeArray")

    port      = CreateObject("roMessagePort")
    slideshow = CreateObject("roSlideShow")
    slideshow.SetMessagePort(port)

    ' Setup Common Items
    o.Screen         = slideshow
    o.Port           = Port
    o.Show           = ShowSlideshowScreen
    o.SetContentList = slideshowSetContentList
    o.SetNext        = slideshowSetNext

    ' Setup Slideshow Settings
	o.Screen.SetUnderscan(4.0)
	o.Screen.SetBorderColor("#504B4B")
	o.Screen.SetMaxUpscale(8.0)
	o.Screen.SetDisplayMode("best-fit")
	o.Screen.SetPeriod(6)

    Return o
End Function


'**********************************************************
'** Show Slideshow Screen
'**********************************************************

Function ShowSlideshowScreen()
    m.screen.Show()
End Function


'**********************************************************
'** Set Content List on Slideshow Screen
'**********************************************************

Function slideshowSetContentList(contentList as Object)
    m.screen.SetContentList(contentList)
End Function


'**********************************************************
'** Set Next Slide on Slideshow Screen
'**********************************************************

Function slideshowSetNext(item as Integer, isImmediate as Boolean)
    m.screen.SetNext(item, isImmediate)
End Function
