@echo off
rem
rem   Define the variables for running builds from this source library.
rem
set srcdir=can
set buildname=
call treename_var "(cog)source/can" sourcedir
set libname=can
set fwname=
set pictype=
set picclass=
set t_parms=
call treename_var "(cog)src/%srcdir%/debug_%fwname%.bat" tnam
make_debug "%tnam%"
call "%tnam%"
