
#SingleInstance Force
#NoEnv
#UseHook
#IF !Hotkey_Arr("Hook")
#IF

Hotkey_Arr("OnGroup", "OnGroupProc")
Hotkey_IniPath("Hotkey.ini")
Hotkey_IniSection("Hotkeys")

Gui, Color, 0xFFDD8A, 0xFFFFAA
Gui, Font, s12
Loop 5
{ 
	Gui, Add, Text, cRed xm y+20, Press %A_Index%:
	Hotkey_Add("cRed w400 yp x+10 Section", "Press" A_Index, "G1KMLRJD", "*", "FuncPress", "Send" A_Index)
	Gui, Add, Text, xm, Send %A_Index%:
	Hotkey_Add("w400 yp xs", "Send" A_Index, "KMLRJ", "*", "FuncSend") 
	Gui, Add, GroupBox, wp+100 h14 y+10 xm
	FuncPress("Press" A_Index), FuncSend("Send" A_Index)
}
Hotkey_ChangeOption("Press1", "G1WKMJD")
Gui, Add, Edit, wp y+20 r10
Gui, Show  


Gui, Color, 0xFFFFAA, 0xFFDD8A
return

OnGroupProc(arr) {
	Sleep 300
 	for k, v in arr.names
		FuncPress(v)
}

FuncPress(name) {
	Static PrKey := {} 
	Hotkey, IF, !Hotkey_Arr("Hook")
	Hotkey, % PrKey[name], Off, UseErrorLevel
	PrKey[name] := Hotkey_Write(name)  
	fn := Func("ActionPress").Bind(Hotkey_Arr("BindString")[Name]) 
	Hotkey, % PrKey[name], % fn, On, UseErrorLevel 
	Hotkey, IF 
}

FuncSend(name) { 
	Hotkey_Arr("User")["StrSend_" name] := Hotkey_HKToSend(Hotkey_Write(name)) 
}

ActionPress(name) {  
	SendInput % Hotkey_Arr("User")["StrSend_" name]
}

GuiClose() {
    ExitApp
}
