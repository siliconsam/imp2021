@echo off
@setlocal EnableDelayedExpansion
@rem Build the npass3 (== new pass3 program)
@rem This program generates COFF object files from the .ibj input file
@fpc -gl ibj2coff
@fpc -gl ibj2compact
@fpc -gl ibj2assembler
@fpc -gl assembler2ibj
@fpc -gl coff2dump

call :foreach_compact %*
call :foreach_assemble %*
call :foreach_generate %*
call :do_link %*

@echo ******************
@echo **** ALL DONE ****
@echo ******************
@goto :exit

:foreach_compact
@echo ***********************
@echo **** COMPACT PHASE ****
@echo ***********************
@setlocal EnableDelayedExpansion
:next_compact
@if "%1"=="" goto :last_compact

@echo Compact the original ibj file "%1.ibj" to form "%1.compact.ibj"
@ibj2compact %1.ibj %1.compact.ibj

@shift
@goto next_compact
:last_compact
endlocal
exit/b

:foreach_assemble
@echo ****************************
@echo **** GENERATE ASSEMBLER ****
@echo ****************************
@setlocal EnableDelayedExpansion
:next_assemble
@if "%1"=="" goto :last_assemble

@rem for %%e in (ibj,ibj.compact) do (
@for %%e in (ibj) do (

@if "%%e"=="ibj" (
@echo From original ibj file "%1.ibj"
@echo     Generating assembler file "%1.assembler"

@ibj2assembler %1.ibj %1.assembler
)
@if "%%e"=="ibj.compact" (
@echo From compact ibj file "%1.%%e"
@echo     Generating assembler file "%1.%%e.assembler"

@ibj2assemble %1.compact.ibj %1.compact.assembler
)
)

@shift
@goto next_assemble
:last_assemble
@endlocal
exit/b

:foreach_generate
@echo *******************************
@echo **** GENERATE OBJECT FILES ****
@echo *******************************
@setlocal EnableDelayedExpansion
:next_generate
@if "%1"=="" goto :last_generate

@rem for %%e in (ibj,ibj.compact) do (
@for %%e in (ibj) do (

@if "%%e"=="ibj"         @echo From original ibj file "%1.ibj"
@if "%%e"=="compact.ibj" @echo From the compacted ibj file "%1.compact.ibj"

@echo     Using C version
@call :do_object pass3 %1 %%e obj
@call :do_dump %1 %%e obj

@echo     Using Pascal version
@call :do_object ibj2coff %1 %%e nobj
@call :do_dump %1 %%e nobj
)

@shift
@goto next_generate
:last_generate
@endlocal
exit/b

:do_object
@echo         Generate the .%4 file

@@%1                %2.%3         %2.%3.%4
exit/b

:do_dump
@echo         Dumping the .%3, .lis, .dump files

@@coff2dump         %1.%2.%3      %1.%2.%3.lis
@@dumpbin /all /out:%1.%2.%3.dump %1.%2.%3
exit/b

:do_link
@echo off
setlocal enabledelayedexpansion

set list=
set argCount=0
for %%x in (%*) do (
   set /A argCount+=1
   set "list=!list! %%~x.ibj.nobj"
)
echo Number of processed arguments: %argCount%

echo Coff object files to link: %list%
@set LIB_HOME=%IMP_INSTALL_HOME%\lib
@link /nologo /stack:80000000,80000000 /heap:80000000,80000000 /OUT:%1.exe %LIB_HOME%\runimp.obj %list% %LIB_HOME%\libi77.lib
@endlocal
exit/b

:exit
@endlocal
@echo on