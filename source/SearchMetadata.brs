'**********************************************************
'** parseSearchResultsResponse
'**********************************************************

Function parseSearchResultsResponse(response as String) As Object

    if response <> invalid

        contentList = CreateObject("roArray", 25, true)
        jsonObj     = ParseJSON(response)

        if jsonObj = invalid
            return invalid
        end if

        totalRecordCount = jsonObj.TotalRecordCount
        indexCount       = 0
        indexSelected    = 0

        for each i in jsonObj.SearchHints
		
            metaData = {}

            metaData.ContentType = i.Type
			metaData.MediaType = i.MediaType
            metaData.Id = i.ItemId

            metaData.ShortDescriptionLine1 = firstOf(i.Name, "Unknown")
            metaData.Title = firstOf(i.Name, "Unknown")

            if i.Type = "Episode"

                episodeInfo = ""

                if i.ParentIndexNumber <> invalid
                    episodeInfo = itostr(i.ParentIndexNumber)
                end if

                if i.IndexNumber <> invalid
                    episodeInfo = episodeInfo + "x" + ZeroPad(itostr(i.IndexNumber))
                end if

                if episodeInfo <> ""
                    episodeInfo = episodeInfo + " - " + firstOf(i.Series, "")
                else
                    episodeInfo = firstOf(i.Series, "")
                end if

                metaData.ShortDescriptionLine2 = episodeInfo
				
            end if

            sizes = GetImageSizes("two-row-flat-landscape-custom")

            if i.MediaType = "Video" and i.Type <> "Episode"

                if i.ThumbImageItemId <> "" And i.ThumbImageItemId <> invalid
                    imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.ThumbImageItemId) + "/Images/Thumb/0"

                    metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ThumbImageTag)
                    metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ThumbImageTag)

                else if i.BackdropImageItemId <> "" And i.BackdropImageItemId <> invalid
				
                    imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.BackdropImageItemId) + "/Images/Backdrop/0"

                    metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.BackdropImageTag)
                    metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.BackdropImageTag)

                else 
                    metaData.HDPosterUrl = GetViewController().getThemeImageUrl("hd-landscape.jpg")
                    metaData.SDPosterUrl = GetViewController().getThemeImageUrl("sd-landscape.jpg")

                end if

            else if i.Type = "Episode"

                if i.PrimaryImageTag <> "" And i.PrimaryImageTag <> invalid
                    imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.ItemId) + "/Images/Primary/0"

                    metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.PrimaryImageTag)
                    metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.PrimaryImageTag)

                else 
                    metaData.HDPosterUrl = GetViewController().getThemeImageUrl("hd-landscape.jpg")
                    metaData.SDPosterUrl = GetViewController().getThemeImageUrl("sd-landscape.jpg")

                end if

            else if i.Type = "MusicGenre" Or i.Type = "Genre"

                if i.BackdropImageItemId <> "" And i.BackdropImageItemId <> invalid
                    imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.BackdropImageItemId) + "/Images/Backdrop/0"

                    metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.BackdropImageTag)
                    metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.BackdropImageTag)

                else if i.ThumbImageItemId <> "" And i.ThumbImageItemId <> invalid
				
                    imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.ThumbImageItemId) + "/Images/Thumb/0"

                    metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ThumbImageTag)
                    metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ThumbImageTag)

                else 
                    metaData.HDPosterUrl = GetViewController().getThemeImageUrl("hd-landscape.jpg")
                    metaData.SDPosterUrl = GetViewController().getThemeImageUrl("sd-landscape.jpg")

                end if

            else if i.Type = "MusicArtist"

                if i.BackdropImageItemId <> "" And i.BackdropImageItemId <> invalid
                    imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.BackdropImageItemId) + "/Images/Backdrop/0"

                    metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.BackdropImageTag)
                    metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.BackdropImageTag)

                else if i.PrimaryImageTag <> "" And i.PrimaryImageTag <> invalid
				
                    imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.ItemId) + "/Images/Primary/0"

                    metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.PrimaryImageTag)
                    metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.PrimaryImageTag)

                else 
                    metaData.HDPosterUrl = GetViewController().getThemeImageUrl("hd-landscape.jpg")
                    metaData.SDPosterUrl = GetViewController().getThemeImageUrl("sd-landscape.jpg")

                end if

            else if i.Type = "Person"
			
                if i.PrimaryImageTag <> "" And i.PrimaryImageTag <> invalid
                    imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.ItemId) + "/Images/Primary/0"
					
					portraitSizes = GetImageSizes("flat-portrait")
                    metaData.HDPosterUrl = BuildImage(imageUrl, portraitSizes.hdWidth, portraitSizes.hdHeight, i.PrimaryImageTag)
                    metaData.SDPosterUrl = BuildImage(imageUrl, portraitSizes.sdWidth, portraitSizes.sdHeight, i.PrimaryImageTag)

                else 
                    metaData.HDPosterUrl = GetViewController().getThemeImageUrl("hd-landscape.jpg")
                    metaData.SDPosterUrl = GetViewController().getThemeImageUrl("sd-landscape.jpg")

                end if

            else

                metaData.HDPosterUrl = GetViewController().getThemeImageUrl("hd-landscape.jpg")
                metaData.SDPosterUrl = GetViewController().getThemeImageUrl("sd-landscape.jpg")

            end if

            contentList.push( metaData )
        end for

		if totalRecordCount > 50 then totalRecordCount = 50

        return {
            Items: contentList
            TotalCount: totalRecordCount
        }
    else
        Debug("Error parsing search results")
    end if

    return invalid
End Function