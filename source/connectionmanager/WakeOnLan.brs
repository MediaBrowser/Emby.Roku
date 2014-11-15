'** Credit: Rarflix https://github.com/ljunkie/rarflix

Sub mgrSendWolToAllServers(screen = invalid)

	for each server in m.GetSavedServerList()
	
		m.SendWol(server.Id, screen)
		
	end for
	
End Sub

Sub mgrSendWol(machineID as String, screen=invalid)

    if machineID <> invalid then
        numReqToSend = 5

        mac = m.GetServerData(machineID, "MacAddress")

        if mac = invalid then return

        ' Broadcasting to 255.255.255.255 only works on some Rokus, but we
        ' can't reliably determine the broadcast address for our current
        ' interface. Try assuming a /24 network - we may need a toggle to 
        ' override the broadcast address

        ip = invalid
        subnetRegex = CreateObject("roRegex", "((\d+)\.(\d+)\.(\d+)\.)(\d+)", "")
        addr = GetFirstIPAddress()
        if addr <> invalid then
            match = subnetRegex.Match(addr)
            if match.Count() > 0 then
                ip = match[1] + "255"
                Debug("Using broadcast address " + ip)
            end if
        end if

        if ip = invalid then return

        ' only send the broadcast 5 (numReqToSend) times per requested mac address
        WOLcounterKey = "WOLCounter" + tostr(mac)
        if GetGlobalAA().lookup(WOLcounterKey) = invalid then GetGlobalAA().AddReplace(WOLcounterKey, 0)
        GetGlobalAA()[WOLcounterKey] = GetGlobalAA().[WOLcounterKey]  + 1

        ' return if we have already send enough requests
        if GetGlobalAA()[WOLcounterKey] > numReqToSend then 
            Debug(tostr(GetGlobalAA()[WOLcounterKey]) + " WOL requests have already been sent")
            GetGlobalAA().AddReplace(WOLcounterKey, 0)
            return
        end if

        ' Get our secure on pass
        pass = m.GetServerData(machineID, "WOLPass")
        if pass = invalid or Len(pass) <> 12 then pass = "ffffffffffff"
               
        header = "ffffffffffff"
        For k=1 To 16
            header = header + mac
        End For
        
        'Append our SecureOn password
        header = header + pass
        Debug ("SendWOL:: header " + tostr(header))
        
        port = CreateObject("roMessagePort")
        addr = CreateObject("roSocketAddress")
        udp = CreateObject("roDatagramSocket")
        packet = CreateObject("roByteArray")
        udp.setMessagePort(port)
        udp.setBroadcast(true)
      
        addr.setHostname(ip)
        addr.setPort(9)
        udp.setSendToAddress(addr)
        
        packet.fromhexstring(header)
        udp.notifyReadable(true)
        sent = udp.send(packet,0,108)
        Debug ("SendWOL:: Sent Magic Packet of " + tostr(sent) + " bytes to " + ip )
        udp.close()
        
        ' no more need for sleeping 'Sleep(100) -- timer will take care re-requesting the data
        if GetGlobalAA()[WOLcounterKey] <= numReqToSend then m.SendWol(machineID, screen)

        ' add timer to create requests again (only if we made this request from the Home Screen)
        if screen <> invalid and screen.ScreenName = "Home" then 
            if screen.WOLtimer = invalid then 
                Debug("Created WOLtimer to refresh home screen data")
                screen.WOLtimer = createTimer()
                screen.WOLtimer.Name = "WOLsent"
                screen.WOLtimer.SetDuration(3*1000, false) ' 3 second time ( we will try 3 times )
                GetViewController().AddTimer(screen.WOLtimer, screen) 
            end if
            ' mark the request - we send multiple, so reset timer
            screen.WOLtimer.mark()
        end if

    end if
End Sub