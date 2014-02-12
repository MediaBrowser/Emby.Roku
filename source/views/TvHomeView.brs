'**********************************************************
'**  Media Browser Roku Client - TV Home Screen View
'**********************************************************


Function createTvHomeView(controller) As Object

    ' Setup Screen
    o = CreateObject("roAssociativeArray")

    ' Create Grid Screen
    screen = CreateGridScreen("", "TV", "mixed-aspect-ratio", controller.GetPort())

    ' Setup Variables
    o.Screen         = screen
    o.Controller     = controller

    ' Setup Functions
    o.MessageHandler = tvhomeMessageHandler
    o.Show           = tvhomeShowView
    o.Close          = tvhomeCloseView

    return o
End Function


'**********************************************************
'** Message Handler for TV Home Screen View
'**********************************************************

Function tvhomeMessageHandler(msg) As Dynamic

    if type(msg) = "roGridScreenEvent" then

        if msg.isListItemFocused() then

        else if msg.isListItemSelected() then
            row = msg.GetIndex()
            selection = msg.getData()

            Debug("Content type: " + m.screen.rowContent[row][selection].ContentType)

            if m.screen.rowContent[row][selection].ContentType = "MovieLibrary" then
                Print "movie library selected"

            end if



        else if msg.isScreenClosed() then
            Debug("Close tv view")
            m.Controller.popScreen()

        end if

    end if

End Function


'**********************************************************
'** Load Data and Show TV Home Screen View
'**********************************************************

Function tvhomeShowView()

    ' Initialize TV Metadata

    m.screen.AddRow("All", "landscape")

    ' Fetch Default Data
    tvData = tvmetadata_show_list()

    'if showData = invalid
    '    createDialog("Problem Loading TV Series", "There was an problem while attempting to get the list of music albums from the server.", "Continue")
    '    return 0
    'end if

    m.screen.ShowNames()

    ' Set Content
    m.screen.AddRowContent(tvData.Items)

    ' Show Screen
    m.screen.Show()

End Function


'**********************************************************
'** Close TV Home Screen View
'**********************************************************

Function tvhomeCloseView()
    m.screen.Close()
End Function
