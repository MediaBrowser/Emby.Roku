'*****************************************************************
'**  Media Browser Roku Client - Experimental EHS
'*****************************************************************


'**********************************************************
'** Show Experimental EHS
'**********************************************************

Function ShowExpEHS() As Integer


    ' Setup Screen
    port = CreateObject("roMessagePort")
    canvas = CreateObject("roImageCanvas")
    canvas.SetMessagePort(port)

    m.FontRegistry = CreateObject("roFontRegistry")
    m.rowContent = []

    ' Header Text
    headerStaticArea = BuildHeaderStaticArea()
    headerDynamicArea = BuildHeaderDynamicArea()
    mainMenuArea = BuildMainMenuArea(canvas, 0, true)

    mainBodyArea = BuildMoviesArea()

    ' Get Tile Coordinates
    tileCoords = GetTileCoordinates()

    canvas.SetLayer(0, { Color: "#504B4B", CompositionMode: "Source" })
    canvas.SetLayer(1, headerStaticArea)
    canvas.SetLayer(2, headerDynamicArea)
    canvas.SetLayer(3, mainMenuArea)
    canvas.SetLayer(4, mainBodyArea)

    canvas.Show()

    ' Remote key id's for navigation
    remoteKeyBack   = 0
    remoteKeyUp     = 2
    remoteKeyDown   = 3
    remoteKeyLeft   = 4
    remoteKeyRight  = 5
    remoteKeyOK     = 6

    selectedIndex = 0
    selectedRow = 0
    rowIndexes = []
    rowIndexes[0] = 0


    While true
        msg = wait(10,port)

        if msg = invalid Then

            ' Redraw time
            headerDynamicArea = BuildHeaderDynamicArea()
            canvas.SetLayer(2, headerDynamicArea)

        else if type(msg) = "roImageCanvasEvent" Then
            if msg.isRemoteKeyPressed() then
                index = msg.GetIndex()

                If index = remoteKeyBack Then
                    exit while

                Else If index = remoteKeyLeft Then
                    selectedIndex = selectedIndex-1

                    ' Check Bounds
                    selectedIndex = CheckBounds(selectedRow, selectedIndex)

                    If selectedIndex < 0
                        selectedIndex = 0
                    End If

                    rowIndexes[selectedRow] = selectedIndex

                Else If index = remoteKeyRight Then
                    selectedIndex = selectedIndex+1


                    If selectedIndex > 3
                        selectedIndex = 3
                    End If

                    rowIndexes[selectedRow] = selectedIndex

                Else If index = remoteKeyUp Then
                    selectedRow = selectedRow-1

                    If selectedRow < 0
                        selectedRow = 0
                    End If
                    
                    If selectedRow = 0
                        selectedIndex = rowIndexes[selectedRow]

                        ' Clear Select Box
                        canvas.ClearLayer(5)
                    End If

                Else If index = remoteKeyDown Then
                    ' ReDraw Main Menu Text
                    If selectedRow = 0
                        mainMenuArea = BuildMainMenuArea(canvas, selectedIndex, false)

                        ' Redraw main menu
                        canvas.SetLayer(3, mainMenuArea)
                    End If

                    selectedRow = selectedRow+1
                    If selectedRow > 3
                        selectedRow = 3
                    End If

                    ' Reset row index to 0
                    rowIndexes[selectedRow] = 0
                    
                End If


                If selectedRow = 0 And selectedIndex = 0 Then
                    mainBodyArea = BuildMoviesArea()

                Else If selectedRow = 0 And selectedIndex = 1 Then
                    mainBodyArea = BuildTVArea()

                Else If selectedRow = 0 And selectedIndex = 2 Then
                    mainBodyArea = BuildMusicArea()

                Else If selectedRow = 0 And selectedIndex = 3 Then
                    mainBodyArea = BuildMediaCollectionsArea()

                End If

                ' ReDraw Main Menu with underline
                If selectedRow = 0 Then
                    mainMenuArea = BuildMainMenuArea(canvas, selectedIndex, true)
                    canvas.SetLayer(3, mainMenuArea)
                Else
                    Print "row: "; selectedRow; " column: "; selectedIndex

                    ' Handle Selection

                    ' Large Tile
                    If selectedRow = 1 Then

                        If selectedIndex = 0
                            selectedItem = GetSelectBox(126, 210, "large") ' Large Select Box

                        Else If selectedIndex = 1
                            selectedItem = GetSelectBox(126, 210, "large") ' Large Select Box

                        Else If selectedIndex = 2
                            selectedItem = GetSelectBox(tileCoords[0].x, tileCoords[0].y, "small") ' Select Box

                        Else If selectedIndex = 3
                            selectedItem = GetSelectBox(tileCoords[1].x, tileCoords[1].y, "small") ' Select Box

                        End If

                    Else If selectedRow = 2 Then

                        If selectedIndex = 0
                            selectedItem = GetSelectBox(126, 210, "large") ' Large Select Box

                        Else If selectedIndex = 1
                            selectedItem = GetSelectBox(126, 210, "large") ' Large Select Box

                        Else If selectedIndex = 2
                            selectedItem = GetSelectBox(tileCoords[2].x, tileCoords[2].y, "small") ' Select Box

                        Else If selectedIndex = 3
                            selectedItem = GetSelectBox(tileCoords[3].x, tileCoords[3].y, "small") ' Select Box

                        End If

                    Else If selectedRow = 3 Then
                        If selectedIndex = 0
                            selectedItem = GetSelectBox(tileCoords[4].x, tileCoords[4].y, "small") ' Select Box

                        Else If selectedIndex = 1
                            selectedItem = GetSelectBox(tileCoords[5].x, tileCoords[5].y, "small") ' Select Box

                        Else If selectedIndex = 2
                            selectedItem = GetSelectBox(tileCoords[6].x, tileCoords[6].y, "small") ' Select Box

                        Else If selectedIndex = 3
                            selectedItem = GetSelectBox(tileCoords[7].x, tileCoords[7].y, "small") ' Select Box

                        End If

                    End If

                    ' ReDraw Selected Item
                    canvas.SetLayer(5, selectedItem)

                End If


                ' ReDraw Main Area
                canvas.SetLayer(4, mainBodyArea)


            else if msg.isScreenClosed() Then
                print "Closed"
                exit While
                
            end If

        end if
    End While

    canvas.Close()
    Return 0
End Function


'**********************************************************
'** Header Functions
'**********************************************************

Function BuildHeaderStaticArea() As Object

    headerList = []

    headerList.Push({
        url: "pkg:/images/mblogowhite.png"
        TargetRect: {x: 35, y: 35, w: 302, h: 55}
    })

    Return headerList
End Function


Function BuildHeaderDynamicArea() As Object

    headerList = []

    dateTime = CreateObject("roDateTime")

    ' Localize Time
    dateTime.ToLocalTime()

    hours = dateTime.GetHours()
    period = "am"
    If hours > 11 Then period = "pm"
    If hours > 12 Then hours = hours-12
    If hours = 0 Then hours = 12

    headerList.Push({
        Text:  itostr(hours) + ":" + ZeroPad(itostr(dateTime.GetMinutes())) + " " + period
        TextAttrs: { font: "medium", color: "#ffffff", halign: "center", valign: "top" }
        TargetRect: {x: 1080, y: 35, w: 110, h: 55}
    })

    Return headerList
End Function


Function BuildMainMenuArea(canvas, selectedIndex, showUnderline) As Object

    ' Canvas Size
    canvasRect = canvas.GetCanvasRect()

    categories = []
    categories.Push({name: "movies", id: "movies"})
    categories.Push({name: "television", id: "tv"})
    categories.Push({name: "music", id: "music"})
    categories.Push({name: "media collections", id: "collections"})

    headerText = []
    m.rowContent[0] = []

    headerItemWidth = 200
    headerTotalWidth = headerItemWidth * categories.Count()

    xOffset = int((canvasRect.w - headerTotalWidth) / 2)
    headerCount = 0

    For each category in categories
        m.rowContent[0].Push(category)

        categoryOffset = headerCount * headerItemWidth
        xCoords = xOffset + categoryOffset

        If headerCount = selectedIndex Then
            textColor = "#FFFFFF"
            underlinePosition = {TargetRect: {x: xCoords, y: 150, w: 200, h: 2}, url: "pkg:/images/progressbar/bar.png"}
        Else
            textColor = "#C9C9C9"
        End If

        headerText.Push({
            Text:  category.name
            TextAttrs: { font: "small", color: textColor, halign: "center", valign: "top" }
            TargetRect: {x: xCoords, y: 125, w: headerItemWidth, h: 50}
        })

        headerCount = headerCount + 1
    End For

    If showUnderline
        headerText.Push(underlinePosition)
    End If

    Return headerText
End Function



'**********************************************************
'** Body Functions
'**********************************************************


Function BuildMoviesArea() As Object

    ' Get Latest Unwatched Movies
    recentMovies = GetMoviesRecentAdded()
    If recentMovies=invalid
        Return []
    End If

    ' Get Tile Coordinates
    tileCoords = GetTileCoordinates()

    moviesList = []

    fontsize = m.FontRegistry.Get("Default", 16, false, false)

    moviesList.Push({
        Text:  "What's New >"
        TextAttrs: { font: fontsize, color: "#ffffff", halign: "left" }
        TargetRect: {x: 126, y: 165, w: 120, h: 50}
    })

    ' Large Tile
    moviesList.Append( BuildImageBox("pkg:/images/ehs/largeTest.jpg", 126, 210, 509, 289, "Harry Potter And the Deathly Hallows: Part 2") ) ' Row 1-2, Col 1-2

    ' Loop through movies
    movieCount = 0
    For Each movie In recentMovies

        moviesList.Append( BuildImageBox(movie.HDPosterUrl, tileCoords[movieCount].x, tileCoords[movieCount].y, tileCoords[movieCount].w, tileCoords[movieCount].h, Truncate(movie.Title, 25, true)) )

        movieCount = movieCount + 1
    End For


    'moviesList.Append( BuildImageBox("pkg:/images/home/test1.jpg", 640, 200, 266, 150, "A Good Day to Die Hard") ) ' Row 1, Col 3
    'moviesList.Append( BuildImageBox("pkg:/images/home/test2.jpg", 911, 200, 266, 150, "Silver Linings Playbook") ) ' Row 1, Col 4

    'moviesList.Append( BuildImageBox("pkg:/images/home/test3.jpg", 640, 355, 266, 150, "Superman: Unbound") ) ' Row 2, Col 3
    'moviesList.Append( BuildImageBox("pkg:/images/home/test4.jpg", 911, 355, 266, 150, "Rise of the Guardians") ) ' Row 2, Col 4

    'moviesList.Append( BuildImageBox("pkg:/images/home/test5.jpg", 98, 510, 266, 150, "The Hobbit") ) ' Row 3, Col 1
    'moviesList.Append( BuildImageBox("pkg:/images/home/test6.jpg", 369, 510, 266, 150, "Batman") ) ' Row 3, Col 2
    'moviesList.Append( BuildImageBox("pkg:/images/home/test7.jpg", 640, 510, 266, 150, "Argo") ) ' Row 3, Col 3
    'moviesList.Append( BuildImageBox("pkg:/images/home/test8.jpg", 911, 510, 266, 150, "Captain America") ) ' Row 3, Col 4


    Return moviesList
End Function


Function BuildTVArea() As Object

    moviesList = []

    moviesList.Push({
        url: "pkg:/images/items/collection.png"
        TargetRect: {x: 374, y: 210, w: 533, h: 300}
    })

    moviesList.Push({
        Text:  "TV"
        TextAttrs: { font: "medium", color: "#ffffff", halign: "center", valign: "top" }
        TargetRect: {x: 590, y: 510, w: 100, h: 55}
    })

    Return moviesList
End Function


Function BuildMusicArea() As Object

    moviesList = []

    moviesList.Push({
        url: "pkg:/images/items/collection.png"
        TargetRect: {x: 374, y: 210, w: 533, h: 300}
    })

    moviesList.Push({
        Text:  "Music"
        TextAttrs: { font: "medium", color: "#ffffff", halign: "center", valign: "top" }
        TargetRect: {x: 590, y: 510, w: 100, h: 55}
    })

    Return moviesList
End Function


Function BuildMediaCollectionsArea() As Object

    moviesList = []

    moviesList.Push({
        url: "pkg:/images/items/collection.png"
        TargetRect: {x: 374, y: 210, w: 533, h: 300}
    })

    moviesList.Push({
        Text:  "Media Collections"
        TextAttrs: { font: "medium", color: "#ffffff", halign: "center", valign: "top" }
        TargetRect: {x: 590, y: 510, w: 100, h: 55}
    })

    Return moviesList
End Function


'**********************************************************
'** General Functions
'**********************************************************


Function BuildImageBox(imageUrl, imageX, imageY, imageWidth, imageHeight, overlayText) As Object

    imageBox = []

    imageBox.Push({
        url: imageUrl
        TargetRect: {x: imageX, y: imageY, w: imageWidth, h: imageHeight}
    })

    textYCoords = imageY + imageHeight
    textYCoords = textYCoords - 25

    imageBox.Push({
        url: "pkg:/images/ehs/OverlayBG.png"
        TargetRect: {x: imageX, y: textYCoords, w: imageWidth, h: 25}
    })

    fontsize = m.FontRegistry.Get("Default", 16, false, false)

    imageBox.Push({
        Text: overlayText
        TextAttrs: { font: fontsize, color: "#ffffff", halign: "left"}
        TargetRect: {x: imageX+5, y: textYCoords, w: imageWidth, h: 25}
    })

    Return imageBox
End Function


Function GetSelectBox(imageX, imageY, selectSize) As Object

    If selectSize = "large" Then
        ' Large Select Box
        selectBox = {
            url: "pkg:/images/ehs/SelectBoxLg.png",
            TargetRect: {x: imageX-5, y: imageY-5, w: 519, h: 299}
        }

    Else
        ' Small Select Box
        selectBox = {
            url: "pkg:/images/ehs/SelectBoxSm.png",
            TargetRect: {x: imageX-5, y: imageY-5, w: 262, h: 152}
        }
    End If

    Return selectBox
End Function


Function GetTileCoordinates() As Object
    coords = []

    coords.Push({x: 640, y: 210, w: 252, h: 142}) ' Tile 1
    coords.Push({x: 897, y: 210, w: 252, h: 142}) ' Tile 2
    coords.Push({x: 640, y: 357, w: 252, h: 142}) ' Tile 3
    coords.Push({x: 897, y: 357, w: 252, h: 142}) ' Tile 4
    coords.Push({x: 126, y: 504, w: 252, h: 142}) ' Tile 5
    coords.Push({x: 383, y: 504, w: 252, h: 142}) ' Tile 6
    coords.Push({x: 640, y: 504, w: 252, h: 142}) ' Tile 7
    coords.Push({x: 897, y: 504, w: 252, h: 142}) ' Tile 8

    return coords
End Function

Function CheckBounds(selectedRow, selectedIndex) As Integer

    If m.rowContent[selectedRow]<>invalid Then
        Print "Row "; selectedRow; " has "; m.rowContent[selectedRow].Count(); " items"
    End If

    Return selectedIndex
End Function
