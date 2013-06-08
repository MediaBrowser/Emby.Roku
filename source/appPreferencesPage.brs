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
    'screen.SetHeader("Welcome to The Channel Diner")

    ' Get Preference Functions
    preferenceFunctions = [
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

    For each itemData in list
        If itemData.Id = selected Then
            return itemData.Title
        End If
    End For

    ' Nothing selected, return first item
    return list[0].Title
End Function


'**********************************************************
'** Get Next Preference
'**********************************************************

Function GetNextPreference(list As Object, selected) as Object

    if validateParam(list, "roArray", "GetNextPreference") = false return -1

    index = 0
    currentIndex = 0
    For each itemData in list
        If itemData.Id = selected Then
            currentIndex = index
            Exit For
        End If
        index = index + 1
    End For

    nextIndex = currentIndex + 1
    if nextIndex >= list.Count() then
       nextIndex = 0 
    end if

    return list[nextIndex]
End Function

'**********************************************************
'** Get Preference Options
'**********************************************************

Function GetPreferenceMovieImageType() as Object
    prefOptions = [
        {
            Title: "Backdrop [default]",
            Id: "backdrop"
        },
        {
            Title: "Poster",
            Id: "poster"
        },
        {
            Title: "Thumb",
            Id: "thumb"
        }
    ]

    return prefOptions
End Function

Function GetPreferenceMovieTitle() as Object
    prefOptions = [
        {
            Title: "Show [default]",
            Id: "show"
        },
        {
            Title: "Hide",
            Id: "hide"
        }
    ]

    return prefOptions
End Function

Function GetPreferenceTVImageType() as Object
    prefOptions = [
        {
            Title: "Backdrop [default]",
            Id: "backdrop"
        },
        {
            Title: "Poster",
            Id: "poster"
        },
        {
            Title: "Thumb",
            Id: "thumb"
        }
    ]

    return prefOptions
End Function

Function GetPreferenceTVTitle() as Object
    prefOptions = [
        {
            Title: "Show [default]",
            Id: "show"
        },
        {
            Title: "Hide",
            Id: "hide"
        }
    ]

    return prefOptions
End Function
