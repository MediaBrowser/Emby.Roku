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
        homeResult = ShowHomePage()
        if homeResult = true
            ' Retry Login Check
            Goto serverProfileMarker
        end if

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
    if modelName = "Roku 3"
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
    
    brandingWhite   = "#eeeeee"
    backgroundColor = "#504B4B"

    textColorWhite = "#ffffff"
    textColorBlack = "#000000"

    theme = {

        '*** HD Styles ****
        OverhangSliceHD: "pkg:/images/overhang/hd-header-slice.png"
        OverhangLogoHD: "pkg:/images/overhang/hd-logo.png"
        OverhangOffsetHD_X: "80"
        OverhangOffsetHD_Y: "30"

        FilterBannerSliceHD: "pkg:/images/overhang/hd-filter-banner.png"
        FilterBannerActiveHD: "pkg:/images/overhang/hd-filter-active.png"
        FilterBannerInactiveHD: "pkg:/images/overhang/hd-filter-inactive.png"

        GridScreenLogoHD: "pkg:/images/overhang/hd-logo.png"
        GridScreenOverhangSliceHD: "pkg:/images/overhang/hd-header-slice.png"
        GridScreenLogoOffsetHD_X: "80"
        GridScreenLogoOffsetHD_Y: "30"
        GridScreenOverhangHeightHD: "124"
        GridScreenFocusBorderHD: "pkg:/images/grid/hd-border-flat-landscape.png"
        GridScreenBorderOffsetHD: "(-34,-19)"
        GridScreenDescriptionImageHD: "pkg:/images/grid/hd-description-background.png"
        'GridScreenDescriptionOffsetHD:"(150,205)"

        ListItemHighlightHD: "pkg:/images/hd-list-item.png"


        '*** SD Styles ****

        OverhangSliceSD: "pkg:/images/overhang/sd-header-slice.png"
        OverhangLogoSD: "pkg:/images/overhang/sd-logo.png"
        OverhangOffsetSD_X: "20"
        OverhangOffsetSD_Y: "20"

        FilterBannerSliceSD: "pkg:/images/overhang/sd-filter-banner.png"
        FilterBannerActiveSD: "pkg:/images/overhang/sd-filter-active.png"
        FilterBannerInactiveSD: "pkg:/images/overhang/sd-filter-inactive.png"

        GridScreenLogoSD: "pkg:/images/overhang/sd-logo.png"
        GridScreenOverhangSliceSD: "pkg:/images/overhang/sd-header-slice.png"
        GridScreenLogoOffsetSD_X: "20"
        GridScreenLogoOffsetSD_Y: "20"
        GridScreenOverhangHeightSD: "83"

        'ListItemHighlightSD: "pkg:/images/sd-list-item.png"


        '*** Common Styles ****

        BackgroundColor: backgroundColor

        BreadcrumbTextLeft: "#dfdfdf"
        BreadcrumbTextRight: "#eeeeee"
        BreadcrumbDelimiter: "#eeeeee"

        ParagraphHeaderText: "#ffffff"
        ParagraphBodyText: "#dfdfdf"

        PosterScreenLine1Text: "#ffffff"
        PosterScreenLine2Text: "#9a9a9a"
        EpisodeSynopsisText: "#dfdfdf"

        ListItemText: "#dfdfdf"
        ListItemHighlightText: "#ffffff"
        ListScreenDescriptionText: "#9a9a9a"
        ListScreenTitleColor: "#ffffff"
        ListScreenHeaderText: "#ffffff"

        CounterTextLeft: brandingWhite
        CounterTextRight: brandingWhite
        CounterSeparator: brandingWhite

        FilterBannerActiveColor: "#ffffff"
        FilterBannerInactiveColor: "#cccccc"
        FilterBannerSideColor: "#cccccc"

        GridScreenBackgroundColor: backgroundColor
        GridScreenListNameColor: brandingWhite
        GridScreenDescriptionTitleColor: "#1E1E1E"
        GridScreenDescriptionDateColor: "#1E1E1E"

        SpringboardActorColor: "#9a9a9a"

        SpringboardAlbumColor: "#ffffff"
        SpringboardAlbumLabel: "#ffffff"
        SpringboardAlbumLabelColor: "#ffffff"

        'SpringboardAllow6Buttons: false

        SpringboardArtistColor: "#ffffff"
        SpringboardArtistLabel: "#ffffff"
        SpringboardArtistLabelColor: "#ffffff"

        SpringboardDirectorColor: "#ffffff"
        SpringboardDirectorLabel: "#ffffff"
        SpringboardDirectorLabelColor: "#ffffff"
        SpringboardDirectorPrefixText: "#ffffff"

        SpringboardGenreColor: "#ffffff"
        SpringboardRuntimeColor: "#ffffff"
        SpringboardSynopsisColor: "#dfdfdf"
        SpringboardTitleText: "#ffffff"

        'ThemeType: "generic-dark"
    }

    app.SetTheme( theme )
End Sub
