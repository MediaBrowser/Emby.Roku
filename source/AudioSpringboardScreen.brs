'** Credit: Plex Roku https://github.com/plexinc/roku-client-public

Function createAudioSpringboardScreen(context, index, viewController) As Dynamic
    obj = createBaseSpringboardScreen(context, index, viewController)

    obj.SetupButtons = audioSetupButtons
    obj.GetMediaDetails = audioGetMediaDetails
    obj.superHandleMessage = obj.HandleMessage
    obj.HandleMessage = audioHandleMessage
    obj.OnTimerExpired = audioOnTimerExpired

    obj.Screen.SetDescriptionStyle("audio")
    obj.Screen.AllowNavRewind(true)
    obj.Screen.AllowNavFastForward(true)

    ' If there isn't a single playable item in the list then the Roku has
    ' been observed to die a horrible death.
    obj.IsPlayable = false
    for i = obj.CurIndex to obj.Context.Count() - 1
        url = obj.Context[i].Url
        if url <> invalid AND url <> "" then
            obj.IsPlayable = true
            obj.CurIndex = i
            obj.Item = obj.Context[i]
            exit for
        end if
    next

    if NOT obj.IsPlayable then
        dialog = createBaseDialog()
        dialog.Title = "Unsupported Format"
        dialog.Text = "None of the audio tracks in this list are in a supported format. Use MP3s for best results."
        dialog.Show()
        return invalid
    end if

    obj.callbackTimer = createTimer()
    obj.callbackTimer.Active = false
    obj.callbackTimer.SetDuration(1000, true)
    viewController.AddTimer(obj.callbackTimer, obj)

    ' Start playback when screen is opened if there's nothing playing
    player = AudioPlayer()
    if NOT player.IsPlaying then
        obj.Playstate = 2
        player.SetContext(obj.Context, obj.CurIndex, obj, true)
        player.Play()
    else if player.ContextScreenID = obj.ScreenID AND player.IsPlaying then
        obj.Playstate = 2
        obj.callbackTimer.Active = true
        obj.Screen.SetProgressIndicatorEnabled(true)
    else
        obj.Playstate = 0
    end if

    if player.ContextScreenID = obj.ScreenID then
        NowPlayingManager().location = "fullScreenMusic"
    end if

    return obj
End Function

Sub audioSetupButtons()
    m.ClearButtons()

    if NOT m.IsPlayable then return

    if m.Playstate = 2 then
        m.AddButton("pause playing", "pause")
        m.AddButton("stop playing", "stop")
    else if m.Playstate = 1 then
        m.AddButton("resume playing", "resume")
        m.AddButton("stop playing", "stop")
    else
        m.AddButton("start playing", "play")
    end if

    if m.Context.Count() > 1 then
        m.AddButton("next song", "next")
        m.AddButton("previous song", "prev")
    end if

    if m.metadata.UserRating = invalid then
        m.metadata.UserRating = 0
    endif
    if m.metadata.StarRating = invalid then
        m.metadata.StarRating = 0
    endif

    m.AddButton("more...", "more")
End Sub

Sub audioGetMediaDetails(content)
    m.metadata = content
    m.media = invalid
End Sub

Function audioHandleMessage(msg) As Boolean
    handled = false

    player = AudioPlayer()

    if type(msg) = "roSpringboardScreenEvent" then
        if msg.isButtonPressed() then
            handled = true
            buttonCommand = m.buttonCommands[str(msg.getIndex())]
            Debug("Button command: " + tostr(buttonCommand))
            if buttonCommand = "play" then
                player.SetContext(m.Context, m.CurIndex, m, true)
                player.Play()
            else if buttonCommand = "resume" then
                player.Resume()
            else if buttonCommand = "pause" then
                player.Pause()
            else if buttonCommand = "stop" then
                player.Stop()

                ' There's no audio player event for stop, so we need to do some
                ' extra work here.
                m.Playstate = 0
                m.callbackTimer.Active = false
                m.SetupButtons()
            else if buttonCommand = "next" then
                if m.GotoNextItem() then
                    player.Next()
                end if
            else if buttonCommand = "prev" then
                if m.GotoPrevItem() then
                    player.Prev()
                end if
            else if buttonCommand = "more" then
                dialog = createBaseDialog()
                dialog.Title = ""
                dialog.Text = ""
                dialog.Item = m.metadata
                if m.IsShuffled then
                    dialog.SetButton("shuffle", "Shuffle: On")
                else
                    dialog.SetButton("shuffle", "Shuffle: Off")
                end if

                if player.ContextScreenID = m.ScreenID then
                    if player.Repeat = 2 then
                        dialog.SetButton("loop", "Loop: On")
                    else
                        dialog.SetButton("loop", "Loop: Off")
                    end if
                end if

                dialog.SetButton("rate", "_rate_")
                
				dialog.SetButton("close", "Back")
                dialog.HandleButton = audioDialogHandleButton
                dialog.ParentScreen = m
                dialog.Show()
            else
                handled = false
            end if
            m.SetupButtons()
        else if msg.isRemoteKeyPressed() then
            handled = true
            button = msg.GetIndex()
            Debug("Remote Key button = " + tostr(button))

            if button = 5 or button = 9 ' next
                if m.GotoNextItem() then
                    player.Next()
                end if
            else if button = 4 or button = 8 ' prev
                if m.GotoPrevItem() then
                    player.Prev()
                end if
            end if
            m.SetupButtons()
        end if
    else if type(msg) = "roAudioPlayerEvent" AND player.ContextScreenID = m.ScreenID then
        if msg.isRequestSucceeded() then
            m.GotoNextItem()
        else if msg.isRequestFailed() then
            m.GotoNextItem()
        else if msg.isListItemSelected() then
            m.CurIndex = player.CurIndex
            m.Item = m.Context[m.CurIndex]
            m.Refresh(true)
            m.callbackTimer.Active = true
            m.Playstate = 2

            m.SetupButtons()
            if m.metadata.Duration <> invalid then
                m.Screen.SetProgressIndicator(0, m.metadata.Duration)
                m.Screen.SetProgressIndicatorEnabled(true)
            else
                m.Screen.SetProgressIndicatorEnabled(false)
            end if
        else if msg.isStatusMessage() then
            'Debug("Audio player status: " + tostr(msg.getMessage()))
        else if msg.isFullResult() then
            Debug("Playback of entire list finished")
            m.Playstate = 0
            m.Refresh(false)
        else if msg.isPartialResult() then
            Debug("isPartialResult")
        else if msg.isPaused() then
            m.Playstate = 1
            m.callbackTimer.Active = false
            m.SetupButtons()
        else if msg.isResumed() then
            m.Playstate = 2
            m.callbackTimer.Active = true
            m.SetupButtons()
        end if
    end if

    return handled OR m.superHandleMessage(msg)
End Function

Sub audioOnTimerExpired(timer)
    if m.Playstate = 2 AND m.metadata.Duration <> invalid then
        m.Screen.SetProgressIndicator(AudioPlayer().GetPlaybackProgress(), m.metadata.Duration)
    end if
End Sub

Function audioDialogHandleButton(command, data) As Boolean
    ' We're evaluated in the context of the dialog, but we want to be in
    ' the context of the original screen.
    obj = m.ParentScreen
    player = AudioPlayer()

    if command = "shuffle" then
        if obj.IsShuffled then
            obj.Unshuffle()
            obj.IsShuffled = false
            m.SetButton(command, "Shuffle: Off")
        else
            obj.Shuffle()
            obj.IsShuffled = true
            m.SetButton(command, "Shuffle: On")
        end if
        m.Refresh()

        if player.ContextScreenID = obj.ScreenID
            player.SetContext(obj.Context, obj.CurIndex, obj, false)
        end if
    else if command = "loop" then
        if player.Repeat = 2 then
            m.SetButton(command, "Loop: Off")
            player.SetRepeat(0)
        else
            m.SetButton(command, "Loop: On")
            player.SetRepeat(2)
        end if
        m.Refresh()
		
    else if command = "rate" then
        Debug("audioHandleMessage:: Rate audio for key " + tostr(obj.metadata.ratingKey))
        rateValue% = (data /10)
        obj.metadata.UserRating = data
        if obj.metadata.ratingKey <> invalid then
            obj.Item.server.Rate(obj.metadata.ratingKey, obj.metadata.mediaContainerIdentifier, rateValue%.ToStr())
        end if
    else if command = "close" then
        return true
    end if
    return false
End Function