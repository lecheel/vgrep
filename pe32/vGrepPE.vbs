'''''''''''''''''''''''''''''''''''''''''''''''
'  VGREP.VBS   ViewGREP support to PE32
'  Author      Lechee.Lai
'
'  Date:       October 17, 2oo2     - Preliminary Version
'
'  Overview:
'
'     This macro allows you to use GNU grep 2.0f via PE32
'
'  Keys:
'
'
'  Usage notes:
'  requirement:
'
'    NOTE: This macro has been tested with GNU grep 2.0f
'          Code check with PE32 1.02.3 
'
'  There is no warranty of any kind related to this file.
'  If you don't like that, don't use it.
'
'
'


'
'   Vgrep word Use external GNU grep as
'   grep -i -n -S -z [pattern] *.c *.cpp >c:\pe32.grp
'   for PE32
'
Function VGrep
  Dim fso
  Set fso = CreateObject("Scripting.FileSystemObject")
  If (fso.FileExists("c:\pe32.grp")) then
    pe32.command "[e c:\pe32.grp][line 1]"
    pe32.Message = "Load VGrep Completed"
    pe32.ReadOnly = 1
  Else
    pe32.Message = "Grep Index not founded. Create PE32.GRP First"
  End if
End Function

'
' Hooks orginal [enter] when pe32.grp not founded.
'
'
'
Function GoGrep

  Vname = LCase(pe32.Filename)
  if Vname ="c:\pe32.grp" Then
    pe32.command "[begin line][wb]" 
    spat = pe32.Word
    grepLine = spat
    exitLoop = 0
    Do
      pe32.command "[begin line][wb]"
      spat = pe32.Word
     if Len(spat) Then
      if Eval(spat) Then
        pe32.command "[up][wb]"
        str2 = pe32.Word
        if str2 = "File" Then
            pe32.command "[tab word][unmark][mark block][end line][mark block][left]"
            grepName = pe32.GetMarkedLine(1)
            pe32.command "[unmark][begin line]"
            exitLoop=1
            pe32.command "[e "+grepName+"][line "+grepLine+"]"
        end if
      else
        if spat = "File" Then
            pe32.command "[tab word][unmark][mark block][end line][mark block][left]"
            grepName = pe32.GetMarkedLine(1)
            pe32.command "[unmark][begin line]"
            exitLoop=1
            pe32.command "[e "+grepName+"]"
        else
            pe32.command "[up]"
        end if
      end if
     else
      pe32.Message = "unknow Error, close the index and try again"
      exitLoop =1
     end if
    loop until exitLoop=1
  else
    pe32.command "[split][begin line][wb][down]"       'with indent
'   pe32.command "[split][begin line][down]"           'without indent
  End if
End Function