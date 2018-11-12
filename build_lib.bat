@echo off
rem
rem   BUILD_LIB [-dbg]
rem
rem   Build the CAN library.
rem
setlocal
call build_pasinit

call src_insall %srcdir% %libname%

call src_get %srcdir% %libname%3.insall.pas
if exist %libname%3.h del %libname%3.h
sst %libname%3.insall.pas -show_unused 0 -local_ins -ins %libname%3.ins.pas
rename %libname%3.insall.c %libname%3.h

call src_pas %srcdir% %libname%_add %1
call src_pas %srcdir% %libname%_devlist %1
call src_pas %srcdir% %libname%_open %1
call src_pas %srcdir% %libname%_queue %1
call src_pas %srcdir% %libname%_recv %1
call src_pas %srcdir% %libname%_send %1
call src_pas %srcdir% %libname%_usbcan %1

call src_lib %srcdir% %libname%
call src_msg %srcdir% %libname%
