#Requires AutoHotkey v2.0
#SingleInstance Force

#b::Run "firefox.exe"
#Enter::Run "wt.exe"
#q::WinClose "A"

!Left::Send "{Blind}+{Tab}"
!Right::Send "{Blind}{Tab}"
