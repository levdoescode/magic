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
Global hotstringList := [] ; Saved hotstrings will be loaded here
Global fileTypes := ""
Global iniOK := False
Global listRow := 0

Global settingsFileName := "settings.ini"
Global separator := "	" ; Tab

; Settings to include in the default ini file
Global settingsIni := "
(
[Settings]
Separator=	
FileTypes=html	css	js	cpp	h	txt	ahk
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
FuncLoadGUI()
;FuncLoadHotstrings()
; GuiControl, Focus, EDFileTypes ; Set focus so text is not highlighted
; SendMessage, 0xB1, -2, -1, , ahk_id %TypesHandle% ; Send the cursor to the end of the edit box

Gui GUIOpt:Show, W640 H480

;LVChange()
Return
;╔═══════════════════════════════════════════════════════════════════════════════════════════════╗;
;║                                              GUI                                              ║;
;╚═══════════════════════════════════════════════════════════════════════════════════════════════╝;
FuncLoadGUI()
{
  Global ; Required to make GUI element labels e.g. vEDFileTypes accessible to other functions
  xMargin := 5 ; margin in pixels
  yMargin := 5 ; margin in pixels
  xStart := 5 ; starting x position
  yStart := 5 ; starting y position
  Gui GUIOpt:New, -DPIScale, % WINTITLE
  Gui GUIOpt:Color, 0XFFFFFF
  Gui GUIOpt:Margin, %xMargin%, %yMargin%
  Gui GUIOpt:Add, Text, x%xStart%	y%yStart% h21	Section +0x800200, % "Supported file types" ; 0x200 centers text vertically
  Gui GUIOpt:Add, Edit, w200 y+m r5 vEDFileTypes hwndTypesHandle,
  Gui GUIOpt:Add, Text, h21 +0x800200, % "Current Hotstring Short"
  Gui GUIOpt:Add, Edit, w200 y+m r1 -VScroll vEDCurrentShort,
  Gui GUIOpt:Add, Text, h21 +0x800200, % "Current Hotstring Long"
  Gui GUIOpt:Add, Edit, w200 y+m r10 vEDCurrentLong,
  ; Draw checkboxes for the suport file types
  Gui GUIOpt:Add, Text, h21 +0x800200, % "Current Supported File Types"
  Loop, Parse, fileTypes, %A_Tab%
  {
    theX := Mod(A_Index - 1, 4) * 50 ; Determine the x offset
    If ( (Mod(A_Index, 4) ) == 1 )
    {
      Gui GUIOpt:Add, Checkbox, xs+%theX% h21 +0x200, % A_LoopField
    }
    Else
    {
      Gui GUIOpt:Add, Checkbox, xs+%theX% yp h21 +0x200, % A_LoopField
    }
  }
  ; Draw the list of hotstrings
  Gui GUIOpt:Add, Text, h21 ys+0 +0x800200, % "Hotstring List" ; ys draws the element on the next calculated column(y) in the section(s)
  Gui GUIOpt:Add, ListView, w300 y+m +AltSubmit vLVHotstrings gLVChange, Short|Long|Omit

  ; Populate the Edit with the supported file types  
  edText := ""
  Loop, Parse, fileTypes, %A_Tab%
    edText := edText A_LoopField "`n"
  GuiControl, Text, EDFileTypes, %edText%

  ; Populate the List View with the current hotstrings
  Gui, ListView, LVHotstrings ; Select which ListView
  For index, hotstring in hotstringList
  {
    LV_Add("", hotstringList[A_Index].Short, hotstringList[A_Index].Long, hotstringList[A_Index].Omit)
  }
  ;LV_ModifyCol(1, "150")
  GuiControl, Focus, LVHotstrings ; Select the ListView GUI element
  LV_ModifyCol()
  LV_Modify(1, "+Select +Focus") ; Focus the first element in the List View
}

; Load hotstrings from the hotstrings list
FuncLoadHotstrings()
{
  ;FuncMessageBox(sectionList)
  Loop, Parse, sectionList, `n
  {
    If(A_Loopfield == "Settings")
      Continue
    If(A_LoopField != "HS2")
      Continue
    
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
}

;╔═══════════════════════════════════════════════════════════════════════════════════════════════╗;
;║                                              INI                                              ║;
;╚═══════════════════════════════════════════════════════════════════════════════════════════════╝;

; Create ini file, load it if present, update hotstring list and file types variables
FuncLoadIni(inIfile)
{
  ; ==================================================
  ; If config file doesn't exist, create it with default settings
  If (!FileExist(inIfile))
  {
    
    FileAppend, % settingsIni, %inIfile%
    If (ErrorLevel == 1)
    {
      FuncMessageBox("Can't create the settings file")
      Return
    }
  }
  ; ==================================================
  ; Ini file exists, load settings
  HSPreffix := "::"
  HSPreffixO := ":O:"
  ; Read the list of sections
  IniRead, sectionList, %settingsFileName%
  If(sectionList = "ERROR")
  {
    FuncMessageBox("Can't read the settings file")
    Return
  }
  
  ; Loop through the ini sections and load hotstrings
  Loop, Parse, sectionList, `n
  {
    If(A_Loopfield == "Settings")
    {
      IniRead, fileTypes, %settingsFileName%, Settings, FileTypes
      If(fileTypes = "ERROR")
      {
        FuncMessageBox("Can't find the settings file")
        Return
      }
      Continue
    }
    
    ; All sections after Settings will contain a hotstring
    ; Read the values for the current section
    IniRead, HSShort, %settingsFileName%, %A_LoopField%, Short
    IniRead, HSLong , %settingsFileName%, %A_LoopField%, Long
    IniRead, HSOmit , %settingsFileName%, %A_LoopField%, Omit
    IniRead, HSTypes, %settingsFileName%, %A_LoopField%, Types
    ; Confirm all values are valid
    If(HSShort != "ERROR" && HSLong != "ERROR" && HSOmit != "ERROR" && HSTypes != "ERROR")
    {
      ; Replace all tabs for line feeds in the snippet
      HSLong := StrReplace(HSLong, A_Tab, "`n")
      thisHotstring := {Long: HSLong, Short: HSShort, Omit: HSOmit, Types: HSTypes} ; Build the associative array
      hotstringList.Push(thisHotstring) ; push it to the hotstring array
      ; FuncMessageBox(thisHotstring["Long"]) ; Proper way to read the value of the associative array
      ; FuncMessageBox(hotstringList[1].Long) ; Proper way to read the hoststring array values
      ; FuncMessageBox(hotstringList[hotstringList.MaxIndex()].Long) ; Read property of the last added item
    }
  }

  ; Check if valid hotstrings were read
  if(hotstringList.Count() > 0)
    iniOK := True
}

FuncMessageBox(thisMessage)
{
  MsgBox, % thisMessage
}

; Load the hotstring
LVChange()
{
  ; Avoid multiple successful calls
  If(listRow == LV_GetNext(, "F") || LV_GetNext(, "F") == 0)
    Return
  listRow := LV_GetNext()

  ; Load the edit boxes with the hotstring text
}