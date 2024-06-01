@echo off
rem
rem   Set up for building a Pascal module.
rem
call build_vars

call src_get %srcdir% %libname%.ins.pas
call src_get %srcdir% %libname%2.ins.pas
call src_get %srcdir% %libname%3.ins.pas

call src_getbase
call src_getfrom pic pic.ins.pas
call src_getfrom stuff stuff.ins.pas
call src_getfrom ioext usbcan usbcan.ins.pas

call src_builddate "%srcdir%"
