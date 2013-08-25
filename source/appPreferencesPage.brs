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
        GetPreferenceTVThemeMusicRepeat
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
            ShortDescriptionLine1: "Select the quality of the video streams"
        },
        {
            Title: "Movie Image Type: " + GetSelectedPreference(GetPreferenceMovieImageType(), RegRead("prefMovieImageType")),
            ShortTitle: "Movie Image Type",
            ID: "prefMovieImageType",
            ShortDescriptionLine1: "Select from backdrop, poster, or thumb image"
        },
        {
            Title: "Movie Title: " + GetSelectedPreference(GetPreferenceMovieTitle(), RegRead("prefMovieTitle")),
            ShortTitle: "Movie Title",
            ID: "prefMovieTitle",
            ShortDescriptionLine1: "Show or hide the movie title below the movie image."            
        },
        {
            Title: "Movies PopUp Bubble: " + GetSelectedPreference(GetPreferenceMovieDisplayPopup(), RegRead("prefMovieDisplayPopup")),
            ShortTitle: "Display PopUp Bubble for Movies",
            ID: "prefMovieDisplayPopup",
            ShortDescriptionLine1: "Show Or Hide a PopUp bubble with extra information."            
        },
        {
            Title: "TV Series Image Type: " + GetSelectedPreference(GetPreferenceTVImageType(), RegRead("prefTVImageType")),
            ShortTitle: "TV Series Image Type",
            ID: "prefTVImageType",
            ShortDescriptionLine1: "Select from backdrop, poster, or thumb image"
        },
        {
            Title: "TV Series Title: " + GetSelectedPreference(GetPreferenceTVTitle(), RegRead("prefTVTitle")),
            ShortTitle: "TV Series Title",
            ID: "prefTVTitle",
            ShortDescriptionLine1: "Show or hide the tv series title below the tv series image."            
        },
        {
            Title: "TV PopUp Bubble: " + GetSelectedPreference(GetPreferenceTVDisplayPopup(), RegRead("prefTVDisplayPopup")),
            ShortTitle: "Display PopUp Bubble For TV",
            ID: "prefTVDisplayPopup",
            ShortDescriptionLine1: "Show Or Hide a PopUp bubble with extra information."            
        },
        {
            Title: "Play TV Theme Music: " + GetSelectedPreference(GetPreferenceTVThemeMusic(), RegRead("prefTVMusic")),
            ShortTitle: "Play TV Theme Music",
            ID: "prefTVMusic",
            ShortDescriptionLine1: "Play TV theme music while browsing a TV Series."            
        },
        {
            Title: "Repeat TV Theme Music: " + GetSelectedPreference(GetPreferenceTVThemeMusicRepeat(), RegRead("prefTVMusicLoop")),
            ShortTitle: "Repeat TV Theme Music",
            ID: "prefTVMusicLoop",
            ShortDescriptionLine1: "Repeat TV theme music while browsing TV Series."            
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
