' UnZip a file script
'
' It's a mess, I know!!!
'

' Dim ArgObj, var1, var2
Set ArgObj = WScript.Arguments

If (Wscript.Arguments.Count > 0) Then
 var1 = ArgObj(0)
Else
 var1 = ""
End if

If var1 = "" then
 strFileZIP = "example.zip"
Else
 strFileZIP = var1
End if

'The location of the zip file.
REM Set WshShell = CreateObject("Wscript.Shell")
REM CurDir = WshShell.ExpandEnvironmentStrings("%%cd%%")
Dim sCurPath
sCurPath = CreateObject("Scripting.FileSystemObject").GetAbsolutePathName(".")
strZipFile = sCurPath & "\" & strFileZIP
'The folder the contents should be extracted to.
outFolder = sCurPath & "\"
Set objShell = CreateObject( "Shell.Application" )
Set objSource = objShell.NameSpace(strZipFile).Items()
Set objTarget = objShell.NameSpace(outFolder)
intOptions = 256
objTarget.CopyHere objSource, intOptions
