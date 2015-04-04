'******************************************************
' getPublicUserProfiles
'******************************************************

Function getPublicUserProfiles(serverUrl as String) As Object

	Debug("getPublicUserProfiles url: " + serverUrl)
	
    ' URL
    url = GetServerBaseUrl(serverUrl) + "/Users/Public"

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

        contentList   = CreateObject("roArray", 25, true)
        jsonObj       = ParseJSON(response)

        if jsonObj = invalid
            Debug("Error while parsing JSON response for All User Profiles")
            return invalid
        end if

        for each i in jsonObj
            metaData = parseUser(i, serverUrl)

            contentList.push( metaData )
        end for

        return contentList
    else
        Debug("Failed To Get All User Profiles")
    end if

    return invalid
End Function


'******************************************************
' Get User Profile
'******************************************************

Function getUserProfile(userId As String) As Object
    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(userId)

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

        i = ParseJSON(response)

        if i = invalid
            Debug("Error Parsing User Profile")
            return invalid
        end if
        
        metaData = parseUser(i)

        return metaData
    else
        Debug("Failed To Get User Profile")
    end if

    return invalid
End Function

Function parseUser(i as Object, serverUrl = "") as Object

    metaData = {}

    ' Set the Id
    metaData.Id = i.Id

    ' Set the Content Type
    metaData.ContentType = "user"

    ' Set the Username
    metaData.Title = firstOf(i.Name, "Unknown")
    metaData.ShortDescriptionLine1 = firstOf(i.Name, "Unknown")

    ' Set the Has Password Flag
    metaData.HasPassword = firstOf(i.HasPassword, false)

    ' Get Image Sizes
    sizes = GetImageSizes("arced-square")

    ' Check if Item has Image, otherwise use default
    if i.PrimaryImageTag <> "" And i.PrimaryImageTag <> invalid
        imageUrl = GetServerBaseUrl(serverUrl) + "/Users/" + HttpEncode(i.Id) + "/Images/Primary/0"

        metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.PrimaryImageTag, false, 0)
        metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.PrimaryImageTag, false, 0)

    else 
        metaData.HDPosterUrl = GetViewController().getThemeImageUrl("hd-default-user.png")
        metaData.SDPosterUrl = GetViewController().getThemeImageUrl("hd-default-user.png")

    end if

	return metadata

End Function


'**********************************************************
'** Get Alphabetical List
'**********************************************************

Function getAlphabetList(contentType As String, parentId = invalid) As Object

    ' Set the buttons
    buttons = []
    letters = ["#","a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"]

    for each cLetter in letters
        letterButton = {
            Id: cLetter
            ContentType: contentType
            Title: "Letter " + UCase(cLetter)
            ShortDescriptionLine1: " "
            HDPosterUrl: GetViewController().getThemeImageUrl("letter_" + cLetter + ".jpg")
            SDPosterUrl: GetViewController().getThemeImageUrl("letter_" + cLetter + ".jpg")
        }
		
		if parentId <> invalid then
			letterButton.ParentId = parentId
		end if

        buttons.Push( letterButton )
    end for

    return {
        Items: buttons
        TotalCount: 27
    }
End Function

'**********************************************************
'** parseItemsResponse
'**********************************************************

Function parseItemsResponse(response as String, imageType as Integer, primaryImageStyle as String, mode ="" as String) As Object

    if response <> invalid

        fixedResponse = normalizeJson(response)

        contentList = CreateObject("roArray", 25, true)
        jsonObj     = ParseJSON(fixedResponse)

        if jsonObj = invalid
            Debug("Error while parsing JSON response")
            return invalid
        end if

        totalRecordCount = jsonObj.TotalRecordCount

		style = primaryImageStyle

        for each i in jsonObj.Items
            
			metaData = getMetadataFromServerItem(i, imageType, primaryImageStyle, mode)

            contentList.push( metaData )
        end for

        return {
            Items: contentList
            TotalCount: totalRecordCount
        }
		
    end if

	Debug("Error getting folder items.")
    return invalid
End Function

Function getMetadataFromServerItem(i as Object, imageType as Integer, primaryImageStyle as String, mode ="" as String) As Object

    style = primaryImageStyle

    metaData = {}

    metaData.ContentType = getContentType(i, mode)

    metaData.Id = i.Id
	metaData.ServerId = i.ServerId

    metaData.Title = getTitle(i)

	metaData.IsFolder = i.IsFolder
	metaData.MediaType = i.MediaType
	metaData.PrimaryImageAspectRatio = i.PrimaryImageAspectRatio
	metaData.MediaSources = i.MediaSources
	metaData.People = i.People
	metaData.CollectionType = i.CollectionType
	
	metaData.ChannelId = i.ChannelId
	metaData.StartDate = i.StartDate
	metaData.EndDate = i.EndDate
	metaData.TimerId = i.TimerId
	metaData.SeriesTimerId = i.SeriesTimerId
	metaData.ProgramId = i.ProgramId

	line1 = getShortDescriptionLine1(i, mode)

	if line1 <> "" then
		metaData.ShortDescriptionLine1 = line1
	end If

	line2 = getShortDescriptionLine2(i, mode)

	if line2 <> "" then
		metaData.ShortDescriptionLine2 = line2
	end If

    if i.RunTimeTicks <> "" And i.RunTimeTicks <> invalid
        metaData.Length = Int(((i.RunTimeTicks).ToFloat() / 10000) / 1000)
    end if

	description = getDescription(i, mode)
    if description <> ""
        metaData.Description = description
    end if

    if i.OfficialRating <> invalid
        metaData.Rating = i.OfficialRating
    end if

    if i.CommunityRating <> invalid
        metaData.StarRating = Int(i.CommunityRating) * 10
    end if
	
	metaData.Director = getDirector(i, mode)

    ' Set the Play Access
    metaData.PlayAccess = firstOf(i.PlayAccess, "Full")

    ' Set the Place Holder (default to is not a placeholder)
    metaData.IsPlaceHolder = firstOf(i.IsPlaceHolder, false)

    ' Set the Local Trailer Count
    metaData.LocalTrailerCount = firstOf(i.LocalTrailerCount, 0)

    ' Set the Special Feature Count
    metaData.SpecialFeatureCount = firstOf(i.SpecialFeatureCount, 0)

    ' Set the Playback Position
	FillUserDataFromItem(metaData, i)

	releaseDate = i.PremiereDate
	if releaseDate = invalid then releaseDate = i.StartDate
	
	' Most people won't care about the exact release date of some types
	if i.Type = "Episode" then
        if releaseDate<> invalid
            metaData.ReleaseDate = formatDateStamp(releaseDate)
        end if
	else
        if releaseDate <> invalid
            metaData.ReleaseDate = left(releaseDate, 4)
        end if
	end If

    if i.RecursiveItemCount <> invalid
        metaData.NumEpisodes = i.RecursiveItemCount
    end if

    ' Set HD Flags
    if i.IsHD <> invalid
        metaData.HDBranded = i.IsHD
        metaData.IsHD = i.IsHD
    end if

    ' Set the Artist Name
    if i.AlbumArtist <> "" And i.AlbumArtist <> invalid
        metaData.Artist = i.AlbumArtist
    else if i.Artists <> invalid And i.Artists[0] <> "" And i.Artists[0] <> invalid
        metaData.Artist = i.Artists[0]
    else
        metaData.Artist = ""
    end if

    if i.PlayedPercentage <> invalid
			
        PlayedPercentage = i.PlayedPercentage
				
    else if i.UserData.PlaybackPositionTicks <> "" And i.UserData.PlaybackPositionTicks <> invalid
			
        if i.RunTimeTicks <> "" And i.RunTimeTicks <> invalid
            currentPosition = Int(((i.UserData.PlaybackPositionTicks).ToFloat() / 10000) / 1000)
            totalLength     = Int(((i.RunTimeTicks).ToFloat() / 10000) / 1000)
            if totalLength <> 0
                PlayedPercentage = Int((currentPosition / totalLength) * 100)
            else
                PlayedPercentage = 0
            end if
        else
            PlayedPercentage = 0
        end If
    else
        PlayedPercentage = 0
    end if

    if PlayedPercentage = 100
        PlayedPercentage = 0
    end if

    ' Set Unplayed Count
    UnplayedCount = i.UserData.UnplayedItemCount
	
	if UnplayedCount = invalid then UnplayedCount = 0

	isPlayed = i.UserData.Played

	if UnplayedCount > 0 then
		PlayedPercentage = 0
	end if

	' Don't show progress bars for these
	if i.Type = "MusicAlbum" or i.Type = "MusicArtist" then
		PlayedPercentage = 0
		isPlayed = false
	end if
	
	' Only display for these types
	if i.Type <> "Season" and i.Type <> "Series" and i.Type <> "BoxSet" then
		UnplayedCount = 0
	end if

	' Primary Image
    if imageType = 0 then

		if mode = "autosize" then
		
			if i.PrimaryImageAspectRatio <> invalid and i.PrimaryImageAspectRatio >= 1.35 then
				sizes = GetImageSizes("two-row-flat-landscape-custom")
			else if i.PrimaryImageAspectRatio <> invalid and i.PrimaryImageAspectRatio >= .95 then
				sizes = GetImageSizes("arced-square")
			else
				sizes = GetImageSizes("mixed-aspect-ratio-portrait")
			end if
			
		else
			sizes = GetImageSizes(style)
		end if
        

		if mode = "seriesimageasprimary" And i.SeriesPrimaryImageTag <> "" And i.SeriesPrimaryImageTag <> invalid

            imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.SeriesId) + "/Images/Primary/0"

            metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.SeriesPrimaryImageTag, isPlayed, PlayedPercentage, UnplayedCount)
            metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.SeriesPrimaryImageTag, isPlayed, PlayedPercentage, UnplayedCount)
					
        else if i.ImageTags <> invalid And i.ImageTags.Primary <> "" And i.ImageTags.Primary <> invalid
				
            imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.Id) + "/Images/Primary/0"

            metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ImageTags.Primary, isPlayed, PlayedPercentage, UnplayedCount)
            metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ImageTags.Primary, isPlayed, PlayedPercentage, UnplayedCount)

        else if i.BackdropImageTags <> invalid and i.BackdropImageTags[0] <> "" And i.BackdropImageTags[0] <> invalid
				
            imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.Id) + "/Images/Backdrop/0"

            metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.BackdropImageTags[0], isPlayed, PlayedPercentage, UnplayedCount)
            metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.BackdropImageTags[0], isPlayed, PlayedPercentage, UnplayedCount)

        else if style = "two-row-flat-landscape-custom" or style = "flat-episodic-16x9"

            metaData.HDPosterUrl = GetViewController().getThemeImageUrl("hd-landscape.jpg")
            metaData.SDPosterUrl = GetViewController().getThemeImageUrl("sd-landscape.jpg")

        else if style = "mixed-aspect-ratio-square" or style = "arced-square" or style = "list" or style = "rounded-square-generic"

            metaData.HDPosterUrl = GetViewController().getThemeImageUrl("hd-square.jpg")
            metaData.SDPosterUrl = GetViewController().getThemeImageUrl("sd-square.jpg")

        else

            metaData.HDPosterUrl = GetViewController().getThemeImageUrl("hd-poster.jpg")
            metaData.SDPosterUrl = GetViewController().getThemeImageUrl("sd-poster.jpg")

        end if

    ' Thumb Image
    else if imageType = 1 then

        sizes = GetImageSizes("two-row-flat-landscape-custom")

        if i.ImageTags.Thumb <> "" And i.ImageTags.Thumb <> invalid
				
            imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.Id) + "/Images/Thumb/0"

            metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ImageTags.Thumb, isPlayed, PlayedPercentage, UnplayedCount)
            metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ImageTags.Thumb, isPlayed, PlayedPercentage, UnplayedCount)

        else if i.SeriesThumbImageTag <> "" And i.SeriesThumbImageTag <> invalid

            imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.SeriesId) + "/Images/Thumb/0"

            metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.SeriesThumbImageTag, isPlayed, PlayedPercentage, UnplayedCount)
            metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.SeriesThumbImageTag, isPlayed, PlayedPercentage, UnplayedCount)

        else if i.BackdropImageTags[0] <> "" And i.BackdropImageTags[0] <> invalid
				
            imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.Id) + "/Images/Backdrop/0"

            metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.BackdropImageTags[0], isPlayed, PlayedPercentage, UnplayedCount)
            metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.BackdropImageTags[0], isPlayed, PlayedPercentage, UnplayedCount)

        else if i.ImageTags.Primary <> "" And i.ImageTags.Primary <> invalid
				
            imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.Id) + "/Images/Primary/0"

            metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ImageTags.Primary, isPlayed, PlayedPercentage, UnplayedCount)
            metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ImageTags.Primary, isPlayed, PlayedPercentage, UnplayedCount)

        else 
            metaData.HDPosterUrl = GetViewController().getThemeImageUrl("hd-landscape.jpg")
            metaData.SDPosterUrl = GetViewController().getThemeImageUrl("sd-landscape.jpg")

        end if

    ' Backdrop Image
    else

        sizes = GetImageSizes("two-row-flat-landscape-custom")

        if i.BackdropImageTags[0] <> "" And i.BackdropImageTags[0] <> invalid
				
            imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.Id) + "/Images/Backdrop/0"

            metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.BackdropImageTags[0], isPlayed, PlayedPercentage, UnplayedCount)
            metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.BackdropImageTags[0], isPlayed, PlayedPercentage, UnplayedCount)

        else if i.ImageTags.Primary <> "" And i.ImageTags.Primary <> invalid
				
            imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.Id) + "/Images/Primary/0"

            metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ImageTags.Primary, isPlayed, PlayedPercentage, UnplayedCount)
            metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ImageTags.Primary, isPlayed, PlayedPercentage, UnplayedCount)

        else 
				
            metaData.HDPosterUrl = GetViewController().getThemeImageUrl("hd-landscape.jpg")
            metaData.SDPosterUrl = GetViewController().getThemeImageUrl("sd-landscape.jpg")

        end if

    end if

	if i.Type = "Episode" then
	
        ' Build Episode Information
        episodeInfo = ""

        ' Add Series Name
        if i.SeriesName <> invalid
            episodeInfo = i.SeriesName
        end if

        ' Add Season Number
        if i.ParentIndexNumber <> invalid
            if episodeInfo <> ""
                episodeInfo = episodeInfo + " / "
            end if

            episodeInfo = episodeInfo + "Season " + itostr(i.ParentIndexNumber)
        end if

        ' Add Episode Number
        if i.IndexNumber <> invalid
            if episodeInfo <> ""
                episodeInfo = episodeInfo + " / "
            end if
                
            episodeInfo = episodeInfo + "Episode " + itostr(i.IndexNumber)

            ' Add Double Episode Number
            if i.IndexNumberEnd <> invalid
                episodeInfo = episodeInfo + "-" + itostr(i.IndexNumberEnd)
            end if
        end if

        ' Use Actors Area for Series / Season / Episode
        metaData.Actors = episodeInfo

	else
		FillActorsFromItem(metaData, i)
	end if
	
	FillChaptersFromItem(metaData, i)
	FillCategoriesFromGenres(metaData, i)
	
	if i.MediaType = "Photo" then
		FillPhotoInfo(metaData, i)
	end if

    metaData.LocationType = firstOf(i.LocationType, "FileSystem")

    ' Setup Chapters
	
	addVideoDisplayInfo(metaData, i)

	if i.MediaType = "Audio" then SetAudioStreamProperties(metaData)

	if i.SeriesTimerId <> invalid And i.SeriesTimerId <> ""
        metaData.HDSmallIconUrl = GetViewController().getThemeImageUrl("SeriesRecording.png")
        metaData.SDSmallIconUrl = GetViewController().getThemeImageUrl("SeriesRecording.png")
    else if i.TimerId <> invalid And i.TimerId <> ""
        metaData.HDSmallIconUrl = GetViewController().getThemeImageUrl("Recording.png")
        metaData.SDSmallIconUrl = GetViewController().getThemeImageUrl("Recording.png")
    end if
   
    
	return metaData
	
End Function

Sub FillPhotoInfo(metaData as Object, item as Object)

	if item.ImageTags <> invalid And item.ImageTags.Primary <> "" And item.ImageTags.Primary <> invalid
				
		imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(item.Id) + "/Images/Primary/0"

		metaData.Url = BuildImage(imageUrl, invalid, invalid, item.ImageTags.Primary, false, 0, 0)
		
		metaData.Url = imageUrl
		
	end if
	
	metaData.TextOverlayUL = firstOf(item.Album, "")
	
	' Handled in PhotoPlayer
	'metaData.TextOverlayUR = "3 of 20"
	
	metaData.TextOverlayBody = metaData.Title

End Sub

Sub FillActorsFromItem(metaData as Object, item as Object)

		' Check For People, Grab First 3 If Exists
		if item.People <> invalid And item.People.Count() > 0
			metaData.Actors = CreateObject("roArray", 3, true)

			' Set Max People to grab Size of people array
			maxPeople = item.People.Count()-1

			' Check To Max sure there are 3 people
			if maxPeople > 2
				maxPeople = 2
			end if

			for actorCount = 0 to maxPeople
				if item.People[actorCount].Name <> "" And item.People[actorCount].Name <> invalid
					metaData.Actors.Push(item.People[actorCount].Name)
				end if
			end for
		end if

	
End Sub

Sub FillChaptersFromItem(metaData as Object, item as Object)

    if item.Chapters <> invalid

        metaData.Chapters = CreateObject("roArray", 5, true)
        chapterCount = 0

        for each c in item.Chapters
            chapterData = {}

            ' Set the chapter display title
            chapterData.Title = firstOf(c.Name, "Unknown")
            chapterData.ShortDescriptionLine1 = firstOf(c.Name, "Unknown")

            ' Set chapter time
            if c.StartPositionTicks <> invalid
                chapterPositionSeconds = Int(((c.StartPositionTicks).ToFloat() / 10000) / 1000)

                chapterData.StartPosition = chapterPositionSeconds
                chapterData.ShortDescriptionLine2 = formatTime(chapterPositionSeconds)
            end if

            ' Get Image Sizes
            sizes = GetImageSizes("flat-episodic-16x9")

            ' Check if Chapter has Image, otherwise use default
            if c.ImageTag <> "" And c.ImageTag <> invalid
			
                imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(item.Id) + "/Images/Chapter/" + itostr(chapterCount)

                chapterData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, c.ImageTag, false, 0)
                chapterData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, c.ImageTag, false, 0)

            else 
                chapterData.HDPosterUrl = GetViewController().getThemeImageUrl("hd-landscape.jpg")
                chapterData.SDPosterUrl = GetViewController().getThemeImageUrl("sd-landscape.jpg")

            end if

            ' Increment Count
            chapterCount = chapterCount + 1

            metaData.Chapters.push( chapterData )
        end for

    end if
	
End Sub

Sub FillUserDataFromItem(metaData as Object, item as Object)

	if item.UserData = invalid then return
	
    if item.UserData.PlaybackPositionTicks <> "" And item.UserData.PlaybackPositionTicks <> invalid
        positionSeconds = Int(((item.UserData.PlaybackPositionTicks).ToFloat() / 10000) / 1000)
        metaData.BookmarkPosition = positionSeconds
    else
        metaData.BookmarkPosition = 0
    end if

    if item.UserData.Played <> invalid And item.UserData.Played = true
        metaData.Watched = true
    else
        metaData.Watched = false
    end if

    if item.UserData.IsFavorite <> invalid And item.UserData.IsFavorite = true
        metaData.IsFavorite = true
    else
        metaData.IsFavorite = false
    end if
	
End Sub

Sub FillCategoriesFromGenres(metaData as Object, item as Object)

	metaData.Categories = CreateObject("roArray", 3, true)
	
    if item.Genres <> invalid And item.Genres.Count() > 0

        maxCategories = item.Genres.Count()-1

        if maxCategories > 2
            maxCategories = 2
        end if

        for categoryCount = 0 to maxCategories
            if item.Genres[categoryCount] <> "" And item.Genres[categoryCount] <> invalid
                metaData.Categories.Push(item.Genres[categoryCount])
            end if
        end for
    end if

End Sub

Function getTitle(i as Object) as String

	name = firstOf(i.Name, "Unknown")

	if i.Type = "Audio" Then

		if i.IndexNumber <> invalid then 
			name = tostr(i.IndexNumber) + ". " + name
		end if

	else if i.Type = "TvChannel" Then

		return firstOf(i.Number, "") + " " + firstOf(i.Name, "")

	else if i.Type = "Program" Then

		programTitle = ""
		if i.StartDate <> invalid And i.StartDate <> ""
			programTitle = getProgramDisplayTime(i.StartDate) + " - "
		end if

		' Add the Program Name
		programTitle = programTitle + firstOf(i.Name, "")

		return firstOf(programTitle, "")

	end If

	return name

End Function

'**********************************************************
'** getProgramDisplayTime
'**********************************************************

Function getProgramDisplayTime(dateString As String) As String

    dateTime = CreateObject("roDateTime")
    dateTime.FromISO8601String(dateString)
    return GetTimeString(dateTime, true)
	
End Function

Function getContentType(i as Object, mode as String) as String

	if i.Type = "CollectionFolder" Then

		return "MediaFolder"

	else if i.Type = "Genre" and mode = "moviegenre"
		return "MovieGenre"

	else if i.Type = "Genre" and mode = "tvgenre"
		return "TvGenre"

	end If

	return i.Type

End Function

function getShortDescriptionLine1(i as Object, mode as String) as String

	if i.Type = "Episode" Then

		if mode = "episodedetails" then return firstOf(i.Name, "Unknown")

		return firstOf(i.SeriesName, "Unknown")

	else if i.Type = "Recording" and mode = "recordinggroup" Then

		if i.EpisodeTitle <> invalid And i.EpisodeTitle <> ""
			return firstOf(i.EpisodeTitle, "Unknown")
		end if

	else if i.Type = "TvChannel" Then

		return firstOf(i.Number, "") + " " + firstOf(i.Name, "")
		
	end If

	return firstOf(i.Name, "Unknown")

End Function

Function getShortDescriptionLine2(i as Object, mode as String) as String

	if i.Type = "MusicArtist" or i.Type = "MusicAlbum" Then

		if i.RecursiveItemCount <> invalid then return Pluralize(i.RecursiveItemCount, "song")

	else if i.Type = "MusicGenre" Then

		if i.SongCount <> invalid then return Pluralize(i.SongCount, "song")
		if i.ChildCount <> invalid then return Pluralize(i.ChildCount, "song")

	else if i.Type = "Genre" Then

		if mode = "moviegenre" and i.MovieCount <> invalid and i.MovieCount > 0 then return Pluralize(i.MovieCount, "movie")
		if mode = "tvgenre" and i.SeriesCount <> invalid and i.SeriesCount > 0 then return Pluralize(i.SeriesCount, "show")

	else if i.Type = "BoxSet" Then

		if i.ChildCount <> invalid then return Pluralize(i.ChildCount, "movie")

	else if i.Type = "Episode" and mode = "episodedetails" Then

		episodeInfo = ""

		if i.ParentIndexNumber <> invalid then episodeInfo = "S" + itostr(i.ParentIndexNumber)

        ' Add Episode Number
        if i.IndexNumber <> invalid

            if episodeInfo <> ""
                episodeInfo = episodeInfo + " / "
            end if
                
            episodeInfo = episodeInfo + "Ep " + itostr(i.IndexNumber)

            ' Add Double Episode Number
            if i.IndexNumberEnd <> invalid
                episodeInfo = episodeInfo + "-" + itostr(i.IndexNumberEnd)
            end if
        end if

        ' Set the Episode rating
        if i.OfficialRating <> "" And i.OfficialRating <> invalid
            if episodeInfo <> ""
                episodeInfo = episodeInfo + " / "
            end if

            episodeInfo = episodeInfo + firstOf(i.OfficialRating, "")
        end if

        ' Set HD Video Flag
        if i.IsHD <> invalid
            if i.IsHD then episodeInfo = episodeInfo + " / HD" 
        end if

		return episodeInfo

	else if i.Type = "Episode" Then

		text = ""

		if i.ParentIndexNumber <> invalid then text = "S" + tostr(i.ParentIndexNumber) + ", "

		if i.IndexNumber <> invalid then text = text + "E" + tostr(i.IndexNumber)

		if i.Name <> invalid and i.Name <> "" then text = text + " - " + i.Name

		return text

	else if i.Type = "Series" Then

		if i.ProductionYear <> invalid then return tostr(i.ProductionYear)

	else if i.Type = "Recording" and mode = "recordinggroup" Then

        if i.StartDate <> invalid And i.StartDate <> ""
            return mid(i.StartDate, 6, 5)
        end if

	else if i.Type = "Recording" Then

        episodeInfo = ""
        if i.StartDate <> invalid And i.StartDate <> ""
            episodeInfo = mid(i.StartDate, 6, 5) + ": "
        end if
            
        return episodeInfo + firstOf(i.EpisodeTitle, "")

	else if i.Type = "TvChannel" Then

        if i.CurrentProgram <> invalid and i.CurrentProgram.Name <> invalid
            return i.CurrentProgram.Name
        end if
			
	else if i.Type = "Program" Then

		programTime = ""
		
		if i.StartDate <> invalid And i.StartDate <> "" and i.EndDate <> invalid And i.EndDate <> ""
			programTime = getProgramDisplayTime(i.StartDate) + " - " + getProgramDisplayTime(i.EndDate)
		end if

        return programTime

	else if i.MediaType = "Video" Then

		if i.ProductionYear <> invalid then return tostr(i.ProductionYear)

	end If

	return ""

End Function

Function getDescription(i as Object, mode as String) as String

	if i.Type = "MusicGenre" Then

		if i.SongCount <> invalid then return Pluralize(i.SongCount, "song")
		if i.ChildCount <> invalid then return Pluralize(i.ChildCount, "song")

	else if i.Type = "Genre" Then

		if mode = "moviegenre" and i.MovieCount <> invalid and i.MovieCount > 0 then return Pluralize(i.MovieCount, "movie")
		if mode = "tvgenre" and i.SeriesCount <> invalid and i.SeriesCount > 0 then return Pluralize(i.SeriesCount, "show")

	else if i.Type = "TvChannel" Then

        if i.CurrentProgram <> invalid and i.CurrentProgram.Overview <> invalid
            return i.CurrentProgram.Overview
        end if
			
	else if i.Overview <> invalid Then

		return i.Overview

	end If

	return ""

End Function

function getDirector(i as Object, mode as String) as String

	if i.People <> invalid then
		for each person in i.People
			if person.Type = "Director" or person.Role = "Director" then
				
				return person.Name
			end if
		end for
	end if
	
	directorValue = ""
	
	return directorValue

End Function

Sub SetAudioStreamProperties(item as Object)

    ' Get Extension
	if item.MediaSources = invalid or item.MediaSources.Count() = 0 then return

	mediaSource = item.MediaSources[0]

    container = mediaSource.Container

	stream = CreateObject("roAssociativeArray")

	itemId = item.Id
	
	item.MediaSourceId = mediaSource.Id

	' Get the version number for checkminimumversion
	versionArr = getGlobalVar("rokuVersion")
	
    ' Direct Playback mp3 and wma(plus flac for firmware 5.3 and above)
    If (container = "mp3") 
        item.Url = GetServerBaseUrl() + "/Audio/" + itemId + "/stream.mp3?static=true"
        item.StreamFormat = "mp3"
		item.playMethod = "DirectStream"
		item.canSeek = true
		
    Else If (container = "wma") 
        item.Url = GetServerBaseUrl() + "/Audio/" + itemId + "/stream.wma?static=true"
        item.StreamFormat = "wma"
		item.playMethod = "DirectStream"
		item.canSeek = true
		
    Else If (container = "flac") And CheckMinimumVersion(versionArr, [5, 3])
        item.Url = GetServerBaseUrl() + "/Audio/" + itemId + "/stream.flac?static=true"
        item.StreamFormat = "flac"
		item.playMethod = "DirectStream"
		item.canSeek = true
	Else
        ' Transcode Play
        item.Url = GetServerBaseUrl() + "/Audio/" + itemId + "/stream.mp3?audioBitrate=128000&deviceId=" + getGlobalVar("rokuUniqueId", "Unknown")
        item.StreamFormat = "mp3"
		item.playMethod = "Transcode"
		item.canSeek = item.Length <> invalid
    End If
	
	accessToken = ConnectionManager().GetServerData(item.ServerId, "AccessToken")
		
	if firstOf(accessToken, "") <> "" then
		item.Url = item.Url + "&api_key=" + accessToken
	end if	

End Sub


'**********************************************************
'** getThemeMusic
'**********************************************************

Function getThemeMusic(itemId As String) As Object

    ' Validate Parameter
    if validateParam(itemId, "roString", "getThemeMusic") = false return invalid

    ' URL
    url = GetServerBaseUrl() + "/Items/" + HttpEncode(itemId) + "/ThemeSongs"

    ' Query
    query = {
        userid: getGlobalVar("user").Id
		InheritFromParent: "true"
    }

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

		return parseItemsResponse(response, 0, "list")
    else
        Debug("Error getting theme music")
    end if

    return invalid
End Function

Function convertItemPeopleToMetadata(people as Object) as Object

    contentList = CreateObject("roArray", 25, true)

    for each i in people
            
		metaData = {}

		metadata.ContentType = "ItemPerson"

		metadata.Title = firstOf(i.Name, "Unknown")
		metadata.Id = i.Id
		metaData.ShortDescriptionLine1 = metaData.Title

		sizes = GetImageSizes("arced-portrait")

		if i.PrimaryImageTag <> "" And i.PrimaryImageTag <> invalid
				
            imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.Id) + "/Images/Primary/0"

            metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.PrimaryImageTag, false, 0, 0)
            metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.PrimaryImageTag, false, 0, 0)

        else
            metaData.HDPosterUrl = GetViewController().getThemeImageUrl("hd-poster.jpg")
            metaData.SDPosterUrl = GetViewController().getThemeImageUrl("sd-poster.jpg")
		end If

		if i.Role <> invalid and i.Role <> "" then
			metaData.ShortDescriptionLine2 = "as " + i.Role
		else if i.Type <> invalid then
			metaData.ShortDescriptionLine2 = i.Type
		end if

        contentList.push( metaData )
    end for

    return contentList
End Function


'**************************************************************
'** videoGetMediaDetails
'**************************************************************

Function GetFullItemMetadata(item, isForPlayback as Boolean, options as Object) as Object

	itemId = item.Id
	itemType = item.ContentType

	Debug("Getting metadata for Id " + itemId)

    if itemType = "Program" then
	
		item = getLiveTvProgramMetadata(itemId)		
		
		if isForPlayback = true then
			item = getLiveTvChannel(item.ChannelId)
		end if
        
    else if itemType = "Recording" 
        item = getLiveTvRecording(itemId)
	else
		item = getVideoMetadata(itemId)
    end if

	if item.MediaType = "Video" or item.MediaType = "Audio" then
		item.StreamInfo = getStreamInfo(item.MediaSources[0], options) 
	end if

	if item.MediaType = "Video" and isForPlayback = true then
		addPlaybackInfo(item, options)
	end if
	
	return item

End Function

Sub addPlaybackInfo(item, options as Object)

	startPositionTicks = tostr(firstOf(options.PlayStart, 0)) + "0000000"
	
	deviceProfile = getDeviceProfile()
	
	playbackInfo = getDynamicPlaybackInfo(item.Id, deviceProfile, startPositionTicks, options.MediaSourceId, options.AudioStreamIndex, options.SubtitleStreamIndex)

	if validatePlaybackInfoResult(playbackInfo) = true then
		
		dynamicMediaSource = getOptimalMediaSource(item.MediaType, playbackInfo.MediaSources)
		
		if dynamicMediaSource <> invalid then
		
			if dynamicMediaSource.RequiresOpening = true then
				liveStreamResult = getLiveStream(item.Id, deviceProfile, startPositionTicks, dynamicMediaSource, options.AudioStreamIndex, options.SubtitleStreamIndex)
				
				liveStreamResult.MediaSource.enableDirectPlay = supportsDirectPlay(liveStreamResult.MediaSource)
				dynamicMediaSource = liveStreamResult.MediaSource
				
			end if
			
			addPlaybackInfoFromMediaSource(item, dynamicMediaSource, options)
			
		else
			showPlaybackInfoErrorMessage("NoCompatibleStream")
		end if
		
	end if
End Sub

Sub addPlaybackInfoFromMediaSource(item, mediaSource, options as Object)

	streamInfo = getStreamInfo(mediaSource, options) 

	if streamInfo = invalid then return

	item.StreamInfo = streamInfo
	
	accessToken = firstOf(ConnectionManager().GetServerData(item.ServerId, "AccessToken"), "")

	' Setup Roku Stream
	' http://sdkdocs.roku.com/display/sdkdoc/Content+Meta-Data

	mediaSourceId = mediaSource.Id
	
	enableSelectableSubtitleTracks = true

	if streamInfo.PlayMethod = "DirectPlay" Then

		item.Stream = {
			url: mediaSource.Path
			contentid: "x-directstream"
			quality: false
		}

		' http://sdkdocs.roku.com/display/sdkdoc/Content+Meta-Data
		if mediaSource.Container = "mov" or mediaSource.Container = "m4v" then
			item.StreamFormat = "mp4"
		else
			item.StreamFormat = mediaSource.Container
		end if
		
	else if streamInfo.PlayMethod = "DirectStream" Then

		item.Stream = {
			url: GetServerBaseUrl() + "/Videos/" + item.Id + "/stream?static=true&mediaSourceId=" + mediaSourceId + "&api_key=" + accessToken,
			contentid: "x-directstream"
			quality: false
		}

		' http://sdkdocs.roku.com/display/sdkdoc/Content+Meta-Data
		if mediaSource.Container = "mov" or mediaSource.Container = "m4v" then
			item.StreamFormat = "mp4"
		else
			item.StreamFormat = mediaSource.Container
		end if
		
	else
	
		url = GetServerBaseUrl() + mediaSource.TranscodingUrl

		if streamInfo.SubtitleStream <> invalid then
		
			if firstOf(streamInfo.SubtitleStream.DeliveryMethod, "") <> "External" then
			
				url = url + "&SubtitleStreamIndex=" + tostr(streamInfo.SubtitleStreamIndex)
				enableSelectableSubtitleTracks = false
				
			else
				if streamInfo.SubtitleStream.IsExternalUrl = true then
					item.SubtitleUrl = streamInfo.SubtitleStream.DeliveryUrl
				else
					item.SubtitleUrl = GetServerBaseUrl() + streamInfo.SubtitleStream.DeliveryUrl
				end if
								
				item.SubtitleConfig = {
					ShowSubtitle: 1
					TrackName: item.SubtitleUrl
				}
			end if
			
		end if

		item.Stream = {
			url: url
			contentid: "x-hls"
			quality: false
		}

        item.StreamFormat = "hls"
        item.SwitchingStrategy = "full-adaptation"

	end if
	
	if streamInfo.Bitrate <> invalid then
		item.Stream.Bitrate = streamInfo.Bitrate / 1000
	end if

	isDisplayHd = getGlobalVar("displayType") = "HDTV"
	
	if item.IsHD = true And isDisplayHd then item.Stream.quality = true
	
	item.SubtitleTracks = []
	
	for each stream in mediaSource.MediaStreams
		if enableSelectableSubtitleTracks AND stream.Type = "Subtitle" and firstOf(stream.DeliveryMethod, "") = "External" then
		
			subtitleInfo = {
				Language: stream.Language
				TrackName: stream.DeliveryUrl
				Description: stream.Codec
			}
			
			if stream.IsExternalUrl <> true then
				subtitleInfo.TrackName = GetServerBaseUrl() + subtitleInfo.TrackName
			end if
								
			if subtitleInfo.Language = invalid then subtitleInfo.Language = "und"
			
			item.SubtitleTracks.push(subtitleInfo)
			
		end if
	end for
	
End Sub

Function getOptimalMediaSource(mediaType, mediaSources) 

	for each mediaSource in mediaSources
	
		mediaSource.enableDirectPlay = supportsDirectPlay(mediaSource)
		
		if mediaSource.enableDirectPlay = true then
			return mediaSource
		end if
	end for
	
	for each mediaSource in mediaSources
	
		if mediaSource.SupportsDirectStream = true then
			return mediaSource
		end if
	end for
	
	for each mediaSource in mediaSources
	
		if mediaSource.SupportsTranscoding = true then
			return mediaSource
		end if
	end for
	
	return invalid

End Function

Function supportsDirectPlay(mediaSource)

	if mediaSource.SupportsDirectPlay = true and mediaSource.Protocol = "Http" then

		' TODO: Need to verify the host is going to be reachable
		return true
	end if

	return false
			
End Function

Function validatePlaybackInfoResult(playbackInfo)

	return true
	
End Function

function showPlaybackInfoErrorMessage(errorCode)

End Function

function getDynamicPlaybackInfo(itemId, deviceProfile, startPositionTicks, mediaSourceId, audioStreamIndex, subtitleStreamIndex) 

	maxVideoBitrate = firstOf(RegRead("prefVideoQuality"), "3200")
	maxVideoBitrate = maxVideoBitrate.ToInt() * 1000
	
	postData = {
		DeviceProfile: deviceProfile
	}

	query = {
		StartTimeTicks: startPositionTicks
		MaxStreamingBitrate: maxVideoBitrate
	}

	if audioStreamIndex <> invalid then 
		query.AudioStreamIndex = audioStreamIndex
	end if
	
	if subtitleStreamIndex <> invalid then 
		query.SubtitleStreamIndex = subtitleStreamIndex
	end if
	
	if mediaSourceId <> invalid then
		query.MediaSourceId = mediaSourceId
	end if

    url = GetServerBaseUrl() + "/Items/" + itemId + "/PlaybackInfo?UserId=" + getGlobalVar("user").Id

	for each key in query
		url = url + "&" + key +"=" + tostr(query[key])
	end for

	' Prepare Request
    request = HttpRequest(url)
    request.AddAuthorization()
	request.ContentType("json")

	json = SimpleJSONBuilder(postData)
    response = request.PostFromStringWithTimeout(json, 10)

	if response = invalid
        return invalid
    else
	
		fixedResponse = normalizeJson(response)
        jsonObj     = ParseJSON(fixedResponse)	
        
		return jsonObj
		
    end if
	
End Function

function getLiveStream(itemId, deviceProfile, startPositionTicks, mediaSource, audioStreamIndex, subtitleStreamIndex) 

	maxVideoBitrate = firstOf(RegRead("prefVideoQuality"), "3200")
	maxVideoBitrate = maxVideoBitrate.ToInt() * 1000
	
	postData = {
		DeviceProfile: deviceProfile
		OpenToken: mediaSource.OpenToken
	}

	query = {
		StartTimeTicks: startPositionTicks
		ItemId: itemId
		MaxStreamingBitrate: maxVideoBitrate
	}

	if audioStreamIndex <> invalid then 
		query.AudioStreamIndex = audioStreamIndex
	end if
	
	if subtitleStreamIndex <> invalid then 
		query.SubtitleStreamIndex = subtitleStreamIndex
	end if

    url = GetServerBaseUrl() + "/LiveStreams/Open?UserId=" + getGlobalVar("user").Id

	for each key in query
		url = url + "&" + key +"=" + tostr(query[key])
	end for

	' Prepare Request
    request = HttpRequest(url)
    request.AddAuthorization()
	request.ContentType("json")

	json = SimpleJSONBuilder(postData)
    response = request.PostFromStringWithTimeout(json, 10)

	if response = invalid
        return invalid
    else
	
		fixedResponse = normalizeJson(response)
        jsonObj     = ParseJSON(fixedResponse)	
        
		return jsonObj
		
    end if
	
End Function

'**********************************************************
'** Format Time From Seconds
'**********************************************************

Function formatTime(seconds As Integer) As String
    if validateParam(seconds, "roInt", "formatTime") = false return -1

    textTime = ""
    hasHours = false

    ' Special Check For Zero
    if seconds < 60
        return "0:" + ZeroPad(itostr(seconds))
    end if
    
    ' Hours
    if seconds >= 3600
        textTime = textTime + itostr(seconds / 3600) + ":"
        hasHours = true
        seconds = seconds Mod 3600
    end if
    
    ' Minutes
    if seconds >= 60
        if hasHours
            textTime = textTime + ZeroPad(itostr(seconds / 60)) + ":"
        else
            textTime = textTime + itostr(seconds / 60) + ":"
        end if
        
        seconds = seconds Mod 60
    else
        if hasHours
            textTime = textTime + "00:"
        end if
    end if

    ' Seconds
    textTime = textTime + ZeroPad(itostr(seconds))

    return textTime
End Function