'*****************************************************************
'**  Media Browser Roku Client - Preferences Page
'*****************************************************************


'**********************************************************
'** Show Preferences Page
'**********************************************************

Function ShowPreferencesPage()

    ' Create List Screen
    screen = CreateListScreen("", "Preferences")

    ' Get Preference Functions
    preferenceFunctions = [
        GetPreferenceVideoQuality,
        GetPreferenceMovieImageType,
        GetPreferenceMovieTitle,
        GetPreferenceMovieDisplayPopup,
        GetPreferenceTVImageType,
        GetPreferenceTVTitle,
        GetPreferenceTVDisplayPopup,
        GetPreferenceTVThemeMusic,
        GetPreferenceTVThemeMusicRepeat,
        GetPreferenceCollectionView,
        GetPreferenceCollectionTitle,
        GetPreferenceCollectionPopup,
        GetPreferenceCollectionsFirstRow,
        GetPreferenceEnhancedImages,
        GetPreferenceMediaIndicators,
        GetPreferenceTheme,
        GetPreferenceServerUpdates
    ]

    ' Fetch / Refresh Preference Screen
    preferenceList = RefreshPreferencesPage(screen)

    while true
        msg = wait(0, screen.Port)

        If type(msg) = "roListScreenEvent" Then

            If msg.isListItemFocused() Then

            Else If msg.isListItemSelected() Then
                if preferenceList[msg.GetIndex()].ContentType = "exit"
                    Debug("Close prefs screen")
                    return false
                else
                    prefName    = preferenceList[msg.GetIndex()].Id
                    shortTitle  = preferenceList[msg.GetIndex()].ShortTitle
                    itemOptions = preferenceFunctions[msg.GetIndex()]()

                    ' Show Item Options Screen
                    ShowItemOptions(shortTitle, prefName, itemOptions)

                    ' Refresh Page
                    preferenceList = RefreshPreferencesPage(screen)

                    ' Refocus Item
                    screen.SetFocusedItem(msg.GetIndex())
                end if

            Else If msg.isScreenClosed() Then
                Debug("Close prefs screen")
                return false
            End If
        End If
    end while

    return false
End Function


'**********************************************************
'** Show Item Options
'**********************************************************

Function ShowItemOptions(title As String, itemId As String, list As Object)

    ' Create List Screen
    screen = CreateListScreen("", "Preferences")

    ' Back Button
    if getGlobalVar("legacyDevice")
        backButton = {
            Title: ">> Back to Preferences <<",
            ContentType: "exit",
        }

        list.Unshift( backButton )
    end if


    ' Set Content
    screen.SetHeader(title)
    screen.SetContent(list)

    ' Show Screen
    screen.Show()

    while true
        msg = wait(0, screen.Port)

        If type(msg) = "roListScreenEvent" Then

            If msg.isListItemFocused() Then

            Else If msg.isListItemSelected() Then
                prefSelected = list[msg.GetIndex()].Id
                if list[msg.GetIndex()].ContentType = "exit"
                    return false
                
                else if prefSelected = "manual" then
                    serverSaved = createServerConfigurationScreen("")
                    if serverSaved
                        Debug("Saved Server - Close Server Setup Screen")
                        return false
                    end if
                else if prefSelected = "discover" then
                    ' Create Waiting Dialog
                    dialog = createWaitingDialog("Please Wait...", "Please wait while we scan your network for a running media browser server.")

                    ' Scan Network
                    results = scanLocalNetwork()

                    ' Close Dialog
                    dialog.Close()

                    if results <> invalid
                        ' Show Found Server Screen
                        createServerFoundScreen(results)

                        ' Show Server Configuration Screen
                        serverSaved = createServerConfigurationScreen(results)
                        if serverSaved
                            Debug("Saved Server - Close Server Setup Screen")
                            return false
                        end if
                    else
                        createDialog("No Server Found", "We were unable to find a server running on your local network. Please make sure your server is running or if you continue to have problems, manually add the server.", "Back")
                    end if
                else
                    ' Save New Preference
                    RegWrite(itemId, prefSelected)

                    ' Close Screen
                    return false
                end if
                
                

            Else If msg.isScreenClosed() Then
                return false
            End If
        End If
    end while

    return false
End Function


'**********************************************************
'** Refresh Preferences Page
'**********************************************************

Function RefreshPreferencesPage(screen As Object) As Object

    ' Get Data
    preferenceList = GetPreferenceList()

    ' Show Screen
    screen.SetContent(preferenceList)
    screen.Show()

    return preferenceList
End Function


'**********************************************************
'** Get Selected Preference
'**********************************************************

Function GetSelectedPreference(list As Object, selected) as String

    if validateParam(list, "roArray", "GetSelectedPreference") = false return -1

    index = 0
    defaultIndex = 0

    For each itemData in list
        ' Find Default Index
        If itemData.IsDefault Then
            defaultIndex = index
        End If

        If itemData.Id = selected Then
            return itemData.Title
        End If

        index = index + 1
    End For

    ' Nothing selected, return default item
    return list[defaultIndex].Title
End Function


'**********************************************************
'** Get Main Preferences List
'**********************************************************

Function GetPreferenceList() as Object
    preferenceList = [
        {
            Title: "Video Quality: " + GetSelectedPreference(GetPreferenceVideoQuality(), RegRead("prefVideoQuality")),
            ShortTitle: "Video Quality",
            ID: "prefVideoQuality",
            ContentType: "pref",
            ShortDescriptionLine1: "Select the quality of the video streams",
            HDBackgroundImageUrl: "pkg://images/hd-preferences-lg.png",
            SDBackgroundImageUrl: "pkg://images/sd-preferences-lg.png"
        },
        {
            Title: "Movie Image Type: " + GetSelectedPreference(GetPreferenceMovieImageType(), RegRead("prefMovieImageType")),
            ShortTitle: "Movie Image Type",
            ID: "prefMovieImageType",
            ContentType: "pref",
            ShortDescriptionLine1: "Select from backdrop, poster, or thumb image",
            HDBackgroundImageUrl: "pkg://images/hd-preferences-lg.png",
            SDBackgroundImageUrl: "pkg://images/sd-preferences-lg.png"
        },
        {
            Title: "Movie Title: " + GetSelectedPreference(GetPreferenceMovieTitle(), RegRead("prefMovieTitle")),
            ShortTitle: "Movie Title",
            ID: "prefMovieTitle",
            ContentType: "pref",
            ShortDescriptionLine1: "Show or hide the movie title below the movie image.",
            HDBackgroundImageUrl: "pkg://images/hd-preferences-lg.png",
            SDBackgroundImageUrl: "pkg://images/sd-preferences-lg.png"
        },
        {
            Title: "Movies PopUp Bubble: " + GetSelectedPreference(GetPreferenceMovieDisplayPopup(), RegRead("prefMovieDisplayPopup")),
            ShortTitle: "Display PopUp Bubble for Movies",
            ID: "prefMovieDisplayPopup",
            ContentType: "pref",
            ShortDescriptionLine1: "Show Or Hide a PopUp bubble with extra information.",
            HDBackgroundImageUrl: "pkg://images/hd-preferences-lg.png",
            SDBackgroundImageUrl: "pkg://images/sd-preferences-lg.png"
        },
        {
            Title: "TV Series Image Type: " + GetSelectedPreference(GetPreferenceTVImageType(), RegRead("prefTVImageType")),
            ShortTitle: "TV Series Image Type",
            ID: "prefTVImageType",
            ContentType: "pref",
            ShortDescriptionLine1: "Select from backdrop, poster, or thumb image",
            HDBackgroundImageUrl: "pkg://images/hd-preferences-lg.png",
            SDBackgroundImageUrl: "pkg://images/sd-preferences-lg.png"
        },
        {
            Title: "TV Series Title: " + GetSelectedPreference(GetPreferenceTVTitle(), RegRead("prefTVTitle")),
            ShortTitle: "TV Series Title",
            ID: "prefTVTitle",
            ContentType: "pref",
            ShortDescriptionLine1: "Show or hide the tv series title below the tv series image.",
            HDBackgroundImageUrl: "pkg://images/hd-preferences-lg.png",
            SDBackgroundImageUrl: "pkg://images/sd-preferences-lg.png"
        },
        {
            Title: "TV PopUp Bubble: " + GetSelectedPreference(GetPreferenceTVDisplayPopup(), RegRead("prefTVDisplayPopup")),
            ShortTitle: "Display PopUp Bubble For TV",
            ID: "prefTVDisplayPopup",
            ContentType: "pref",
            ShortDescriptionLine1: "Show Or Hide a PopUp bubble with extra information.",
            HDBackgroundImageUrl: "pkg://images/hd-preferences-lg.png",
            SDBackgroundImageUrl: "pkg://images/sd-preferences-lg.png"
        },
        {
            Title: "Play TV Theme Music: " + GetSelectedPreference(GetPreferenceTVThemeMusic(), RegRead("prefTVMusic")),
            ShortTitle: "Play TV Theme Music",
            ID: "prefTVMusic",
            ContentType: "pref",
            ShortDescriptionLine1: "Play TV theme music while browsing a TV Series.",
            HDBackgroundImageUrl: "pkg://images/hd-preferences-lg.png",
            SDBackgroundImageUrl: "pkg://images/sd-preferences-lg.png"
        },
        {
            Title: "Repeat TV Theme Music: " + GetSelectedPreference(GetPreferenceTVThemeMusicRepeat(), RegRead("prefTVMusicLoop")),
            ShortTitle: "Repeat TV Theme Music",
            ID: "prefTVMusicLoop",
            ContentType: "pref",
            ShortDescriptionLine1: "Repeat TV theme music while browsing TV Series.",
            HDBackgroundImageUrl: "pkg://images/hd-preferences-lg.png",
            SDBackgroundImageUrl: "pkg://images/sd-preferences-lg.png"
        },
        {
            Title: "Collection View: " + GetSelectedPreference(GetPreferenceCollectionView(), RegRead("prefCollectionView")),
            ShortTitle: "Collection View",
            ID: "prefCollectionView",
            ContentType: "pref",
            ShortDescriptionLine1: "Select from backdrop, poster, or thumb image",
            HDBackgroundImageUrl: "pkg://images/hd-preferences-lg.png",
            SDBackgroundImageUrl: "pkg://images/sd-preferences-lg.png"
        },
        {
            Title: "Collection Title: " + GetSelectedPreference(GetPreferenceCollectionTitle(), RegRead("prefCollectionTitle")),
            ShortTitle: "Collection Title",
            ID: "prefCollectionTitle",
            ContentType: "pref",
            ShortDescriptionLine1: "Show or hide the collection title.",
            HDBackgroundImageUrl: "pkg://images/hd-preferences-lg.png",
            SDBackgroundImageUrl: "pkg://images/sd-preferences-lg.png"
        },
        {
            Title: "Collection PopUp Bubble: " + GetSelectedPreference(GetPreferenceCollectionPopup(), RegRead("prefCollectionPopup")),
            ShortTitle: "Display Collection PopUp Bubble",
            ID: "prefCollectionPopup",
            ContentType: "pref",
            ShortDescriptionLine1: "Show Or Hide a PopUp bubble with extra information.",
            HDBackgroundImageUrl: "pkg://images/hd-preferences-lg.png",
            SDBackgroundImageUrl: "pkg://images/sd-preferences-lg.png"
        },
        {
            Title: "Show Collections First Row: " + GetSelectedPreference(GetPreferenceCollectionsFirstRow(), RegRead("prefCollectionsFirstRow")),
            ShortTitle: "Show Collections First Row",
            ID: "prefCollectionsFirstRow",
            ContentType: "pref",
            ShortDescriptionLine1: "Show collections on the first row of the home screen. (requires restart)",
            HDBackgroundImageUrl: "pkg://images/hd-preferences-lg.png",
            SDBackgroundImageUrl: "pkg://images/sd-preferences-lg.png"
        },
        {
            Title: "Use Enhanced Images: " + GetSelectedPreference(GetPreferenceEnhancedImages(), RegRead("prefEnhancedImages")),
            ShortTitle: "Use Enhanced Images",
            ID: "prefEnhancedImages",
            ContentType: "pref",
            ShortDescriptionLine1: "Use Enhanced Images such as Cover Art.",
            HDBackgroundImageUrl: "pkg://images/hd-preferences-lg.png",
            SDBackgroundImageUrl: "pkg://images/sd-preferences-lg.png"
        },
        {
            Title: "Use Media Indicators: " + GetSelectedPreference(GetPreferenceMediaIndicators(), RegRead("prefMediaIndicators")),
            ShortTitle: "Use Media Indicators",
            ID: "prefMediaIndicators",
            ContentType: "pref",
            ShortDescriptionLine1: "Show or Hide media indicators such as played or percentage played.",
            HDBackgroundImageUrl: "pkg://images/hd-preferences-lg.png",
            SDBackgroundImageUrl: "pkg://images/sd-preferences-lg.png"
        },
        {
            Title: "Theme: " + GetSelectedPreference(GetPreferenceTheme(), RegRead("prefTheme")),
            ShortTitle: "Theme",
            ID: "prefTheme",
            ContentType: "pref",
            ShortDescriptionLine1: "Select from dark or original (restart required)",
            HDBackgroundImageUrl: "pkg://images/hd-preferences-lg.png",
            SDBackgroundImageUrl: "pkg://images/sd-preferences-lg.png"
        },
        {
            Title: "Check for Server Updates: " + GetSelectedPreference(GetPreferenceServerUpdates(), RegRead("prefServerUpdates")),
            ShortTitle: "Check Server Updates",
            ID: "prefServerUpdates",
            ContentType: "pref",
            ShortDescriptionLine1: "Check for Media Browser Server updates on start up.",
            HDBackgroundImageUrl: "pkg://images/hd-preferences-lg.png",
            SDBackgroundImageUrl: "pkg://images/sd-preferences-lg.png"
        }
    ]

    if getGlobalVar("legacyDevice")
        backButton = {
            Title: ">> Back to Home <<",
            ContentType: "exit",
            HDBackgroundImageUrl: "pkg://images/hd-preferences-lg.png",
            SDBackgroundImageUrl: "pkg://images/sd-preferences-lg.png"
        }

        preferenceList.Unshift( backButton )
    end if

    return preferenceList
End Function


'**********************************************************
'** Get Preference Options
'**********************************************************

Function GetPreferenceVideoQuality() as Object
    prefOptions = [
        {
            Title: "664 Kbps SD",
            Id: "664",
            IsDefault: false
        },
        {
            Title: "996 Kbps HD",
            Id: "996",
            IsDefault: false
        },
        {
            Title: "1.3 Mbps HD",
            Id: "1320",
            IsDefault: false
        },
        {
            Title: "2.6 Mbps HD",
            Id: "2600",
            IsDefault: false
        },
        {
            Title: "3.2 Mbps HD [default]",
            Id: "3200",
            IsDefault: true
        },
        {
            Title: "4.7 Mbps HD",
            Id: "4700",
            IsDefault: false
        },
        {
            Title: "6.2 Mbps HD",
            Id: "6200",
            IsDefault: false
        },
        {
            Title: "7.7 Mbps HD",
            Id: "7700",
            IsDefault: false
        },
        {
            Title: "9.2 Mbps HD",
            Id: "9200",
            IsDefault: false
        },
        {
            Title: "10.7 Mbps HD",
            Id: "10700",
            IsDefault: false
        },
        {
            Title: "12.2 Mbps HD",
            Id: "12200",
            IsDefault: false
        },
        {
            Title: "13.7 Mbps HD",
            Id: "13700",
            IsDefault: false
        },
        {
            Title: "15.2 Mbps HD",
            Id: "15200",
            IsDefault: false
        },
        {
            Title: "16.7 Mbps HD",
            Id: "16700",
            IsDefault: false
        },
        {
            Title: "18.2 Mbps HD",
            Id: "18200",
            IsDefault: false
        },
        {
            Title: "20.0 Mbps HD",
            Id: "20000",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceMovieImageType() as Object
    prefOptions = [
        {
            Title: "Backdrop [default]",
            Id: "backdrop",
            IsDefault: true
        },
        {
            Title: "Poster",
            Id: "poster",
            IsDefault: false
        },
        {
            Title: "Thumb",
            Id: "thumb",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceMovieTitle() as Object
    prefOptions = [
        {
            Title: "Show [default]",
            Id: "show",
            IsDefault: true
        },
        {
            Title: "Hide",
            Id: "hide",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceMovieDisplayPopup() as Object
    prefOptions = [
        {
            Title: "No [default]",
            Id: "no",
            IsDefault: true
        },
        {
            Title: "Yes",
            Id: "yes",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceTVImageType() as Object
    prefOptions = [
        {
            Title: "Backdrop [default]",
            Id: "backdrop",
            IsDefault: true
        },
        {
            Title: "Poster",
            Id: "poster",
            IsDefault: false
        },
        {
            Title: "Thumb",
            Id: "thumb",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceTVTitle() as Object
    prefOptions = [
        {
            Title: "Show [default]",
            Id: "show",
            IsDefault: true
        },
        {
            Title: "Hide",
            Id: "hide",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceTVDisplayPopup() as Object
    prefOptions = [
        {
            Title: "No [default]",
            Id: "no",
            IsDefault: true
        },
        {
            Title: "Yes",
            Id: "yes",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceTVThemeMusic() as Object
    prefOptions = [
        {
            Title: "No [default]",
            Id: "no",
            IsDefault: true
        },
        {
            Title: "Yes",
            Id: "yes",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceTVThemeMusicRepeat() as Object
    prefOptions = [
        {
            Title: "No [default]",
            Id: "no",
            IsDefault: true
        },
        {
            Title: "Yes",
            Id: "yes",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceCollectionView() as Object
    prefOptions = [
        {
            Title: "Backdrop [default]",
            Id: "backdrop",
            IsDefault: true
        },
        {
            Title: "Poster",
            Id: "poster",
            IsDefault: false
        },
        {
            Title: "Thumb",
            Id: "thumb",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceTheme() as Object
    prefOptions = [
        {
            Title: "Original [default]",
            Id: "original",
            IsDefault: true
        },
        {
            Title: "Dark",
            Id: "dark",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceCollectionTitle() as Object
    prefOptions = [
        {
            Title: "Show [default]",
            Id: "show",
            IsDefault: true
        },
        {
            Title: "Hide",
            Id: "hide",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceCollectionPopup() as Object
    prefOptions = [
        {
            Title: "No [default]",
            Id: "no",
            IsDefault: true
        },
        {
            Title: "Yes",
            Id: "yes",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceCollectionsFirstRow() as Object
    prefOptions = [
        {
            Title: "No [default]",
            Id: "no",
            IsDefault: true
        },
        {
            Title: "Yes",
            Id: "yes",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceEnhancedImages() as Object
    prefOptions = [
        {
            Title: "No [default]",
            Id: "no",
            IsDefault: true
        },
        {
            Title: "Yes",
            Id: "yes",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceMediaIndicators() as Object
    prefOptions = [
        {
            Title: "No",
            Id: "no",
            IsDefault: false
        },
        {
            Title: "Yes [default]",
            Id: "yes",
            IsDefault: true
        }
    ]

    return prefOptions
End Function

Function GetPreferenceServerUpdates() as Object
    prefOptions = [
        {
            Title: "No",
            Id: "no",
            IsDefault: false
        },
        {
            Title: "Yes [default]",
            Id: "yes",
            IsDefault: true
        }
    ]

    return prefOptions
End Function
