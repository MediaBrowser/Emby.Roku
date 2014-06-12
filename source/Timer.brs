'** Credit: Plex Roku https://github.com/plexinc/roku-client-public

Function createTimer() As Object
    timer = CreateObject("roAssociativeArray")
    timer.timer = CreateObject("roTimespan")
    timer.PrintElapsedTime = timerPrintElapsedTime
    timer.GetElapsedMillis = timerGetElapsedMillis
    timer.GetElapsedSeconds = timerGetElapsedSeconds
    timer.Mark = timerMark
    timer.SetDuration = timerSetDuration
    timer.IsExpired = timerIsExpired
    timer.RemainingMillis = timerRemainingMillis

    timer.Active = true
    timer.Repeat = false
    timer.DurationMillis = 0
    timer.Name = invalid

    timer.timer.Mark()

    return timer
End Function

Sub timerPrintElapsedTime(msg As String, mark=True As Boolean)
    elapsed = m.timer.TotalMilliseconds()
    Debug(msg + " took: " + tostr(elapsed) + "ms")
    if mark then m.timer.Mark()
End Sub

Function timerGetElapsedMillis() As Integer
    return m.timer.TotalMilliseconds()
End Function

Function timerGetElapsedSeconds() As Integer
    return m.timer.TotalSeconds()
End Function

Sub timerMark()
    m.timer.Mark()
End Sub

Sub timerSetDuration(millis, repeat=false As Boolean)
    m.DurationMillis = millis
    m.Repeat = repeat
End Sub

Function timerIsExpired() As Boolean
    if m.Active then
        if m.timer.TotalMilliseconds() > m.DurationMillis then
            if m.Repeat then
                m.Mark()
            else
                m.Active = false
            end if
            return true
        end if
    end if

    return false
End Function

Function timerRemainingMillis()
    if m.Active then
        remaining = m.DurationMillis - m.timer.TotalMilliseconds()
        if remaining <= 0 then remaining = 1
        return remaining
    end if

    return 0
End Function