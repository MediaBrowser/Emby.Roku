'**********************************************************
'**  Media Browser Roku Client - Paragraph Screen
'**********************************************************


Function CreateParagraphScreen(title As String) As Object

    ' Setup Screen
    o = CreateObject("roAssociativeArray")

    port      = CreateObject("roMessagePort")
    paragraph = CreateObject("roParagraphScreen")
    paragraph.SetMessagePort(port)

    ' Setup Common Items
    o.Screen         = paragraph
    o.Port           = Port
    o.Show           = ShowParagraphScreen
    o.AddHeaderText  = paragraphAddHeaderText
    o.AddParagraph   = paragraphAddParagraph
    o.AddButton      = paragraphAddButton

    ' Set Title
    o.Screen.SetTitle(title)

    Return o
End Function


'**********************************************************
'** Show Paragraph Screen
'**********************************************************

Function ShowParagraphScreen()
    m.screen.Show()
End Function


'**********************************************************
'** Add Header Text on Paragraph Screen
'**********************************************************

Function paragraphAddHeaderText(text as String)
    m.screen.AddHeaderText(text)
End Function


'**********************************************************
'** Add Paragraph on Paragraph Screen
'**********************************************************

Function paragraphAddParagraph(text as String)
    m.screen.AddParagraph(text)
End Function


'**********************************************************
'** Add Button on Paragraph Screen
'**********************************************************

Function paragraphAddButton(buttonId as Integer, title as String)
    m.screen.AddButton(buttonId, title)
End Function

