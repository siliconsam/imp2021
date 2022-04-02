@setlocal
@set COM_HOME=%~dp0
@rem now remove the \lib\ (last 10 characters) from the script directory variable
@set DEV_HOME=%COM_HOME:~0,-5%

@set driver=i32

@set option=-DMSVC

:parseargs
@if "%1"=="gcc" @goto clearoption
@rem if "%1"=="" @goto setoption
@rem if here parameter assumed to be the build folder
@goto clearit

:clearoption
@rem Use this parameter to indicate we are using the Microsoft C compiler, linker and libraries
@set option=
@shift
@goto parseargs

:setoption
@rem Use this parameter to indicate we are using the Microsoft C compiler, linker and libraries
@set option=-DMSVC
@shift
@goto parseargs

:clearit
@if exist *.assemble del *.assemble
@if exist *.cod      del *.cod
@if exist *.dump     del *.dump
@if exist *.ibj      del *.ibj
@if exist *.icd      del *.icd
@if exist *.lst      del *.lst
@if exist *.obj      del *.obj

@goto runit

:runit
@rem Compile the C implemented primitives code
@rem The possible parameter 
@cl /nologo /Gd /c /Gs /W3 /Od /arch:IA32 -D_CRT_SECURE_NO_WARNINGS %option% /FAscu /Foprim-rtl-file.obj /Faprim-rtl-file.lst prim-rtl-file.c

@rem Compile the IMP77 implemented library code
@call :%driver% impcore-arrayutils
@call :%driver% impcore-mathutils
@call :%driver% impcore-signal
@call :%driver% impcore-strutils

@call :%driver% implib-arg
@call :%driver% implib-debug
@call :%driver% implib-env
@call :%driver% implib-heap
@call :%driver% implib-read
@call :%driver% implib-strings
@call :%driver% implib-trig

@call :%driver% imprtl-main
@call :%driver% imprtl-event
@call :%driver% imprtl-io
@call :%driver% imprtl-trap

@rem Ensure we have a clean library
@if exist libimp.lib del libimp.lib

@rem Store the C source primitives object code into the library
@lib /nologo /out:libimp.lib prim-rtl-file.obj
@rem do NOT add the runimp.obj file to the library as all symbol references start with this code
@rem do NOT add the runarg.obj file to the library as all symbol references start with this code

@rem Store the Imp source generated object code into the library
@lib /nologo /out:libimp.lib libimp.lib imprtl-main.obj
@lib /nologo /out:libimp.lib libimp.lib imprtl-event.obj
@lib /nologo /out:libimp.lib libimp.lib imprtl-io.obj
@lib /nologo /out:libimp.lib libimp.lib imprtl-trap.obj

@lib /nologo /out:libimp.lib libimp.lib impcore-arrayutils.obj
@lib /nologo /out:libimp.lib libimp.lib impcore-mathutils.obj
@lib /nologo /out:libimp.lib libimp.lib impcore-signal.obj
@lib /nologo /out:libimp.lib libimp.lib impcore-strutils.obj

@lib /nologo /out:libimp.lib libimp.lib implib-arg.obj
@lib /nologo /out:libimp.lib libimp.lib implib-debug.obj
@lib /nologo /out:libimp.lib libimp.lib implib-env.obj
@lib /nologo /out:libimp.lib libimp.lib implib-heap.obj
@lib /nologo /out:libimp.lib libimp.lib implib-read.obj
@lib /nologo /out:libimp.lib libimp.lib implib-strings.obj
@lib /nologo /out:libimp.lib libimp.lib implib-trig.obj

@rem Create the library which allows command line to specify the file I/O
@if exist libi77.lib del libi77.lib
@copy libimp.lib libi77.lib

@rem we no longer need the base object archive
@del libimp.lib
@goto the_end

:i32
@setlocal
@set source=%1
@%IMP_INSTALL_HOME%/bin/pass1        %source%.imp,stdperm.imp=%source%.icd:b,%source%.lst
@%IMP_INSTALL_HOME%/bin/pass2        %source%.icd:b,%source%.imp=%source%.ibj,%source%.cod

@%DEV_HOME%\pass3\pass3coff       %source%.ibj                %source%.obj
@%IMP_INSTALL_HOME%\bin\coff2dump %source%.obj                %source%.dump

@rem %DEV_HOME%\pass3\pass3elf        %source%.ibj                %source%.o

@%IMP_INSTALL_HOME%\bin\icd2assemble %source%.icd                %source%.icd.assemble
@%IMP_INSTALL_HOME%\bin\ibj2assemble %source%.ibj                %source%.ibj.assemble

@endlocal
@exit/b

:the_end
@endlocal
