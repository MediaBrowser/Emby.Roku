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
    checkServerStatus:

    dialogBox = ShowPleaseWait("Please Wait...", "Connecting To MediaBrowser 3 Server")

    'Get MediaBrowser Server
    status = GetServerStatus()

    ' Check If Server Ping Failed
    If status = 0 Then
        dialogBox.Close()
        dialogBox = ShowPleaseWait("Please Wait...", "Could Not Find Server. Attempting Auto-Discovery")

        ' Refresh Server Call
        status = GetServerStatus(true)
    End If
    
    ' Check If Ping And Automated Discovery Failed
    If status = -1 Then
        dialogBox.Close()

        ' Server Not found even after refresh, Give Option To Type In IP Or Try again later
        buttonPress = ShowConnectionFailed()

        If buttonPress=0 Then
            Return
        Else
            savedConf = ShowManualServerConfiguration()
            If savedConf = 1 Then
                ' Retry Connection with manual entries
                Goto checkServerStatus
            Else
                ' Exit Application
                Return
            End if
        End If
    End if

    'Close Dialog Box
    dialogBox.Close()

    ' Goto Marker
    checkLoginStatus:

    ' Check to see if they have already selected a User
    ' Show home page if so, otherwise show login page.
    If RegRead("userId")<>invalid And RegRead("userId")<>""
        m.curUserProfile = GetUserProfile(RegRead("userId"))
        GetGlobalAA().AddReplace("user", m.curUserProfile) ' Will replace curUserProfile
        homeResult = ShowHomePage()
        If homeResult = true Then
            ' Retry Login Check
            Goto checkLoginStatus
        End If
    Else
        loginResult = ShowLoginPage()
        If loginResult = true Then
            ' Retry Login Check
            Goto checkLoginStatus
        End If
    End If

    ' Exit Application
    Return

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

    ' Get model name
    If major > 4 Or (major = 4 And minor >= 8) Then
        modelName   = device.GetModelDisplayName()
        modelNumber = device.GetModel()
    Else
        modelNumber = device.GetModel()

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
        GridScreenFocusBorderSD: "pkg:/images/grid/sd-border-flat-landscape.png"
        GridScreenBorderOffsetSD: "(-34,-19)"
        GridScreenDescriptionImageSD: "pkg:/images/grid/sd-description-background.png"
        'GridScreenDescriptionOffsetSD:"(125,170)"

        ListItemHighlightSD: "pkg:/images/sd-list-item.png"


        '*** Common Styles ****

        BackgroundColor: backgroundColor

        BreadcrumbTextLeft: "#dfdfdf"
        BreadcrumbTextRight: "#eeeeee"
        BreadcrumbDelimiter: "#eeeeee"
        
        PosterScreenLine1Text: "#ffffff"

        ListItemText: "#dfdfdf"
        ListItemHighlightText: "#ffffff"
        ListScreenDescriptionText: "#9a9a9a"
        ListScreenTitleColor: "#000000"

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
    }

    app.SetTheme( theme )
End Sub
