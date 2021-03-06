 	;  Автор - serzh82saratov
	;  E-Mail: serzh82saratov@mail.ru
	;  Описание - http://forum.script-coding.com/viewtopic.php?id=8343

Hotkey_Add(ControlOption, Name, Option = "", Hotkey = "", Func = "", BindString = "", ByRef hEdit = "") {
	Local M, M1, M2, FuncObj, GuiName, Write
	If (Name + 0 != "") {
		MsgBox, 4112, Hotkey add error, % "Name '" Name "' can not be a number, exit app."
		ExitApp
	}
	If Hotkey ~= "^:" && StrLen(Hotkey) > 1
		Hotkey := SubStr(Hotkey, 2), Write := 1
	RegExMatch(ControlOption, "S)^\s*(\S+:)*(.*)$", M), GuiName := M1, ControlOption := M2
	ControlOption := "r1 +ReadOnly +Center " Hotkey_Arr("ControlOption") " " ControlOption
	Gui, %GuiName%Add, Edit, %ControlOption% hwndhEdit, % Hotkey_HKToStr(Hotkey)
	Hotkey_ID(hEdit, Name), Hotkey_ID(Name, hEdit), Hotkey_Value(Name, Hotkey)
	If Write
		Hotkey_Write(Name)
	RegExMatch(Option, "Si)G(\d+)", M) && Hotkey_Group("Set", Name, M1)
	Hotkey_Options(hEdit, Option = "" ? "K" : Option)
	Hotkey_Arr("BindString")[Name] := BindString
	Hotkey_Arr("AllHotkeys")[Name] := hEdit
	FuncObj := Func(Func).Bind(Name)
	GuiControl, +g, % hEdit, % FuncObj
	Hotkey_Start()
}

Hotkey_Start() {
	Static IsStart
	Local fn
	If IsStart
		Return Hotkey_IsRegFocus()
	#HotkeyInterval 0
	fn := Func("Hotkey_WM_LBUTTONDBLCLK"), OnMessage(0x203, fn)  ;	WM_LBUTTONDBLCLK
	Hotkey_SetWinEventHook(0x8005, 0x8005, 0, RegisterCallback("Hotkey_EventFocus", "F"), 0, 0, 0)   ;  EVENT_OBJECT_FOCUS := 0x8005 
	If !Hotkey_Arr("ResetAllways")
		Hotkey_InitHotkeys()
	Hotkey_IsRegFocus(), IsStart := 1
}

	; -------------------------------------- ComboBox --------------------------------------
	
Hotkey_AddCB(ControlOption, Name, Option = "", Hotkey = "", Func = "", BindString = "", ByRef hCB = "") {  
	Local k, v, g, g1, i, hEdit, arr, fn, hDL, Write
	If (Name + 0 != "") {
		MsgBox, 4112, Hotkey add error, % "Name '" Name "' can not be a number, exit app."
		ExitApp
	}
	If Hotkey ~= "^:" && StrLen(Hotkey) > 1
		Hotkey := SubStr(Hotkey, 2), Write := 1
	RegExMatch(ControlOption, "S)^\s*(\S+:)*(.*)$", M), GuiName := M1, ControlOption := M2 
	ControlOption := "+Center " Hotkey_Arr("ControlOption") " " ControlOption
	Gui, %GuiName%Add, ComboBox, %ControlOption% hwndhCB
	Hotkey_CBGetEdit(hCB, hEdit, hDL)	
	Hotkey_ID(hEdit, Name), Hotkey_ID(Name, hEdit) 
	If ControlOption ~= "i)\+Center" 
		Control, Style, +0x1, , ahk_id %hEdit% 
	Hotkey_Options(hEdit, Option = "" ? "KC" : Option "C") 
	Hotkey_Arr("BindString")[Name] := BindString
	Hotkey_Arr("AllHotkeys")[Name] := hEdit
	Hotkey := Trim(Hotkey, "|"), Hotkey := RegExReplace(Hotkey, "\|+", "|")    
	SendMessage, 0x143, , "    " Hotkey_Arr("CBAddStr"), , ahk_id %hCB%  ; CB_ADDSTRING 
	arr := {}, i := 0
	Loop, Parse, % Hotkey, |
	{
		arr.Index[++i] := A_LoopField
		arr.Hotkey[A_LoopField] := i
		SendMessage, 0x143, , "    " Hotkey_HKToStr(A_LoopField), , ahk_id %hCB%  ; CB_ADDSTRING
	}
	Hotkey_Value(Name, arr.Index[1]), Hotkey_Value(hEdit, arr.Index[1])
	
	If (arr.Index[1] = "")
		SendMessage, 0xC, 0, "" Hotkey_Arr("Empty"), , ahk_id %hEdit%
	Else 
	{
		SendMessage, 0xC, 0, "" Hotkey_HKToStr(arr.Index[1]), , ahk_id %hEdit%
		SendMessage, 0x0144, 1, , , ahk_id %hCB%  ;  CB_DELETESTRING  
		arr.Hotkey.Delete(arr.Index[1]), arr.Index.RemoveAt(1)
	} 
	Hotkey_CBArr(hEdit, {hCB:hCB, hDL:hDL, name:Name, arr:arr,func:Func}), Hotkey_CBArr(Name, hEdit)
	
	for k, v in Hotkey_CBArr(hEdit).arr.Index
		Hotkey_CBArr(hEdit).arr.Hotkey[v] := k
		
	PostMessage, 0x00CF, 1, , , % "ahk_id" hEdit   ;  EM_SETREADONLY
	If RegExMatch(Option, "i)G(\d+)", g)
		Hotkey_Group("Set", Name, g1)
	If Write
		Hotkey_CBWrite(Name)
	fn := Func("Hotkey_CBSelect").Bind(hEdit)
	GuiControl, +g, % hCB, % fn 
	Hotkey_Start() 
}  

Hotkey_CBCheck(hEdit) { 
	Local func
	If Hotkey_CBArr(hEdit).arr.Hotkey[Hotkey_Value(hEdit)] != ""   ;	повтор
	{
		SendMessage, 0xC, 0, "" Hotkey_Arr("Empty"), , ahk_id %hEdit%
		Hotkey_Value(hEdit, ""), Hotkey_Value(Hotkey_ID(hEdit), ""), Hotkey_Blink(Hotkey_CBArr(hEdit).hCB)
	} 
	If (func := Hotkey_CBArr(hEdit).func) != ""
		Func(func).Call(hEdit)   
} 

Hotkey_CBSelect(hEdit, hCB) {
	Local Pos, HK, arr, k, v, Count
	SendMessage, 0x0147, 0, 0, , ahk_id %hCB% ;  CB_GETCURSEL
	Pos := ErrorLevel + 1 ; -1 not selected
	SendMessage, 0x0146, 0, 0, , ahk_id %hCB% ;  CB_GETCOUNT
	Count := ErrorLevel
	HK := Hotkey_Value(hEdit)
	If (Pos < 1 || Pos > Count)
	{
		SendMessage, 0xC, 0, "" Hotkey_HKToStr(HK), , ahk_id %hEdit%
		Return
	}
	If Pos = 1
	{
		SendMessage, 0xC, 0, "" Hotkey_Arr("Empty"), , ahk_id %hEdit%
		Sleep 10
		SendMessage, 0xC, 0, "" Hotkey_Arr("Empty"), , ahk_id %hEdit%
		Hotkey_Value(hEdit, ""), Hotkey_Value(Hotkey_ID(hEdit), "") 
		PostMessage, 0x00B1, -2, -2, , ahk_id %hEdit%   ;  EM_SETSEL
		If HK =  
			Return
		arr := Hotkey_CBArr(hEdit).arr
		SendMessage, 0x143, , "    " Hotkey_HKToStr(HK), , ahk_id %hCB%  ; CB_ADDSTRING
		Count := arr.Index.Count(), (!Count && Count := 0)
		arr.Hotkey[HK] := Count + 1
		arr.Index[Count + 1] := HK
		Return
	}
	arr := Hotkey_CBArr(hEdit).arr
	PostMessage, 0x00B1, -2, -2, , ahk_id %hEdit%   ;  EM_SETSEL
	SendMessage, 0x0144, Pos - 1, , , ahk_id %hCB%  ;  CB_DELETESTRING 
	SendMessage, 0xC, 0, "" Hotkey_HKToStr(arr.Index[Pos - 1]), , ahk_id %hEdit%  
	Hotkey_Value(Hotkey_CBArr(hEdit).name, arr.Index[Pos - 1])
	Hotkey_Value(hEdit, arr.Index[Pos - 1])
	arr.Hotkey.Delete(arr.Index[Pos - 1]), arr.Index.RemoveAt(Pos - 1)
	
	If HK !=
	{
		SendMessage, 0x143, , "    " Hotkey_HKToStr(HK), , ahk_id %hCB%  ; CB_ADDSTRING
		Count := arr.Index.Count()
		arr.Hotkey[HK] := Count + 1
		arr.Index[Count + 1] := HK
	}
}

Hotkey_CBValue(name) {
	Local k, v, Str
	Str := Hotkey_Value(name)  
	for k, v in Hotkey_CBArr(Hotkey_ID(name)).arr.Index
		Str .= "|" v 
	Return Trim(Str, "|")
}

Hotkey_CBWrite(ID, Section = "", FilePath = "") {
	Local Name
	Name := (ID + 0 = "") ? ID : Hotkey_ID(ID)
	If (Name != "")
		IniWrite, % Hotkey_CBValue(name), % FilePath = "" ? Hotkey_IniPath() : FilePath, % Section = "" ? Hotkey_IniSection() : Section, % Name
}

Hotkey_CBHotkey(Name, Label = "", Option = "") {
	Loop, Parse, % Hotkey_CBValue(Name), |
		Hotkey, % A_LoopField, % Label = "" ? "Off" : Label, % (Label = "" ? "" : "On") " UseErrorLevel " Option
}

Hotkey_CBArr(P*) {
	Static Arr := {}
	Return P.MaxIndex() = 1 ? Arr[P[1]] : P.MaxIndex() = 2 ? (Arr[P[1]] := P[2]) : !P.MaxIndex() ? Arr : Arr.Delete(P[1])
}

Hotkey_CBGetEdit(hCombo, byref hEdit, byref hDL) {
	Static SizeOfCBI := 40 + (A_PtrSize * 3)
	VarSetCapacity(CBI, SizeOfCBI, 0) ; COMBOBOXINFO structure - msdn.microsoft.com/en-us/library/bb775798(v=vs.85).aspx
	NumPut(SizeOfCBI, CBI, 0, "UInt")
	DllCall("GetComboBoxInfo", "Ptr", hCombo, "Ptr", &CBI, "Int") ; msdn.microsoft.com/en-us/library/bb775939(v=vs.85).aspx 
	hEdit := NumGet(CBI, 40 + A_PtrSize, "UPtr")
	hDL := NumGet(CBI, 40 + A_PtrSize * 2, "UPtr")
} 

	; -------------------------------------- Main --------------------------------------
	
Hotkey_Main(Param1, Param2 = "") {
	Static OnlyMods, ControlHandle, Hotkey, KeyName, K := {}
	, Prefix := {"LCtrl":"<^","RCtrl":">^","LShift":"<+","RShift":">+"
				,"LAlt":"<!","RAlt":">!","LWin":"<#","RWin":">#"
				,"Ctrl":"^","Shift":"+","Alt":"!","Win":"#"}
	, EngSym := {"sc2":"1","sc3":"2","sc4":"3","sc5":"4","sc6":"5","sc7":"6"
				,"sc8":"7","sc9":"8","scA":"9","scB":"0","scC":"-","scD":"="
				,"sc10":"Q","sc11":"W","sc12":"E","sc13":"R","sc14":"T","sc15":"Y"
				,"sc16":"U","sc17":"I","sc18":"O","sc19":"P","sc1A":"[","sc1B":"]"
				,"sc1E":"A","sc1F":"S","sc20":"D","sc21":"F","sc22":"G","sc23":"H"
				,"sc24":"J","sc25":"K","sc26":"L","sc27":"`;","sc28":"'","sc29":"``"
				,"sc2B":"\","sc2C":"Z","sc2D":"X","sc2E":"C","sc2F":"V","sc30":"B"
				,"sc31":"N","sc32":"M","sc33":",","sc34":".","sc35":"/","sc56":"\"}
	Local IsMod, ThisHotkey, Text
	If Param1 = GetMod
		Return !!(K.MLCtrl K.MRCtrl K.MLShift K.MRShift K.MLAlt K.MRAlt K.MLWin K.MRWin K.MCtrl K.MShift K.MAlt K.MWin)
	If Param1 = Clean
	{
		ControlHandle := !Param2 ? ControlHandle : Param2
		Hotkey_SetText(ControlHandle, Hotkey_Arr("Empty"), "")
		Return K := {}, OnlyMods := 0, Hotkey := KeyName := ""
	}
	If Param2
	{
		K := {}
		If OnlyMods && !(OnlyMods := 0)
			Hotkey_SetText(ControlHandle, Hotkey_Arr("Empty"), "")
		ControlHandle := Param2
		Hotkey_Arr("Hook", Hotkey_Options(ControlHandle))
		PostMessage, 0x00B1, -2, -2, , ahk_id %ControlHandle%   ;	EM_SETSEL
	}
	Else If Hotkey_Arr("Hook")
	{
		Hotkey_Arr("Hook", "")
		If OnlyMods && !(OnlyMods := 0)
			Hotkey_SetText(ControlHandle, Hotkey_Arr("Empty"), "")
		SetTimer, Hotkey_IsRegFocus, -200
	}
	Return

	Hotkey_Mods:
		ThisHotkey := Hotkey_GetName(A_ThisHotkey, "M")
		If Hotkey_IsBan(ThisHotkey, ControlHandle)
			Return Hotkey_Main("Clean")
		If Hotkey_InHook("S") || Hotkey_InHook("W")
		{
			KeyName := Hotkey := ThisHotkey
			GoTo, Hotkey_Put
		}
		IsMod := Hotkey_InHook("D") ? ThisHotkey : SubStr(ThisHotkey, 2)
		If (K["M" IsMod] != "")
			Return
		K["M" IsMod] := IsMod " + ", K["P" IsMod] := Prefix[IsMod]
		GoTo, Hotkey_ViewMod

	Hotkey_ModsUp:
		If Hotkey_InHook("S") || Hotkey_InHook("W")
			Return
		ThisHotkey := SubStr(A_ThisHotkey, 1, -3)
		ThisHotkey := Hotkey_GetName(ThisHotkey, "M")
		If Hotkey_InHook("Z") && Hotkey = ""
		{
			If Hotkey_IsBan(ThisHotkey, ControlHandle)
				Return Hotkey_Main("Clean")
			K := {}, KeyName := Hotkey := ThisHotkey
			GoTo, Hotkey_Put
		}
		IsMod := Hotkey_InHook("D") ? ThisHotkey : SubStr(ThisHotkey, 2)
		If K["M" IsMod] = ""  ;	Check LCtrl Up, for activate window AltGr layout language
			Return
		If Hotkey_IsBan(ThisHotkey, ControlHandle)
			Return Hotkey_Main("Clean")
		K["M" IsMod] := "", K["P" IsMod] := ""
		If (Hotkey != "")
			Return

	Hotkey_ViewMod:
		Hotkey := "", OnlyMods := 1
		K.Mods := K.MLCtrl K.MRCtrl K.MLShift K.MRShift K.MLAlt K.MRAlt K.MLWin K.MRWin K.MCtrl K.MShift K.MAlt K.MWin
		Text := K.Mods = "" ? Hotkey_Arr("Empty") : K.Mods
		Hotkey_SetText(ControlHandle, Text, "")
		Return

	Hotkey_ViewNum:  ;	code
		ThisHotkey := Hotkey_GetName(A_ThisHotkey, "C")
		If Hotkey_IsBan(ThisHotkey, ControlHandle)
			Return Hotkey_Main("Clean")
		 If Hotkey_InHook("N")
			KeyName := GetKeyName(ThisHotkey), Hotkey := ThisHotkey
		Else
			Hotkey := Format("sc{:x}", GetKeySC(ThisHotkey)), KeyName := GetKeyName(Hotkey)
		GoTo, Hotkey_Put

	Hotkey_ViewNumExcept:  ;	code
		ThisHotkey := Hotkey_GetName(A_ThisHotkey, "C")
		If Hotkey_IsBan(ThisHotkey, ControlHandle)
			Return Hotkey_Main("Clean")
		If Hotkey_InHook("N")
			GetKeyState("NumLock", "T") ? (KeyName := "Numpad5", Hotkey := "vk65") : (KeyName := "NumpadClear", Hotkey := "vkC")
		Else
			KeyName := "NumpadClear", Hotkey := ThisHotkey
		GoTo, Hotkey_Put

	Hotkey_ViewSC:  ;	code
		ThisHotkey := Hotkey_GetName(A_ThisHotkey, "C")
		If Hotkey_IsBan(ThisHotkey, ControlHandle)
			Return Hotkey_Main("Clean")
		KeyName := Hotkey_Arr("OnlyEngSym") ? EngSym[ThisHotkey] : Format("{:U}", GetKeyName(ThisHotkey))
		Hotkey := ThisHotkey
		GoTo, Hotkey_Put

	Hotkey_ViewJoy:
		If Hotkey_Main("GetMod") || Hotkey_InHook("W")
			Return
		ThisHotkey := Hotkey_GetName(A_ThisHotkey, "J")
		If Hotkey_IsBan(ThisHotkey, ControlHandle)
			Return Hotkey_Main("Clean")
		KeyName := Hotkey := ThisHotkey
		GoTo, Hotkey_Put

	Hotkey_View:
		ThisHotkey := Hotkey_GetName(A_ThisHotkey, "N")
		If Hotkey_IsBan(ThisHotkey, ControlHandle)
			Return Hotkey_Main("Clean")
		KeyName := Hotkey := ThisHotkey

	Hotkey_Put:
		If Hotkey_InHook("W")
			GoTo, Hotkey_Double
		OnlyMods := 0
		K.Prefix := K.PLCtrl K.PRCtrl K.PLShift K.PRShift K.PLAlt K.PRAlt K.PLWin K.PRWin K.PCtrl K.PShift K.PAlt K.PWin
		K.Mods := K.MLCtrl K.MRCtrl K.MLShift K.MRShift K.MLAlt K.MRAlt K.MLWin K.MRWin K.MCtrl K.MShift K.MAlt K.MWin
		Text := K.Mods KeyName = "" ? Hotkey_Arr("Empty") : K.Mods KeyName
		Hotkey_SetText(ControlHandle, Text, K.Prefix Hotkey)

	Hotkey_GroupCheck:
		If Hotkey_Group("Get", Hotkey_ID(ControlHandle)) && Hotkey_Group("SaveCheck", ControlHandle)
			SetTimer, Hotkey_Group, -70
		Return

	Hotkey_Double:
		If !K.Double
		{
			K.DHotkey := Hotkey, K.DName := KeyName, K.Double := 1, OnlyMods := 1
			Hotkey_SetText(ControlHandle, KeyName " & ", "")
			Return
		}
		If (K.DHotkey = Hotkey)
			Return
		Text := K.DName " & " KeyName, K.Double := 0, OnlyMods := 0
		Hotkey_SetText(ControlHandle, Text, K.DHotkey " & " Hotkey)
		GoTo, Hotkey_GroupCheck

	Hotkey_RButton:
		If Hotkey_InHook("L") && GetKeyState("LButton"`, "P")
			KeyName := Hotkey := "LButton"
		Else If Hotkey_InHook("R")
			KeyName := Hotkey := "RButton"
		Else
			Return
		If Hotkey_IsBan(Hotkey, ControlHandle)
			Return Hotkey_Main("Clean")
		GoTo, Hotkey_Put
}

Hotkey_GetName(HK, Type) {
	Static ModsNames := {"LCtrl":"LCtrl","RCtrl":"RCtrl","LShift":"LShift"
	,"RShift":"RShift","LAlt":"LAlt","RAlt":"RAlt","LWin":"LWin","RWin":"RWin"}
	HK := RegExReplace(HK, "S)[~\*\$]")
	If Type = N
		Return GetKeyName(HK)
	If Type = M
		Return ModsNames[HK]
	If Type = C
		Return RegExReplace(HK, "Si)(vk|sc)(.*)", "$L1$U2")
	If Type = J
		Return RegExReplace(HK, "Si)(Joy)", "Joy", , 1)
}

Hotkey_InitHotkeys(Option = 1) {
	Local S_FormatInteger, S_BatchLines
	Static nmMods := "LCtrl|RCtrl|LShift|RShift|LAlt|RAlt|LWin|RWin"
	, nmMouse := "MButton|WheelDown|WheelUp|WheelRight|WheelLeft|XButton1|XButton2"
	, scSymb := "2|3|4|5|6|7|8|9|A|B|C|D|10|11|12|13|14|15|16|17|18|19|1A|1B|"
		. "1E|1F|20|21|22|23|24|25|26|27|28|29|2B|2C|2D|2E|2F|30|31|32|33|34|35|56"
	, scOther := "1|E|F|1C|37|39|3A|3B|3C|3D|3E|3F|40|41|42|43|44|46|4A|4E|54|57|58|63|64|65|"
		. "66|67|68|69|6A|6B|6C|6D|6E|76|7C|11C|135|145|147|148|149|14B|14D|14F|150|151|152|153|15D"
	, vkNum := "21|22|23|24|25|26|27|28|2D|2E|60|61|62|63|64|66|67|68|69|6E|C|65"	; , scNum := "53|52|4F|50|51|4B|4D|47|48|49|4C|59"
	, vkOther := "3|13|5F|A6|A7|A8|A9|AA|AB|AC|AD|AE|AF|B0|B1|B2|B3|B4|B5|B6|B7"

	S_BatchLines := A_BatchLines
	SetBatchLines, -1
	Option := Option ? "On" : "Off"
	#IF Hotkey_IsRegControl()
	#IF Hotkey_Hook("K")
	#IF Hotkey_Hook("M")
	#IF Hotkey_Hook("L") && GetKeyState("RButton", "P")
	#IF Hotkey_Hook("R") || Hotkey_InHook("L")
	#IF Hotkey_Hook("J")
	#IF Hotkey_Arr("Hook") && !Hotkey_InHook("K")
	#IF
	Hotkey, IF, Hotkey_Hook("M")
	Loop, Parse, nmMouse, |
		Hotkey, % A_LoopField, Hotkey_View, % Option
	Hotkey, IF, Hotkey_Hook("K")
	Loop, Parse, nmMods, |
	{
		Hotkey, % A_LoopField, Hotkey_Mods, % Option
		Hotkey, % A_LoopField " Up", Hotkey_ModsUp, % Option
	}
	Loop, Parse, scSymb, |
		Hotkey, % "sc" A_LoopField, Hotkey_ViewSC, % Option
	Loop, Parse, scOther, |
		Hotkey, % GetKeyName("sc" A_LoopField), Hotkey_View, % Option
	Loop, Parse, vkNum, |
		Hotkey, % "vk" A_LoopField, Hotkey_ViewNum, % Option
	Hotkey, sc59, Hotkey_ViewNumExcept, % Option  ;	NumpadClear
	Loop, Parse, vkOther, |
		Hotkey, % GetKeyName("vk" A_LoopField), Hotkey_View, % Option
	Hotkey, IF, Hotkey_Hook("L") && GetKeyState("RButton"`, "P")
	Hotkey, LButton, Hotkey_Return, % Option
	Hotkey, IF, Hotkey_Hook("R") || Hotkey_InHook("L")
	Hotkey, RButton, Hotkey_Return, % Option
	Hotkey, RButton Up, Hotkey_RButton, % Option
	S_FormatInteger := A_FormatInteger
	SetFormat, IntegerFast, D
	Hotkey, IF, Hotkey_Hook("J")
	Loop, 128
		Hotkey % Ceil(A_Index / 32) "Joy" Mod(A_Index - 1, 32) + 1, Hotkey_ViewJoy, % Option
	SetFormat, IntegerFast, %S_FormatInteger%
	Hotkey, IF, Hotkey_IsRegControl()
	Hotkey, RButton, Hotkey_Return, % Option
	Hotkey, RButton Up, Hotkey_Return, % Option
	Hotkey, IF, Hotkey_Arr("Hook") && !Hotkey_InHook("K")
	Hotkey, AppsKey Up, Hotkey_Return, % Option
	Hotkey, +F10, Hotkey_Return, % Option
	Hotkey, IF
	SetBatchLines, %S_BatchLines%
	Return

	Hotkey_Return:
		Return
}

Hotkey_IsRegControl() {
	Local Control
	MouseGetPos,,,, Control, 2
	Return Hotkey_ID(Control) != ""
}

Hotkey_IsRegFocus() {
	Local ControlNN, hFocus
	ControlGetFocus, ControlNN, A
	ControlGet, hFocus, Hwnd, , %ControlNN%, A
	Hotkey_ID(hFocus) != "" ? Hotkey_Main("Control", hFocus) : 0 
}

Hotkey_WM_LBUTTONDBLCLK(wp, lp, msg, hwnd) {
	If (Hotkey_ID(hwnd) = "")
		Return
	Hotkey_Main("Clean", hwnd)
	Sleep 50
	PostMessage, 0x00B1, -2, -2, , ahk_id %hwnd%   ;	EM_SETSEL
}

Hotkey_EventFocus(hWinEventHook, event, hwnd) { 
	Hotkey_ID(hwnd) != "" ? Hotkey_Main("Control", hwnd) : Hotkey_Main("Control")
}

Hotkey_SetWinEventHook(eventMin, eventMax, hmodWinEventProc, lpfnWinEventProc, idProcess, idThread, dwFlags) {
	Return DllCall("SetWinEventHook" , "UInt", eventMin, "UInt", eventMax, "Ptr", hmodWinEventProc
			, "Ptr", lpfnWinEventProc, "UInt", idProcess, "UInt", idThread, "UInt", dwFlags, "Ptr")
} 

	; -------------------------------------- Get and set --------------------------------------

Hotkey_Arr(P*) {
	Static Arr := {Empty:"Нет", CBAddStr:"    Добавить хоткей", AllHotkeys:{}, BindString:{}, User:{}}
	Return P.MaxIndex() = 1 ? Arr[P[1]] : P.MaxIndex() = 2 ? (Arr[P[1]] := P[2]) : !P.MaxIndex() ? Arr : Arr.Delete(P[1])
}

Hotkey_ID(P*) {
	Static Arr := {}
	Return P.MaxIndex() = 1 ? Arr[P[1]] : P.MaxIndex() = 2 ? (Arr[P[1]] := P[2]) : !P.MaxIndex() ? Arr : Arr.Delete(P[1])
}

Hotkey_Value(P*) {
	Static Arr := {}
	Return P.MaxIndex() = 2 ? (Arr[P[1]] := P[2], Arr[Hotkey_ID(P[1])] := P[2]) : P.MaxIndex() = 1 ? Arr[P[1]] : !P.MaxIndex() ? Arr : (Arr.Delete(P[1]), Arr.Delete(Hotkey_ID(P[1])))
}

Hotkey_Options(P*) {
	Static Arr := {}
	Return P.MaxIndex() = 1 ? Arr[P[1]] : P.MaxIndex() = 2 ? (Arr[P[1]] := P[2]) : !P.MaxIndex() ? Arr : Arr.Delete(P[1])
}

Hotkey_BanKey(Keys, Name = 0) {
	Hotkey_BanArr()[Name] := {}
	Loop, Parse, Keys, |
		Hotkey_BanArr()[Name][A_LoopField] := 1
}

Hotkey_BanArr(P*) {
	Static Arr := {}
	Return Arr
}

Hotkey_IsBan(HK, hwnd) {
	If Hotkey_BanArr().0.HasKey(HK)  ;	Global ban
		Return 1
	If Hotkey_BanArr()[Hotkey_ID(hwnd)].HasKey(HK)
		Return 1
	Return 0
}

Hotkey_IniPath(Path = "") {
	Return Path = "" ? Hotkey_Arr("IniPath") : Hotkey_Arr("IniPath", Path)
}

Hotkey_IniSection(Section = "") {
	Return Section = "" ? Hotkey_Arr("IniSection") : Hotkey_Arr("IniSection", Section)
}

Hotkey_Hook(Option) {
	Return Hotkey_Arr("Hook") && InStr(Hotkey_Arr("Hook"), Option)
}

Hotkey_InHook(Option) {
	Return InStr(Hotkey_Arr("Hook"), Option)
}

Hotkey_ChangeOption(Name, Option = "") {
	Local g, g1, IsCB
	If Hotkey_Group("Get", Name)
		Hotkey_Group("Delete", Name)
	If RegExMatch(Option, "Si)G(\d+)", g)
		Hotkey_Group("Set", Name, g1)
	IsCB := !!InStr(Hotkey_Options(Hotkey_ID(Name)), "C")
	Option := Option = "" ? "K" : Option
	Option .= (IsCB ? "C" : "")
	Return Hotkey_Options(Hotkey_ID(Name), Option)
}

Hotkey_Delete(Name, Destroy = 1) {
	Local Hwnd, hFocus, ControlNN, hCB 
	Hwnd := Hotkey_ID(Name)
	GuiControl, -g, % Hwnd
	If Hotkey_Group("Get", Name)
		Hotkey_Group("Delete", Name)
	Hotkey_Value(Hwnd, "", "")  ;	Удалять, до удаления Hotkey_ID
	Hotkey_ID(Hwnd, "", ""), Hotkey_ID(Name, "", "")
	IsCB := !!InStr(Hotkey_Options(Hwnd), "C") 
	Hotkey_Options(Hwnd, "", "")
	Hotkey_BanArr().Delete(Name)
	Hotkey_Arr("AllHotkeys").Delete(Name)
	Hotkey_Arr("BindString").Delete(Name)
	ControlGetFocus, ControlNN, A
	ControlGet, hFocus, Hwnd, , %ControlNN%, A
	(hFocus = Hwnd ? Hotkey_Main("Control") : 0)
	If IsCB 
		hCB := Hotkey_CBArr(Hwnd).hCB, Hotkey_CBArr(Hwnd, 0, 0)
		, Hotkey_CBArr(Name, 0, 0), Hwnd := hCB
	If Destroy
		DllCall("DestroyWindow", "Ptr", Hwnd)
	Else
		PostMessage, 0x00CF, 0, , , ahk_id %hwnd%		;	EM_SETREADONLY
	Return Hwnd
}

Hotkey_SetText(hwnd, Text, HK) {
	Hotkey_Value(hwnd, HK)
	SendMessage, 0x000C, 0, &Text, , ahk_id %hwnd%		;	WM_SETTEXT
	PostMessage, 0x00B1, -2, -2, , ahk_id %hwnd%		;	EM_SETSEL
	If InStr(Hotkey_Arr("Hook"), "C")
		Hotkey_CBCheck(hwnd)
}

Hotkey_Set(Name, HK = "") {
	Local Text
	Text := Hotkey_HKToStr(HK)
	Hotkey_SetText(Hotkey_ID(Name), Text, HK)
	Return Text
}

Hotkey_Read(Name, Section = "", FilePath = "") {
	Local HK
	IniRead, HK, % FilePath = "" ? Hotkey_IniPath() : FilePath, % Section = "" ? Hotkey_IniSection() : Section, % Name, % A_Space
	Return HK
}

Hotkey_Write(Name, Section = "", FilePath = "") {
	Local HK
	IniWrite, % HK := Hotkey_Value(Name), % FilePath = "" ? Hotkey_IniPath() : FilePath, % Section = "" ? Hotkey_IniSection() : Section, % Name
	Return HK
}

	; -------------------------------------- Group --------------------------------------

Hotkey_Group(Key = "", p1 = "", p2 = "") {
	Local Name, Value, k, v, n, m, f, r
	Static NG := {}, GN := [], SaveCheck := []
	If (Key = "") {
		For k, Name in SaveCheck {
			If ((Value := Hotkey_Value(Name)) != "") {
				(f := Hotkey_Arr("GroupEvents")) != "" && (r := {}, r.names := [])
				For m, n in GN[NG[Name]] {
					If (n = Name)
						Continue 
					h := Hotkey_ID(n)
					b := (Hotkey_Equal(Value, Hotkey_Value(h)))
					
					If InStr(Hotkey_Options(h), "C")  ;	ComboBox
					{ 
						If b && (h := Hotkey_CBArr(h).hCB)
							Goto, Hotkey_Find  
						for k2, v2 in Hotkey_CBArr(h).arr.Index
							If (Hotkey_Equal(Value, v2)) && (h := Hotkey_CBArr(h).hCB)
								Goto, Hotkey_Find 
					}
					If !b
						Continue
						
					Hotkey_Find:
						Hotkey_Set(Name)
						(f != "") && (r.names.Push(n), r.this := Name, r.value := Value, r.group := NG[Name])
						Hotkey_Blink(h)
						Continue 
					}
				} 
			SaveCheck.Delete(k)
		}
		(f != "") && (r.this != "") && %f%(r)
	}
	Else If (Key = "Set")
		NG[p1] := p2, IsObject(GN[p2]) ? GN[p2].Push(p1) : GN[p2] := [p1]
	Else If (Key = "SaveCheck")
		Return 1, SaveCheck[p1] := Hotkey_ID(p1)
	Else If (Key = "Get")
		Return NG[p1]
	Else If (Key = "CheckAll") {
		For k, v in GN
			For k, n in v
				If ((Value := Hotkey_Value(n)) != "")
					For k, m in v
						If (n != m && Hotkey_Equal(Value, Hotkey_Value(m)))
							Hotkey_Set(m)
	}
	Else If (Key = "Delete") {
		For k, v in GN[NG[p1]]
			If (v = p1) {
				GN[NG[p1]].RemoveAt(k)
				Break
			}
		NG.Delete(p1)
	}
}

Hotkey_Blink(hwnd) {
	Local k
	Static i, Blink := {}
	If !DllCall("IsWindowVisible", "Ptr", hwnd)
		Return
	DllCall("ShowWindowAsync", "Ptr", hwnd, "Int", 0)
	Blink[hwnd] := 1, i := 3
	SetTimer, Hotkey_BlinkControl, -50
	Return

	Hotkey_BlinkControl:
		For k in Blink
			DllCall("ShowWindowAsync", "Ptr", k, "Int", Mod(i, 2) ? 4 : 0)
		If (--i > 0) || !(Blink := {})
			SetTimer, Hotkey_BlinkControl, -50
		Return
}

Hotkey_Equal(HK1, HK2) {
	Local Bool
	If (HK2 = "")
		Return 0
	If (HK1 = HK2)
		Return 1
	If (HK1 ~= "S)[<>]") && (HK2 ~= "S)[<>]")
		Return 0
	If Hotkey_EqualDouble(HK1, HK2, Bool)
		Return Bool
	If !(HK1 ~= "S)[\^\+!#]") || !(HK2 ~= "S)[\^\+!#]")
		Return 0
	Return (Hotkey_ModsSub(HK1) = Hotkey_ModsSub(HK2))
}

Hotkey_EqualDouble(HK1, HK2, ByRef Bool) {
	Static Prefix := {"LCtrl":"<^","RCtrl":">^","LShift":"<+","RShift":">+"
						,"LAlt":"<!","RAlt":">!","LWin":"<#","RWin":">#"}
	Local K, K1, K2, i, D, P, R
	If !(!!InStr(HK1, " & ") && i:=1) ^ (!!InStr(HK2, " & ") && i:=2)
		Return Bool := 0
	D := HK%i%, P := i = 1 ? HK2 : HK1
	If !((1, RegExReplace(P, "[\^\+!#]", , R, 2)) && (R = 1)
	&& RegExMatch(D, "S)^\s*(.*?) & (.*?)\s*$", K)
	&& (Prefix[K1] && !Prefix[K2]) && (1, D := Prefix[K1] . K2))
		Return Bool := 0
	Return 1, Bool := SubStr(D, 1 + !(P ~= "S)[<>]")) = P
}

Hotkey_ModsSub(HK) {
	If !(HK ~= "[<>]")
		Return HK
	HK := StrReplace(HK, "<")
	HK := StrReplace(HK, ">")
	HK := StrReplace(HK, "^^", "^", , 1)
	HK := StrReplace(HK, "++", "+", , 1)
	HK := StrReplace(HK, "!!", "!", , 1)
	Return StrReplace(HK, "##", "#", , 1)
}

	; -------------------------------------- Format --------------------------------------

Hotkey_HKToStr(HK) {
	Static Prefix := {"^":"Ctrl","+":"Shift","!":"Alt","#":"Win","<":"L",">":"R"}
	, EngSym := {"sc2":"1","sc3":"2","sc4":"3","sc5":"4","sc6":"5","sc7":"6"
				,"sc8":"7","sc9":"8","scA":"9","scB":"0","scC":"-","scD":"="
				,"sc10":"Q","sc11":"W","sc12":"E","sc13":"R","sc14":"T","sc15":"Y"
				,"sc16":"U","sc17":"I","sc18":"O","sc19":"P","sc1A":"[","sc1B":"]"
				,"sc1E":"A","sc1F":"S","sc20":"D","sc21":"F","sc22":"G","sc23":"H"
				,"sc24":"J","sc25":"K","sc26":"L","sc27":"`;","sc28":"'","sc29":"``"
				,"sc2B":"\","sc2C":"Z","sc2D":"X","sc2E":"C","sc2F":"V","sc30":"B"
				,"sc31":"N","sc32":"M","sc33":",","sc34":".","sc35":"/","sc56":"\"

				,"vk31":"1","vk32":"2","vk33":"3","vk34":"4","vk35":"5","vk36":"6"
				,"vk37":"7","vk38":"8","vk39":"9","vk30":"0","vkBD":"-","vkBB":"="
				,"vk51":"Q","vk57":"W","vk45":"E","vk52":"R","vk54":"T","vk59":"Y"
				,"vk55":"U","vk49":"I","vk4F":"O","vk50":"P","vkDB":"[","vkDD":"]"
				,"vk41":"A","vk53":"S","vk44":"D","vk46":"F","vk47":"G","vk48":"H"
				,"vk4A":"J","vk4B":"K","vk4C":"L","vkBA":"`;","vkDE":"'","vkC0":"``"
				,"vkDC":"\","vk5A":"Z","vk58":"X","vk43":"C","vk56":"V","vk42":"B"
				,"vk4E":"N","vk4D":"M","vkBC":",","vkBE":".","vkBF":"/","vkE2":"\"}

	Local K, K1, K2, R, R1, R2, M, P := 1
	If InStr(HK, " & ")
	{
		RegExMatch(HK, "S)^\s*(.*?) & (.*?)\s*$", K)
		If K1 ~= "i)^(vk|sc[^r])"
			K1 := Hotkey_Arr("OnlyEngSym") && EngSym.HasKey(K1) ? EngSym[K1] : GetKeyName(K1)
		If K2 ~= "i)^(vk|sc[^r])"
			K2 := Hotkey_Arr("OnlyEngSym") && EngSym.HasKey(K2) ? EngSym[K2] : GetKeyName(K2)
		Return (StrLen(K1) = 1 ? Format("{:U}", K1) : K1) " & " (StrLen(K2) = 1 ? Format("{:U}", K2) : K2)
	}
	RegExMatch(HK, "S)^\s*([~\*\$\^\+!#<>]*)\{?(.*?)}?\s*$", K)
	If (K2 = "")
		Return "" Hotkey_Arr("Empty")
	If K2 ~= "i)^(vk|sc[^r])"
		K2 := Hotkey_Arr("OnlyEngSym") && EngSym.HasKey(K2) ? EngSym[K2] : GetKeyName(K2)
	While P := RegExMatch(K1, "S)([<>])*([\^\+!#])", R, P) + StrLen(R)
		M .= Prefix[R1] . Prefix[R2] . " + "
	Return M . (StrLen(K2) = 1 ? Format("{:U}", K2) : K2)
}

Hotkey_HKToSend(HK, Section = "", FilePath = "") {
	Local K, K1, K2
	If (HK = "")
		Return
	If (Section != "")
		IniRead, HK, % FilePath = "" ? Hotkey_IniPath() : FilePath, % Section, % HK, % A_Space
	If InStr(HK, " & ") && (1, RegExMatch(HK, "S)^\s*(.*?) & (.*?)\s*$", K))
		Return "{" RegExReplace(K1, "S)[~\$\*]") "}{" K2 "}"
	RegExMatch(HK, "S)^\s*([~\*\$\^\+!#<>]*)\{?(.*?)}?\s*$", K)
	Return RegExReplace(K1, "S)([^\^\+!#]*)") "{" K2 "}"
}

Hotkey_HKToSendEx(HK, Section = "", FilePath = "") {
	Static V := {"^":"Ctrl","+":"Shift","!":"Alt","#":"Win","<":"L",">":"R","":"L"}
	Local K, K1, K2, M1, M2, R, R1, R2, P := 1
	If (HK = "")
		Return
	If (Section != "")
		IniRead, HK, % FilePath = "" ? Hotkey_IniPath() : FilePath, % Section, % HK, % A_Space
	If InStr(HK, " & ") && (1, RegExMatch(HK, "S)^\s*(.*?) & (.*?)\s*$", K))
		Return "{" (K1 := RegExReplace(K1, "S)[~\$\*]")) " Down}{" K2 " Down}{" K1 " Up}{" K2 " Up}"
	RegExMatch(HK, "S)^\s*([~\*\$\^\+!#<>]*)\{?(.*?)}?\s*$", K)
	While P := RegExMatch(K1, "S)([<>])*([\^\+!#])", R, P) + StrLen(R)
		M1 .= "{" V[R1] V[R2] " Down}", M2 .= "{" V[R1] V[R2] " Up}"
	Return M1 . "{" K2 "}" . M2
}

	; ---------------------------------------------------------------------------------

#NoEnv
#SingleInstance Force
OnExit("ExitApp")
Menu, Tray, Click, 1
Menu, Tray, NoStandard
Menu, Tray, Add, Hide/Show, GuiClose
Menu, Tray, Add, ExitApp, ExitApp
Menu, Tray, Default, Hide/Show
Hotkey_IniPath(A_ScriptDir "\Hotkey.ini"), Hotkey_IniSection("Hotkeys")
#IF !GuiShow
#IF
GuiShow := 0
Gui, Font, s12
Hotkey_Add("w400", "MyHotkey1", "KMJG1", Hotkey_Read("MyHotkey1"))
Hotkey_Add("wp y+10", "MyHotkey2", "KMJG1", Hotkey_Read("MyHotkey2"))
Hotkey_AddCB("wp y+10 r10", "MyHotkey3", "KJG1", Hotkey_Read("MyHotkey3"))
Hotkey_AddCB("wp y+10", "MyHotkey4", "KJG1", Hotkey_Read("MyHotkey4"))
Gui, Add, Edit, xp+100 wp-100 y+10

for name, hwnd in Hotkey_Arr("AllHotkeys")
	SetStaticColor(hwnd, 0x2D46BD, 0xFFFFFF) 
	
GuiClose:
	HotkeySet(GuiShow := !GuiShow)
	Gui, Show, % GuiShow ? "" : "Hide"
	Return

HotkeySet(Reset=0) {
	Hotkey, IF, !GuiShow
	for name in Hotkey_Arr("AllHotkeys")
	{
		If Hotkey_CBArr(name)
		{
			IF Reset
				Hotkey_CBHotkey(name)
			Else IF (1, Hotkey_CBWrite(name))
				Hotkey_CBHotkey(name, "L_" name)
		}
		Else
		{
			IF Reset
				Hotkey, % Hotkey_Value(name), Off, UseErrorLevel
			Else IF (1, Hotkey_Write("MyHotkey" A_Index))
				Hotkey, % Hotkey_Value(name), L_%name%, UseErrorLevel On  
		}
	}
	Hotkey, IF
} 

ExitApp() {
	HotkeySet()
    ExitApp
}

L_MyHotkey1:
	MsgBox, , , % A_ThisLabel "`n" A_ThisHotkey, 0.6
	Return

L_MyHotkey2:
	MsgBox, , , % A_ThisLabel "`n" A_ThisHotkey, 0.6
	Return

L_MyHotkey3:
	MsgBox, , , % A_ThisLabel "`n" A_ThisHotkey, 0.6
	Return
	
L_MyHotkey4:
	MsgBox, , , % A_ThisLabel "`n" A_ThisHotkey, 0.6
	Return
	
	
	
	
	
	
	
	
	
SetStaticColor(hStatic, b_color, f_color)
{
	static arr := [], GWL_WNDPROC := -4
	hGui := DllCall("GetParent", Ptr, hStatic, Ptr)
	if !arr.HasKey(hGui)  {
		arr[hGui] := {}, arr[hGui].Statics := []
		arr[hGui].ProcOld := DllCall("SetWindowLong" . (A_PtrSize = 8 ? "Ptr" : ""), Ptr, hGui, Int, GWL_WNDPROC
												, Ptr, RegisterCallback("WindowProc", "", 4, Object(arr[hGui])), Ptr)
	}
	else if arr[hGui].Statics.HasKey(hStatic)
		DllCall("DeleteObject", Ptr, arr[hGui].Statics[hStatic].hBrush)
	arr[hGui].Statics[hStatic] := { b_color: Rgb2Bgr(b_color), f_color: Rgb2Bgr(f_color)
											, hBrush: DllCall("CreateSolidBrush", UInt, Rgb2Bgr(b_color), Ptr) }
	WinSet, Redraw,, ahk_id %hGui%
}
  ;	OnMessage( WM_CTLCOLORSTATIC, "WM_CTLCOLOR" )       https://autohotkey.com/board/topic/125484-change-background-color-of-individual-controls/
WindowProc(hwnd, uMsg, wParam, lParam)
{
	Critical
	static WM_CTLCOLORSTATIC := 0x138
	obj := Object(A_EventInfo)
	if (uMsg = WM_CTLCOLORSTATIC && k := obj.Statics[lParam])  {
		DllCall("SetBkColor", Ptr, wParam, UInt, k.b_color)
		DllCall("SetTextColor", Ptr, wParam, UInt, k.f_color)
		Return k.hBrush
	}
	Return DllCall("CallWindowProc", Ptr, obj.ProcOld, Ptr, hwnd, UInt, uMsg, Ptr, wParam, Ptr, lParam)
}
	
Rgb2Bgr(color)
{
	Return (color & 0xff) << 16 | ((color >> 8) & 0xff) << 8 | color >> 16
}
	
