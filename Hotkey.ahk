
	;  http://forum.script-coding.com/viewtopic.php?id=8343

Hotkey_Register(Handles) {
	Static IsStart
	Loop, Parse, Handles, `,,%A_Space%%A_Tab%
	{
		Hotkey_("Name", %A_LoopField%, A_LoopField)
		GuiControl, +ReadOnly, % %A_LoopField%
	}
	If IsStart
		Return
	Hotkey_SetWinEventHook(0x8005, 0x8005, 0, RegisterCallback("Hotkey_WinEvent", "F"), 0, 0, 0)   ;  EVENT_OBJECT_FOCUS := 0x8005
	Hotkey_Arr("hHook", Hotkey_SetWindowsHookEx())
	Return IsStart := 1
}

Hotkey_Main(Param1, Param2=0) {
	Static OnlyMods, ControlHandle, Hotkey, KeyName
		, MCtrl, MAlt, MShift, MWin, PCtrl, PAlt, PShift, PWin, Prefix
		, Pref := {"Alt":"!","Ctrl":"^","Shift":"+","Win":"#"}
		, Symbols := "|vkBA|vkBB|vkBC|vkBD|vkBE|vkBF|vkC0|vkDB|vkDC|vkDD|vkDE|vk41|vk42|"
					. "vk43|vk44|vk45|vk46|vk47|vk48|vk49|vk4A|vk4B|vk4C|vk4D|vk4E|"
					. "vk4F|vk50|vk51|vk52|vk53|vk54|vk55|vk56|vk57|vk58|vk59|vk5A|"
	Local IsMod, WriteText

	If Param1 = GetMod
		Return MCtrl MAlt MShift MWin = "" ? 0 : 1
	If Param1 = Control
	{
		If Param2
		{
			If OnlyMods
				SendMessage, 0xC, 0, "" Hotkey_Arr("Empty"), , ahk_id %ControlHandle%
			OnlyMods := 0, ControlHandle := Param2
			If !Hotkey_Arr("Hook")
				Hotkey_Arr("Hook", 1)
			PostMessage, 0x00B1, -1, -1, , ahk_id %ControlHandle%   ;  EM_SETSEL
		}
		Else If Hotkey_Arr("Hook")
		{
			Hotkey_Arr("Hook", 0)
			MCtrl := MAlt := MShift := MWin := ""
			PCtrl := PAlt := PShift := PWin := Prefix := ""
			If OnlyMods
				SendMessage, 0xC, 0, "" Hotkey_Arr("Empty"), , ahk_id %ControlHandle%
		}
		Return
	}
	If Param1 = Mod
	{
		IsMod := Param2
		If (M%IsMod% != "")
			Return 1
		M%IsMod% := IsMod "+", P%IsMod% := Pref[IsMod]
	}
	Else If Param1 = ModUp
	{
		IsMod := Param2, M%IsMod% := P%IsMod% := ""
		If (Hotkey != "")
			Return 1
	}
	(IsMod) ? (KeyName := Hotkey := Prefix := "", OnlyMods := 1)
	: (KeyName := GetKeyName(Param1 Param2)
	, (StrLen(KeyName) = 1 ? (KeyName := Format("{:U}", KeyName)) : 0)
	, Hotkey := InStr(Symbols, "|" Param1 "|") ? Param1 : KeyName
	, KeyName := Hotkey = "vkBF" ? "/" : KeyName
	, Prefix := PCtrl PAlt PShift PWin, OnlyMods := 0)
	Hotkey_("Value", Hotkey_("Name", ControlHandle), Prefix Hotkey)
	WriteText := MCtrl MAlt MShift MWin KeyName = "" ? Hotkey_Arr("Empty") : MCtrl MAlt MShift MWin KeyName
	SendMessage, 0xC, 0, &WriteText, , ahk_id %ControlHandle%
	Return 1

Hotkey_PressName:
	KeyName := Hotkey := A_ThisHotkey
	Prefix := PCtrl PAlt PShift PWin
	OnlyMods := 0
	Hotkey_("Value", Hotkey_("Name", ControlHandle), Prefix Hotkey)
	WriteText := MCtrl MAlt MShift MWin KeyName
	SendMessage, 0xC, 0, &WriteText, , ahk_id %ControlHandle%
	Return
}

Hotkey_WinEvent(hWinEventHook, event, hwnd) {
	Hotkey_("Name", hwnd) != "" ? Hotkey_Main("Control", hwnd) : Hotkey_Main("Control")
}

Hotkey_Option(Options) {
	Local S_FormatInteger, MouseKey
	#IF Hotkey_Arr("Hook")
	#IF Hotkey_Arr("Hook") && Hotkey_Main("GetMod")
	#IF Hotkey_Arr("Hook") && !Hotkey_Main("GetMod")
	#IF
	IfInString, Options, M
	{
		MouseKey := "MButton|WheelDown|WheelUp|WheelRight|WheelLeft|XButton1|XButton2"
		Hotkey, IF, Hotkey_Arr("Hook")
		Loop, Parse, MouseKey, |
			Hotkey, %A_LoopField%, Hotkey_PressName
	}
	IfInString, Options, J
	{
		S_FormatInteger := A_FormatInteger
		SetFormat, IntegerFast, D
		Hotkey, IF, Hotkey_Arr("Hook") && !Hotkey_Main("GetMod")
		Loop, 128
			Hotkey % Ceil(A_Index/32) "Joy" Mod(A_Index-1,32)+1, Hotkey_PressName
		SetFormat, IntegerFast, %S_FormatInteger%
	}
	IfInString, Options, L
	{
		Hotkey, IF, Hotkey_Arr("Hook") && Hotkey_Main("GetMod")
		Hotkey, LButton, Hotkey_PressName
	}
	IfInString, Options, R
	{
		Hotkey, IF, Hotkey_Arr("Hook")
		Hotkey, RButton, Hotkey_PressName
		Hotkey_RButton(1)
	}
	Else
		Hotkey_RButton(0)
	Hotkey, IF
}

Hotkey_LowLevelKeyboardProc(nCode, wParam, lParam) {
	Static Mods := {"vkA4":"Alt","vkA5":"Alt","vkA2":"Ctrl","vkA3":"Ctrl"
		,"vkA0":"Shift","vkA1":"Shift","vk5B":"Win","vk5C":"Win"}
		, oMem := [], HEAP_ZERO_MEMORY := 0x8, Size := 16, hHeap := DllCall("GetProcessHeap", Ptr)
	Local pHeap, Wp, Lp, Ext, VK, SC, IsMod
	Critical

	If !Hotkey_Arr("Hook")
		Return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "UInt", wParam, "UInt", lParam)
	pHeap := DllCall("HeapAlloc", Ptr, hHeap, UInt, HEAP_ZERO_MEMORY, Ptr, Size, Ptr)
	DllCall("RtlMoveMemory", Ptr, pHeap, Ptr, lParam, Ptr, Size), oMem.Push([wParam, pHeap])
	SetTimer, Hotkey_LLKPWork, -10
	Return nCode < 0 ? DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "UInt", wParam, "UInt", lParam) : 1

	Hotkey_LLKPWork:
		While (oMem[1] != "")
		{
			IF Hotkey_Arr("Hook")
			{
				Wp := oMem[1][1], Lp := oMem[1][2]
				VK := Format("vk{:X}", NumGet(Lp + 0, "UInt"))
				Ext := NumGet(Lp + 0, 8, "UInt")
				SC := Format("sc{:X}", (Ext & 1) << 8 | NumGet(Lp + 0, 4, "UInt"))
				IsMod := Mods[VK]
				If (Wp = 0x100 || Wp = 0x104)		;  WM_KEYDOWN := 0x100, WM_SYSKEYDOWN := 0x104
					(IsMod := Mods[VK]) ? Hotkey_Main("Mod", IsMod) : Hotkey_Main(VK, SC)
				Else IF ((Wp = 0x101 || Wp = 0x105) && VK != "vk5D")   ;  WM_KEYUP := 0x101, WM_SYSKEYUP := 0x105, AppsKey = "vk5D"
					(IsMod := Mods[VK]) ? Hotkey_Main("ModUp", IsMod) : 0
			}
			DllCall("HeapFree", Ptr, hHeap, UInt, 0, Ptr, Lp)
			oMem.RemoveAt(1)
		}
		Return
}

Hotkey_SetWinEventHook(eventMin, eventMax, hmodWinEventProc, lpfnWinEventProc, idProcess, idThread, dwFlags) {
	Return DllCall("SetWinEventHook" , "UInt", eventMin, "UInt", eventMax, "Ptr", hmodWinEventProc
			, "Ptr", lpfnWinEventProc, "UInt", idProcess, "UInt", idThread, "UInt", dwFlags, "Ptr")
}

Hotkey_SetWindowsHookEx() {
	Return DllCall("SetWindowsHookEx" . (A_IsUnicode ? "W" : "A")
		, "Int", 13   ;  WH_KEYBOARD_LL := 13
		, "Ptr", RegisterCallback("Hotkey_LowLevelKeyboardProc", "Fast")
		, "Ptr", DllCall("GetModuleHandle", "UInt", 0, "Ptr")
		, "UInt", 0, "Ptr")
}

Hotkey_Exit() {
	DllCall("UnhookWindowsHookEx", "Ptr", Hotkey_Arr("hHook"))
}

Hotkey_Arr(P*) {
	Static Arr := {Empty:"Нет"}
	Return P.MaxIndex() = 1 ? Arr[P[1]] : (Arr[P[1]] := P[2])
}

Hotkey_(Type, P*) {
	Static ArrName := [], ArrValue := {}
	Return P.MaxIndex() = 1 ? Arr%Type%[P[1]] : (Arr%Type%[P[1]] := P[2])
}

Hotkey_IsRegControl() {
	Local Control
	MouseGetPos,,,, Control, 2
	Return Hotkey_("Name", Control) != ""
}

Hotkey_RButton(RM) {
	#IF Hotkey_IsRegControl()
	#IF !Hotkey_Arr("Hook") && Hotkey_IsRegControl()
	#IF
	If RM
		Hotkey, IF, !Hotkey_Arr("Hook") && Hotkey_IsRegControl()
	Else
		Hotkey, IF, Hotkey_IsRegControl()
	Hotkey, RButton Up, Hotkey_RButton
	Hotkey, IF
	Return

	Hotkey_RButton:
		Click
		Return
}

	; -------------------------------------- Format func --------------------------------------

Hotkey_Get(Key, Section="", FilePath="") {
	Local Data
	If FilePath =
		Return Hotkey_("Value", Key)
	IniRead, Data, % FilePath, % Section, % Key, % A_Space
	Return Hotkey_HKToStr(Data), Hotkey_("Value", Key, Data)
}

Hotkey_HKToStr(Key) {
	Local K, K1, K2, KeyName
	RegExMatch(Key, "S)^([\^\+!#]*)\{?(.*?)}?$", K)
	If (K2 = "")
		Return "" Hotkey_Arr("Empty")
	If InStr(K2, "vk")
		KeyName := K2 = "vkBF" ? "/" : GetKeyName(K2)
	Else
		KeyName := K2
	Return (InStr(K1,"^")?"Ctrl+":"")(InStr(K1,"!")?"Alt+":"")
			. (InStr(K1,"+")?"Shift+":"")(InStr(K1,"#")?"Win+":"")
			. (StrLen(KeyName) = 1 ? Format("{:U}", KeyName) : KeyName)
}

Hotkey_HKToSend(Key, Section = "", Path = "") {
	Local Data
	If (Section != "")
		IniRead, Data, % Path, % Section, % Key, % A_Space
	Return RegExReplace(Data, "S)[^\^!\+#].*", "{$0}")
}
