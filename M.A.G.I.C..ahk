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
Global fileTypes := "" ; All supported file types, A_Tab delimited
Global typesCheckboxes := [] ; The names of all checkbox GUI elements
Global iniOK := False
Global listRow := 0
Global firstCheckboxX := 5
Global firstCheckboxY := 411

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
Omit=Yes
Types=html	css	js	cpp
[HS2]
Short=for.
Long=for(let i=0; i< ; i++){		}
Omit=No
Types=js
[HS3]
Short=.for
Long=for(int i=0; i< ; i++){		}
Omit=Yes
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

Gui GUIOpt:Show, W640 H485

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
  ; ----- Create GUI elements -----
  Gui GUIOpt:New, -DPIScale, % WINTITLE
  Gui GUIOpt:Color, 0XFFFFFF
  Gui GUIOpt:Margin, %xMargin%, %yMargin%
  Gui GUIOpt:Add, Text, x%xStart%	y%yStart% h21	Section +0x200, % "Supported file types" ; 0x200 centers text vertically
  Gui GUIOpt:Add, Edit, w200 y+m r5 vEDFileTypes hwndTypesHandle,
  Gui GUIOpt:Add, Text, 		xp+0		y+20	w200		h1 	+0x10
  Gui GUIOpt:Add, Text, h21 +0x200, % "Hotstring Short"
  Gui GUIOpt:Add, Edit, w200 y+m r1 -VScroll vEDCurrentShort,
  Gui GUIOpt:Add, Text, h21 +0x200, % "Hotstring Long"
  Gui GUIOpt:Add, Edit, w200 y+m r10 vEDCurrentLong,
  Gui GUIOpt:Add, CheckBox, h21 +0x200 vCheckOmit, % "Omit trailing character"
  ; Draw checkboxes for the suport file types
  Gui GUIOpt:Add, Text, h21 +0x200, % "Hotstring File Types"
  FuncLoadCheckboxes()
  
  ; Draw the list of hotstrings
  Gui GUIOpt:Add, Text, h21 ys+0 +0x200, % "Hotstring List" ; ys draws the element on the next calculated column(y) in the section(s)
  Gui GUIOpt:Add, ListView, w425 y+m +AltSubmit vLVHotstrings gFuncHotstringGUI, Short|Long|Omit
  ; File types save button
  Gui GUIOpt:Add, Button, w85 gFuncSaveFileTypes, % "Save File Types"

  ; ----- Populate GUI elements ---
  ; Populate the Edit with the supported file types  
  FuncLoadFileTypes()

  ; Populate the List View with the current hotstrings
  Gui, ListView, LVHotstrings ; Select which ListView
  For index, hotstring in hotstringList
    LV_Add("", hotstringList[A_Index].Short, hotstringList[A_Index].Long, hotstringList[A_Index].Omit)

  ;LV_ModifyCol(1, "150")
  LV_ModifyCol()
  GuiControl, Focus, LVHotstrings ; Select the ListView GUI element
  LV_Modify(1, "+Select +Focus") ; Focus the first element in the List View
  ;FuncHotstringGUI() ;Load the hotstring info into the edit boxes
  ;GuiControl, , CBhtml, 1
}

; Save the files types in the ini file and update the checkboxes
FuncSaveFileTypes()
{
  GuiControlGet, edText, , EDFileTypes
  fileTypes := ""
  Loop, Parse, edText, `n`r
  {
    If (A_LoopField == "") ; Don't save empty lines
      Continue
    fileTypes := fileTypes A_LoopField A_Tab
  }
  fileTypes := Trim(fileTypes, A_Tab)
  ; Write to the settings.ini file
  IniWrite, %fileTypes%, %settingsFileName%, Settings, FileTypes
  FuncLoadCheckboxes()
}

; Read the filesTypes variable and update the file types edit box
FuncLoadFileTypes()
{
  local edText := ""
  Loop, Parse, fileTypes, %A_Tab%
  {
    If (A_LoopField == "") ; Don't load empty types
      Continue
    edText := edText A_LoopField "`n"
  }
  GuiControl, Text, EDFileTypes, %edText%
}

; Load the checkboxes with the list from the edit box
FuncLoadCheckboxes()
{
  Global ; Keyword needed to add GUI elements which require global labels
  Local typesArray := StrSplit(fileTypes, A_Tab)
  Local lastIndex := 0

  For typesIndex, currentType in typesArray
  {
    if(currentType == "")
    {
      Continue ; The user entered an empty line
    }
    
    Local checkboxName := % typesCheckboxes[typesIndex] ; build the name of the checkbox
    ; check if there is a corresponding checkbox in its name array
    if( checkboxName != "")
    {
      ; Make sure the checkbox is not hidden
      GuiControl, Text, % checkboxName, % typesArray[typesIndex] ; Set the appropriate text for the checkbox
    }
    Else ; We need to add new checkboxes in its name array
    {
      checkboxName := % "CB" typesCheckboxes.Count() + 1 ; build the name of the checkbox
      typesCheckboxes.Push(checkboxName)
      Gui GUIOpt:Add, Checkbox, x-100 y-100 h21 w50 +0x100 v%checkboxName%, % currentType
    }
    lastIndex := typesIndex

    ; Place the checkboxes properly
    Local theX := firstCheckboxX + Mod(typesIndex - 1, 4) * 50 ; Determine the x offset
    Local theY := firstCheckboxY + Floor((typesIndex - 1)/4) * 26
    
    GuiControl, Move, %checkboxName%,  x%theX% y%theY%
    GuiControl, Show, %checkboxName% ; Show the checkbox
  }

  ; Hide the checkboxes that won't be used
  Local loopCount := % typesCheckboxes.Count() - typesArray.Count()  
  Loop, % loopCount
  {
    Local nextBox := typesCheckboxes[lastIndex + A_Index]
    GuiControl, Hide, %nextBox%
  }
}

FuncLoadCheckboxes2()
{
  Global
  Loop, Parse, fileTypes, %A_Tab%
  {
    Local theX := Mod(A_Index - 1, 4) * 50 ; Determine the x offset
    Local labelCheckbox := "CB" A_Index
    
    If ( (Mod(A_Index, 4) ) == 1 )
      Gui GUIOpt:Add, Checkbox, xs+%theX%    h21 w50 +0x100 v%labelCheckbox%, % A_LoopField
    Else
      Gui GUIOpt:Add, Checkbox, xs+%theX% yp h21 w50 +0x100 v%labelCheckbox%, % A_LoopField
    typesCheckboxes.Push(labelCheckbox)
    If(A_Index == 1)
    {
      ;firstCheckboxX =: 0
      ;firstCheckboxY =: 0
      ;GuiControlGet, firstCheckbox, Pos, %labelCheckbox% ; Save the position to global variables firstCheckboxX and firstCheckboxY
    }
  }
}

FuncHotstringGUI()
{
  ; Avoid multiple successful calls
  If(listRow == LV_GetNext(, "F") || LV_GetNext(, "F") == 0)
    Return
  listRow := LV_GetNext()

  ; Check if the hoststring list is empty
  if(LV_GetCount() == 0)
    Return
  
  currentRow := LV_GetNext()
  ; Cycle through all the hotstrings in the List View
  Loop % LV_GetCount("Column")
  {
    If (A_Index == 1) ; Hotstring short
    {
      LV_GetText(edText, currentRow, 1)
      GuiControl, , EDCurrentShort, % edText
    }
    If (A_Index == 2) ; Hotstring long
    {
      LV_GetText(edText, currentRow, 2)
      GuiControl, , EDCurrentLong, % edText
    }
    If (A_Index >= 3) ; Hotstring omit
    {
      LV_GetText(edText, currentRow, 3)
      edText := edText == "Yes" ? 1 : 0 ; Translate Yes/No to 1/0
      GuiControl, , CheckOmit, % edText
    }
  }
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