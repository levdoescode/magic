;╔═══════════════════════════════════════════════════════════════════════════════════════════════╗;
;║                                             Setup                                             ║;
;╚═══════════════════════════════════════════════════════════════════════════════════════════════╝;
#Requires AutoHotkey v1.1.33+
#SingleInstance force
#NoEnv
#Warn ; Enable warnings to assist with detecting common errors.
SendMode Input
SetWorkingDir %A_ScriptDir%
FileEncoding, UTF-16

;╔═══════════════════════════════════════════════════════════════════════════════════════════════╗;
;║                                           Variables                                           ║;
;╚═══════════════════════════════════════════════════════════════════════════════════════════════╝;
VERSION := 0.1
file := A_ScriptName
name := SubStr(file, 1, InStr(file, ".", , 0) - 1)
Global WINTITLE := A_Tab "✨" name "✨ " VERSION
Global settingsFileName := "settings.ini"
Global separator := "	" ; Tab
Global fileTypes := "html	css	js"
; Settings to include in the default ini file
Global settingsIni := "
(
[Settings]
Separator=	
FileTypes=html	css	js	cpp
[Hotstrings]
HS1=mg.
HL1=M.A.G.I.C.
HT1=global
HS2=for.
HL2=for(let i=0; i< ; i++){		}
HT2=js
HS3=.for
HL3=for(int i=0; i< ; i++){		}
HT3=cpp
)"

;╔═══════════════════════════════════════════════════════════════════════════════════════════════╗;
;║                                              GUI                                              ║;
;╚═══════════════════════════════════════════════════════════════════════════════════════════════╝;

FuncLoadGUI()
{
  xMg := 5
  yMg := 5
  xStart := 5
  yStart := 5
  Gui GUIOpt:New, +MaxSize640x480, % WINTITLE
  Gui GUIOpt:Color, 0XFFFFFF
  Gui GUIOpt:Margin, %xMg%, %yMg%
  Gui GUIOpt:Add, Text,		 x%xStart%	y%yStart%		h21	Section +0x200 , % "Profile"
  Gui GUIOpt:Add, ComboBox,	x+m			 w120 Limit
  Gui GUIOpt:Add, Button,		x+m			 w60		 h21					 , % "Save"
  Gui GUIOpt:Add, Button,		x+m			 w60		 h21 , % "Delete"
  Gui GUIOpt:Add, Button,		x+m			 w60		 h21 , % "Reset"
  
  Gui GUIOpt:Show
  funcUpdateGUI()
}

; Read Ini sections and create the GUI elements
funcUpdateGUI()
{
  ; Read sections
  IniRead, sectionList, %settingsFileName%, Hotstrings
  FuncMessageBox(sectionList)
}

;╔═══════════════════════════════════════════════════════════════════════════════════════════════╗;
;║                                              INI                                              ║;
;╚═══════════════════════════════════════════════════════════════════════════════════════════════╝;

; Create ini file or load it if present
FuncLoadIni(iniFile)
{
  if (!FileExist(iniFile))
  {
    ; if config file doesn't exist, create it
    FileAppend, % settingsIni, %iniFile%
    if (ErrorLevel == 1)
    {
      FuncMessageBox("Error")
      return
    }
  }
  ; Ini file exists  
  ; Try to load settings
  IniRead, varFileTypes, %settingsFileName%, Settings, FileTypes
  if(varFileTypes = "ERROR")
  {
    FuncMessageBox("Can't find Settings")
    FuncMessageBox(A_WorkingDir)
  }
}

FuncMessageBox(thisMessage)
{
  MsgBox, % thisMessage
}

FuncLoadGUI()
FuncLoadIni(settingsFileName)

