@echo off
@setlocal
@set IMP_HOME=%IMP_INSTALL_HOME%
@rem just removed the \bin\ (last 5 characters) from the path

@set PERM_HOME=%IMP_HOME%\include
@set P1_HOME=%IMP_HOME%\bin
@set P2_HOME=%IMP_HOME%\bin
@set P3_HOME=%IMP_HOME%\bin
@set LIB_HOME=%IMP_HOME%\lib

@echo.
@call :foreach_pass1 %*
@call :foreach_pass2 %*
@call :foreach_generate_pascal %*
@call :foreach_generate_c %*
@call :do_link %*

@echo ******************
@echo **** ALL DONE ****
@echo ******************
@goto :exit

:foreach_pass1
@echo *****************************
@echo **** Start PASS1 phase for %*
@echo *****************************
@echo.
:next_pass1
@if "%1"=="" goto :last_pass1

@echo     Generating icd file "%1.icd from %1.imp"
@%P1_HOME%\pass1 %1.imp,%PERM_HOME%\stdperm.imp %1.icd:b,%1.lst
@if not errorlevel 0 @goto error_pass1
@echo.
@goto shift_pass1

:error_pass1
@echo **** ERROR **** in pass1 for %1
@goto :shift_pass1

:shift_pass1
@shift
@goto next_pass1

:last_pass1
@echo *************************
@echo **** End PASS1 phase ****
@echo *************************
@echo.
exit/b


:foreach_pass2
@echo *****************************
@echo **** Start PASS2 phase for %*
@echo *****************************
@echo.
:next_pass2
@if "%1"=="" goto :last_pass2

@echo     Generating ibj file "%1.ibj from %1.icd"
@%P2_HOME%\pass2 %1.icd:b,%1.imp %1.ibj,%1.cod
@if not errorlevel 0 @goto error_pass2
@for /F "usebackq" %%A IN ('%1.ibj') DO set ibj_size=%%~zA
@if %ibj_size%==0 @goto missing_ibj_pass2
@ibj2assembler %1.ibj %1.assembler

@echo.
@goto shift_pass2

:error_pass2
@echo **** ERROR **** in pass2 for %1
@goto :shift_pass2

:missing_ibj_pass2
@echo **** ERROR **** in pass2. No ibj file generated for %1
@goto :shift_pass2

:shift_pass2
@shift
@goto next_pass2

:last_pass2
@echo *************************
@echo **** End PASS2 phase ****
@echo *************************
@echo.
exit/b

:foreach_generate_pascal
@echo *****************************************************
@echo **** Start OBJECT phase using PASCAL generator for %*
@echo *****************************************************
@echo.
:next_generate_pascal
@if "%1"=="" goto :last_generate_pascal

@%P3_HOME%\ibj2coff %1.ibj  %1.nobj
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

:foreach_generate_c
@echo ************************************************
@echo **** Start OBJECT phase using C generator for %*
@echo ************************************************
@echo.
:next_generate_c
@if "%1"=="" goto :last_generate_c

@%P3_HOME%\pass3 %1.ibj  %1.obj
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

:do_dump
@echo         Dumping the .%1.%2 into .lis, .dump files
@echo.
@coff2dump                 %1.%2      %1.%2.lis
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
