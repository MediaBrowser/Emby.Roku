Function SimpleJSONBuilder( jsonArray As Object ) As String
    Return SimpleJSONAssociativeArray( jsonArray )
End Function

Function SimpleJSONAssociativeArray( jsonArray As Object ) As String
    jsonString = "{"
    
    For Each key in jsonArray
        jsonString = jsonString + Chr(34) + key + Chr(34) + ":"
        value = jsonArray[ key ]

		' rewster: The type values are not roString. roInt etc just String, Int.  Added a check for either as this break the LiveTV schedule recording
		If Type( value ) = "roString" or Type( value ) = "String" Then
            jsonString = jsonString + Chr(34) + value + Chr(34)
        Else If Type( value ) = "roInt" Or Type( value ) = "roFloat" Or Type( value ) = "Int" Or Type( value ) = "Float" Then
            jsonString = jsonString + value.ToStr()
        Else If Type( value ) = "roBoolean"  Or Type( value ) = "Boolean" Then
            jsonString = jsonString + IIf( value, "true", "false" )
        Else If Type( value ) = "roArray" Or Type( value ) = "Array" Then
            jsonString = jsonString + SimpleJSONArray( value )
        Else If Type( value ) = "roAssociativeArray" Then
            jsonString = jsonString + SimpleJSONBuilder( value )
        End If
        jsonString = jsonString + ","
    Next
    If Right( jsonString, 1 ) = "," Then
        jsonString = Left( jsonString, Len( jsonString ) - 1 )
    End If
    
    jsonString = jsonString + "}"
    Return jsonString
End Function

Function SimpleJSONArray( jsonArray As Object ) As String
    jsonString = "["
    
    For Each value in jsonArray
        If Type( value ) = "roString" Then
            jsonString = jsonString + Chr(34) + value + Chr(34)
        Else If Type( value ) = "roInt" Or Type( value ) = "roFloat" Then
            jsonString = jsonString + value.ToStr()
        Else If Type( value ) = "roBoolean" Then
            jsonString = jsonString + IIf( value, "true", "false" )
        Else If Type( value ) = "roArray" Then
            jsonString = jsonString + SimpleJSONArray( value )
        Else If Type( value ) = "roAssociativeArray" Then
            jsonString = jsonString + SimpleJSONAssociativeArray( value )
        End If
        jsonString = jsonString + ","
    Next
    If Right( jsonString, 1 ) = "," Then
        jsonString = Left( jsonString, Len( jsonString ) - 1 )
    End If
    
    jsonString = jsonString + "]"
    Return jsonString
End Function

Function IIf( Condition, Result1, Result2 )
    If Condition Then
        Return Result1
    Else
        Return Result2
    End If
End Function