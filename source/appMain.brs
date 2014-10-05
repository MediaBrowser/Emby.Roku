'********************************************************************
'**  Media Browser Roku Client - Main
'********************************************************************

Sub Main()

    'Initialize globals
    initGlobals()

    'Initialize theme
    'prepare the screen for display and get ready to begin
    viewController = createViewController()
	
	' Uncomment this as needed to debug startup sequence
	'RegDelete("serverActive")

	'RunScreenSaver()
	viewController.Show()

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
			Debug("--" + entry[1] + "--")
            GetGlobalAA().AddReplace("channelVersion", MID(entry[1], 0, 4))
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
        models["2700X"] = "Roku LT (2013)"
        models["2710X"] = "Roku 1 (2013)"
        models["2720X"] = "Roku 2 (2013)"
        models["3000X"] = "Roku 2 HD"
        models["3050X"] = "Roku 2 XD"
        models["3100X"] = "Roku 2 XS"
        models["3400X"] = "Roku Streaming Stick"
        models["3420X"] = "Roku Streaming Stick"
        models["3500R"] = "Roku Streaming Stick (2014)"
        models["4200X"] = "Roku 3"
        models["4200R"] = "Roku 3"

        If models.DoesExist(modelNumber) Then
            modelName = models[modelNumber]
        Else
            modelName = modelNumber
        End If
    End If

    GetGlobalAA().AddReplace("rokuModelNumber", modelNumber)
    GetGlobalAA().AddReplace("rokuModelName", modelName)

    ' Check for DTS passthrough support
    if left(modelNumber,4) = "4200"
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

    ' Support for ReFrames seems mixed. These numbers could be wrong, but
    ' there are reports that the Roku 1 can't handle more than 5 ReFrames,
    ' and testing has shown that the video is black beyond that point. The
    ' Roku 2 has been observed to play all the way up to 16 ReFrames, but
    ' on at least one test video there were noticeable artifacts as the
    ' number increased, starting with 8.
    if left(modelNumber,4) = "4200" and major >=5 then
	GetGlobalAA().AddReplace("maxRefFrames", 12)
    elseif major >= 4 then
        GetGlobalAA().AddReplace("maxRefFrames", 8)
    else
        GetGlobalAA().AddReplace("maxRefFrames", 5)
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

    playsAnamorphic = major > 4 OR (major = 4 AND (minor >= 8 OR device.GetDisplayType() = "HDTV"))
    Debug("Anamorphic support: " + tostr(playsAnamorphic))
    GetGlobalAA().AddReplace("playsAnamorphic", playsAnamorphic)

	SupportsSurroundSound()
	
End Sub

'*************************************************************
'** Get a variable from the Global Array
'*************************************************************

Function getGlobalVar(name, default=invalid)
    Return firstOf(GetGlobalAA().Lookup(name), default)
End Function

Function SupportsSurroundSound(transcoding=false, refresh=false) As Boolean

    ' Before the Roku 3, there's no need to ever refresh.
    major = getGlobalVar("rokuVersion")[0]

    if m.SurroundSoundTimer = invalid then
        refresh = true
        m.SurroundSoundTimer = CreateTimer()
    else if major <= 4 then
        refresh = false
    else if m.SurroundSoundTimer.GetElapsedSeconds() > 10 then
        refresh = true
    end if

    if refresh then
        device = CreateObject("roDeviceInfo")
        result = device.HasFeature("5.1_surround_sound")
        GetGlobalAA().AddReplace("surroundSound", result)
        m.SurroundSoundTimer.Mark()
    else
        result = getGlobalVar("surroundSound")
    end if

    if transcoding then
        return (result AND major >= 4)
    else
        return result
    end if
End Function

Function CheckMinimumVersion(versionArr, requiredVersion) As Boolean
    index = 0
    for each num in versionArr
        if index >= requiredVersion.count() then exit for
        if num < requiredVersion[index] then
            return false
        else if num > requiredVersion[index] then
            return true
        end if
        index = index + 1
    next
    return true
End Function

Function IsActiveSupporter() as Boolean

	' URL
    url = GetServerBaseUrl() + "/Plugins/SecurityInfo"

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
	
	if response <> invalid then
		
		userInfo = ParseJSON(response)
		
		if userInfo <> invalid then
			return userInfo.IsMBSupporter
		end if
	
	end if
	
	return false
	
End Function
