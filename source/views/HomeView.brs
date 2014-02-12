'**********************************************************
'**  Media Browser Roku Client - Home Screen View
'**********************************************************


Function createHomeView(controller) As Object

    ' Setup Screen
    o = CreateObject("roAssociativeArray")

    ' Create Grid Screen
    screen = CreateGridScreen("", getGlobalVar("user").Title, "two-row-flat-landscape-custom", controller.GetPort())

    ' Setup Variables
    o.Screen         = screen
    'o.VController     = controller

    ' Setup Functions
    o.MessageHandler = homeMessageHandler
    o.Show           = homeShowView
    o.Close          = homeCloseView

    return o
End Function


'**********************************************************
'** Message Handler for Home Screen View
'**********************************************************

Function homeMessageHandler(msg) As Dynamic

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
            Debug("Close home view")
            'm.Controller.popScreen()

        end if

    end if

End Function


'**********************************************************
'** Load Data and Show Home Screen View
'**********************************************************

Function homeShowView()
    ' Get Item Counts
    mediaItemCounts = getMediaItemCounts()

    if mediaItemCounts = invalid
        createDialog("Problem Loading", "There was an problem while attempting to get media items from server. Please make sure your server is running and try again.", "Exit")
        return invalid
    end if

    ' Setup Grid Rows
    if RegRead("prefCollectionsFirstRow") = "yes" then
        m.screen.AddRow("Media Folders", "landscape")
    end if
    
    if mediaItemCounts.MovieCount > 0 then
        m.screen.AddRow("Movies", "landscape")
    end if

    if mediaItemCounts.SeriesCount > 0 then
        m.screen.AddRow("TV", "landscape")
    end if

    if mediaItemCounts.SongCount > 0 then
        m.screen.AddRow("Music", "landscape")
    end if

    if RegRead("prefCollectionsFirstRow") = "no" Or RegRead("prefCollectionsFirstRow") = invalid then
        m.screen.AddRow("Media Folders", "landscape")
    end if

    m.screen.AddRow("Options", "landscape")
    m.screen.ShowNames()

    ' Get Grid Data
    if RegRead("prefCollectionsFirstRow") = "yes" then
        collectionButtons = GetCollectionButtons()
        m.screen.AddRowContent(collectionButtons)
    end if

    if mediaItemCounts.MovieCount > 0 then
        moviesButtons = GetMoviesButtons()
        m.screen.AddRowContent(moviesButtons)
    end if

    if mediaItemCounts.SeriesCount > 0 then
        tvButtons = GetTVButtons()
        m.screen.AddRowContent(tvButtons)
    end if

    if mediaItemCounts.SongCount > 0 then
        musicButtons = GetMusicButtons()
        m.screen.AddRowContent(musicButtons)
    end if

    if RegRead("prefCollectionsFirstRow") = "no" Or RegRead("prefCollectionsFirstRow") = invalid
        collectionButtons = GetCollectionButtons()
        m.screen.AddRowContent(collectionButtons)
    end if

    optionButtons = GetOptionsButtons()
    m.screen.AddRowContent(optionButtons)

    ' Show Grid Screen
    m.screen.Show()

    ' Hide Description Popup
    m.screen.SetDescriptionVisible(false)
End Function


'**********************************************************
'** Close Home Screen View
'**********************************************************

Function homeCloseView()
    m.screen.Close()
End Function
