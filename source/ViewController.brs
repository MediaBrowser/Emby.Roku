'*
'* A controller for managing the stack of screens that have been displayed.
'* By centralizing this we can better support things like destroying and
'* recreating views and breadcrumbs. It also provides a single place that
'* can take an item and figure out which type of screen should be shown
'* so that logic doesn't have to be in each individual screen type.
'*

Function createViewController() As Object
    controller = CreateObject("roAssociativeArray")

    controller.breadcrumbs = CreateObject("roArray", 10, true)
    controller.screens = CreateObject("roArray", 10, true)

    controller.GlobalMessagePort = CreateObject("roMessagePort")
    
	controller.CreateHomeScreen = vcCreateHomeScreen
	controller.CreateScreenForItem = vcCreateScreenForItem
	controller.ShowInitialScreen = vcShowInitialScreen
	controller.CreateTextInputScreen = vcCreateTextInputScreen
    controller.CreateEnumInputScreen = vcCreateEnumInputScreen
    controller.CreateContextMenu = vcCreateContextMenu
    
	controller.CreatePhotoPlayer = vcCreatePhotoPlayer
    controller.CreateVideoPlayer = vcCreateVideoPlayer
    controller.CreatePlayerForItem = vcCreatePlayerForItem
    controller.IsVideoPlaying = vcIsVideoPlaying

    controller.getDefaultTheme = vcGetDefaultTheme
	controller.loadUserTheme = vcLoadUserTheme

	controller.changeUser = vcChangeUser
	
	' An object containing information about the current custom theme (if any)
	controller.themeMetadata = invalid
	
	controller.getThemeImageUrl = vcGetThemeImageUrl
	
	controller.getPort = vcGetPort

    controller.InitializeOtherScreen = vcInitializeOtherScreen
    controller.AssignScreenID = vcAssignScreenID
    controller.PushScreen = vcPushScreen
    controller.PopScreen = vcPopScreen
    controller.IsActiveScreen = vcIsActiveScreen

    controller.afterCloseCallback = invalid
    controller.CloseScreenWithCallback = vcCloseScreenWithCallback
    controller.CloseScreen = vcCloseScreen

    controller.Show = vcShow
    controller.OnInitialized = vcOnInitialized
    controller.UpdateScreenProperties = vcUpdateScreenProperties
    controller.AddBreadcrumbs = vcAddBreadcrumbs

    controller.DestroyGlitchyScreens = vcDestroyGlitchyScreens
	
	' Even with the splash screen, we still need a facade for memory purposes
    ' and a clean exit.
    controller.facade = CreateObject("roGridScreen")
    controller.facade.Show()

    controller.nextScreenId = 1
    controller.nextTimerId = 1

    controller.PendingRequests = {}
    controller.RequestsByScreen = {}
    controller.StartRequest = vcStartRequest
    controller.StartRequestIgnoringResponse = vcStartRequestIgnoringResponse
    controller.CancelRequests = vcCancelRequests

    controller.SocketListeners = {}
    controller.AddSocketListener = vcAddSocketListener

    controller.Timers = {}
    controller.TimersByScreen = {}
    controller.AddTimer = vcAddTimer

    controller.SystemLog = CreateObject("roSystemLog")
    controller.SystemLog.SetMessagePort(controller.GlobalMessagePort)
    controller.SystemLog.EnableType("bandwidth.minute")

    controller.backButtonTimer = createTimer()
    controller.backButtonTimer.SetDuration(60000, true)

    ' Stuff the controller into the global object
    m.ViewController = controller

    ' Initialize things that run in the background
    'AppManager().AddInitializer("viewcontroller")
    InitWebServer(controller)
    AudioPlayer()

    return controller
End Function

Sub vcAddSocketListener(socket, listener)
    m.SocketListeners[socket.GetID().tostr()] = listener
End Sub

Function GetViewController()
    return m.ViewController
End Function

Sub vcOnInitialized()

	m.ShowInitialScreen()
End Sub

Sub vcShowInitialScreen()

	sendWolToAllServers()
	
    ' Server Start Up
    serverStart = serverStartUp()
	
    '** 0 = First Run, 1 = Server List, 2 = Connect to Server
    if serverStart = 0
        Print "Server Setup"
        screen = createServerFirstRunSetupScreen(m)
		m.InitializeOtherScreen(screen, ["Setup"])
		screen.Show()
		
    else if serverStart = 1
        Print "Server List"
        showServerListScreen(m)

    else if serverStart = 2
        Print "Connecting To Server"

		' Check to see if they have already selected a User
		' Show home page if so, otherwise show login page.
		if RegRead("userId") <> invalid And RegRead("userId") <> ""

			if RegRead("prefRememberUser") = "no"
				RegDelete("userId")
				showLoginScreen(m)

			else
				m.changeUser(RegRead("userId"))
			end if
		
		else
	
			showLoginScreen(m)
		end if
    end if

End Sub

Sub showLoginScreen(viewController as Object)
	screen = CreateLoginScreen(viewController)
	screen.ScreenName = "Login"
	viewController.InitializeOtherScreen(screen, ["Please Sign In"])
	screen.Screen.SetBreadcrumbEnabled(true)
	screen.Show()
End Sub

Sub vcChangeUser(userId as String)

    userProfile = getUserProfile(RegRead("userId"))

    ' If unable to get user profile, delete saved user and redirect to login
    if userProfile = invalid
        RegDelete("userId")
        m.ShowInitialScreen()
    end if

    GetGlobalAA().AddReplace("user", userProfile)

    m.Home = m.CreateHomeScreen()

End Sub

Function vcCreateHomeScreen()
    screen = createHomeScreen(m)
    screen.ScreenName = "Home"
    m.InitializeOtherScreen(screen, invalid)
    screen.Screen.SetBreadcrumbEnabled(true)

	screen.refreshBreadcrumb()

    screen.Show()

    return screen
End Function

Function vcGetDefaultTheme() as Object

    theme = {

        '*** HD Styles ****
        OverhangSliceHD: vcGetDefaultThemeImageUrl("hd-header-slice.png")
        OverhangLogoHD: vcGetDefaultThemeImageUrl("hd-logo.png")
        OverhangOffsetHD_X: "80"
        OverhangOffsetHD_Y: "30"

        FilterBannerSliceHD: vcGetDefaultThemeImageUrl("hd-filter-banner.png")
        FilterBannerActiveHD: vcGetDefaultThemeImageUrl("hd-filter-active.png")
        FilterBannerInactiveHD: vcGetDefaultThemeImageUrl("hd-filter-inactive.png")

        GridScreenLogoHD: vcGetDefaultThemeImageUrl("hd-logo.png")
        GridScreenOverhangSliceHD: vcGetDefaultThemeImageUrl("hd-header-slice.png")
        GridScreenLogoOffsetHD_X: "80"
        GridScreenLogoOffsetHD_Y: "30"
        GridScreenOverhangHeightHD: "120"
        GridScreenFocusBorderHD: vcGetDefaultThemeImageUrl("hd-border-flat-landscape.png")
        GridScreenBorderOffsetHD: "(-34,-19)"
        'GridScreenDescriptionImageHD: vcGetDefaultThemeImageUrl("hd-description-background.png")

        '*** SD Styles ****

        OverhangSliceSD: vcGetDefaultThemeImageUrl("hd-header-slice.png")
        OverhangLogoSD: vcGetDefaultThemeImageUrl("sd-logo.png")
        OverhangOffsetSD_X: "20"
        OverhangOffsetSD_Y: "20"

        FilterBannerSliceSD: vcGetDefaultThemeImageUrl("sd-filter-banner.png")
        FilterBannerActiveSD: vcGetDefaultThemeImageUrl("sd-filter-active.png")
        FilterBannerInactiveSD: vcGetDefaultThemeImageUrl("sd-filter-inactive.png")

        GridScreenLogoSD: vcGetDefaultThemeImageUrl("sd-logo.png")
        GridScreenOverhangSliceSD: vcGetDefaultThemeImageUrl("hd-header-slice.png")
        GridScreenLogoOffsetSD_X: "20"
        GridScreenLogoOffsetSD_Y: "20"
        GridScreenOverhangHeightSD: "83"

        '*** Common Styles ****

        BackgroundColor: "#181818"

        BreadcrumbTextLeft: "#dfdfdf"
        BreadcrumbTextRight: "#eeeeee"
        BreadcrumbDelimiter: "#eeeeee"

		ButtonMenuNormalText: "#333333"
		ButtonNormalColor: "#333333"

        ParagraphHeaderText: "#ffffff"
        ParagraphBodyText: "#dfdfdf"

        PosterScreenLine1Text: "#ffffff"
        PosterScreenLine2Text: "#bbbbbb"
        EpisodeSynopsisText: "#dfdfdf"

        'ListItemText: "#dfdfdf"
        'ListItemHighlightText: "#ffffff"
        'ListScreenDescriptionText: "#9a9a9a"
        ListScreenTitleColor: "#ffffff"
        ListScreenHeaderText: "#ffffff"

        CounterTextLeft: "#ffffff"
        CounterTextRight: "#ffffff"
        CounterSeparator: "#ffffff"

        FilterBannerActiveColor: "#ffffff"
        FilterBannerInactiveColor: "#cccccc"
        FilterBannerSideColor: "#cccccc"

        GridScreenBackgroundColor: "#181818"
        'GridScreenListNameColor: "#ffffff"
        'GridScreenDescriptionTitleColor: "#ffffff"
        'GridScreenDescriptionDateColor: "#ffffff"
        'GridScreenDescriptionSynopsisColor: "#ffffff"
        'GridScreenDescriptionRuntimeColor: "#ffffff"

        SpringboardActorColor: "#9a9a9a"

        SpringboardAlbumColor: "#ffffff"
        SpringboardAlbumLabel: "#ffffff"
        SpringboardAlbumLabelColor: "#ffffff"

        SpringboardAllow6Buttons: "true"

        SpringboardArtistColor: "#ffffff"
        SpringboardArtistLabel: "#ffffff"
        SpringboardArtistLabelColor: "#ffffff"

        SpringboardDirectorColor: "#ffffff"
        SpringboardDirectorLabelColor: "#181818"
        'SpringboardDirectorPrefixText: "#ffffff"

        SpringboardGenreColor: "#ffffff"
        SpringboardRuntimeColor: "#ffffff"
        SpringboardSynopsisColor: "#dfdfdf"
        SpringboardTitleText: "#ffffff"

        ThemeType: "generic-dark"
    }

	return theme
	
End Function

Function vcGetThemeImageUrl(name as String) as String

	url = invalid
	
	if m.themeMetadata <> invalid then
		url = getImageUrlFromThemeMetadata(m.themeMetadata)
	end if
	
	if url = invalid then
		url = vcGetDefaultThemeImageUrl(name)
	end if
	
	return url

End Function

Function getImageUrlFromThemeMetadata(themeMetadata as Object) as String

	' TODO: loop through the images of the custom theme, and if found, build the full url and return it
	url = invalid
	
	return url

End Function

Function vcGetDefaultThemeImageUrl(name as String) as String

	url = "pkg:/images/themes/default/" + name
	
	return url

End Function

Sub vcLoadUserTheme()

	themeMetadata = getCustomTheme()
	m.themeMetadata = themeMetadata
	
	theme = m.getDefaultTheme()
	
	if themeMetadata <> invalid then
	
		' Override theme properties with values from themeMetadata
		if themeMetadata.Options <> invalid then
			for each key in themeMetadata.Options
				theme.AddReplace(key, themeMetadata.Options[key])
			end for
		end If
		
	end if
	
    ' Set background Color
    GetGlobalAA().AddReplace("backgroundColor", theme.BackgroundColor)

    app = CreateObject("roAppManager")
    app.SetTheme( theme )
	
End Sub

Function getCustomTheme() as Object

	' TODO: Figure out current user id
	' TODO: Get saved theme id based on current user id
	' TODO: Download theme metadata from server based on theme id
	' Return invalid if none, or if anything fails
	theme = invalid
	
	return theme
	
End Function

Sub vcShow()

	m.loadUserTheme()
	
	m.OnInitialized()

    timeout = 0
    while m.screens.Count() > 0
        m.WebServer.prewait()
        msg = wait(timeout, m.GlobalMessagePort)
        if msg <> invalid then
            ' Printing debug information about every message may be overkill
            ' regardless, but note that URL events don't play by the same rules,
            ' and there's no ifEvent interface to check for. Sigh.
            'if GetInterface(msg, "ifUrlEvent") = invalid AND GetInterface(msg, "ifSocketEvent") = invalid then
                'Debug("Processing " + type(msg) + " (top of stack " + type(m.screens.Peek().Screen) + "): " + tostr(msg.GetType()) + ", " + tostr(msg.GetIndex()) + ", " + tostr(msg.GetMessage()))
            'end if

            for i = m.screens.Count() - 1 to 0 step -1
                if m.screens[i].HandleMessage(msg) then exit for
            end for

            ' Process URL events. Look up the request context and call a
            ' function on the listener.
            if type(msg) = "roUrlEvent" AND msg.GetInt() = 1 then
                id = msg.GetSourceIdentity().tostr()
                requestContext = m.PendingRequests[id]
                if requestContext <> invalid then
                    m.PendingRequests.Delete(id)
                    if requestContext.Listener <> invalid then
                        requestContext.Listener.OnUrlEvent(msg, requestContext)
                    end if
                    requestContext = invalid
                end if
            else if type(msg) = "roSocketEvent" then
                listener = m.SocketListeners[msg.getSocketID().tostr()]
                if listener <> invalid then
                    listener.OnSocketEvent(msg)
                    listener = invalid
                else
                    ' Assume it was for the web server (it won't hurt if it wasn't)
                    m.WebServer.postwait()
                end if
            else if type(msg) = "roAudioPlayerEvent" then
                AudioPlayer().HandleMessage(msg)
            else if type(msg) = "roSystemLogEvent" then
                msgInfo = msg.GetInfo()
                if msgInfo.LogType = "bandwidth.minute" then
                    GetGlobalAA().AddReplace("bandwidth", msgInfo.Bandwidth)
                end if
            else if msg.isRemoteKeyPressed() and msg.GetIndex() = 10 then
                m.CreateContextMenu()
            end if
        end if

        ' Check for any expired timers
        timeout = 0
        for each timerID in m.Timers
            timer = m.Timers[timerID]
            if timer.IsExpired() then
                timer.Listener.OnTimerExpired(timer)
            end if

            ' Make sure we set a timeout on the wait so we'll catch the next timer
            remaining = timer.RemainingMillis()
            if remaining > 0 AND (timeout = 0 OR remaining < timeout) then
                timeout = remaining
            end if
        next
    end while

    ' Clean up some references on the way out
    AudioPlayer().Cleanup()
    m.Home = invalid
    m.WebServer = invalid
    m.Timers.Clear()
    m.PendingRequests.Clear()
    m.SocketListeners.Clear()

    Debug("Finished global message loop")
	
End Sub

Function vcGetPort()
	return m.GlobalMessagePort
End Function

Sub InitWebServer(vc)

    ' Initialize some globals for the web server
    globals = CreateObject("roAssociativeArray")
    globals.pkgname = "Media Browser"
    globals.maxRequestLength = 4000
    globals.idletime = 60
    globals.wwwroot = "tmp:/"
    globals.index_name = "index.html"
    globals.serverName = "MediaBrowser"
    AddGlobals(globals)
    MimeType()
    HttpTitle()
    
	ClassReply().AddHandler("/mediabrowser/message/MoveUp", ProcessNavigationMoveUp)
	ClassReply().AddHandler("/mediabrowser/message/MoveRight", ProcessNavigationMoveRight)
	ClassReply().AddHandler("/mediabrowser/message/MoveLeft", ProcessNavigationMoveLeft)
	ClassReply().AddHandler("/mediabrowser/message/MoveDown", ProcessNavigationMoveDown)
	ClassReply().AddHandler("/mediabrowser/message/Select", ProcessNavigationSelect)
	ClassReply().AddHandler("/mediabrowser/message/GoHome", ProcessNavigationHome)
	ClassReply().AddHandler("/mediabrowser/message/Back", ProcessNavigationBack)
	ClassReply().AddHandler("/mediabrowser/message/GoToSettings", ProcessNavigationSettings)
	ClassReply().AddHandler("/mediabrowser/message/GoToSearch", ProcessNavigationSearch)
	ClassReply().AddHandler("/mediabrowser/message/SendString", ProcessApplicationSetText)
	ClassReply().AddHandler("/mediabrowser/message/ShowNowPlaying", ProcessApplicationSetText)
	ClassReply().AddHandler("/mediabrowser/message/Ping", ProcessPingRequest)
	ClassReply().AddHandler("/mediabrowser/message/ServerRestarting", ProcessPingRequest)
	ClassReply().AddHandler("/mediabrowser/message/ServerShuttingDown", ProcessPingRequest)
	ClassReply().AddHandler("/mediabrowser/message/RestartRequired", ProcessPingRequest)
	ClassReply().AddHandler("/mediabrowser/message/Stop", ProcessPlaybackStop)
	ClassReply().AddHandler("/mediabrowser/message/Pause", ProcessPlaybackPause)
	ClassReply().AddHandler("/mediabrowser/message/Unpause", ProcessPlaybackPlay)
	ClassReply().AddHandler("/mediabrowser/message/NextTrack", ProcessPlaybackSkipNext)
	ClassReply().AddHandler("/mediabrowser/message/PreviousTrack", ProcessPlaybackSkipPrevious)
	ClassReply().AddHandler("/mediabrowser/message/Seek", ProcessPlaybackSeekTo)
	ClassReply().AddHandler("/mediabrowser/message/Rewind", ProcessPlaybackStepBack)
	ClassReply().AddHandler("/mediabrowser/message/FastForward", ProcessPlaybackStepForward)

	ClassReply().AddHandler("/mediabrowser/message/PlayNow", ProcessPlaybackPlayMedia)

    vc.WebServer = InitServer({msgPort: vc.GlobalMessagePort, port: 8324})
End Sub

Function ProcessPingRequest() As Boolean
   	
	m.simpleOK("")
	return true

End Function

Function ProcessNavigationSettings() As Boolean
	
	m.simpleOK("")
	return true

End Function

Function ProcessNavigationSearch() As Boolean
   	
	m.simpleOK("")
	return true

End Function

Function ProcessPlaybackPlayMedia() As Boolean

	ids = m.request.query["ItemIds"]

    r = CreateObject("roRegex", ",", "")
    idArray = r.Split(ids)

	item = getVideoMetadata(idArray[0])

	items = []
	items.push(item)

	GetViewController().CreatePlayerForItem(items, 0)

    m.simpleOK("")
    return true

End Function

Function ProcessPlaybackSeekTo() As Boolean

    offset = m.request.query["SeekPositionTicks"]

    if AudioPlayer().IsPlaying then
        AudioPlayer().Seek(int(val(offset)))
    else

		videoPlayer = VideoPlayer()

		if videoPlayer <> invalid then
            player.Seek(int(val(offset)))
		else 
			
		end If
    end if

    m.simpleOK("")
    return true
End Function

Function ProcessPlaybackSkipNext() As Boolean

    ' Try to deal with the command directly, falling back to ECP.
    if AudioPlayer().IsPlaying then
        AudioPlayer().Next()
    else

		videoPlayer = VideoPlayer()

		if videoPlayer <> invalid then
			videoPlayer.Next()
		else 
			photoPlayer = PhotoPlayer()
			if photoPlayer <> invalid then 
				photoPlayer.Next()
			else
				SendEcpCommand("Fwd")
			end if
		end If
    end if

    m.simpleOK("")
    return true
End Function

Function ProcessPlaybackSkipPrevious() As Boolean

    ' Try to deal with the command directly, falling back to ECP.
    if AudioPlayer().IsPlaying then
        AudioPlayer().Prev()
    else

		videoPlayer = VideoPlayer()

		if videoPlayer <> invalid then
			videoPlayer.Prev()
		else 
			photoPlayer = PhotoPlayer()
			if photoPlayer <> invalid then 
				photoPlayer.Prev()
			else
				SendEcpCommand("Rev")
			end if
		end If
    end if

    m.simpleOK("")
    return true
End Function

Function ProcessPlaybackStepBack() As Boolean

    ' Try to deal with the command directly, falling back to ECP.
    if AudioPlayer().IsPlaying then
        AudioPlayer().Seek(-15000, true)
    else

		videoPlayer = VideoPlayer()

		if videoPlayer <> invalid then
			SendEcpCommand("InstantReplay")
		else 
			
		end If
    end if

    m.simpleOK("")
    return true
End Function

Function ProcessPlaybackStepForward() As Boolean

    player = invalid
    
	' Try to deal with the command directly, falling back to ECP.
    if AudioPlayer().IsPlaying then
        player = AudioPlayer()
    else
		player = VideoPlayer()
    end if

    if player <> invalid then
        player.Seek(30000, true)
    end if

    m.simpleOK("")
    return true
End Function

Function ProcessPlaybackPause() As Boolean

    ' Try to deal with the command directly, falling back to ECP.
    if AudioPlayer().IsPlaying then
        AudioPlayer().Pause()
    else

		videoPlayer = VideoPlayer()

		if videoPlayer <> invalid then
			videoPlayer.Pause()
		else 
			photoPlayer = PhotoPlayer()
			if photoPlayer <> invalid then photoPlayer.Pause()

		end If
    end if

    m.simpleOK("")
    return true
End Function

Function ProcessPlaybackPlay() As Boolean

    ' Try to deal with the command directly, falling back to ECP.
    if AudioPlayer().IsPlaying then
        AudioPlayer().Resume()
    else

		videoPlayer = VideoPlayer()

		if videoPlayer <> invalid then
			videoPlayer.Resume()
		else 
			photoPlayer = PhotoPlayer()
			if photoPlayer <> invalid then 
				photoPlayer.Resume()
			else
				SendEcpCommand("Play")
			end if
		end If
    end if

    m.simpleOK("")
    return true
End Function

Function ProcessPlaybackStop() As Boolean

    ' Try to deal with the command directly, falling back to ECP.
    if AudioPlayer().IsPlaying then
        AudioPlayer().Stop()
    else

		videoPlayer = VideoPlayer()

		if videoPlayer <> invalid then
			videoPlayer.Stop()
		else 
			photoPlayer = PhotoPlayer()
			if photoPlayer <> invalid then photoPlayer.Stop()

		end If
    end if

    m.simpleOK("")
    return true

End Function

Function ProcessNavigationMoveRight() As Boolean

    SendEcpCommand("Right")
	
	m.simpleOK("")
	return true

End Function

Function ProcessNavigationMoveLeft() As Boolean

    SendEcpCommand("Left")
	
	m.simpleOK("")
	return true

End Function

Function ProcessNavigationMoveDown() As Boolean

    SendEcpCommand("Down")
	
	m.simpleOK("")
	return true

End Function

Function ProcessNavigationMoveUp() As Boolean

    SendEcpCommand("Up")
	
	m.simpleOK("")
	return true

End Function

Sub ProcessNavigationSelect() As Boolean

    SendEcpCommand("Select")
	
	m.simpleOK("")
	return true
	
End Sub

Sub ProcessNavigationHome() As Boolean

    context = CreateObject("roAssociativeArray")
    context.OnAfterClose = CloseScreenUntilHomeVisible
    context.OnAfterClose()

    m.simpleOK("")
	return true
	
End Sub

Sub ProcessNavigationBack() As Boolean

    ' Sending an ECP back can potentially exit the app, so leave it up to the
    ' ViewController to close the active screen.
    GetViewController().CloseScreen(true)
	
	m.simpleOK("")
	return true
	
End Sub

Function ProcessApplicationSetText() As Boolean

    screen = GetViewController().screens.Peek()

    if type(screen.SetText) = "roFunction" then
	
        value = firstOf(m.request.query["String"], "")
        NowPlayingManager().textFieldContent = value
        screen.SetText(value, true)

	end if

    m.simpleOK("")
    return true
	
End Function

Function ProcessNavigationMusic() As Boolean

    dummyItem = CreateObject("roAssociativeArray")
    dummyItem.ContentType = "audio"
    dummyItem.Key = "nowplaying"
    GetViewController().CreateScreenForItem(dummyItem, invalid, ["Now Playing"])

    m.simpleOK("")
    return true
End Function

Sub SendEcpCommand(command)
    GetViewController().StartRequestIgnoringResponse("http://127.0.0.1:8060/keypress/" + command, "", "txt")
End Sub

Sub vcInitializeOtherScreen(screen, breadcrumbs)
    m.AddBreadcrumbs(screen, breadcrumbs)
    m.UpdateScreenProperties(screen)
    m.PushScreen(screen)
End Sub

Sub vcAssignScreenID(screen)
    if screen.ScreenID = invalid then
        screen.ScreenID = m.nextScreenId
        m.nextScreenId = m.nextScreenId + 1
    end if
End Sub

Function vcStartRequest(urlTransferObject, listener, context, body=invalid, method = invalid) As Boolean

    urlTransferObject.SetPort(m.GlobalMessagePort)
    context.Listener = listener
    context.Request = urlTransferObject

    if method = "post" then
        started = urlTransferObject.AsyncPostFromString(body)
    else if body = invalid then
        started = urlTransferObject.AsyncGetToString()
    else
        started = urlTransferObject.AsyncPostFromString(body)
    end if

    if started then
        id = urlTransferObject.GetIdentity().tostr()
        m.PendingRequests[id] = context

        if listener <> invalid then
            screenID = listener.ScreenID.tostr()
            if NOT m.RequestsByScreen.DoesExist(screenID) then
                m.RequestsByScreen[screenID] = []
            end if
            ' Screen ID's less than 0 are fake screens that won't be popped until
            ' the app is cleaned up, so no need to waste the bytes tracking them
            ' here.
            if listener.ScreenID >= 0 then m.RequestsByScreen[screenID].Push(id)
        end if

        return true
    else
        return false
    end if
End Function

Sub vcStartRequestIgnoringResponse(url, body=invalid, contentType="xml")
    request = CreateURLTransferObject(url)
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")

    if body <> invalid then
        request.AddHeader("Content-Type", MimeType(contentType))
    end if

    context = CreateObject("roAssociativeArray")
    context.requestType = "ignored"

    m.StartRequest(request, invalid, context, body)
End Sub

Sub vcPushScreen(screen)
    m.AssignScreenID(screen)
    screenName = firstOf(screen.ScreenName, type(screen.Screen))
    
	Debug("Pushing screen " + tostr(screen.ScreenID) + " onto view controller stack - " + screenName)
    m.screens.Push(screen)
End Sub

Sub vcPopScreen(screen)
    if screen.Cleanup <> invalid then screen.Cleanup()

    ' Try to clean up some potential circular references
    screen.Listener = invalid
    if screen.Loader <> invalid then
        screen.Loader.Listener = invalid
        screen.Loader = invalid
    end if

    if screen.ScreenID = invalid OR m.screens.Peek().ScreenID = invalid then
        Debug("Trying to pop screen a screen without a screen ID!")
        Return
    end if

    callActivate = true
    screenID = screen.ScreenID.tostr()
    if screen.ScreenID <> m.screens.Peek().ScreenID then
        Debug("Trying to pop screen that doesn't match the top of our stack!")

        ' This is potentially indicative of something very wrong, which we may
        ' not be able to recover from. But it also happens when we launch a new
        ' screen from a dialog and try to pop the dialog after the new screen
        ' has been put on the stack. If we don't remove the screen from the
        ' stack, things will almost certainly go wrong (seen one crash report
        ' likely caused by this). So we might as well give it a shot.

        for i = m.screens.Count() - 1 to 0 step -1
            if screen.ScreenID = m.screens[i].ScreenID then
                Debug("Removing screen " + screenID + " from middle of stack!")
                m.screens.Delete(i)
                exit for
            end if
        next
        callActivate = false
    else
        Debug("Popping screen " + screenID + " and cleaning up " + tostr(screen.NumBreadcrumbs) + " breadcrumbs")
        m.screens.Pop()
        for i = 0 to screen.NumBreadcrumbs - 1
            m.breadcrumbs.Pop()
        next
    end if

    ' Clean up any requests initiated by this screen
    m.CancelRequests(screen.ScreenID)

    ' Clean up any timers initiated by this screen
    timers = m.TimersByScreen[screenID]
    if timers <> invalid then
        for each timerID in timers
            timer = m.Timers[timerID]
            timer.Active = false
            timer.Listener = invalid
            m.Timers.Delete(timerID)
        next
        m.TimersByScreen.Delete(screenID)
    end if

    ' Let the new top of the stack know that it's visible again. If we have
    ' no screens on the stack, but we didn't just close the home screen, then
    ' we haven't shown the home screen yet. Show it now.
    if m.Home <> invalid AND screen.screenID = m.Home.ScreenID then
        Debug("Popping home screen")
        while m.screens.Count() > 1
            m.PopScreen(m.screens.Peek())
        end while
        m.screens.Pop()
    else if m.screens.Count() = 0 then
        m.Home = m.CreateHomeScreen()
    else if callActivate then
        newScreen = m.screens.Peek()
        screenName = firstOf(newScreen.ScreenName, type(newScreen.Screen))
        Debug("Top of stack is once again: " + screenName)
        
		newScreen.Activate(screen)
    end if

    ' If some other screen requested this close, let it know.
    if m.afterCloseCallback <> invalid then
        callback = m.afterCloseCallback
        m.afterCloseCallback = invalid
        callback.OnAfterClose()
    end if
End Sub

Function vcIsActiveScreen(screen) As Boolean
    return m.screens.Peek().ScreenID = screen.ScreenID
End Function


Function vcCreateScreenForItem(context, contextIndex, breadcrumbs, show=true) As Dynamic

	Debug("Entered CreateScreenForItem")

    if type(context) = "roArray" then
        item = context[contextIndex]
    else
        item = context
    end if

    contentType = item.ContentType
	itemId = item.Id
    viewGroup = item.viewGroup
    if viewGroup = invalid then viewGroup = ""

    screen = invalid

    ' NOTE: We don't support switching between them as a preference, but
    ' the poster screen can be used anywhere the grid is used below. By
    ' default the poster screen will try to decide whether or not to
    ' include the filter bar that makes it more grid like, but it can
    ' be forced by setting screen.FilterMode = true.

    screenName = invalid

	if contentType = "Preferences" then
	
        screen = createPreferencesScreen(m)
        screenName = "Preferences"

	else if contentType = "Search" then

        screen = createSearchScreen(m)
        screenName = "Search"

	else if contentType = "SwitchUser" then

        RegDelete("userId")
        Debug("Switch User")

		' For now, until there's a chance to break the initial screen workflow into separate pieces
		m.ShowInitialScreen()

    else if contentType = "TVLibrary" then
		screen = createTvLibraryScreen(m)
        screenName = "TVLibrary"

    else if contentType = "MovieLibrary" then
		screen = createMovieLibraryScreen(m)
        screenName = "MovieLibrary"

    else if contentType = "TvChannel" then
		screen = createLiveTvProgramsScreen(m, item)
		screenName = "TvChannel " + itemId

    else if item.MediaType = "Video" or item.MediaType = "Game" or item.MediaType = "Book" or contentType = "ItemPerson" then
		Debug ("Calling createVideoSpringboardScreen")
		screen = createVideoSpringboardScreen(context, contextIndex, m)
		screenName = "VideoSpringboardScreen" + itemId

    else if contentType = "MusicGenre" then
		screen = createMusicGenresScreen(m, item.Title)
		screenName = "MusicGenre " + item.Title

    else if contentType = "MovieGenre" then
		screen = createMovieGenreScreen(m, item.Title)
		screenName = "MovieGenre " + item.Title

    else if contentType = "Genre" then
		screen = createGenreSearchScreen(m, item.Title)
		screenName = "GenreSearch " + item.Title

    else if contentType = "MovieAlphabet" then
		screen = createMovieAlphabetScreen(m, itemId)
        screenName = "MovieAlphabet " + itemId

    else if contentType = "TvGenre" then
		screen = createTvGenreScreen(m, item.Title)
		screenName = "TvGenre " + item.Title

    else if contentType = "TvAlphabet" then
		screen = createTvAlphabetScreen(m, itemId)
        screenName = "TvAlphabet " + itemId

    else if contentType = "Series" then
		screen = createTvSeasonsScreen(m, item)
        screenName = "Series " + itemId

    else if contentType = "LiveTVChannels" then
		screen = createLiveTvChannelsScreen(m)
		screenName = "LiveTVChannels"

    else if contentType = "LiveTVRecordings" then
		screen = createLiveTvRecordingsScreen(m)
		screenName = "LiveTVRecordings"

    else if contentType = "MusicLibrary" then
		screen = createMusicLibraryScreen(m)
		screenName = "MusicLibrary"

    else if contentType = "MusicArtist" then
		screen = createMusicAlbumsScreen(m, item)
        screenName = "MusicArtist " + itemId

    else if contentType = "MusicAlbum" then
		screen = createMusicSongsScreen(m, item)
        screenName = "MusicAlbum " + itemId
		
    else if contentType = "MusicAlbumAlphabet" then
		screen = createMusicAlbumsAlphabetScreen(m, itemId)
		screenName = "MusicAlbumAlphabet " + itemId

    else if contentType = "MusicArtistAlphabet" then
		screen = createMusicArtistsAlphabetScreen(m, itemId)
		screenName = "MusicArtistAlphabet " + itemId

    else if contentType = "MediaFolder" or contentType = "PhotoFolder" or contentType = "Folder" or contentType = "BoxSet" or item.IsFolder = true then
		screen = createFolderScreen(m, item)
		screenName = "Folder " + itemId

    else if item.MediaType = "Photo" then
		ShowPhotoPage(m, itemId)

    else if contentType = "RecordingGroup" then
		screen = createLiveTvRecordingGroupsScreen(m, item)
		screenName = "RecordingGroup " + itemId

    else if item.key = "nowplaying" or contentType = "NowPlaying" then
        if AudioPlayer().ContextScreenID = m.screens.Peek().ScreenID then
            screen = invalid
        else
            AudioPlayer().ContextScreenID = m.nextScreenId
            screen = createAudioSpringboardScreen(AudioPlayer().Context, AudioPlayer().CurIndex, m)
            screenName = "Now Playing"
        end if
        if screen = invalid then return invalid
    else if item.MediaType = "Audio" then
        screen = createAudioSpringboardScreen(context, contextIndex, m)
        if screen = invalid then return invalid
        screenName = "Audio Springboard"
    else if contentType = "keyboard" then
        screen = createKeyboardScreen(m, item)
        screenName = "Keyboard"
    else if contentType = "search" then
        screen = createSearchScreen(item, m)
        screenName = "Search"
    else if item.searchTerm <> invalid then

        screen = createSearchResultsScreen(m, item.searchTerm)
        screenName = "Search Results"

    else if item.settings = "1"
        screen = createSettingsScreen(item, m)
        screenName = "Settings"

	else
		Debug ("Encountered unknown type in CreateScreenForItem")
    end if

	if screen <> invalid then
		if screenName = invalid then
			screenName = type(screen.Screen) + " " + firstOf(contentType, "unknown")
		end if

		screen.ScreenName = screenName

		m.AddBreadcrumbs(screen, breadcrumbs)
		m.UpdateScreenProperties(screen)
		m.PushScreen(screen)

		if show then screen.Show()

		return screen
	end If

	return invalid

End Function

Function vcCreateTextInputScreen(title, heading, breadcrumbs, initialValue="", secure=false) As Dynamic
    screen = createKeyboardScreen(m, invalid, title, heading, initialValue, secure)
    screen.ScreenName = "Keyboard: " + tostr(heading)

    m.AddBreadcrumbs(screen, breadcrumbs)
    m.UpdateScreenProperties(screen)
    m.PushScreen(screen)

    return screen
End Function

Function vcCreateEnumInputScreen(options, selected, heading, breadcrumbs, show=true) As Dynamic
    screen = createEnumScreen(options, selected, m)
    screen.ScreenName = "Enum: " + tostr(heading)

    if heading <> invalid then
        screen.Screen.SetHeader(heading)
    end if

    m.AddBreadcrumbs(screen, breadcrumbs)
    m.UpdateScreenProperties(screen)
    m.PushScreen(screen)

    if show then screen.Show()

    return screen
End Function

Function vcCreateContextMenu()

	screen = m.screens.Peek()

	menuShown = screen.createContextMenu()

	if menuShown = false then
		' Our context menu is only relevant if the audio player has content.
		if AudioPlayer().ContextScreenID = invalid then return invalid

		return AudioPlayer().ShowContextMenu()
	end If

End Function

Function vcCreatePhotoPlayer(context, contextIndex=invalid, show=true, shuffled=false)
    
	screen = createPhotoPlayerScreen(context, contextIndex, m, shuffled)
    screen.ScreenName = "Photo Player"

    m.AddBreadcrumbs(screen, invalid)
    m.UpdateScreenProperties(screen)
    m.PushScreen(screen)

    if show then screen.Show()

    return screen
End Function

Function vcCreateVideoPlayer(context, contextIndex, playOptions, show=true)
    
	' Stop any background audio first
    AudioPlayer().Stop()

    screen = createVideoPlayerScreen(context, contextIndex, playOptions, m)
    screen.ScreenName = "Video Player"

    m.AddBreadcrumbs(screen, invalid)
	m.UpdateScreenProperties(screen)
    m.PushScreen(screen)

    if show then screen.Show()

    return screen
End Function

Function vcCreatePlayerForItem(context, contextIndex, playOptions)
    item = context[contextIndex]

    if item.MediaType = "Photo" then
        return m.CreatePhotoPlayer(context, contextIndex)
    else if item.MediaType = "Audio" then
        AudioPlayer().Stop()
        return m.CreateScreenForItem(context, contextIndex, invalid)
    else if item.MediaType = "Video" then
	
		return m.CreateVideoPlayer(context, contextIndex, playOptions)
    else
        Debug("Not sure how to play item of type " + tostr(item.ContentType))
        return m.CreateScreenForItem(context, contextIndex, invalid)
    end if
End Function

Function vcIsVideoPlaying() As Boolean
    return VideoPlayer() <> invalid
End Function


Sub vcCancelRequests(screenID)
    requests = m.RequestsByScreen[screenID.tostr()]
    if requests <> invalid then
        for each requestID in requests
            request = m.PendingRequests[requestID]
            if request <> invalid then request.Request.AsyncCancel()
            m.PendingRequests.Delete(requestID)
        next
        m.RequestsByScreen.Delete(screenID.tostr())
    end if
End Sub

Sub vcCloseScreenWithCallback(callback)
    m.afterCloseCallback = callback
    m.screens.Peek().Screen.Close()
End Sub

Sub vcCloseScreen(simulateRemote)
    ' Unless the visible screen is the home screen.
    if m.Home <> invalid AND NOT m.IsActiveScreen(m.Home) then
        ' Our one complication is the screensaver, which we can't know anything
        ' about. So if we're simulating the remote control and haven't been
        ' called in a while, send an ECP back. Otherwise, directly close our
        ' top screen.
        if m.backButtonTimer.IsExpired() then
            SendEcpCommand("Back")
        else
            m.screens.Peek().Screen.Close()
        end if
    end if
End Sub

Sub vcAddBreadcrumbs(screen, breadcrumbs)
    ' Add the breadcrumbs to our list and set them for the current screen.
    ' If the current screen specified invalid for the breadcrubms then it
    ' doesn't want any breadcrumbs to be shown. If it specified an empty
    ' array, then the current breadcrumbs will be shown again.
    screenType = type(screen.Screen)
    if breadcrumbs = invalid then
        screen.NumBreadcrumbs = 0
        return
    end if

    ' Special case for springboard screens, don't show the current title
    ' in the breadcrumbs.
    if screenType = "roSpringboardScreen" AND breadcrumbs.Count() > 0 then
        breadcrumbs.Pop()
    end if

    if breadcrumbs.Count() = 0 AND m.breadcrumbs.Count() > 0 then
        count = m.breadcrumbs.Count()
        if count >= 2 then
            breadcrumbs = [m.breadcrumbs[count-2], m.breadcrumbs[count-1]]
        else
            breadcrumbs = m.breadcrumbs[0]
        end if

        m.breadcrumbs.Append(breadcrumbs)
        screen.NumBreadcrumbs = breadcrumbs.Count()
    else
        for each b in breadcrumbs
            m.breadcrumbs.Push(tostr(b))
        next
        screen.NumBreadcrumbs = breadcrumbs.Count()
    end if
End Sub

Sub vcUpdateScreenProperties(screen)

    if screen.NumBreadcrumbs <> 0 then
        count = m.breadcrumbs.Count()
        if count >= 2 then
            enableBreadcrumbs = true
            bread1 = m.breadcrumbs[count-2]
            bread2 = m.breadcrumbs[count-1]
        else if count = 1 then
            enableBreadcrumbs = true
            bread1 = ""
            bread2 = m.breadcrumbs[0]
        else
            enableBreadcrumbs = false
        end if
    else
        enableBreadcrumbs = false
    end if

    screenType = type(screen.Screen)
    ' Different screen types don't support breadcrumbs with the same functions
    if screenType = "roGridScreen" OR screenType = "roPosterScreen" OR screenType = "roSpringboardScreen" then
        if enableBreadcrumbs then
            screen.Screen.SetBreadcrumbEnabled(true)
            screen.Screen.SetBreadcrumbText(bread1, bread2)
        else
            screen.Screen.SetBreadcrumbEnabled(false)
        end if
    else if screenType = "roSearchScreen" then
        if enableBreadcrumbs then
            screen.Screen.SetBreadcrumbText(bread1, bread2)
        end if
    else if screenType = "roListScreen" then
        if enableBreadcrumbs then
			screen.Screen.SetBreadcrumbText(bread1, bread2)
		else
            screen.Screen.SetTitle(bread2)
        end if
    else if screenType = "roListScreen" OR screenType = "roKeyboardScreen" OR screenType = "roParagraphScreen" then
        if enableBreadcrumbs then
            screen.Screen.SetTitle(bread2)
        end if
    else
        Debug("Not sure what to do with breadcrumbs on screen type: " + tostr(screenType))
    end if
End Sub

Sub vcAddTimer(timer, listener)
    timer.ID = m.nextTimerId.tostr()
    m.nextTimerId = m.NextTimerId + 1
    timer.Listener = listener
    m.Timers[timer.ID] = timer

    screenID = listener.ScreenID.tostr()
    if NOT m.TimersByScreen.DoesExist(screenID) then
        m.TimersByScreen[screenID] = []
    end if
    m.TimersByScreen[screenID].Push(timer.ID)
End Sub

Sub CloseScreenUntilHomeVisible()
    vc = GetViewController()

    if vc.Home = invalid OR NOT vc.IsActiveScreen(vc.Home) then
        vc.CloseScreenWithCallback(m)
    end if
End Sub

Sub vcDestroyGlitchyScreens()
    ' The audio player / grid screen glitch only affects older firmware versions.
    versionArr = getGlobalVar("rokuVersion")
    if versionArr[0] >= 4 then return

    for each screen in m.screens
        if screen.DestroyAndRecreate <> invalid then
            Debug("Destroying screen " + tostr(screen.ScreenID) + " to work around glitch")
            screen.DestroyAndRecreate()
        end if
    next
End Sub