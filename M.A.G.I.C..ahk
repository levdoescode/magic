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
[HS1]
Short=mg.
Long=M.A.G.I.C.
Omit=true
Types=html	css	js	cpp
[HS2]
Short=for.
Long=for(let i=0; i< ; i++){		}
Omit=true
Types=js
[HS3]
Short=.for
Long=for(int i=0; i< ; i++){		}
Omit=true
Types=cpp
)"

;╔═══════════════════════════════════════════════════════════════════════════════════════════════╗;
;║                                           START CODE                                          ║;
;╚═══════════════════════════════════════════════════════════════════════════════════════════════╝;

FuncLoadIni(settingsFileName)
Gosub, LablStartGUI

;╔═══════════════════════════════════════════════════════════════════════════════════════════════╗;
;║                                              GUI                                              ║;
;╚═══════════════════════════════════════════════════════════════════════════════════════════════╝;
; Can't be a function because GUI elements need a global variable and they can't be created
; dynamically e.g. %A_Loop%Short inside a function, only in labels, which LablStartGUI calls
LablStartGUI:
  xMg := 5 ; margin in pixels
  yMg := 5 ; margin in pixels
  xStart := 5 ; starting x position
  yStart := 5 ; starting y position
  Gui GUIOpt:New, , % WINTITLE
  Gui GUIOpt:Color, 0XFFFFFF
  Gui GUIOpt:Margin, %xMg%, %yMg%
  Gui GUIOpt:Add, Text,		 x%xStart%	y%yStart%		h21	Section +0x200 , % "Hotstring list"
  ;Gui GUIOpt:Add, ComboBox,	y+m			 w120 Limit
  ;Gui GUIOpt:Add, Button,		x+m			 w60		 h21 , % "Save"
  ;Gui GUIOpt:Add, Button,		x+m			 w60		 h21 , % "Delete"
  ;Gui GUIOpt:Add, Button,		x+m			 w60		 h21 , % "Reset"
  Gosub, FuncLoadHotGUI
  GuiControl, Focus, HS2Short
  Gui GUIOpt:Show
return

; Read Ini sections and create the GUI elements
FuncLoadHotGUI:

  HSPreffix := "::"
  HSPreffixO := ":O:"
  ; Read the list sections
  IniRead, sectionList, %settingsFileName%
  ;FuncMessageBox(sectionList)
  Loop, Parse, sectionList, `n
  {
    If(A_Loopfield == "Settings")
      Continue
    If(A_LoopField != "HS2")
      Continue
    ; Read the values for the current section
    IniRead, HSShort, %settingsFileName%, %A_LoopField%, Short
    IniRead, HSLong , %settingsFileName%, %A_LoopField%, Long
    IniRead, HSOmit , %settingsFileName%, %A_LoopField%, Omit
    IniRead, HSTypes, %settingsFileName%, %A_LoopField%, Types
    ; Confirm all values are valid
    If(HSShort != "ERROR" && HSLong != "ERROR" && HSTypes != "ERROR")
    {
      ; Replace all tabs for line feeds in the snippet
      HSLong := StrReplace(HSLong, A_Tab, "`n")
      ; Implement the hotstrings
      If(HSOmit == "true")
        Hotstring(HSPreffixO HSShort, HSLong, "On")
      Else If(HSOmit == "false")
        Hotstring(HSPreffix HSShort, HSLong, "On")
      
      ; Create the GUI elements for the current hotstring
      ;Global labelShort
      labelShort := A_LoopField "Short"
      Gui GUIOpt:Add, Edit,	y+m w120 h21 v%labelShort% Section, % HSShort

      ;Global labelLong
      labelLong  := A_LoopField "Long"
      Gui GUIOpt:Add, Edit,	x+m w120 h21 v%labelLong%         , % HSLong
      
      ; Read all file types valid for the current hotstring
      Loop, Parse, HSTypes, %A_Tab%
      {
        ;FuncMessageBox(A_LoopField)
      }
    }
    Break
  }
return

;╔═══════════════════════════════════════════════════════════════════════════════════════════════╗;
;║                                              INI                                              ║;
;╚═══════════════════════════════════════════════════════════════════════════════════════════════╝;

; Create ini file or load it If present
FuncLoadIni(inIfile)
{
  If (!FileExist(inIfile))
  {
    ; If config file doesn't exist, create it
    FileAppend, % settingsIni, %inIfile%
    If (ErrorLevel == 1)
    {
      FuncMessageBox("Error")
      return
    }
  }
  ; Ini file exists  
  ; Try to load settings
  IniRead, varFileTypes, %settingsFileName%, Settings, FileTypes
  If(varFileTypes = "ERROR")
  {
    FuncMessageBox("Can't find Settings")
    FuncMessageBox(A_WorkingDir)
  }
}

FuncMessageBox(thisMessage)
{
  MsgBox, % thisMessage
}
