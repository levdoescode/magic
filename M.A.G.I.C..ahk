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
SetTitleMatchMode, 2

;╔═══════════════════════════════════════════════════════════════════════════════════════════════╗;
;║                                           Variables                                           ║;
;╚═══════════════════════════════════════════════════════════════════════════════════════════════╝;
VERSION := 0.7
file := A_ScriptName
name := SubStr(file, 1, InStr(file, ".", , 0) - 1)
Global WINTITLE := A_Tab "✨" name "✨ " VERSION
Global hotstringList := [] ; Saved hotstrings will be loaded here
Global fileTypes := "" ; All supported file types, A_Tab delimited
Global typesCheckboxes := [] ; The names of all checkbox GUI elements
Global extDiv := "■"
Global yesText := "⬤"
Global noText := "◯"
Global iniOK := False
Global listRow := 0
Global firstCheckboxX := 5
Global firstCheckboxY := 411
Global newHotstringstate := 0
Global firstLoad := True
Global loadingHotGUI := True

Global settingsFileName := "settings.ini"
Global separator := "	" ; Tab

; Settings to include in the default ini file
Global settingsIni := "
(
[Settings]
Separator=	
FileTypes=html,css,js,cpp,h,txt,ahk,ini
[HS1]
Short=mg.
Long=M.A.G.I.C.
Omit=Yes
Types=
[HS2]
Short=sy.
Long=Sincerely yours,
Omit=Yes
Types=
[HS3]
Short=for.
Long=for(let i=0; i< ; i++){■■}
Omit=Yes
Types=js
[HS4]
Short=for.
Long=for(int i=0; i< ; i++){■■■}
Omit=Yes
Types=cpp,ini
)"

;╔═══════════════════════════════════════════════════════════════════════════════════════════════╗;
;║                                           START CODE                                          ║;
;╚═══════════════════════════════════════════════════════════════════════════════════════════════╝;

FuncLoadIni(settingsFileName)
FuncLoadAllHotstrings()
FuncLoadGUI()
Gui GUIOpt:Show, W840 H509
listRow := 0
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
  Gui GUIOpt:Add, Text, x%xStart%	y%yStart% h21	Section +0x200, % "File types" ; 0x200 centers text vertically
  Gui GUIOpt:Add, Edit, w200 y+m r5 vEDFileTypes hwndTypesHandle,
  Gui GUIOpt:Add, Text, 		xp+0		y+20	w200		h1 	+0x10
  Gui GUIOpt:Add, Text, h21 +0x200, % "Hotstring Short Text"
  Gui GUIOpt:Add, Edit, w200 y+m r1 -VScroll gFuncEditShort vEDCurrentShort,
  Gui GUIOpt:Add, Text, h21 +0x200, % "Hotstring Expanded Text"
  Gui GUIOpt:Add, Edit, w200 y+m r10 gFuncEditLong vEDCurrentLong,
  Gui GUIOpt:Add, CheckBox, h21 +0x200 vCBOmit, % "Omit trigger character"
  Gui GUIOpt:Add, StatusBar, , % "Delete the settings.ini file if you run into issues"
  ; Draw checkboxes for the suport file types
  Gui GUIOpt:Add, Text, h21 +0x200, % "Hotstring File Types"
  FuncLoadCheckboxes()

  ; Draw the list of hotstrings
  Gui GUIOpt:Add, Text, h21 ys+0 +0x200, % "Hotstring List" ; ys draws the element on the next calculated column(y) in the section(s)
  Gui GUIOpt:Add, ListView, w625 r23 y+m +AltSubmit vLVHotstrings gFuncHotstringToGUI, Short|Extended|Omit
  ; File types save button
  Gui GUIOpt:Add, Button, y+m w95 vBTNewHotstring gFuncSaveHotstring, % "New Hotstring"
  Gui GUIOpt:Add, Button, x+m w85 vBTDeleteHotstring gFuncDeleteHotstring +0x8000000, % "Delete Hotstring"
  Gui GUIOpt:Add, Button, x+m w85 gFuncMinimize, % "Minimize"
  Gui GUIOpt:Add, Button, x+m w85 gFuncExit, % "Exit"
  Gui GUIOpt:Add, Button, x125 y5 w80 gFuncSaveFileTypes, % "Save Types"
  Gui GUIOpt:Add, Button, x125 y133 w80 gFuncUpdateHotstring vBTUpdate +0x8000000, % "Update"
  

  ; ----- Populate GUI elements ---
  ; Populate the Edit with the supported file types  
  FuncLoadFileTypes()

  ; Populate the List View with the current hotstrings
  Gui, ListView, LVHotstrings ; Select which ListView
  For index, hotstring in hotstringList
    LV_Add("", hotstringList[A_Index].Short, hotstringList[A_Index].Long, hotstringList[A_Index].Omit)
  FuncLoadListView() ; Load the supported file types columns
  
  ;Adjust the List View Column widths
  LV_ModifyCol(1, "75")
  LV_ModifyCol(2, "125")
  LV_ModifyCol(3, "50 Center")

  ; Load the hotstring info into the edit boxes
  ;GuiControl, Focus, LVHotstrings ; Select the ListView GUI element
  ;LV_Modify(1, "+Select +Focus") ; Focus the first element in the List View
}

; Update a hotstring when a ListView item is selected
FuncUpdateHotstring()
{
  MsgBox, 8196, % "Are you sure?", % "Do you want to update the current hotstring?"
  IfMsgBox, Yes
  {
    ; Load the last saved values
    thisHotIndex := LV_GetNext()
    hotShort := hotstringList[thisHotIndex].Short
    hotLong  := hotstringList[thisHotIndex].Long
    hotOmit  := hotstringList[thisHotIndex].Omit
    hotTypes := hotstringList[thisHotIndex].Types

    ; Update the hotstring and load it
    GuiControlGet, edShort, , EDCurrentShort
    GuiControlGet, edLong , , EDCurrentLong
    GuiControlGet, edOmit , , CBOmit
    edOmit := edOmit == 1 ? "Yes" : "No" ; Translate 1/0 to Yes/No
    edTypes := FuncGetTypesCheckboxes()
    
    ; Check if the values have changed
    If (hotShort == edShort && hotLong == edLong && hotOmit == edOmit && hotTypes == edTypes)
    {
      SB_SetText("The Short and Long are the same. No changes have been saved!")
      Return
    }
    FuncDisableHotstring(hotShort, hotOmit, hotTypes)

    ; Update the array
    newHot := {Short: edShort, Long: edLong, Omit: edOmit, Types: edTypes}
    hotstringList[thisHotIndex] := newHot
    FunLoadHotstring(edShort, edLong, edOmit, edTypes)
    IniWrite, % edShort, %settingsFileName%, % "HS" thisHotIndex, % "Short"
    IniWrite, % edLong , %settingsFileName%, % "HS" thisHotIndex, % "Long"
    IniWrite, % edOmit , %settingsFileName%, % "HS" thisHotIndex, % "Omit"
    IniWrite, % edTypes, %settingsFileName%, % "HS" thisHotIndex, % "Types"
    SB_SetText("The Hotstring changes have been saved")
  }
  Else
  {
    IfMsgBox, No
    {
      SB_SetText("No changes were made")
    }
  }
  FuncLoadListView()
}

; Check if long is being edited
FuncEditLong()
{
  GuiControlGet, focusedControl, FocusV
  If (LV_GetNext() != 0 && focusedControl == "EDCurrentLong")
  {
    GuiControl, -0x8000000, BTUpdate ; Enable the hotstring update button
  }
}

; Check if short is being edited
FuncEditShort()
{
  ;listPicked := LV_GetNext()
  GuiControlGet, edShort, , EDCurrentShort
  ; Edit the new hotstring button
  If (edShort != "" && LV_GetNext() == 0 && newHotstringState == 0) ; No List View item is selected
  {
    GuiControl, , BTNewHotstring, % "Save Hotstring" ; Change the text in the button
    newHotstringState := 1
    GuiControl, +0x8000000, BTUpdate ; Disable the hotstring update button
    SB_SetText("Enter short and expanded texts - No file types checkboxes result in a global Hotstring - The omit checkbox will delete the Space character that triggers the Hotstring")
  }
  Else
  {
    If (LV_GetNext() != 0 && newHotstringstate == 1)
    {
      GuiControl, , BTNewHotstring, % "New Hotstring" ; Change the text in the button
      newHotstringState := 0
    }

    GuiControlGet, focusedControl, FocusV
    If(LV_GetNext() != 0 && focusedControl == "EDCurrentShort" && edShort != "")
    {
      GuiControl, -0x8000000, BTUpdate ; Enable the hotstring update button
    }
    Else If (listRow != 0)
    {
      GuiControl, +0x8000000, BTUpdate ; Disable the hotstring update button
    }
  }
}

; Create a new Hotstring from the GUI and load it
FuncSaveHotstring()
{
  GuiControl, +0x8000000, BTUpdate ; Disable the hotstring update button
  If (newHotstringState == 0)
  {
    ; Unselect the list view
    currentRow := LV_GetNext()
    LV_Modify(0, "+Select +Focus")
    LV_Modify(0, "-Select -Focus")
    GuiControl, , BTNewHotstring, % "Save Hotstring" ; Change the text in the button
    ; Clear edit boxes and checkboxes
    GuiControl, , EDCurrentShort, % ""
    GuiControl, , EDCurrentLong, % ""
    ; Clear the checkboxes
    GuiControl, , CBOmit, % 0
    For typesIndex, currentCheckbox in typesCheckboxes
      GuiControl, , %currentCheckbox%, % 0
    GuiControl, Focus, EDCurrentShort
    newHotstringState := 1
    SB_SetText("Enter short and expanded texts - No file types checkboxes result in a global Hotstring - The omit checkbox will delete the Space character that triggers the Hotstring")
  }
  Else If (newHotstringState == 1)
  {
    GuiControlGet, edShort, , EDCurrentShort
    GuiControlGet, edLong , , EDCurrentLong
    If (Trim(edShort) == "" || Trim(edLong) == "")
    {
      SB_SetText("Can't save an empty Hotstring - Enter the short and expanded text")
    }
    Else
    {
      ; Save the new hotstring
      GuiControlGet, edOmit, , CBOmit
      edOmit := edOmit == 1 ? "Yes" : "No" ; Translate 1/0 to Yes/No
      ; Translate files checkboxes to a string
      edTypes := ""
      For boxIndex, currentBox in typesCheckboxes
      {
        GuiControlGet, boxCheck, , % currentBox
        If (boxCheck == 1)
        {
          GuiControlGet, boxType , , % currentBox, Text ; Retrieve the text of the checkbox type
          edTypes := edTypes boxType ","
        }
      }
      edTypes := Trim(edTypes, ",")
      
      ; Add the hotstring to the array
      thisHotstring := {Long: edLong, Short: edShort, Omit: edOmit, Types: edTypes} ; Build the associative array
      hotstringList.Push(thisHotstring) ; push it to the hotstring array

      ; Save the hotstring array to the ini file
      ; Delete all hotstrings in the ini file first
      IniRead, sectionList, %settingsFileName%
      If (sectionList = "ERROR")
      {
        FuncMessageBox("Can't read the settings file")
        hotstringList.Pop()
        Return
      }
      Loop, Parse, sectionList, `n ; Loop through the ini sections and delete the hotstrings
      {
        If (A_Loopfield == "Settings")
          Continue
        IniDelete, %settingsFileName%, % A_LoopField
      }
      ; Loop through the hotstring array and write to the ini file
      For hotIndex, currentHot in hotstringList
      {
        sectionName := "HS" hotIndex
        edLong := StrReplace(currentHot["Long"], "`n", extDiv) ; Convert from array format to ini format
        IniWrite, % currentHot["Short"], %settingsFileName%, % sectionName, % "Short"
        IniWrite, % edLong, %settingsFileName%, % sectionName, % "Long"
        IniWrite, % currentHot["Omit"] , %settingsFileName%, % sectionName, % "Omit"
        IniWrite, % currentHot["Types"] , %settingsFileName%, % sectionName, % "Types"
      }
      
      ; Add hotstring to the end of the ListView
      LV_Add("", currentHot["Short"], currentHot["Long"], currentHot["Omit"])
      FuncLoadListView() ; Will populate the file types columns
      FunLoadHotstring(currentHot["Short"], currentHot["Long"], currentHot["Omit"], currentHot["Types"]) ; Load the new Hotstring
      
      ; Clear the edit boxes and reset the butotn text
      ;GuiControl, , newHotstringstate, % "New Hotstring" ; Change the text in the button
      GuiControl, , EDCurrentShort, % ""
      GuiControl, , EDCurrentLong , % ""
      ; Clear the checkboxes
      GuiControl, , CBOmit, % 0
      For typesIndex, currentCheckbox in typesCheckboxes
        GuiControl, , %currentCheckbox%, % 0
      GuiControl, Focus, EDCurrentShort
      ;newHotstringState := 0
      SB_SetText("New Hotstring Saved and Loaded!") ; Update the status bar
    }
  }
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
    fileTypes := FileTypes A_LoopField ","
  }
  
  fileTypes := Trim(fileTypes, ",")
  ; Write to the settings.ini file
  IniWrite, %fileTypes%, %settingsFileName%, Settings, FileTypes
  FuncLoadCheckboxes()
  FuncLoadListView()
  SB_SetText("File type changes saved!") ; Update the status bar
}

; Read the filesTypes variable and update the file types edit box
FuncLoadFileTypes()
{
  local edText := ""
  Loop, Parse, fileTypes, % ","
  {
    If (A_LoopField == "") ; Don't load empty types
      Continue
    edText := edText A_LoopField "`n"
  }
  GuiControl, Text, EDFileTypes, %edText%
}

; Load the ListView
FuncLoadListView()
{
  ; Check there is at least 1 row in the List View
  LV_GetText(testRow, 1, 1)
  If( testRow == "" )
    Return
  ; Get the list of currently supported file types
  typesArray := StrSplit(fileTypes, ",")
  ; Update the columns

  For typesIndex, currentType in typesArray
  {
    ; Add or modify column
    If( LV_GetCount("Column") - 3 < typesIndex ) ; Column doesn't exist, add it
    {
      LV_InsertCol(200, " 50 Center", currentType) ; Add to the last possible column, 200
    }
    ; Update the column headers
    LV_ModifyCol(3 + typesIndex, , currentType)
  }
  ; Destroy columns no longer in use
  loopCount := % LV_GetCount("Column") - 3 - typesArray.Count()
  Loop, % loopCount
  {
    LV_DeleteCol(LV_GetCount("Column"))
  }
  
  ; Populate the columns with the supported file types
  For hotIndex, currentHot in hotstringList ; Loop through the hotstring list
  {
    For typesIndex, currentType in typesArray ; Loop through the supported files array
    {
      colNum := "Col" 3+typesIndex
      LV_Modify(hotIndex, colNum, noText) ; Default value
      Loop, Parse, % currentHot.Types, % "," ; Loop through the supported files in the current hotstring
      {
        If ( currentType == Trim(A_LoopField) )
        {
          LV_Modify(hotIndex, colNum, yesText)
          Break
        }
      }
    }
  }

  For hotIndex, hotCurrent in hotstringList
  {
    LV_Modify(hotIndex, "Col1", hotstringList[hotIndex].Short)
    LV_Modify(hotIndex, "Col2", hotstringList[hotIndex].Long)
    LV_Modify(hotIndex, "Col3", hotstringList[hotIndex].Omit)
  }
}

; Load the checkboxes with the list from the edit box
FuncLoadCheckboxes()
{
  Global ; Keyword needed to add GUI elements which require global labels
  Local typesArray := StrSplit(fileTypes, ",")
  Local typesIndex, currentType
  Local lastIndex := 0
  
  For typesIndex, currentType in typesArray
  {
    if( currentType == "" )
    {
      Continue ; The user entered an empty line
    }

    Local checkboxName := % typesCheckboxes[typesIndex] ; build the name of the checkbox
    ; check if there is a corresponding checkbox in its name array
    if( checkboxName != "" )
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

    GuiControl, Move, %checkboxName%, x%theX% y%theY%
    GuiControl, Show, %checkboxName% ; Show the checkbox
  }

  ; Hide the checkboxes that won't be used
  Local loopCount := % typesCheckboxes.Count() - typesArray.Count() 
  Loop, % loopCount
  {
    Local nextBox := typesCheckboxes[lastIndex + A_Index]
    GuiControl, Hide, %nextBox%
  }
  GuiControl, Focus, EDFileTypes
}

; Populate the GUI elements with the data from the selected hotstring on the List View
FuncHotstringToGUI()
{
  If(LV_GetNext() != 0)
  {
    GuiControl, +0x8000000, BTUpdate ; Disable the hotstring update button
    GuiControl, -0x8000000, BTDeleteHotstring 
  }
  Else
  {
    GuiControl, +0x8000000, BTDeleteHotstring 
  }
  ; Check and restore the save hotstring button
  If (LV_GetNext() != 0 && newHotstringState == 1)
  {
    GuiControl, , BTNewHotstring, % "New Hotstring" ; Change the text in the button
    newHotstringState := 0
  }
  If (LV_GetNext() == 0)
  {
    GuiControl, , BTNewHotstring, % "New Hotstring" ; Change the text in the button
    newHotstringState := 0
  }
  ; Avoid multiple successful calls
  If(listRow == LV_GetNext(, "F") || LV_GetNext(, "F") == 0)
  {
    if(LV_GetNext() == 0)
    {
      Loop % LV_GetCount("Column")
        GuiControl, , % typesCheckboxes[A_Index], % 0
      GuiControl, , EDCurrentShort, % ""
      GuiControl, , EDCurrentLong, % ""
      GuiControl, , CBOmit, % 0
      Return
    }
  }
  ; Check if the hoststring list is empty
  if(LV_GetCount() == 0)
    Return
  
  ; Cycle through all the hotstrings in the List View
  listRow := LV_GetNext()
  Loop % LV_GetCount("Column")
  {
    If (A_Index == 1) ; Hotstring short
    {
      LV_GetText(edText, listRow, 1)
      GuiControl, , EDCurrentShort, % edText
      Continue
    }
    If (A_Index == 2) ; Hotstring long
    {
      LV_GetText(edText, listRow, 2)
      GuiControl, , EDCurrentLong, % edText
      Continue
    }
    If (A_Index == 3) ; Hotstring omit
    {
      LV_GetText(edText, listRow, 3)
      edText := edText == "Yes" ? 1 : 0 ; Translate Yes/No to 1/0
      GuiControl, , CBOmit, % edText
      Continue
    }
    
    ; Populate the typesCheckboxes
    LV_GetText(edText, listRow, A_Index) ; Get the text in the column
    edText := edText == yesText ? 1 : 0 ; Translate Yes/No to 1/0
    checkboxName := % typesCheckboxes[A_Index - 3] ; build the name of the checkbox
    GuiControl, , %checkboxName%, % edText
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
      HSLong := StrReplace(HSLong, extDiv, "`n")
      thisHotstring := {Short: HSShort, Long: HSLong, Omit: HSOmit, Types: HSTypes} ; Build the associative array
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

;╔═══════════════════════════════════════════════════════════════════════════════════════════════╗;
;║                                          HOTSTRINGS                                           ║;
;╚═══════════════════════════════════════════════════════════════════════════════════════════════╝;

; Load all hotstrings loaded by FuncLoadIni or added afterwards
FuncLoadAllHotstrings()
{
  For hotIndex, hotCurrent in hotstringList
  {
    FunLoadHotstring(hotCurrent["Short"], hotCurrent["Long"], hotCurrent["Omit"], hotCurrent["Types"]) ; Load the new Hotstring
  }
}

; Implement a hotstring contextually or not
FunLoadHotstring(short, long, omit, types)
{
  long := StrReplace(long, "{", "⦃⦃")
  long := StrReplace(long, "}", "⦄⦄")
  long := StrReplace(long, "⦃⦃", "{{}")
  long := StrReplace(long, "⦄⦄", "{}}")
  long := StrReplace(long, "#", "{#}")
  long := StrReplace(long, "!", "{!}")
  long := StrReplace(long, "^", "{^}")
  long := StrReplace(long, "+", "{+}")
  long := StrReplace(long, "&", "{&}")

  ; Translate omit's Yes/No to the appropriate hotstring prefix
  HSPreffix := omit == "Yes" ? ":O:" : "::"
  If (types == "")
  {
    Hotstring(HSPreffix short, long, "On")
  }
  Else
  {
    Loop, Parse, types, % ","
    {
      Hotkey, IfWinActive, % Trim(A_LoopField)
      Hotstring(HSPreffix short, long, "On")
      Hotkey, IfWinActive
    }
  }
}

; Remove hotstrings and all
FuncDeleteHotstring()
{
  rowIndex := LV_GetNext()
  If(rowIndex == 0)
    Return
  LV_Delete(rowIndex)
  FuncDisableHotstring(hotstringList[rowIndex].Short, hotstringList[rowIndex].Omit, hotstringList[rowIndex].Types)
  hotstringList.RemoveAt(rowIndex)
  sectionIndex := "HS" rowIndex
  IniDelete, %settingsFileName%, % sectionIndex
  GuiControl, Focus, LVHotstrings ; Select the ListView GUI element
  LV_Modify(rowIndex - 1, "+Select +Focus") ; Focus the first element in the List View
  SB_SetText("The Hotstring has been deleted!")
}

; Disable the context or global hotstring if it exists. AHK doesn't support Hotstring deletion
FuncDisableHotstring(short, omit, types)
{
  hotPrefix := omit == "Yes" ? ":O:" : "::"
  Loop, Parse, % types, % ","
  {
    Hotkey, IfWinActive, % Trim(A_LoopField)
    Hotstring(hotPrefix short, , "Off")
    Hotkey, IfWinActive
  }
  If (types == "")
    Hotstring(hotPrefix short, , "Off")
}

; Test
FuncTest()
{

}

;╔═══════════════════════════════════════════════════════════════════════════════════════════════╗;
;║                                       HELPER FUNCTIONS                                        ║;
;╚═══════════════════════════════════════════════════════════════════════════════════════════════╝;
FuncMessageBox(thisMessage)
{
  MsgBox, % thisMessage
}

; Retrieve the file types checkboxes in comma separated format
FuncGetTypesCheckboxes()
{
  types := ""
  Loop,
  {
    checkboxName := "CB" A_Index
    GuiControlGet, checkVis, Visible, % checkboxName ; Check if the checkbox is visible
    GuiControlGet, checkChk,        , % checkboxName ; Check if the checkbox is checked
    If (ErrorLevel == 1) ; Didn't find the checkbox
      Break
    If (checkVis == 1 && checkChk == 1)
    {
      GuiControlGet, boxType , , % checkboxName, Text
      types := types boxType ","
    }
  }
  Return Trim(types, ",")
}

FuncMinimize()
{
  Gui GUIOpt:Hide
}

FuncExit()
{
  ExitApp
}