'*****************************************************************
'**  Media Browser Roku Client - Controller
'*****************************************************************


'******************************************************
' Create the Main Controller
'******************************************************

Function createController() As Object

    ' Setup Controller
    o = CreateObject("roAssociativeArray")

    ' Setup Variables
    o.port           = CreateObject("roMessagePort")
    o.screenStack    = CreateObject("roArray", 10, true)

    ' Setup Functions
    o.getPort        = ctrlGetPort
    o.startUp        = ctrlStartUp
    o.eventLoop      = ctrlEventLoop
    o.pushScreen     = ctrlPushScreen
    o.popScreen      = ctrlPopScreen

    ' View Functions
    o.createHomeView   = ctrlCreateHomeView
    o.createTvHomeView = ctrlCreateTvHomeView

    return o
End Function


'**********************************************************
'** 
'**********************************************************

Function ctrlGetPort()
    return m.port
End Function


'**********************************************************
'** 
'**********************************************************

Function ctrlStartUp() As Object

    v = m.createHomeView()
    'm.createTvHomeView()

End Function


'**********************************************************
'** 
'**********************************************************

Function ctrlEventLoop()

    Print "before Event loop"

    'printList(m.screenStack)

    Count = 1
    while true
        msg = wait(0, m.port)

        Print "inside Event loop"

        Count = Count + 1
        'm.screenStack[0].MessageHandler(msg)

        If Count = 10 Then Exit while

    end while

    Print "after Event loop"


End Function

'**********************************************************
'** 
'**********************************************************

Function ctrlPushScreen(v)
    ' Add View to screen stack
    m.screenStack.push(v)
End Function


'**********************************************************
'** 
'**********************************************************

Function ctrlPopScreen()
    ' Remove view from screen stack
    v = m.screenStack.pop()

    ' Close View screen
    if v <> invalid
        v.Close()
    end if
End Function


'**********************************************************
'** Create Views
'**********************************************************

Function ctrlCreateHomeView()
    ' Create Facade
    'facade = CreateObject("roGridScreen")
    'facade.Show()

    ' Create View
    v = createHomeView(m)

    ' Add View to screen stack
    m.pushScreen(v.screen)

    ' Show Screen
    v.Show()
    Print "after home show"
   
    ' Close Facade Screen
    'facade.Close()

    return v
End Function

Function ctrlCreateTvHomeView()
    ' Create Facade
    'facade = CreateObject("roGridScreen")
    'facade.Show()

    ' Create View
    'v = createTvHomeView(m)

    ' Add View to screen stack
    'm.pushScreen(v)

    ' Show Screen
    'v.Show()

    ' Close Facade Screen
    'facade.Close()

    'return v
End Function

