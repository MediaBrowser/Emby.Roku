'*****************************************************************
'**  Media Browser Roku Client - Preferences Page
'*****************************************************************


'**********************************************************
'** Show Preferences Page
'**********************************************************

Function ShowPreferencesPage()

    ' Setup Screen
    port   = CreateObject("roMessagePort")
    screen = CreateObject("roListScreen")
    screen.SetMessagePort(port)

    screen.SetBreadcrumbText("", "Preferences")

    ' Get Preference Functions
    preferenceFunctions = [
        GetPreferenceVideoQuality,
        GetPreferenceMovieImageType,
        GetPreferenceMovieTitle,
        GetPreferenceTVImageType,
        GetPreferenceTVTitle
    ]

    ' Fetch / Refresh Preference Screen
    preferenceList = RefreshPreferencesPage(screen)

    while true
        msg = wait(0, screen.GetMessagePort())

        If type(msg) = "roListScreenEvent" Then

            If msg.isListItemFocused() Then

            Else If msg.isListItemSelected() Then
                prefName = "pref" + preferenceList[msg.GetIndex()].Id
                nextPreference = GetNextPreference( preferenceFunctions[msg.GetIndex()](), RegRead(prefName) )

                ' Save New Preference
                RegWrite(prefName, nextPreference.Id)

                ' Refresh Page
                preferenceList = RefreshPreferencesPage(screen)

                ' Refocus Item
                screen.SetFocusedListItem(msg.GetIndex())

            Else If msg.isScreenClosed() Then
                Print "Close prefs screen"
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

    if validateParam(screen, "roListScreen", "RefreshPreferencesPage") = false return -1

    ' Get Data
    preferenceList = GetPreferenceList()

    ' Show Screen
    screen.SetContent(preferenceList)
    screen.Show()

    return preferenceList
End Function

'**********************************************************
'** Get Preferences List
'**********************************************************

Function GetPreferenceList() as Object
    preferenceList = [
        {
            Title: "Video Quality: " + GetSelectedPreference(GetPreferenceVideoQuality(), RegRead("prefVideoQuality")),
            ID: "VideoQuality",
            ShortDescriptionLine1: "Select the quality of the video streams"
        },
        {
            Title: "Movie Image Type: " + GetSelectedPreference(GetPreferenceMovieImageType(), RegRead("prefMovieImageType")),
            ID: "MovieImageType",
            ShortDescriptionLine1: "Select from backdrop, poster, or thumb image"
        },
        {
            Title: "Movie Title: " + GetSelectedPreference(GetPreferenceMovieTitle(), RegRead("prefMovieTitle")),
            ID: "MovieTitle",
            ShortDescriptionLine1: "Show or hide the movie title below the movie image."            
        },
        {
            Title: "TV Series Image Type: " + GetSelectedPreference(GetPreferenceTVImageType(), RegRead("prefTVImageType")),
            ID: "TVImageType",
            ShortDescriptionLine1: "Select from backdrop, poster, or thumb image"
        },
        {
            Title: "TV Series Title: " + GetSelectedPreference(GetPreferenceTVTitle(), RegRead("prefTVTitle")),
            ID: "TVTitle",
            ShortDescriptionLine1: "Show or hide the tv series title below the tv series image."            
        }
    ]

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
'** Get Next Preference
'**********************************************************

Function GetNextPreference(list As Object, selected) as Object

    if validateParam(list, "roArray", "GetNextPreference") = false return -1

    index = 0
    currentIndex = 0
    defaultIndex = 0

    For each itemData in list
        ' Find Default Index
        If itemData.IsDefault Then
            defaultIndex = index
        End If

        If itemData.Id = selected Then
            currentIndex = index
            Exit For
        End If
        index = index + 1
    End For

    ' Handle Default
    If selected = invalid Then
        currentIndex = defaultIndex
    End If

    nextIndex = currentIndex + 1
    if nextIndex >= list.Count() then
       nextIndex = 0 
    end if

    return list[nextIndex]
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
