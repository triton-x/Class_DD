﻿; v1.33 (2019-5-22) - Updated RunAsAdmin and DD_demo.ahk
; v1.32 (2017-3-12) - Added nCount prameter to _btn_press()
; v1.31 (2017-3-11) - Added _key_pressEx(); Added x, y paramaters to _btn() and _btn_press()
; v1.30 (2017-3-11) - Added _btn_press()
; v1.20 (2017-1-18) - Added 4 methods: GetActiveWindow/MouseMove/SnapPic/PickColor
; v1.10 (2017-1-18) - Allow _key_press() to send Key combinations
; v1.00 (2017-1-18)

class DD extends DD_Helper
{
	; Simulate mouse button press
	; param:   1 = LButton Down,    2 = LButton Up
	;          4 = RButton Down,    8 = RButton Up
	;         16 = MButton Down,   32 = MButton Up
	;         64 = Button 4 Down, 128 = Button 4 Up
	;        256 = Button 5 Down, 512 = Button 5 Up
	btn(param) {
		return DllCall(this.dllFile "\DD_btn", "int", param)
	}

	; Simulate mouse move
	mov(x, y) {
		return DllCall(this.dllFile "\DD_mov", "int", x, "int", y)
	}

	; Simulate mouse move (relatively)
	movR(dx, dy) {
		return DllCall(this.dllFile "\DD_movR", "int", dx, "int", dy)
	}

	; Simulate mouse wheel
	; param: 1=upward 2=downward
	whl(param) {
		return DllCall(this.dllFile "\DD_whl", "int", param)
	}

	; Simulate keyboard
	; param1: DD code
	; param2: 1=Down 2=Up
	key(param1, param2) {
		return DllCall(this.dllFile "\DD_key", "int", param1, "int", param2)
	}

	; VKCode to DD code
	todc(VKCode) {
		return DllCall(this.dllFile "\DD_todc", "int", VKCode)
	}

	; Send string
	str(string) {
		return DllCall(this.dllFile "\DD_str", "astr", string)
	}

	; Get hwnd of active window
	GetActiveWindow() {
		; return DllCall(this.dllFile "\DD_GetActiveWindow", "ptr") ; seems not working
		return WinExist("A")
	}

	MouseMove(hwnd, x, y) {
		return DllCall(this.dllFile "\DD_MouseMove", "ptr", hwnd, "int", x, "int", y)
	}

	; The picture is saved to "C:\DD Snap\" folder
	SnapPic(hwnd, x, y, w, h) {
		return DllCall(this.dllFile "\DD_SnapPic", "ptr", hwnd, "int", x, "int", y, "int", w, "int", h)
	}

	PickColor(hwnd, x, y, mode=2) {
		return DllCall(this.dllFile "\DD_PickColor", "ptr", hwnd, "int", x, "int", y, "int", mode)
	}
}

class DD_Helper
{
	static _ := DD_Helper.InitClass()

	InitClass() {
		this.RunAsAdmin()
		this.LoadDll()
	}

	; https://www.autohotkey.com/docs/commands/Run.htm#RunAs
	RunAsAdmin() {
		full_command_line := DllCall("GetCommandLine", "str")

		if not (A_IsAdmin or RegExMatch(full_command_line, " /restart(?!\S)"))
		{
			try
			{
				if A_IsCompiled
					Run *RunAs "%A_ScriptFullPath%" /restart
				else
					Run *RunAs "%A_AhkPath%" /restart "%A_ScriptFullPath%"
			}
			ExitApp
		}
	}

	LoadDll() {
		dllFile := (A_PtrSize=8) ? "DD64.dll" : "DD32.dll"

		if !this.hModule := DllCall("LoadLibrary", "Str", dllFile, "Ptr") {
			if !FileExist(dllFile) {
				throw, dllFile " not found."
			}
			throw, "LoadLibrary failed. DllFile is " dllFile
		}
		this.dllFile := dllFile
	}

	UnloadDll() {
		DllCall("FreeLibrary", "Ptr", this.hModule)
	}
	
	; Example: _btn("RButtonDown")
	_btn(sNick, x:="", y:="") {
		static oNick := { LButtonDown: 1, LButtonUp: 2
		                , RButtonDown: 4, RButtonUp: 8
		                , MButtonDown: 16, MButtonUp: 32
		                , 4ButtonDown: 64, 4ButtonUp: 128
		                , 5ButtonDown: 256, 5ButtonUp: 512 }
		if !( n := oNick[sNick] ) {
			throw, sNick " is not a valid nick."
		}
		if (x != "") {
			this.mov(x, y)
		}
		this.btn(n)
	}

	; Example: _btn_press("RButton")
	_btn_press(sNick, x:="", y:="", nCount:=1) {
		static oNick := { LButton: {Down: 1, Up: 2}
		                , RButton: {Down: 4, Up: 8}
		                , MButton: {Down: 16, Up: 32}
		                , 4Button: {Down: 64, Up: 128}
		                , 5Button: {Down: 256, Up: 512} }
		if !( o := oNick[sNick] ) {
			throw, sNick " is not a valid nick."
		}
		if (x != "") {
			this.mov(x, y)
		}
		Loop, % nCount {
			this.btn( o.Down )
			this.btn( o.Up )
			Sleep, 5
		}
	}

	; Example: _key("F11", "Down")
	;          _key("F11", "Up")
	_key(sKey, sflag) {
		ddCode := this._key_to_dc(sKey)
		this.key(ddCode, (sflag="Up") ? 2 : 1 )
	}

	; Example: _key_press("F11")
	;          _key_press("Ctrl", "A")
	_key_press(sKey*) {
		arr_ddCode := []

		for i, k in sKey {
			arr_ddCode[i] := this._key_to_dc(k)
			this.key(arr_ddCode[i], 1) ; Down
		}
		for i, ddCode in arr_ddCode {
			this.key(ddCode, 2) ; Up
		}
	}

	_key_pressEx(sKey, nCount := 1) {
		ddCode := this._key_to_dc(sKey)

		Loop, % nCount {
			this.key(ddCode, 1) ; Down
			this.key(ddCode, 2) ; Up
		}
	}

	; Example: _whl("down")
	;          _whl("up")
	_whl(sParam) {
		this.whl( (sParam="Up") ? 1 : 2 )
	}

	_key_to_dc(key) {
		static o := {"Win": "Lwin"}

		if o.HasKey(key)
			key := o[key]

		return this.todc( GetKeyVK(key) )
	}
}
