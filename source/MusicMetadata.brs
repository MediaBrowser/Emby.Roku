'*****************************************************************
'**  Media Browser Roku Client - Music Metadata Class
'*****************************************************************


Function ClassMusicMetadata()
    ' initializes static members once
    this = m.ClassMusicMetadata

    if this = invalid
        this = CreateObject("roAssociativeArray")

        ' constants
        this.class        = "MusicMetadata"

        'variables
        this.jumpList     = {}

        ' functions
        this.GetMusicList = musicmetadata_music_list
        this.GetResumable = musicmetadata_resumable
        this.GetLatest    = musicmetadata_latest

        ' singleton
        m.ClassMusicMetadata = this
    end if
    
    return this
End Function


Function InitMusicMetadata()
    this = ClassMusicMetadata()
    return this
End Function
