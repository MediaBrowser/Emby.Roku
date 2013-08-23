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

Function getGlobalVar(name, default)
    Return firstOf(GetGlobalAA().Lookup(name), default)
End Function


'*************************************************************
'** Setup the theme for the application
'*************************************************************

Sub initTheme()
    app = CreateObject("roAppManager")
    
    listItemHighlight           = "#ffffff"
    listItemText                = "#707070"
    brandingWhite               = "#eeeeee"
    backgroundColor             = "#504B4B"
    breadcrumbText              = "#eeeeee"

    textColorWhite = "#ffffff"
    textColorBlack = "#000000"

    theme = {
        BackgroundColor: backgroundColor

        OverhangSliceHD: "pkg:/images/Overhang_Background_HD.png"
        OverhangSliceSD: "pkg:/images/Overhang_Background_SD.png"
        OverhangLogoHD: "pkg:/images/mblogowhite.png"
        OverhangLogoSD: "pkg:/images/mblogowhite.png"
        OverhangOffsetSD_X: "35"
        OverhangOffsetSD_Y: "35"
        OverhangOffsetHD_X: "35"
        OverhangOffsetHD_Y: "35"

        BreadcrumbTextLeft: breadcrumbText
        BreadcrumbTextRight: breadcrumbText
        BreadcrumbDelimiter: breadcrumbText
        
        PosterScreenLine1Text: "#ffffff"

        ListItemText: listItemText
        ListItemHighlightText: listItemHighlight
        ListScreenDescriptionText: listItemText
        ListItemHighlightHD: "pkg:/images/select_bkgnd.png"
        ListItemHighlightSD: "pkg:/images/select_bkgnd.png"

        CounterTextLeft: brandingWhite
        CounterTextRight: brandingWhite
        CounterSeparator: brandingWhite

        GridScreenBackgroundColor: backgroundColor
        GridScreenListNameColor: brandingWhite
        GridScreenDescriptionTitleColor: "#1E1E1E"
        GridScreenDescriptionDateColor: "#1E1E1E"
        GridScreenLogoHD: "pkg:/images/mblogowhite.png"
        GridScreenLogoSD: "pkg:/images/mblogowhite.png"
        GridScreenOverhangHeightHD: "124"
        GridScreenOverhangHeightSD: "83"
        GridScreenOverhangSliceHD: "pkg:/images/Overhang_Background_HD.png"
        GridScreenOverhangSliceSD: "pkg:/images/Overhang_Background_SD.png"
        GridScreenLogoOffsetHD_X: "35"
        GridScreenLogoOffsetHD_Y: "35"
        GridScreenLogoOffsetSD_X: "35"
        GridScreenLogoOffsetSD_Y: "35"

        'GridScreenFocusBorderSD: "pkg:/images/grid/GridCenter_Border_Movies_SD43.png"
        'GridScreenBorderOffsetSD: "(-26,-25)"
        'GridScreenFocusBorderHD: "pkg:/images/grid/GridCenter_Border_Movies_HD2.png"
        'GridScreenBorderOffsetHD: "(-15,-15)"

        'GridScreenDescriptionImageSD: "pkg:/images/grid/Grid_Description_Background_Portrait_SD43.png"
        'GridScreenDescriptionOffsetSD:"(125,170)"
        GridScreenDescriptionImageHD: "pkg:/images/grid/Grid_Description_Background_16x9_HD.png"
        'GridScreenDescriptionOffsetHD:"(150,205)"

        SpringboardActorColor: "#ffffff"

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
        SpringboardSynopsisColor: "#ffffff"
        SpringboardTitleText: "#ffffff"
    }

    app.SetTheme( theme )
End Sub
