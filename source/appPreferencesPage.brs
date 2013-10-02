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
        GetPreferenceEnhancedImages,
        GetPreferenceMediaIndicators
    ]

    ' Fetch / Refresh Preference Screen
    preferenceList = RefreshPreferencesPage(screen)

    while true
        msg = wait(0, screen.Port)

        If type(msg) = "roListScreenEvent" Then

            If msg.isListItemFocused() Then

            Else If msg.isListItemSelected() Then
                prefName    = preferenceList[msg.GetIndex()].Id
                shortTitle  = preferenceList[msg.GetIndex()].ShortTitle
                itemOptions = preferenceFunctions[msg.GetIndex()]()

                ' Show Item Options Screen
                ShowItemOptions(shortTitle, prefName, itemOptions)

                ' Refresh Page
                preferenceList = RefreshPreferencesPage(screen)

                ' Refocus Item
                screen.SetFocusedItem(msg.GetIndex())

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

                ' Save New Preference
                RegWrite(itemId, prefSelected)

                ' Close Screen
                return false

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
            ShortDescriptionLine1: "Select the quality of the video streams",
            HDBackgroundImageUrl: "pkg://images/hd-preferences-lg.png",
            SDBackgroundImageUrl: "pkg://images/sd-preferences-lg.png"
        },
        {
            Title: "Movie Image Type: " + GetSelectedPreference(GetPreferenceMovieImageType(), RegRead("prefMovieImageType")),
            ShortTitle: "Movie Image Type",
            ID: "prefMovieImageType",
            ShortDescriptionLine1: "Select from backdrop, poster, or thumb image",
            HDBackgroundImageUrl: "pkg://images/hd-preferences-lg.png",
            SDBackgroundImageUrl: "pkg://images/sd-preferences-lg.png"
        },
        {
            Title: "Movie Title: " + GetSelectedPreference(GetPreferenceMovieTitle(), RegRead("prefMovieTitle")),
            ShortTitle: "Movie Title",
            ID: "prefMovieTitle",
            ShortDescriptionLine1: "Show or hide the movie title below the movie image.",
            HDBackgroundImageUrl: "pkg://images/hd-preferences-lg.png",
            SDBackgroundImageUrl: "pkg://images/sd-preferences-lg.png"
        },
        {
            Title: "Movies PopUp Bubble: " + GetSelectedPreference(GetPreferenceMovieDisplayPopup(), RegRead("prefMovieDisplayPopup")),
            ShortTitle: "Display PopUp Bubble for Movies",
            ID: "prefMovieDisplayPopup",
            ShortDescriptionLine1: "Show Or Hide a PopUp bubble with extra information.",
            HDBackgroundImageUrl: "pkg://images/hd-preferences-lg.png",
            SDBackgroundImageUrl: "pkg://images/sd-preferences-lg.png"
        },
        {
            Title: "TV Series Image Type: " + GetSelectedPreference(GetPreferenceTVImageType(), RegRead("prefTVImageType")),
            ShortTitle: "TV Series Image Type",
            ID: "prefTVImageType",
            ShortDescriptionLine1: "Select from backdrop, poster, or thumb image",
            HDBackgroundImageUrl: "pkg://images/hd-preferences-lg.png",
            SDBackgroundImageUrl: "pkg://images/sd-preferences-lg.png"
        },
        {
            Title: "TV Series Title: " + GetSelectedPreference(GetPreferenceTVTitle(), RegRead("prefTVTitle")),
            ShortTitle: "TV Series Title",
            ID: "prefTVTitle",
            ShortDescriptionLine1: "Show or hide the tv series title below the tv series image.",
            HDBackgroundImageUrl: "pkg://images/hd-preferences-lg.png",
            SDBackgroundImageUrl: "pkg://images/sd-preferences-lg.png"
        },
        {
            Title: "TV PopUp Bubble: " + GetSelectedPreference(GetPreferenceTVDisplayPopup(), RegRead("prefTVDisplayPopup")),
            ShortTitle: "Display PopUp Bubble For TV",
            ID: "prefTVDisplayPopup",
            ShortDescriptionLine1: "Show Or Hide a PopUp bubble with extra information.",
            HDBackgroundImageUrl: "pkg://images/hd-preferences-lg.png",
            SDBackgroundImageUrl: "pkg://images/sd-preferences-lg.png"
        },
        {
            Title: "Play TV Theme Music: " + GetSelectedPreference(GetPreferenceTVThemeMusic(), RegRead("prefTVMusic")),
            ShortTitle: "Play TV Theme Music",
            ID: "prefTVMusic",
            ShortDescriptionLine1: "Play TV theme music while browsing a TV Series.",
            HDBackgroundImageUrl: "pkg://images/hd-preferences-lg.png",
            SDBackgroundImageUrl: "pkg://images/sd-preferences-lg.png"
        },
        {
            Title: "Repeat TV Theme Music: " + GetSelectedPreference(GetPreferenceTVThemeMusicRepeat(), RegRead("prefTVMusicLoop")),
            ShortTitle: "Repeat TV Theme Music",
            ID: "prefTVMusicLoop",
            ShortDescriptionLine1: "Repeat TV theme music while browsing TV Series.",
            HDBackgroundImageUrl: "pkg://images/hd-preferences-lg.png",
            SDBackgroundImageUrl: "pkg://images/sd-preferences-lg.png"
        },
        {
            Title: "Collection View: " + GetSelectedPreference(GetPreferenceCollectionView(), RegRead("prefCollectionView")),
            ShortTitle: "Collection View",
            ID: "prefCollectionView",
            ShortDescriptionLine1: "Select from backdrop, poster, or thumb image",
            HDBackgroundImageUrl: "pkg://images/hd-preferences-lg.png",
            SDBackgroundImageUrl: "pkg://images/sd-preferences-lg.png"
        },
        {
            Title: "Collection Title: " + GetSelectedPreference(GetPreferenceCollectionTitle(), RegRead("prefCollectionTitle")),
            ShortTitle: "Collection Title",
            ID: "prefCollectionTitle",
            ShortDescriptionLine1: "Show or hide the collection title.",
            HDBackgroundImageUrl: "pkg://images/hd-preferences-lg.png",
            SDBackgroundImageUrl: "pkg://images/sd-preferences-lg.png"
        },
        {
            Title: "Collection PopUp Bubble: " + GetSelectedPreference(GetPreferenceCollectionPopup(), RegRead("prefCollectionPopup")),
            ShortTitle: "Display Collection PopUp Bubble",
            ID: "prefCollectionPopup",
            ShortDescriptionLine1: "Show Or Hide a PopUp bubble with extra information.",
            HDBackgroundImageUrl: "pkg://images/hd-preferences-lg.png",
            SDBackgroundImageUrl: "pkg://images/sd-preferences-lg.png"
        },
        {
            Title: "Use Enhanced Images: " + GetSelectedPreference(GetPreferenceEnhancedImages(), RegRead("prefEnhancedImages")),
            ShortTitle: "Use Enhanced Images",
            ID: "prefEnhancedImages",
            ShortDescriptionLine1: "Use Enhanced Images such as Cover Art.",
            HDBackgroundImageUrl: "pkg://images/hd-preferences-lg.png",
            SDBackgroundImageUrl: "pkg://images/sd-preferences-lg.png"
        },
        {
            Title: "Use Media Indicators: " + GetSelectedPreference(GetPreferenceMediaIndicators(), RegRead("prefMediaIndicators")),
            ShortTitle: "Use Media Indicators",
            ID: "prefMediaIndicators",
            ShortDescriptionLine1: "Show or Hide media indicators such as played or percentage played.",
            HDBackgroundImageUrl: "pkg://images/hd-preferences-lg.png",
            SDBackgroundImageUrl: "pkg://images/sd-preferences-lg.png"
        }
    ]

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
