@setlocal
@echo off


@echo.
@call :do_link %*

@echo ******************
@echo **** ALL DONE ****
@echo ******************
@goto :end

:do_link
@echo off
setlocal enabledelayedexpansion
@echo ********************************************
@echo **** Linking OBJECT files from %*
@echo ********************************************
@echo.

set objlist=
set argCount=0
for %%x in (%*) do (
   set /A argCount+=1
   set "objlist=!objlist! %%~x.obj"
)
@echo Number of object files to link: %argCount% generating list %objlist%
@echo.

@set LIB_HOME=%IMP_INSTALL_HOME%\lib
@link /nologo /SUBSYSTEM:CONSOLE /stack:0x800000,0x800000 /MAPINFO:EXPORTS /MAP:%1.map /OUT:%1.exe /DEFAULTLIB:%LIB_HOME%\libi77.lib %objlist% %LIB_HOME%\libi77.lib
@rem link /nologo /SUBSYSTEM:CONSOLE /stack:0x800000,0x800000 /heap:0x800000,0x800000 /OUT:%1.exe /DEFAULTLIB:%LIB_HOME%\libi77.lib %objlist% %LIB_HOME%\libi77.lib
@echo.
@endlocal
exit/b

:end
@endlocal
@echo on
