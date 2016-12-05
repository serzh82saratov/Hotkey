
	;  http://forum.script-coding.com/viewtopic.php?id=8343

Hotkey_Register(Controls*) {
	Static IsStart
	Local k, v, g, g1
	For k, v in Controls
	{
		Hotkey_ID(v[2], v[1]), Hotkey_ID(v[1], v[2])
		Hotkey_Options(v[2], v[3] = "" ? "K" : v[3])
		Hotkey_Value(v[2], Hotkey_Value(v[1]))
		PostMessage, 0x00CF, 1, , , % "ahk_id" v[2]   ;  EM_SETREADONLY
		If RegExMatch(v[3], "i)G(\d+)", g)
			Hotkey_Group("Set", v[1], g1)
	}
	If IsStart
		Return Hotkey_IsRegFocus()
	#HotkeyInterval 0
	Hotkey_SetWinEventHook(0x8005, 0x8005, 0, RegisterCallback("Hotkey_EventFocus", "F"), 0, 0, 0)   ;  EVENT_OBJECT_FOCUS := 0x8005
	Hotkey_InitHotkeys(), Hotkey_IsRegFocus(), IsStart := 1
}

Hotkey_Main(Param1, Param2 = "") {
	Static OnlyMods, ControlHandle, Hotkey, KeyName, K := {}
	, Prefix := {"LAlt":"<!","LCtrl":"<^","LShift":"<+","LWin":"<#"
				,"RAlt":">!","RCtrl":">^","RShift":">+","RWin":">#"
				,"Alt":"!","Ctrl":"^","Shift":"+","Win":"#"}
	, EngSym := {"sc2":"1","sc3":"2","sc4":"3","sc5":"4","sc6":"5","sc7":"6"
				,"sc8":"7","sc9":"8","scA":"9","scB":"0","scC":"-","scD":"="
				,"sc10":"Q","sc11":"W","sc12":"E","sc13":"R","sc14":"T","sc15":"Y"
				,"sc16":"U","sc17":"I","sc18":"O","sc19":"P","sc1A":"[","sc1B":"]"
				,"sc1E":"A","sc1F":"S","sc20":"D","sc21":"F","sc22":"G","sc23":"H"
				,"sc24":"J","sc25":"K","sc26":"L","sc27":"`;","sc28":"'","sc29":"``"
				,"sc2B":"\","sc2C":"Z","sc2D":"X","sc2E":"C","sc2F":"V","sc30":"B"
				,"sc31":"N","sc32":"M","sc33":",","sc34":".","sc35":"/"}
	Local IsMod, Text

	If Param1 = GetMod
		Return K.MLCtrl K.MRCtrl K.MLAlt K.MRAlt K.MLShift K.MRShift K.MLWin K.MRWin K.MCtrl K.MAlt K.MShift K.MWin
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
	Return

Hotkey_Mods:
	If InStr(Hotkey_Arr("Hook"), "S")
		GoTo Hotkey_View
	IsMod := InStr(Hotkey_Arr("Hook"), "D") ? A_ThisHotkey : SubStr(A_ThisHotkey, 2)
	If (K["M" IsMod] != "")
		Return
	K["M" IsMod] := IsMod "+", K["P" IsMod] := Prefix[IsMod]
	GoTo Hotkey_ViewMod

Hotkey_ModsUp:
	If InStr(Hotkey_Arr("Hook"), "S")
		Return
	IsMod := InStr(Hotkey_Arr("Hook"), "D") ? SubStr(A_ThisHotkey, 1, -3) : SubStr(A_ThisHotkey, 2, -3)
	K["M" IsMod] := "", K["P" IsMod] := ""
	If (Hotkey != "")
		Return

Hotkey_ViewMod:
	Hotkey := "", OnlyMods := 1, Hotkey_Value(Hotkey_ID(ControlHandle), K.Prefix Hotkey), Hotkey_Value(ControlHandle, K.Prefix Hotkey)
	K.Mods := K.MLCtrl K.MRCtrl K.MLAlt K.MRAlt K.MLShift K.MRShift K.MLWin K.MRWin K.MCtrl K.MAlt K.MShift K.MWin
	Text := K.Mods = "" ? Hotkey_Arr("Empty") : K.Mods
	SendMessage, 0xC, 0, &Text, , ahk_id %ControlHandle%
	Return

Hotkey_View:
Hotkey_ViewSC:
	If (A_ThisLabel = "Hotkey_ViewSC")
		KeyName := Hotkey_Arr("OnlyEngSym") ? EngSym[A_ThisHotkey] : Format("{:U}", GetKeyName(A_ThisHotkey))
	Else
		KeyName := A_ThisHotkey
	Hotkey := A_ThisHotkey, OnlyMods := 0
	K.Prefix := K.PLCtrl K.PRCtrl K.PLAlt K.PRAlt K.PLShift K.PRShift K.PLWin K.PRWin K.PCtrl K.PAlt K.PShift K.PWin
	Hotkey_Value(Hotkey_ID(ControlHandle), K.Prefix Hotkey), Hotkey_Value(ControlHandle, K.Prefix Hotkey)
	K.Mods := K.MLCtrl K.MRCtrl K.MLAlt K.MRAlt K.MLShift K.MRShift K.MLWin K.MRWin K.MCtrl K.MAlt K.MShift K.MWin
	Text := K.Mods KeyName = "" ? Hotkey_Arr("Empty") : K.Mods KeyName
	SendMessage, 0xC, 0, &Text, , ahk_id %ControlHandle%
	If Hotkey_Group("Get", Hotkey_ID(ControlHandle)) && Hotkey_Group("SaveCheck", ControlHandle)
		SetTimer, Hotkey_Group, -70
	Return
}

Hotkey_InitHotkeys() {
	Local S_FormatInteger, S_BatchLines
	Static nmMods := "LAlt|RAlt|LCtrl|RCtrl|LShift|RShift|LWin|RWin"
	, nmMouse := "MButton|WheelDown|WheelUp|WheelRight|WheelLeft|XButton1|XButton2"
	, scSymb := "2|3|4|5|6|7|8|9|A|B|C|D|10|11|12|13|14|15|16|17|18|19|1A|1B|"
		. "1E|1F|20|21|22|23|24|25|26|27|28|29|2B|2C|2D|2E|2F|30|31|32|33|34|35"
	, scNoSymb := "1|E|F|1C|37|39|3A|3B|3C|3D|3E|3F|40|41|42|43|44|45|46|47|48|49|4A|4B|4C|4D|4E|4F|50|51|52|"
		. "53|54|57|58|63|64|65|66|67|68|69|6A|6B|6C|6D|6E|76|11C|135|147|148|149|14B|14D|14F|150|151|152|153|15D"
	, vkOther := "3|13|5F|60|61|62|63|64|65|66|67|68|69|6E|A6|A7|A8|A9|AA|AB|AC|AD|AE|AF|B0|B1|B2|B3|B4|B5|B6|B7"
	S_BatchLines := A_BatchLines
	SetBatchLines, -1
	#IF Hotkey_IsRegControl()
	#IF Hotkey_Hook("K")
	#IF Hotkey_Hook("M")
	#IF Hotkey_Hook("L") && GetKeyState("RButton", "P")
	#IF Hotkey_Hook("R")
	#IF Hotkey_Hook("J") && !Hotkey_Main("GetMod")
	#IF Hotkey_Arr("Hook") && !Hotkey_Hook("K")
	#IF
	Hotkey, IF, Hotkey_Hook("M")
	Loop, Parse, nmMouse, |
		Hotkey, % A_LoopField, Hotkey_View
	Hotkey, IF, Hotkey_Hook("K")
	Loop, Parse, nmMods, |
	{
		Hotkey, % A_LoopField, Hotkey_Mods
		Hotkey, % A_LoopField " Up", Hotkey_ModsUp
	}
	Loop, Parse, scSymb, |
		Hotkey, % "sc" A_LoopField, Hotkey_ViewSC
	Loop, Parse, scNoSymb, |
		Hotkey, % GetKeyName("sc" A_LoopField), Hotkey_View
	Loop, Parse, vkOther, |
		Hotkey, % GetKeyName("vk" A_LoopField), Hotkey_View
	Hotkey, IF, Hotkey_Hook("L") && GetKeyState("RButton"`, "P")
	Hotkey, LButton, Hotkey_View
	Hotkey, IF, Hotkey_Hook("R")
	Hotkey, RButton, Hotkey_View
	S_FormatInteger := A_FormatInteger
	SetFormat, IntegerFast, D
	Hotkey, IF, Hotkey_Hook("J") && !Hotkey_Main("GetMod")
	Loop, 128
		Hotkey % Ceil(A_Index / 32) "Joy" Mod(A_Index - 1, 32) + 1, Hotkey_View
	SetFormat, IntegerFast, %S_FormatInteger%
	Hotkey, IF, Hotkey_IsRegControl()
	Hotkey, RButton, Hotkey_RButton
	Hotkey, RButton Up, Hotkey_Return
	Hotkey, IF, Hotkey_Arr("Hook") && !Hotkey_Hook("K")
	Hotkey, AppsKey Up, Hotkey_Return
	Hotkey, +F10, Hotkey_Return
	Hotkey, IF
	SetBatchLines, %S_BatchLines%
	Return

	Hotkey_RButton:
		Click
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

Hotkey_EventFocus(hWinEventHook, event, hwnd) {
	Hotkey_ID(hwnd) != "" ? Hotkey_Main("Control", hwnd) : Hotkey_Main("Control")
}

Hotkey_SetWinEventHook(eventMin, eventMax, hmodWinEventProc, lpfnWinEventProc, idProcess, idThread, dwFlags) {
	Return DllCall("SetWinEventHook" , "UInt", eventMin, "UInt", eventMax, "Ptr", hmodWinEventProc
			, "Ptr", lpfnWinEventProc, "UInt", idProcess, "UInt", idThread, "UInt", dwFlags, "Ptr")
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
	Local Hwnd, Name, g, g1
	(ID + 0 = "") ? (Hwnd := Hotkey_ID(ID), Name := ID) : (Hwnd := ID, Name := Hotkey_ID(ID))
	If RegExMatch(Hotkey_Options(Hwnd), "i)G(\d+)", g)
		Hotkey_Group("Delete", Name)
	If RegExMatch(Option, "i)G(\d+)", g)
		Hotkey_Group("Set", Name, g1)
	Return Hotkey_Options(Hwnd, Option)
}

Hotkey_Hook(Option) {
	Return Hotkey_Arr("Hook") && !!InStr(Hotkey_Arr("Hook"), Option)
}

Hotkey_Delete(ID, Destroy=0) {
	Local Hwnd, Name, hFocus, ControlNN
	(ID + 0 = "") ? (Hwnd := Hotkey_ID(ID), Name := ID) : (Hwnd := ID, Name := Hotkey_ID(ID))
	Hotkey_Group("Delete", Name)
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
	Local Text
	Text := Hotkey_HKToStr(Value)
	SendMessage, 0xC, 0, &Text, , % "ahk_id" Hotkey_ID(Name)
	Return Text, Hotkey_Value(Name, Value), Hotkey_Value(Hotkey_ID(Name), Value)
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

	; -------------------------------------- Group --------------------------------------

Hotkey_Group(Key = "", p1 = "", p2 = "") {
	Local Name, Value, k, v, n, m
	Static NG := {}, GN := [], Blink := [], SaveCheck := [], i := 0
	If (Key = "") {
		For k, Name in SaveCheck {
			If ((Value := Hotkey_Value(Name)) != "")
				For m, n in GN[NG[Name]] {
					If (n != Name && Hotkey_Equal(Value, Hotkey_Value(n))) {
						Hotkey_Set(Name)
						If !DllCall("IsWindowVisible", "Ptr", Hotkey_ID(n))
							Return
						DllCall("ShowWindowAsync", "Ptr", Hotkey_ID(n), "Int", 0)
						Blink[Hotkey_ID(n)] := 1, i := 3
						SetTimer, Hotkey_BlinkControl, -50
					}
				}
			SaveCheck.Delete(k)
		}
	}
	Else If (Key = "Set")
		NG[p1] := p2, IsObject(GN[p2]) ? GN[p2].Push(p1) : GN[p2] := [p1]
	Else If (Key = "SaveCheck")
		Return 1, SaveCheck[p1] := Hotkey_ID(p1)
	Else If (Key = "Get")
		Return NG[p1] != ""
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
	Return

	Hotkey_BlinkControl:
		For k in Blink
			DllCall("ShowWindowAsync", "Ptr", k, "Int", Mod(i, 2) ? 4 : 0)
		If (--i > 0) || !(Blink := [])
			SetTimer, Hotkey_BlinkControl, -50
		Return
}

Hotkey_Equal(HK1, HK2) {
	If (HK2 = "")
		Return 0
	If (HK1 = HK2)
		Return 1
	If !(HK1 ~= "S)[\^\+!#]") || !(HK2 ~= "S)[\^\+!#]")
		Return 0
	If (HK1 ~= "S)[<>]") && (HK2 ~= "S)[<>]")
		Return 0
	Return (Hotkey_ModsSub(HK1) = Hotkey_ModsSub(HK2))
}

Hotkey_ModsSub(Value) {
	If !(Value ~= "[<>]")
		Return Value
	Value := StrReplace(Value, "<")
	Value := StrReplace(Value, ">")
	Value := StrReplace(Value, "^^", "^", , 1)
	Value := StrReplace(Value, "!!", "!", , 1)
	Value := StrReplace(Value, "++", "+", , 1)
	Return StrReplace(Value, "##", "#", , 1)
}

	; -------------------------------------- Format --------------------------------------

	; http://forum.script-coding.com/viewtopic.php?pid=105023#p105023

Hotkey_HKToStr(HK) {
	Static LRPrefix := [["<^","LCtrl"],[">^","RCtrl"],["<!","LAlt"],[">!","RAlt"]
					,["<+","LShift"],[">+","RShift"],["<#","LWin"],[">#","RWin"]]
	, Prefix := [["^","Ctrl"],["!","Alt"],["+","Shift"],["#","Win"]]
	, EngSym := {"sc2":"1","sc3":"2","sc4":"3","sc5":"4","sc6":"5","sc7":"6"
				,"sc8":"7","sc9":"8","scA":"9","scB":"0","scC":"-","scD":"="
				,"sc10":"Q","sc11":"W","sc12":"E","sc13":"R","sc14":"T","sc15":"Y"
				,"sc16":"U","sc17":"I","sc18":"O","sc19":"P","sc1A":"[","sc1B":"]"
				,"sc1E":"A","sc1F":"S","sc20":"D","sc21":"F","sc22":"G","sc23":"H"
				,"sc24":"J","sc25":"K","sc26":"L","sc27":"`;","sc28":"'","sc29":"``"
				,"sc2B":"\","sc2C":"Z","sc2D":"X","sc2E":"C","sc2F":"V","sc30":"B"
				,"sc31":"N","sc32":"M","sc33":",","sc34":".","sc35":"/"

				,"vk31":"1","vk32":"2","vk33":"3","vk34":"4","vk35":"5","vk36":"6"
				,"vk37":"7","vk38":"8","vk39":"9","vk30":"0","vkBD":"-","vkBB":"="
				,"vk51":"Q","vk57":"W","vk45":"E","vk52":"R","vk54":"T","vk59":"Y"
				,"vk55":"U","vk49":"I","vk4F":"O","vk50":"P","vkDB":"[","vkDD":"]"
				,"vk41":"A","vk53":"S","vk44":"D","vk46":"F","vk47":"G","vk48":"H"
				,"vk4A":"J","vk4B":"K","vk4C":"L","vkBA":"`;","vkDE":"'","vkC0":"``"
				,"vkDC":"\","vk5A":"Z","vk58":"X","vk43":"C","vk56":"V","vk42":"B"
				,"vk4E":"N","vk4D":"M","vkBC":",","vkBE":".","vkBF":"/"}

	Local K, K1, K2, I, V, M, R
	RegExMatch(HK, "S)^\s*([~\*\$\^\+!#<>]*)\{?(.*?)}?\s*$", K)
	If (K2 = "")
		Return "" Hotkey_Arr("Empty")
	If (InStr("|" K2, "|sc", 1) || InStr("|" K2, "|vk", 1))
		K2 := Hotkey_Arr("OnlyEngSym") && EngSym.HasKey(K2) ? EngSym[K2] : Format("{:U}", GetKeyName(K2))
	If (K1 != "")
		For I, V in K1 ~= "[<>]" ? LRPrefix : Prefix
			K1 := StrReplace(K1, V[1], "", R), R && (M .= V[2] "+")
	Return M . (StrLen(K2) = 1 ? Format("{:U}", K2) : K2)
}

Hotkey_HKToSend(HK, Section = "", FilePath = "") {
	Static LRPrefix := [["<^","LCtrl"],[">^","RCtrl"],["<!","LAlt"],[">!","RAlt"]
					,["<+","LShift"],[">+","RShift"],["<#","LWin"],[">#","RWin"]]
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
