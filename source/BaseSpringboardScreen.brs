'*
'* Base springboard screen on top of which audio/video/photo players are used.
'*
'** Credit: Plex Roku https://github.com/plexinc/roku-client-public

Function itemIsRefreshable(item) As Boolean
    return item <> invalid
End Function

Function createBaseSpringboardScreen(context, index, viewController, includePredicate=itemIsRefreshable) As Object
    obj = CreateObject("roAssociativeArray")
    initBaseScreen(obj, viewController)

    screen = CreateObject("roSpringboardScreen")
    screen.SetMessagePort(obj.Port)

    ' Filter out anything in the context that can't be shown on a springboard.
    contextCopy = []
    i = 0
    offset = 0
    for each item in context
        if includePredicate(item) then
            contextCopy.Push(item)
            item.OrigIndex = i - offset
        else if i < index then
            offset = offset + 1
        end if
        i = i + 1
    next

    index = index - offset

    ' Standard properties for all our Screen types
    obj.Item = contextCopy[index]
    obj.Screen = screen
    obj.Show = sbShow
    obj.HandleMessage = sbHandleMessage

    ' Some properties that allow us to move between items in whatever
    ' container got us to this point.
    obj.Context = contextCopy
    obj.CurIndex = index
    obj.AllowLeftRight = contextCopy.Count() > 1
    obj.WrapLeftRight = obj.AllowLeftRight

    obj.IsShuffled = false
    obj.Shuffle = sbShuffle
    obj.Unshuffle = sbUnshuffle

    obj.Refresh = sbRefresh
    obj.GotoNextItem = sbGotoNextItem
    obj.GotoPrevItem = sbGotoPrevItem

    ' Properties/methods to facilitate setting up buttons in the UI
    obj.buttonCommands = invalid
    obj.buttonCount = 0
    obj.ClearButtons = sbClearButtons
    obj.AddButton = sbAddButton
    obj.AddRatingButton = sbAddRatingButton

    ' Methods that will need to be provided by subclasses
    obj.SetupButtons = invalid
    obj.GetMediaDetails = invalid

    obj.thumbnailsToReset = []

    ' Stretched and cropped posters both look kind of terrible, so zoom.
    screen.SetDisplayMode("scale-to-fill")

    item = obj.Item

	if item.StarRating <> invalid then
		obj.Screen.SetStaticRatingEnabled(true)
	else
		obj.Screen.SetStaticRatingEnabled(false)
	end if

	if item.PrimaryImageAspectRatio <> invalid then
		Debug ("Primary image aspect ratio " + tostr(item.PrimaryImageAspectRatio))
		if item.PrimaryImageAspectRatio >= 1.35 then
			obj.Screen.SetPosterStyle("rounded-rect-16x9-generic")
		else if item.PrimaryImageAspectRatio >= .99 then
			obj.Screen.SetPosterStyle("rounded-square-generic")
		end if
	end If

    return obj
End Function

Sub sbShuffle()
    ' Our context is already a copy of the original, so we can safely shuffle
    ' in place. Mixing up the list means that all the navigation will work as
    ' expected without needing a bunch of special logic elsewhere.

    m.CurIndex = ShuffleArray(m.Context, m.CurIndex)
End Sub

Sub sbUnshuffle()
    m.CurIndex = UnshuffleArray(m.Context, m.CurIndex)
End Sub

Sub sbShow()
    ' Refresh calls m.Screen.Show()
    m.Refresh()
End Sub

Function sbHandleMessage(msg) As Boolean
    handled = false

    if type(msg) = "roSpringboardScreenEvent" then
        handled = true

        if msg.isScreenClosed() then
            for each item in m.thumbnailsToReset
                item.SDPosterUrl = item.SDGridThumb
                item.HDPosterUrl = item.HDGridThumb
            next
            m.thumbnailsToReset.Clear()

            m.ViewController.PopScreen(m)
            NowPlayingManager().location = "navigation"
        else if msg.isButtonPressed() then
            buttonCommand = m.buttonCommands[str(msg.getIndex())]
            Debug("Unhandled button press: " + tostr(buttonCommand))
        else if msg.isRemoteKeyPressed() then
            '* index=4 -> left ; index=5 -> right
            if msg.getIndex() = 4 then
                m.GotoPrevItem()
            else if msg.getIndex() = 5 then
                m.GotoNextItem()
            endif
        end if
    end if

    return handled
End Function

Function sbRefresh(force=false)
    ' Don't show any sort of facade or loading dialog. We already have the
    ' metadata for all of our siblings, we don't have to fetch anything, and
    ' so the new screen usually comes up immediately. The dialog with the
    ' spinner ends up just flashing on the screen and being annoying.
    m.Screen.SetContent(invalid)

    'if force then m.Item.Refresh(true)

    m.GetMediaDetails(m.Item)

    if m.AllowLeftRight then
        if m.WrapLeftRight then
            m.Screen.AllowNavLeft(true)
            m.Screen.AllowNavRight(true)
        else
            m.Screen.AllowNavLeft(m.CurIndex > 0)
            m.Screen.AllowNavRight(m.CurIndex < m.Context.Count() - 1)
        end if
    end if

    ' See if we should switch the poster
    if m.metadata.SDDetailThumb <> invalid then
        m.metadata.SDPosterUrl = m.metadata.SDDetailThumb
        m.metadata.HDPosterUrl = m.metadata.HDDetailThumb
        m.thumbnailsToReset.Push(m.metadata)
    end if

    Debug("Setting video springboard screen content")
	m.Screen.setContent(m.metadata)

    m.Screen.AllowUpdates(false)
    m.SetupButtons()
    m.Screen.AllowUpdates(true)
    if m.metadata.SDPosterURL <> invalid and m.metadata.HDPosterURL <> invalid then
        m.Screen.PrefetchPoster(m.metadata.SDPosterURL, m.metadata.HDPosterURL)
        'SaveImagesForScreenSaver(m.metadata, ImageSizes(m.metadata.ViewGroup, m.metadata.Type))
    endif

	Debug("Showing video springboard screen")
    m.Screen.Show()
End Function

Function TimeDisplay(intervalInSeconds) As String
    hours = fix(intervalInSeconds/(60*60))
    remainder = intervalInSeconds - hours*60*60
    minutes = fix(remainder/60)
    seconds = remainder - minutes*60
    hoursStr = hours.tostr()
    if hoursStr.len() = 1 then
        hoursStr = "0"+hoursStr
    endif
    minsStr = minutes.tostr()
    if minsStr.len() = 1 then
        minsStr = "0"+minsStr
    endif
    secsStr = seconds.tostr()
    if secsStr.len() = 1 then
        secsStr = "0"+secsStr
    endif
    return hoursStr+":"+minsStr+":"+secsStr
End Function

Function sbGotoNextItem() As Boolean
    if NOT m.AllowLeftRight then return false

    maxIndex = m.Context.Count() - 1
    index = m.CurIndex
    newIndex = index

    if index < maxIndex then
        newIndex = index + 1
    else if m.WrapLeftRight then
        newIndex = 0
    end if

    if index <> newIndex then
	
		newItem = m.Context[newIndex]
		
		if newItem = invalid or newItem.Id = invalid then
			return false
		end if
		
        m.CurIndex = newIndex
        m.Item = m.Context[newIndex]
        m.Refresh()
        return true
    end if

    return false
End Function

Function sbGotoPrevItem() As Boolean
    if NOT m.AllowLeftRight then return false

    maxIndex = m.Context.Count() - 1
    index = m.CurIndex
    newIndex = index

    if index > 0 then
        newIndex = index - 1
    else if m.WrapLeftRight then
        newIndex = maxIndex
    end if

    if index <> newIndex then
        
		newItem = m.Context[newIndex]
		
		if newItem = invalid or newItem.Id = invalid then
			return false
		end if
		
        m.CurIndex = newIndex
        m.Item = m.Context[newIndex]
        m.Refresh()
        return true
    end if

    return false
End Function

Sub sbClearButtons()
    m.buttonCommands = CreateObject("roAssociativeArray")
    m.Screen.ClearButtons()
    m.buttonCount = 0
End Sub

Sub sbAddButton(label, command)
    m.Screen.AddButton(m.buttonCount, label)
    m.buttonCommands[str(m.buttonCount)] = command
    m.buttonCount = m.buttonCount + 1
End Sub

Sub sbAddRatingButton(userRating, rating, command)
    m.Screen.AddRatingButton(m.buttonCount, userRating, rating)
    m.buttonCommands[str(m.buttonCount)] = command
    m.buttonCount = m.buttonCount + 1
End Sub