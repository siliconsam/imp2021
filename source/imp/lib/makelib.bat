@setlocal
@set COM_HOME=%~dp0
@rem now remove the \lib\ (last 10 characters) from the script directory variable
@set DEV_HOME=%COM_HOME:~0,-5%

@set driver=i32

@set option=-DMSVC

:parseargs
@if "%1"=="gcc" @goto clearoption
@if "%1"=="" @goto setoption
@rem if here parameter assumed to be the build folder
@goto runit

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

:runit
@rem Compile the C implemented primitives code
@rem The possible parameter 
@cl /nologo /Gd /c /Gs /W3 /Od /arch:IA32 -D_CRT_SECURE_NO_WARNINGS %option% /FAscu /Foprim-rtl-file.obj /Faprim-rtl-file.lst prim-rtl-file.c

@rem Compile the IMP77 implemented library code
@call :%driver% imprtl-main
@call :%driver% imprtl-event
@call :%driver% imprtl-io
@call :%driver% imprtl-trap
@call :%driver% impcore-adef
@call :%driver% impcore-aref
@call :%driver% impcore-fexp
@call :%driver% impcore-iexp
@call :%driver% impcore-signal
@call :%driver% impcore-strcat
@call :%driver% impcore-strcmp
@call :%driver% impcore-strcpy
@call :%driver% impcore-strjam
@call :%driver% impcore-strjcat
@call :%driver% impcore-strres
@call :%driver% implib-arg
@call :%driver% implib-cosine
@call :%driver% implib-debug
@call :%driver% implib-dispose
@call :%driver% implib-env
@call :%driver% implib-formatnumber
@call :%driver% implib-int2ascii
@call :%driver% implib-intpt
@call :%driver% implib-itos
@call :%driver% implib-new
@call :%driver% implib-newline
@call :%driver% implib-newlines
@call :%driver% implib-read
@call :%driver% implib-write
@call :%driver% implib-print
@call :%driver% implib-printstring
@call :%driver% implib-sine
@call :%driver% implib-skipsymbol
@call :%driver% implib-space
@call :%driver% implib-spaces
@call :%driver% implib-substring
@call :%driver% implib-tolower
@call :%driver% implib-toupper
@call :%driver% implib-trim

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
@lib /nologo /out:libimp.lib libimp.lib impcore-adef.obj
@lib /nologo /out:libimp.lib libimp.lib impcore-aref.obj
@lib /nologo /out:libimp.lib libimp.lib impcore-fexp.obj
@lib /nologo /out:libimp.lib libimp.lib impcore-iexp.obj
@lib /nologo /out:libimp.lib libimp.lib impcore-signal.obj
@lib /nologo /out:libimp.lib libimp.lib impcore-strcat.obj
@lib /nologo /out:libimp.lib libimp.lib impcore-strcmp.obj
@lib /nologo /out:libimp.lib libimp.lib impcore-strcpy.obj
@lib /nologo /out:libimp.lib libimp.lib impcore-strjam.obj
@lib /nologo /out:libimp.lib libimp.lib impcore-strjcat.obj
@lib /nologo /out:libimp.lib libimp.lib impcore-strres.obj
@lib /nologo /out:libimp.lib libimp.lib implib-arg.obj
@lib /nologo /out:libimp.lib libimp.lib implib-cosine.obj
@lib /nologo /out:libimp.lib libimp.lib implib-debug.obj
@lib /nologo /out:libimp.lib libimp.lib implib-dispose.obj
@lib /nologo /out:libimp.lib libimp.lib implib-env.obj
@lib /nologo /out:libimp.lib libimp.lib implib-formatnumber.obj
@lib /nologo /out:libimp.lib libimp.lib implib-int2ascii.obj
@lib /nologo /out:libimp.lib libimp.lib implib-intpt.obj
@lib /nologo /out:libimp.lib libimp.lib implib-itos.obj
@lib /nologo /out:libimp.lib libimp.lib implib-new.obj
@lib /nologo /out:libimp.lib libimp.lib implib-newline.obj
@lib /nologo /out:libimp.lib libimp.lib implib-newlines.obj
@lib /nologo /out:libimp.lib libimp.lib implib-read.obj
@lib /nologo /out:libimp.lib libimp.lib implib-write.obj
@lib /nologo /out:libimp.lib libimp.lib implib-print.obj
@lib /nologo /out:libimp.lib libimp.lib implib-printstring.obj
@lib /nologo /out:libimp.lib libimp.lib implib-sine.obj
@lib /nologo /out:libimp.lib libimp.lib implib-skipsymbol.obj
@lib /nologo /out:libimp.lib libimp.lib implib-space.obj
@lib /nologo /out:libimp.lib libimp.lib implib-spaces.obj
@lib /nologo /out:libimp.lib libimp.lib implib-substring.obj
@lib /nologo /out:libimp.lib libimp.lib implib-tolower.obj
@lib /nologo /out:libimp.lib libimp.lib implib-toupper.obj
@lib /nologo /out:libimp.lib libimp.lib implib-trim.obj

@rem Create the library which allows command line to specify the file I/O
@if exist libi77.lib del libi77.lib
@copy libimp.lib libi77.lib

@rem we no longer need the base object archive
@del libimp.lib
@goto the_end

:i32
@setlocal
@set source=%1
@%IMP_INSTALL_HOME%\bin\pass1     %source%.imp,..\lib\stdperm.imp=%source%.icd:b,%source%.lst
@%IMP_INSTALL_HOME%\bin\pass2     %source%.icd:b,%source%.imp=%source%.ibj,%source%.cod
@%DEV_HOME%\pass3\pass3coff       %source%.ibj                %source%.obj
@%IMP_INSTALL_HOME%\bin\coff2dump %source%.obj                %source%.dump
@endlocal
@exit/b

:the_end
@endlocal
