'********************************************************************
'**  Media Browser Roku Client - Main
'********************************************************************

Sub Main()

    'Initialize theme
    initTheme()

    'Create facade screen
    facade = CreateObject("roParagraphScreen")
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
'** Setup the theme for the application
'*************************************************************

Sub initTheme()
    app = CreateObject("roAppManager")
    
    listItemHighlight           = "#ffffff"
    listItemText                = "#707070"
    brandingWhite               = "#eeeeee"
    backgroundColor             = "#504B4B"
    breadcrumbText              = "#eeeeee"

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
        GridScreenDescriptionTitleColor: brandingWhite
        GridScreenDescriptionDateColor: brandingWhite
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
        'GridScreenDescriptionImageHD: "pkg:/images/grid/Grid_Description_Background_Portrait_HD.png"
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
