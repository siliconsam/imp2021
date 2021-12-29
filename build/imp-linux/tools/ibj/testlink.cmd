@echo off
@setlocal
@rem Build the ibj2coff program (== new Pascal version of the pass3 program)
@rem This program generates COFF object files from the .ibj input file
@fpc -gl assembler2ibj
@fpc -gl coff2dump
@fpc -gl ibj2assembler
@fpc -gl ibj2coff
@fpc -gl ibj2compact

@echo.
call :foreach_assemble %*
call :foreach_generate_c %*
call :foreach_generate_pascal %*
call :do_link %*

@echo ******************
@echo **** ALL DONE ****
@echo ******************
@goto :exit

:foreach_assemble
@echo ********************************
@echo **** Start ASSEMBLE phase for %*
@echo ********************************
@echo.
:next_assemble
@if "%1"=="" goto :last_assemble

@echo     Generating assembler file "%1.assemble from %1.ibj"
@ibj2assembler %1.ibj %1.assembler
@echo.

@shift
@goto next_assemble

:last_assemble
@echo ****************************
@echo **** End ASSEMBLE phase ****
@echo ****************************
@echo.
exit/b

:foreach_generate_c
@echo ************************************************
@echo **** Start OBJECT phase using C generator for %*
@echo ************************************************
@echo.
:next_generate_c
@if "%1"=="" goto :last_generate_c

@pass3    %1.ibj  %1.obj
@echo.

@call :do_dump %1 obj
@echo.

@shift
@goto next_generate_c

:last_generate_c
@echo ********************************************
@echo **** End OBJECT phase using C generator ****
@echo ********************************************
@echo.
exit/b

:foreach_generate_pascal
@echo *****************************************************
@echo **** Start OBJECT phase using PASCAL generator for %*
@echo *****************************************************
@echo.
:next_generate_pascal
@if "%1"=="" goto :last_generate_pascal

@ibj2coff %1.ibj  %1.nobj
@echo.

@call :do_dump %1 nobj
@echo.

@shift
@goto next_generate_pascal

:last_generate_pascal
@echo *************************************************
@echo **** End OBJECT phase using PASCAL generator ****
@echo *************************************************
@echo.
exit/b

:do_dump
@echo         Dumping the .%1.%2 into .lis, .dump files
@echo.
@readobj           %1.%2      %1.%2.lis
@dumpbin /nologo /all /out:%1.%2.dump %1.%2
exit/b

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
   set "objlist=!objlist! %%~x.nobj"
)
@echo Number of object files to link: %argCount% generating list %objlist%
@echo.

@set LIB_HOME=%IMP_INSTALL_HOME%\lib
@link /nologo /stack:80000000,80000000 /heap:80000000,80000000 /OUT:%1.exe %LIB_HOME%\runimp.obj %objlist% %LIB_HOME%\libi77.lib
@echo.
@endlocal
exit/b

:exit
@endlocal
@echo on
