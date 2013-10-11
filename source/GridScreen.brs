'**********************************************************
'**  Media Browser Roku Client - Grid Screen
'**********************************************************


Function CreateGridScreen(lastLocation As String, currentLocation As String, style As String) As Object

    ' Setup Border
    if style = "two-row-flat-landscape-custom" then
        app = CreateObject("roAppManager")
        app.SetThemeAttribute("GridScreenFocusBorderHD", "pkg:/images/grid/hd-border-flat-landscape.png")
        app.SetThemeAttribute("GridScreenBorderOffsetHD", "-34,-19")
    else if style = "mixed-aspect-ratio" then
        app = CreateObject("roAppManager")
        app.SetThemeAttribute("GridScreenFocusBorderHD", "pkg:/images/grid/hd-border-portrait.png")
        app.SetThemeAttribute("GridScreenBorderOffsetHD", "-25,-35")
    end if

    ' Setup Screen
    o = CreateObject("roAssociativeArray")

    port = CreateObject("roMessagePort")
    grid = CreateObject("roGridScreen")
    grid.SetMessagePort(port)

    ' Setup Common Items
    o.Screen                = grid
    o.Port                  = port
    o.AddRow                = AddGridRow
    o.ShowNames             = ShowGridNames
    o.AddRowContent         = AddGridRowContent
    o.UpdateRowContent      = UpdateGridRowContent
    o.LoadRowContent        = LoadGridRowContent
    o.SetDescriptionVisible = ShowGridDescriptionBox
    o.SetListPosterStyles   = SetGridPosterStyles
    o.SetFocusedListItem    = SetGridFocusedItem
    o.Show                  = ShowGridScreen

    o.rowNames              = []
    o.rowStyles             = []
    o.rowContent            = []
    o.rowLoadedCount        = []
    o.rowFinishedLoading    = []
    o.rowPageSize           = 100
    o.rowPageEdge           = 25

    ' Set Breadcrumbs
    o.Screen.SetBreadcrumbText(lastLocation, currentLocation)

    ' Setup Display Style
    o.Screen.SetGridStyle(style)
    o.Screen.SetDisplayMode("scale-to-fit")

    Return o
End Function


'**********************************************************
'** Add Grid Row Titles
'**********************************************************

Function AddGridRow(title As String, rowStyle As String) As Boolean

    m.rowNames.push(title)

    If rowStyle = "portrait" Then
        m.rowStyles.push( "portrait" )
    Else
        m.rowStyles.push( "landscape" )
    End If

    Return true
End Function


'**********************************************************
'** Show Grid Row Titles
'**********************************************************

Function ShowGridNames()
    m.screen.SetupLists(m.rowNames.Count())
    m.screen.SetListNames(m.rowNames)
End Function


'**********************************************************
'** Add Grid Row Content (Hide if no content)
'**********************************************************

Function AddGridRowContent(rowData) As Boolean
    if rowData = invalid then rowData = []

    m.rowContent.push(rowData)

    rowIndex = m.rowContent.Count() - 1

    m.screen.SetContentList(rowIndex, rowData)

    if rowData.Count() = 0 then
        m.screen.SetListVisible(rowIndex, false)
    end if

    return true
End Function


'**********************************************************
'** Update Grid Row Content (Hide if no content)
'**********************************************************

Function UpdateGridRowContent(rowIndex As Integer, rowData As Object) As Boolean

    m.rowContent[rowIndex] = rowData

    m.screen.SetContentList(rowIndex, rowData)

    If rowData.Count() = 0 Then
        m.screen.SetListVisible(rowIndex, false)
    End If

    Return true
End Function


'**********************************************************
'** Load Grid Row Content (Hide if no content)
'**********************************************************

Function LoadGridRowContent(rowIndex, rowData, offset, limit) As Boolean
    if rowData = invalid then
        rowData = {}
        rowData.Items = []
        rowData.TotalCount = 0
    end if

    ' Fill In Missing Items If Not 0
    if offset <> 0 then
        for i = 0 to rowData.Items.Count() - 1
            m.rowContent[rowIndex][offset + i] = rowData.Items[i]
        end for
    else
        m.rowContent.push(rowData.Items)
    end if

    ' Setup Row Loaded count
    if m.rowLoadedCount[rowIndex] = invalid then m.rowLoadedCount[rowIndex] = 0

    Debug("Loading On Row " + itostr(rowIndex) + ": " + itostr(offset+1) + " - " + itostr(offset+limit) + " of " + itostr(rowData.TotalCount) + "; Currently Loaded: " + itostr(m.rowLoadedCount[rowIndex]))

    ' Add Current Row Size
    m.rowLoadedCount[rowIndex] = m.rowLoadedCount[rowIndex] + rowData.Items.Count()

    ' Hide Row if No Data
    if m.rowLoadedCount[rowIndex] = 0
        Print "No Data For Row: "; rowIndex
        m.screen.SetListVisible(rowIndex, false)
        m.rowFinishedLoading[rowIndex] = true
        return true
    end if

    ' Handle Size of Row Counter
    if m.rowContent[rowIndex].Count() < rowData.TotalCount And offset = 0
        lastIndex = rowData.TotalCount - 1
        m.rowContent[rowIndex][lastIndex] = {title: "Loading..."}
    end if

    if m.rowLoadedCount[rowIndex] >= rowData.TotalCount
        m.screen.SetContentList(rowIndex, m.rowContent[rowIndex])
        m.rowFinishedLoading[rowIndex] = true
        Print "Loading All Data For Row: "; rowIndex

    else
        m.screen.SetContentListSubset(rowIndex, m.rowContent[rowIndex], offset, limit)
        m.rowFinishedLoading[rowIndex] = false
        Print "Loading Partial Data For Row: "; rowIndex

    end if
    
    Return true
End Function


'**********************************************************
'** Show Grid Description Box
'**********************************************************

Function ShowGridDescriptionBox(visible)
    m.screen.SetDescriptionVisible(visible)
End Function


'**********************************************************
'** Set Grid Poster Styles
'**********************************************************

Function SetGridPosterStyles(styles As Object)
    'm.screen.SetListPosterStyles(styles)
End Function


'**********************************************************
'** Set Grid Focused List Item
'**********************************************************

Function SetGridFocusedItem(listIndex As Integer, itemIndex As Integer)
    m.screen.SetFocusedListItem(listIndex, itemIndex)
End Function


'**********************************************************
'** Show Grid Screen
'**********************************************************

Function ShowGridScreen()
    m.screen.Show()
End Function


'**********************************************************
'** Find Closest Letter with Data
'**********************************************************

Function FindClosestLetter(letter As String, metadata As Object) As String
    letters = ["a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"]

    ' If Data exists, just return the letter
    If metadata.jumpList.DoesExist(letter) Then
        return letter
    End If

    ' Determine the index of the letter
    index = 0
    letterIndex = 0

    For Each cLetter In letters
        If cLetter = letter Then
            letterIndex = index
            Exit For
        End If
        index = index + 1
    End For

    ' Find closest letter with data incrementing
    For i=letterIndex To 25
        If metadata.jumpList.DoesExist(letters[i]) Then
            return letters[i]
        End If
    End For

    ' Find closest letter with data decreasing
    For i=letterIndex To 0 Step -1
        If metadata.jumpList.DoesExist(letters[i]) Then
            return letters[i]
        End If
    End For

    return invalid
End Function


'**********************************************************
'** Create the Jump List Dialog
'**********************************************************

Function CreateJumpListDialog()

    ' Setup Screen
    port = CreateObject("roMessagePort")
    canvas = CreateObject("roImageCanvas")
    canvas.SetMessagePort(port)

    ' Center Dialog
    canvasRect = canvas.GetCanvasRect()

    dlgRect = {x: 0, y: 0, w: 700, h: 300}
    dlgRect.x = int((canvasRect.w - dlgRect.w) / 2)
    dlgRect.y = int((canvasRect.h - dlgRect.h) / 2)

    ' Build Dialog
    list = []
    selectedIndex = 0
    selectedRow = 0

    ' Letters List
    letters = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"]
    lettersLower = ["a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"]
    positions = GetAlphabetPositions()

    ' Dialog Background
    dialogBackground = {
        url: "pkg:/images/jumplist/dialog.png"
        TargetRect: dlgRect
    }

    ' Instruction Text
    list.Push({
        Text:  "Jump To Letter:"
        TextAttrs: { font: "small", color: "#303030", halign: "center", valign: "top" }
        TargetRect: {x: 300, y: 250, w: 200, h: 60}
    })

    ' Alphabet
    For i=0 To 12
        list.Push({
            Text:  letters[i]
            TextAttrs: { font: "huge", color: "#303030", halign: "center", valign: "middle" }
            TargetRect: positions[0][i]
        })
    End For

    For i=0 To 12
        list.Push({
            Text:  letters[i+13]
            TextAttrs: { font: "huge", color: "#303030", halign: "center", valign: "middle" }
            TargetRect: positions[1][i]
        })
    End For

    ' Selected Letter Box
    selectedLetter = {
        url: "pkg:/images/jumplist/box.png",
        TargetRect: {x: positions[selectedRow][selectedIndex].x-5, y: positions[selectedRow][selectedIndex].y-9, w: 60, h: 60}
    }            

    ' Show Dialog
    canvas.SetLayer(0, { Color: "#00000000", CompositionMode: "Source_Over" })
    canvas.SetLayer(1, dialogBackground)
    canvas.SetLayer(2, list)
    canvas.SetLayer(3, selectedLetter)
    canvas.Show()

    canvas.AllowUpdates(true)

    ' Remote key id's for navigation
    remoteKeyBack   = 0
    remoteKeyUp     = 2
    remoteKeyDown   = 3
    remoteKeyLeft   = 4
    remoteKeyRight  = 5
    remoteKeyOK     = 6
    
    While true
        msg = wait(0, port)

        If type(msg) = "roImageCanvasEvent" Then

            If msg.isRemoteKeyPressed()
                index = msg.GetIndex()

                If index = remoteKeyBack Then
                    canvas.Close()
                    return invalid
                Else If index = remoteKeyOK Then
                    canvas.Close()
                    If selectedRow = 1 Then
                        return lettersLower[selectedIndex+13]
                    Else
                        return lettersLower[selectedIndex]
                    End If

                Else If index = remoteKeyLeft Then
                    selectedIndex = selectedIndex-1
                    If selectedIndex < 0
                        selectedIndex = 0
                    End if

                Else If index = remoteKeyRight Then
                    selectedIndex = selectedIndex+1
                    If selectedIndex > 12
                        selectedIndex = 12
                    End if

                Else If index = remoteKeyUp Then
                    selectedRow = selectedRow-1
                    If selectedRow < 0
                        selectedRow = 0
                    End if

                Else If index = remoteKeyDown Then
                    selectedRow = selectedRow+1
                    If selectedRow > 1
                        selectedRow = 1
                    End If

                ' Handle Remote Keyboards
                Else if index > 64 and index < 91 then
                    return LCase(chr(index))

                Else If index > 97 and index < 123 then
                    return chr(index)

                End If

                ' Rebuild Dialog Screen
                selectedLetter.TargetRect = {x: positions[selectedRow][selectedIndex].x-5, y: positions[selectedRow][selectedIndex].y-9, w: 60, h: 60}

                canvas.SetLayer(0, { Color: "#00000000", CompositionMode: "Source_Over" })
                canvas.SetLayer(1, dialogBackground)
                canvas.SetLayer(2, list)
                canvas.SetLayer(3, selectedLetter)                

            End If       
            
        End If
    End While

    return invalid
End Function


'**********************************************************
'** Get the position of letters for jump list
'**********************************************************

Function GetAlphabetPositions() As Object
    posArray = []
    rowOneArray = []
    rowTwoArray = []

    ' A-M
    rowOneArray.Push({x: 310, y: 300, w: 50, h: 50}) ' A
    rowOneArray.Push({x: 360, y: 300, w: 50, h: 50}) ' B
    rowOneArray.Push({x: 410, y: 300, w: 50, h: 50}) ' C
    rowOneArray.Push({x: 460, y: 300, w: 50, h: 50}) ' D
    rowOneArray.Push({x: 510, y: 300, w: 50, h: 50}) ' E
    rowOneArray.Push({x: 560, y: 300, w: 50, h: 50}) ' F
    rowOneArray.Push({x: 610, y: 300, w: 50, h: 50}) ' G
    rowOneArray.Push({x: 660, y: 300, w: 50, h: 50}) ' H
    rowOneArray.Push({x: 710, y: 300, w: 50, h: 50}) ' I
    rowOneArray.Push({x: 760, y: 300, w: 50, h: 50}) ' J
    rowOneArray.Push({x: 810, y: 300, w: 50, h: 50}) ' K
    rowOneArray.Push({x: 860, y: 300, w: 50, h: 50}) ' L
    rowOneArray.Push({x: 910, y: 300, w: 50, h: 50}) ' M

    posArray[0] = rowOneArray

    ' N-Z
    rowTwoArray.Push({x: 310, y: 380, w: 50, h: 50}) ' N
    rowTwoArray.Push({x: 360, y: 380, w: 50, h: 50}) ' O
    rowTwoArray.Push({x: 410, y: 380, w: 50, h: 50}) ' P
    rowTwoArray.Push({x: 460, y: 380, w: 50, h: 50}) ' Q
    rowTwoArray.Push({x: 510, y: 380, w: 50, h: 50}) ' R
    rowTwoArray.Push({x: 560, y: 380, w: 50, h: 50}) ' S
    rowTwoArray.Push({x: 610, y: 380, w: 50, h: 50}) ' T
    rowTwoArray.Push({x: 660, y: 380, w: 50, h: 50}) ' U
    rowTwoArray.Push({x: 710, y: 380, w: 50, h: 50}) ' V
    rowTwoArray.Push({x: 760, y: 380, w: 50, h: 50}) ' W
    rowTwoArray.Push({x: 810, y: 380, w: 50, h: 50}) ' X
    rowTwoArray.Push({x: 860, y: 380, w: 50, h: 50}) ' Y
    rowTwoArray.Push({x: 910, y: 380, w: 50, h: 50}) ' Z

    posArray[1] = rowTwoArray

    return posArray
End Function
