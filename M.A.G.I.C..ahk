VERSION := 0.1

file = %A_ScriptName%
name := SubStr(file, 1, InStr(file, ".", , 0) - 1)
WINTITLE := "✨" name "✨ " VERSION

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input
SetWorkingDir %A_ScriptDir%

