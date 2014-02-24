'********************************************************************
'**  Media Browser Roku Client - Main
'********************************************************************

Sub Main()

    'Initialize theme
    initTheme()

    'Initialize globals
    initGlobals()

    'Create facade screen
    facade = CreateObject("roPosterScreen")
    facade.Show()

    ' Goto Marker
    serverStartupMarker:

    ' Server Start Up
    serverStart = serverStartUp()

    '** 0 = First Run, 1 = Server List, 2 = Connect to Server
    if serverStart = 0
        Print "Server Setup"
        savedServer = createServerFirstRunSetupScreen()

        If Not savedServer
            ' Exit Application
            return
        end if

        ' Redo Server Startup
        Goto serverStartupMarker

    else if serverStart = 1
        Print "Server List"
        selectedServer = createServerListScreen()

        if selectedServer = -1
            ' Exit Application
            return
        else if selectedServer = 0
            ' Redo Server Startup
            Goto serverStartupMarker
        end if

        RegWrite("serverActive", itostr(selectedServer))

        ' Redo Server Startup
        Goto serverStartupMarker

    else if serverStart = 2
        Print "Connecting To Server"

    end if

    ' Setup Web Server
    'initWebServer()

    ' Goto Marker
    serverProfileMarker:

    ' Check to see if they have already selected a User
    ' Show home page if so, otherwise show login page.
    if RegRead("userId") <> invalid And RegRead("userId") <> ""
        userProfile = getUserProfile(RegRead("userId"))

        ' If unable to get user profile, delete saved user and redirect to login
        if userProfile = invalid
            RegDelete("userId")
            Goto serverProfileMarker
        end if
        
        GetGlobalAA().AddReplace("user", userProfile)


        '''''''''''''''''''''''''''''''''''''''''''''''''
        ' Comment Out For now
        'controller = createController()
        'controller.startUp()
        'controller.eventLoop()
        '''''''''''''''''''''''''''''''''''''''''''''''''

        homeResult = ShowHomePage()
        if homeResult = true
            ' Retry Login Check
            Goto serverProfileMarker
        end if

        'Print "exit"
    else
        loginResult = ShowLoginPage()
        if loginResult = 1
            ' Go back to selected user
            Goto serverProfileMarker
        else if loginResult = 2
            ' Remove active server and go back to selection screen
            RegDelete("serverActive")
            Goto serverStartupMarker
        end if
    end if

    ' Exit Application
    return

End Sub


'*************************************************************
'** Setup Global variables for the application
'*************************************************************

Sub initGlobals()
    device = CreateObject("roDeviceInfo")

    ' Get device software version
    version = device.GetVersion()
    major = Mid(version, 3, 1).toInt()
    minor = Mid(version, 5, 2).toInt()
    build = Mid(version, 8, 5).toInt()
    versionStr = major.toStr() + "." + minor.toStr() + " build " + build.toStr()

    GetGlobalAA().AddReplace("rokuVersion", [major, minor, build])

    ' Get channel version
    manifest = ReadAsciiFile("pkg:/manifest")
    lines = manifest.Tokenize(chr(10))

    For each line In lines
        entry = line.Tokenize("=")

        If entry[0]="version" Then
            GetGlobalAA().AddReplace("channelVersion", entry[1])
            Exit For
        End If
    End For

    GetGlobalAA().AddReplace("rokuUniqueId", device.GetDeviceUniqueId())

    ' Get model name and audio output 
    If major > 4 Or (major = 4 And minor >= 8) Then
        modelName   = device.GetModelDisplayName()
        modelNumber = device.GetModel()

        ' Set Audio Output
        if device.GetAudioOutputChannel() = "5.1 surround"
            GetGlobalAA().AddReplace("audioOutput51", true)
        else
            GetGlobalAA().AddReplace("audioOutput51", false)
        end if
    Else
        modelNumber = device.GetModel()
        GetGlobalAA().AddReplace("audioOutput51", false)

        models = {}
        models["N1050"] = "Roku SD"
        models["N1000"] = "Roku HD Classic"
        models["N1100"] = "Roku HD Classic"
        models["2050X"] = "Roku XD"
        models["2050N"] = "Roku XD"
        models["N1101"] = "Roku XD|S Classic"
        models["2100X"] = "Roku XD|S"
        models["2100N"] = "Roku XD|S"
        models["2000C"] = "Roku HD"
        models["2500X"] = "Roku HD"
        models["2400X"] = "Roku LT"
        models["2450X"] = "Roku LT"
        models["2400SK"] = "Now TV"
        models["3000X"] = "Roku 2 HD"
        models["3050X"] = "Roku 2 XD"
        models["3100X"] = "Roku 2 XS"
        models["3400X"] = "Roku Streaming Stick"
        models["3420X"] = "Roku Streaming Stick"
        models["4200X"] = "Roku 3"

        If models.DoesExist(modelNumber) Then
            modelName = models[modelNumber]
        Else
            modelName = modelNumber
        End If
    End If

    GetGlobalAA().AddReplace("rokuModelNumber", modelNumber)
    GetGlobalAA().AddReplace("rokuModelName", modelName)

    ' Check for DTS passthrough support
    if modelNumber = "4200X"
        GetGlobalAA().AddReplace("audioDTS", true)
    else
        GetGlobalAA().AddReplace("audioDTS", false)
    end if

    ' Assume everything below major version of 4.0 To be a legacy device
    if major < 4
        GetGlobalAA().AddReplace("legacyDevice", true)
    else
        GetGlobalAA().AddReplace("legacyDevice", false)
    end if

    ' Check if HDTV screen
    If device.GetDisplayType() = "HDTV" Then
        GetGlobalAA().AddReplace("isHD", true)
    Else
        GetGlobalAA().AddReplace("isHD", false)
    End If

    ' Check to see if the box can support surround sound
    surroundSound = device.HasFeature("5.1_surround_sound")
    GetGlobalAA().AddReplace("surroundSound", surroundSound)

    ' Get display information
    GetGlobalAA().AddReplace("displaySize", device.GetDisplaySize())
    GetGlobalAA().AddReplace("displayMode", device.GetDisplayMode())
    GetGlobalAA().AddReplace("displayType", device.GetDisplayType())

End Sub


'*************************************************************
'** Get a variable from the Global Array
'*************************************************************

Function getGlobalVar(name, default=invalid)
    Return firstOf(GetGlobalAA().Lookup(name), default)
End Function


'*************************************************************
'** Setup the theme for the application
'*************************************************************

Sub initTheme()
    app = CreateObject("roAppManager")
    theme = CreateObject("roAssociativeArray")
    
    brandingWhite   = "#eeeeee"
    backgroundColor = "#504B4B"

    textColorWhite = "#ffffff"
    textColorBlack = "#000000"
    
    rfTheme = RegRead("prefTheme")
    if rfTheme = "dark" then 
        GetGlobalAA().AddReplace("rf_theme_dir", "file://pkg:/images/dark/")
        GetGlobalAA().AddReplace("rfBGcolor", "0F0F0F")
    else 
        GetGlobalAA().AddReplace("rf_theme_dir", "file://pkg:/images/")
        GetGlobalAA().AddReplace("rfBGcolor", "504B4B")
    end if
    imageDir = GetGlobalAA().Lookup("rf_theme_dir")
    
    background = "#" + GetGlobalAA().Lookup("rfBGcolor")
    titleText = "#BFBFBF"
    normalText = "#999999"
    detailText = "#74777A"
    subtleText = "#525252"
    
    

        '*** HD Styles ****
        theme.OverhangSliceHD = imageDir + "overhang/hd-header-slice.png"
        theme.OverhangLogoHD =  "pkg:/images/overhang/hd-logo.png"
        theme.OverhangOffsetHD_X =  "80"
        theme.OverhangOffsetHD_Y =  "30"

        theme.FilterBannerSliceHD =  imageDir + "overhang/hd-filter-banner.png"
        theme.FilterBannerActiveHD =  imageDir + "overhang/hd-filter-active.png"
        theme.FilterBannerInactiveHD =  imageDir + "overhang/hd-filter-inactive.png"

        theme.GridScreenLogoHD =  "pkg:/images/overhang/hd-logo.png"
        theme.GridScreenOverhangSliceHD =  imageDir + "overhang/hd-header-slice.png"
        theme.GridScreenLogoOffsetHD_X =  "80"
        theme.GridScreenLogoOffsetHD_Y =  "30"
        theme.GridScreenOverhangHeightHD =  "124"
        theme.GridScreenFocusBorderHD =  imageDir + "grid/hd-border-flat-landscape.png"
        theme.GridScreenBorderOffsetHD =  "(-34,-19)"
        theme.GridScreenDescriptionImageHD =  "pkg:/images/grid/hd-description-background.png"
        'theme.GridScreenDescriptionOffsetHD = "(150,205)"

        theme.ListItemHighlightHD =  imageDir + "hd-list-item.png"


        '*** SD Styles ****

        theme.OverhangSliceSD =  "pkg:/images/overhang/sd-header-slice.png"
        theme.OverhangLogoSD =  "pkg:/images/overhang/sd-logo.png"
        theme.OverhangOffsetSD_X =  "20"
        theme.OverhangOffsetSD_Y =  "20"

        theme.FilterBannerSliceSD =  "pkg:/images/overhang/sd-filter-banner.png"
        theme.FilterBannerActiveSD =  "pkg:/images/overhang/sd-filter-active.png"
        theme.FilterBannerInactiveSD =  "pkg:/images/overhang/sd-filter-inactive.png"

        theme.GridScreenLogoSD =  "pkg:/images/overhang/sd-logo.png"
        theme.GridScreenOverhangSliceSD =  "pkg:/images/overhang/sd-header-slice.png"
        theme.GridScreenLogoOffsetSD_X =  "20"
        theme.GridScreenLogoOffsetSD_Y =  "20"
        theme.GridScreenOverhangHeightSD =  "83"

        'theme.ListItemHighlightSD =  "pkg:/images/sd-list-item.png"


        '*** Common Styles ****

        theme.BackgroundColor =  background

        theme.BreadcrumbTextLeft =  normaltext
        theme.BreadcrumbTextRight =  titletext
        theme.BreadcrumbDelimiter =  titletext

        theme.ParagraphHeaderText =  titletext
        theme.ParagraphBodyText =  normaltext
        
        if rfTheme = "dark" then 
          theme.ThemeType = "generic-dark"
          theme.DialogTitleText="#000000" ' header should be bold and black
          theme.DialogBodyText="#222222"  ' text should not be too light or to dark
          theme.ButtonNormalColor = "#333333" 'normalText
        else
          theme.DialogTitleText="#000000" ' header should be bold and black
          theme.DialogBodyText="#222222"  ' text should not be too light or to dark
          theme.ButtonNormalColor = normalText
        end if

        if rfTheme = "dark" then 
          theme.TextScreenBodyText = "#f0f0f0"
          theme.TextScreenBodyBackgroundColor = "#111111"
          theme.TextScreenScrollBarColor = "#a0a0a0"
          theme.TextScreenScrollThumbColor = "#f0f0f0"
        else 
          theme.TextScreenBodyText = "#f0f0f0"
          theme.TextScreenBodyBackgroundColor = "#111111"
          theme.TextScreenScrollBarColor = "#a0a0a0"
          theme.TextScreenScrollThumbColor = "#f0f0f0"
        end if
    
    
        theme.PosterScreenLine1Text =  titletext
        theme.PosterScreenLine2Text =  normaltext
        theme.EpisodeSynopsisText =  normaltext

        theme.ListItemText =  normaltext
        theme.ListItemHighlightText =  titletext
        theme.ListScreenDescriptionText =  normaltext
        theme.ListScreenTitleColor =  titletext
        theme.ListScreenHeaderText =  titletext

        theme.CounterTextLeft =  titletext
        theme.CounterTextRight =  normaltext
        theme.CounterSeparator =  normaltext

        theme.FilterBannerActiveColor =  titletext
        theme.FilterBannerInactiveColor =  subtletext
        theme.FilterBannerSideColor =  subtletext

        theme.GridScreenBackgroundColor =  background
        theme.GridScreenRetrievingColor =  subtleText
        theme.GridScreenListNameColor =  titletext
        theme.GridScreenDescriptionTitleColor =  titletext
        theme.GridScreenDescriptionDateColor =  titletext

        theme.SpringboardActorColor =  titletext

        theme.SpringboardAlbumColor =  titletext
        theme.SpringboardAlbumLabel =  titletext
        theme.SpringboardAlbumLabelColor =  detailtext

        'theme.SpringboardAllow6Buttons =  false

        theme.SpringboardArtistColor =  titletext
        theme.SpringboardArtistLabel =  titletext
        theme.SpringboardArtistLabelColor =  detailtext

        theme.SpringboardDirectorColor =  titletext
        theme.SpringboardDirectorLabel =  detailtext
        theme.SpringboardDirectorLabelColor =  titletext
        theme.SpringboardDirectorPrefixText =  titletext

        theme.SpringboardGenreColor =  normaltext
        theme.SpringboardRuntimeColor =  normaltext
        theme.SpringboardSynopsisColor =  normaltext
        theme.SpringboardTitleText =  titletext
    

    app.SetTheme( theme )
End Sub


Sub initWebServer()
    ' Initialize the web server
    globals = CreateObject("roAssociativeArray")
    globals.pkgname  = "Media Browser"
    globals.maxRequestLength = 4000
    globals.idletime = 60
    globals.wwwroot = "tmp:/"
    globals.index_name = "index.html"
    globals.serverName = "Media Browser"
    AddGlobals(globals)
    MimeType()
    HttpTitle()
    ClassReply().AddHandler("/logs", ProcessLogsRequest)

    webServer = InitServer({port: 8324})
End Sub

Function ProcessLogsRequest() As Boolean
    Print "logs"
    Return true
End Function