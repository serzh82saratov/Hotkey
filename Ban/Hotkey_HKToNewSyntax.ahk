Hotkey_HKToNewSyntax(HK) {
	Static ArrEx := ["<^",">^","<+",">+","<!",">!","<#",">#"]
			, ArrSimple := ["^","+","!","#"]
	Local K, K1, K2, K3, M, i, v
	If (HK = "") || InStr(HK, " & ")
		Return HK
	RegExMatch(HK, "S)^\s*([~\*\$]*)([\^\+!#<>]*)(.*?)\s*$", K)
	If (K2 = "")
		Return HK
	for, i, v in (K2 ~= "S)[<>]") ? ArrEx : ArrSimple
		If Instr(K2, v)
			M .= v
	Return K1 . M . K3
}
