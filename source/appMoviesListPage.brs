'*****************************************************************
'**  Media Browser Roku Client - Movies List Page
'*****************************************************************


'**********************************************************
'** Show Movies List Page
'**********************************************************

Function ShowMoviesListPage() As Integer

    ' Setup Screen
    port   = CreateObject("roMessagePort")
    screen = CreateObject("roGridScreen")
    screen.SetMessagePort(port)

    screen.SetBreadcrumbText("", "Movies")

    ' Determine Display Type
    If RegRead("prefMovieImageType") = "poster" Then
        screen.SetGridStyle("mixed-aspect-ratio")
    Else
        screen.SetGridStyle("two-row-flat-landscape-custom")
    End If

    screen.SetDisplayMode("scale-to-fill")

    ' Get Data
    sectionNames = CreateObject("roArray", 3, true)
    sectionIndex = 1

    rowData = CreateObject("roArray", 3, true)

    listStyles = CreateObject("roArray", 3, true)

    ' Setup Jump List
    m.jumpList = {}

    ' Movies
    moviesAll = GetMoviesAll()
    sectionNames.push( "Movies A-Z" )
    movieIndex = 0

    If RegRead("prefMovieImageType") = "poster" Then
        listStyles.push( "portrait" )
    End If

    ' Box Sets
    moviesBoxsets = GetMoviesBoxsets()

    If moviesBoxsets.Count() > 0 Then
        sectionNames.push( "Box Sets" )
        boxsetIndex  = sectionIndex
        sectionIndex = sectionIndex + 1

        If RegRead("prefMovieImageType") = "poster" Then
            listStyles.push( "landscape" )
        End If
    End If

    ' Genres
    moviesGenres = GetMoviesGenres()

    If moviesGenres.Count() > 0 Then
        sectionNames.push( "Genres" )
        genreIndex = sectionIndex
        sectionIndex = sectionIndex + 1

        If RegRead("prefMovieImageType") = "poster" Then
            listStyles.push( "landscape" )
        End If
    End If

    screen.SetupLists(sectionNames.Count())
    screen.SetListNames(sectionNames)

    If RegRead("prefMovieImageType") = "poster" Then
        screen.SetListPosterStyles(listStyles)
    End If

    ' Movie data
    rowData[movieIndex] = moviesAll
    screen.SetContentList(movieIndex, moviesAll)

    ' Box Sets Data
    If moviesBoxsets.Count() > 0 Then
        rowData[boxsetIndex] = moviesBoxsets
        screen.SetContentList(boxsetIndex, moviesBoxsets)
    End If

    ' Genres Data
    If moviesGenres.Count() > 0 Then
        rowData[genreIndex] = moviesGenres
        screen.SetContentList(genreIndex, moviesGenres)
    End If

    ' Show Screen
    screen.Show()

    ' Hide Description Popup
    screen.SetDescriptionVisible(false)

    ' Remote key id's for navigation
    remoteKeyStar = 10

    while true
        msg = wait(0, screen.GetMessagePort())

        if type(msg) = "roGridScreenEvent" Then
            if msg.isListItemFocused() then
                'print "list focused | index = "; msg.GetIndex(); " | category = "; 'm.curCategory
            else if msg.isListItemSelected() Then
                row = msg.GetIndex()
                selection = msg.getData()

                If rowData[row][selection].ContentType = "Movie" Then
                    movieIndex = ShowMoviesDetailPage(rowData[row][selection].Id, moviesAll, selection)
                    screen.SetFocusedListItem(row, movieIndex)
                Else If rowData[row][selection].ContentType = "Genre" Then
                    ShowMoviesGenrePage(rowData[row][selection].Id)
                Else If rowData[row][selection].ContentType = "BoxSet" Then
                    ShowMoviesBoxsetPage(rowData[row][selection].Id, rowData[row][selection].Title)
                Else 
                    Print "Unknown Type found"
                End If

            else if msg.isRemoteKeyPressed() then
                index = msg.GetIndex()

                If index = remoteKeyStar Then
                    letterSelected = CreateJumpListDialog()

                    If letterSelected <> invalid Then
                        letter = FindClosestLetter(letterSelected)
                        screen.SetFocusedListItem(0, m.jumpList.Lookup(letter))
                    End If
                End If

            else if msg.isScreenClosed() then
                return -1
            end if
        end if
    end while

    return 0
End Function


'**********************************************************
'** Get All Movies From Server
'**********************************************************

Function GetMoviesAll() As Object
    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/Users/" + m.curUserProfile.Id + "/Items?Recursive=true&IncludeItemTypes=Movie&Fields=UserData%2CMediaStreams%2CSortName&SortBy=SortName&SortOrder=Ascending", true)

    if (request.AsyncGetToString())
        while (true)
            msg = wait(0, request.GetPort())

            if (type(msg) = "roUrlEvent")
                code = msg.GetResponseCode()

                if (code = 200)
                    index    = 0
                    list     = CreateObject("roArray", 2, true)
                    jsonData = ParseJSON(msg.GetString())
                    for each itemData in jsonData.Items
                        movieData = {
                            Id: itemData.Id
                            Title: itemData.Name
                            ContentType: "Movie"
                            Watched: itemData.UserData.Played
                        }

                        ' Get Image Type From Preference
                        If RegRead("prefMovieImageType") = "poster" Then

                            ' Check If Item has Image, otherwise use default
                            If itemData.ImageTags.Primary<>"" And itemData.ImageTags.Primary<>invalid
                                movieData.HDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Primary/0?height=192&width=&EnableImageEnhancers=false&tag=" + itemData.ImageTags.Primary
                                movieData.SDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Primary/0?height=140&width=&EnableImageEnhancers=false&tag=" + itemData.ImageTags.Primary
                            Else 
                                movieData.HDPosterUrl = "pkg://images/items/collection.png"
                                movieData.SDPosterUrl = "pkg://images/items/collection.png"
                            End If

                        Else If RegRead("prefMovieImageType") = "thumb" Then

                            ' Check If Item has Image, otherwise use default
                            If itemData.ImageTags.Thumb<>"" And itemData.ImageTags.Thumb<>invalid
                                movieData.HDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Thumb/0?height=150&width=&EnableImageEnhancers=false&tag=" + itemData.ImageTags.Thumb
                                movieData.SDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Thumb/0?height=94&width=&EnableImageEnhancers=false&tag=" + itemData.ImageTags.Thumb
                            Else 
                                movieData.HDPosterUrl = "pkg://images/items/collection.png"
                                movieData.SDPosterUrl = "pkg://images/items/collection.png"
                            End If

                        Else

                            ' Check If Item has Image, otherwise use default
                            If itemData.BackdropImageTags[0]<>"" And itemData.BackdropImageTags[0]<>invalid
                                movieData.HDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Backdrop/0?height=150&width=&tag=" + itemData.BackdropImageTags[0]
                                movieData.SDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Backdrop/0?height=94&width=&tag=" + itemData.BackdropImageTags[0]
                            Else 
                                movieData.HDPosterUrl = "pkg://images/items/collection.png"
                                movieData.SDPosterUrl = "pkg://images/items/collection.png"
                            End If

                        End If

                        ' Show / Hide Series Name
                        If RegRead("prefMovieTitle") = "show" Then
                            movieData.ShortDescriptionLine1 = itemData.Name
                        End If

                        ' Build Jump List
                        firstChar = Left(itemData.SortName, 1)
                        If Not m.jumpList.DoesExist(firstChar) Then
                            m.jumpList.AddReplace(firstChar, index)
                        End If

                        ' Increment Count
                        index = index + 1

                        list.push( movieData )
                    end for
                    return list
                end if
            else if (event = invalid)
                request.AsyncCancel()
            endif
        end while
    endif

    Return invalid
End Function


'**********************************************************
'** Get Movie Genres From Server
'**********************************************************

Function GetMoviesGenres() As Object
    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/Genres?UserId=" + m.curUserProfile.Id + "&Recursive=true&IncludeItemTypes=Movie&Fields=ItemCounts&SortBy=SortName&SortOrder=Ascending", true)

    if (request.AsyncGetToString())
        while (true)
            msg = wait(0, request.GetPort())

            if (type(msg) = "roUrlEvent")
                code = msg.GetResponseCode()

                if (code = 200)
                    list     = CreateObject("roArray", 2, true)
                    jsonData = ParseJSON(msg.GetString())
                    for each itemData in jsonData.Items
                        movieData = {
                            Id: itemData.Name
                            Title: itemData.Name
                            ContentType: "Genre"
                            ShortDescriptionLine1: itemData.Name
                            ShortDescriptionLine2: Stri(itemData.ChildCount) + " movies"
                        }

                        ' Check If Item has Image, otherwise use default
                        If itemData.ImageTags.Primary<>"" And itemData.ImageTags.Primary<>invalid
                            movieData.HDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Primary/0?height=150&width=&tag=" + itemData.ImageTags.Primary
                            movieData.SDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Primary/0?height=94&width=&tag=" + itemData.ImageTags.Primary
                        Else 
                            movieData.HDPosterUrl = "pkg://images/items/collection.png"
                            movieData.SDPosterUrl = "pkg://images/items/collection.png"
                        End If

                        list.push( movieData )
                    end for
                    return list
                endif
            else if (event = invalid)
                request.AsyncCancel()
            endif
        end while
    endif

    Return invalid
End Function


'**********************************************************
'** Get Movie Boxsets From Server
'**********************************************************

Function GetMoviesBoxsets() As Object

    request = CreateURLTransferObjectJson(GetServerBaseUrl() + "/Users/" + m.curUserProfile.Id + "/Items?Recursive=true&IncludeItemTypes=BoxSet&Fields=UserData%2CItemCounts&SortBy=SortName&SortOrder=Ascending", true)

    if (request.AsyncGetToString())
        while (true)
            msg = wait(0, request.GetPort())

            if (type(msg) = "roUrlEvent")
                code = msg.GetResponseCode()

                if (code = 200)
                    list     = CreateObject("roArray", 2, true)
                    jsonData = ParseJSON(msg.GetString())
                    for each itemData in jsonData.Items
                        movieData = {
                            Id: itemData.Id
                            Title: itemData.Name
                            ContentType: "BoxSet"
                            ShortDescriptionLine1: itemData.Name
                            Watched: itemData.UserData.Played
                        }

                        ' Check If Item has Image, otherwise use default
                        If itemData.BackdropImageTags[0]<>"" And itemData.BackdropImageTags[0]<>invalid
                            movieData.HDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Backdrop/0?height=150&width=&tag=" + itemData.BackdropImageTags[0]
                            movieData.SDPosterUrl = GetServerBaseUrl() + "/Items/" + itemData.Id + "/Images/Backdrop/0?height=94&width=&tag=" + itemData.BackdropImageTags[0]
                        Else 
                            movieData.HDPosterUrl = "pkg://images/items/collection.png"
                            movieData.SDPosterUrl = "pkg://images/items/collection.png"
                        End If

                        list.push( movieData )
                    end for
                    return list
                endif
            else if (event = invalid)
                request.AsyncCancel()
            endif
        end while
    endif

    Return invalid
End Function


'**********************************************************
'** Find Closest Letter with Data
'**********************************************************

Function FindClosestLetter(letter As String) As String
    letters = ["a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"]

    ' If Data exists, just return the letter
    If m.jumpList.DoesExist(letter) Then
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
        If m.jumpList.DoesExist(letters[i]) Then
            return letters[i]
        End If
    End For

    ' Find closest letter with data decreasing
    For i=letterIndex To 0 Step -1
        If m.jumpList.DoesExist(letters[i]) Then
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
        TextAttrs: { font: "small", color: "#000000", halign: "center", valign: "top" }
        TargetRect: {x: 300, y: 250, w: 200, h: 60}
    })

    ' Alphabet
    For i=0 To 12
        list.Push({
            Text:  letters[i]
            TextAttrs: { font: "huge", color: "#000000", halign: "center", valign: "middle" }
            TargetRect: positions[0][i]
        })
    End For

    For i=0 To 12
        list.Push({
            Text:  letters[i+13]
            TextAttrs: { font: "huge", color: "#000000", halign: "center", valign: "middle" }
            TargetRect: positions[1][i]
        })
    End For

    ' Selected Letter Box
    selectedLetter = {
        url: "pkg:/images/jumplist/box.png",
        TargetRect: {x: positions[selectedRow][selectedIndex].x-5, y: positions[selectedRow][selectedIndex].y-9, w: 60, h: 60}
    }            

    ' Show Dialog
    canvas.SetLayer(0, { Color: "#00000000", CompositionMode: "Source" })
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
                    End if

                End If

                ' Rebuild Dialog Screen
                selectedLetter.TargetRect = {x: positions[selectedRow][selectedIndex].x-5, y: positions[selectedRow][selectedIndex].y-9, w: 60, h: 60}

                canvas.SetLayer(0, { Color: "#00000000", CompositionMode: "Source" })
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
