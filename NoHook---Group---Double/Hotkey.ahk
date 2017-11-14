	;  Автор - serzh82saratov
	;  E-Mail: serzh82saratov@mail.ru
	;  Описание - http://forum.script-coding.com/viewtopic.php?id=8343

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
	OnMessage(0x203, "Hotkey_WM_LBUTTONDBLCLK")  ;	WM_LBUTTONDBLCLK
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
				,"sc31":"N","sc32":"M","sc33":",","sc34":".","sc35":"/","sc56":"\"}
	Local IsMod, Text
	
	If Param1 = GetMod
		Return K.MLCtrl K.MRCtrl K.MLAlt K.MRAlt K.MLShift K.MRShift K.MLWin K.MRWin K.MCtrl K.MAlt K.MShift K.MWin
	If Param1 = Clean
		Return K := {}, OnlyMods := 0, Hotkey := KeyName := ""
	If Param2
	{
		K := {}
		If OnlyMods && !(OnlyMods := 0)
			SendMessage, 0xC, 0, "" Hotkey_Arr("Empty"), , ahk_id %ControlHandle%
		ControlHandle := Param2
		Hotkey_Arr("Hook", Hotkey_Options(ControlHandle))
		PostMessage, 0x00B1, -1, -1, , ahk_id %ControlHandle%   ;  EM_SETSEL
	}
	Else If Hotkey_Arr("Hook")
	{
		Hotkey_Arr("Hook", 0)
		If OnlyMods && !(OnlyMods := 0)
			SendMessage, 0xC, 0, "" Hotkey_Arr("Empty"), , ahk_id %ControlHandle%
		SetTimer, Hotkey_IsRegFocus, -200
	}
	Return

Hotkey_Mods:
	If InStr(Hotkey_Arr("Hook"), "S") || InStr(Hotkey_Arr("Hook"), "W")
		GoTo Hotkey_View
	IsMod := InStr(Hotkey_Arr("Hook"), "D") ? A_ThisHotkey : SubStr(A_ThisHotkey, 2)
	If (K["M" IsMod] != "")
		Return
	K["M" IsMod] := IsMod " + ", K["P" IsMod] := Prefix[IsMod]
	GoTo Hotkey_ViewMod

Hotkey_ModsUp:
	If InStr(Hotkey_Arr("Hook"), "S") || InStr(Hotkey_Arr("Hook"), "W")
		Return
	IsMod := InStr(Hotkey_Arr("Hook"), "D") ? SubStr(A_ThisHotkey, 1, -3) : SubStr(A_ThisHotkey, 2, -3)
	K["M" IsMod] := "", K["P" IsMod] := ""
	If (Hotkey != "")
		Return

Hotkey_ViewMod:
	Hotkey := "", OnlyMods := 1, Hotkey_Value(Hotkey_ID(ControlHandle), ""), Hotkey_Value(ControlHandle, "")
	K.Mods := K.MLCtrl K.MRCtrl K.MLAlt K.MRAlt K.MLShift K.MRShift K.MLWin K.MRWin K.MCtrl K.MAlt K.MShift K.MWin
	Text := K.Mods = "" ? Hotkey_Arr("Empty") : K.Mods
	SendMessage, 0xC, 0, &Text, , ahk_id %ControlHandle%
	Return

Hotkey_ViewNum:
	 If InStr(Hotkey_Arr("Hook"), "N")
		KeyName := GetKeyName(A_ThisHotkey), Hotkey := A_ThisHotkey
	Else
		Hotkey := Format("sc{:x}", GetKeySC(A_ThisHotkey)), KeyName := GetKeyName(Hotkey)
	GoTo, Hotkey_Put

Hotkey_ViewNumExcept:
	If InStr(Hotkey_Arr("Hook"), "N")
		GetKeyState("NumLock", "T") ? (KeyName := "Numpad5", Hotkey := "vk65") : (KeyName := "NumpadClear", Hotkey := "vkC")
	Else
		KeyName := "NumpadClear", Hotkey := A_ThisHotkey
	GoTo, Hotkey_Put
	
Hotkey_ViewSC:
	KeyName := Hotkey_Arr("OnlyEngSym") ? EngSym[A_ThisHotkey] : Format("{:U}", GetKeyName(A_ThisHotkey))
	Hotkey := A_ThisHotkey
	GoTo, Hotkey_Put

Hotkey_View:
	KeyName := Hotkey := A_ThisHotkey

Hotkey_Put:
	If InStr(Hotkey_Arr("Hook"), "W")
		GoTo Hotkey_Double
	OnlyMods := 0
	K.Prefix := K.PLCtrl K.PRCtrl K.PLAlt K.PRAlt K.PLShift K.PRShift K.PLWin K.PRWin K.PCtrl K.PAlt K.PShift K.PWin
	Hotkey_Value(Hotkey_ID(ControlHandle), K.Prefix Hotkey), Hotkey_Value(ControlHandle, K.Prefix Hotkey)
	K.Mods := K.MLCtrl K.MRCtrl K.MLAlt K.MRAlt K.MLShift K.MRShift K.MLWin K.MRWin K.MCtrl K.MAlt K.MShift K.MWin
	Text := K.Mods KeyName = "" ? Hotkey_Arr("Empty") : K.Mods KeyName
	SendMessage, 0xC, 0, &Text, , ahk_id %ControlHandle%
	
Hotkey_GroupCheck:
	If Hotkey_Group("Get", Hotkey_ID(ControlHandle)) && Hotkey_Group("SaveCheck", ControlHandle)
		SetTimer, Hotkey_Group, -70
	Return

Hotkey_Double:
	If !K.Double
	{
		Hotkey_Value(Hotkey_ID(ControlHandle), ""), Hotkey_Value(ControlHandle, "")
		K.DHotkey := Hotkey, K.DName := KeyName, K.Double := 1, OnlyMods := 1
		Text := KeyName " & "
		SendMessage, 0xC, 0, &Text, , ahk_id %ControlHandle%
		Return
	}
	If (K.DHotkey = Hotkey)
		Return
	Hotkey_Value(Hotkey_ID(ControlHandle), K.DHotkey " & " Hotkey), Hotkey_Value(ControlHandle, K.DHotkey " & " Hotkey)
	Text := K.DName " & " KeyName, K.Double := 0, OnlyMods := 0
	SendMessage, 0xC, 0, &Text, , ahk_id %ControlHandle%
	GoTo, Hotkey_GroupCheck

Hotkey_RButton:
	If Hotkey_Hook("L") && GetKeyState("LButton"`, "P")
		KeyName := Hotkey := "LButton"
	Else If Hotkey_Hook("R")
		KeyName := Hotkey := "RButton"
	Else
		Return
	GoTo, Hotkey_Put
}

Hotkey_InitHotkeys(Option = 1) {
	Local S_FormatInteger, S_BatchLines
	Static nmMods := "LAlt|RAlt|LCtrl|RCtrl|LShift|RShift|LWin|RWin"
	, nmMouse := "MButton|WheelDown|WheelUp|WheelRight|WheelLeft|XButton1|XButton2"
	, scSymb := "2|3|4|5|6|7|8|9|A|B|C|D|10|11|12|13|14|15|16|17|18|19|1A|1B|"
		. "1E|1F|20|21|22|23|24|25|26|27|28|29|2B|2C|2D|2E|2F|30|31|32|33|34|35|56"
	, scOther := "1|E|F|1C|37|39|3A|3B|3C|3D|3E|3F|40|41|42|43|44|45|46|4A|4E|54|57|58|63|64|65|"
		. "66|67|68|69|6A|6B|6C|6D|6E|76|7C|11C|135|145|147|148|149|14B|14D|14F|150|151|152|153|15D"
	, vkNum := "21|22|23|24|25|26|27|28|2D|2E|60|61|62|63|64|66|67|68|69|6E|C|65"	; , scNum := "53|52|4F|50|51|4B|4D|47|48|49|4C|59"
	, vkOther := "3|13|5F|A6|A7|A8|A9|AA|AB|AC|AD|AE|AF|B0|B1|B2|B3|B4|B5|B6|B7"
	S_BatchLines := A_BatchLines
	Option := Option ? "On" : "Off"
	SetBatchLines, -1
	#IF Hotkey_IsRegControl()
	#IF Hotkey_Hook("K")
	#IF Hotkey_Hook("M")
	#IF Hotkey_Hook("L") && GetKeyState("RButton", "P")
	#IF Hotkey_Hook("R") || Hotkey_Hook("L")
	#IF Hotkey_Hook("J") && !Hotkey_Main("GetMod")
	#IF Hotkey_Arr("Hook") && !Hotkey_Hook("K")
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
	Hotkey, IF, Hotkey_Hook("R") || Hotkey_Hook("L")
	Hotkey, RButton, Hotkey_Return, % Option
	Hotkey, RButton Up, Hotkey_RButton, % Option
	S_FormatInteger := A_FormatInteger
	SetFormat, IntegerFast, D
	Hotkey, IF, Hotkey_Hook("J") && !Hotkey_Main("GetMod")
	Loop, 128
		Hotkey % Ceil(A_Index / 32) "Joy" Mod(A_Index - 1, 32) + 1, Hotkey_View, % Option
	SetFormat, IntegerFast, %S_FormatInteger%
	Hotkey, IF, Hotkey_IsRegControl()
	Hotkey, RButton, Hotkey_Return, % Option
	Hotkey, RButton Up, Hotkey_Return, % Option
	Hotkey, IF, Hotkey_Arr("Hook") && !Hotkey_Hook("K")
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
	SendMessage, 0xC, 0, "" Hotkey_Arr("Empty"), , ahk_id %hwnd%
	Hotkey_Value(hwnd, ""), Hotkey_Value(Hotkey_ID(hwnd), ""), Hotkey_Main("Clean")
	Sleep 50
	PostMessage, 0x00B1, -1, -1, , ahk_id %hwnd%   ;  EM_SETSEL
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

Hotkey_Hook(Option) {
	Return Hotkey_Arr("Hook") && !!InStr(Hotkey_Arr("Hook"), Option)
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

Hotkey_Delete(ID, Destroy = 0) {
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

Hotkey_Set(Name, Value = "") {
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
	Local Name
	Name := (ID + 0 = "") ? ID : Hotkey_ID(ID)
	If (Name != "")
		IniWrite, % Hotkey_Value(ID), % FilePath = "" ? Hotkey_IniPath() : FilePath, % Section = "" ? Hotkey_IniSection() : Section, % Name
}

	; -------------------------------------- Group --------------------------------------

Hotkey_Group(Key = "", p1 = "", p2 = "") {
	Local Name, Value, k, v, n, m, f, r
	Static NG := {}, GN := [], Blink := [], SaveCheck := [], i := 0
	If (Key = "") {
		For k, Name in SaveCheck {
			If ((Value := Hotkey_Value(Name)) != "") {
				(f := Hotkey_Arr("GroupEvents")) != "" && (r := {}, r.names := [])
				For m, n in GN[NG[Name]] {
					If (n != Name && Hotkey_Equal(Value, Hotkey_Value(n))) {
						Hotkey_Set(Name)
						(f != "") && (r.names.Push(n), r.this := Name, r.value := Value, r.group := NG[Name])
						If !DllCall("IsWindowVisible", "Ptr", Hotkey_ID(n))
							Continue
						DllCall("ShowWindowAsync", "Ptr", Hotkey_ID(n), "Int", 0)
						Blink[Hotkey_ID(n)] := 1, i := 3
						SetTimer, Hotkey_BlinkControl, -50
					}
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
	Local Bool
	If (HK2 = "")
		Return 0
	If (HK1 = HK2)
		Return 1
	If Hotkey_EqualDouble(HK1, HK2, Bool) || Hotkey_EqualDouble(HK2, HK1, Bool)
		Return Bool
	If !(HK1 ~= "S)[\^\+!#]") || !(HK2 ~= "S)[\^\+!#]")
		Return 0		
	If (HK1 ~= "S)[<>]") && (HK2 ~= "S)[<>]")
		Return 0
	Return (Hotkey_ModsSub(HK1) = Hotkey_ModsSub(HK2))
}

Hotkey_EqualDouble(HK1, HK2, ByRef Bool) {
	Static Prefix := {"LAlt":"<!","LCtrl":"<^","LShift":"<+","LWin":"<#"
					,"RAlt":">!","RCtrl":">^","RShift":">+","RWin":">#"}
	Local K, K1, K2
	If InStr(HK1, " & ") && !InStr(HK2, " & ") && (HK2 ~= "S)[\^\+!#]")
	&& (HK1 ~= "S)(L|R)(Ctrl|Alt|Shift|Win) & ") 
	&& !(HK1 ~= "S) & (L|R)(Ctrl|Alt|Shift|Win)")
	{
		RegExMatch(HK1, "S)^\s*(.*?) & (.*?)\s*$", K)
		K := Prefix[K1] . K2
		If (HK2 ~= "S)[<>]")
			Return 1, Bool := K = HK2
		Return 1, Bool := RegExReplace(K, "(<|>)") = HK2
	}
	Return 0
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

Hotkey_HKToStr(HK) {
	Static Prefix := {"^":"Ctrl","!":"Alt","+":"Shift","#":"Win","<":"L",">":"R"}
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
	Static V := {"^":"Ctrl","!":"Alt","+":"Shift","#":"Win","<":"L",">":"R","":"L"}
	Local K, K1, K2, M1, M2, R, R1, R2, P := 1
	If (HK = "")
		Return
	If (Section != "")
		IniRead, HK, % FilePath = "" ? Hotkey_IniPath() : FilePath, % Section, % HK, % A_Space
	If InStr(HK, " & ") && (1, RegExMatch(HK, "S)^\s*(.*?) & (.*?)\s*$", K))
		Return "{" K1 " Down}{" K2 " Down}{" K1 " Up}{" K2 " Up}"
	RegExMatch(HK, "S)^\s*([~\*\$\^\+!#<>]*)\{?(.*?)}?\s*$", K)
	While P := RegExMatch(K1, "S)([<>])*([\^\+!#])", R, P) + StrLen(R)
		M1 .= "{" V[R1] V[R2] " Down}", M2 .= "{" V[R1] V[R2] " Up}"
	Return M1 . "{" K2 "}" . M2
}
