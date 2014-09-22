'**********************************************************
'** createPreferencesScreen
'**********************************************************

Function createPreferencesScreen(viewController as Object) as Object

    ' Create List Screen
    screen = CreateListScreen(viewController)

	screen.baseHandleMessage = screen.HandleMessage
	screen.HandleMessage = handlePreferencesScreenMessage

	screen.Activate = preferencesActivate

    ' Refresh Preference Screen
    RefreshPreferencesPage(screen)

	return screen

End Function

Function handlePreferencesScreenMessage(msg) as Boolean

	handled = false

	viewController = m.ViewController
	screen = m

    ' Fetch / Refresh Preference Screen
    If type(msg) = "roListScreenEvent" Then

		If msg.isListItemSelected() Then

			handled = true
		
			preferenceList = GetPreferenceList()

            if preferenceList[msg.GetIndex()].ContentType = "exit"
                
				m.Screen.Close()

            else

				m.lastIndex = msg.GetIndex()

				prefType	= preferenceList[msg.GetIndex()].PrefType
					
				' Get Preference Functions
				preferenceFunctions = [
					GetTextPreference,
					GetPreferenceVideoQuality,
					GetPreferenceTVThemeMusic,
					GetPreferenceTVThemeMusicRepeat,
					GetPreferenceRememberUser,
					GetPreferenceEnhancedImages,
					GetPreferenceMediaIndicators,
					GetPreferenceShowClock,
                    GetPreferenceTimeFormat
				]

				if (prefType = "custom") then
					' Call custom function
					preferenceFunctions[msg.GetIndex()](viewController, preferenceList[msg.GetIndex()])
				else
					prefName    = preferenceList[msg.GetIndex()].Id
					shortTitle  = preferenceList[msg.GetIndex()].ShortTitle
					itemOptions = preferenceFunctions[msg.GetIndex()]()

					' Show Item Options Screen
					newScreen = createItemOptionsScreen(viewController, shortTitle, prefName, itemOptions)
					newScreen.ScreenName = "ItemOptions"
					viewController.InitializeOtherScreen(newScreen, [shortTitle])
					newScreen.Show()


				endif

            end if

        End If
    End If

	if handled = false then
		handled = m.baseHandleMessage(msg)
	end If

	return handled

End Function


'**********************************************************
'** gridActivate
'**********************************************************

Sub preferencesActivate(priorScreen)
    if m.popOnActivate then
        m.ViewController.PopScreen(m)
        return
    else if m.closeOnActivate then
        if m.Screen <> invalid then
            m.Screen.Close()
        else
            m.ViewController.PopScreen(m)
        end if
        return
    end if

    ' If our screen was destroyed by some child screen, recreate it now
    if m.Screen = invalid then

    else
		RefreshPreferencesPage(m)

		m.Screen.SetFocusedListItem(m.lastIndex)
    end if

    if m.Facade <> invalid then m.Facade.Close()
End Sub

'**********************************************************
'** Get A Text Preference Value
'**********************************************************
Function GetTextPreference(viewController, options as Object)

	listener = CreateObject("roAssociativeArray")
	listener.OnUserInput = textScreenCallback
	listener.optionId = options.ID

	screen = viewController.CreateTextInputScreen(options.ShortTitle, options.ShortDescriptionLine1, [options.ShortTitle], firstOf(regRead(options.ID),""), false)
	screen.Listener = listener

	screen.Show()

End Function


Function textScreenCallback(value, screen) As Boolean

    if value <> invalid and value <> ""
        regWrite(m.optionId, value)
    end if

	return true
	
End Function

'**********************************************************
'** Show Item Options
'**********************************************************

Function createItemOptionsScreen(viewController as Object, title As String, itemId As String, list As Object) as Object

    ' Create List Screen
    screen = CreateListScreen(viewController)

	screen.itemId = itemId

	screen.baseHandleMessage = screen.HandleMessage
	screen.HandleMessage = handleItemOptionsScreenMessage

    ' Set Content
    screen.SetHeader(title)
    screen.SetContent(list)

    return screen

End Function

Function handleItemOptionsScreenMessage(msg) as Boolean

	handled = false

    ' Fetch / Refresh Preference Screen
    If type(msg) = "roListScreenEvent" Then

        If msg.isListItemSelected() Then

			handled = true

			index = msg.GetIndex()
			list = m.contentArray

            prefSelected = list[index].Id

            ' Save New Preference
            RegWrite(m.itemId, prefSelected)

			m.Screen.Close()

        End If
    End If

	if handled = false then
		handled = m.baseHandleMessage(msg)
	end If

	return handled

End Function


'**********************************************************
'** Refresh Preferences Page
'**********************************************************

Function RefreshPreferencesPage(screen As Object) As Object

    ' Get Data
    preferenceList = GetPreferenceList()

    ' Show Screen
    screen.SetContent(preferenceList)

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

	viewController = GetViewController()
	
    preferenceList = [
        {
            Title: "Roku Display Name: " + FirstOf(RegRead("prefDisplayName"),"Roku"),
            ShortTitle: "Roku Display Name",
            ID: "prefDisplayName",
            ContentType: "pref",
			PrefType: "custom",
            ShortDescriptionLine1: "Provide a name for this Roku. e.g. Kid's Roku or Living Room",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Video Quality: " + GetSelectedPreference(GetPreferenceVideoQuality(), RegRead("prefVideoQuality")),
            ShortTitle: "Video Quality",
            ID: "prefVideoQuality",
            ContentType: "pref",
			PrefType: "list",
            ShortDescriptionLine1: "Select the quality of the video streams",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Play Theme Music: " + GetSelectedPreference(GetPreferenceTVThemeMusic(), RegRead("prefThemeMusic")),
            ShortTitle: "Play Theme Music",
            ID: "prefThemeMusic",
            ContentType: "pref",
			PrefType: "list",
            ShortDescriptionLine1: "Play theme music while browsing the library.",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Repeat Theme Music: " + GetSelectedPreference(GetPreferenceTVThemeMusicRepeat(), RegRead("prefThemeMusicLoop")),
            ShortTitle: "Repeat Theme Music",
            ID: "prefThemeMusicLoop",
            ContentType: "pref",
			PrefType: "list",
            ShortDescriptionLine1: "Repeat theme music while browsing the library.",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Remember User: " + GetSelectedPreference(GetPreferenceRememberUser(), RegRead("prefRememberUser")),
            ShortTitle: "Remember User",
            ID: "prefRememberUser",
            ContentType: "pref",
			PrefType: "list",
            ShortDescriptionLine1: "Remember the current logged in user for next time you open the channel.",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Use CoverArt: " + GetSelectedPreference(GetPreferenceEnhancedImages(), RegRead("prefEnhancedImages")),
            ShortTitle: "Use CoverArt",
            ID: "prefEnhancedImages",
            ContentType: "pref",
			PrefType: "list",
            ShortDescriptionLine1: "Use Enhanced Images such as Cover Art.",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Use Media Indicators: " + GetSelectedPreference(GetPreferenceMediaIndicators(), RegRead("prefMediaIndicators")),
            ShortTitle: "Use Media Indicators",
            ID: "prefMediaIndicators",
            ContentType: "pref",
			PrefType: "list",
            ShortDescriptionLine1: "Show or Hide media indicators such as played or percentage played.",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Show Clock: " + GetSelectedPreference(GetPreferenceShowClock(), RegRead("prefShowClock")),
            ShortTitle: "Show Clock",
            ID: "prefShowClock",
            ContentType: "pref",
            PrefType: "list",
            ShortDescriptionLine1: "Show or hide clock on Home Screen.",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Time Format: " + GetSelectedPreference(GetPreferenceTimeFormat(), RegRead("prefTimeFormat")),
            ShortTitle: "Time Format",
            ID: "prefTimeFormat",
            ContentType: "pref",
            PrefType: "list",
            ShortDescriptionLine1: "Select 12h or 24h time format.",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
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
            Title: "2.0 Mbps HD",
            Id: "2000",
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

Function GetPreferenceTVThemeMusic() as Object
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

Function GetPreferenceRememberUser() as Object
    prefOptions = [
        {
            Title: "Yes [default]",
            Id: "yes",
            IsDefault: true
        },
        {
            Title: "No",
            Id: "no",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceEnhancedImages() as Object
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

Function GetPreferenceShowClock() as Object
    prefOptions = [
        {
            Title: "Yes [default]",
            Id: "yes", 
            IsDefault: true
        },
        {
            Title: "No",
            Id: "no",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceTimeFormat() as Object
    prefOptions = [
        {
            Title: "12h [default]",
            Id: "12h",
            IsDefault: true
        },
        {
            Title: "24h",
            Id: "24h",
            IsDefault: false
        }
    ]

    return prefOptions
End Function
