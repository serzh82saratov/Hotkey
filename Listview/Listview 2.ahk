#NoEnv
#SingleInstance Force

; Hotkey_Arr("KillFocus", true)  ; Запускать перед созданием контролов.
Hotkey_IniPath(A_ScriptDir "\Hotkey.ini")
Hotkey_IniSection("Hotkeys")
Hotkey_Arr("OnGroup", "OnGroupProc") 
; Hotkey_Arr("OnlyEngSym", True)

ArrLVActions := {1:"Action1",2:"Action2",3:"Action3",4:"Action4"}


Gui, -DPIScale +HWNDhGui
Gui, Font, s14

;  https://www.autohotkey.com/docs/misc/Styles.htm#LVS_EX
;  D:\AutoIt\=Help\ListView\WM_NOTIFY.ahk


LVS_EX_INFOTIP = LV0x400   ;  уведомляющее сообщение LVN_GETINFOTIP
LVS_EX_HEADERDRAGDROP = LV0x10   ;  	Включает перетаскивание столбцов в элементе управления представления списка.
Gui, Add, Listview
, x300 y100 w600 h480 cBlue gListview vListViewName hwndhLW AltSubmit NoSortHdr Grid -Multi -%LVS_EX_HEADERDRAGDROP% +%LVS_EX_INFOTIP% 
, Действие|Хоткей|Комментарий   
; Gui, Show


; Gui, New: +Parent%hGui% -Caption +AlwaysOnTop
; Gui,  New: Add, Edit, w686 h28 x0 y0 vetrtertert, sfdgdfgsdfgdfgdf
; Gui,  New: Show, x430 y158
 
Loop 24
{
	Name := "Action" A_Index 
	Hotkey_Add("Hotkey:w300 gHotkeyText", Name, "KMJG1", "*", "Save", A_Index)
	LV_Add("", Name, Hotkey_ValueText(Name))
} 
; Gui, Hotkey:Show
; Gui, %hGui%: Default
 
LV_ModifyCol(1, "150")
LV_ModifyCol(2, "300 Center")
LV_ModifyCol(3, "126")  
Gui, Show  
Return

Listview() {
	Critical
	; ToolTip % A_EventInfo "`n" A_GuiEvent "`n" ErrorLevel 
	i := LV_GetNext()
	If Hotkey_Arr("Hook") && (A_GuiEvent == "f" || !i || (A_GuiEvent = "S" && i)) 
		Hotkey_Main(), LV_Modify(i, "-Focus"), LV_Modify(i, "-Select")  
	Else If (A_GuiEvent = "DoubleClick" && i)
		LV_Modify(i, "col" 2,  Hotkey_Main("Clean"))
	Else If i && (A_GuiEvent == "Normal" || A_GuiEvent == "F")
	{
		Hotkey_Main(Hotkey_ID("Action" i)) 
	}
}
	

GLabel(Name) {
	LV_Modify(Hotkey_Arr("BindString")[Name], "col" 2, Hotkey_ValueText(Name))
} 

HotkeyText(hwnd) {  
	funcobj := Func("GLabel").Bind(Hotkey_ID(hwnd))
	Try SetTimer, % funcobj, -1
}

Save(Name) {
	SetTimer HideTooltip19, -800
	ToolTip % Hotkey_HKToStr(Hotkey_Write(Name)) "`n" Name "`n" A_TickCount "`n" "`n" A_DefaultListView, -33, -33, 19
	Return

	HideTooltip19:
		ToolTip, , , , 19
		Return
}

GuiEscape:
GuiClose:
Escape::  ExitApp


OnGroupProc(arr) {
 	for k, v in arr.names
		Row_Blink(Hotkey_Arr("BindString")[v])
}

Row_Blink(id) {
	Local k
	Static i, Blink := {}  
	LV_Modify(id, "col" 2, "")
	Blink[id] := 1, i := 5
	SetTimer, Row_BlinkControl, -50
	Return

	Row_BlinkControl:
		For k in Blink
			LV_Modify(k, "col" 2, !Mod(i, 2) ? "" : Hotkey_ValueText("Action" k))
		If (--i > 0) || !(Blink := {})
			SetTimer, Row_BlinkControl, -50
		Return
}
