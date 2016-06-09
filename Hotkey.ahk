	;  http://forum.script-coding.com/viewtopic.php?pid=72549#p72549

Hotkey_Register(Controls*) {
	Static IsStart
	Local k, v
	For k, v in Controls
	{
;		If (v[1] = "" || v[1] + 0 != "" || v[2] + 0 = "")
;			Throw "Invalid name or hwnd for Hotkey_Register"
;		If (Hotkey_ID(v[1]) != "")
;			Throw "Control already exists for Hotkey_Register"
		Hotkey_ID(v[2], v[1]), Hotkey_ID(v[1], v[2])
		Hotkey_Options(v[2], v[3] = "" ? "K" : v[3])
		Hotkey_Value(v[2], Hotkey_Value(v[1]))
		PostMessage, 0x00CF, 1, , , % "ahk_id" v[2]   ;  EM_SETREADONLY
	}
	Hotkey_IsRegFocus()
	If IsStart
		Return
	#HotkeyInterval 0
	Hotkey_SetWinEventHook(0x8005, 0x8005, 0, RegisterCallback("Hotkey_WinEvent", "F"), 0, 0, 0)   ;  EVENT_OBJECT_FOCUS := 0x8005
	Hotkey_Arr("hHook", Hotkey_SetWindowsHookEx()), Hotkey_InitHotkeys(), IsStart := 1, Hotkey_IsRegFocus()
}

Hotkey_Main(Param1, Param2=0) {
	Static OnlyMods, ControlHandle, Hotkey, KeyName, K := {}
	, Prefix := {"LAlt":"<!","LCtrl":"<^","LShift":"<+","LWin":"<#"
				,"RAlt":">!","RCtrl":">^","RShift":">+","RWin":">#"
				,"Alt":"!","Ctrl":"^","Shift":"+","Win":"#"}
	, EngSym := {"vkBB":"=","vkBC":",","vkBD":"-","vkBE":".","vkBF":"/","vkC0":"``","vkBA":"`;"
				,"vkDB":"[","vkDC":"\","vkDD":"]","vkDE":"'","vk41":"A","vk42":"B","vk43":"C"
				,"vk44":"D","vk45":"E","vk46":"F","vk47":"G","vk48":"H","vk49":"I","vk4A":"J"
				,"vk4B":"K","vk4C":"L","vk4D":"M","vk4E":"N","vk4F":"O","vk50":"P","vk51":"Q"
				,"vk52":"R","vk53":"S","vk54":"T","vk55":"U","vk56":"V","vk57":"W","vk58":"X"
				,"vk59":"Y","vk5A":"Z"}
	Local IsMod, Text

	If Param1 = GetMod
		Return K.MLCtrl K.MRCtrl K.MLAlt K.MRAlt K.MLShift K.MRShift K.MLWin K.MRWin K.MCtrl K.MAlt K.MShift K.MWin
	If Param1 = Control
	{
		If Param2
		{
			If OnlyMods
			{
				SendMessage, 0xC, 0, "" Hotkey_Arr("Empty"), , ahk_id %ControlHandle%
				OnlyMods := 0, K := {}
			}
			ControlHandle := Param2
			Hotkey_Arr("Hook", Hotkey_Options(ControlHandle))
			PostMessage, 0x00B1, -1, -1, , ahk_id %ControlHandle%   ;  EM_SETSEL
		}
		Else If Hotkey_Arr("Hook")
		{
			Hotkey_Arr("Hook", 0), K := {}
			If OnlyMods
				SendMessage, 0xC, 0, "" Hotkey_Arr("Empty"), , ahk_id %ControlHandle%
			SetTimer, Hotkey_IsRegFocus, -200
		}
		Return 1
	}
	If Param1 = Mod
	{
		IsMod := Hotkey_Hook("D") ? Param2 : SubStr(Param2, 2)
		If (K["M" IsMod] != "")
			Return 1
		K["M" IsMod] := IsMod "+", K["P" IsMod] := Prefix[IsMod]
	}
	Else If Param1 = ModUp
	{
		IsMod := Hotkey_Hook("D") ? Param2 : SubStr(Param2, 2)
		K["M" IsMod] := "", K["P" IsMod] := ""
		If (Hotkey != "")
			Return 1
	}
	(IsMod) ? (KeyName := Hotkey := K.Prefix := "", OnlyMods := 1)
	: (KeyName := GetKeyName(Param1 Param2), OnlyMods := 0
	, (StrLen(KeyName) = 1 ? (KeyName := Format("{:U}", KeyName)) : 0)
	, Hotkey := EngSym.HasKey(Param1) ? Param1 : KeyName
	, KeyName := Hotkey = "vkBF" ? "/" : KeyName
	, (Hotkey_Arr("OnlyEngSym") && EngSym.HasKey(Param1) ? (KeyName := EngSym[Param1]) : 0)
	, K.Prefix := K.PLCtrl K.PRCtrl K.PLAlt K.PRAlt K.PLShift K.PRShift K.PLWin K.PRWin K.PCtrl K.PAlt K.PShift K.PWin)
	Hotkey_Value(Hotkey_ID(ControlHandle), K.Prefix Hotkey)
	Hotkey_Value(ControlHandle, K.Prefix Hotkey)
	K.Mods := K.MLCtrl K.MRCtrl K.MLAlt K.MRAlt K.MLShift K.MRShift K.MLWin K.MRWin K.MCtrl K.MAlt K.MShift K.MWin
	Text := K.Mods KeyName = "" ? Hotkey_Arr("Empty") : K.Mods KeyName
	SendMessage, 0xC, 0, &Text, , ahk_id %ControlHandle%
	Return 1

Hotkey_PressName:
	KeyName := Hotkey := A_ThisHotkey, OnlyMods := 0
	K.Prefix := K.PLCtrl K.PRCtrl K.PLAlt K.PRAlt K.PLShift K.PRShift K.PLWin K.PRWin K.PCtrl K.PAlt K.PShift K.PWin
	Hotkey_Value(Hotkey_ID(ControlHandle), K.Prefix Hotkey)
	Hotkey_Value(ControlHandle, K.Prefix Hotkey)
	K.Mods := K.MLCtrl K.MRCtrl K.MLAlt K.MRAlt K.MLShift K.MRShift K.MLWin K.MRWin K.MCtrl K.MAlt K.MShift K.MWin
	Text := K.Mods KeyName
	SendMessage, 0xC, 0, &Text, , ahk_id %ControlHandle%
	Return
}

Hotkey_LowLevelKeyboardProc(nCode, wParam, lParam) {
	Static Mods := {"vkA4":"LAlt","vkA5":"RAlt","vkA2":"LCtrl","vkA3":"RCtrl"
		,"vkA0":"LShift","vkA1":"RShift","vk5B":"LWin","vk5C":"RWin"}
		, oMem := [], HEAP_ZERO_MEMORY := 0x8, Size := 16, hHeap := DllCall("GetProcessHeap", "Ptr")
	Local pHeap, Wp, Lp, Ext, VK, SC, IsMod

	If !Hotkey_Hook("K")
		Return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "UInt", wParam, "UInt", lParam)
	pHeap := DllCall("HeapAlloc", "Ptr", hHeap, "UInt", HEAP_ZERO_MEMORY, "Ptr", Size, "Ptr")
	DllCall("RtlMoveMemory", "Ptr", pHeap, "Ptr", lParam, "Ptr", Size), oMem.Push([wParam, pHeap])
	SetTimer, Hotkey_LLKPWork, -10
	Return nCode < 0 ? DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "UInt", wParam, "UInt", lParam) : 1

	Hotkey_LLKPWork:
		While (oMem[1] != "")
		{
			IF Hotkey_Hook("K")
			{
				Wp := oMem[1][1], Lp := oMem[1][2]
				VK := Format("vk{:X}", NumGet(Lp + 0, "UInt"))
				Ext := NumGet(Lp + 0, 8, "UInt")
				SC := Format("sc{:X}", (Ext & 1) << 8 | NumGet(Lp + 0, 4, "UInt"))
				If !Hotkey_Hook("S")
					IsMod := Mods[VK]
				If (Wp = 0x100 || Wp = 0x104)		;  WM_KEYDOWN := 0x100, WM_SYSKEYDOWN := 0x104
					IsMod ? Hotkey_Main("Mod", IsMod) : Hotkey_Main(VK, SC)
				Else IF ((Wp = 0x101 || Wp = 0x105) && VK != "vk5D")   ;  WM_KEYUP := 0x101, WM_SYSKEYUP := 0x105, AppsKey = "vk5D"
					IsMod ? Hotkey_Main("ModUp", IsMod) : 0
			}
			DllCall("HeapFree", "Ptr", hHeap, "UInt", 0, "Ptr", Lp)
			oMem.RemoveAt(1)
		}
		Return
}

Hotkey_InitHotkeys() {
	Local S_FormatInteger
	Static MouseKey := "MButton|WheelDown|WheelUp|WheelRight|WheelLeft|XButton1|XButton2"
	#IF Hotkey_IsRegControl()
	#IF Hotkey_Hook("M")
	#IF Hotkey_Hook("L") && GetKeyState("RButton", "P")
	#IF Hotkey_Hook("R")
	#IF Hotkey_Hook("J") && !Hotkey_Main("GetMod")
	#IF

	Hotkey, IF, Hotkey_Hook("M")
	Loop, Parse, MouseKey, |
		Hotkey, %A_LoopField%, Hotkey_PressName

	Hotkey, IF, Hotkey_Hook("L") && GetKeyState("RButton"`, "P")
	Hotkey, LButton, Hotkey_PressName

	Hotkey, IF, Hotkey_Hook("R")
	Hotkey, RButton, Hotkey_PressName

	S_FormatInteger := A_FormatInteger
	SetFormat, IntegerFast, D
	Hotkey, IF, Hotkey_Hook("J") && !Hotkey_Main("GetMod")
	Loop, 128
		Hotkey % Ceil(A_Index/32) "Joy" Mod(A_Index-1,32)+1, Hotkey_PressName
	SetFormat, IntegerFast, %S_FormatInteger%

	Hotkey, IF, Hotkey_IsRegControl()
	Hotkey, RButton Up, Hotkey_RButton_Up
	Hotkey, RButton, Hotkey_RButton
	Hotkey, IF
	Return

	Hotkey_RButton:
		Click
	Hotkey_RButton_Up:
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

Hotkey_WinEvent(hWinEventHook, event, hwnd) {
	Hotkey_ID(hwnd) != "" ? Hotkey_Main("Control", hwnd) : Hotkey_Main("Control")
}

Hotkey_SetWinEventHook(eventMin, eventMax, hmodWinEventProc, lpfnWinEventProc, idProcess, idThread, dwFlags) {
	Return DllCall("SetWinEventHook" , "UInt", eventMin, "UInt", eventMax, "Ptr", hmodWinEventProc
			, "Ptr", lpfnWinEventProc, "UInt", idProcess, "UInt", idThread, "UInt", dwFlags, "Ptr")
}

Hotkey_SetWindowsHookEx() {
	OnExit("Hotkey_Exit")
	Return DllCall("SetWindowsHookEx" . (A_IsUnicode ? "W" : "A")
		, "Int", 13   ;  WH_KEYBOARD_LL := 13
		, "Ptr", RegisterCallback("Hotkey_LowLevelKeyboardProc", "Fast")
		, "Ptr", DllCall("GetModuleHandle", "UInt", 0, "Ptr")
		, "UInt", 0, "Ptr")
}

Hotkey_Exit() {
	DllCall("UnhookWindowsHookEx", "Ptr", Hotkey_Arr("hHook"))
}

	; -------------------------------------- Save and get --------------------------------------

Hotkey_Arr(P*) {
	Static Arr := {"Empty":"Нет"}
	Return P.MaxIndex() = 1 ? Arr[P[1]] : (Arr[P[1]] := P[2])
}

Hotkey_ID(P*) {
	Static Arr := {}
	Return P.MaxIndex() = 1 ? Arr[P[1]] : P.MaxIndex() = 2 ? (Arr[P[1]] := P[2]) : Arr.Delete(P[1])
}

Hotkey_Value(P*) {
	Static Arr := {}
	Return P.MaxIndex() = 1 ? Arr[P[1]] : P.MaxIndex() = 2 ? (Arr[P[1]] := P[2]) : Arr.Delete(P[1])
}

Hotkey_Options(P*) {
	Static Arr := {}
	Return P.MaxIndex() = 1 ? Arr[P[1]] : P.MaxIndex() = 2 ? (Arr[P[1]] := P[2]) : Arr.Delete(P[1])
}

Hotkey_ChangeOption(ID, Option) {
	Local Hwnd
	Hwnd := (ID + 0 != "") ? ID : Hotkey_ID(ID)
	Return Hotkey_Options(Hwnd, Option)
}

Hotkey_Hook(Option) {
	Return !!InStr(Hotkey_Arr("Hook"), Option)
}

Hotkey_Delete(ID, Destroy=0) {
	Local Hwnd, Name, hFocus, ControlNN
	(ID + 0 = "") ? (Hwnd := Hotkey_ID(ID), Name := ID) : (Hwnd := ID, Name := Hotkey_ID(ID))
	Hotkey_ID(Hwnd, "", 1), Hotkey_ID(Name, "", 1)
	Hotkey_Value(Hwnd, "", 1), Hotkey_Value(Name, "", 1)
	Hotkey_Options(Hwnd, "", 1)
	ControlGetFocus, ControlNN, A
	ControlGet, hFocus, Hwnd, , %ControlNN%, A
	(hFocus = Hwnd ? Hotkey_Main("Control") : 0)
	If Destroy
		DllCall("DestroyWindow", "Ptr", Hwnd)
	Else
		PostMessage, 0x00CF, 0, , , % "ahk_id" Hwnd		;  EM_SETREADONLY
	Return Hwnd
}

Hotkey_Set(Name, Value="") {
	Hotkey_Value(Name, Value)
	Return Hotkey_HKToStr(Value)
}

Hotkey_Read(Name, Section = "", FilePath = "") {
	Local HK
	HK := Hotkey_IniRead(Name, Section, FilePath), Hotkey_Value(Name, HK)
	Return Hotkey_HKToStr(HK)
}

Hotkey_IniPath(Path = "") {
	Return Path = "" ? Hotkey_Arr("IniPath") : Hotkey_Arr("IniPath", Path)
}

Hotkey_IniSection(Section = "") {
	Return Section = "" ? Hotkey_Arr("IniSection") : Hotkey_Arr("IniSection", Section)
}

Hotkey_IniRead(Name, Section = "", FilePath = "") {
	Local Data
	IniRead, Data, % FilePath = "" ? Hotkey_IniPath() : FilePath, % Section = "" ? Hotkey_IniSection() : Section, % Name, % A_Space
	Return Data
}

Hotkey_IniWrite(ID, Section = "", FilePath = "") {
	Local Key
	Key := (ID + 0 = "") ? ID : Hotkey_ID(ID)
	If (Key != "")
		IniWrite, % Hotkey_Value(ID), % FilePath = "" ? Hotkey_IniPath() : FilePath, % Section = "" ? Hotkey_IniSection() : Section, % Key
}

	; -------------------------------------- Format --------------------------------------

Hotkey_HKToStr(HK) {
	Static LRPrefix := [["<^","LCtrl"],[">^","RCtrl"],["<!","LAlt"],[">!","RAlt"]
	,["<+","LShift"],[">+","RShift"],["<#","LWin"],[">#","RWin"]]
	, Prefix := [["^","Ctrl"],["!","Alt"],["+","Shift"],["#","Win"]]
	, EngSym := {"vkBB":"=","vkBC":",","vkBD":"-","vkBE":".","vkBF":"/","vkC0":"``","vkBA":"`;"
				,"vkDB":"[","vkDC":"\","vkDD":"]","vkDE":"'","vk41":"A","vk42":"B","vk43":"C"
				,"vk44":"D","vk45":"E","vk46":"F","vk47":"G","vk48":"H","vk49":"I","vk4A":"J"
				,"vk4B":"K","vk4C":"L","vk4D":"M","vk4E":"N","vk4F":"O","vk50":"P","vk51":"Q"
				,"vk52":"R","vk53":"S","vk54":"T","vk55":"U","vk56":"V","vk57":"W","vk58":"X"
				,"vk59":"Y","vk5A":"Z"}
	Local K, K1, K2, I, V, M, R
	RegExMatch(HK, "S)^\s*([~\*\$\^\+!#<>]*)\{?(.*?)}?\s*$", K)
	If (K2 = "")
		Return "" Hotkey_Arr("Empty")
	If InStr("|" K2, "|vk")
		K2 := K2 = "vkBF" ? "/" : (Hotkey_Arr("OnlyEngSym") && EngSym.HasKey(K2) ? EngSym[K2] : GetKeyName(K2))
	If (K1 != "")
		For I, V in K1 ~= "[<>]" ? LRPrefix : Prefix
			K1 := StrReplace(K1, V[1], "", R), R && (M .= V[2] "+")
	Return M . (StrLen(K2) = 1 ? Format("{:U}", K2) : K2)
}

Hotkey_HKToSend(HK, Section = "", FilePath = "") {
	Static LRPrefix := [["<^","LCtrl"],[">^","RCtrl"],["<!","LAlt"]
	,[">!","RAlt"],["<+","LShift"],[">+","RShift"],["<#","LWin"],[">#","RWin"]]
	, Prefix := [["^","LCtrl"],["!","LAlt"],["+","LShift"],["#","LWin"]]
	Local K, K1, K2, I, V, M1, M2, R
	If (HK = "")
		Return
	If (Section != "")
		IniRead, HK, % FilePath = "" ? Hotkey_IniPath() : FilePath, % Section, % HK, % A_Space
	RegExMatch(HK, "S)^\s*([~\*\$\^\+!#<>]*)\{?(.*?)}?\s*$", K)
	If (K1 != "")
		For I, V in K1 ~= "[<>]" ? LRPrefix : Prefix
			K1 := StrReplace(K1, V[1], "", R)
			, R ? (M1 .= "{" V[2] " Down}", M2 .= "{" V[2] " Up}") : 0
	Return M1 . "{" K2 "}" . M2
}
