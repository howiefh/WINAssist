; ************************************************************************************************
;        Version:  1.2
;           Date:  2013/05/05
;		Platform:  Windows 7
;	      Author:  howiefh
;         E-mail:  howiefh@gmail.com
;    Description:  Assist for Windows
; ************************************************************************************************
;  NOTE:PLEASE DO NOT REMOVE INFO ABOVE THIS LINE WHEN YOUR BUILD YOUR OWN SCRIPT
; ************************************************************************************************
#Include include/URLDownloadToVar.ahk
#Include include/json.ahk
#Include include/convertCodepage.ahk
;ClipJump
#Include include/imagelib.ahk
#Include include/HotkeyParser.ahk
#include include/gdiplus.ahk
#SingleInstance,Force

#Persistent

applicationname := SubStr(A_ScriptName, 1, StrLen(A_ScriptName) - 4)
IfNotExist,%A_ScriptDir%\%applicationname%.ini
{
	tooltip,Not exist %A_ScriptDir%\%applicationname%.ini
	sleep 1000
	tooltip 
	ExitApp
}
; 中键打开文件
; 必须初始化数组
SoftList := Object()
ExtList := Object()
loop 
{
	IniRead, SoftTemp, %A_ScriptDir%\%applicationname%.ini, softpath,soft_%a_index%
	IniRead, ExtListTemp, %A_ScriptDir%\%applicationname%.ini, ExtList, ExtList_%a_index%
	If (SoftTemp = "ERROR")
      Break
	SoftList[a_index] := SoftTemp
	ExtList[a_index] := ExtListTemp
}
IniRead, GVIM, %A_ScriptDir%\%applicationname%.ini, softpath,GVIM
; IniRead, gvimExtList, %A_ScriptDir%\%applicationname%.ini, ExtList,gvimExtList
; IniRead, SPLAYER, %A_ScriptDir%\%applicationname%.ini, softpath,SPLAYER
; IniRead, POTPLAYER, %A_ScriptDir%\%applicationname%.ini, softpath,POTPLAYER
; IniRead, potplayerExtList, %A_ScriptDir%\%applicationname%.ini, ExtList, potplayerExtList
IniRead, screenCaptureSoft, %A_ScriptDir%\%applicationname%.ini, softpath,ScreenCaptureSoft

; HDDMonitor
HDDMtitle = Drives Leds 

Menu, THISISASECRETMENU, Add, List&Lines, ListLines
Menu, THISISASECRETMENU, Add, List&Vars, ListVars
Menu, THISISASECRETMENU, Add, List&Hotkeys, ListHotkeys
Menu, THISISASECRETMENU, Add, &KeyHistory, KeyHistory
Hotkey, !^#F, f_ShowMenuX, UseErrorLevel

;******************************* function  *******************************{{{
;=================== 公共函数 ===================
;验证是否开启或禁用某功能
FnSwitch(FnID)
{
global BlackList
MouseGetPos,x,y,MouseID,MouseControl
WinGetClass,MouseClass,ahk_id %MouseID%
;msgbox,%FnID%---000 BlackList=%BlackList%
	If(BlackList<>"")
	{
		
		If MouseClass in %BlackList%
		{
		;
			return 0
			;msgbox,%FnID%---222
		}
		else
		{
		
		;msgbox,%FnID%---333  Not in BlackListGroup
			if (Fn%FnID%_V=1)
				return 1
			else if (Fn%FnID%_V=0 or Fn%FnID%_V="")
				return 0
			else
			{
			
			;msgbox,%FnID%---444
				temp0:=Fn%FnID%_V
				If MouseClass in %temp0%
				{
					;msgbox,will return 0 haha
					
					return 0
				}
				else
				{
				
					return 1
				}
			}

		}
		
		;GoSub,GetInfoUnderMouse
	}
	else
	{
	;If BlackList="" it will run from here
		if (Fn%FnID%_V=1)
			return 1
		else if (Fn%FnID%_V=0 or Fn%FnID%_V="")
			return 0
		else
		{
		
		;msgbox,%FnID%---444
			temp:=Fn%FnID%_V
			If MouseClass in %temp%
			{
				;msgbox,will return 0 haha
				
				return 0
			}
			else
			{
			
				return 1
			}
		}
	}	
}
;foldermenu function
f_CreateFavorite(ThisMenu, ThisMenuItem, ThisMenuItemFirstChar, Pos)
{
   Global
   Local ThisMenuItem0
   Local ThisMenuItem1
   Local ThisMenuItem2
   if ThisMenuItemFirstChar = :   ; start with ':' indicates a submenu
   {
      StringTrimLeft, ThisMenuItem, ThisMenuItem, 1   ; trim ':'
      StringSplit, ThisMenuItem, ThisMenuItem, |   ; get submenu
      StringTrimLeft, ThisMenuItem2, ThisMenuItem, StrLen(ThisMenuItem1)+1   ; get item
      ThisMenuItem1 = %ThisMenuItem1%   ; Trim leading and trailing spaces.
      ThisMenuItem2 = %ThisMenuItem2%   ; Trim leading and trailing spaces.
      StringLeft, ThisMenuItem2FirstChar, ThisMenuItem2, 1
      if f_IfMenuItemNotExist(ThisMenu, ThisMenuItem1)   ; first time to create this submenu
      {
         %ThisMenuItem1%ItemPos = 1   ; this menu count 1
         %ThisMenu%ItemPos++      ; parent menu +1
      }
      f_CreateFavorite(ThisMenuItem1, ThisMenuItem2, ThisMenuItem2FirstChar, %ThisMenuItem1%ItemPos)
      Menu, %ThisMenu%, Add, %ThisMenuItem1%, :%ThisMenuItem1%
   }
   else if ThisMenuItem = -   ; '-' indicates a separator
   {
      Menu, %ThisMenu%, Add
      %ThisMenu%ItemPos++
   }
   else   ; a fav item
   {
      StringSplit, ThisMenuItem, ThisMenuItem, `=
      ThisMenuItem1 = %ThisMenuItem1%   ; Trim leading and trailing spaces.
      ThisMenuItem2 = %ThisMenuItem2%   ; Trim leading and trailing spaces.
      ; Resolve any references to variables within either field, and
      ; create a new array element containing the path of this favorite:
      if !f_IfMenuItemNotExist(ThisMenu, ThisMenuItem1)
      {
         Msgbox, 16, Error, Item [%ThisMenuItem1%] duplicated.`n`nPlease check your config file.
         return
      }
      Transform, i_%ThisMenu%_%Pos%_Path, deref, %ThisMenuItem2%
;      Transform, i_%ThisMenu%_%Pos%_Name, deref, %ThisMenuItem1%
      Menu, %ThisMenu%, Add, %ThisMenuItem1%, f_OpenFavorite
	  ifexist,%A_ScriptDir%\icon\%ThisMenuItem1%.ico
	  {
		  ; 如果菜单项存在
		  if f_IfMenuItemNotExist(ThisMenu, ThisMenuItem1)
			 Menu tray, Icon, %ThisMenuItem1%,%A_ScriptDir%\icon\%ThisMenuItem1%.ico
	  }
      %ThisMenu%ItemPos++
   }
   return
}


f_IfMenuItemNotExist(Menu, Item)   ; test if a menuitem exist, 1 for NOT exist.
{
   Menu, %Menu%, UseErrorLevel
   Menu, %Menu%, Enable, %Item%
   if ErrorLevel   ; Not exist
   {
      Menu, %Menu%, UseErrorLevel, OFF
      return 1
   }
   else   ; Exist
   {
      Menu, %Menu%, UseErrorLevel, OFF
      return 0
   }
}

;******************************* 滚轮 *******************************
IsCorner(CN) {
	temp0=0
	SysGet, MonFull, Monitor
	CoordMode,Mouse, Screen   ;为MouseGetPos命令设置相对于激活窗口或屏幕的坐标模式。
	MouseGetPos, xpos, ypos , Win
	;MonFullRight=1366        MonFullBottom=768
	;右下角
	If (CN=3)
	{
		If (xpos>MonFullRight*0.9 and ypos>MonFullBottom*0.95)
			temp0=1
	}
	;左下角
	else If (CN=4)
	{
		If (xpos<MonFullRight*0.05 and ypos>MonFullBottom*0.95)
			temp0=1
	}
	;右上角
	else If (CN=2)
	{
		If (xpos>MonFullRight*0.95 and ypos<MonFullBottom*0.05)
			temp0=1
	}
	;左上角
	else If (CN=1)
	{
		If (xpos<MonFullRight*0.05 and ypos<MonFullBottom*0.05)
			temp0=1
	}

	If temp0=1
		return 1
	else
		return 0
}
;WheelUp::SendMessage, 0x115, 0, 0, %MouseControl%, ahk_id %MouseID%
MouseIsOver2(WinTitle,x) {

	SysGet, MonFull, Monitor
	MouseGetPos, xpos, ypos , Win
	;If (xpos>MonFullRight-10 and ypos>MonFullBottom-20)
	return WinExist(WinTitle . " ahk_id " . Win) and xpos<MonFullRight*x
}
Show_Vol(Now_Vol)
{
	if Now_Vol=0
		return 0
	else
	{
		Var = %Now_Vol%
		SetFormat, float, 6.0
		Var -= 1
		Var += 1
		return Var
	}
}
;******************************* 链接转换：迅雷、快车、旋风地址转换为普通地址 *******************************
DeCode(c) { ; c = a char in Chars ==> position [0,63]
   Global Chars
   Return InStr(Chars,c,1) - 1
}
Base64Decode(code) {
   StringReplace, code, code, `r,,All
   StringReplace, code, code, `n,,All
   Loop Parse, code
   {
      m := A_Index & 3 ; mod 4
      IfEqual m,0, {
         buffer += DeCode(A_LoopField)
         out := out Chr(buffer>>16) Chr(255 & buffer>>8) Chr(255 & buffer)
      }
      Else IfEqual m,1, SetEnv buffer, % DeCode(A_LoopField) << 18
      Else buffer += DeCode(A_LoopField) << 24-6*m
   }
   IfEqual m,0, Return out
   IfEqual m,2, Return out Chr(buffer>>16)
   Return out Chr(buffer>>16) Chr(255 & buffer>>8)
}
;******************************* 定时关机 *******************************
ShutdownTimeCheck(as_hr,as_min){
	If as_hr is not integer
		return 0
	else If as_min is not integer
		return 0
	else If (as_hr>23 or as_hr<0)
		return 0
	else If (as_min>59 or as_min<0)
		return 0		
	else
		return 1		
}
;;THE END OF FUN_ShutdownTimeCheck
PlayWAV(wavfile)
{
IfExist, %A_WinDir%\Media\%wavfile%.wav
	SoundPlay, %A_WinDir%\Media\%wavfile%.wav
else
	SoundPlay *48
}

;******************************* screenlock 白领们的小助手：老板键、视力保护、锁屏三合一软件  *******************************
EmptyMem(PID="AHK Rocks"){
    pid:=(pid="AHK Rocks") ? DllCall("GetCurrentProcessId") : pid
    h:=DllCall("OpenProcess", "UInt", 0x001F0FFF, "Int", 0, "Int", pid)
    DllCall("SetProcessWorkingSetSize", "UInt", h, "Int", -1, "Int", -1)
    DllCall("CloseHandle", "Int", h)
}

SystemCursor(OnOff=1)   ; INIT = "I","Init"; OFF = 0,"Off"; TOGGLE = -1,"T","Toggle"; ON = others
{
   static AndMask, XorMask, $, h_cursor
      , c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13 ; system cursors
      ,    b1,b2,b3,b4,b5,b6,b7,b8,b9,b10,b11,b12,b13   ; blank cursors
      ,    h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13   ; handles of default cursors
   if (OnOff = "Init" or OnOff = "I" or $ = "")      ; init when requested or at first call
   {
      $ = h                                ; active default cursors
      VarSetCapacity( h_cursor,4444, 1 )
      VarSetCapacity( AndMask, 32*4, 0xFF )
      VarSetCapacity( XorMask, 32*4, 0 )
      system_cursors = 32512,32513,32514,32515,32516,32642,32643,32644,32645,32646,32648,32649,32650
      StringSplit c, system_cursors, `,
      Loop %c0%
      {
         h_cursor   := DllCall( "LoadCursor", "uint",0, "uint",c%A_Index% )
         h%A_Index% := DllCall( "CopyImage",  "uint",h_cursor, "uint",2, "int",0, "int",0, "uint",0 )
         b%A_Index% := DllCall("CreateCursor","uint",0, "int",0, "int",0
            , "int",32, "int",32, "uint",&AndMask, "uint",&XorMask )
      }
   }
   if (OnOff = 0 or OnOff = "Off" or $ = "h" and (OnOff < 0 or OnOff = "Toggle" or OnOff = "T"))
      $ = b  ; use blank cursors
   else
      $ = h  ; use the saved cursors

   Loop %c0%
   {
      h_cursor := DllCall( "CopyImage", "uint",%$%%A_Index%, "uint",2, "int",0, "int",0, "uint",0 )
      DllCall( "SetSystemCursor", "uint",h_cursor, "uint",c%A_Index% )
   }
}
;******************************* 便捷搜索  *******************************
Google_Fuck_GFW(Engine)
{If Engine=INTL
{
	;run,http://www.google.com/search?hl=zh-CN&q=%clipboard%&oq=%clipboard%&aq=f&aqi=&aql=&gs_sm=e
	run,http://www.google.com/search?hl=zh-CN&inlang=zh-CN&q=%clipboard%&oq=%clipboard%&aq=f&aqi=&aql=&gs_sm=e
}
else
	run,http://www.google.com.hk/search?hl=zh-CN&q=%clipboard%&oq=%clipboard%&aq=f&aqi=&aql=&gs_sm=e
	;run,http://www.google.com.hk/search?hl=zh-CN&inlang=zh-CN&newwindow=1&ie=utf-8&oe=utf-8&q=%clipboard%

	sleep,2000
	WinGetTitle, CurTabTitle , A
	
	StringSplit, DividedPart, CurTabTitle , -
	KW=%DividedPart1%
	;;;;MsgBox,CurTabTitle=%CurTabTitle%  》》》》 KW=%DividedPart1%
	loop,20
	 {	 
	 sleep,1000
	 ;if (WinActive(%clipboard%))
	 ;msgbox,KW=%KW%   CurTabTitle=%CurTabTitle%
	 if (WinActive("无法显示") or WinActive("无法载入")or WinActive("页面载入出错")or WinActive("无法访问"))
	{
	run,http://www.baidu.com/s?wd=%clipboard%
	;MsgBox, 262192, don't be evil, Google Walled，Fucking Baidu ...`n`n请注意百度标注为“推广”的链接！谨防受骗！,10
	tooltip,Google 打不开，转向 Baidu ...
	SetTimer, RemoveToolTip, 5000
	break
	
	}
	else If(CurTabTitle=="Mozilla Firefox")
	{
	run,http://www.baidu.com/s?wd=%clipboard%
	;MsgBox, 262192, don't be evil, Google 好像牺牲了，暂时转向百度......`n`n请注意百度标注为“推广”的链接！谨防受骗！,10
	tooltip,Google 打不开，转向 Baidu ...
	SetTimer, RemoveToolTip, 5000
	break
	
	}
	IfInString,  CurTabTitle,%KW%
	{
	;msgbox,OK
	break
	}
	 
	 }
	 ;;;;End Loop tag
	
	;WinGetTitle, OutputVar222 , A
	;msgbox,%OutputVar222%
}
;******************************* 虚拟桌面  *******************************
; switch to the desktop with the given index number
SwitchToDesktop(newDesktop)
{
   global

	ifExist %A_ScriptDir%\icon\%newDesktop%.ico
		Menu TRAY, Icon, %A_ScriptDir%\icon\%newDesktop%.ico

   if (curDesktop <> newDesktop)
   {
      GetCurrentWindows(curDesktop)

      ;WinGet, windows%curDesktop%, List,,, Program Manager   ; get list of all visible windows

      ShowHideWindows(curDesktop, false)
      ShowHideWindows(newDesktop, true)

      curDesktop := newDesktop

      ;Send, {ALT DOWN}{TAB}{ALT UP}   ; activate the right window
   }
   
   WinClose, ahk_class SysShadow   
   ShowBanner("Desktop: " newDesktop)

   EmptyMem()
   return
}

; sends the given window from the current desktop to the given desktop
SendToDesktop(windowID, newDesktop)
{
   global
   RemoveWindowID(curDesktop, windowID)

   ; add window to destination desktop
   windows%newDesktop% += 1
   i := windows%newDesktop%

   windows%newDesktop%%i% := windowID
   
   WinHide, ahk_id %windowID%

   Send, {ALT DOWN}{TAB}{ALT UP}   ; activate the right window
}

; sends the currently active window to the given desktop
SendActiveToDesktop(newDesktop)
{
   global
   WinGet, id, ID, A
   if (newDesktop == curDesktop)
   {
	   return
   }
   SendToDesktop(id, newDesktop)
   EmptyMem()
}

; removes the given window id from the desktop <desktopIdx>
RemoveWindowID(desktopIdx, ID)
{
   global   
   Loop, % windows%desktopIdx%
   {
      if (windows%desktopIdx%%A_Index% = ID)
      {
         RemoveWindowID_byIndex(desktopIdx, A_Index)
         Break
      }
   }
}

; this removes the window id at index <ID_idx> from desktop number <desktopIdx>
RemoveWindowID_byIndex(desktopIdx, ID_idx)
{
   global
   Loop, % windows%desktopIdx% - ID_idx
   {
      idx1 := % A_Index + ID_idx - 1
      idx2 := % A_Index + ID_idx
      windows%desktopIdx%%idx1% := windows%desktopIdx%%idx2%
   }
   windows%desktopIdx% -= 1
}

; this builds a list of all currently visible windows in stores it in desktop <index>
GetCurrentWindows(index)
{
   global
   WinGet, windows%index%, List,,, Program Manager      ; get list of all visible windows
   removed_num=0
   ; now remove task bar "window" (is there a simpler way?)
   Loop, % windows%index%
   {
	   real_index=% A_Index-removed_num
      id := % windows%index%%real_index%

      WinGetClass, windowClass, ahk_id %id%

     
    ;去掉开始按钮、任务栏、桌面的id，使他们不隐藏 
      if windowClass =  Button     ; remove start Button window id
      {
         RemoveWindowID_byIndex(index, real_index)
		 removed_num+=1
      }
	  if windowClass = Shell_TrayWnd      ; remove task bar window id
      {
         RemoveWindowID_byIndex(index, real_index)
		 removed_num+=1
      } 
	  if windowClass = WorkerW      ; remove Desktop window id
      {
         RemoveWindowID_byIndex(index, real_index)
		 removed_num+=1
      } 
   }
 
}

; if show=true then shows windows of desktop %index%, otherwise hides them
ShowHideWindows(index, show)
{
   global

   Loop, % windows%index%
   {
      id := % windows%index%%A_Index%

      if show
         WinShow, ahk_id %id%
      else
         WinHide, ahk_id %id%
   }
}

ShowBanner(Text)
{
    global
    Trans := 255
    
    GuiControl, 2:Text, String, % Text
    Gui, 2:Show, x895 y677 h24 w92 NoActivate, MyTransparentBanner
    WinSet, Transparent, %Trans%, MyTransparentBanner
    Sleep 500
    
    Loop
    {
        if(Trans <= 0)
        {
            Trans := 0
            WinSet, Transparent, %Trans%, MyTransparentBanner
            break
        }
                
        WinSet, Transparent, %Trans%, MyTransparentBanner
        Trans := Trans - 5
        Sleep, 10
    }
    
    return
}
;;;;;;;;;HDDMonitor PCMeter;;;;;;;;;;;;;;;;;;;;;;;;;;;;


POPUPMENU(wParam, lParam)
{
    if (A_Gui == 12)
        Menu, HDDMonitor, Show
	if (A_Gui == 8 )
		Menu, PCMeter, Show
    Return 0
}
openWith(win_Class)
{
	global ExtList,SoftList
	; global GVIM,POTPLAYER,potplayerExtList,gvimExtList   ;SPLAYER
	is_open_success := 0
	If (win_Class = "WorkerW"  or win_Class = "CabinetWClass") 		
	{
		tempclip=%clipboard%
		send, ^c
		sleep 500
		Full_FileName=%clipboard%
		clipboard=%tempclip%
		SplitPath, Full_FileName, , , ext
		; 循环查看是否为中键打开功能支持的后缀，是则打开该文件
		loop % SoftList.maxindex()
		{
			if ext in % ExtList[A_Index]
			{
				cmd := SoftList[A_Index]
				run %cmd% "%Full_FileName%"
				; run % SoftList[A_Index] . " " . Full_FileName
				is_open_success := 1
				break
			}
		}
		if (is_open_success == 0)
		{
			tooltip, 不支持该类型文件
			SetTimer, RemoveToolTip, 2000
			return
		}
		; if (ext="txt" or ext="c" or ext= "cpp" or ext="html" or ext="ahk" or ext="sql")
		; if ext in %gvimExtList%
		; {
			; run %GVIM% "%Full_FileName%"
			; return
		; }
		; else if (ext="wmv" or ext="mp4" or ext="rm" or ext="rmvb" or ext="avi" or ext="mpg" or ext="flv" or ext="swf" or ext="mkv" or ext="mpg" or ext="mpeg")
		; else if ext in %potplayerExtList%
		; {
			; run %POTPLAYER% "%Full_FileName%"
			; return
		; }
		; else
		; {
			; tooltip, 不支持该类型文件
			; SetTimer, RemoveToolTip, 2000
			; return
		; }
	}
}
;******************************* function  *******************************}}}
SYS_ToolTipFeedback=1
BeforRemoveToolTip=
AutoShutdown_Run=0
AutoShutdown_Run_INI=0
win_hide_show_v=1
if_sleep_time=0
if_on_top=0

thundernum=0


;*******************************  read setting file  *******************************{{{
	
;#★★General★
IniRead, version, %A_ScriptDir%\%applicationname%.ini, General,version
IniRead, updatefile, %A_ScriptDir%\%applicationname%.ini, General,updatefile
IniRead, productpage, %A_ScriptDir%\%applicationname%.ini, General,productpage
IniRead, myblog, %A_ScriptDir%\%applicationname%.ini, General,blog


;#★★★快捷键开关★★★
IniRead, BlackList, %A_ScriptDir%\%applicationname%.ini, FnSwitch,BlackList
IniRead, Fn0113_V, %A_ScriptDir%\%applicationname%.ini, FnSwitch, Fn0113
IniRead, Fn0117_V, %A_ScriptDir%\%applicationname%.ini, FnSwitch, Fn0117
IniRead, Fn0118_V, %A_ScriptDir%\%applicationname%.ini, FnSwitch, Fn0118
IniRead, Fn0120_V, %A_ScriptDir%\%applicationname%.ini, FnSwitch, Fn0120
IniRead, Fn0122_V, %A_ScriptDir%\%applicationname%.ini, FnSwitch, Fn0122
IniRead, Fn0203_V, %A_ScriptDir%\%applicationname%.ini, FnSwitch, Fn0203
IniRead, Fn0204_V, %A_ScriptDir%\%applicationname%.ini, FnSwitch, Fn0204
IniRead, Fn0215_V, %A_ScriptDir%\%applicationname%.ini, FnSwitch, Fn0215
IniRead, Fn0301_V, %A_ScriptDir%\%applicationname%.ini, FnSwitch, Fn0301
IniRead, Fn0304_V, %A_ScriptDir%\%applicationname%.ini, FnSwitch, Fn0304
IniRead, Fn0310_V, %A_ScriptDir%\%applicationname%.ini, FnSwitch, Fn0310
IniRead, Fn0330_V, %A_ScriptDir%\%applicationname%.ini, FnSwitch, Fn0330
IniRead, Fn0333_V, %A_ScriptDir%\%applicationname%.ini, FnSwitch, Fn0333
IniRead, Fn0334_V, %A_ScriptDir%\%applicationname%.ini, FnSwitch, Fn0334
IniRead, Fn0335_V, %A_ScriptDir%\%applicationname%.ini, FnSwitch, Fn0335
IniRead, Fn0336_V, %A_ScriptDir%\%applicationname%.ini, FnSwitch, Fn0336
IniRead, Fn0338_V, %A_ScriptDir%\%applicationname%.ini, FnSwitch, Fn0338
IniRead, Fn0340_V, %A_ScriptDir%\%applicationname%.ini, FnSwitch, Fn0340
IniRead, Fn0555_V, %A_ScriptDir%\%applicationname%.ini, FnSwitch, Fn0555
IniRead, Fn0556_V, %A_ScriptDir%\%applicationname%.ini, FnSwitch, Fn0556
IniRead, Fn0557_V, %A_ScriptDir%\%applicationname%.ini, FnSwitch, Fn0557
IniRead, Fn0558_V, %A_ScriptDir%\%applicationname%.ini, FnSwitch, Fn0558
IniRead, Fn0559_V, %A_ScriptDir%\%applicationname%.ini, FnSwitch, Fn0559
IniRead, Fn0560_V, %A_ScriptDir%\%applicationname%.ini, FnSwitch, Fn0560
IniRead, Fn0561_V, %A_ScriptDir%\%applicationname%.ini, FnSwitch, Fn0561
IniRead, Fn0562_V, %A_ScriptDir%\%applicationname%.ini, FnSwitch, Fn0562
IniRead, Fn0563_V, %A_ScriptDir%\%applicationname%.ini, FnSwitch, Fn0563
IniRead, Fn0564_V, %A_ScriptDir%\%applicationname%.ini, FnSwitch, Fn0564
IniRead, Fn0565_V, %A_ScriptDir%\%applicationname%.ini, FnSwitch, Fn0565
IniRead, Fn0566_V, %A_ScriptDir%\%applicationname%.ini, FnSwitch, Fn0566
IniRead, Fn0567_V, %A_ScriptDir%\%applicationname%.ini, FnSwitch, Fn0567


;#★★Clipjump★
; Clipboard = 

If (FnSwitch(0565)=1)
{
IniRead,maxclips,%A_ScriptDir%\%applicationname%.ini,Clipjump,Minimum_No_Of_Clips_to_be_Active
IniRead,threshold,%A_ScriptDir%\%applicationname%.ini,Clipjump,Threshold
IniRead,ismessage,%A_ScriptDir%\%applicationname%.ini,Clipjump,Show_Copy_Message
IniRead,quality,%A_ScriptDir%\%applicationname%.ini,Clipjump,Quality_of_Thumbnail_Previews
IniRead,keepsession,%A_ScriptDir%\%applicationname%.ini,Clipjump,Keep_Session
IniRead,R_lf,%A_ScriptDir%\%applicationname%.ini,Clipjump,Remove_Ending_Linefeeds
Iniread,generalsleep,%A_ScriptDir%\%applicationname%.ini,Clipjump,Wait_Key
Iniread,lastclip,%A_ScriptDir%\cache\%applicationname%cache.txt,Clipjump,lastclip
}
; ScreenCapture
If (FnSwitch(0567)=1)
{
IfNotExist, %a_scriptdir%\%applicationname%.ini
{
	iniwrite,jpg,%a_scriptdir%\%applicationname%.ini,ScreenCapture,Extension_To_Save_in
	iniwrite,100,%a_scriptdir%\%applicationname%.ini,ScreenCapture,Quality_of_clips
	iniwrite,1,%a_scriptdir%\%applicationname%.ini,ScreenCapture,Action_After_Finish
	iniwrite,mspaint.exe,%a_scriptdir%\%applicationname%.ini,ScreenCapture,Open_Capture_Soft
	IniWrite,"" ,%a_scriptdir%\%applicationname%.ini,ScreenCapture,Capture_Directory
	iniwrite,PrintScreen,%a_scriptdir%\%applicationname%.ini,ScreenCapture,PrimaryKey
	IniWrite,LeftMousebutton,%a_scriptdir%\%applicationname%.ini,ScreenCapture,SecondaryKey
	IniWrite,CB2322,%a_scriptdir%\%applicationname%.ini,ScreenCapture,Color
}
;-----------------------CONFIGURE--------------------------------------------------------------------
IniRead,SC_CaptureExtension,%a_scriptdir%\%applicationname%.ini,ScreenCapture,Extension_To_Save_in
IniRead,SC_qualityofpic,%a_scriptdir%\%applicationname%.ini,ScreenCapture,Quality_of_clips
IniRead,SC_actionafterfinish,%a_scriptdir%\%applicationname%.ini,ScreenCapture,Action_After_Finish
IniRead,SC_openCaptureSoft,%a_scriptdir%\%applicationname%.ini,ScreenCapture,Open_Capture_Soft
IniRead,SC_CaptureDir,%a_scriptdir%\%applicationname%.ini,ScreenCapture,Capture_Directory
IniRead,SC_PrimaryHotkey,%a_scriptdir%\%applicationname%.ini,ScreenCapture,PrimaryKey
IniRead,SC_SecondaryHotkey,%a_scriptdir%\%applicationname%.ini,ScreenCapture,SecondaryKey
IniRead,SC_CaptureGuiColor,%a_scriptdir%\%applicationname%.ini,ScreenCapture,Color

if SC_CaptureDir = 
	SC_CaptureDir = %a_scriptdir%\cache\Captures
splitpath, SC_CaptureDir,SC_captureDirName

IfEqual,SC_actionafterfinish,0
	SC_actionafterfinish := 
else
	SC_actionafterfinish := True

SC_PrimaryHotkey := (HParse(SC_PrimaryHotkey) == "") ? ("PrintScreen") : (Hparse(SC_PrimaryHotkey))
SC_SecondaryHotkey := (HParse(SC_SecondaryHotkey) == "") ? ("LButton") : (Hparse(SC_SecondaryHotkey))
}
;#★★★鼠标手势★★★
IniRead, IE_Gesture_Back, %A_ScriptDir%\%applicationname%.ini, Gesture,IE_Gesture_Back
IniRead, IE_Gesture_Forward, %A_ScriptDir%\%applicationname%.ini, Gesture,IE_Gesture_Forward
IniRead, IE_Gesture_Refresh, %A_ScriptDir%\%applicationname%.ini, Gesture,IE_Gesture_Refresh
IniRead, IE_Gesture_Stop, %A_ScriptDir%\%applicationname%.ini, Gesture,IE_Gesture_Stop
IniRead, IE_Gesture_PreTab, %A_ScriptDir%\%applicationname%.ini, Gesture,IE_Gesture_PreTab
IniRead, IE_Gesture_NextTab, %A_ScriptDir%\%applicationname%.ini, Gesture,IE_Gesture_NextTab
IniRead, IE_Gesture_CloseTab, %A_ScriptDir%\%applicationname%.ini, Gesture,IE_Gesture_CloseTab
IniRead, IE_Gesture_UndoTab, %A_ScriptDir%\%applicationname%.ini, Gesture,IE_Gesture_UndoTab
IniRead, IE_Gesture_NewTab, %A_ScriptDir%\%applicationname%.ini, Gesture,IE_Gesture_NewTab
IniRead, IE_Gesture_PageHome, %A_ScriptDir%\%applicationname%.ini, Gesture,IE_Gesture_PageHome
IniRead, IE_Gesture_PageEnd, %A_ScriptDir%\%applicationname%.ini, Gesture,IE_Gesture_PageEnd

IniRead, Ex_Gesture_Copy, %A_ScriptDir%\%applicationname%.ini, Gesture,Ex_Gesture_Copy
IniRead, Ex_Gesture_Paste, %A_ScriptDir%\%applicationname%.ini, Gesture,Ex_Gesture_Paste
IniRead, Ex_Gesture_Cute, %A_ScriptDir%\%applicationname%.ini, Gesture,Ex_Gesture_Cute
IniRead, Ex_Gesture_Del, %A_ScriptDir%\%applicationname%.ini, Gesture,Ex_Gesture_Del
IniRead, Ex_Gesture_DelInst, %A_ScriptDir%\%applicationname%.ini, Gesture,Ex_Gesture_DelInst
IniRead, Ex_Gesture_Pro, %A_ScriptDir%\%applicationname%.ini, Gesture,Ex_Gesture_Pro
IniRead, Ex_Gesture_Back, %A_ScriptDir%\%applicationname%.ini, Gesture,Ex_Gesture_Back
IniRead, Ex_Gesture_Fwd, %A_ScriptDir%\%applicationname%.ini, Gesture,Ex_Gesture_Fwd
IniRead, Ex_Gesture_Upper, %A_ScriptDir%\%applicationname%.ini, Gesture,Ex_Gesture_Upper
IniRead, Ex_Gesture_Close, %A_ScriptDir%\%applicationname%.ini, Gesture,Ex_Gesture_Close
IniRead, Ex_Gesture_Undo, %A_ScriptDir%\%applicationname%.ini, Gesture,Ex_Gesture_Undo

IniRead, PH_Gesture_Back, %A_ScriptDir%\%applicationname%.ini, Gesture,PH_Gesture_Back
IniRead, PH_Gesture_Fwd, %A_ScriptDir%\%applicationname%.ini, Gesture,PH_Gesture_Fwd
;#★★★用户参数设置★★★

IniRead, Vol_Morning, %A_ScriptDir%\%applicationname%.ini, UserSetting,Vol_Morning
IniRead, Vol_Night, %A_ScriptDir%\%applicationname%.ini, UserSetting,Vol_Night
IniRead, Vol_Max, %A_ScriptDir%\%applicationname%.ini, UserSetting,Vol_Max
IniRead, Vol_Home, %A_ScriptDir%\%applicationname%.ini, UserSetting, Vol_Home
IniRead, SEID, %A_ScriptDir%\%applicationname%.ini, UserSetting,SearchEngine_F3
IniRead, SEID2, %A_ScriptDir%\%applicationname%.ini, UserSetting,SearchEngine_Shift_F3
IniRead,InstantMinimizeWindow_V,%A_ScriptDir%\%applicationname%.ini,UserSetting,InstantMinimizeWindow
IniRead, AutoShutdownTime, %A_ScriptDir%\%applicationname%.ini,UserSetting,AutoShutdownTime
	If AutoShutdownTime<>
	{
	 IfInString, AutoShutdownTime, :
		{
			StringSplit, as_time, AutoShutdownTime, `:,%A_Space%
			GoSub,as_time_format_AutoRun
			
		}
	else IfInString, AutoShutdownTime, ：
		{
			StringSplit, as_time, AutoShutdownTime, `：,%A_Space%
			GoSub,as_time_format_AutoRun	
			
		}
	else
		{
		AutoShutdown_Run_INI=0
	MsgBox, 262160, WINAssist 定时关机 输入有误, 您输入的定时关机时间格式错误：`nAutoShutdownTime=%AutoShutdownTime%`n`n请重新设置，正确的格式有：`nAutoShutdownTime=6:05`nAutoShutdownTime=23:45`n`n取消自动关机请留空，即`nAutoShutdownTime=
	;GoSub,OpenINI
	;sleep,2000
	
			Send, {CTRLDOWN}f{CTRLUP}
			sleep,200
			SendInput {Raw}AutoShutdownTime
			sleep,300
			Send, {Enter}
			;Send, {Tab 4}{Enter}
		}
	
	}
;;;THE END of If AutoShutdownTime
IniRead, TransparentList, %A_ScriptDir%\%applicationname%.ini, UserSetting,TransparentList
IniRead, TransparentValue, %A_ScriptDir%\%applicationname%.ini, UserSetting,TransparentValue
;msgbox,BlackList=%BlackList%
IniRead, WheelList, %A_ScriptDir%\%applicationname%.ini, UserSetting,WheelList
;WheelListInside=Flip3D,Photo_Lightweight_Viewer,OpusApp,XLMAIN,%WheelList%
IniRead, WheelSpeed, %A_ScriptDir%\%applicationname%.ini, UserSetting,WheelSpeed

; screenlock 白领们的小助手：老板键、视力保护、锁屏三合一软件
IniRead, idle, %A_ScriptDir%\%applicationname%.ini, lock, idle, 10
IniRead, key, %A_ScriptDir%\%applicationname%.ini, lock, key, appinn
IniRead, interface, %A_ScriptDir%\%applicationname%.ini, lock, interface, 1
IniRead, direct_lock, %A_ScriptDir%\%applicationname%.ini, lock, direct_lock, 0
IniRead, if_turnoff_monitor, %A_ScriptDir%\%applicationname%.ini, lock, if_turnoff_monitor, 0
IniRead, if_mute, %A_ScriptDir%\%applicationname%.ini, lock, if_mute, 0
IniRead, if_fullscreen, %A_ScriptDir%\%applicationname%.ini, lock, if_fullscreen, 0
IniRead, worktime, %A_ScriptDir%\%applicationname%.ini, lock, worktime, 45    ;工作45分钟后强制休息
IniRead, relaxtime, %A_ScriptDir%\%applicationname%.ini, lock, relaxtime, 3       ;眼睛放松时间或者叫强制休息时间
IniRead, hidewindow, %A_ScriptDir%\%applicationname%.ini, lock, hidewindow
IniRead, hotkey,%a_scriptdir%\%applicationname%.ini, lock, hotkey, #k
IniRead, language,%a_scriptdir%\%applicationname%.ini, lock, language, 0

;读取任务列表
/*
IniRead, todolist_0, %A_ScriptDir%\%applicationname%.ini, todolist, todolist_0
IniRead, todolist_1, %A_ScriptDir%\%applicationname%.ini, todolist, todolist_1
IniRead, todolist_2, %A_ScriptDir%\%applicationname%.ini, todolist, todolist_2
IniRead, todolist_3, %A_ScriptDir%\%applicationname%.ini, todolist, todolist_3
IniRead, todolist_4, %A_ScriptDir%\%applicationname%.ini, todolist, todolist_4
IniRead, todolist_5, %A_ScriptDir%\%applicationname%.ini, todolist, todolist_5
IniRead, todolist_6, %A_ScriptDir%\%applicationname%.ini, todolist, todolist_6
IniRead, todolist_7, %A_ScriptDir%\%applicationname%.ini, todolist, todolist_7
IniRead, todolist_8, %A_ScriptDir%\%applicationname%.ini, todolist, todolist_8
IniRead, todolist_9, %A_ScriptDir%\%applicationname%.ini, todolist, todolist_9
*/
;*******************************  read setting file  *******************************}}}
;--------------------------------------------------------
InToDolist = 0
Full_todolist = 
Loop, Read, %A_ScriptDir%\%applicationname%.ini
{
   if A_LoopReadLine =   ; skip blank lines
      continue
   StringLeft, A_LoopReadLineFirstChar, A_LoopReadLine, 1   ; Skip comments
   if A_LoopReadLineFirstChar = `;
      continue
   if InToDolist = 0
   {
      IfInString, A_LoopReadLine, [todolist]   ; Favorites section start
         InToDolist = 1
      else
         continue   ; Start a new loop iteration.
   }
   else if InToDolist = 1
   {
      if A_LoopReadLineFirstChar = [   ; Another section start
         Break
	  ;Full_todolist +=%A_LoopReadLine%`n 
	  Full_todolist:= Full_todolist . A_LoopReadLine . "`n"
   }
}

GroupAdd, WinGroup, ahk_class Progman ;桌面
GroupAdd, WinGroup, ahk_class WorkerW ;桌面
GroupAdd, WinGroup, ahk_class ExploreWClass ;我的电脑
GroupAdd, WinGroup, ahk_class CabinetWClass  ;我的电脑


;迅雷、快车、旋风地址转换为普通地址
Chars=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/
;screenlock 白领们的小助手：老板键、视力保护、锁屏三合一软件
starttime:=A_now   ;记录工作开始时间
temptime:=starttime
temptime+=worktime,Minutes
formattime,showtime,%temptime%,time
menutipshow=%Full_todolist%电脑将在%showtime%强制休息
menu,tray,Tip,%menutipshow%  ;鼠标经过图标时将显示休息时间
temptime+=-1,Minutes
if (FnSwitch(0558)=1)
	Hotkey, %hotkey%, start, On               ;Turn on the hotkey.
if (FnSwitch(0559)=1)
	Hotkey, ^!h, win_hide_show, On
;Hotkey, ^!s, myshow, On
Gosub, setLang

SetTimer,CheckIdle,60000

	
Gosub, makeMenu
; 开机启动
IfExist,%a_startup%/WINAssist.lnk
{
FileDelete,%a_startup%/WINAssist.lnk
FileCreateShortcut,%A_ScriptFullPath%,%A_Startup%/WINAssist.lnk,%a_scriptdir%/
Menu,more,Check,开机启动
}
if ( direct_lock = 1 )
{
   Gosub, start
}


; Clipjump begin

If (FnSwitch(0565)=1)
{
IfEqual,maxclips
	maxclips = 9999999
if maxclips is not integer
	maxclips = 20
If threshold is not integer
	threshold = 10
IfEqual,ismessage,0
	CopyMessage = 
else
	CopyMessage = Transfered to ClipJump
If quality is not Integer
	quality = 20
if keepsession is not integer
	keepsession = 1
if (R_lf == 0)
	R_lf := false
else
	R_lf := true

if generalsleep is not Integer
	generalsleep := 200

IfLess,generalsleep,200
	generalsleep := 200

IfEqual,keepsession,0
	gosub, cleardata

totalclips := Threshold + maxclips

loop,
{
IfNotExist,%A_ScriptDir%/cache/Clips/%a_index%.avc
{
	cursave := a_index - 1
	tempsave := cursave
	break
}
}

; Gui
Gui, 15: +LastFound +AlwaysOnTop -Caption +ToolWindow
gui, 15: add, picture,x0 y0 w400 h300 vimagepreview,

FileCreateDir,%A_ScriptDir%/cache
FileCreateDir,%A_ScriptDir%/cache/clips
FileCreateDir,%A_ScriptDir%/cache/thumbs
FileCreateDir,%A_ScriptDir%/cache/fixate
FileSetAttrib,+H,%a_scriptdir%\cache

scrnhgt := A_ScreenHeight / 2.5
scrnwdt := A_ScreenWidth / 2

caller := true
in_back := false

Hotkey,$^v,Paste,On
Hotkey,$^c,NativeCopy,On
Hotkey,$^x,NativeCut,On
Hotkey,^!c,CopyFile,On
Hotkey,^!x,CopyFolder,On
}
; Clipjump end

; ScreenCapture
If (FnSwitch(0567)=1){
	Hotkey,%SC_PrimaryHotkey%,capture,On
}

;虚拟桌面
; ***** initialization *****
SetBatchLines, -1   ; maximize script speed!
SetWinDelay, -1
OnExit, CleanUp      ; clean up in case of error (otherwise some windows will get lost)

numDesktops := 4   ; maximum number of desktops
curDesktop := 1      ; index number of current desktop

WinGet, windows1, List   ; get list of all currently visible windows

; Transparent Banner GUI
Gui, 2:-Caption +ToolWindow +LastFound +AlwaysOnTop
Gui, 2:Add, Picture, x0 y0, d:\Program Files\Autohotkey\Scripts\banner.png
Gui, 2:Add, Text, x15 y5 w70 +BackgroundTrans vString

; WeatherForecast 天气预报
FormatTime, today, , dddd 
weeks := Object(0,"星期日",1,"星期一",2,"星期二",3,"星期三",4,"星期四",5,"星期五",6,"星期六")
for WF_key in weeks
{
	; key 为 today 在 weeks 中的 index
	if (weeks[WF_key] == today)
		break
}

weatherInfoUpdate := 0
initWeatherInfo := 0
Gosub weatherINIREAD

; Shows clock, batterypower, mem load and cpu load on top of screen
; PCMeter
if(FnSwitch(0566)=1)
{
Gosub, INIREAD

windowTitle := "PCMeter"

regionMargin := 10
progressBarPos := regionMargin - 1

; I tried to make as much as possible configurable in the ini file, so we need some calculations.
clockFontStyle = s%fontsize% bold
infoFontStyle = s%infoFontSize% bold

FormatTime, clockText ,, %timeFormat%
clockWidth := GetTextSize(clockText, clockFontStyle "," clockFont )+10

battText1 = xx
battText2 := "100%"
battWidth := GetTextSize(battText1, infoFontStyle "," Webdings )+10
battWidth += GetTextSize(battText2, infoFontStyle "," infoFont )+10

memText := memLabel . "100%"
memWidth := GetTextSize(memText, infoFontStyle "," infoFont )+10

cpuText := cpuLabel . "100.00%"
cpuWidth := GetTextSize(cpuText, infoFontStyle "," infoFont )+10

maxWidth := Max(battWidth, Max(memWidth, cpuWidth))
; Use the widest width for all
battWidth := maxWidth
cpuWidth := maxWidth
memWidth := maxWidth

battProgressWidth := battWidth + 1
memProgressWidth := memWidth + 1
cpuProgressWidth := cpuWidth + 1

height := fontSize + (fontsize * 0.7)
infoHeight := infoFontSize + (fontsize * 0.7)
txtY := 0
txtX := 15
posFromRight = 120

battInfo := GetPowerStatus(acLineStatus)

VarSetCapacity( IdleTicks, 2*4 )
VarSetCapacity( memstatus, 100 )

; OnExit, ExitSub

Gosub, CALCULATEPOSITIONS
Gosub, CREATECLOCKWINDOW
OnMessage(0x200, "WM_MOUSEMOVE")
if %showPCMeter% 
{
SetTimer, UPDATECLOCK, 1000
SetTimer, UPDATEBATTERY, 2000
SetTimer, UPDATECPU, 1500
SetTimer, WATCHCURSOR, 115
SetTimer, KEEPONTOP, 1000
}
}
;HDDMonitor
if(FnSwitch(0564)=1)
{
if (FileExist("paused.ico"))
    Menu, tray, Icon, paused.ico
else
    Menu, tray, Icon
lasticonname = ----


inifile = %A_ScriptDir%\%applicationname%.ini

GoSub, LoadSettings

if (! FileExist(inifile))
{
    IniWrite, %period%,           %A_ScriptDir%\%applicationname%.ini, HDDMSetting, Period
    IniWrite, %preferreddrvs%,    %A_ScriptDir%\%applicationname%.ini, HDDMSetting, PreferredDrives
    IniWrite, %includeremovable%, %A_ScriptDir%\%applicationname%.ini, HDDMSetting, IncludeRemovable
    IniWrite, %fontcolor%,        %A_ScriptDir%\%applicationname%.ini, HDDMSetting, FontColor
    IniWrite, %backgroundcolor%,  %A_ScriptDir%\%applicationname%.ini, HDDMSetting, BackgroundColor
    IniWrite, %barsbkgcolor%,     %A_ScriptDir%\%applicationname%.ini, HDDMSetting, BarsBkgColor
    IniWrite, %barswidth%,        %A_ScriptDir%\%applicationname%.ini, HDDMSetting, BarsWidth
    IniWrite, %barsheight%,       %A_ScriptDir%\%applicationname%.ini, HDDMSetting, BarsHeight
    IniWrite, %keyboardclassnum%, %A_ScriptDir%\%applicationname%.ini, HDDMSetting, KeyboardClassNum
}


; define the tray icon (Later, only the color map is changed)

IconDataTemplateHex =
( join
2800000010000000
2000000001000400
00000000C0000000
0000000000000000
0000000000000000

00000000
22222200
55555500
88888800

00000000
22222200
55555500
88888800

00000000
22222200
55555500
88888800

00000000
22222200
55555500
88888800

88899888CCCDDCCC
89AAAA98CDEEEEDC
8AABBAA8CEEFFEEC
9ABBBBA9DEFFFFED
9ABBBBA9DEFFFFED
8AABBAA8CEEFFEEC
89AAAA98CDEEEEDC
88899888CCCDDCCC

0001100044455444
0122221045666654
0223322046677664
1233332156777765
1233332156777765
0223322046677664
0122221045666654
0001100044455444

0000000000000000
0000000000000000
0000000000000000
0000000000000000
0000000000000000
0000000000000000
0000000000000000
0000000000000000
)

VarSetCapacity( IconData, 296 )
Loop 296
    NumPut( "0x" . SubStr(IconDataTemplateHex,2*A_Index-1,2), IconData, A_Index-1, "Char" )
IconDataTemplateHex := ""

; The 4 parts of the icon's color map are assigned dynamically in different order
; to change the color of each led independently
; No disc activity (grey)
IconDataNHex = 00000000222222005555550088888800
; Read operation only (green)
IconDataRHex = 003300000088000000BB000000EE0000
; Write operation only (red)
IconDataWHex = 00004400000099000000CC000000FF00
; Read and write operations (yellow)
IconDataBHex = 003333000088880000BBBB0000EEEE00
; Unused led (blue)
IconDataUHex = 3000000070000000B0000000F0000000

; initialize the icon structure
InitHIconStruct()


OnExit, CleanExit

GoSub, GetDrivesList

GoSub, OpenBlinkLedHandle

Process, Priority,, High
SetTimer, HDD_Monitor, %period%

OnMessage(0x205, "POPUPMENU")
}


EmptyMem()
; optimize memory
return

!0::ExitApp
!*0::reload
!+1::suspend toggle

;******************************* Tray Menu *******************************{{{
makeMenu:
SetWorkingDir, %A_ScriptDir% 
;切换工作目录
if(FnSwitch(0564)=0)
ifexist,icon\1.ico
{
menu,tray,icon, icon\1.ico
}


;menu, tray, Tip, WINAssist Ver 1.01
Menu, tray, NoStandard
Menu, Tray, Click, 1
Menu, Tray, Show
Menu, Tray, Add, WINAssist, Tray_Show ;和下面一句能使左键显示菜单
Menu, Tray, Default, WINAssist
Menu, Tray, ToggleEnable, WINAssist
Menu, tray, add ; 创建分割线。
Gosub, f_ReadFavorites
;子菜单
If (FnSwitch(0557)=1)
Menu, tool, Add, 链接转换, Convert_Address
If (FnSwitch(0333)=1)
Menu, tool, Add, 定时关机, start_shutdown
Menu, tray, Add, 功能, :tool  ;必须在后
gosub,makescreenlockmenu
GoSub makeWeatherMenu

If (FnSwitch(0565)=1)
{
GoSub makeClipJumpMenu
}
If (FnSwitch(0567)=1)
{
GoSub makeScreenCaptureMenu
}
;子菜单
Menu, tray, add ; 创建分割线。
Menu, more, add, 编辑脚本, edit_script
Menu, more, add, 编辑配置文件, edit_config
; Menu, Tray, Add, 编辑(&E), :AHK_Edit
Menu, more, add, 帮助(&H), installationopen
Menu, more, Add, 更新(&U), update
Menu, more, add, 关于(&A), About
Menu,more,Add,开机启动,startup
Menu, tray, add, 更多, :more
Menu, Tray, Add, 重启(&R), Tray_Reload
Menu, tray, add, 退出(&X), exitIT
return

edit_config:
run %A_ScriptDir%\%applicationname%.ini 
Return

edit_script:
run %GVIM% "%A_ScriptDir%\WINAssist.ahk" 
return 

f_ReadFavorites:
trayItemPos = 1  
InFavSection = 0   ; check if in the favorites section
Loop, Read, %A_ScriptDir%\%applicationname%.ini
{
   if A_LoopReadLine =   ; skip blank lines
      continue
   StringLeft, A_LoopReadLineFirstChar, A_LoopReadLine, 1   ; Skip comments
   if A_LoopReadLineFirstChar = `;
      continue
   if InFavSection = 0
   {
      IfInString, A_LoopReadLine, [Favorites]   ; Favorites section start
         InFavSection = 1
      else
         continue   ; Start a new loop iteration.
   }
   else if InFavSection = 1
   {
      if A_LoopReadLineFirstChar = [   ; Another section start
         Break
      f_CreateFavorite("tray", A_LoopReadLine, A_LoopReadLineFirstChar, trayItemPos)
   }
}
menu, tray, Add
return

f_OpenFavorite:
; Fetch the array element that corresponds to the selected menu item:
if A_ThisMenu = Tray
	menurealitempos:=A_ThisMenuItemPos-2
else
	menurealitempos:=a_thismenuitempos

SplitPath, f_OpenFavPath, , f_OutDir, , , 
StringTrimLeft, f_OpenFavPath, i_%A_ThisMenu%_%menurealitempos%_Path, 0
SetWorkingDir, %f_OutDir%
Run, %f_OpenFavPath%, , UseErrorLevel   ;open a file if the path is not a dir
if ErrorLevel
  TrayTip, Error, Could not open `n%f_OpenFavPath%`nThere's something wrong with your config file., , 3
return

makescreenlockmenu:
if (FnSwitch(0558)=1)
{
	Menu, screenlock, Add, %L_lock%, start
	Menu, screenlock, Default, %L_lock%
	Menu, setting, Add, %L_password%, setPassword
	Menu, setting, Add, %L_autolock%, setAutoLock
	Menu, setting, Add, %L_hotkey%, changeHotkey
	Menu, setting, Add
	Menu, setting, Add, %L_direct_lock%, setDirectLock
	if ( direct_lock = 1 )
	{
	  Menu, setting, Check, %L_direct_lock%
	}
	else
	{
	  Menu, setting, UnCheck, %L_direct_lock%
	}
	Menu, screenlock, Add, %L_setting%, :setting
	menu, interface, Add, %L_interface1%, interface1
	menu, interface, Add, %L_interface2%, interface2
	menu, interface, Add, %L_interface3%, interface3
	Menu, interface, Add
	Menu, interface, Add, %L_fullscreen%, setFullscreen
	if ( if_fullscreen = 1 )
	{
	  Menu, interface, Check, %L_fullscreen%
	}
	else
	{
	  Menu, interface, UnCheck, %L_fullscreen%
	}
	Menu, interface, Add, %L_screenoff%, setTurnoffMonitor
	if ( if_turnoff_monitor = 1 )
	{
	  Menu, interface, Check, %L_screenoff%
	}
	else
	{
	  Menu, interface, UnCheck, %L_screenoff%
	}
	Menu, interface, Add, %L_mute%, setMute
	if ( if_mute = 1 )
	{
	  Menu, interface, Check, %L_mute%
	}
	else
	{
	  Menu, interface, UnCheck, %L_mute%
	}
	menu, interface, UnCheck, %L_interface1%
	menu, interface, UnCheck, %L_interface2%
	menu, interface, UnCheck, %L_interface3%
	if ( interface = 1 )
	  menu, interface, Check, %L_interface1%
	else if ( interface = 2 )
	  menu, interface, Check, %L_interface2%
	else if ( interface = 3 )
	  menu, interface, Check, %L_interface3%

	Menu, screenlock, Add, %L_interface%, :interface
	Menu, tray, Add, screenlock, :screenlock
	Menu, tray, Icon, screenlock, icon\lock.ico,, 15
}
if(FnSwitch(0560)=1)
{
	Menu, DesktopSwitch, add, CleanUp,showalldesktops
	Menu, DesktopSwitch, Add, 桌面1, SwitchToDesktop1
	Menu, DesktopSwitch, Add, 桌面2, SwitchToDesktop2
	Menu, DesktopSwitch, Add, 桌面3, SwitchToDesktop3
	Menu, DesktopSwitch, Add, 桌面4, SwitchToDesktop4
	Menu, tray, Add, 虚拟桌面, :DesktopSwitch  
}

if(FnSwitch(0564)=1)
{
	Menu, HDDMonitor, Add,     Info Window,  ToggleInfo
	Menu, HDDMonitor, Default, Info Window
	Menu, HDDMonitor, Add, Always On Top,    ToggleAlwaysOnTop
	Menu, HDDMonitor, Add, Transparent bars, ToggleTransparent
	Menu, HDDMonitor, Add
	Menu, Blink, Add, None,        BlinkNone
	Menu, Blink, Add, Scroll Lock, BlinkScrollLock
	Menu, Blink, Add, Num Lock,    BlinkNumLock
	Menu, Blink, Add, Caps Lock,   BlinkCapsLock
	Menu, HDDMonitor, Add, Blink Keyboard Led, :Blink
	Menu, HDDMonitor, Add
	Menu, HDDMonitor, Add, Edit settings,    EditSettings
	Menu, HDDMonitor, Add
	Menu, HDDMonitor, Add, Rescan drives,    GetDrivesList
	Menu, HDDMonitor, Add, Pause,            TogglePause
	Menu,tray , add, HDDMonitor, :HDDMonitor
}
if(FnSwitch(0566)=1)
{
	Menu, PCMeter, Add,show Window,  TogglePCMeter
	Menu, tray, add, PCMeter, :PCMeter
}
return


makeClipJumpMenu:
Menu, ClipJump, Add, 清空缓存, cleardata
menu, tray , add , 剪贴板,:ClipJump
return
 
Tray_Show:
Menu, Tray, Show
return

exitIT:
ExitApp 
return

Tray_Reload:
If (FnSwitch(0565)=1)
{
IniWrite,%lastclip%,%A_ScriptDir%\cache\%applicationname%cache.txt,Clipjump,lastclip
}
Reload
Return

About:
Gui, 16:Font, S18 CRed, Consolas
Gui, 16:Add, Text, x2 y0 w550 h40 +Center gupdate, WINAssist v%version%
Gui, 16:Font, S14 CBlue, Verdana
Gui, 16:Add, Text, x2 y40 w550 h30 +Center gblog, howiefh
Gui, 16:Font, S16 CBlack, Verdana
Gui, 16:Font, S14 CBlack, Verdana
Gui, 16:Add, Text, x2 y70 w550 h30 +Center, Assist for Windows
Gui, 16:Font, S14 CBlack, Verdana
Gui, 16:Font, S14 CRed, Verdana
Gui, 16:Add, Text, x2 y120 w100 h30 , Thanks
Gui, 16:Font, S14 CBlue Bold,Consolas
Gui, 16:Add, Text, x2 y150 w550 h90 , Song Ruihua for his HK4WIN.`nAvi Aryan for his ClipJump.`n
Gui, 16:Font, S14 CBlack Bold, Verdana
Gui, 16:Add, Text, x2 y260 w300 h30 ginstallationopen, Open Offline Help
Gui, 16:Font, S14 CBlack, Verdana
Gui, 16:Add, Text, x-8 y330 w560 h24 +Center, Copyright (C) 2013
Gui, 16:Show, x416 y126 h354 w557, WINAssist v%version%
return

startup:
Menu,more,Togglecheck,开机启动
IfExist, %a_startup%/WINAssist.lnk
	FileDelete,%a_startup%/WINAssist.lnk
else
	FileCreateShortcut,%A_ScriptFullPath%,%A_Startup%/WINAssist.lnk, %a_scriptdir%/
return

update:
URLDownloadToFile,%updatefile%,%a_scriptdir%/cache/latestversion.txt
FileReadLine,latestversion,%a_scriptdir%/cache/latestversion.txt,1
IfGreater,latestversion,%version%
{
MsgBox, 48, Update Avaiable, Your Version = %version%         `nCurrent Version = %latestversion%       `n`nGo to Website
IfMsgBox OK
{
	run, %productpage%
}
}
else
	MsgBox, 64, WINAssist, No Updates Available
return

installationopen:
run, %a_scriptdir%/help.htm
return

blog:
IfExist, %a_programfiles%/Internet Explorer/iexplore.exe
	run, iexplore.exe %myblog%
else
	run, %myblog%
return

16GuiEscape:
16GuiClose:
Gui, 16:hide
EmptyMem()
return

;虚拟桌面
SwitchToDesktop1:
SwitchToDesktop(1)
return
SwitchToDesktop2: 
SwitchToDesktop(2)
return
SwitchToDesktop3:
SwitchToDesktop(3)
return
SwitchToDesktop4: 
SwitchToDesktop(4)
return
;******************************* Tray Menu *******************************}}}

;=================== 公共标签 ===================
;清除提示
RemoveToolTip:
SetTimer, RemoveToolTip, Off
If (BeforRemoveToolTip<>"")
{
ToolTip,%BeforRemoveToolTip%
sleep,1000
BeforRemoveToolTip=
}
ToolTip
return
;获取光标下方窗口信息
GetInfoUnderMouse:
{
	MouseGetPos,x,y,MouseID,MouseControl
	WinGetClass,MouseClass,ahk_id %MouseID%
	WinGetClass,ActClass,A
	WinGet,ActID,ID,A
	controlget,childHWND,Hwnd,,%MouseControl%,ahk_id %MouseID%

}
return
;; 移动gui
GuiMove:
    PostMessage, 0xA1, 2,,, A
Return
;=================== 公共标签 ===================
;=================== 快捷键以其他方式打开文件 ===================
$^o::
	MouseGetPos,mouse_X,mouse_Y,win_UID,win_ClassNN ;获取指针下窗口的 UID 和 ClassNN以及鼠标指针全屏坐标
	WinGetClass,win_Class,ahk_id %win_UID% ;根据 UID 获得窗口类名
	openWith(win_Class)
return
;=================== 快捷键以其他方式打开文件 ===================

;===================打开截图工具===================
^!z:: 
run %screenCaptureSoft%
return
;===================打开截图工具=================== 
/*
;===================透明度调整=================== ;
#If (FnSwitch(0339)="1")
~LShift & WheelUp:: 
; 透明度调整
WinGet, Transparent, Transparent,A	
If (Transparent="") 
	Transparent=255 
Transparent_New:=Transparent+10 
;msgbox,Transparent_New=%Transparent_New% 
If (Transparent_New > 254)
	Transparent_New =255 
	
WinSet,Transparent,%Transparent_New%,A 
return 
	
~LShift & WheelDown:: 
WinGet, Transparent, Transparent,A 
If (Transparent="") 
	Transparent=255 
Transparent_New:=Transparent-10 
;msgbox,Transparent_New=%Transparent_New% 
If (Transparent_New < 30) 
	Transparent_New = 30 
WinSet,Transparent,%Transparent_New%,A 
EmptyMem()
return 
#If
;;;;;The end #IF tag of FnSwitch 0339
;===================透明度调整=================== ;
*/	
;HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH   隐藏文件   开始   HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH 
;任何时候只允许有三种状态
;1.系统文件和隐藏文件都显示
;2.系统文件和隐藏文件都不显示
;3.系统文件不显示、隐藏文件显示
;显示隐藏 系统文件、隐藏文件 
#If (FnSwitch(0120)=1)
$^h:: 
	KeyWait,LWin 
	KeyWait,RWin 
	;BY_F5=0 
	SUPER_SHOW=0 
	Gosub, HIDE_SHOW_REG_CHECK 
	EmptyMem()
	return 

;显示隐藏 隐藏文件 
$#^h:: 
	KeyWait,LWin 
	KeyWait,RWin 
	;BY_F5=0 
	SUPER_SHOW=1 
	Gosub, HIDE_SHOW_REG_CHECK 
	EmptyMem()
	return 
#If
;;;;;The end #IF tag of FnSwitch 0120
	
HIDE_SHOW_REG_CHECK: 
;if (WinActive("ahk_class CabinetWClass") or WinActive("ahk_class ExploreWClass")) 
If WinActive("ahk_group WinGroup")
{ 
	RegRead, HIDDEN_REG_1, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced, Hidden 
	;if (SUPER_SHOW=1) 
	RegRead, HIDDEN_REG_2, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced, ShowSuperHidden 
	;系统文件和隐藏文件都显示时 
	if (HIDDEN_REG_1="1" and HIDDEN_REG_2="1") 
	{ 
		SUPER_SHOW=1 
		Gosub, HIDE_FILES 
	} 
	;系统文件不显示、隐藏文件显示，并且ctrl h时，此时应该显示系统文件 
	else if  (HIDDEN_REG_1="1" and HIDDEN_REG_2="0" and SUPER_SHOW=1) 
	{ 
		Gosub, SHOW_FILES 
	} 
	;系统文件不显示、隐藏文件显示，并且win ctrl h时，此时应该不显示隐藏文件 
	else if  (HIDDEN_REG_1="1" and HIDDEN_REG_2="0" and SUPER_SHOW=0) 
	{ 
		Gosub, HIDE_FILES 
	} 
	;系统文件和隐藏文件都不显示,并且ctrl h时，此时应该显示系统文件、隐藏文件 
	;系统文件和隐藏文件都不显示,并且win ctrl h时，此时应该显示隐藏文件 
	else if (HIDDEN_REG_1="2" and HIDDEN_REG_2="0") 
		Gosub, SHOW_FILES 
	else 
	{ 
		SoundPlay *48 
		SysGet, MonFull, Monitor 
		tooltip,变量取值错误,MonFullRight/2-100,MonFullBottom/2-50 
		;sleep,2000 
		;tooltip 
		SetTimer, RemoveToolTip, 2000
	} 
} 
else 
{ 
	;;;MsgBox, 262192, WINAssist 显示已隐藏的文件和文件夹, “显示已隐藏的文件和文件夹”功能只能在资源管理器中使用。,8
	if SUPER_SHOW=1
		send, ^h
	else if SUPER_SHOW=0
		send, #^h
	else
	{
		SoundPlay *48
		SysGet, MonFull, Monitor
		tooltip,此功能只能在资源管理器中使用,MonFullRight/2-100,MonFullBottom/2-50
		;sleep,2000
		;tooltip
		SetTimer, RemoveToolTip, 2000
	}
} 
return

HIDE_FILES: 
	if (SUPER_SHOW=1) 
		RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced, ShowSuperHidden, 0
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced, Hidden, 2

	;以下两个是我加的
	sleep,500
	send {F5}{F5}

	SoundPlay *48
	SysGet, MonFull, Monitor
	tooltip, 隐藏文件,MonFullRight/2-100,MonFullBottom/2-50
	;sleep,2000
	;tooltip
	SetTimer, RemoveToolTip, 2000
	;Gosub, REFRESH_CURRENT_WINDOW
	return

SHOW_FILES: 
	if (SUPER_SHOW=1) 
		RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced, ShowSuperHidden, 1 
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced, Hidden, 1
	;以下两个是我加的
	sleep,500
	send {F5}{F5}

	SoundPlay *48
	SysGet, MonFull, Monitor
	tooltip, 显示文件,MonFullRight/2-100,MonFullBottom/2-50
	;sleep,2000
	;tooltip
	SetTimer, RemoveToolTip, 2000
	;Gosub, REFRESH_CURRENT_WINDOW

	return


;HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH   隐藏文件   结束   HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH ;
	

;nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn  新建文件夹\文件  nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn 
; CreateNewFolder
#If (FnSwitch(0118)=1)
$#n::
If WinActive("ahk_group WinGroup")
;if (WinActive("ahk_class CabinetWClass") or WinActive("ahk_class ExploreWClass"))
{
	CNF_folder := GetFolder()
	FormatTime, CurrentDateTime,, yyyy-MM-dd [HH.mm.ss]
	IfNotEqual,CNF_folder
	{
		CNF_folder .= "\" . CurrentDateTime
		FileCreateDir %CNF_folder%
	}
}
else
	send,#n
EmptyMem()
return
; CreateNewFile
$#!n::
If WinActive("ahk_group WinGroup")
;if (WinActive("ahk_class CabinetWClass") or WinActive("ahk_class ExploreWClass"))
{
	CNF_file := GetFolder()
	FormatTime, CurrentDateTime,, yyyy-MM-dd [HH.mm.ss]
	IfNotEqual,CNF_folder
	{
		CNF_file .= "\" . CurrentDateTime . ".txt"
		FileAppend , , %CNF_file%
	}
}
else
	send,#n
EmptyMem()
return
#If
;;;;;The end #IF tag of FnSwitch 0118
;nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn  新建文件夹\文件  nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn 
	
;oooooooooooooooooooooooooooooooo 打开c、d、e……盘 oooooooooooooooooooooooooooooooo
#If (FnSwitch(0113)=1)
#!c::
IfExist, C:\
Run C:\	
return
#!d::
IfExist, D:\
Run D:\
return
#!e::
IfExist, E:\
Run E:\
return
#!f::
IfExist, F:\
Run F:\
return
#!g::
IfExist, G:\
	Run G:\
return
#!h::
IfExist, H:\
	Run H:\
return
#!i::
IfExist, I:\
	Run I:\
return
#!j::
IfExist, J:\
	Run J:\
return
#!k::
IfExist, K:\
	Run K:\
return
#!l::
IfExist, L:\
	Run L:\
return
#If
;;;;;The end #IF tag of FnSwitch 0113
;oooooooooooooooooooooooooooooooo 打开c、d、e……盘 oooooooooooooooooooooooooooooooo

;******************************* 反选 *******************************
#If (FnSwitch(0117)=1)
$#i::
;if WinActive("ahk_class CabinetWClass")
if (WinActive("ahk_class CabinetWClass") or WinActive("ahk_class ExploreWClass"))
	;;;Send, {F10}ei	; 反向选择
	{
		send,!e
	sleep,100
	send,i
	}
else
	send,#i
EmptyMem()
return
#If
;;;;;The end #IF tag of FnSwitch 0117
;******************************* 反选 *******************************
;******************************* 鼠标手势 *******************************
;Windows 照片查看器鼠标手势
#If (FnSwitch(0555)=1 and WinActive("ahk_class Photo_Lightweight_Viewer"))
MButton::
mousegetpos xpos1,ypos1
settimer,gtrack,1
;MouseClick,M
;MouseClick,M
Return
MButton Up::
  settimer,gtrack,off           

	If (gtrack="")
		{
			sleep,20
			;MouseClick,M
			;MouseClick,M, , , , , U
			
			gosub MButtonUpAction
			return
		}
	else If (gtrack=PH_Gesture_Back)
		{
		Send, {Left}
		tooltip,上一个
		SetTimer, RemoveToolTip, 700
		}		
	else If (gtrack=PH_Gesture_Fwd)
		{
		;Sendplay {LButton}
		Send, {Right}
		tooltip,下一个
		SetTimer, RemoveToolTip, 700
		}
	else
		{
		tooltip,此鼠标手势未定义
		SetTimer, RemoveToolTip, 700
		}		
gtrack=
EmptyMem()
Return
#If
;the end #If tag of Windows 照片查看器 条件限制
;资源管理器鼠标手势
#If (FnSwitch(0122)=1 and (WinActive("ahk_class OpusApp") or WinActive("ahk_class CabinetWClass") or WinActive("ahk_class Progman") or WinActive("ahk_class WorkerW") or WinActive("ahk_class ExploreWClass")))
MButton::
mousegetpos xpos1,ypos1
settimer,gtrack,1
Return
MButton Up::
  settimer,gtrack,off           

	If (gtrack="")
		{
			sleep,20
			;MouseClick,M
			MouseClick,M, , , , , U
			;中键以其他方式打开文件
			If (FnSwitch(0556)=1)
			{
				MouseGetPos,mouse_X,mouse_Y,win_UID,win_ClassNN ;获取指针下窗口的 UID 和 ClassNN以及鼠标指针全屏坐标
				WinGetPos , win_X, win_Y, win_Width, , ahk_id %win_UID%
				WinGetClass,win_Class,ahk_id %win_UID% ;根据 UID 获得窗口类名

				WinGet, MIW_WinStyle, Style, ahk_id %win_UID%
				SysGet, MIW_CaptionHeight, 4 ; SM_CYCAPTION
				SysGet, MIW_BorderHeight, 7 ; SM_CXDLGFRAME
				MouseGetPos, , MIW_MouseY

				If ( MIW_MouseY <= MIW_CaptionHeight + MIW_BorderHeight )
				{
					; checks wheter the window has a sizing border (WS_THICKFRAME)
						Gosub, NWD_SetAllOff
						ROL_WinID = %win_UID%
						Gosub, ROL_RollToggle
				}
				
				else
				{
					openWith(win_Class)
				}
			}
			
				return
			;中键以其他方式打开文件
		}
	else If (gtrack=Ex_Gesture_Copy)
		{	clipboard=
			Send, ^c
			;;ClipWait,3
			If (clipboard="")
			{
				tooltip,复制前请先选中
				SetTimer, RemoveToolTip, 1000
			}
			else 
			{
				StringLen, CBLen, clipboard
				StringMid, CBA2, clipboard, 2 , 1
				StringMid, CBA7, clipboard, 7 , 1
				If ((CBLen="3")or(CBA2=":" and CBA7=":"))
				{
					tooltip,无法复制
					clipboard=
					SetTimer, RemoveToolTip, 1200
				}
				else
				{
					tooltip,复制
					SetTimer, RemoveToolTip, 700
				}
			}
		}
		
	else If (gtrack=Ex_Gesture_Paste)
		{
		;msgbox,clipboard=%clipboard%
			If (clipboard="")
			{
			tooltip,无法粘贴，剪贴板为空
			SetTimer, RemoveToolTip, 1000
			}
			else
			{
			tooltip,粘贴
			SetTimer, RemoveToolTip, 700
			Send, ^v
			;clipboard=
			}
		}
	else If (gtrack=Ex_Gesture_DelInst)
		{
		Send, {SHIFTDOWN}{DEL}{SHIFTUP}
		tooltip,永久删除
		SetTimer, RemoveToolTip, 700
		}
	else If (gtrack=Ex_Gesture_Del)
		{
		Send, {DEL}
		tooltip,删除
		SetTimer, RemoveToolTip, 700
		}
	else If (gtrack=Ex_Gesture_Upper)
		{
		GoSub,GoUpperDir
		tooltip,向上
		SetTimer, RemoveToolTip, 700
		}
	else If (gtrack=Ex_Gesture_Cute)
		{	clipboard=
			Send, ^x
			;msgbox,clipboard=%clipboard%
			If (clipboard="")
			{
			tooltip,剪切前，请先选中文件(夹)
			SetTimer, RemoveToolTip, 1000
			}
			else
			{
			tooltip,剪切
			SetTimer, RemoveToolTip, 700
			}
		}

	else If (gtrack=Ex_Gesture_Back)
		{
		Send, !{Left}
		tooltip,返回
		SetTimer, RemoveToolTip, 700
		}		
	else If (gtrack=Ex_Gesture_Pro)
		{
		;Sendplay {LButton}
		Send, !{Enter}
		tooltip,属性
		SetTimer, RemoveToolTip, 700
		}
		
	else If (gtrack=Ex_Gesture_Fwd)
		{
		Send, !{Right}
		tooltip,前进
		SetTimer, RemoveToolTip, 700
		}		
	else If (gtrack=Ex_Gesture_Close)
		{
		Send, ^w
		tooltip,关闭
		SetTimer, RemoveToolTip, 700
		}		
	else If (gtrack=Ex_Gesture_Undo)
		{
		sleep,30
		Send, ^z
		tooltip,撤销
		SetTimer, RemoveToolTip, 700
		}
	else
		{
		tooltip,此鼠标手势未定义
		SetTimer, RemoveToolTip, 700
		}		
gtrack=
EmptyMem()
Return
#If
;the end #If tag of 资源管理器 条件限制
;IE浏览器鼠标手势
#If (FnSwitch(0215)=1 and WinActive("ahk_class IEFrame") )
MButton::
mousegetpos xpos1,ypos1
settimer,gtrack,1
;MouseClick,M
;MouseClick,M
Return
MButton Up::
  settimer,gtrack,off           

	If (gtrack="")
		{
			sleep,20
;			MouseClick,M
;			MouseClick,M, , , , , U

			gosub MButtonUpAction
			return 
		}
	else If (gtrack=IE_Gesture_CloseTab)
		{
		Send, ^w
		tooltip,关闭
		SetTimer, RemoveToolTip, 700
		}
	else If (gtrack=IE_Gesture_Back)
		{
		Send, !{Left}
		tooltip,返回
		SetTimer, RemoveToolTip, 700
		}		
	else If (gtrack=IE_Gesture_Refresh)
		{
		Send, {F5}
		tooltip,刷新
		SetTimer, RemoveToolTip, 700
		}		
	else If (gtrack=IE_Gesture_NewTab)
		{
		Send, ^t
		tooltip,新建选项卡
		SetTimer, RemoveToolTip, 700
		}		
	else If (gtrack=IE_Gesture_UndoTab)
		{
		Send, ^+t
		tooltip,恢复关闭的选项卡
		SetTimer, RemoveToolTip, 700
		}		
	else If (gtrack=IE_Gesture_NextTab)
		{
		Send, ^{Tab}
		tooltip,后一个选项卡
		SetTimer, RemoveToolTip, 700
		}		
	else If (gtrack=IE_Gesture_PreTab)
		{
		Send, ^+{Tab}
		tooltip,前一个选项卡
		SetTimer, RemoveToolTip, 700
		}		
	else If (gtrack=IE_Gesture_Stop)
		{
		Send, {Esc}
		tooltip,停止
		SetTimer, RemoveToolTip, 700
		}		
	else If (gtrack=IE_Gesture_Forward)
		{
		Send, !{Right}
		tooltip,前进
		SetTimer, RemoveToolTip, 700
		}		
	else If (gtrack=IE_Gesture_PageHome)
		{
		Send, <^{Home}
		tooltip,页面顶部
		SetTimer, RemoveToolTip, 700
		}		
	else If (gtrack=IE_Gesture_PageEnd)
		{
		Send, <^{End}
		tooltip,页面底部
		SetTimer, RemoveToolTip, 700
		}
	else
		{
		tooltip,此鼠标手势未定义
		SetTimer, RemoveToolTip, 700
		}		
		
gtrack=
EmptyMem()
Return
#If
;the end #If tag of IE 条件限制
  
;获取鼠标轨迹  
gtrack:
mousegetpos xpos2,ypos2
track:=(abs(ypos1-ypos2)>=abs(xpos1-xpos2)) ? (ypos1>ypos2 ? "U" : "D") : (xpos1>xpos2 ? "L" : "R") 
if (track<>SubStr(gtrack, 0, 1)) and (abs(ypos1-ypos2)>4 or abs(xpos1-xpos2)>4)
gtrack.=track 
xpos1:=xpos2,ypos1:=ypos2
return
  
;上一层目录  
GoUpperDir: 
;WinGetClass,sClass,A
;If (sClass="CabinetWClass")
;	Send, !{up}
;else If (sClass="ExploreWClass")
;	Send, {BS}
;else
;	MouseClick,M
If A_OSVersion in WIN_7,WIN_VISTA
	Send, !{up}
else
	Send, {BS}
return
;******************************* 鼠标手势 *******************************

/*
;******************************* 中键用其他软件打开当前文件 *******************************

#IfWinActive ahk_group WinGroup
~MButton::
GVIM="D:\Program Files\PortableApps\Vim\vim73\gvim.exe"
SPLAYER="D:\Program Files\PortableApps\splayer\splayer.exe"
send, ^c
sleep 500
Full_FileName=%clipboard%
SplitPath, Full_FileName, , , ext
;msgbox, %ext%
if (ext="txt" or ext="c" or ext= "cpp" or ext="html" or ext="ahk" or ext="sql")
{
	;msgbox, %GVIM%
	run %GVIM% "%Full_FileName%"
	return
}
else if (ext="wmv" or ext="mp4" or ext="rm" or ext="rmvb" or ext="avi" or ext="mpg" or ext="flv" or ext="swf" or ext="mkv" or ext="mpg" or ext="mpeg")
{
	run %SPLAYER% "%Full_FileName%"
	return
}
else
{
	tooltip, 不支持该类型文件
	sleep,2000
	tooltip
	return
}
return

;******************************* 中键用其他软件打开当前文件 *******************************
*/

;******************************* 链接转换：迅雷、快车、旋风地址转换为普通地址 *******************************
#If (FnSwitch(0557)=1)
^#z::
Convert_Address:
Gui, 3:Destroy
Gui, 3:font,, Arial
Gui, 3:font,,微软雅黑
Gui, 3:Add, Edit, x3 y3 w300 h77 +Multi +Wrap Vurl,
Gui, 3:Add, Button, x306 y3 w24 h37 Gconvert_paste, 粘贴
Gui, 3:Add, Button, x306 y43 w24 h37 Gcopy, 复制
Gui, 3:Add, Button, x3 y83 w90 h30 Gdo, 转换
Gui, 3:Add, Button, x99 y83 w90 h30 Gabout_3, 关于
Gui, 3:Add, Button, x195 y83 w90 h30 Gclose_3, 退出
;Gui, 3:Add, Button, x195 y83 w90 h30 GGuiClose, 退出
Gui, 3:Add, Checkbox, x289 y83 w40 h30 Vtop Gctop, 置顶
Gui, 3:Show, center w333 h116 ,专用链转换V1.0
Return
#If

ctop:
Gui,3:Submit,NoHide
If top = 1
{
Gui 3:+AlwaysOnTop
}
else
{
Gui 3:-AlwaysOnTop
}
return

3GuiEscape:
3GuiClose:
close_3:
;exitapp
Gui, 3:Destroy
EmptyMem()
return

about_3:
Gui 3:+OwnDialogs
msgbox,,By DieJian,支持(迅雷,快车,旋风,rayfile)
return

convert_paste:
decodeurl:=Clipbard
GuiControl,3:, url, %decodeurl%
return

copy:
Gui,3:Submit,NoHide
Clipboard:=url
return

do:
Gui,3:Submit,NoHide
StringReplace, url, url,%A_space%,,All
StringReplace, url, url,`n,,All
decodeurl =
If url contains ://
{
  cut:=InStr(url,"://",false,1)-1
  StringLeft, type, url,%cut%

  If type not in thunder,qqdl,flashget,fs2you,http
  {
    decodeurl =
  }
  else
  {
    If(type="http"){
      decodeurl:=url
    }
    If(type="thunder"){
      StringReplace, url, url,thunder://,,All
      StringReplace, url, url, /,,All
      IfInString, url,=
      {
        cut:=StrLen(url)-InStr(url,"=",false,1)+1
        StringTrimRight, url, url, %cut%
      }
      url:=Base64Decode(url)
      StringTrimLeft, url, url, 2
      StringTrimRight, decodeurl, url, 2
    }
    If(type="qqdl"){
      StringReplace, url, url,qqdl://,,All
      StringReplace, url, url, /,,All
      IfInString, url,=
      {
        cut:=StrLen(url)-InStr(url,"=",false,1)+1
        StringTrimRight, url, url, %cut%
      }
      decodeurl:=Base64Decode(url)
    }
    If(type="flashget"){
      StringReplace, url, url,flashget://,,All
      StringReplace, url, url, /,,All
      IfInString, url,=
      {
        cut:=StrLen(url)-InStr(url,"=",false,1)+1
        StringTrimRight, url, url, %cut%
      }
      IfInString, url,&
      {
        cut:=StrLen(url)-InStr(url,"&",false,1)+1
        StringTrimRight, url, url, %cut%
      }
      url:=Base64Decode(url)
      StringTrimLeft, url, url, 10
      StringTrimRight, decodeurl, url, 10
    }
    If(type="fs2you"){
      StringReplace, url, url,fs2you://,,All
      StringReplace, url, url, /,,All
      IfInString, url,=
      {
        cut:=StrLen(url)-InStr(url,"=",false,1)+1
        StringTrimRight, url, url, %cut%
      }
      url:=Base64Decode(url)
      IfInString, url,|
      {
        cut:=StrLen(url)-InStr(url,"|",false,0)+1
        StringTrimRight, url, url, %cut%
      }
      decodeurl:="http://"url
    }
  }
}
end:
GuiControl,3:, url, %decodeurl%
return

;******************************* 链接转换：迅雷、快车、旋风地址转换为普通地址 *******************************
;******************************* 定时关机 *******************************
#If (FnSwitch(0333)=1)
~LCtrl & RCtrl::             ;定时关机
~RCtrl & LCtrl::
start_shutdown:
If AutoShutdown_Alarm_Text=Shown
	return
SetTimer, as_Input_AlwaysOnTop , -1000
If (AutoShutdown_Run=1 or AutoShutdown_Run_INI=1)
{
	If AutoShutdown_Run_INI=1
		ASDINI=`n在INI文件中您设置了AutoShutdownTime的值
	else
		ASDINI=
	MsgBox, 262436, WINAssist 提醒, 您之前已经设置过定时关机！%ASDINI%`n自动关机时间是 %CancelAskTime%`n`n取消并重新设定吗？
	IfMsgBox Yes
	{
	SetTimer, AutoShutdown_Alarm , Off
	SetTimer, AutoShutdown , Off
	SetTimer, ShutdownOn , Off
	CancelAskTime=
	AutoShutdown_Run=0
	AutoShutdown_Run_INI=0
	;MsgBox, 262192, WINAssist自动关机, 已取消,2
	tooltip,WINAssist 定时关机已取消
	;SetTimer, RemoveToolTip, 3000
	;sleep,1500
	;tooltip
	SetTimer, RemoveToolTip, 1000
	Gosub, INPUT_NUM			
	}
	else
	{
		return
	}

}
else
{
	Gosub, INPUT_NUM
}
;;;;;;;;;SetTimer, INPUT_NUM, 3000
EmptyMem()
return
#If
;;;;;The end #IF tag of FnSwitch 0333

INPUT_NUM:
 ;msgbox,898989
IfWinExist,WINAssist 定时关机
	WinActivate,WINAssist 定时关机
else
{
	InputBox, pageacc,WINAssist 请设定自动关机时间, 倒计时模式：您可以指定若干分钟后自动关机，例如要40分钟后关机，请输入数字40。支持最长3天内的自动关机（最大限值4320）。`n`n定时模式：您可以直接指定自动关机时间（24小时制），例如21:05。支持24小时内的自动关机。,notHIDE, 370, 220
	
	Gosub, CHECK_NUM
}
return
; ========================检查数字合法性=========================
ShutdownOn:

;MsgBox, SetTimer ShutdownOn runing
;PlayWAV("ding")
  If ((A_Hour = as_alarm_hr) && (A_Min = as_alarm_min) )
  {
	GoSub,AutoShutdown_Alarm
	AutoShutdown_Alarm_Did=1
	}
	else If ((A_Hour = as_time1) && (A_Min = as_time2) )
	{
	GoSub,AutoShutdown
	SetTimer, ShutdownOn , off
	;MsgBox, HAHA will shutdown on %as_time1%:%as_time2% NOW is %A_Hour%:%A_Min%:%A_Sec%
	}
return

as_time_format:
{
	If ShutdownTimeCheck(as_time1,as_time2)=1
		{
		If as_time2<10
			{
			If as_time1="00"
				as_alarm_hr="23"
			else
				as_alarm_hr:=as_time1-1
				
			as_alarm_min:=as_time2+50
			}
		else
			{
			as_alarm_hr:=as_time1
			as_alarm_min:=as_time2-10
			}
		StringLen, as_time1_len, as_time1
		StringLen, as_time2_len, as_time2
		StringLen, as_alarm_hr_len, as_alarm_hr
		StringLen, as_alarm_min_len, as_alarm_min
		If as_time1_len=1
			as_time1=0%as_time1%
		If as_time2_len=1
			as_time2=0%as_time2%
		If as_alarm_min_len=1
			as_alarm_min=0%as_alarm_min%
		If as_alarm_hr_len=1
			as_alarm_hr=0%as_alarm_hr%
		;MsgBox, will shutdown on %as_time1%:%as_time2% NOW is %A_Hour%:%A_Min%:%A_Sec% ALARM on %as_alarm_hr%:%as_alarm_min%
		If as_time1<6
			AP=凌晨
		else If  as_time1<12
			AP=上午
		else If  as_time1<18
			AP=下午
		else If  as_time1<24
			AP=晚上
		MsgBox, 262180, WINAssist 提醒, 您确定在%AP% %as_time1%:%as_time2% 自动关机吗？`n`n注意：`n1. WINAssist 会强制关闭您的计算机，这意味着如果自动关机时您有未保存的文件，那么这些文件可能丢失；`n2. 如果您提前手动关闭、重启了您的计算机，或退出、重启了 WINAssist ，则本次设置自动失效；`n3.在执行自动关机前 30 秒，您将有机会取消自动关机；`n4.上述%as_time1%:%as_time2%指24小时之内的时刻。
			IfMsgBox Yes
			{
				SetTimer, ShutdownOn , 10000
				AutoShutdown_Run=1		
				AutoShutdown_Alarm_Did=0				
				msgbox,262192,WINAssist 定时关机已启用, 已确认`n`n%AP% %as_time1%:%as_time2% 自动关机。,5
				CancelAskTime=%AP% %as_time1%:%as_time2%
				SetTimer, as_Input_AlwaysOnTop , Off
				
			}
			else
			{
			;MsgBox, 262208, WINAssist 定时关机, WINAssist 已取消操作，同时按左右 Ctrl 键重新设置。,10
			Gosub, INPUT_NUM
			}

		}
		;Gosub, ShutdownOn
	else
		{
		MsgBox, 262160, WINAssist 定时关机 输入有误, 时间输入错误，请参照 6:05 和 23:45 重新设置,7
		Gosub, INPUT_NUM
		}
}
return


as_time_format_AutoRun:
				If ShutdownTimeCheck(as_time1,as_time2)=1
		{
		If as_time2<10
			{
			If as_time1="00"
				as_alarm_hr="23"
			else
				as_alarm_hr:=as_time1-1
				
			as_alarm_min:=as_time2+50
			}
		else
			{
			as_alarm_hr:=as_time1
			as_alarm_min:=as_time2-10
			}
		StringLen, as_time1_len, as_time1
		StringLen, as_time2_len, as_time2
		StringLen, as_alarm_hr_len, as_alarm_hr
		StringLen, as_alarm_min_len, as_alarm_min
		If as_time1_len=1
			as_time1=0%as_time1%
		If as_time2_len=1
			as_time2=0%as_time2%
		If as_alarm_min_len=1
			as_alarm_min=0%as_alarm_min%
		If as_alarm_hr_len=1
			as_alarm_hr=0%as_alarm_hr%
		;MsgBox, will shutdown on %as_time1%:%as_time2% NOW is %A_Hour%:%A_Min%:%A_Sec% ALARM on %as_alarm_hr%:%as_alarm_min%
		If as_time1<6
			AP=凌晨
		else If  as_time1<12
			AP=上午
		else If  as_time1<18
			AP=下午
		else If  as_time1<24
			AP=晚上
				SetTimer, ShutdownOn , 1000
				AutoShutdown_Run_INI=1	
				AutoShutdown_Alarm_Did=0
				;msgbox,262192,WINAssist 定时关机已启用, %AP% %as_time1%:%as_time2% 时将会自动关机。,5
				tooltip,%AP% %as_time1%:%as_time2% 自动关机
				;sleep,3000
				;tooltip
				SetTimer, RemoveToolTip, 3000
				CancelAskTime=%AP% %as_time1%:%as_time2%
		}
	else
		{
		AutoShutdown_Run_INI=0
		MsgBox, 262160, WINAssist 定时关机 输入有误, 您输入的定时关机时间格式错误：`nAutoShutdownTime=%AutoShutdownTime%`n`n请重新设置，正确的格式有：`nAutoShutdownTime=6:05`nAutoShutdownTime=23:45`n`n取消自动关机请留空，即`nAutoShutdownTime=
		;GoSub,OpenINI
		;sleep,2000
		
		;		Send, {CTRLDOWN}f{CTRLUP}
		;		sleep,200
		;		SendInput {Raw}AutoShutdownTime
		;		sleep,300
		;		Send, {Enter}
				;Send, {Tab 4}{Enter}
		}
			;msgbox,as_time_format
return

CHECK_NUM:
if ErrorLevel
	{
	;MsgBox, 262208, WINAssist 定时关机, WINAssist 已取消操作，同时按左右 Ctrl 键重新设置。,10
	}
else IfInString, pageacc, :
	{
	StringSplit, as_time, pageacc, `:,%A_Space%
	GoSub,as_time_format	
	}
else IfInString, pageacc, ：
	{
	StringSplit, as_time, pageacc, `：,%A_Space%
	GoSub,as_time_format	
	}
else if (pageacc=null)
	{  MsgBox, 262160, WINAssist 定时关机 输入有误, 不能为空,3
		Gosub, INPUT_NUM
	}
else if (pageacc=0)
	{  MsgBox, 262160, WINAssist 定时关机 输入有误, 不能为0，请重新输入,3
		Gosub, INPUT_NUM
	}
else if (pageacc<0)
	{  MsgBox, 262160, WINAssist 定时关机 输入有误, 输入有误，请重新输入,3
		Gosub, INPUT_NUM
	}
else if pageacc is not integer 
	{  MsgBox, 262160, WINAssist 定时关机 输入有误, 倒计时模式下必须是整数，如40`n定时模式下必须是24小时制时刻，如21:05`n`n请重新输入,7
		Gosub, INPUT_NUM
	}
else if (pageacc>4320)
	{  MsgBox, 262192, WINAssist 定时关机 输入有误, 倒计时不能超过 4320 分钟（=72小时=3天）！请重新输入,5
		Gosub, INPUT_NUM
	}
else
	{  
;%WhichDay%%AP% %SDTimeHr3%:%SDTimeMin2%
Gosub,TimeAfterMin
		MsgBox, 262180, WINAssist 提醒, 确定在 %pageacc2%后，即%WhichDay%%AP% %SDTimeHr3%:%SDTimeMin2% 关机吗？`n`n注意：`n1. WINAssist 会强制关闭您的计算机，这意味着如果自动关机时您有未保存的文件，那么这些文件可能丢失；`n2. 如果您提前手动关闭、重启了您的计算机，或退出、重启了 WINAssist ，则本次设置自动失效；`n3. 上述关机倒计时从您按下“是”按钮后开始计算；`n4. 在执行自动关机前 30 秒，您将有机会取消自动关机。
			IfMsgBox Yes
			{
			PlayWAV("notify")
			;msgbox,00000000000--%asmin%
			SetTimer, AutoShutdown, -%asmin%
			AutoShutdown_Run=1
			If asmin>600000
			{
			asmin2:=asmin-600000
			;;;msgbox,262192,00002222222--%asmin2%
			SetTimer, AutoShutdown_Alarm, -%asmin2%
			}
Gosub,TimeAfterMin
			msgbox,262192,WINAssist 定时关机已启用,已确认自动关机时间为`n`n%pageacc2%后即%WhichDay%%TheASDDateAndTime%。,10
			SetTimer, as_Input_AlwaysOnTop , Off
			
			;CancelAskTime=%SDTimeHr3%:%SDTimeMin2%
			CancelAskTime=%TheASDDateAndTime%
			AutoShutdown_Alarm_Did=0
			}
			else
			{
			;MsgBox, 262208, WINAssist 定时关机, WINAssist 已取消操作，同时按左右 Ctrl 键重新设置。,10
			Gosub, INPUT_NUM
			}
		
	}
return

Ding:
{
PlayWAV("ding")
}
return

AutoShutdown:
{
IfNotExist, %A_ScriptDir%\WINAssist_SD.vbs
FileAppend, set kickoff=createobject("wscript.shell")`nkickoff.run "shutdown -s -f  -c WINAssist将在1分钟内关闭计算机，请您立刻结束并保存正在进行的工作... -t 65", %A_ScriptDir%\WINAssist_SD.vbs

Run,%A_ScriptDir%\WINAssist_SD.vbs
AutoShutdown_Is_Counting_Down=1
SetTimer, Ding, 1000
}
return


^+!d::GoSub,AutoShutdown_Cancel
AutoShutdown_Cancel:
If AutoShutdown_Is_Counting_Down<>1
return
;MsgBox, 262436, WINAssist 提醒, 取消自动关机吗？
;IfMsgBox Yes
;{
	AutoShutdown_Run=0
	AutoShutdown_Run_INI=0
	AutoShutdown_Is_Counting_Down=0
	SetTimer, Ding, off
	AutoShutdown_Alarm_Text=None
	SetTimer, ShutdownTimerDown, off 
BlockInput MouseMove
send,#r
WinWait , 运行
SendInput {Raw}shutdown -a
send,{Enter}
BlockInput MouseMoveOff
MsgBox, 262192, WINAssist 自动关机已取消,自动关机已中止。,30
;}
;else
;{

;}
return



AutoShutdown_Alarm:
{
If AutoShutdown_Alarm_Did=1
return
PlayWAV("notify")
sleep,120
PlayWAV("notify")
sleep,120
PlayWAV("notify")
MsgBox, 262192, WINAssist 即将强制关机！！！, 注意：WINAssist 将于 10 分钟后强制关闭您的计算机！！！`n`n请尽快结束正在进行的工作并保存！！！,30
;IfMsgBox Timeout
    ;MsgBox You didn't press YES or NO within the 5-second period.

;msgbox,gogogo222;;;Gosub, SAP
;Shutdown, 0
}
return



as_Input_AlwaysOnTop:
{
WinSet, AlwaysOnTop, On, WINAssist 定时关机
}
return

TimeAfterMin:
{
				asmin:=pageacc*60000
		If pageacc>60
		{
		my_hr:=pageacc/60
		my_hr^=0
		
		;msgbox,my_hr===%my_hr%
		my_min:=pageacc-(my_hr*60)
		;msgbox,%my_hr%---%my_min%
		If my_min=0
			pageacc2= %my_hr% 小时  
		else
			pageacc2= %my_hr% 小时 %my_min% 分钟 
		}
		else if (pageacc=60)
		{
			pageacc2= 1 小时
			my_min=0
			my_hr=1
		}
		else
		{
			pageacc2=%pageacc% 分钟
			my_min=%pageacc%
			my_hr=0
		}
;;计算关机时间--开始			
		FormatTime, CurrentMin,, m
		FormatTime, CurrentHr,, H
		;;;msgbox,CurrentHr=%CurrentHr%，CurrentMin=%CurrentMin%---N小时（ %my_min% ）分钟后关机
		all_only_Min:=CurrentMin + my_min
		;;msgbox,all_only_Min=%all_only_Min%
		If all_only_Min>60
		{
		;;msgbox,all_only_Min>60
		hr_add_step:=all_only_Min/60
		hr_add_step^=0
		

		
		}
		else if (all_only_Min=60)
			hr_add_step=1 
		else
			hr_add_step=0
			
		;;msgbox,hr_add_step===%hr_add_step%			
		
		SDTimeHr:=CurrentHr + hr_add_step + my_hr
		;;msgbox,SDTimeHr1=%SDTimeHr%
		SDTimeHr^=0
		;;msgbox,SDTimeHr2=%SDTimeHr%
		SDTimeMin:=all_only_Min - (hr_add_step*60)
		
		If (SDTimeHr>=24 and SDTimeHr<48)
		{
		WhichDay=明天
		SDTimeHr2:=SDTimeHr-24
		}
		else If (SDTimeHr>=48 and SDTimeHr<72)
		{
		WhichDay=后天
		SDTimeHr2:=SDTimeHr-48
		}
		else If (SDTimeHr>=72 and SDTimeHr<97)
		{
		WhichDay=大后天
		SDTimeHr2:=SDTimeHr-72
		}
		else
		{
		WhichDay=今天
		SDTimeHr2:=SDTimeHr
		}
		
		;FormatTime, CurrentHr,, H
		;;msgbox,SDTimeHr=%SDTimeHr2%，SDTimeMin=%SDTimeMin%
		If SDTimeHr2<6
			AP=凌晨
		else If  SDTimeHr2<12
			AP=上午
		else If  SDTimeHr2<18
			AP=下午
		else If  SDTimeHr2<24
			AP=晚上
		
		If SDTimeHr2<10
			SDTimeHr3=0%SDTimeHr2%
		else
			SDTimeHr3:=SDTimeHr2
		
		If SDTimeMin<10
			SDTimeMin2=0%SDTimeMin%
		else
			SDTimeMin2:=SDTimeMin		
		
		;SDTimeHr:=CurrentHr + my_min
;;计算关机时间--结束

			var1 =
			var1 += %pageacc%, Minutes
			;msgbox,%var1%
			StringMid, var1Year, var1, 1 , 4 
			StringMid, var1Month, var1, 5 , 2 
			StringMid, var1Day, var1, 7 , 2 
			StringMid, var1Hr, var1, 9 , 2 
			StringMid, var1Min, var1, 11 , 2 
			;StringMid, var1Sec, var1, 13 , 2
			
	TheASDDateAndTime=%var1Year%年%var1Month%月%var1Day%日%var1Hr%时%var1Min%分
}
return


ShutdownTimerDown: 
IfWinNotExist, WINAssist 即将强制关机！！！
    return  ; Keep waiting.
NumInp -= 1
WinActivate 
ControlSetText, Button1, 中止自动关机
ControlSetText, Static2,  　　%NumInp% 秒后自动关机
return
;
;******************************* 定时关机 *******************************

;SSSSSSSSSSSSSSSSS用快捷键得到当前选中文件的路径SSSSSSSSSSSSSSSS
#If (FnSwitch(0330)=1)
^#c::
;If (sClass="CabinetWClass" || sClass="ExploreWClass")
if (WinActive("ahk_class CabinetWClass") or WinActive("ahk_class ExploreWClass")or WinActive("ahk_class Progman")or WinActive("ahk_class WorkerW"))
{
clipboard=
send ^c
sleep,100
;ClipWait,3
clipboard=%clipboard% ;%null%
tooltip,已复制以下路径`n%clipboard%
;sleep,2000
;tooltip,
SetTimer, RemoveToolTip, 2000
}
return
#If
;;;;;The end #IF tag of FnSwitch 0330
;EEEEEEEEEEEEEEEEEEEEE用快捷键得到当前选中文件的路径EEEEEEEEEEEEEEE
#If (FnSwitch(0334)=1)
;;;$$$$$$$$$$$ KDE窗口风格  开始$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
;;;;;;;;;;;;;;;;;;;;;;SetWinDelay,0
!LButton::
SetWinDelay,2
CoordMode,Mouse
; Get the initial mouse position and window id, and
; abort if the window is maximized.
MouseGetPos,KDE_X1,KDE_Y1,KDE_id
WinGet,KDE_Win,MinMax,ahk_id %KDE_id%
If KDE_Win
    return
; Get the initial window position.
WinGetPos,KDE_WinX1,KDE_WinY1,,,ahk_id %KDE_id%
Loop
{
    GetKeyState,KDE_Button,LButton,P ; Break if button has been released.
    If KDE_Button = U
        break
    MouseGetPos,KDE_X2,KDE_Y2 ; Get the current mouse position.
    KDE_X2 -= KDE_X1 ; Obtain an offset from the initial mouse position.
    KDE_Y2 -= KDE_Y1
    KDE_WinX2 := (KDE_WinX1 + KDE_X2) ; Apply this offset to the window position.
    KDE_WinY2 := (KDE_WinY1 + KDE_Y2)
    WinMove,ahk_id %KDE_id%,,%KDE_WinX2%,%KDE_WinY2% ; Move the window to the new position.
}
return

!RButton::
SetWinDelay,2
CoordMode,Mouse
; Get the initial mouse position and window id, and
; abort if the window is maximized.
MouseGetPos,KDE_X1,KDE_Y1,KDE_id
WinGet,KDE_Win,MinMax,ahk_id %KDE_id%
If KDE_Win
    return
; Get the initial window position and size.
WinGetPos,KDE_WinX1,KDE_WinY1,KDE_WinW,KDE_WinH,ahk_id %KDE_id%
; Define the window region the mouse is currently in.
; The four regions are Up and Left, Up and Right, Down and Left, Down and Right.
If (KDE_X1 < KDE_WinX1 + KDE_WinW / 2)
   KDE_WinLeft := 1
Else
   KDE_WinLeft := -1
If (KDE_Y1 < KDE_WinY1 + KDE_WinH / 2)
   KDE_WinUp := 1
Else
   KDE_WinUp := -1
Loop
{
    GetKeyState,KDE_Button,RButton,P ; Break if button has been released.
    If KDE_Button = U
        break
    MouseGetPos,KDE_X2,KDE_Y2 ; Get the current mouse position.
    ; Get the current window position and size.
    WinGetPos,KDE_WinX1,KDE_WinY1,KDE_WinW,KDE_WinH,ahk_id %KDE_id%
    KDE_X2 -= KDE_X1 ; Obtain an offset from the initial mouse position.
    KDE_Y2 -= KDE_Y1
    ; Then, act according to the defined region.
    WinMove,ahk_id %KDE_id%,, KDE_WinX1 + (KDE_WinLeft+1)/2*KDE_X2  ; X of resized window
                            , KDE_WinY1 +   (KDE_WinUp+1)/2*KDE_Y2  ; Y of resized window
                            , KDE_WinW  -     KDE_WinLeft  *KDE_X2  ; W of resized window
                            , KDE_WinH  -       KDE_WinUp  *KDE_Y2  ; H of resized window
    KDE_X1 := (KDE_X2 + KDE_X1) ; Reset the initial position for the next iteration.
    KDE_Y1 := (KDE_Y2 + KDE_Y1)
}
return
;;;$$$$$$$$$$$ KDE窗口风格  结束$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

; [TRA] provides window transparency

/**
 * Adjusts the transparency of the active window in ten percent steps 
 * (opaque = 100%) which allows the contents of the windows behind it to shine 
 * through. If the window is completely transparent (0%) the window is still 
 * there and clickable. If you loose a transparent window it will be extremly 
 * complicated to find it again because it's invisible (see the first hotkey 
 * in this list for emergency help in such situations). 
 */
#If (FnSwitch(0562)=1)
#WheelUp::
#+WheelUp::
#WheelDown::
#+WheelDown::
	Gosub, TRA_CheckWinIDs
	SetWinDelay, -1
	IfWinActive, A
	{
		WinGet, TRA_WinID, ID
		If ( !TRA_WinID )
			Return
		WinGetClass, TRA_WinClass, ahk_id %TRA_WinID%
		If ( TRA_WinClass = "Progman" )
			Return
		
		IfNotInString, TRA_WinIDs, |%TRA_WinID%
			TRA_WinIDs = %TRA_WinIDs%|%TRA_WinID%
		TRA_WinAlpha := TRA_WinAlpha%TRA_WinID%
		TRA_PixelColor := TRA_PixelColor%TRA_WinID%
		
		IfInString, A_ThisHotkey, +
			TRA_WinAlphaStep := 255 * 0.01 ; 1 percent steps
		Else
			TRA_WinAlphaStep := 255 * 0.1 ; 10 percent steps

		If ( TRA_WinAlpha = "" )
			TRA_WinAlpha = 255

		IfInString, A_ThisHotkey, WheelDown
			TRA_WinAlpha -= TRA_WinAlphaStep
		Else
			TRA_WinAlpha += TRA_WinAlphaStep

		If ( TRA_WinAlpha > 255 )
			TRA_WinAlpha = 255
		Else
			If ( TRA_WinAlpha < 0 )
				TRA_WinAlpha = 0

		If ( !TRA_PixelColor and (TRA_WinAlpha = 255) )
		{
			Gosub, TRA_TransparencyOff
			SYS_ToolTipText = Transparency: OFF
		}
		Else
		{
			TRA_WinAlpha%TRA_WinID% = %TRA_WinAlpha%

			If ( TRA_PixelColor )
				WinSet, TransColor, %TRA_PixelColor% %TRA_WinAlpha%, ahk_id %TRA_WinID%
			Else
				WinSet, Transparent, %TRA_WinAlpha%, ahk_id %TRA_WinID%

			TRA_ToolTipAlpha := TRA_WinAlpha * 100 / 255
			Transform, TRA_ToolTipAlpha, Round, %TRA_ToolTipAlpha%
			SYS_ToolTipText = Transparency: %TRA_ToolTipAlpha% `%
		}
		Gosub, SYS_ToolTipFeedbackShow
	}
Return

#^LButton::
#^MButton::
	Gosub, TRA_CheckWinIDs
	SetWinDelay, -1
	CoordMode, Mouse, Screen
	CoordMode, Pixel, Screen
	MouseGetPos, TRA_MouseX, TRA_MouseY, TRA_WinID
	If ( !TRA_WinID )
		Return
	WinGetClass, TRA_WinClass, ahk_id %TRA_WinID%
	If ( TRA_WinClass = "Progman" )
		Return
	
	IfWinNotActive, ahk_id %TRA_WinID%
		WinActivate, ahk_id %TRA_WinID%
	IfNotInString, TRA_WinIDs, |%TRA_WinID%
		TRA_WinIDs = %TRA_WinIDs%|%TRA_WinID%
	
	IfInString, A_ThisHotkey, MButton
	{
		AOT_WinID = %TRA_WinID%
		if (if_on_top=1)
			Gosub, AOT_SetOn
		TRA_WinAlpha%TRA_WinID% := 25 * 255 / 100
	}
	
	TRA_WinAlpha := TRA_WinAlpha%TRA_WinID%
	
	; TODO : the transparency must be set off first, 
	; this may be a bug of AutoHotkey
	WinSet, TransColor, OFF, ahk_id %TRA_WinID%
	PixelGetColor, TRA_PixelColor, %TRA_MouseX%, %TRA_MouseY%, RGB
	WinSet, TransColor, %TRA_PixelColor% %TRA_WinAlpha%, ahk_id %TRA_WinID%
	TRA_PixelColor%TRA_WinID% := TRA_PixelColor

	IfInString, A_ThisHotkey, MButton
		SYS_ToolTipText = Transparency: 25 `% + %TRA_PixelColor% color (RGB) + Always on Top
	Else
		SYS_ToolTipText = Transparency: %TRA_PixelColor% color (RGB)
	Gosub, SYS_ToolTipFeedbackShow
Return

#MButton::
	Gosub, TRA_CheckWinIDs
	SetWinDelay, -1
	MouseGetPos, , , TRA_WinID
	If ( !TRA_WinID )
		Return
	IfWinNotActive, ahk_id %TRA_WinID%
		WinActivate, ahk_id %TRA_WinID%
	IfNotInString, TRA_WinIDs, |%TRA_WinID%
		Return
	Gosub, TRA_TransparencyOff

	SYS_ToolTipText = Transparency: OFF
	Gosub, SYS_ToolTipFeedbackShow
Return

TRA_TransparencyOff:
	Gosub, TRA_CheckWinIDs
	SetWinDelay, -1
	If ( !TRA_WinID )
		Return
	IfNotInString, TRA_WinIDs, |%TRA_WinID%
		Return
	StringReplace, TRA_WinIDs, TRA_WinIDs, |%TRA_WinID%, , All
	TRA_WinAlpha%TRA_WinID% =
	TRA_PixelColor%TRA_WinID% =
	; TODO : must be set to 255 first to avoid the black-colored-window problem
	WinSet, Transparent, 255, ahk_id %TRA_WinID%
	WinSet, TransColor, OFF, ahk_id %TRA_WinID%
	WinSet, Transparent, OFF, ahk_id %TRA_WinID%
	WinSet, Redraw, , ahk_id %TRA_WinID%
Return

TRA_TransparencyAllOff:
	Gosub, TRA_CheckWinIDs
	Loop, Parse, TRA_WinIDs, |
		If ( A_LoopField )
		{
			TRA_WinID = %A_LoopField%
			Gosub, TRA_TransparencyOff
		}
Return

#^t::
	Gosub, TRA_TransparencyAllOff
	SYS_ToolTipText = Transparency: ALL OFF
	Gosub, SYS_ToolTipFeedbackShow
Return

TRA_CheckWinIDs:
	DetectHiddenWindows, On
	Loop, Parse, TRA_WinIDs, |
		If ( A_LoopField )
			IfWinNotExist, ahk_id %A_LoopField%
			{
				StringReplace, TRA_WinIDs, TRA_WinIDs, |%A_LoopField%, , All
				TRA_WinAlpha%A_LoopField% =
				TRA_PixelColor%A_LoopField% =
			}
Return

TRA_ExitHandler:
	Gosub, TRA_TransparencyAllOff
Return
#if 


; [NWD] nifty window dragging
NWD_SetDraggingOff:
	NWD_Dragging = 0
Return

NWD_SetClickOff:
	NWD_PermitClick = 0
	NWD_ImmediateDownRequest = 0
Return

NWD_SetAllOff:
	Gosub, NWD_SetDraggingOff
	Gosub, NWD_SetClickOff
Return


; [ROL] rolls up/down a window to/from its title bar

ROL_RollToggle:
	Gosub, ROL_CheckWinIDs
	SetWinDelay, -1
	IfWinNotExist, ahk_id %ROL_WinID%
		Return
	WinGetClass, ROL_WinClass, ahk_id %ROL_WinID%
	If ( ROL_WinClass = "Progman" or ROL_WinClass = "WorkerW")
		Return
	
	IfNotInString, ROL_WinIDs, |%ROL_WinID%
	{
		SYS_ToolTipText = Window Roll: UP
		Gosub, ROL_RollUp
	}
	Else
	{
		WinGetPos, , , , ROL_WinHeight, ahk_id %ROL_WinID%
		If ( ROL_WinHeight = ROL_WinRolledHeight%ROL_WinID% )
		{
			SYS_ToolTipText = Window Roll: DOWN
			Gosub, ROL_RollDown
		}
		Else
		{
			SYS_ToolTipText = Window Roll: UP
			Gosub, ROL_RollUp
		}
	}
	Gosub, SYS_ToolTipFeedbackShow
Return

ROL_RollUp:
	Gosub, ROL_CheckWinIDs
	SetWinDelay, -1
	IfWinNotExist, ahk_id %ROL_WinID%
		Return
	WinGetClass, ROL_WinClass, ahk_id %ROL_WinID%
	If ( ROL_WinClass = "Progman" ROL_WinClass = "WorkerW")
		Return
	
	WinGetPos, , , , ROL_WinHeight, ahk_id %ROL_WinID%
	IfInString, ROL_WinIDs, |%ROL_WinID%
		If ( ROL_WinHeight = ROL_WinRolledHeight%ROL_WinID% ) 
			Return
	SysGet, ROL_CaptionHeight, 4 ; SM_CYCAPTION
	SysGet, ROL_BorderHeight, 7 ; SM_CXDLGFRAME
	If ( ROL_WinHeight > (ROL_CaptionHeight + ROL_BorderHeight) )
	{
		IfNotInString, ROL_WinIDs, |%ROL_WinID%
			ROL_WinIDs = %ROL_WinIDs%|%ROL_WinID%
		ROL_WinOriginalHeight%ROL_WinID% := ROL_WinHeight
		WinMove, ahk_id %ROL_WinID%, , , , , (ROL_CaptionHeight + ROL_BorderHeight)
		WinGetPos, , , , ROL_WinRolledHeight%ROL_WinID%, ahk_id %ROL_WinID%
	}
Return

ROL_RollDown:
	Gosub, ROL_CheckWinIDs
	SetWinDelay, -1
	If ( !ROL_WinID )
		Return
	IfNotInString, ROL_WinIDs, |%ROL_WinID%
		Return
	WinGetPos, , , , ROL_WinHeight, ahk_id %ROL_WinID%
	If( ROL_WinHeight = ROL_WinRolledHeight%ROL_WinID% )
		WinMove, ahk_id %ROL_WinID%, , , , , ROL_WinOriginalHeight%ROL_WinID%
	StringReplace, ROL_WinIDs, ROL_WinIDs, |%ROL_WinID%, , All
	ROL_WinOriginalHeight%ROL_WinID% =
	ROL_WinRolledHeight%ROL_WinID% =
Return

ROL_RollDownAll:
	Gosub, ROL_CheckWinIDs
	Loop, Parse, ROL_WinIDs, |
		If ( A_LoopField )
		{
			ROL_WinID = %A_LoopField%
			Gosub, ROL_RollDown
		}
Return

#^r::
	Gosub, ROL_RollDownAll
	SYS_ToolTipText = Window Roll: ALL DOWN
	Gosub, SYS_ToolTipFeedbackShow
Return

ROL_CheckWinIDs:
	DetectHiddenWindows, On
	Loop, Parse, ROL_WinIDs, |
		If ( A_LoopField )
			IfWinNotExist, ahk_id %A_LoopField%
			{
				StringReplace, ROL_WinIDs, ROL_WinIDs, |%A_LoopField%, , All
				ROL_WinOriginalHeight%A_LoopField% =
				ROL_WinRolledHeight%A_LoopField% =
			}
Return

ROL_ExitHandler:
	Gosub, ROL_RollDownAll
Return


; [SYS] handles tooltips

SYS_ToolTipShow:
	If ( SYS_ToolTipText )
	{
		If ( !SYS_ToolTipSeconds )
			SYS_ToolTipSeconds = 2
		SYS_ToolTipMillis := SYS_ToolTipSeconds * 1000
		CoordMode, Mouse, Screen
		CoordMode, ToolTip, Screen
		If ( !SYS_ToolTipX or !SYS_ToolTipY )
		{
			MouseGetPos, SYS_ToolTipX, SYS_ToolTipY
			SYS_ToolTipX += 16
			SYS_ToolTipY += 24
		}
		ToolTip, %SYS_ToolTipText%, %SYS_ToolTipX%, %SYS_ToolTipY%
		SetTimer, SYS_ToolTipHandler, %SYS_ToolTipMillis%
	}
	SYS_ToolTipText =NWD_WinClass !=
	SYS_ToolTipSeconds =
	SYS_ToolTipX =
	SYS_ToolTipY =
Return

SYS_ToolTipFeedbackShow:
	If ( SYS_ToolTipFeedback )
		Gosub, SYS_ToolTipShow
	SYS_ToolTipText =
	SYS_ToolTipSeconds =
	SYS_ToolTipX =
	SYS_ToolTipY =
Return

SYS_ToolTipHandler:
	SetTimer, SYS_ToolTipHandler, Off
	ToolTip
Return
; [AOT] toggles always on top

/**
 * Toggles the always-on-top attribute of the selected/active window.
 */
#LButton::
AOT_SetToggle:
	Gosub, AOT_CheckWinIDs
	SetWinDelay, -1
	
	IfInString, A_ThisHotkey, LButton
	{
		MouseGetPos, , , AOT_WinID
		If ( !AOT_WinID )
			Return
		IfWinNotActive, ahk_id %AOT_WinID%
			WinActivate, ahk_id %AOT_WinID%
	}
	
	IfWinActive, A
	{
		WinGet, AOT_WinID, ID
		If ( !AOT_WinID )
			Return
		WinGetClass, AOT_WinClass, ahk_id %AOT_WinID%
		If ( (NWD_WinClass = "Progman") or (NWD_WinClass = "WorkerW")) 
			Return
			
		WinGet, AOT_ExStyle, ExStyle, ahk_id %AOT_WinID%
		If ( AOT_ExStyle & 0x8 ) ; 0x8 is WS_EX_TOPMOST
		{
			SYS_ToolTipText = Always on Top: OFF
			Gosub, AOT_SetOff
		}
		Else
		{
			SYS_ToolTipText = Always on Top: ON
			Gosub, AOT_SetOn
		}
		Gosub, SYS_ToolTipFeedbackShow
	}
Return

AOT_SetOn:
	Gosub, AOT_CheckWinIDs
	SetWinDelay, -1
	IfWinNotExist, ahk_id %AOT_WinID%
		Return
	IfNotInString, AOT_WinIDs, |%AOT_WinID%
		AOT_WinIDs = %AOT_WinIDs%|%AOT_WinID%
	WinSet, AlwaysOnTop, On, ahk_id %AOT_WinID%
Return

AOT_SetOff:
	Gosub, AOT_CheckWinIDs
	SetWinDelay, -1
	IfWinNotExist, ahk_id %AOT_WinID%
		Return
	StringReplace, AOT_WinIDs, AOT_WinIDs, |%A_LoopField%, , All
	WinSet, AlwaysOnTop, Off, ahk_id %AOT_WinID%
Return

AOT_SetAllOff:
	Gosub, AOT_CheckWinIDs
	Loop, Parse, AOT_WinIDs, |
		If ( A_LoopField )
		{
			AOT_WinID = %A_LoopField%
			Gosub, AOT_SetOff
		}
Return

AOT_CheckWinIDs:
	DetectHiddenWindows, On
	Loop, Parse, AOT_WinIDs, |
		If ( A_LoopField )
			IfWinNotExist, ahk_id %A_LoopField%
				StringReplace, AOT_WinIDs, AOT_WinIDs, |%A_LoopField%, , All
Return

AOT_ExitHandler:
	Gosub, AOT_SetAllOff
Return
; [TSW {NWD}] provides alt-tab-menu to the right mouse button + mouse wheel

TSW_WheelHandler:
	GetKeyState, TSW_RButtonState, RButton, P
	If ( TSW_RButtonState = "U" )
	{
		SetTimer, TSW_WheelHandler, Off
		GetKeyState, TSW_LAltState, LAlt
		If ( TSW_LAltState = "D" )
			Send, {LAlt up}
	}
Return

#If
;;;;;The end #IF tag of FnSwitch 0334
;******************************* 滚轮 *******************************
;静音
#If IsCorner("3")=1
MButton::
If (FnSwitch(0301)=0)
return
			;任务栏静音--开始
if A_OSVersion not in WIN_7,WIN_VISTA
{
	SoundSet, +1, , mute
	SoundGet, MUTE_ONOFF, , mute
	If(MUTE_ONOFF="Off")
	{
		SoundGet, Now_Vol
		Now_Vol2:=Show_Vol(Now_Vol)
		ToolTip, 音量 : %Now_Vol2% ％
		SetTimer, RemoveToolTip, 1000
	}
	else
	{
		ToolTip, 静音
		SetTimer, RemoveToolTip, 1000
	}
	return
}
else
{
	Send {Volume_Mute}
	return
}
;任务栏静音--结束
;the end if tag of fn0301
EmptyMem()
return
#If
WheelUp::
	GetKeyState, TSW_RButtonState, RButton, P
	If ( (TSW_RButtonState = "D") and (!NWD_ImmediateDown) and FnSwitch(0563) )
	{
		; TODO : this is a workaround because the original tabmenu 
		; code of AutoHotkey is buggy on some systems
		GetKeyState, TSW_LAltState, LAlt
		If ( TSW_LAltState = "U" )
		{
			Gosub, NWD_SetAllOff
			Send, {LAlt down}+{Tab}
			SetTimer, TSW_WheelHandler, 1
		}
		Else
			Send, +{Tab}
	}
	else
	{
		;3D窗口切换
		If ((IsCorner("4") or MouseIsOver2("ahk_class Button",0.2)) and FnSwitch(0310)=1)
		{
			Gosub,GetInfoUnderMouse
			If (MouseClass<>"Flip3D")
			{
				;send ^#{Tab}
				;run %a_scriptdir%\soft\3d窗口切换.lnk
				run C:\Windows\System32\rundll32.exe DwmApi #105
				send { Up 1 }
			}
			else
				send { Up 1 }
		EmptyMem()
			return
		}
		;音量调节
		If (FnSwitch(0301)=1)
		{
			If IsCorner("3")=1
			{
				;任务栏调高音量--开始
				SoundGet, Now_Vol
				FormatTime, Now_Hr,, H
				FormatTime, Now_HrMin,, H:mm

				;MsgBox,%Now_Hr%
				;;SendInput %CurrentDateTime%
				If (Now_Vol>Vol_Max-2 and (Now_Hr>Vol_Night-1 or Now_Hr<Vol_Morning))
				{
					;if A_OSVersion not in WIN_7,WIN_VISTA
					MsgBox, 262192, WINAssist 音量过高提醒, Now_Vol=%Now_Vol%>Vol_Max=%Vol_Max%-2现在时间 %Now_HrMin% ，请不要将音量开得过大。`n`n如需对此提醒进行设置请按 Ctrl+Alt+Shift+Z 打开设置文件，`n调整底部“用户参数设置”的三个参数`nVol_Morning、Vol_Night 和 Vol_Max。


				}



				if A_OSVersion not in WIN_7,WIN_VISTA
				{
					SoundGet, MUTE_ONOFF, , mute
					If(MUTE_ONOFF="Off")
					SoundSet +1
					else
					{
						SoundSet, 0
						SoundSet, +1, , mute
						SoundSet +1
					}

					SoundGet, Now_Vol,MASTER
					Now_Vol2:=Show_Vol(Now_Vol)
					ToolTip, 音量 : %Now_Vol2% ％
					SetTimer, RemoveToolTip, 1000
				}
				else
				{
					;;;;若果是WIN_7,WIN_VIST
					Send {Volume_Up}
					;MsgBox,Volume_Up
				}

				;任务栏调高音量--结束
				EmptyMem()

				return
			}

		}
		;The end tag of Fn0301



		;标题栏向上滚轮 最大化窗口

		If (FnSwitch(0335)=1)
		{
			if WinActive("ahk_class DV2ControlHost")
			{
				GoSub,DoWU
				return
			}

			;CoordMode, Mouse, Relative
			MouseGetPos,mouse_X,mouse_Y,win_UID,win_ClassNN ;获取指针下窗口的 UID 和 ClassNN以及鼠标指针全屏坐标
			WinGetPos , win_X, win_Y, win_Width, , ahk_id %win_UID%
			WinGetClass,win_Class,ahk_id %win_UID% ;根据 UID 获得窗口类名

			;if WinActive("ahk_id %win_UID%") 
			;	WinGetPos , , , win_Width,,A
			;else
			;	WinGetPos , , , win_Width,,ahk_id %win_UID%
			If (win_Class = "Shell_TrayWnd") ;指针是否在任务栏上
			{
				;;;;;;;If (MouseIsOver("ahk_class Shell_TrayWnd",0.9) and FnSwitch(0301)=1)
				SendEvent,{click,Right}
				;MouseClick , Left
				sleep,500
					;SendEvent,{click,Right}
				;Send,{WheelDown}
			}
			Else
			{
				;msgbox,否在任务栏上win_LeftBorder=%win_LeftBorder%///win_TopBorder=%win_TopBorder%///win_RightBorder=%win_RightBorder%
				If ((mouse_Y <= win_Y+28) &&(mouse_Y >= win_Y)&& (mouse_X >= win_X) && (mouse_X <= win_X+win_Width))
				{
					If ((win_Class = "Progman") or (win_Class = "WorkerW")or (win_Class = "#32768")or (win_Class = "#32770"))
						return
					
					;msgbox,最大化窗口 ;关闭窗口
					;WinGet, wheelfn_maximized , MinMax,ahk_id %UID%
					WinMaximize,ahk_id %win_UID%
					WinSet, AlwaysOnTop, On,  ahk_id %win_UID%
					sleep,100
					WinSet, AlwaysOnTop, Off,  ahk_id %win_UID%
					;msgbox,//////////%wheelfn_maximized%\\\\\\\\\\
					sleep,500
					return

				}
				Else
				{
					GoSub,DoWU
				}
			}
			;CoordMode, Mouse, Screen
				;msgbox,CoordMode--ed
		}
		;The end tag of Fn0335
		else
		{
			GoSub,DoWU
		}
	}
EmptyMem()
;The end tag of Fn0335
Return

;WheelDown::SendMessage, 0x115, 1, 0, %MouseControl%, ahk_id %MouseID%


WheelDown::
GetKeyState, TSW_RButtonState, RButton, P
	If ( (TSW_RButtonState = "D") and (!NWD_ImmediateDown) and FnSwitch(0563) )
	{
		; TODO : this is a workaround because the original tabmenu 
		; code of AutoHotkey is buggy on some systems
		GetKeyState, TSW_LAltState, LAlt
		If ( TSW_LAltState = "U" )
		{
			Gosub, NWD_SetAllOff
			Send, {LAlt down}{Tab}
			SetTimer, TSW_WheelHandler, 1
		}
		Else
			Send, {Tab}
	}
	else
	{
		;3D窗口切换
		If ((IsCorner("4") or MouseIsOver2("ahk_class Button",0.2)) and FnSwitch(0310)=1)
		{
			Gosub,GetInfoUnderMouse
			If (MouseClass<>"Flip3D")
			;	send ^#{Tab}
			;	run %a_scriptdir%\soft\3DSwitchTask.lnk
			run C:\Windows\System32\rundll32.exe DwmApi #105
			else
				send { Down 1 }
		EmptyMem()
			return
		}



		;音量调节
		If (FnSwitch(0301)=1)
		{
			If IsCorner("3")=1
			{
				;任务栏调低音量--开始
				if A_OSVersion not in WIN_7,WIN_VISTA
				{
					SoundGet, MUTE_ONOFF, , mute
					If(MUTE_ONOFF="Off")
						SoundSet -1
					else
						SoundSet, 0

					SoundGet, Now_Vol,MASTER
					Now_Vol2:=Show_Vol(Now_Vol)
					ToolTip, 音量 : %Now_Vol2% ％
					SetTimer, RemoveToolTip, 1000
				}
				else
					Send {Volume_Down}
		EmptyMem()		;任务栏调低音量--结束
				return
			}
		}
		;the end if tag of fn0301



		;标题栏向下滚轮 恢复/最小化窗口
		If (FnSwitch(0336)=1)
		{
			;if WinActive("ahk_class MozillaWindowClass") or WinActive("ahk_class MozillaUIWindowClass")
			;{

			;if MinFx=0
			;{
			;	GoSub,DoWD
			;return
			;}
			;}
			if WinActive("ahk_class DV2ControlHost")
			{
				GoSub,DoWD
				return
			}
			;CoordMode, Mouse, Relative
			MouseGetPos,mouse_X,mouse_Y,win_UID,win_ClassNN ;获取指针下窗口的 UID 和 ClassNN以及鼠标指针全屏坐标
			WinGetPos , win_X, win_Y, win_Width, , ahk_id %win_UID%
			WinGetClass,win_Class,ahk_id %win_UID% ;根据 UID 获得窗口类名

			;if WinActive("ahk_id %win_UID%") 
			;	WinGetPos , , , win_Width,,A
			;else
			;	WinGetPos , , , win_Width,,ahk_id %win_UID%
			If (win_Class = "Shell_TrayWnd") ;指针是否在任务栏上
			{
				;;;;;;;If (MouseIsOver("ahk_class Shell_TrayWnd",0.9) and FnSwitch(0301)=1)



				;msgbox,不调
				send,#m
				sleep,500


				;SendEvent,{click,Right}
				;Send,{WheelDown}

			}
			Else
			{


				;msgbox,否在任务栏上win_LeftBorder=%win_LeftBorder%///win_TopBorder=%win_TopBorder%///win_RightBorder=%win_RightBorder%
				If ((mouse_Y <= win_Y+28) &&(mouse_Y >= win_Y)&& (mouse_X >= win_X) && (mouse_X <= win_X+win_Width))
				{

					If ((win_Class = "Progman") or (win_Class = "WorkerW")or (win_Class = "#32768")or (win_Class = "#32770"))
						return
			
					If (InstantMinimizeWindow_V<>0)
					{
						If (win_Class<>"TXGuiFoundation")
							WinRestore, ahk_id %win_UID%
							;WinMinimize, ahk_id %win_UID%
						else
						{
							WinGetTitle, Temp0 , ahk_id %win_UID%
							If Temp0 contains QQ20,QQ2011,QQ2010,QQ2009,QQ2008,QQ2007
								Send, {CTRLDOWN}{ALTDOWN}z{ALTUP}{CTRLUP}
							else
								;WinMinimize, ahk_id %win_UID%
								WinRestore, ahk_id %win_UID%
						}
					}
					else
					{
						;msgbox,最小化窗口 ;关闭窗口
						;WinMinimize,ahk_id %win_UID%
						WinGet, DAXIAO , MinMax, ahk_id %win_UID%
						if (DAXIAO = "1")
							WinRestore, ahk_id %win_UID%
						else
						{

							If (win_Class<>"TXGuiFoundation")
								;WinMinimize, ahk_id %win_UID%
								WinRestore, ahk_id %win_UID%
							else
							{
								WinGetTitle, Temp0 , ahk_id %win_UID%
									If Temp0 contains QQ20
									Send, {CTRLDOWN}{ALTDOWN}z{ALTUP}{CTRLUP}
								else
									;WinMinimize, ahk_id %win_UID%
									WinRestore, ahk_id %win_UID%
							}
						}

						;MouseGetPos,,,UID
						;msgbox,action最小化%UID%
						;msgbox,%UID%
					}
					sleep,500
					return
				}
				Else
				{
					GoSub,DoWD
				}
			}
			;CoordMode, Mouse, Screen
				;msgbox,CoordMode--ed
		}
		;the end if tag of fn0336
		else
		{
			GoSub,DoWD
		}
	}
EmptyMem()
;the end if tag of fn0336
Return

;#If !(WinActive("ahk_class CabinetWClass") or WinActive("ahk_class IEFrame") or WinActive("ahk_class Progman") or WinActive("ahk_class WorkerW") or WinActive("ahk_class ExploreWClass") or WinActive("ahk_class MozillaWindowClass") or WinActive("ahk_class MozillaUIWindowClass")or WinActive("ahk_class MozillaWindowClass") or WinActive("ahk_class MozillaUIWindowClass"))

;#If
;MButton Up::MouseClick,M, , , , , UNWD_WinClass !=
MButton Up::
MButtonUpAction:
	MouseGetPos, , , NWD_WinID
	WinGetClass,NWD_WinClass,ahk_id %NWD_WinID%
	/*
	tooltip %NWD_WinClass%
	sleep 1000
	tooltip
	*/
	If (NWD_WinClass != "WorkerW" and NWD_WinClass !="Shell_TrayWnd" and NWD_WinClass !="Button" and NWD_WinClass != "TaskListThumbnailWnd" and NWD_WinClass !="DV2ControlHost") 
	{
		WinGet, MIW_WinStyle, Style, ahk_id %NWD_WinID%
		SysGet, MIW_CaptionHeight, 4 ; SM_CYCAPTION
		SysGet, MIW_BorderHeight, 7 ; SM_CXDLGFRAME
		MouseGetPos, , MIW_MouseY

		If ( MIW_MouseY <= MIW_CaptionHeight + MIW_BorderHeight )
		{
			; checks wheter the window has a sizing border (WS_THICKFRAME)
				Gosub, NWD_SetAllOff
				ROL_WinID = %NWD_WinID%
				Gosub, ROL_RollToggle
		}
		Else
		{
			; the second condition checks for minimizable window:
			; (WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX)
				Gosub, NWD_SetAllOff
				WinMinimize, ahk_id %NWD_WinID%
				SYS_ToolTipText = Window Minimize
				Gosub, SYS_ToolTipFeedbackShow
		}
	}
	Else
	{
		; this feature should be implemented by using a timer because 
		; AutoHotkeys threading blocks the first thread if another 
		; one is started (until the 2nd is stopped)
		
		;Thread, priority, 1
		;MouseClick, m, , , , , D
		;KeyWait, mButton
		MouseClick, m, , , , , U
	}
Return


;向上滚滚轮
DoWU:
{
	If (FnSwitch(0340)=0)
	{
		Send,{WheelUp}
		return
	}
	Gosub,GetInfoUnderMouse

	If(MouseID=ActID  and MouseClass<>"CabinetWClass" and MouseClass<>"HH Parent")
	{
		Send,{WheelUp}
		return
	}

	If MouseClass contains  Photo_Lightweight_Viewer,OpusApp,XLMAIN,PP12FrameClass,rctrl_renwnd32,%WheelList%
	{
		;msgbox,contains %MouseClass%
		WinActivate, ahk_id %MouseID%
		Send,{WheelUp}
		;SendMessage, 0x115, 0, 0, %MouseControl%, ahk_id %MouseID%
	}
	else
	{	
		If MouseControl contains DirectUIHWND,ToolbarWindow,RebarWindow
		MouseControl=ScrollBar2
		Loop %WheelSpeed%{
			SendMessage, 0x115, 0, 0, %MouseControl%, ahk_id %MouseID%
		}		
	}
}
Return


DoWD:
{
	If (FnSwitch(0340)=0)
	{
		Send,{WheelDown}
		return
	}
	Gosub,GetInfoUnderMouse

	If(MouseID=ActID and MouseClass<>"CabinetWClass" and MouseClass<>"HH Parent")
	{
		Send,{WheelDown}
		return
	}

	If MouseClass contains Photo_Lightweight_Viewer,OpusApp,XLMAIN,PP12FrameClass,rctrl_renwnd32,%WheelList%
	{
		WinActivate, ahk_id %MouseID%
		Send,{WheelDown}
	}
	else
	{	
		If MouseControl contains DirectUIHWND,ToolbarWindow,RebarWindow
		MouseControl=ScrollBar2

		;msgbox,MouseID=%MouseID%   MouseControl=%MouseControl%
		Loop %WheelSpeed%{
			SendMessage, 0x115, 1, 0, %MouseControl%, ahk_id %MouseID%
		}		
	}
}
Return


;******************************* 滚轮 *******************************
;******************************* everything *******************************
#If (FnSwitch(0304)=1)
^+f::send ^f
$^f::
;if WinActive("ahk_class CabinetWClass")
if (WinActive("ahk_class CabinetWClass") or WinActive("ahk_class ExploreWClass"))
	GoSub,SuperFind
else
	send ^f
EmptyMem()
return
#If
;;;;;The end #IF tag of FnSwitch 0304


#If (FnSwitch(0204)=1)
#Space::GoSub,Switch_Evethg
#If
;;;;;The end #IF tag of FnSwitch 0204


#If (FnSwitch(0203)=1)
$#f::GoSub,SuperFind
#If
;;;;;The end #IF tag of FnSwitch 0203


SuperFind:
;if WinActive("ahk_class CabinetWClass")
if (WinActive("ahk_class CabinetWClass") or WinActive("ahk_class ExploreWClass"))
{
;;;;msgbox,11111
WinWaitActive
	ControlGetText, FilePath, Edit1, A
	;;msgbox, %FilePath%
	;;;;;;;;stringreplace, FilePath, FilePath, 地址:%A_space%, , All	
	if (FilePath="桌面") or WinActive("ahk_class Progman")or WinActive("ahk_class WorkerW")
		FilePath=%A_Desktop%
	if FilePath in 我的文档,库
		FilePath=%A_MyDocuments%
	if FilePath in 我的电脑,计算机,网上邻居,控制面板,回收站,控制面板,我们的电脑
	{
	;;;;msgbox,2222
		GoSub,Switch_Evethg
		sleep 20
		IfWinExist ahk_class EVERYTHING
		{
		;;;msgbox,333333
		WinActivate
		WinWaitActive, Everything
		ControlSetText, Edit1, , ahk_class EVERYTHING
		}
		else
		;;;msgbox,44444
		;;;;send,#f
		return
	}	
	GoSub,Switch_Evethg
	sleep 20
	IfWinExist ahk_class EVERYTHING
	{
	;;;msgbox,555555555
	WinActivate
	WinWaitActive, Everything
	;;;msgbox,OK
	ControlSetText, Edit1, "%FilePath%"%A_space%, ahk_class EVERYTHING
	sleep 20
	send {end}
	}
	;;;;;;;;;;;;;;;;;;;;;若在资源管理器中，但不存在evth
	else
		send,^f
}
;;;;;;;;;;;;;;;;;;;;;若不在资源管理器中
else
{

		GoSub,Switch_Evethg
		sleep 20
		IfWinExist ahk_class EVERYTHING
		{
		WinActivate
		WinWaitActive, Everything
		ControlSetText, Edit1, , ahk_class EVERYTHING
		}
	;else
		;send,^f



}
return




Switch_Evethg:

	send #^+!P
	WinActivate
	sleep,150
	if WinActive("ahk_class EVERYTHING")
	WinMaximize, ahk_class EVERYTHING
	;;msgbox,ET2222222222
return

;******************************* everything *******************************

;******************************* screenlock 白领们的小助手：老板键、视力保护、锁屏三合一软件  *******************************
 ;隐藏
win_hide_show:
if (win_hide_show_v=1)
{
	SetTitleMatchMode, 2
	WinGet, id, list,,, Program Manager ;任务管理器
	if hidewindow=""
		return
	Loop, %id%
	{
		this_id := id%A_Index%
		WinGetTitle, this_title, ahk_id %this_id%
		WinGetClass,this_class,ahk_id %this_id%
		;tooltip, %this_class% %hidewindow% ...
		;SetTimer, RemoveToolTip, 5000
		;sleep 5000
		if this_class in %hidewindow% 
		{
			WinHide, %this_title%
			FileAppend, %this_title%`n, temp.txt
		}
	}
	win_hide_show_v=0
	EmptyMem()
	Return
}
else{
	SetTitleMatchMode, 2
	DetectHiddenWindows, On
	Loop, 20
	{
		FileReadLine, title, temp.txt, %A_Index%
		WinShow, %title%
	}
	FileDelete, temp.txt
	win_hide_show_v=1
	EmptyMem()
	Return
}

setPassword:
   InputBox, new_key, password, , HIDE, 130, 100
   if NOT ErrorLevel
   {
      IniWrite, %new_key%,%a_scriptdir%\%applicationname%.ini, lock, key
      key := new_key
   }
return

setAutoLock:
   InputBox, new_idle, the idle time(minutes), , , 240, 100
   if NOT ErrorLevel
   {
      IniWrite, %new_idle%,%a_scriptdir%\%applicationname%.ini, lock, idle
      idle := new_idle
   }
return

start:
; bolckinput好像不好使
   ; BlockInput, on  ;禁止键盘和鼠标输入
   ; 按win还是会呼出开始菜单
   GoSub inputoff
   SetTimer, CheckIdle, Off
   SystemCursor(0)
   if ( interface = 1 )
   {
      Gui, 4:+AlwaysOnTop +Disabled -SysMenu +Owner -Caption +ToolWindow
      if ( if_fullscreen = 1 )
      {
         ww := A_ScreenWidth // 2 - 65
         hh := A_Screenheight // 2 - 15
         Gui, 4:Add, text, x%ww% y%hh%, %L_enterpw1%`n%L_enterpw2%
         CustomColor = 999A9B
         Gui, 4:Color, %CustomColor%
         Gui, 4:Show, Maximize
      }
      else
      {
         Gui, 4:Add, text, , %L_enterpw1%`n%L_enterpw2%
         CustomColor = 999A9B
         Gui, 4:Color, %CustomColor%
         Gui, 4:Show
      }
   }
   if ( interface = 2 )
   {
      Gui, 4:+AlwaysOnTop +Disabled -SysMenu +Owner -Caption +ToolWindow
      if ( if_fullscreen = 1 )
      {
         Gui, 4:margin, 0,0
         Gui, 4:Add, Picture, x0 y0 w%A_ScreenWidth% h%A_ScreenHeight%, %A_ScriptDir%\icon\lock.jpg
         CustomColor = EE0000
         Gui, 4:Color, %CustomColor%
         Gui, 4:Show, Maximize
      }
      else
      {
         Gui, 4:Add, Picture, w300 h-1, %A_ScriptDir%\icon\lock.jpg
         CustomColor = EE0000
         Gui, 4:Color, %CustomColor%
         Gui, 4:Show
      }
   }
   if ( if_turnoff_monitor = 1 )
   {
      SetTimer, TurnoffMonitor, 3000 
      StringRight, H_key, hotkey, 1
      KeyWait %H_key%
      KeyWait LWin
      KeyWait RWin
      KeyWait Shift
      KeyWait Control
      KeyWait Alt
      ;Power off the screen
      SendMessage, 0x112, 0xF170, 2,,ahk_id 0xFFFF
   }
   if ( if_mute = 1 and if_sleep_time = 0 )
   {
	   /*
	SoundGet, MUTE_ONOFF, , mute  ;SoundGet 在WIN_7下有问题，设置autohotkey兼容模式
	If(MUTE_ONOFF="OFF")
	{
		 Send {Volume_Mute}
	}
	*/ 
	Send {Volume_Down 50}
   }
gosub startunlock
; BlockInput, off  ;禁止键盘和鼠标输入
GoSub inputon
return

startunlock:
   i:=1
   Loop
   {
      Input, a, L1
      StringLeft, temp, key, %i%
      StringRight, temp, temp, 1
      if a=%temp%
      {
         i++
      }else{
         i:=1
      }
      if (i=(strlen(key)+1))
      {
         if ( interface = 1 )
         {
            Gui,4:Destroy
            if ( if_fullscreen = 1 )
            {
            }
            else
            {
               Gui, 4:+AlwaysOnTop +Disabled -SysMenu +Owner -Caption +ToolWindow
               Gui, 4:Add, text, , %L_unlock%
               CustomColor = 999A9B
               Gui, 4:Color, %CustomColor%
               Gui, 4:Show
               sleep, 300
               Gui, 4:Destroy
            }
         }
         if ( interface = 2 )
         {
            Gui, 4:Destroy
            if ( if_fullscreen = 1 )
            {
            }
            else
            {
               Gui, 4:+AlwaysOnTop +Disabled -SysMenu +Owner -Caption +ToolWindow
               Gui, 4:Add, Picture, w300 h-1, %A_ScriptDir%\icon\lock.jpg
               CustomColor = 00EE00
               Gui, 4:Color, %CustomColor%
               Gui, 4:Show
               sleep, 300
               Gui, 4:Destroy
            }
         }
         if ( if_turnoff_monitor = 1 )
         {
            SetTimer, TurnoffMonitor, off 
         }
        /*
		 if ( if_mute = 1 )
         {
            ;Send {Volume_Mute}
         }
		 */
         SystemCursor(1)

		 if_sleep_time=0
		starttime:=A_now ;锁屏后强制休息时间重新开始计时
		temptime:=starttime
		temptime+=worktime,Minutes
		formattime,showtime,%temptime%,time
		menutipshow=%Full_todolist%电脑将在%showtime%强制休息
		menu,tray,Tip,%menutipshow%  ;鼠标经过图标时将显示休息时间
;			menu,tray,Tip,电脑将在%showtime%强制休息
		temptime+=-1,Minutes
         SetTimer, CheckIdle, On

         break
      }
   }
EmptyMem()   
return

inputoff:
; 禁用热键及一些功能键
	suspend on
	BlockInput, MouseMove

	; 和suspend有冲突
	; Hotkey, Lbutton, stop, on
	; Hotkey, Rbutton, stop, on
	; Hotkey, Mbutton, stop, on
	; Hotkey, LWin, stop, on
	; Hotkey, Rwin, stop, on
	; Hotkey, LAlt, stop, on
	; Hotkey, RAlt, stop, on
	; Hotkey, Ctrl, stop, on
	; Hotkey, esc, stop, on
	; Hotkey, del, stop, on
	; Hotkey, f1, stop, on
	; Hotkey, f4, stop, on
	; Hotkey, tab, stop, on
return

inputon:
; 启用热键及一些功能键
	suspend off
	blockinput, mousemoveoff

	; hotkey, lbutton, stop, off
	; hotkey, rbutton, stop, off
	; hotkey, mbutton, stop, off
	; hotkey, lwin, stop, off
	; hotkey, rwin, stop, off
	; hotkey, lalt, stop, off
	; hotkey, ralt, stop, off
	; Hotkey, Ctrl, stop, off
	; Hotkey, esc, stop, off
	; Hotkey, del, stop, off
	; Hotkey, f1, stop, off
	; Hotkey, f4, stop, off
	; Hotkey, tab, stop, off
return

stop:
return

setFullscreen:
   if ( if_fullscreen = 1 )
   {
      if_fullscreen = 0
      Menu, interface, UnCheck, %L_fullscreen%
   }
   else
   {
      if_fullscreen = 1
      Menu, interface, Check, %L_fullscreen%
   }
   IniWrite, %if_fullscreen%,%a_scriptdir%\%applicationname%.ini, lock, if_fullscreen
return

setTurnoffMonitor:
   if ( if_turnoff_monitor = 1 )
   {
      if_turnoff_monitor = 0
      Menu, interface, UnCheck, %L_screenoff%
   }
   else
   {
      if_turnoff_monitor = 1
      Menu, interface, Check, %L_screenoff%
   }
   IniWrite, %if_turnoff_monitor%,%a_scriptdir%\%applicationname%.ini, lock, if_turnoff_monitor
return

setMute:
   if ( if_mute = 1 )
   {
      if_mute= 0
      Menu, interface, UnCheck, %L_mute%
   }
   else
   {
      if_mute= 1
      Menu, interface, Check, %L_mute%
   }
   IniWrite, %if_mute%,%a_scriptdir%\%applicationname%.ini, lock, if_mute
return
setDirectLock:
   if ( direct_lock = 1 )
   {
      direct_lock = 0
      Menu, setting, UnCheck, %L_direct_lock%
   }
   else
   {
      direct_lock = 1
      Menu, setting, Check, %L_direct_lock%
   }
   IniWrite, %direct_lock%,%a_scriptdir%\%applicationname%.ini, lock, direct_lock
return

setLang:
      L_english := "English"
      L_simple := "Simple Chinese"
      L_traditional := "Triditional Chinese"
      L_lock     := "锁定"
      L_password := "密码"
      L_autolock := "自动锁定"
      L_hotkey   := "快捷键"
      L_direct_lock := "启动时锁定"
      L_setting  := "设置"
      L_language := "语言"
      L_interface:= "界面"
      L_autolocktime := "空闲时间（分钟）"
      L_enterpw1  := "你已经锁定键盘与鼠标"
      L_enterpw2  := "请输入正确的密码解锁"
      L_unlock   := "已解锁"
      L_invalid_hotkey := "无效的快捷键!"
      L_interface1 := "1"
      L_interface2 := "2"
      L_interface3 := "3"
      L_fullscreen := "全屏显示"
      L_screenoff := "关闭屏幕"
	  L_mute :="静音"
return

interface1:
   interface = 1
   IniWrite, 1,%a_scriptdir%\%applicationname%.ini, lock, interface
   Menu, setting, DeleteAll
   Menu, interface, DeleteAll
   ;Gosub makeMenu
   Gosub makescreenlockmenu
return

interface2:
   interface = 2
   IniWrite, 2,%a_scriptdir%\%applicationname%.ini, lock, interface
   Menu, setting, DeleteAll
   Menu, interface, DeleteAll
   ;Gosub makeMenu
   Gosub makescreenlockmenu
return

interface3:
   interface = 3
   IniWrite, 3,%a_scriptdir%\%applicationname%.ini, lock, interface
   Menu, setting, DeleteAll
   Menu, interface, DeleteAll
   ;Gosub makeMenu
   Gosub makescreenlockmenu
return

CheckIdle:
;msgbox,%temptime%
   if ( idle > 0 )
   {
      idleTime:=idle*60*1000
      if ( A_TimeIdle >= idleTime )
      {
         Gosub start
      }
   }
  
     if temptime<%A_now%
   {
  ; msgbox,,提醒,一分钟后将强制休息，请作好准备！,60
  ; ToolTip, 提醒,一分钟后将强制休息，请作好准备！
  ; SetTimer, RemoveToolTip, 1000

	; gui,1:-caption +alwaysontop +owner ;去标题栏
	; gui,1:margin,0,0 ;去边距
	; gui,1:color, 800080  
	; gui,1:font,s16 cwhite,Arial
	; Gui,1:Add, Text,, 提醒,一分钟后将强制休息，请作好准备!
	; gui,1:show
	; sleep,1000
	; gui,1:Destroy
   TrayTip, 现在时间: %A_YYYY%-%A_MM%-%A_DD% %A_Hour%:%A_Min% %A_DDDD%,`n%Full_todolist% `n提醒， 一分钟后将强制休息，请作好准备! ,30,1 
   sleep,60000
   Gosub gosleep
   }
   
  if ( A_TimeIdle >= 300000 )
  {				;无操作5分钟后重新计算强制休息时间
	starttime:=A_now
	temptime:=starttime
	temptime+=worktime,Minutes
	formattime,showtime,%temptime%,time
;	menu,tray,Tip,电脑将在%showtime%强制休息
	menutipshow=%Full_todolist%电脑将在%showtime%强制休息
	menu,tray,Tip,%menutipshow%  ;鼠标经过图标时将显示休息时间
	temptime+=-1,Minutes
  }
return

changeHotkey:
   StringLeft, old_Win, hotkey, 1 
   StringTrimLeft, old_Hotkey, hotkey, 1 
   Gui, 4:-SysMenu
   if (old_Win = "#")
   {
      Gui, 4:Add, Hotkey,   vHK, %old_Hotkey%     ;add a hotkey control
      Gui, 4:Add, CheckBox, vCB x+5 hp Checked, Win  ;add a checkbox to allow the Windows key (#) as a modifier.
   }
   else
   {
      Gui, 4:Add, Hotkey,   vHK, %hotkey%     ;add a hotkey control
      Gui, 4:Add, CheckBox, vCB x+5 hp , Win  ;add a checkbox to allow the Windows key (#) as a modifier.
   }
   Gui, 4:Add, Button, default ys, OK  
   Gui, 4:Add, Button, ys, Cancel  
   Gui, 4:Show,,hotkey
return

4ButtonOK:
   Gui, 4:Submit, NoHide
   If CB                                  ;If the 'Win' box is checked, then add its modifier (#).
   {
      HK := "#" HK
   }
   FoundPos := RegExMatch(HK, "^[#\+\^!]+\w$")
   if ( FoundPos = 1 )
   {
      Hotkey, %hotkey%, start, off
      hotkey := HK
      Hotkey, %hotkey%, start, on
      IniWrite, %hotkey%,%a_scriptdir%\%applicationname%.ini, lock, hotkey
   }
   else
   {
      MsgBox, %L_invalid_hotkey%
   }
   Gui, 4:Destroy
return

4ButtonCancel:
   Gui, 4:Submit, NoHide
   Gui, 4:Destroy
return
TurnoffMonitor:
      if ( A_TimeIdle >= 300000 )
      {
         ;Power off the screen
         SendMessage, 0x112, 0xF170, 2,,ahk_id 0xFFFF
      }
return

gosleep:   ;锁屏休息
; BlockInput, on  ;禁止键盘和鼠标输入
GoSub inputoff
SetTimer, CheckIdle, Off
screenLockBGColor := "21AABD"
MyProgressBGColor := "04477c"
MyProgressColor := "70e1ff"

Gui, 4:+LastFound +AlwaysOnTop +Disabled -SysMenu +Owner -Caption +ToolWindow
Gui, 4:margin, 0,0
Gui, 4:Add, Picture, x0 y0 w%A_ScreenWidth% h%A_ScreenHeight%, %A_ScriptDir%\icon\lock.jpg

xx:=(A_ScreenWidth-400)/2
yy:=A_ScreenHeight/2
Gui, 4:Add, Progress, x%xx% y%yy% vMyProgress w400 c%MyProgressColor% background%MyProgressBGColor% 
; Gui, 4:Add, Progress, x%xx% y%yy% vMyProgress w400 -smooth
gui, 4:font, s18 bold, Verdana 
Gui, 4:Add, text, vMytext w400 h60 +Center BackgroundTrans,  `n你工作很久了,请休息休息!!!
Gui, 4:Color, %screenLockBGColor%
Gui, 4:Show, Maximize
		 
gosub ButtonStartTheBarMoving

GuiControl, 4:hide, MyProgress
GuiControl, 4:hide, Mytext

if_sleep_time=1
; gosub start   ;强制休息完后调用锁屏
gosub startunlock

; BlockInput, off  ;允许键盘和鼠标输入 
GoSub inputon
return

ButtonStartTheBarMoving:  ;滑动条
Loop  
{
if (A_Index > relaxtime*60) ;强制休息时间
break
last:=100-A_Index*100/(relaxtime*60)
;msgbox,%last%
GuiControl,4:, MyProgress, %last%
Sleep 1000
}
return
;******************************* screenlock 白领们的小助手：老板键、视力保护、锁屏三合一软件  *******************************

;******************************* 便捷搜索  *******************************
#If (FnSwitch(0338)=1)
$F3::
User_Content=%Clipboard%
Clipboard=
sleep,100
send,^c
;;ClipWait,3
;;;;;;;;;;;;Keywords=%clipboard%
If (Clipboard<>"")
{
StringLeft, Left4, Clipboard, 4
;StringRight, Right4, Clipboard, 4
;StringRight, Right3, Clipboard, 3
;or Right4=".com"  or Right4=".COM" or Right4="com/" or Right4="COM/" or Right4=".net" or Right4=".NET" or Right4="net/" or Right4="NET/" or Right4=".org" or Right4=".ORG" or Right4="org/" or Right4="ORG/"  or Right3=".cn"  or Right3=".CN" or Right3="cn/" or Right3="CN/" 
If (Left4="http" or Left4="www." or Left4="Http" or Left4="HTTP" or Left4="WWW." or Left4="Www.")
{
	run,%Clipboard%
	return
} 

If (SEID=1)
	Google_Fuck_GFW("HK")
else if (SEID=2)
	Google_Fuck_GFW("INTL")
else if (SEID=3)
	run,http://www.baidu.com/s?wd=%clipboard%
else
	Google_Fuck_GFW("HK")
}
else
send,{F3}
Clipboard=%User_Content%
;Keywords=""
EmptyMem()
return

$+F3::
User_Content=%Clipboard%
Clipboard=
sleep,100
send,^c
;;ClipWait,3
;;;;;;;;;;;;Keywords=%clipboard%
If (Clipboard<>"")
{

If (SEID2=3)
	run,http://www.baidu.com/s?wd=%clipboard%
else if (SEID2=2)
	Google_Fuck_GFW("INTL")
else if (SEID2=1)	
	Google_Fuck_GFW("HK")
else
	run,http://www.baidu.com/s?wd=%clipboard%
}
else
send,+{F3}
Clipboard=%User_Content%
;Keywords=""
EmptyMem()
return
#If
;The end tag of Fn0338

;******************************* 便捷搜索  *******************************

;******************************* 虚拟桌面  *******************************
; ***** hotkeys *****
if(FnSwitch(0560)=1)
{
#MaxThreadsPerHotkey 6
	!1::SwitchToDesktop(1)
	!2::SwitchToDesktop(2)
	!3::SwitchToDesktop(3)
	!4::SwitchToDesktop(4)
#MaxThreadsPerHotkey 1
	^!1::SendActiveToDesktop(1)
	^!2::SendActiveToDesktop(2)
	^!3::SendActiveToDesktop(3)
	^!4::SendActiveToDesktop(4)
}
;;;;;;;;;;
showalldesktops:
; show all windows from all desktops
Loop, %numDesktops%
   ShowHideWindows(A_Index, true)
return

;******************************* 虚拟桌面  *******************************
;*******************************  在当前位置打开cmd  *******************************
;http://www.autohotkey.com/forum/topic76985.html
#c::
;Ifwinactive, ahk_class CabinetWClass ; CabinetWClass is for Explorer window in Win 7 - This is different in XP.
if WinActive("ahk_class CabinetWClass")
{
ControlGetText, Address, ToolbarWindow322, A ; Edit1 doesn't work because that value is only updated when you actually click on the addressbar. The control ToolbarWindow322 contains the text "Address: Path" So the next two lines extract the path. This is Different in XP - May need to be changed.
Pos := InStr(Address,A_Space) ; Find the position of the space before the path.
Dir := SubStr(Address, Pos) ; Returns only the path
;~ msgbox % Dir ; Used in testing
Run, cmd /s /K "pushd %Dir%" ; Open cmd window at that location      改为了cd /d
}
else if WinActive("ahk_class WorkerW")
{
	; run, cmd /s /k "cd /d %A_Desktop%"
	run, cmd /s /k "pushd %A_Desktop%"
}
EmptyMem()
return
;*******************************  在当前位置打开cmd  *******************************
;******************************* 天气预报 *******************************
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Functions;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 判断是否闰年
Syear(year) {
	if( !mod(year, 400) or !mod(year, 4) and mod(year, 100)) 
		return 1
	return 0
}

; 获取下一天的日期
nextDate(ByRef year,ByRef month,ByRef day) {
	days := Object(1,31,2,28,3,31,4,30,5,31,6,30,7,31,8,31,9,30,10,31,11,30,12,31)
	IncMonth := 0
	IncYear := 0 
	MaxMonth := 12
	if( Syear(year) and month == 2 ) 
		MaxDay := 29
	else	
		MaxDay := days[month]
	IncMonth := day // MaxDay
	day := mod((day + 1), MaxDay)
	if(day == 0) 
		day := MaxDay
	IncYear := (month + IncMonth) // MaxMonth
	month := mod((month + IncMonth), 12)
	if(month == 0) 
		month := 12
	year += IncYear
}	
; 根据ip获取id
getCityID()
{
	idResult := URLDownloadToVar("http://61.4.185.48:81/g/")
	if RegExMatch(idResult, "var id=(\d*)", idResult)
	{
		Return idResult1
	}
	return 0
}
; 检测网络连接
InternetCheckConnection(Url="",FIFC=1) { 
	if %A_IsUnicode%
		Return DllCall("Wininet.dll\InternetCheckConnectionW", Str,Url, Int,FIFC, Int,0) 
	else 
		Return DllCall("Wininet.dll\InternetCheckConnectionA", Str,Url, Int,FIFC, Int,0) 
}
; 设置City ID
; WF_data: json内容
; s: 解析的路径,最后一个[]前的部分
; return: 返回城市列表
SelectArea(ByRef WF_data,s){
	WF_CityList := "--"
	loop
	{
		WF_temp := json(WF_data,s . "[" . a_index-1 . "].name")
		
		if (WF_temp == "")
		{ 
			break
		}
		if (a_index == 1)
		{
			WF_CityList := WF_temp
		}
		else {
			WF_CityList := WF_CityList . "|" . WF_temp
		}
	}
	return WF_CityList
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Labels;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 菜单
makeWeatherMenu:
Menu, weatherForecast, Add, 自动获取ID, toggleAutoGetId
Menu, weatherForecast, Add, 设置ID, setCityID 
Menu, weatherForecast, Add, 设置显示延时, setDelay
Menu, weatherForecast, Add, 显示的天数, setShowDayCount 
menu, weatherForecast, add, 更新天气数据, updateWeatherInfo
menu, tray , add , 天气预报,:weatherForecast
return

; 设置显示天气延时
setDelay:
InputBox, new_var, 请输入显示延时, , , 240, 100
   if NOT ErrorLevel
   {
       delay := new_var
	   if ( delay <= 0 or delay > 5000 or delay/500 == 0)
		{
			delay := 2000
			Iniwrite,%delay%,%a_scriptdir%\%applicationname%.ini,weatherSettings, delay
		}
	   iniwrite,%delay%,%a_scriptdir%\%applicationname%.ini,weatherSettings,delay
   }
return
; 设置显示天数
setShowDayCount:
   InputBox, new_var, 请输入要显示的天数（1~6天）, , , 240, 100
   if NOT ErrorLevel
   {
		if(new_var < 1 or new_var >6)
			new_var = 3
      IniWrite, %new_var%, %a_scriptdir%\%applicationname%.ini, weatherSettings, showDayCount
      showDayCount := new_var
	  Gosub getWeatherForecast
   }
return
; 自动获取城市ID开关
toggleAutoGetId:
    if %autoGetCityId%
    {
        autoGetCityId = 0
        Menu, weatherForecast, unCheck, 自动获取ID
		menu, weatherForecast, enable, 设置ID
    }
    else
    {
        autoGetCityId = 1
        Menu, weatherForecast, Check, 自动获取ID
		menu, weatherForecast, disable, 设置ID
		WF_CityID := getCityID()
		iniwrite,%WF_CityID%,%a_scriptdir%\%applicationname%.ini,weatherSettings,cityID
		Gosub getWeatherForecast
    }
	iniwrite,%autoGetCityId%,%a_scriptdir%\%applicationname%.ini,weatherSettings, autoGetCityId
Return
; 更新天气信息 并显示
updateWeatherInfo:
GoSub getWeatherForecast
GoSub showWeatherForecast
Return
; 读配置文件
weatherINIREAD:
IfNotExist,%a_scriptdir%\%applicationname%.ini
{
	autoGetCityId := 1 
	showDayCount := 3
	WF_CityID := getCityID()
	delay := 2000
	Gosub,weatherINIWRITE
	return
}
IniRead,autoGetCityId,%a_scriptdir%\%applicationname%.ini,weatherSettings, autoGetCityId
if(autoGetCityId == 1)
{
	WF_CityID := getCityID()
	iniwrite,%WF_CityID%,%a_scriptdir%\%applicationname%.ini,weatherSettings,cityID
}
else
	IniRead,WF_CityID,%a_scriptdir%\%applicationname%.ini,weatherSettings,cityID
IniRead,showDayCount,%a_scriptdir%\%applicationname%.ini,weatherSettings,showDayCount
if ( showDayCount < 1 or showDayCount > 6)
{
	showDayCount := 3
	Iniwrite,%showDayCount%,%a_scriptdir%\%applicationname%.ini,weatherSettings,showDayCount
}
IniRead,delay,%a_scriptdir%\%applicationname%.ini,weatherSettings,delay
if ( delay <= 0 or delay > 5000 or delay/1000 == 0)
{
	delay := 2000
	Iniwrite,%delay%,%a_scriptdir%\%applicationname%.ini,weatherSettings, delay
}
if %autoGetCityId%
{
	Menu, weatherForecast, Check, 自动获取ID
	menu, weatherForecast, disable, 设置ID
}
Return
; 写配置文件
weatherINIWRITE:
iniwrite,%autoGetCityId%,%a_scriptdir%\%applicationname%.ini,weatherSettings, autoGetCityId
iniwrite,%WF_CityID%,%a_scriptdir%\%applicationname%.ini,weatherSettings,cityID
Iniwrite,%showDayCount%,%a_scriptdir%\%applicationname%.ini,weatherSettings,showDayCount
Iniwrite,%delay%,%a_scriptdir%\%applicationname%.ini,weatherSettings, delay
Return

; 获取天气预报信息
getWeatherForecast:
if(WF_CityID == 0)
{
	WF_CityID := getCityID()
	if(WF_CityID == 0)
		return
	else
		iniwrite,%WF_CityID%,%a_scriptdir%\%applicationname%.ini,weatherSettings,cityID
}
; 获取 json 格式的天气预报
; http://jerryqiu.iteye.com/blog/1106241
; http://www.dream798.com/default.php?page=Display_Info&id=297
; http://service.weather.com.cn/plugin/forcast.shtml?id=pn11#
; for utf-8
; weatherResult := URLDownloadToVar("http://m.weather.com.cn/data/" . WF_CityID . ".html","UTF-8")
weatherResult := URLDownloadToVar("http://m.weather.com.cn/data/" . WF_CityID . ".html")
; 失败
if ( weatherResult == 0)
{
	return
}
weatherInfoUpdate = 1

; 转码
; UTF82Ansi 函数见 http://ahk.5d6d.com/thread-1123-1-1.html
if A_IsUnicode != 1
{
	weatherResult := UTF82Ansi(weatherResult)
}
; 用 json 提取数据, 和 javascript 类似
city := json(weatherResult, "weatherinfo.city")
city_en := json(weatherResult, "weatherinfo.city_en")
date_y := json(weatherResult, "weatherinfo.date_y")
week := json(weatherResult, "weatherinfo.week")
Date_year := a_yyyy
; 不能有0
FormatTime, Date_day, DD, d
FormatTime, Date_month, MM, M
; Date_month := a_mm
; Date_day := a_dd
showWeather := ""
loop, %showDayCount%
{
	weather := json(weatherResult, "weatherinfo.weather" . a_index)
	temp := json(weatherResult, "weatherinfo.temp" . a_index)
	showWeather .= Date_month . "." . Date_day . "(" . weeks[mod(key++, 7)] . ")" . ": " . json(weatherResult, "weatherinfo.weather" . a_index) . " " . json(weatherResult, "weatherinfo.temp" . a_index) 
	if ( a_index < showDayCount)
	{
		showWeather .=  "`n"
		nextDate(Date_year, Date_month, Date_day)
	}
}
if (initWeatherInfo == 0 and city <> "")
{
	GoSub showWeatherForecast
	initWeatherInfo = 1
}
Return



#w::
; 输出
showWeatherForecast:
; 还没有获取天气信息
; city 为空说明 getWeatherForecast 未正常执行完，否则显示
if (city == "")
{
	; http://www.autohotkey.com/community/viewtopic.php?t=22293
	; 可以联网
	If InternetCheckConnection("http://www.weather.com.cn") 
	{
		Gosub getWeatherForecast
	}
	else 
	{
		ToolTip, 请检查网络连接是否正确!
		Sleep, 2000
		ToolTip
		Return 
	}
}
else 
{
	ToolTip, % city  "(" city_en ")" "`n"  date_y "	"  week "`n" showWeather
	Sleep, %delay%
	ToolTip
	Return
}
return

; 设置City ID
setCityID:
makeSelectCityIDGUI:
fileread WF_data, %A_ScriptDir%\data\cityID.json
WF_CityList := SelectArea(WF_data,"root.area")
Gui, 17: Add, DropDownList, x12 y40 w100 h20 R5 gSelectedArea1 vSelectedAreaVar1 AltSubmit, %WF_CityList%
Gui, 17: Add, DropDownList, x132 y40 w100 h20 R5 gSelectedArea2 vSelectedAreaVar2 AltSubmit, --
Gui, 17: Add, DropDownList, x252 y40 w100 h20 R5 gSelectedArea3 vSelectedAreaVar3 AltSubmit, --
Gui, 17: Add, Button, x372 y40 w90 h30 gWF_OK, 确定
Gui, 17: Add, Text, x12 y80 w340 h30 vWF_selectedCity,
Gui, 17: Show, w475 h128, 选择城市
return

;第一个下拉菜单选择后执行
SelectedArea1:
; gui 不能隐藏
Gui, 17: Submit,NoHide
WF_CityList := SelectArea(WF_data,"root.area[" . SelectedAreaVar1-1 . "].area")
guicontrol, 17:, SelectedAreaVar2,|%WF_CityList%
return
;第二个下拉菜单选择后执行
SelectedArea2:
Gui, 17: Submit,NoHide
WF_CityList := SelectArea(WF_data,"root.area[" . SelectedAreaVar1-1 . "].area[" . SelectedAreaVar2-1 . "].city")
guicontrol, 17:, SelectedAreaVar3,|%WF_CityList%
return
;第三个下拉菜单选择后执行
SelectedArea3:
Gui, 17: Submit,NoHide
return
;点击确定按钮
WF_OK:
; 获取id
WF_CityID := json(WF_data,"root.area[" . SelectedAreaVar1-1 . "].area[" . SelectedAreaVar2-1 . "].city[" . SelectedAreaVar3-1 . "].id")
; 获取城市名
WF_CityName := json(WF_data,"root.area[" . SelectedAreaVar1-1 . "].area[" . SelectedAreaVar2-1 . "].city[" . SelectedAreaVar3-1 . "].name")
guicontrol, 17:, WF_selectedCity, 您选择的城市是: %WF_CityName%  ID是: %WF_CityID%
Gosub getWeatherForecast
iniwrite,%WF_CityID%,%a_scriptdir%\%applicationname%.ini,weatherSettings,cityID
return

17GuiClose:
gui, 17:destroy
return
;******************************* 天气预报 *******************************

;-------------------------------------------------------------------------------
; 13:52 13-4-2007, by Bold, parts from autohotkey forum.
;
; Shows clock, batterypower, mem load and cpu load on top of screen
; Derived from:
; Snippets and scripts from the AutoHotkey forum.
; Thanks to Majkinetor for his getTextWidth function.

; The script is not flawless, no warranties.
; The progressbars disappear (the text stays) on mouseover so they don't get in the way if you want to click something below it.
; The text overlay is in a separate gui on top of the progressbar, not sure if this is the best way to get a progressbar with text overlay.
; You can set thresholds for low battery, high mem load and high cpu. When these thresholds are reached the colors change.
;
; Problems:
; - The date time seems to lose the time sometimes and only shows the date
; - I'm not sure how to always keep the windows on top, even if an other
; - sometimes there is an annoying flicker in the guis.
;
WM_MOUSEMOVE(){ 
	; CurrControl := a_guicontrol
	; If (CurrControl = "CpuBar" or CurrControl = "MemBar" or CurrControl = "BattBar") 
	if (A_Gui == 8)
	{
		; 注释掉 否则无法联网时，会卡
		; Gosub showWeatherForecast
	}
}

getDistance(mX, mY, x, y, w, h)
{
    ; pointer is in object
    If (mX > x) and (mX < (x + w))
    and (mY > y) and (mY < (y + h))
    {
        xDistance := 0
        yDistance := 0
    }
    Else
    {
        ; pointer is to the left of object
        If (mX < x)
            xDistance := x - mX
        ; pointer is to the right of object
        Else If (mX > (x + w))
            xDistance := mX - (x + w)

        ; pointer is above object
        If (mY < y)
            yDistance := y - mY
        ; pointer is below object
        Else If (mY > (y + h))
            yDistance := mY - (y + h)
    }
    distance := max(xDistance, yDistance) * 6
    return distance
}

CALCULATEPOSITIONS:
   savedScreenWidth := A_ScreenWidth
   savedScreenHeight := A_ScreenHeight

   width := clockWidth + battWidth + memWidth + cpuWidth + margin * 3
   PCMeterxPos := savedScreenWidth - width - posFromRight
   PCMeteryPos := 2
    battPos := clockWidth + margin * 4
    memPos := battPos + battWidth + margin
    cpuPos := memPos + memWidth + margin
Return

WATCHCURSOR:
    CoordMode, Mouse
    MouseGetPos, mouseX, mouseY
	WinGetPos, XcurPos, YcurPos, Width, Height, %windowTitle%
	
    ; totalTransparency := min(getDistance(mouseX, mouseY, xPos + regionMargin+clockWidth,  yPos, regionMargin+clockWidth+memWidth+cpuWidth+battWidth, height), transparency)
    totalTransparency := min(getDistance(mouseX, mouseY, XcurPos + regionMargin+clockWidth,  YcurPos, regionMargin+Width, height), transparency)
    ; clockTransparency := min(getDistance(mouseX, mouseY, xPos + regionMargin, yPos, regionMargin + clockWidth, height), transparency)
    ; battTransparency := min(getDistance(mouseX, mouseY, battPos + regionMargin, yPos, regionMargin + battWidth, height), transparency)
    ; memTransparency := min(getDistance(mouseX, mouseY, memPos + regionMargin, yPos, regionMargin + memWidth, height), transparency)
    ; cpuTransparency := min(getDistance(mouseX, mouseY, cpuPos + regionMargin, yPos, regionMargin + cpuWidth, height), transparency)

   ; WinSet, Transparent, %clockTransparency%, %windowTitle%
   WinSet, Transparent, %totalTransparency%, %windowTitle%
   ; WinSet, Transparent, %battTransparency%,ahk_id %BattBarHwnd% 
   ; WinSet, Transparent, %memTransparency%,ahk_id %MemBarHwnd% 
   ; WinSet, Transparent, %cpuTransparency%,ahk_id %CpuBarHwnd% 
Return


CREATECLOCKWINDOW:
	offset := 6
	progressHeight := 12
	progressPos := 2
	Gui, 8:+LastFound +AlwaysOnTop +ToolWindow -SysMenu -Caption 
	Gui, 8:Color, %clockBGColor%
	Gui, 8:Font, c%clockFontColor% %clockFontStyle%, %clockFont%
	Gui, 8:Add,Text,vDate HwndClockHwnd y%txtY% x%txtX% BackgroundTrans GGuiMove, %clockText% 

	; 6: Window for the batt progress bar
	Gui, 8:Add, Progress, x%battPos% y%progressPos% w%battProgressWidth%  h%progressHeight% c%battBarColor% vBattBar HwndBattBarHwnd  Background%battBGColor%

	; 2: Window for the batt text
	Gui, 8:Color, %battBGColor%
	Gui, 8:Font, c%battFontColor% %infoFontStyle%, Webdings
	Gui, 8:Add,Text,vPlugged y-2 xp+%offset% BackgroundTrans, x
	Gui, 8:Font, c%battFontColor% %infoFontStyle%, %infoFont%
	Gui, 8:Add,Text,vBatt HwndBattHwnd y%txtY% w%battWidth% xp+25 BackgroundTrans, %battinfo%`%

	; 7: Window for the memory progress bar
	Gui, 8:Add, Progress,x%memPos%  y%progressPos% w%memProgressWidth% h%progressHeight% c%memBarColor% vMemBar HwndMemBarHwnd  Background%memBGColor%
	GuiControl, 8:, MemBar, 50 

	; 3: Window for the memory text
	Gui, 8:Color, %memBGColor%
	Gui, 8:Font, c%memFontColor% %infoFontStyle%, %infoFont%
	Gui, 8:Add,Text,vMem HwndMemHwnd y%txtY% xp+%offset% BackgroundTrans, %memText%


	; 5: Window for the cpu progress bar
	Gui, 8:Add, Progress,x%cpuPos%  y%progressPos% w%cpuProgressWidth% h%progressHeight% c%cpuBarColor% vCpuBar HwndCpuBarHwnd Background%cpuBGColor%

	; 4: Window for the cpu text
	Gui, 8:Color, %cpuBGColor%
	Gui, 8:Font, c%cpuFontColor% %infoFontStyle%, %infoFont%
	Gui, 8:Add,Text,vCpu HwndCpuHwnd y%txtY% xp+%offset% BackgroundTrans, %cpuText% 

	
	if %showPCMeter%
	{
		Gui, 8:show, x%PCMeterxPos% y%PCMeteryPos%, PCMeter
		totalwidth := clockWidth + battWidth + memWidth + cpuWidth
		WinSet, Region, %regionMargin%-0 W%totalwidth% H%infoHeight% R5-5, PCMeter
	}
Return

UPDATECLOCK:
   if (savedScreenWidth <> A_ScreenWidth)
   {
      ; I switch recolution often on my laptop so thats why I added this.
       Gosub, CalculatePositions
	   Gui, 8:Hide 
      ; These will be shown again by the KEEPONTOP sub
    }
   FormatTime, clockText ,, %timeFormat%
    GuiControl, 8:,Date, %clockText%
	if (RegExMatch(clockText, "18:00:00") = 1 or RegExMatch(clockText, "08:00:00") = 1)
	{
		GoSub getWeatherForecast 
	}
Return

UPDATEBATTERY:
    battinfo := GetPowerStatus(acLineStatus)
    If (acLineStatus > 0)
    {
        GuiControl, 8:,Plugged, ~
      Gui, 8:Font, c%battFontColor%
      GuiControl, 8: +Background%battBGColor%, BattBar
      GuiControl, 8: +c%battBarColor%, BattBar
    }
    Else
    {
        GuiControl, 8:,Plugged, x
        if (battinfo < alertbattLevel)
      {
         Gui, 8:Font, c%battFontColorAlert%
         GuiControl, 8: +Background%battBGColorAlert%, BattBar
         GuiControl, 8: +c%battBarColorAlert%, BattBar
      }
    }
    GuiControl, 8:Font, Batt  ; Put the above font into effect for a control.
    GuiControl, 8:,Batt,%battinfo%`%
   GuiControl, 8:, BattBar, %battinfo%
Return
GetSystemTimes()    ; Total CPU Load
{
   Static oldIdleTime, oldKrnlTime, oldUserTime
   Static newIdleTime, newKrnlTime, newUserTime

   oldIdleTime := newIdleTime
   oldKrnlTime := newKrnlTime
   oldUserTime := newUserTime

   DllCall("GetSystemTimes", "int64P", newIdleTime, "int64P", newKrnlTime, "int64P", newUserTime)
   Return (1 - (newIdleTime-oldIdleTime)/(newKrnlTime-oldKrnlTime + newUserTime-oldUserTime)) * 100
}
UPDATECPU:
    ; IdleTime0 = %IdleTime%  ; Save previous values
    ; Tick0 = %Tick%
	; DllCall("kernel32.dll\GetSystemTimes", "uint",&IdleTicks, "uint",0, "uint",0)
    ; IdleTime := *(&IdleTicks)
    ; Loop 7                  ; Ticks when Windows was idle
        ; IdleTime += *( &IdleTicks + A_Index ) << ( 8 * A_Index )
    ; Tick := A_TickCount     ; Ticks all together
    ; load := 100 - 0.01*(IdleTime - IdleTime0)/(Tick - Tick0)

   load := GetSystemTimes()
    SetFormat, Float, 0.1
    load += 0

   If (load > cpuThreshold)
   {
      Gui, 8:Font, c%cpuFontColorAlert%
      GuiControl, 8: +Background%cpuBGColorAlert%, CpuBar
      GuiControl, 8: +c%cpuBarColorAlert%, CpuBar
   }
    Else
    {
      Gui, 8:Font, c%cpuFontColor%
      GuiControl, 8: +Background%cpuBGColor%, CpuBar
      GuiControl, 8: +c%cpuBarColor%, CpuBar
   }
    GuiControl, 8:Font, Cpu  ; Put the above font into effect for a control.
    GuiControl, 8:, Cpu, %cpuLabel%%load%`%
   GuiControl, 8:, CpuBar, %load%

   ; --- Calculate memory
    DllCall("kernel32.dll\GlobalMemoryStatus", "uint",&memstatus)
    mem := *( &memstatus + 4 ) ; last byte is enough, mem = 0..100
   If (mem > memThreshold)
   {
      Gui, 8:Font, c%memFontColorAlert%
      GuiControl, 8: +Background%memBGColorAlert%, MemBar
      GuiControl, 8: +c%memBarColorAlert%, MemBar
   }
    Else
    {
      Gui, 8:Font, c%memFontColor%
      GuiControl, 8: +Background%memBGColor%, MemBar
      GuiControl, 8: +c%memBarColor%, MemBar
   }
    GuiControl, 8:Font, Mem
    GuiControl, 8:,Mem, %memLabel%%mem%`%
   GuiControl, 8:, MemBar, %mem%

Return


GetPowerStatus(ByRef acLineStatus)
{
    VarSetCapacity(powerstatus, 1+1+1+1+4+4)
    success := DllCall("kernel32.dll\GetSystemPowerStatus", "uint", &powerstatus)
    acLineStatus:=ReadInteger(&powerstatus,0,1,false)
    battFlag:=ReadInteger(&powerstatus,1,1,false)
    battLifePercent:=ReadInteger(&powerstatus,2,1,false)
    battLifeTime:=ReadInteger(&powerstatus,4,4,false)
    battFullLifeTime:=ReadInteger(&powerstatus,8,4,false)
   Return battLifePercent
}


ReadInteger( p_address, p_offset, p_size, p_hex=true )
{
    value = 0
    old_FormatInteger := a_FormatInteger
    if ( p_hex )
        SetFormat, integer, hex
    else
        SetFormat, integer, dec
    loop, %p_size%
        value := value+( *( ( p_address+p_offset )+( a_Index-1 ) ) << ( 8* ( a_Index-1 ) ) )
    SetFormat, integer, %old_FormatInteger%
    return, value
}


Max(In_Val1,In_Val2)
{
   IfLess In_Val1,%In_Val2%, Return In_Val2
   Return In_Val1
}

Min(In_Val1,In_Val2)
{
   IfLess In_Val1,%In_Val2%, Return In_Val1
   Return In_Val2
}

INIREAD:
   IfNotExist,%a_scriptdir%\%applicationname%.ini
   {
      clockFont := "Verdana"
      fontSize := 10
      clockFontColor := "Silver"
      clockBGColor := "Black"

      infoFontSize := 10
      infoFont := "Tahoma"

      battFontColor := "Lime"
      battFontColorAlert := "Yellow"
      battBGColor := "Black"
      battBGColorAlert := "Maroon"
      battBarColor := "Green"
      battBarColorAlert := "Red"
      alertbattLevel := 10

      memFontColor := "Fuchsia"
      memFontColorAlert := "Yellow"
      memBGColor := "Black"
      memBGColorAlert := "Maroon"
      memBarColor := "Purple"
      memBarColorAlert := "Red"
      memThreshold := 80

      cpuFontColor := "Aqua"
      cpuFontColorAlert := "Yellow"
      cpuBGColor := "Black"
      cpuBGColorAlert := "Maroon"
      cpuBarColor := "Blue"
      cpuBarColorAlert := "Red"
      cpuThreshold := 80
      margin := 2
      transparency := 200
      memLabel := "Mem: "
      cpuLabel := "Cpu: "
      ; timeFormat := "ddd dd MMM yyyy HH:mm:ss"
      timeFormat := "HH:mm:ss"
	  showPCMeter := 1
      Gosub,INIWRITE
   }
   IniRead,clockFont,%a_scriptdir%\%applicationname%.ini,ClockSettings,clockFont
   IniRead,fontSize,%a_scriptdir%\%applicationname%.ini,ClockSettings,fontSize
   IniRead,clockFontColor,%a_scriptdir%\%applicationname%.ini,ClockSettings,clockFontColor
   IniRead,clockBGColor,%a_scriptdir%\%applicationname%.ini,ClockSettings,clockBGColor
   IniRead,infoFontSize,%a_scriptdir%\%applicationname%.ini,ClockSettings,infoFontSize
   IniRead,infoFont,%a_scriptdir%\%applicationname%.ini,ClockSettings,infoFont
   IniRead,battFontColor,%a_scriptdir%\%applicationname%.ini,ClockSettings,battFontColor
   IniRead,battFontColorAlert,%a_scriptdir%\%applicationname%.ini,ClockSettings,battFontColorAlert
   IniRead,battBGColor,%a_scriptdir%\%applicationname%.ini,ClockSettings,battBGColor
   IniRead,battBGColorAlert,%a_scriptdir%\%applicationname%.ini,ClockSettings,battBGColorAlert
   IniRead,battBarColor,%a_scriptdir%\%applicationname%.ini,ClockSettings,battBarColor
   IniRead,battBarColorAlert,%a_scriptdir%\%applicationname%.ini,ClockSettings,battBarColorAlert
   IniRead,alertbattLevel,%a_scriptdir%\%applicationname%.ini,ClockSettings,alertbattLevel
   IniRead,memFontColor,%a_scriptdir%\%applicationname%.ini,ClockSettings,memFontColor
   IniRead,memFontColorAlert,%a_scriptdir%\%applicationname%.ini,ClockSettings,memFontColorAlert
   IniRead,memBGColor,%a_scriptdir%\%applicationname%.ini,ClockSettings,memBGColor
   IniRead,memBGColorAlert,%a_scriptdir%\%applicationname%.ini,ClockSettings,memBGColorAlert
   IniRead,memBarColor,%a_scriptdir%\%applicationname%.ini,ClockSettings,memBarColor
   IniRead,memBarColorAlert,%a_scriptdir%\%applicationname%.ini,ClockSettings,memBarColorAlert
   IniRead,memThreshold,%a_scriptdir%\%applicationname%.ini,ClockSettings,memThreshold
   IniRead,cpuFontColor,%a_scriptdir%\%applicationname%.ini,ClockSettings,cpuFontColor
   IniRead,cpuFontColorAlert,%a_scriptdir%\%applicationname%.ini,ClockSettings,cpuFontColorAlert
   IniRead,cpuBGColor,%a_scriptdir%\%applicationname%.ini,ClockSettings,cpuBGColor
   IniRead,cpuBGColorAlert,%a_scriptdir%\%applicationname%.ini,ClockSettings,cpuBGColorAlert
   IniRead,cpuBarColor,%a_scriptdir%\%applicationname%.ini,ClockSettings,cpuBarColor
   IniRead,cpuBarColorAlert,%a_scriptdir%\%applicationname%.ini,ClockSettings,cpuBarColorAlert
   IniRead,cpuThreshold,%a_scriptdir%\%applicationname%.ini,ClockSettings,cpuThreshold
   IniRead,margin,%a_scriptdir%\%applicationname%.ini,ClockSettings,margin
   IniRead,transparency,%a_scriptdir%\%applicationname%.ini,ClockSettings,transparency
   IniRead,memLabel,%a_scriptdir%\%applicationname%.ini,ClockSettings,memLabel
   IniRead,cpuLabel,%a_scriptdir%\%applicationname%.ini,ClockSettings,cpuLabel
   IniRead,timeFormat,%a_scriptdir%\%applicationname%.ini,ClockSettings,timeFormat
   IniRead,showPCMeter,%a_scriptdir%\%applicationname%.ini,ClockSettings,showPCMeter
   if %showPCMeter%
        Menu, PCMeter, Check, show Window
Return

INIWRITE:
   IniWrite,%clockFont%,%a_scriptdir%\%applicationname%.ini,ClockSettings,clockFont
   IniWrite,%fontSize%,%a_scriptdir%\%applicationname%.ini,ClockSettings,fontSize
   IniWrite,%clockFontColor%,%a_scriptdir%\%applicationname%.ini,ClockSettings,clockFontColor
   IniWrite,%clockBGColor%,%a_scriptdir%\%applicationname%.ini,ClockSettings,clockBGColor
   IniWrite,%infoFontSize%,%a_scriptdir%\%applicationname%.ini,ClockSettings,infoFontSize
   IniWrite,%infoFont%,%a_scriptdir%\%applicationname%.ini,ClockSettings,infoFont
   IniWrite,%battFontColor%,%a_scriptdir%\%applicationname%.ini,ClockSettings,battFontColor
   IniWrite,%battFontColorAlert%,%a_scriptdir%\%applicationname%.ini,ClockSettings,battFontColorAlert
   IniWrite,%battBGColor%,%a_scriptdir%\%applicationname%.ini,ClockSettings,battBGColor
   IniWrite,%battBGColorAlert%,%a_scriptdir%\%applicationname%.ini,ClockSettings,battBGColorAlert
   IniWrite,%battBarColor%,%a_scriptdir%\%applicationname%.ini,ClockSettings,battBarColor
   IniWrite,%battBarColorAlert%,%a_scriptdir%\%applicationname%.ini,ClockSettings,battBarColorAlert
   IniWrite,%alertbattLevel%,%a_scriptdir%\%applicationname%.ini,ClockSettings,alertbattLevel
   IniWrite,%memFontColor%,%a_scriptdir%\%applicationname%.ini,ClockSettings,memFontColor
   IniWrite,%memFontColorAlert%,%a_scriptdir%\%applicationname%.ini,ClockSettings,memFontColorAlert
   IniWrite,%memBGColor%,%a_scriptdir%\%applicationname%.ini,ClockSettings,memBGColor
   IniWrite,%memBGColorAlert%,%a_scriptdir%\%applicationname%.ini,ClockSettings,memBGColorAlert
   IniWrite,%memBarColor%,%a_scriptdir%\%applicationname%.ini,ClockSettings,memBarColor
   IniWrite,%memBarColorAlert%,%a_scriptdir%\%applicationname%.ini,ClockSettings,memBarColorAlert
   IniWrite,%memThreshold%,%a_scriptdir%\%applicationname%.ini,ClockSettings,memThreshold
   IniWrite,%cpuFontColor%,%a_scriptdir%\%applicationname%.ini,ClockSettings,cpuFontColor
   IniWrite,%cpuFontColorAlert%,%a_scriptdir%\%applicationname%.ini,ClockSettings,cpuFontColorAlert
   IniWrite,%cpuBGColor%,%a_scriptdir%\%applicationname%.ini,ClockSettings,cpuBGColor
   IniWrite,%cpuBGColorAlert%,%a_scriptdir%\%applicationname%.ini,ClockSettings,cpuBGColorAlert
   IniWrite,%cpuBarColor%,%a_scriptdir%\%applicationname%.ini,ClockSettings,cpuBarColor
   IniWrite,%cpuBarColorAlert%,%a_scriptdir%\%applicationname%.ini,ClockSettings,cpuBarColorAlert
   IniWrite,%cpuThreshold%,%a_scriptdir%\%applicationname%.ini,ClockSettings,cpuThreshold
   IniWrite,%margin%,%a_scriptdir%\%applicationname%.ini,ClockSettings,margin
   IniWrite,%transparency%,%a_scriptdir%\%applicationname%.ini,ClockSettings,transparency
   IniWrite,%memLabel%,%a_scriptdir%\%applicationname%.ini,ClockSettings,memLabel
   IniWrite,%cpuLabel%,%a_scriptdir%\%applicationname%.ini,ClockSettings,cpuLabel
   IniWrite,%timeFormat%,%a_scriptdir%\%applicationname%.ini,ClockSettings,timeFormat
   IniWrite,%showPCMeter%,%a_scriptdir%\%applicationname%.ini,ClockSettings,showPCMeter
Return

ExtractInteger(ByRef pSource, pOffset = 0, pIsSigned = false, pSize = 4)
; pSource is a string (buffer) whose memory area contains a raw/binary integer at pOffset.
; The caller should pass true for pSigned to interpret the result as signed vs. unsigned.
; pSize is the size of PSource's integer in bytes (e.g. 4 bytes for a DWORD or Int).
; pSource must be ByRef to avoid corruption during the formal-to-actual copying process
; (since pSource might contain valid data beyond its first binary zero).
{
    Loop %pSize%  ; Build the integer by adding up its bytes.
        result += *(&pSource + pOffset + A_Index-1) << 8*(A_Index-1)
    if (!pIsSigned OR pSize > 4 OR result < 0x80000000)
        return result  ; Signed vs. unsigned doesn't matter in these cases.
    ; Otherwise, convert the value (now known to be 32-bit) to its signed counterpart:
    return -(0xFFFFFFFF - result + 1)
}

;-----------------------------------------------------------------------------------------------------------------------
; Function: GetTextSize
; Calculate widht and/or height of text, taking the font style and face into account
;:
;
;
; Parameters:
;      pStr      - Text to be measured
;      pFont     - Font description in AHK syntax
;      pHeight   - Set to true to return height also. False is default.
;
; Returns:
;   Text width if pHeight=false. Otherwise, dimension is returned as "width,height"
;
; Example:
;      width := GetTextSize("string to be measured", "bold s22, Courier New" )
;
GetTextSize(pStr, pFont="", pHeight=false) {
   local height, weight, italic, underline, strikeout , nCharSet
   local hdc := DllCall("GetDC", "Uint", 0)
   local hFont, hOldFont

  ;parse font
   if (pFont != "") {
      italic      := InStr(pFont, "italic")
      underline   := InStr(pFont, "underline")
      strikeout   := InStr(pFont, "strikeout")
      weight      := InStr(pFont, "bold") ? 700 : 0

      RegExMatch(pFont, "(?<=[S|s])(\d{1,2})(?=[ ,])", height)
      if (height != "")
         height := -DllCall("MulDiv", "int", height, "int", DllCall("GetDeviceCaps", "Uint", hDC, "int", 90), "int", 72)

      RegExMatch(pFont, "(?<=,).+", fontFace)
      fontFace := RegExReplace( fontFace, "(^\s+)|(\s+$)")      ;trim

      ;   msgbox "%fontFace%" "%italic%" "%underline%" "%strikeout%" "%weight%" "%height%"
   }


 ;create font
   hFont  := DllCall("CreateFont", "int", height, "int", 0, "int", 0, "int", 0
                           ,"int", weight, "Uint", italic, "Uint", underline
                           ,"uint", strikeOut, "Uint", nCharSet, "Uint", 0, "Uint", 0, "Uint", 0, "Uint", 0, "str", fontFace)
   hOldFont := DllCall("SelectObject", "Uint", hDC, "Uint", hFont)
   DllCall("GetTextExtentPoint32", "Uint", hDC, "str", pStr, "int", StrLen(pStr), "int64P", nSize)
;   DllCall("DrawTextA", "Uint", hDC, "str", pStr, "int", StrLen(pStr), "int64P", nSize, "uint", 0x400)


 ;clean

   DllCall("SelectObject", "Uint", hDC, "Uint", hOldFont)
   DllCall("DeleteObject", "Uint", hFont)
   DllCall("ReleaseDC", "Uint", 0, "Uint", hDC)

   nWidth  := nSize & 0xFFFFFFFF
   nHeight := nSize >> 32 & 0xFFFFFFFF


   if (pHeight)
      nWidth .= "," nHeight
   return   nWidth
}

KEEPONTOP:
	; Gui, 8::Show, NA x%xPos% y%yPos%, %windowTitle%

	Gui, 8:Show, NA , %windowTitle%
Return


; ExitSub:
; ExitApp

TogglePCMeter:
    if %showPCMeter%
    {
        showPCMeter = 0
        Menu, PCMeter, UnCheck, Show Window
		IniWrite, %showPCMeter%, %A_ScriptDir%\%applicationname%.ini, ClockSettings, showPCMeter
		SetTimer, UPDATECLOCK, off
		SetTimer, UPDATEBATTERY, off
		SetTimer, UPDATECPU, off
		SetTimer, WATCHCURSOR, off
		SetTimer, KEEPONTOP, off
        GoSub, ClosePCMeter
    }
    else
    {
        showPCMeter = 1
        Menu, PCMeter, Check, Show Window
        GoSub, ShowPCMeterGUI
		IniWrite, %showPCMeter%, %A_ScriptDir%\%applicationname%.ini, ClockSettings, showPCMeter
		SetTimer, UPDATECLOCK, 1000
		SetTimer, UPDATEBATTERY, 2000
		SetTimer, UPDATECPU, 1500
		SetTimer, WATCHCURSOR, 115
		SetTimer, KEEPONTOP, 1000
    }
Return  

ShowPCMeterGUI:
	Gui, 8:show, x%PCMeterxPos% y%PCMeteryPos%, PCMeter
	totalwidth := clockWidth + battWidth + memWidth + cpuWidth
	WinSet, Region, %regionMargin%-0 W%totalwidth% H%infoHeight% R5-5, PCMeter
Return

ClosePCMeter:
    IniWrite, %showPCMeter%, %A_ScriptDir%\%applicationname%.ini, ClockSettings, showPCMeter
    Gui,8:Hide
Return

;;;;;;;;;;;;;;HDDMonitor;;;;;;;;;;;;;;;;;;;


HDD_Monitor:
    iconname=
    activity=0
    loop, % NumDrives
    {
        VarSetCapacity(dp, 88)
        DllCall("DeviceIoControl", Uint,hDrv%A_Index%, Uint,0x00070020, Uint,0, Uint,0, Uint,&dp, Uint,88, Uint,0, Uint,0 )
        
        nRC := *(&dp+40) | *(&dp+41) << 8 | *(&dp+42) << 16 | *(&dp+43) << 24
        nWC := *(&dp+44) | *(&dp+45) << 8 | *(&dp+46) << 16 | *(&dp+47) << 24
        RC := Round(100-(100*(1/(1+(nRC-oRC%A_Index%)))))
        WC := Round(100-(100*(1/(1+(nWC-oWC%A_Index%)))))
        oRC%A_Index% := nRC
        oWC%A_Index% := nWC
        if (WC + RC)
            activity = 1
        icon := RC && WC ? "B" : RC ? "R" : WC ? "W" : "N"
        iconname = %iconname%%icon%
        if %showInfo%
        {
            GuiControl,12:, % "ProgressR" . A_Index, % RC
            GuiControl,12:, % "ProgressW" . A_Index, % WC
        }
    }
    if (blinkled && activity != oActivity)
    {
        DllCall("DeviceIoControl", "Uint",hKeybd, "Uint",0x000B0040, "Uint",0, "Uint",0, "UintP",_ledStatus_, "Uint",4, "UintP",nReturn, "Uint",0)
        if (activity)
            ledStatus := _ledStatus_ | blinkled << 16
        else
            ledStatus := _ledStatus_ & ~(blinkled << 16)
        DllCall("DeviceIoControl", "Uint",hKeybd, "Uint",0x000B0008, "UintP",ledStatus, "Uint",4, "Uint",0, "Uint",0, "UintP",nReturn, "Uint",0)
        oActivity = %activity%
    }
    iconname := SubStr(iconname . "UUUU", 1, 4)
    SetTrayIco(iconname)
Return

GetDrivesList:
    GoSub, CloseHandles

    HDD_List =
    ; get the list of fixed drives
    DriveGet, tmplist1, List, FIXED
    ; adds also the removable drives that are not empty
    if (includeremovable)
    {
        DriveGet, tmplist2, List, REMOVABLE
        Loop, parse, tmplist2
        {
            DriveSpaceFree, tmp, %A_LoopField%:\
            If (tmp > 0)
                tmplist1 = %tmplist1%%A_LoopField%
        }
    }
    ; sort the list of drives so that the preferred drives defined in the INI file
    ; are at the beginning of the list and will be displayed in the tray icon.
    Loop, parse, preferreddrvs
    {
        if (InStr(tmplist1, A_LoopField))
            HDD_List = %HDD_List%%A_LoopField%
    }
    Loop, parse, tmplist1
    {
        if (NOT InStr(preferreddrvs, A_LoopField))
            HDD_List = %HDD_List%%A_LoopField%
    }
    NumDrives := StrLen(HDD_List)

    tmp=%HDDMtitle%`nDrives in tray icon:`n
    Loop, parse, HDD_List
    {
        HDD%A_Index%  := A_LoopField
        hDrv%A_Index% := DllCall( "CreateFile", Str,"\\.\" . A_LoopField . ":", Uint,0 ,Uint,3, Uint,0, Uint,3, Uint,0, Uint,0), oRC%A_Index% := 0, oWC%A_Index% := 0
        if (A_Index <= 4)
        {
            tmp = %tmp%%A_Space%%A_Space%%A_LoopField%:
            if (A_Index == 2)
                tmp = %tmp%`n
        }
    }

    ; Menu, tray, Tip, %tmp%

    GoSub, BuildGUI
    if %showInfo%
        GoSub, ShowGUI
Return

CloseHandles:
    Loop, parse, HDD_List
    {
        tmp := hDrv%A_Index%
        DllCall( "CloseHandle", Uint,tmp)
    }
    HDD_List =
    NumDrives = 0
Return

BuildGUI:
    Gui,12:Destroy
    Gui,12:Color, %backgroundcolor%, %backgroundcolor%
    Gui,12:font, s8 bold, Arial

    ; adds a Text widget covering the entire surface of the GUI so that we can drag it
    barsrealwidth := barswidth+2
    guimaxwidth := barsrealwidth + 12
    barsrealheight := (barsheight * 2) + 1
    guimaxheight := barsrealheight*NumDrives+2
    Gui,12:Add, Text, x0 y0 w%guimaxwidth% h%guimaxheight% GGuiMove

    y = 0
    Loop, parse, HDD_List
    {
        py := round((barsrealheight - 9) / 2) + y
        Gui,12:add, Text, x1 y%py% C%fontcolor%, %A_LoopField%:
        py := y+1
        Gui,12:add, Progress, vProgressR%A_Index% w%barsrealwidth% h%barsheight% x12 y%py% Background%barsbkgcolor% CLime
        py := y+barsheight+1
        Gui,12:add, Progress, vProgressW%A_Index% w%barsrealwidth% h%barsheight% x12 y%py% Background%barsbkgcolor% CRed
        y := y+barsrealheight
    }
    Gui,12:Margin, 1, -1
    Gui,12:-Theme +ToolWindow -Caption
    if %alwaysontop%
        Gui,12:+AlwaysOnTop
Return

ShowGUI:
    if (HDDMypos >= 0)
        y = %HDDMypos%
    else
        y := A_ScreenHeight + HDDMypos - barsrealheight*NumDrives
    Gui,12:Show, X%HDDMxpos% Y%y%, %HDDMtitle%
    if %transparent%
        WinSet, TransColor, %barsbkgcolor%, %HDDMtitle%
Return

ToggleAlwaysOnTop:
    if %alwaysontop%
    {
        Gui,12:-AlwaysOnTop
        Menu, HDDMonitor, UnCheck, Always On Top
        alwaysontop = 0
    }
    else
    {
        Gui,12:+AlwaysOnTop
        Menu, HDDMonitor, Check, Always On Top
        alwaysontop = 1
    }
Return

TogglePause:
   if %A_IsPaused%
   {
       GoSub, GetDrivesList
      Pause Off
        SetTrayIco("NNNN")
      Menu, HDDMonitor, Uncheck, Pause
        if %showInfo%
            Gui,12:Show
   }
   else
   {
      Menu, HDDMonitor, Check, Pause
      GoSub, CloseInfoWindow
        GoSub, RestoreKeyboardLeds
      ; we need to freeze the paused icon, so we cannot use SetTrayIco()
      if (FileExist("paused.ico"))
            Menu, tray, Icon, paused.ico, 1, 1
        lasticonname = ----
       GoSub, CloseHandles
      Pause On
   }
Return

ToggleTransparent:
   if %transparent%
   {
        Menu, HDDMonitor, UnCheck, Transparent bars
        WinSet, TransColor, OFF, %HDDMtitle%
        transparent = 0
   }
   else
   {
        Menu, HDDMonitor, Check, Transparent bars
        WinSet, TransColor, %barsbkgcolor%, %HDDMtitle%
        transparent = 1
   }
Return

ToggleInfo:
    if %showInfo%
    {
        showInfo = 0
        Menu, HDDMonitor, UnCheck, Info Window
        GoSub, CloseInfoWindow
    }
    else
    {
        showInfo = 1
        Menu, HDDMonitor, Check, Info Window
        GoSub, ShowGUI
        if %A_IsPaused%
            GoSub, TogglePause
    }
Return

BlinkNone:
    GoSub, RestoreKeyboardLeds
    blinkled = 0
    GoSub, UpdateBlinkLedMenu
    GoSub, CloseBlinkLedHandle
    GoSub, SaveDynamicSettings
Return
BlinkScrollLock:
    GoSub, RestoreKeyboardLeds
    blinkled = 1
    GoSub, UpdateBlinkLedMenu
    GoSub, OpenBlinkLedHandle
    GoSub, SaveDynamicSettings
Return
BlinkNumLock:
    GoSub, RestoreKeyboardLeds
    blinkled = 2
    GoSub, UpdateBlinkLedMenu
    GoSub, OpenBlinkLedHandle
    GoSub, SaveDynamicSettings
Return
BlinkCapsLock:
    GoSub, RestoreKeyboardLeds
    blinkled = 4
    GoSub, UpdateBlinkLedMenu
    GoSub, OpenBlinkLedHandle
    GoSub, SaveDynamicSettings
Return

UpdateBlinkLedMenu:
    Menu, Blink, UnCheck, None
    Menu, Blink, UnCheck, Scroll Lock
    Menu, Blink, UnCheck, Num Lock
    Menu, Blink, UnCheck, Caps Lock
    if (blinkled == 0)
        Menu, Blink, Check, None
    else if (blinkled == 1)
        Menu, Blink, Check, Scroll Lock
    else if (blinkled == 2)
        Menu, Blink, Check, Num Lock
    else if (blinkled == 4)
        Menu, Blink, Check, Caps Lock
Return

OpenBlinkLedHandle:
    if (blinkled) {
        hKeybd := DllCall("CreateFile", "str","\\.\GLOBALROOT\Device\KeyboardClass" . keyboardclassnum, "Uint",0, "Uint",3, "Uint",0, "Uint",3, "Uint",0, "Uint",0)
        DllCall("DeviceIoControl", "Uint",hKeybd, "Uint",0x000B0040, "Uint",0, "Uint",0, "UintP",_ledStatus_, "Uint",4, "UintP",nReturn, "Uint",0)   ; IOCTL_KEYBOARD_QUERY_INDICATORS
    }
    oActivity =
Return

CloseBlinkLedHandle:
    if (_ledStatus_ != "")
    {
        DllCall("CloseHandle", "Uint", hKeybd)
        _ledStatus_ =
    }
    oActivity =
Return

RestoreKeyboardLeds:
    if (_ledStatus_ != "")
    {
        old_pause = %A_IsPaused%
        SetTimer, HDD_Monitor, off
        Sleep, 100
        DllCall("DeviceIoControl", "Uint",hKeybd, "Uint",0x000B0040, "Uint",0, "Uint",0, "UintP",_ledStatus_, "Uint",4, "UintP",nReturn, "Uint",0)
        if (blinkled != 0)
        {
            if (blinkled == 1)
                CurKey = ScrollLock
            else if (blinkled == 2)
                CurKey = NumLock
            else
                CurKey = CapsLock
            if (GetKeyState(CurKey, "T"))
                _ledStatus_ := _ledStatus_ | blinkled << 16
            else
                _ledStatus_ := _ledStatus_ & ~(blinkled << 16)
        }
        DllCall("DeviceIoControl", "Uint",hKeybd, "Uint",0x000B0008, "UintP",_ledStatus_, "Uint",4, "Uint",0, "Uint",0, "UintP",nReturn, "Uint",0)   ; IOCTL_KEYBOARD_SET_INDICATORS
        if (! old_pause)
            SetTimer, HDD_Monitor, %period%
    }
    oActivity =
Return

LoadSettings:
    IniRead, period,           %A_ScriptDir%\%applicationname%.ini, HDDMSetting, Period,           200
    IniRead, preferreddrvs,    %A_ScriptDir%\%applicationname%.ini, HDDMSetting, PreferredDrives,  CDEF
    IniRead, includeremovable, %A_ScriptDir%\%applicationname%.ini, HDDMSetting, IncludeRemovable, 1
    IniRead, fontcolor,        %A_ScriptDir%\%applicationname%.ini, HDDMSetting, FontColor,        C0C0C0
    IniRead, backgroundcolor,  %A_ScriptDir%\%applicationname%.ini, HDDMSetting, BackgroundColor,  000000
    IniRead, barsbkgcolor,     %A_ScriptDir%\%applicationname%.ini, HDDMSetting, BarsBkgColor,     808080
    IniRead, barswidth,        %A_ScriptDir%\%applicationname%.ini, HDDMSetting, BarsWidth,        100
    IniRead, barsheight,       %A_ScriptDir%\%applicationname%.ini, HDDMSetting, BarsHeight,       7
    IniRead, keyboardclassnum, %A_ScriptDir%\%applicationname%.ini, HDDMSetting, KeyboardClassNum, 0
    
    IniRead, showInfo,      %A_ScriptDir%\%applicationname%.ini, AutoHDDMSetting, ShowInfoWindow, 0
    IniRead, alwaysontop,   %A_ScriptDir%\%applicationname%.ini, AutoHDDMSetting, AlwaysOnTop,    0
    IniRead, transparent,   %A_ScriptDir%\%applicationname%.ini, AutoHDDMSetting, Transparent,    0
    IniRead, HDDMxpos,          %A_ScriptDir%\%applicationname%.ini, AutoHDDMSetting, XPos,           200
    IniRead, HDDMypos,          %A_ScriptDir%\%applicationname%.ini, AutoHDDMSetting, YPos,           200
    IniRead, blinkled,      %A_ScriptDir%\%applicationname%.ini, AutoHDDMSetting, BlinkLed,       1
    if (barsheight < 4)
        barsheight = 4
    if %showInfo%
        Menu, HDDMonitor, Check, Info Window
    if %alwaysontop%
        Menu, HDDMonitor, Check, Always On Top
    if %transparent%
        Menu, HDDMonitor, Check, Transparent bars
    GoSub, UpdateBlinkLedMenu
Return

SaveDynamicSettings:
    IniWrite, %showInfo%,    %A_ScriptDir%\%applicationname%.ini, AutoHDDMSetting, ShowInfoWindow
    IniWrite, %alwaysontop%, %A_ScriptDir%\%applicationname%.ini, AutoHDDMSetting, AlwaysOnTop
    IniWrite, %transparent%, %A_ScriptDir%\%applicationname%.ini, AutoHDDMSetting, Transparent
    WinGetPos, HDDMxpos1, ypos1, , , %HDDMtitle%
    if HDDMxpos1 !=
    {
        HDDMxpos = %HDDMxpos1%
        HDDMypos = %ypos1%
        if (HDDMypos > A_ScreenHeight * 0.8)
        {
            HDDMypos := (A_ScreenHeight - HDDMypos - barsrealheight*NumDrives) * -1
            if (HDDMypos >= 0)
                HDDMypos = %ypos1%
        }
        IniWrite, %HDDMxpos%,        %A_ScriptDir%\%applicationname%.ini, AutoHDDMSetting, XPos
        IniWrite, %HDDMypos%,        %A_ScriptDir%\%applicationname%.ini, AutoHDDMSetting, YPos
    } 
    IniWrite, %blinkled%,    %A_ScriptDir%\%applicationname%.ini, AutoHDDMSetting, BlinkLed
Return

EditSettings:
    if %editsettings%
        Return
    editsettings = 1
    Menu, HDDMonitor, Check, Edit settings
    if (showInfo && ! A_IsPaused)
        GoSub, CloseInfoWindow
    RunWait, Notepad.exe "%A_ScriptDir%\%applicationname%.ini"
    GoSub, LoadSettings
    GoSub, BuildGUI
    if (showInfo && ! A_IsPaused)
        GoSub, ShowGUI
    if (! A_IsPaused)
    {
        SetTimer, HDD_Monitor, OFF
        SetTimer, HDD_Monitor, %period%
    }
    Menu, HDDMonitor, UnCheck, Edit settings
    editsettings = 0
Return

GuiClose:
GuiEscape:
    showInfo = 0
    Menu, HDDMonitor, UnCheck, Info Window
    GoSub, CloseInfoWindow
Return

CloseInfoWindow:
    GoSub, SaveDynamicSettings
    Gui,12:Hide
Return




CleanExit:
    SetTimer, HDD_Monitor, OFF
    GoSub, CloseInfoWindow
    sleep, 100
    GoSub, CloseHandles
    GoSub, RestoreKeyboardLeds
    GoSub, CloseBlinkLedHandle
ExitApp



SetTrayIco(IcoName)
{
    global NID, lasticonname, IconData, IconDataNHex, IconDataRHex, IconDataWHex, IconDataBHex, IconDataUHex
    static h_icon
    if (IcoName == lasticonname)
        return
    ; build icon data
    offset = 39
    Loop, parse, IcoName
    {
        if (A_LoopField != SubStr(lasticonname,A_Index,1))
        {
            icmh := IconData%A_LoopField%Hex
            loop, 16
                NumPut( "0x" . SubStr(icmh,2*A_Index-1,2), IconData, offset+A_Index, "Char" )
        }
        offset := offset + 16
    }
    ; build icon
    old_h_icon := h_icon
    h_icon := DllCall( "CreateIconFromResourceEx", UInt,&IconData
                    , UInt,0, Int,1, UInt,196608, Int,16, Int,16, UInt,0 )
    ; display tray icon
    NumPut( h_Icon,NID,20 )
    DllCall( "shell32\Shell_NotifyIcon", UInt,0x1, UInt,&NID )
    if (old_h_icon)
        DllCall( "DestroyIcon", Uint,old_h_Icon)
    lasticonname = %IcoName%
    return
}

InitHIconStruct()
{
    global NID
    PID := DllCall("GetCurrentProcessId")
    VarSetCapacity( NID, 444, 0 )
    NumPut( 444,NID )
    DetectHiddenWindows, On
    NumPut( WinExist(A_ScriptFullPath " ahk_class AutoHotkey ahk_pid " PID), NID,4 )
    DetectHiddenWindows, Off
    NumPut( 1028,NID,8 )
    NumPut( 2,NID,12 )
    return
}



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Clipjump begin;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; in_back:粘贴模式下是否向前切换剪切板
; cursave:当前保存的剪切板个数
; tempsave:当前剪切板,向后切换时减1
paste:
gui, 15: hide
caller := false
if (in_back)
{
in_back := false
If (tempsave == 1)
	tempsave := cursave
else
	tempsave-=1
}
IfNotExist,%A_ScriptDir%/cache/clips/%tempsave%.avc
{
	Tooltip, No Clip Exists
	sleep, 700
	Tooltip
	caller := true
	; Reload
	fileappend ,[%a_now%] paste cursave: %cursave%  tempsave: %tempsave%  caller: %caller% `n, %a_scriptdir%\cache\err.log
}
else
{
	Hotkey,^c,MoveBack,On
	Hotkey,^x,Cancel,On
	Hotkey,^Space,Fixate,On
	Hotkey,^S,Ssuspnd,On

; 读取保存了clipboardall的文件
	fileread,Clipboard,*c %A_ScriptDir%/cache/clips/%tempsave%.avc
	gosub, fixcheck
	realclipno := cursave - tempsave + 1
	; 剪切板为空是图片？
	ifequal,clipboard
	{
		Tooltip, Clip %realclipno% of %cursave% %fixstatus%
		gosub, showpreview
		settimer,ctrlcheck,50
	}
	else
	{
		length := strlen(Clipboard)
		IfGreater,length,200
		{
			StringLeft,halfclip,Clipboard, 200
			halfclip := halfclip . "                      >>>>  .............More"
		}
		else
			halfclip := Clipboard
		ToolTip, Clip %realclipno% of %cursave% %fixstatus%`n%halfclip%
		settimer,ctrlcheck,50
	}
	realactive := tempsave
	tempsave-=1
	If (tempsave == 0)
		tempsave := cursave
}
return

OnClipboardChange:
Critical
If (caller)
{
errlvl := ErrorLevel
gosub, clipchange
}
return

clipchange:
tempclipall := ClipboardAll
If (clipboard != "" or tempclipall != "")
{
If errlvl = 1
{
	IfNotEqual,Clipboard,%lastclip%
	{
	cursave+=1
	gosub, clipsaver
	LastClip := Clipboard
	Tooltip, %CopyMessage%
	tempsave := cursave
	IfEqual,cursave,%totalclips%
		gosub,compacter
	}
if fileappendErr
{
StringLeft,halfclip,Clipboard,200
fileappend ,[%a_now%] err1 cursave: %cursave%  tempsave: %tempsave%  caller: %caller% halfclip: %halfclip%`n, %a_scriptdir%\cache\err.log
}
}
If errlvl = 2
{
	cursave+=1
	Tooltip, %CopyMessage%
	tempsave := cursave
	LastClip := 
	gosub, thumbgenerator
	gosub, clipsaver
	IfEqual,cursave,%totalclips%
		gosub, compacter

if fileappendErr
{
StringLeft,halfclip,Clipboard,200
fileappend ,[%A_now%] err2 cursave: %cursave%  tempsave: %tempsave%  caller: %caller%  halfclip: %halfclip%`n, %a_scriptdir%\cache\err.log
}
}
tempclipall = 
sleep, 500
Tooltip

if fileappendErr
{
StringLeft,halfclip,Clipboard,200
fileappend ,[%a_now%] clipchange cursave: %cursave%  tempsave: %tempsave%  caller: %caller%  halfclip: %halfclip%`n, %a_scriptdir%\cache\err.log
}
EmptyMem()
}
return

MoveBack:
gui, 15: hide
in_back := true
tempsave := realactive + 1
IfEqual,realactive,%cursave%
	tempsave := 1
realactive := tempsave
fileread,Clipboard,*c %A_ScriptDir%/cache/clips/%tempsave%.avc
gosub, fixcheck
realclipno := cursave - tempsave + 1
ifequal,clipboard
{
	Tooltip, Clip %realclipno% of %cursave% %fixstatus%`n
	gosub, showpreview
	settimer,ctrlcheck,50
}
else
{
	StringLeft,halfclip,Clipboard,200
	ToolTip, Clip %realclipno% of %cursave% %fixstatus%`n%halfclip%
	settimer,ctrlcheck,50
}
return

Cancel:
gui, 15: hide
ToolTip, Cancel Paste Operation`nRelease Control to Confirm
ctrlref = cancel
Hotkey,^Space,fixate,Off
Hotkey,^S,Ssuspnd,Off
Hotkey,^x,Cancel,Off
Hotkey,^x,Delete,On
return

Delete:
ToolTip, Delete the current clip`nRelease Control to Confirm`nPress X Again to Delete All Clips.
ctrlref = delete
Hotkey,^x,Delete,Off
Hotkey,^x,DeleTEall,On
return

Deleteall:
Tooltip, Delete all Clips`nRelease Control to Confirm`nPress X Again to Cancel
ctrlref = deleteall
Hotkey,^x,DeleteAll,Off
Hotkey,^x,Cancel,On
return

NativeCopy:
Critical
Hotkey,$^c,NativeCopy,Off
Hotkey,$^c,Blocker,On
Send, ^c
setTimer,CtrlforCopy,50
gosub, CtrlforCopy
return

NativeCut:
Critical
Hotkey,$^x,NativeCut,Off
Hotkey,$^x,Blocker,On
Send, ^x
setTimer,CtrlforCopy,50
gosub, CtrlforCopy
return

CtrlForCopy:
GetKeyState,Ctrlstate,ctrl
if ctrlstate = u
{
Hotkey,$^c,NativeCopy,on
Hotkey,$^x,NativeCut,on
setTimer,CtrlforCopy,Off
}
return

Blocker:
; debug
if fileappendErr
{
StringLeft,halfclip,Clipboard,200
fileappend ,[%A_now%] blocker cursave: %cursave%  tempsave: %tempsave%  caller: %caller% halfclip: %halfclip%`n, %a_scriptdir%\cache\err.log
}
return

Fixate:
IfExist,%A_ScriptDir%\cache\fixate\%realactive%.fxt
{
	fixstatus := ""
	FileDelete,%A_ScriptDir%\cache\fixate\%realactive%.fxt
}
else
{
	fixstatus := "[FIXED]"
	FileAppend,,%A_ScriptDir%\cache\fixate\%realactive%.fxt
}
IfEqual,clipboard
	Tooltip, Clip %realclipno% of %cursave% %fixstatus%`n
else
	ToolTip, Clip %realclipno% of %cursave% %fixstatus%`n%halfclip%
return

clipsaver:
try {
	fileappend,%ClipboardAll%,%A_ScriptDir%/cache/clips/%cursave%.avc
} catch e {
	ToolTip FileAppend error
	sleep 800
	ToolTip
	fileappend ,[%a_now%] fileappendErr %a_lasterror% cursave: %cursave%  tempsave: %tempsave%  caller: %caller% message: " e.message Extra: e.extra`n, %a_scriptdir%\cache\err.log
}
if ErrorLevel   ; 也就是说它既不是空值，也不是0.
{
	fileappendErr := 1
	StringLeft,halfclip,Clipboard,200
	fileappend ,[%a_now%] fileappendErr %a_lasterror% cursave: %cursave%  tempsave: %tempsave%  caller: %caller% halfclip: %halfclip%`n, %a_scriptdir%\cache\err.log
}
ifnotexist %A_ScriptDir%/cache/clips/%cursave%.avc
{
	StringLeft,halfclip,Clipboard,200
	fileappend ,[%A_now%] fileappendErr %a_lasterror% cursave: %cursave%  tempsave: %tempsave%  caller: %caller% halfclip: %halfclip%`n, %a_scriptdir%\cache\err.log
}

loop,%cursave%
{
tempno := cursave - a_index + 1
IfExist,%A_ScriptDir%\cache\fixate\%tempno%.fxt
{
	t_tempno := tempno + 1
	FileMove,%A_ScriptDir%\cache\clips\%t_tempno%.avc,%A_ScriptDir%\cache\clips\%t_tempno%_a.avc
	FileMove,%A_ScriptDir%\cache\clips\%tempno%.avc,%A_ScriptDir%\cache\clips\%t_tempno%.avc
	FileMove,%A_ScriptDir%\cache\clips\%t_tempno%_a.avc,%A_ScriptDir%\cache\clips\%tempno%.avc
	IfExist,%A_ScriptDir%\cache\thumbs\%tempno%.jpg
	{
		FileMove,%A_ScriptDir%\cache\thumbs\%t_tempno%.jpg,%A_ScriptDir%\cache\thumbs\%t_tempno%_a.jpg
		FileMove,%A_ScriptDir%\cache\thumbs\%tempno%.jpg,%A_ScriptDir%\cache\thumbs\%t_tempno%.jpg
		FileMove,%A_ScriptDir%\cache\thumbs\%t_tempno%_a.jpg,%A_ScriptDir%\cache\thumbs\%tempno%.jpg
	}
	FileMove,%A_ScriptDir%\cache\fixate\%tempno%.fxt,%A_ScriptDir%\cache\fixate\%t_tempno%.fxt
}
}
t_tempno =
tempno = 
if fileappendErr
{
StringLeft,halfclip,Clipboard,200
fileappend ,[%A_now%] clipsaver cursave: %cursave%  tempsave: %tempsave%  caller: %caller% halfclip: %halfclip%`n, %a_scriptdir%\cache\err.log
}
return

fixcheck:
IfExist,%A_ScriptDir%\cache\fixate\%tempsave%.fxt
	fixstatus := "[FIXED]"
else
	fixstatus := ""
return

ctrlcheck:
GetKeyState,ctrlstate,ctrl
if ctrlstate=u
{
	caller := false
	gui, 15: hide
	IfEqual,ctrlref,cancel
	{
		ToolTip, Cancelled
		tempsave := cursave
	}
	else IfEqual,ctrlref,deleteall
	{
		Tooltip,Everything Deleted
		gosub, cleardata
	}
	else IfEqual,ctrlref,delete
	{
		Tooltip,Deleted
		gosub, clearclip
	}
	else
	{
		Tooltip, Pasting...
		if (R_lf)
		{
			if (Substr(Clipboard,-1) == "`r`n")
			{
				CopyMessage = 
				StringTrimRight,Clipboard,clipboard,2
				Send, ^v
				sleep, %generalsleep%
				Loop
				{
					IfExist,%A_ScriptDir%\cache\clips\%cursave%.avc
						break
					else
					{
						fileappend ,[%A_now%] ctrlcheckERR cursave: %cursave%  tempsave: %tempsave%  caller: %caller% `n, %a_scriptdir%\cache\err.log
						ToolTip %cursave%.avc not exist
						sleep 800
						ToolTip
						break
					}
				}
				CopyMessage = Transfered to ClipJump
			}
			else
			{
				If (Substr(Clipboard,-11) == "   --[PATH][")
				{
					StringTrimRight,tempclip,Clipboard,12
					SendInput {RAW} %tempclip%
				}
				else
				{
				CopyMessage = 
				Send, ^v
				sleep, %generalsleep%
				Loop
				{
					IfExist,%A_ScriptDir%\cache\clips\%cursave%.avc
						break
					else
					{
						fileappend ,[%A_now%] ctrlcheckERR cursave: %cursave%  tempsave: %tempsave%  caller: %caller% `n, %a_scriptdir%\cache\err.log
						ToolTip %cursave%.avc not exist
						sleep 800
						ToolTip
						break
					}
				}
				CopyMessage = Transfered to ClipJump
				}
			}
		}
		else
		{
		If (Substr(Clipboard,-11) == "   --[PATH][")
			{
			StringTrimRight,tempclip,Clipboard,12
			SendInput {RAW} %tempclip%
			}
			else
			{
			CopyMessage = 
			Send, ^v
			sleep, %generalsleep%
			Loop
			{
				IfExist,%A_ScriptDir%\cache\clips\%cursave%.avc
					break
				else
				{
					fileappend ,[%A_now%] ctrlcheckERR cursave: %cursave%  tempsave: %tempsave%  caller: %caller% `n, %a_scriptdir%\cache\err.log
					ToolTip %cursave%.avc not exist
					sleep 800
					ToolTip
					break
				}
			}
			CopyMessage = Transfered to ClipJump
			}
		}
		tempsave := realactive
	}
	SetTimer,ctrlcheck,Off
	caller := true
	in_back := false
	tempclip = 
	ctrlref = 
	sleep, 700
	Tooltip
	Hotkey,^S,Ssuspnd,Off
	Hotkey,^c,MoveBack,Off
	Hotkey,^x,Cancel,Off
	Hotkey,^Space,Fixate,Off
	Hotkey,^x,Deleteall,Off
	Hotkey,^x,Delete,Off
	;;
	Hotkey,$^c,NativeCopy,On
	Hotkey,$^x,NativeCut,On
	;;
	EmptyMem()
}
return

Ssuspnd:
SetTimer,ctrlcheck,Off
ctrlref = 
tempsave := realactive
Hotkey,^c,MoveBack,Off
Hotkey,^x,Cancel,Off
Hotkey,^Space,Fixate,Off
Hotkey,^x,Deleteall,Off
Hotkey,^x,Delete,Off
Hotkey,^S,Ssuspnd,Off
;;
Hotkey,$^c,NativeCopy,On
Hotkey,$^x,NativeCut,On
;;
in_back := false
caller := false
addtowinclip(realactive, "has Clip " . realclipno)
caller := true
Gui, 15: hide
return

compacter:
loop, %threshold%
{
	FileDelete,%A_ScriptDir%\cache\clips\%a_index%.avc
	FileDelete,%A_ScriptDir%\cache\thumbs\%a_index%.jpg
	FileDelete,%A_ScriptDir%\cache\fixate\%a_index%.fxt
}
loop, %maxclips%
{
	avcnumber := a_index + threshold
	FileMove,%a_scriptdir%/cache/clips/%avcnumber%.avc,%A_ScriptDir%/cache/clips/%a_index%.avc
	filemove,%a_scriptdir%/cache/thumbs/%avcnumber%.jpg,%a_scriptdir%/cache/thumbs/%a_index%.jpg
	filemove,%a_scriptdir%/cache/fixate/%avcnumber%.fxt,%a_scriptdir%/cache/fixate/%a_index%.fxt
}
cursave := maxclips
tempsave := cursave
if fileappendErr
{
StringLeft,halfclip,Clipboard,200
fileappend ,[%A_now%] compacter cursave: %cursave%  tempsave: %tempsave%  caller: %caller% halfclip: %halfclip%`n, %a_scriptdir%\cache\err.log
}
return

cleardata:
LastClip := 
FileDelete,%A_ScriptDir%\cache\clips\*.avc
FileDelete,%A_ScriptDir%\cache\thumbs\*.jpg
FileDelete,%A_ScriptDir%\cache\fixate\*.fxt
; howiefh
IniWrite,%lastclip%,%A_ScriptDir%\cache\%applicationname%cache.txt,Clipjump,lastclip
; howiefh
cursave := 0
tempsave := 0
return

clearclip:
LastClip := 
FileDelete,%A_ScriptDir%\cache\clips\%realactive%.avc
FileDelete,%A_ScriptDir%\cache\thumbs\%realactive%.jpg
FileDelete,%A_ScriptDir%\cache\fixate\%realactive%.fxt
; howiefh
IniWrite,%lastclip%,%A_ScriptDir%\cache\%applicationname%cache.txt,Clipjump,lastclip
; howiefh
tempsave := realactive - 1
if (tempsave == 0)
	tempsave := 1
gosub, renamecorrect
cursave-=1
return

renamecorrect:
looptime := cursave - realactive
If (looptime != 0)
{
loop,%looptime%
{
	newname := realactive
	realactive+=1
	FileMove,%A_ScriptDir%/cache/clips/%realactive%.avc,%A_ScriptDir%/cache/clips/%newname%.avc
	FileMove,%A_ScriptDir%/cache/thumbs/%realactive%.jpg,%A_ScriptDir%/cache/thumbs/%newname%.jpg
	FileMove,%A_ScriptDir%/cache/fixate/%realactive%.fxt,%A_ScriptDir%/cache/fixate/%newname%.fxt
}
}
return

thumbgenerator:
ClipWait,,1
Convert(0, A_ScriptDir . "\cache\thumbs\" . cursave . ".jpg", quality)
return

showpreview:
GDIPToken := Gdip_Startup()
pBM := Gdip_CreateBitmapFromFile( A_ScriptDir . "\cache\thumbs\" . tempsave . ".jpg" )
widthofthumb := Gdip_GetImageWidth( pBM )
heightofthumb := Gdip_GetImageHeight( pBM )  
Gdip_DisposeImage( pBM )                                         
Gdip_Shutdown( GDIPToken )

IfGreater,heightofthumb,%scrnhgt%
	displayh := heightofthumb / 2
else
	displayh := heightofthumb
IfGreater,widthofthumb,%scrnwdt%
	displayw := widthofthumb / 2
else
	displayw := widthofthumb

GuiControl, 15:,imagepreview,*w%displayw% *h%displayh% cache\thumbs\%tempsave%.jpg
MouseGetPos,ax,ay
ay := ay + (scrnhgt / 8)
Gui, 15:Show, x%ax% y%ay% h%displayh% w%displayw%
return

;****************COPY FILE/FOLDER******************************************************************************

copyfile:
CopyMessage = File Path(s) copied to Clipjump
selectedfile := GetFile()
IfNotEqual,selectedfile
	Clipboard := selectedfile . "   --[PATH]["
sleep, %generalsleep%
CopyMessage = Transfered to Clipjump
return

copyfolder:
CopyMessage = Active Folder Path copied to Clipjump
openedfolder := GetFolder()
IfNotEqual,openedfolder
	Clipboard := openedfolder . "   --[PATH]["
sleep, %generalsleep%
Copymessage = Transfered to Clipjump
return


;******FUNCTIONS*************************************************

addtowinclip(lastentry, extratip)
{
ToolTip, Windows Clipboard %extratip%
IfNotEqual,cursave,0
	fileread,Clipboard,*c %A_ScriptDir%/cache/clips/%lastentry%.avc

IF (Substr(Clipboard,-11) == "   --[PATH][")
	StringTrimRight,Clipboard,Clipboard,12
sleep, 1000
ToolTip
}
; EmptyMem()
; {
; return, dllcall("psapi.dll\EmptyWorkingSet", "UInt", -1)
; }

GetFile(hwnd="")
{
	hwnd := hwnd ? hwnd : WinExist("A")
	WinGetClass class, ahk_id %hwnd%
	if (class="CabinetWClass" or class="ExploreWClass" or class="Progman")
		for window in ComObjCreate("Shell.Application").Windows
			if (window.hwnd==hwnd)
    sel := window.Document.SelectedItems
	for item in sel
	ToReturn .= item.path "`n"
	return Trim(ToReturn,"`n")
}

GetFolder()
{
	WinGetClass,var,A
	If var in CabinetWClass,ExplorerWClass,Progman
	{
		IfEqual,var,Progman
			v := A_Desktop
		else
		{
			winGetText,Fullpath,A
			loop,parse,Fullpath,`r`n
			{
			IfInString,A_LoopField,:\
			{
				StringGetPos,pos,A_Loopfield,:\,L
				Stringtrimleft,v,A_loopfield,(pos - 1)
				break
			}
		}
		}
		return, v
	}
}
;;;;;;;;;;;;;;;;;;;;;;;;;;Clipjump end;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ScreenCapture ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
makeScreenCaptureMenu:
Menu, Tray, Add
Menu, ScreenCapture, Add, 清空截图, clearpics 
Menu, Tray, Add, 截屏, :ScreenCapture
return
;*=====================================================================================================================

capture:
gui, 18:destroy
; make selected area gui
gosub makeTransGui
; esc 退出截图
Hotkey,%SC_PrimaryHotkey%,captureFullScreen,On
Hotkey ,Esc, escapeCapture, On
isEscapeCapture := false
; 创建目录
IfNotExist, %SC_CaptureDir%
	FileCreateDir, %SC_CaptureDir%

; 时间文件名
FormatTime, SC_TimeStamp, , yyyyMMdd_HHmmss
SC_CaptureFileName = %SC_CaptureDir%\ScreenShot_%SC_TimeStamp%.%SC_CaptureExtension%
; 要截取窗口的位置坐标
SetTimer, Get_win_pos, 100
return

captureFullScreen:
gosub escapeCapture
SC_isright := true
SC_isdown := true
SysGet, SC_initialx, 76
SysGet, SC_initialy, 77
SysGet, SC_finalx, 78
SysGet, SC_finaly, 79
gosub save_screenshot
Return

Get_win_pos:
; 获取光标下方窗口、控件位置
	MouseGetPos, CaptureMouseX, CaptureMouseY, WhichWindow, WhichControl
	WinGetPos, SC_winX, SC_winY, SC_winW, SC_winH,ahk_id %WhichWindow%
    ControlGetPos, SC_controlX, SC_controlY, SC_controlW, SC_controlH, %WhichControl%, ahk_id %WhichWindow%
	IfEqual ,WhichControl
	{
		gui, 19: show, x%SC_winX% y%SC_winY% h%SC_winH% w%SC_winW%
		; ToolTip, %WhichWindow%`nX%SC_winX%`tY%SC_winY%`nW%SC_winW%`t%SC_winH%, CaptureMouseX+10, CaptureMouseY+10
		ToolTip, %WhichWindow%`nX%SC_winX%`tY%SC_winY%`nW%SC_winW%`t%SC_winH%
		SC_initialx := SC_winX
		SC_initialy := SC_winY
		SC_finalx := SC_initialx + SC_winW
		SC_finaly := SC_initialy + SC_winH
	}
	else
	{
		; 控件坐标是相对窗口的
		SC_controlX := SC_winX + SC_controlX
		SC_controlY := SC_winY + SC_controlY
		gui, 19: show, x%SC_controlX% y%SC_controlY% h%SC_controlH% w%SC_controlW%
		; ToolTip, %WhichControl%`nX%SC_controlX%`tY%SC_controlY%`nW%SC_controlW%`t%SC_controlH%, CaptureMouseX+10, CaptureMouseY+10
		ToolTip, %WhichControl%`nX%SC_controlX%`tY%SC_controlY%`nW%SC_controlW%`t%SC_controlH%
		SC_initialx := SC_winX
		SC_initialy := SC_winY
		SC_finalx := SC_initialx + SC_winW
		SC_finaly := SC_initialy + SC_winH
	}

	GetKeyState, SC_SecondaryHotkeyState,%SC_SecondaryHotkey%, P ;;获取%SC_SecondaryHotkey%状态判断是否按下,注意★这里使用获取方式P要比T稳定,如果使用T会导致无法全选很不稳定
	; %SC_SecondaryHotkey%按下
	if SC_SecondaryHotkeyState = D
	{
		SetTimer, Get_win_pos, off
		; 鼠标初始位置
		MouseGetPos,SC_initialx,SC_initialy
		SetTimer,guimover,100
		KeyWait,%SC_SecondaryHotkey%
		sleep, 120																		;Should use 100, but just to be safe..!
		SetTimer,guimover,off
		; gui, 19:hide
		gui, 19:destroy
		tooltip
		; 鼠标终位置
		MouseGetPos,SC_finalx,SC_finaly
	
		if (!(isEscapeCapture))
		{
			gosub save_screenshot
		}
	}
Return

save_screenshot:
; 截完图恢复原快捷键功能
Hotkey,%SC_PrimaryHotkey%,captureFullScreen,Off
Hotkey,%SC_PrimaryHotkey%,capture,On
; 鼠标初始位置等于终止位置，即认为是单击事件，截取的是光标下的窗口或控件
if SC_initialx = %SC_finalx%
{
	IfEqual ,WhichControl
	{
		SC_initialx := SC_winX
		SC_initialy := SC_winY
		SC_finalx := SC_initialx + SC_winW
		SC_finaly := SC_initialy + SC_winH
	}
	else
	{
		SC_controlX := SC_winX + SC_controlX
		SC_controlY := SC_winY + SC_controlY
		SC_initialx := SC_controlX
		SC_initialy := SC_controlY
		SC_finalx := SC_initialx + SC_controlW
		SC_finaly := SC_initialy + SC_controlH
	}
}
; 鼠标初始位置不等于终止位置，即认为是鼠标拖拽事件，截取的是拖拽鼠标选中的区域
else
{
	if (!(SC_isright)) {
		SC_intmdx := SC_finalx
		SC_finalx := SC_initialx
		SC_initialx := SC_intmdx
	}
	if (!(SC_isdown))
	{
		SC_intmdy := SC_finaly
		SC_finaly := SC_initialy
		SC_initialy := SC_intmdy
	}
}

CaptureScreen(SC_initialx, SC_initialy, SC_finalx, SC_finaly, (SC_finalx - SC_initialx), (SC_finaly - SC_initialy), False, SC_CaptureFileName, SC_qualityofpic)

If (SC_actionafterfinish)
{
	gosub makeSelectActionGui
	GuiControl, 18:,DirEdit,%SC_CaptureFileName%
}
EmptyMem()
return

escapeCapture:
isEscapeCapture := true
Hotkey ,Esc, escapeCapture, Off
SetTimer, Get_win_pos, off
SetTimer,guimover,off
tooltip
; gui, 19:hide
gui, 19:destroy
Return
/*
SUBS==========================================================================|
*/

guimover:
MouseGetPos,tempx,tempy
CaptureWidth := tempx - SC_initialx
CaptureHeight := tempy - SC_initialy
IfGreater,tempx,%SC_initialx%
	SC_isright := true
else
	SC_isright := false
IfGreater,tempy,%SC_initialy%
	SC_isdown := true
else
	SC_isdown := false

If !(SC_isright)
	CaptureWidth := SC_initialx - tempx
If !(SC_isdown)
	CaptureHeight := SC_initialy - tempy

;Anti-Movement Handling  :)
if (!(SC_isright) and !(SC_isdown))
	gui, 19:show, x%tempx% y%tempy% h%CaptureHeight% w%CaptureWidth%
	else if (!(SC_isright))
		gui, 19:show, x%tempx% y%SC_initialy% h%CaptureHeight% w%CaptureWidth%
		else if (!(SC_isdown))
			gui, 19:show, x%SC_initialx% y%tempy% h%CaptureHeight% w%CaptureWidth%
			else
				gui, 19:show, x%SC_initialx% y%SC_initialy% h%CaptureHeight% w%CaptureWidth%
return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
makeTransGui:
CustomColor = EEAA99
Gui, 19:Color, %SC_CaptureGuiColor%
gui, 19:+Lastfound +AlwaysOnTop -Caption +ToolWindow
WinSet, TransColor, %CustomColor% 50
Return
;
makeSelectActionGui:
Gui, 18:Add, Button, x452 y20 w70 h30 , SaveAs
Gui, 18:Add, Button, x62 y60 w70 h30 , OpenDir
Gui, 18:Add, Button, x202 y60 w70 h30 , Open
Gui, 18:Add, Button, x332 y60 w70 h30 , Cancel
gui, 18:Font, S10 CBlack, Verdana
Gui, 18:Add, Edit, x32 y20 w400 h30 -Wrap -VScroll +ReadOnly vDirEdit,
Gui, 18:Show, x321 y167 h115 w554, Select Action
Return

18ButtonSaveAs:
FileSelectFile, SC_SaveFile, S, %SC_CaptureFileName%, Save As,JPEG(*.jpg)
if SC_SaveFile =
{
}
else
{
	GuiControl, 18:,DirEdit,%SC_SaveFile%
	FileMove, %SC_CaptureFileName%, %SC_SaveFile%
	SC_CaptureFileName = %SC_SaveFile%
}
Return

18ButtonOpenDir:
msgbox %SC_capturedirName%
IfWinNotExist,%SC_capturedirName% ahk_class CabinetWClass
	run Explorer /select`,%SC_CaptureFileName%
else
	WinActivate, %SC_capturedirName% ahk_class CabinetWClass
Return

18ButtonOpen:
run, %SC_openCaptureSoft% %SC_CaptureFileName%
Return

18guiclose:
18ButtonCancel:
Gui, 18:destroy
Return

clearpics:
filedelete %SC_CaptureDir%
return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ScreenCapture ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
f_ShowMenuX:
Menu, THISISASECRETMENU, Show
return

ListLines:
ListLines
return

ListVars:
ListVars
return

ListHotkeys:
ListHotkeys
return

KeyHistory:
KeyHistory
return
;onexit
CleanUp:
GoSub showalldesktops
GoSub ROL_ExitHandler
GoSub AOT_ExitHandler
GoSub TRA_ExitHandler
ExitApp

; vim:fdm=marker

