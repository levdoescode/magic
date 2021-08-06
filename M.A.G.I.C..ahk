;╔═══════════════════════════════════════════════════════════════════════════════════════════════╗;
;║                                             Setup                                             ║;
;╚═══════════════════════════════════════════════════════════════════════════════════════════════╝;
#Requires AutoHotkey v1.1.33+
#SingleInstance force
#NoEnv
#Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input
SetWorkingDir %A_ScriptDir%
FileEncoding, UTF-16

;╔═══════════════════════════════════════════════════════════════════════════════════════════════╗;
;║                                           Variables                                           ║;
;╚═══════════════════════════════════════════════════════════════════════════════════════════════╝;
VERSION := 0.1
file := A_ScriptName
name := SubStr(file, 1, InStr(file, ".", , 0) - 1)
WINTITLE := "✨" name "✨ " VERSION

;╔═══════════════════════════════════════════════════════════════════════════════════════════════╗;
;║                                              GUI                                              ║;
;╚═══════════════════════════════════════════════════════════════════════════════════════════════╝;

xMg := 5
yMg := 5
xStart := 5
yStart := 5
Gui GUIOpt:New, AlwaysOnTop +Resize +MinSize640x480, % WINTITLE
;Gui GUIOpt:Color, 0XAAAADD
Gui GUIOpt:Margin, %xMg%, %yMg%
Gui GUIOpt:Add, Text,		x%xStart%	y%yStart%		h21	Section +0x200				, % "Profile"
Gui GUIOpt:Add, ComboBox,	x+m			w120			  Limit
Gui GUIOpt:Add, Button,		x+m			w60		h21					, % "Save"
Gui GUIOpt:Add, Button,		x+m			w60		h21	 	, % "Delete"
Gui GUIOpt:Add, Button,		x+m			w60		h21	 	, % "Reset"
Gui GUIOpt:Show

FuncLoadIni("settings.ini")

; Create ini file or load it if present
FuncLoadIni(iniFile)
{
  if (!FileExist(iniFile))
  {
    ; if config file doesn't exist, create it
    FileAppend, % "", %iniFile%
    if (ErrorLevel = 1)
    {
      FuncMessageBox("Error")
      return
    }
  }
  ;lel := "lelx"
  ;MsgBox, %lel%
}

FuncMessageBox(thisMessage)
{
  MsgBox, % thisMessage
}

settingsInix :=
"
(
[Global_Settings]
HotShort1=mg.
HotLong1=M.A.G.I.C.
)"