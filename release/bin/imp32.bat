@setlocal
@echo off
@set COM_HOME=%~dp0
@set IMP_HOME=%COM_HOME:~0,-5%
@rem just removed the \bin\ (last 5 characters) from the path

@set PERM_HOME=%IMP_HOME%\include
@set P1_HOME=%IMP_HOME%\bin
@set P2_HOME=%IMP_HOME%\bin
@set P3_HOME=%IMP_HOME%\bin
@set LIB_HOME=%IMP_HOME%\lib

@set FILESEP=/
@set dolink=yes
@set docode=no
@set dolist=no
@set doicd=no
@set doheap=no
@set dopass3=yes

:parseargs
@if "%1"=="" @goto help
@if "%1"=="/?" @goto help
@if "%1"=="/h" @goto help
@if "%1"=="/H" @goto help
@if "%1"=="-h" @goto help
@if "%1"=="-H" @goto help
@if "%1"=="/c" @goto clearlink
@if "%1"=="-c" @goto clearlink
@if "%1"=="/Fc" @goto setcode
@if "%1"=="-Fc" @goto setcode
@if "%1"=="/FC" @goto setcode
@if "%1"=="-FC" @goto setcode
@if "%1"=="/Fs" @goto setlist
@if "%1"=="-Fs" @goto setlist
@if "%1"=="/FS" @goto setlist
@if "%1"=="-FS" @goto setlist
@if "%1"=="/Fi" @goto seticd
@if "%1"=="-Fi" @goto seticd
@if "%1"=="/FI" @goto seticd
@if "%1"=="-FI" @goto seticd
@if "%1"=="/Fh" @goto setheap
@if "%1"=="-Fh" @goto setheap
@if "%1"=="/FH" @goto setheap
@if "%1"=="-FH" @goto setheap
@if "%1"=="/Fp" @goto clearpass3
@if "%1"=="-Fp" @goto clearpass3
@if "%1"=="/FP" @goto clearpass3
@if "%1"=="-FP" @goto clearpass3
@rem here it must be a filename
@goto compile

:clearlink
@set dolink=no
@shift
@goto parseargs

:setcode
@set docode=yes
@shift
@goto parseargs

:setlist
@set dolist=yes
@shift
@goto parseargs

:seticd
@set doicd=yes
@shift
@goto parseargs

:setheap
@set doheap=yes
@shift
@goto parseargs

:clearpass3
@set dopass3=no
@shift
@goto parseargs

:compile
@if exist %1.imp @set source=%1.imp
@if exist %1.i @set source=%1.i
@if not exist %source% @goto nosource

@rem set up our files
@set codefile=NUL
@if "%docode%"=="yes" @set codefile=%1.cod

@set listfile=NUL
@if "%dolist%"=="yes" @set listfile=%1.lst

@%P1_HOME%\pass1 %source%,%PERM_HOME%\stdperm.imp=%1.icd:b,%listfile%
@if not errorlevel 0 @goto bad_parse_end

@%P2_HOME%\pass2 %1.icd:b,%source%=%1.ibj,%codefile%
@if not errorlevel 0 @goto bad_codegen_end
@for /F "usebackq" %%A IN ('%1.ibj') DO set ibj_size=%%~zA
@if %ibj_size%==0 @goto no_ibj_file 
@if "%doicd%"=="no" @del %1.icd

@if "%dopass3%"=="no" @goto end
@%P3_HOME%\pass3coff %1.ibj %1.obj
@if not errorlevel 0 @goto bad_objgen_end
@if "%doicd%"=="no" @del %1.ibj

@if "%dolink%"=="no" @goto end
@if "%doheap%"=="no" @goto noheap
@goto yesheap

:noheap
@link /nologo /SUBSYSTEM:CONSOLE /stack:0x800000,0x800000 /MAPINFO:EXPORTS /MAP:%1.map /OUT:%1.exe /DEFAULTLIB:%LIB_HOME%\libi77.lib %1.obj %LIB_HOME%\libi77.lib
@goto postlink

:yesheap
@link /nologo /SUBSYSTEM:CONSOLE /stack:0x800000,0x800000 /heap:0x800000,0x800000 /MAPINFO:EXPORTS /MAP:%1.map /OUT:%1.exe /DEFAULTLIB:%LIB_HOME%\libi77.lib %1.obj %LIB_HOME%\libi77.lib
@goto postlink

:postlink
@if "%doicd%"=="no" @del %1.obj
@goto end

:nosource
@echo Source file not found?

:help
@echo Usage: IMP32 [-c] [-Fc] [-Fs] [-Fi] basename
@echo where basename is the source file (without .IMP extension)
@echo       -c       inhibits the link phase
@echo       -Fc      produces a .COD file with interleaved source and assembler
@echo       -Fs      produces a .LST source listing file
@echo       -Fi      retains the .ICD and .IBJ files for debugging
@echo       -Fh      requests the use of heap storage
@echo       -Fp      skip the .obj generation stage
@goto end

:bad_parse_end
@echo Error detected in Pass1 - The lexer/parser stage generating the iCode
@goto end

:bad_codegen_end
@echo Error detected in Pass2 - The machine code generator reading the iCode
@goto end

:no_ibj_file
@echo Error detected in Pass2 - No machine code generated
@goto end

:bad_objgen_end
@echo Error detected in Pass3 - The object file generator
@goto end

:end
@endlocal
