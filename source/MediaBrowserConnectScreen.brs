Function createConnectSignInScreen(viewController As Object) As Object
    obj = CreateObject("roAssociativeArray")
    initBaseScreen(obj, viewController)

    screen = CreateObject("roCodeRegistrationScreen")
    screen.SetMessagePort(obj.Port)

    screen.SetTitle("Emby Connect")
    screen.AddParagraph("With Emby Connect you can easily access your Emby Server wherever you are and share with your family and friends.")
    screen.AddParagraph(" ")
    screen.AddFocalText("From your computer,", "spacing-dense")
    screen.AddFocalText("go to emby.media/pin", "spacing-dense")
    screen.AddFocalText("and enter this code:", "spacing-dense")
    screen.SetRegistrationCode("retrieving code...")
    screen.AddParagraph(" ")
    screen.AddParagraph("This screen will automatically update once your Roku player has been linked to your Emby account.")

    screen.AddButton(0, "get a new code")
    screen.AddButton(1, "skip (connect to server manually)")

    ' Set standard screen properties/methods
    obj.Screen = screen
    obj.Show = pinShow
    obj.HandleMessage = pinHandleMessage
    obj.OnUrlEvent = pinOnUrlEvent
    obj.OnTimerExpired = pinOnTimerExpired
    obj.ScreenName = "EmbyConnect"

    obj.pinResult = invalid

    return obj
End Function

Sub pinShow()
    m.Screen.Show()

    context = CreateObject("roAssociativeArray")
    context.requestType = "pin"

    startPinHttpRequest(m, context)

    ' Create a timer for polling to see if the code has been linked.
    m.timer = createTimer()
    m.timer.Name = "poll"
    m.timer.SetDuration(5000, true)
    m.ViewController.AddTimer(m.timer, m)
End Sub

Function pinHandleMessage(msg) As Boolean
    handled = false

    if type(msg) = "roCodeRegistrationScreenEvent" then
        handled = true

        if msg.isScreenClosed() then
            m.ViewController.PopScreen(m)
			
        else if msg.isButtonPressed()
		
            if msg.GetIndex() = 0 then
			
                ' Get new code
                m.Screen.SetRegistrationCode("retrieving code...")
                context = CreateObject("roAssociativeArray")
				context.requestType = "pin"

				startPinHttpRequest(m, context)
				
            else if msg.GetIndex() = 1 then
			
				facade = CreateObject("roOneLineDialog")
				facade.SetTitle("Please wait...")
				facade.ShowBusyAnimation()
				facade.Show()

				result = ConnectionManager().connectInitial()

				facade.Close()
				
				' Don't get stuck in a loop and keep coming back here
				if result.State = "ConnectSignIn" then result.State = "ServerSelection"
				
				navigateFromConnectionResult(result)
				
            else
                m.Screen.Close()
            end if
			
        end if
    end if

    return handled
End Function

Sub pinOnUrlEvent(msg, requestContext)

    if requestContext.requestType = "pin" then
        if msg.GetResponseCode() <> 200 then
            Debug("Request for new PIN failed: " + tostr(msg.GetResponseCode()) + " - " + tostr(msg.GetFailureReason()))
            dialog = createBaseDialog()
            dialog.Title = "Server unavailable"
            dialog.Text = "Emby Connect could not be reached, please try again later."
            dialog.Show()
			
        else
		
            m.pinResult = ParseJSON(msg.GetString())
			
            m.Screen.SetRegistrationCode(m.pinResult.Pin)
			
			m.timer.Active = true
			
        end if
		
    else if requestContext.requestType = "poll" then
	
        if msg.GetResponseCode() = 200 then
		
			pollResultString = msg.GetString()
			Debug("Poll result: " + pollResultString)
			pollResult = ParseJSON(pollResultString)
			
			if pollResult.IsExpired = true then
			
				Debug("Expiring PIN, server response was " + tostr(msg.GetResponseCode()))
				m.Screen.SetRegistrationCode("code expired")
				m.pinResult = invalid
			
			else if pollResult.IsConfirmed = true then
			
				Debug("Pin confirmed")
				
				onPinConfirmed(m.pinResult, m, m.timer)
				
			end if
			
        else
            ' Just treat the failure as expired (being lazy here)
			Debug("Expiring PIN, server response was " + tostr(msg.GetResponseCode()))
            m.Screen.SetRegistrationCode("code expired")
            m.pinResult = invalid
        end if
		
    else if requestContext.requestType = "exchange" then
	
        if msg.GetResponseCode() = 200 then
		
			exchangeResult = ParseJSON(msg.GetString())
			
			RegWrite("connectUserId", exchangeResult.UserId)
			RegWrite("connectAccessToken", exchangeResult.AccessToken)
			
			onPinExchanged(m)
			
        else
            ' Just treat the failure as expired (being lazy here)
			Debug("Expiring PIN, server response was " + tostr(msg.GetResponseCode()))
            m.Screen.SetRegistrationCode("code expired")
            m.pinResult = invalid
        end if
		
    end if
	
End Sub

Sub onPinExchanged(connectScreen)

	facade = CreateObject("roOneLineDialog")
	facade.SetTitle("Please wait...")
	facade.ShowBusyAnimation()
	facade.Show()

	result = ConnectionManager().connectInitial()
	
	' Don't get stuck in a loop and keep coming back here
	if result.State = "ConnectSignIn" then
		result.State = "ServerSelection"
	end if
					
	facade.Close()
	
	connectScreen.Screen.Close()
	
	navigateFromConnectionResult(result)

End Sub

Sub onPinConfirmed(pinResult, listener, timer)

	timer.Active = false
	
	request = ConnectionManager().getPinExchangeHttpRequest(pinResult)
	
	body = "deviceId=" + getGlobalVar("rokuUniqueId", "Unknown") + "&pin=" + pinResult.Pin
	
	context = CreateObject("roAssociativeArray")
	context.requestType = "exchange"

	GetViewController().StartRequest(request, listener, context, body, "post")

End Sub

Sub pinOnTimerExpired(timer)
    if m.pinResult <> invalid then
	
        context = CreateObject("roAssociativeArray")
        context.requestType = "poll"
		
		startPinPollHttpRequest(m.pinResult, m, context)
		
    end if
End Sub

Sub startPinHttpRequest(listener, context)

	request = ConnectionManager().getPinCreationHttpRequest()
	
	body = "deviceId=" + getGlobalVar("rokuUniqueId", "Unknown")
	
	GetViewController().StartRequest(request, listener, context, body, "post")

End Sub

Sub startPinPollHttpRequest(pinResult, listener, context)

	request = ConnectionManager().getPinStatusHttpRequest(pinResult)
	
	GetViewController().StartRequest(request, listener, context, invalid, "get")
	
End Sub