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

xMargin := 5
yMargin := 5
xPos    := 5
yPos    := 5
Gui GUIMain:New
Gui GUIOpt:Margin, %xMargin%, %yMargin%
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
  lel := "lelx"
  MsgBox, lel
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