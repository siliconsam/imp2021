@echo off
@setlocal
@set COM_HOME=%~dp0
@rem now remove the \compiler\ (last 10 characters) from the script directory variable
@set DEV_HOME=%COM_HOME:~0,-10%

@rem First tidy up
@if exist *.lst del *.lst
@if exist *.exe del *.exe
@if exist *.obj del *.obj
@if exist *.cod del *.cod
@if exist *.ibj del *.ibj
@if exist *.icd del *.icd
@if exist i77.*_debug del i77.*_debug

@rem compile the takeon lexer/parser table generator using new development library
@call :i32 takeon
@call :dolink takeon

@echo     *******************************************************************************
@echo     *    Form the "development" parse/lex tables from the grammar using takeon    *
@echo     *******************************************************************************
@%DEV_HOME%\compiler\takeon i77.grammar=i77.tables.imp,i77.par_debug,i77.lex_debug
@echo.
@echo     *******************************************************************************
@echo     *    Compile pass1 with the "released" versions of pass1,pass2                *
@echo     *******************************************************************************
@call :i32 pass1

@echo.
@echo     *******************************************************************************
@echo     *    Compile pass2 with the "released" versions of pass1,pass2                *
@echo     *******************************************************************************
@call :i32 pass2

@echo.
@echo     *******************************************************************************
@echo     *    Build pass1,pass2 with "development" pass3 and link to new library       *
@echo     *******************************************************************************
@call :dolink pass1
@call :dolink pass2

@echo.
@echo     *******************************************************************************
@echo     *    Compile pass1 with the "development" versions of pass1,pass2             *
@echo     *******************************************************************************
@call :i32x pass1

@echo.
@echo     *******************************************************************************
@echo     *    Compile pass2 with the "development" versions of pass1,pass2             *
@echo     *******************************************************************************
@call :i32x pass2

@echo.
@echo     *******************************************************************************
@echo     *    Build pass1,pass2 with "development" pass3 and link to new library       *
@echo     *******************************************************************************
@call :dolink pass1
@call :dolink pass2

@echo.
@echo     *******************************************************************************
@echo     *    At this point pass1,pass2 have compiled themselves.                      *
@echo     *******************************************************************************
@goto the_end

:i32
@set source=%1
@%IMP_INSTALL_HOME%\bin\pass1 %source%.imp,..\lib\stdperm.imp=%source%.icd:b,%source%.lst
@%IMP_INSTALL_HOME%\bin\pass2 %source%.icd:b,%source%.imp=%source%.ibj,%source%.cod
exit/b

:i32x
@set source=%1
@%DEV_HOME%\compiler\pass1 %source%.imp,..\lib\stdperm.imp=%source%.icd:b,%source%.lst
@%DEV_HOME%\compiler\pass2 %source%.icd:b,%source%.imp=%source%.ibj,%source%.cod
exit/b

:dolink
@%DEV_HOME%\pass3\pass3coff %1.ibj %1.obj
@%IMP_INSTALL_HOME%\bin\coff2dump %1.obj %1.dump
@link /nologo /stack:0x800000,0x800000 /SUBSYSTEM:CONSOLE /DEFAULTLIB:%DEV_HOME%\lib\libi77.lib /OUT:%1.exe %1.obj %DEV_HOME%\lib\libi77.lib
exit/b

:the_end
@endlocal
