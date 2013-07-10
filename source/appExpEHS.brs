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

    ' Initialize Content Rows
    m.rowContent = []
    m.rowContent[0] = []
    m.rowContent[1] = []
    m.rowContent[2] = []
    m.rowContent[3] = []

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
                    ' Check Bounds
                    selectedIndex = CheckBounds(selectedRow, selectedIndex, "LEFT")
                    rowIndexes[selectedRow] = selectedIndex

                Else If index = remoteKeyRight Then
                    ' Move To Row 1, Column 3 For Large Tile
                    If (selectedRow = 1 Or selectedRow = 2) And (selectedIndex = 0 Or selectedIndex = 1)
                        selectedIndex = 2
                        selectedRow = 1
                    Else
                        ' Check Bounds
                        selectedIndex = CheckBounds(selectedRow, selectedIndex, "RIGHT")
                    End If

                    rowIndexes[selectedRow] = selectedIndex

                Else If index = remoteKeyUp Then

                    ' Handle Large Tile
                    If (selectedRow = 1 Or selectedRow = 2) And (selectedIndex = 0 Or selectedIndex = 1)
                        selectedRow = 0
                    Else
                        ' Check Bounds
                        selectedRow = CheckBounds(selectedRow, selectedIndex, "UP")
                    End If

                    If selectedRow = 0 Then
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

                    ' Handle Large Tile
                    If (selectedRow = 1 Or selectedRow = 2) And (selectedIndex = 0 Or selectedIndex = 1)
                        If m.rowContent[3].Count() > 0 Then
                            selectedIndex = 0
                            selectedRow = 3
                        End If
                    Else
                        ' Check Bounds
                        selectedRow = CheckBounds(selectedRow, selectedIndex, "DOWN")
                    End If

                    ' Reset row index to 0
                    rowIndexes[selectedRow] = 0

                Else If index = remoteKeyOK Then

                    If m.rowContent[selectedRow][selectedIndex].ContentType = "MovieLibrary" Then
                        ShowMoviesListPage()

                    Else If m.rowContent[selectedRow][selectedIndex].ContentType = "Movie" Then
                        ShowMoviesDetailPage(m.rowContent[selectedRow][selectedIndex].Id)

                    Else If m.rowContent[selectedRow][selectedIndex].ContentType = "TVLibrary" Then
                        ShowTVShowListPage()

                    Else If m.rowContent[selectedRow][selectedIndex].ContentType = "Episode" Then
                        ShowTVDetailPage(m.rowContent[selectedRow][selectedIndex].Id)

                    Else If m.rowContent[selectedRow][selectedIndex].ContentType = "MusicLibrary" Then
                        ShowAltMusicListPage()

                    End If

                End If





                If selectedRow = 0 And selectedIndex = 0 Then
                    mainBodyArea = BuildMoviesArea()

                    ' ReDraw Main Area
                    canvas.SetLayer(4, mainBodyArea)

                Else If selectedRow = 0 And selectedIndex = 1 Then
                    mainBodyArea = BuildTVArea()

                    ' ReDraw Main Area
                    canvas.SetLayer(4, mainBodyArea)

                Else If selectedRow = 0 And selectedIndex = 2 Then
                    mainBodyArea = BuildMusicArea()

                    ' ReDraw Main Area
                    canvas.SetLayer(4, mainBodyArea)

                Else If selectedRow = 0 And selectedIndex = 3 Then
                    mainBodyArea = BuildMediaCollectionsArea()

                    ' ReDraw Main Area
                    canvas.SetLayer(4, mainBodyArea)

                End If

                ' ReDraw Main Menu with underline
                If selectedRow = 0 Then
                    mainMenuArea = BuildMainMenuArea(canvas, selectedIndex, true)
                    canvas.SetLayer(3, mainMenuArea)
                Else
                    'Print "row: "; selectedRow; " column: "; selectedIndex

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
    m.rowContent[1] = []
    m.rowContent[2] = []
    m.rowContent[3] = []

    fontsize = m.FontRegistry.Get("Default", 16, false, false)

    moviesList.Push({
        Text:  "What's New"
        TextAttrs: { font: fontsize, color: "#ffffff", halign: "left" }
        TargetRect: {x: 126, y: 165, w: 120, h: 50}
    })


    ' Large Tile
    moviesList.Append( BuildImageBox("pkg:/images/ehs/largeTest.jpg", 126, 210, 509, 289, "Harry Potter And the Deathly Hallows: Part 2") ) ' Row 1-2, Col 1-2

    m.rowContent[1].Push({name: "All Movies", id: "Movies", ContentType: "MovieLibrary", largeTile: true})
    m.rowContent[1].Push({name: "All Movies", id: "Movies", ContentType: "MovieLibrary", largeTile: true})
    m.rowContent[2].Push({name: "All Movies", id: "Movies", ContentType: "MovieLibrary", largeTile: true})
    m.rowContent[2].Push({name: "All Movies", id: "Movies", ContentType: "MovieLibrary", largeTile: true})


    ' Loop through movies
    movieCount = 0
    For Each movie In recentMovies

        ' Row content of current screen
        currentRow = Int(tileCoords[movieCount].row)
        m.rowContent[currentRow].Push({name: movie.Title, Id: movie.Id, ContentType: movie.ContentType})

        ' Build Tile Boxes
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

    ' Get Latest Unwatched TV Episodes
    recentItems = GetTVRecentAdded()
    If recentItems=invalid
        Return []
    End If

    ' Get Tile Coordinates
    tileCoords = GetTileCoordinates()

    itemsList = []
    m.rowContent[1] = []
    m.rowContent[2] = []
    m.rowContent[3] = []
    pages = []

    fontsize = m.FontRegistry.Get("Default", 16, false, false)

    itemsList.Push({
        Text:  "What's New"
        TextAttrs: { font: fontsize, color: "#ffffff", halign: "left" }
        TargetRect: {x: 126, y: 165, w: 120, h: 50}
    })


    ' Large Tile
    itemsList.Append( BuildImageBox("pkg:/images/ehs/largeTest.jpg", 126, 210, 509, 289, "Harry Potter And the Deathly Hallows: Part 2") ) ' Row 1-2, Col 1-2

    m.rowContent[1].Push({name: "All TV Shows", id: "TV Shows", ContentType: "TVLibrary", largeTile: true})
    m.rowContent[1].Push({name: "All TV Shows", id: "TV Shows", ContentType: "TVLibrary", largeTile: true})
    m.rowContent[2].Push({name: "All TV Shows", id: "TV Shows", ContentType: "TVLibrary", largeTile: true})
    m.rowContent[2].Push({name: "All TV Shows", id: "TV Shows", ContentType: "TVLibrary", largeTile: true})


    ' Loop through movies
    movieCount = 0
    For Each movie In recentItems

        ' Row content of current screen
        currentRow = Int(tileCoords[movieCount].row)
        m.rowContent[currentRow].Push({name: movie.Title, Id: movie.Id, ContentType: movie.ContentType})

        ' Build Tile Boxes
        itemsList.Append( BuildImageBox(movie.HDPosterUrl, tileCoords[movieCount].x, tileCoords[movieCount].y, tileCoords[movieCount].w, tileCoords[movieCount].h, Truncate(movie.Title, 25, true)) )

        movieCount = movieCount + 1
    End For

    Return itemsList
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

    coords.Push({row: 1, x: 640, y: 210, w: 252, h: 142}) ' Tile 1
    coords.Push({row: 1, x: 897, y: 210, w: 252, h: 142}) ' Tile 2
    coords.Push({row: 2, x: 640, y: 357, w: 252, h: 142}) ' Tile 3
    coords.Push({row: 2, x: 897, y: 357, w: 252, h: 142}) ' Tile 4
    coords.Push({row: 3, x: 126, y: 504, w: 252, h: 142}) ' Tile 5
    coords.Push({row: 3, x: 383, y: 504, w: 252, h: 142}) ' Tile 6
    coords.Push({row: 3, x: 640, y: 504, w: 252, h: 142}) ' Tile 7
    coords.Push({row: 3, x: 897, y: 504, w: 252, h: 142}) ' Tile 8

    return coords
End Function

Function CheckBounds(selectedRow, selectedIndex, direction) As Integer

    If direction = "LEFT" Then

        ' Only change if Row has content
        If m.rowContent[selectedRow]<>invalid Then

            boundIndex = selectedIndex-1

            If boundIndex < 0
                boundIndex = 0
            End If

        End If

    Else If direction = "RIGHT" Then

        ' Only change if Row has content
        If m.rowContent[selectedRow]<>invalid Then

            boundIndex = selectedIndex+1

            If boundIndex > m.rowContent[selectedRow].Count() - 1

                boundIndex = m.rowContent[selectedRow].Count() - 1

            End If

        End If

    Else If direction = "UP" Then

        boundIndex = selectedRow-1

        If boundIndex < 0
            boundIndex = 0
        End If

        ' If Row has no content, do not change rows
        If m.rowContent[boundIndex]=invalid Then
            boundIndex = selectedRow
        End If

    Else If direction = "DOWN" Then

        boundIndex = selectedRow+1

        If boundIndex > m.rowContent.Count() - 1 Then
            boundIndex = m.rowContent.Count() - 1
        End If

        If m.rowContent[boundIndex][selectedIndex]=invalid Or m.rowContent[boundIndex].Count() = 0 Then
            boundIndex = selectedRow
        End If

    End If

    Return boundIndex
End Function
