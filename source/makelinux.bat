@setlocal
@echo off
@set COM_HOME=%~dp0
@set COM_HOME=%COM_HOME:~0,-1%
@set SOURCE_HOME=%COM_HOME%
@set LINUX_SOURCE_HOME=%COM_HOME%\imp-linux

@rem provide a default target build directory (just in case!)
@set target=

@rem Check that we have "some" parameters
@if "%1"=="" @goto oops

:parseargs
@if "%1"=="-target" @goto usetarget
@if "%1"=="-?"      @goto oops
@if "%1"=="/?"      @goto oops
@rem if here parameter assumed to be the build folder
@goto runit

:oops
@call :showhelp
@goto the_end

:usetarget
@shift
@set target=%1
@shift
@goto parseargs

:runit
@rem default to current parameter
@if "%target%"=="" @set target=%1
@rem do we realy have a target?
@if "%target%"=="" @goto nofolder
@rem ok, we should specified have a target directory
@rem the target should be a directory name, but let the script find out!

@rem set up the various logicals for the build process
@set IMP_SOURCE_HOME=%SOURCE_HOME%\imp
@set TOOLS_SOURCE_HOME=%SOURCE_HOME%\tools
@set TESTS_SOURCE_HOME=%SOURCE_HOME%\tests
@set TARGET_HOME=%target%

@rem We will use the Linux/Elf stdperm.imp
@set PERM_HOME=%TARGET_HOME%\lib

@rem Use the Windows version of the IMP compiler (pass1, pass2)
@set P1_HOME=%IMP_INSTALL_HOME%\bin
@set P2_HOME=%IMP_INSTALL_HOME%\bin
@rem BUT, use the Windows version of the pass3 Elf object file generator
@set P3_HOME=%IMP_INSTALL_HOME%\bin
@rem Use the Windows version of the IMP parse/lex tables generator (takeon)
@set TAKEON_HOME=%IMP_INSTALL_HOME%\bin

@rem now to create the Linux file folder tree
@if      exist %TARGET_HOME%                    @rmdir/S/Q %TARGET_HOME%
@if not  exist %TARGET_HOME%                    @mkdir %TARGET_HOME%

@rem Now, copy the source files into a build area
copy    %LINUX_SOURCE_HOME%\README              %TARGET_HOME%\*                     > nul
@rem copy the source files for the compiler
@if not  exist %TARGET_HOME%\compiler           @mkdir %TARGET_HOME%\compiler
xcopy   %IMP_SOURCE_HOME%\compiler\i77.grammar  %TARGET_HOME%\compiler\*            > nul
xcopy   %IMP_SOURCE_HOME%\compiler\*.imp        %TARGET_HOME%\compiler\*            > nul
xcopy   %IMP_SOURCE_HOME%\pass3\*.c             %TARGET_HOME%\compiler\*            > nul
xcopy   %IMP_SOURCE_HOME%\pass3\*.h             %TARGET_HOME%\compiler\*            > nul
@rem overwrite the target with the linux specific versions for the compiler
xcopy/y %LINUX_SOURCE_HOME%\linux\compiler\*    %TARGET_HOME%\compiler\*            > nul

@rem copy the source files for the lib
@if not  exist %TARGET_HOME%\lib                @mkdir %TARGET_HOME%\lib
xcopy   %IMP_SOURCE_HOME%\lib\*.imp             %TARGET_HOME%\lib\*                 > nul
xcopy   %IMP_SOURCE_HOME%\lib\inc.386.registers %TARGET_HOME%\lib\*                 > nul
xcopy   %IMP_SOURCE_HOME%\lib\*.c               %TARGET_HOME%\lib\*                 > nul
@rem overwrite with the linux specific versions for the library
xcopy/y %LINUX_SOURCE_HOME%\linux\lib\*         %TARGET_HOME%\lib\*                 > nul

@rem don't forget some of the documwentation
@if not  exist %TARGET_HOME%\docs               @mkdir %TARGET_HOME%\docs
copy %SOURCE_HOME%\docs\imp77.pdf               %TARGET_HOME%\docs\imp77.pdf        > nul
copy %SOURCE_HOME%\docs\ascii.txt               %TARGET_HOME%\docs\ascii.txt        > nul
copy %SOURCE_HOME%\docs\icode1v3.txt            %TARGET_HOME%\docs\icode1v3.txt     > nul
copy %SOURCE_HOME%\docs\psr_thesis.txt          %TARGET_HOME%\docs\psr_thesis.txt   > nul

@rem prepare the tools environment
@if not  exist %TARGET_HOME%\tools              @mkdir %TARGET_HOME%\tools
@rem copy the tools folder tree
xcopy/se %TOOLS_SOURCE_HOME%\*                  %TARGET_HOME%\tools\*               > nul

@rem prepare the tests environment
@if not  exist %TARGET_HOME%\tests              @mkdir %TARGET_HOME%\tests
@rem prepare the base set of tests
xcopy   %TESTS_SOURCE_HOME%\*                   %TARGET_HOME%\tests\*               > nul
xcopy   %IMP_SOURCE_HOME%\lib\inc.386.registers %TARGET_HOME%\tests\*               > nul

@rem Now start the process of building the cross compiler environment
@cd %TARGET_HOME%\compiler

@rem use the Windows version of the takeon parse/lex table compiler
@%TAKEON_HOME%\takeon i77.grammar=i77.tables.imp,i77.par.debug,i77.lex.debug

@rem Now build the Elf object files for the compiler passes 
@call :i77 pass1
@call :i77 pass2
@rem Also build the Elf object files for the grammar generator 
@call :i77 takeon

@cd %TARGET_HOME%\lib
@rem Now build the Elf object files for the run-time modules (IMP implementation)
@call :i77 impcore-adef
@call :i77 impcore-aref
@call :i77 impcore-fexp
@call :i77 impcore-iexp
@call :i77 impcore-signal
@call :i77 impcore-strcat
@call :i77 impcore-strcmp
@call :i77 impcore-strcpy
@call :i77 impcore-strjam
@call :i77 impcore-strjcat
@call :i77 impcore-strres
@call :i77 implib-arg
@call :i77 implib-cosine
@call :i77 implib-debug
@call :i77 implib-dispose
@call :i77 implib-env
@call :i77 implib-formatnumber
@call :i77 implib-int2ascii
@call :i77 implib-intpt
@call :i77 implib-itos
@call :i77 implib-new
@call :i77 implib-newline
@call :i77 implib-newlines
@call :i77 implib-print
@call :i77 implib-printstring
@call :i77 implib-read
@call :i77 implib-sine
@call :i77 implib-skipsymbol
@call :i77 implib-space
@call :i77 implib-spaces
@call :i77 implib-substring
@call :i77 implib-tolower
@call :i77 implib-toupper
@call :i77 implib-trim
@call :i77 implib-write
@call :i77 imprtl-event
@call :i77 imprtl-io
@call :i77 imprtl-main
@call :i77 imprtl-trap

@cd %TARGET_HOME%
@rem remove the files only useful in the Windows environment
@del compiler\*.obj
@del compiler\*.exe
@del compiler\*.map
@del compiler\*.debug
@rem We keep the .o files and i77.tables.imp file needed by the Linux bootstrap step
@rem Also, the *.cod,*.ibj,*.icd,*.lst files are retained for debugging

@cd %SOURCE_HOME%

@call :build_instructions
@goto the_end

:i77
@rem set up our files
@set source=%1.imp
@set icdfile=%1.icd:b
@set codefile=%1.cod
@set listfile=%1.lst

@rem Use the Windows version of pass1,pass2 to create the .ibj files
@%P1_HOME%\pass1 %source%,%PERM_HOME%\stdperm.imp=%icdfile%,%listfile%
@%P2_HOME%\pass2 %icdfile%,%source%=%1.ibj,%codefile%
@rem Use the Windows executable ELF version of pass3.c to create the .o files
@%P3_HOME%\pass3elf %1.ibj %1.o
@exit/b

:nofolder
@echo "**** ERROR **** No Build target directory given for Linux bootstrap!"
@exit/b

:build_instructions
@echo.
@echo *************************************************************************
@echo *                                                                       *
@echo * All required IMP .o file should have been generated                   *
@echo * (the i77.tables.imp is needed as a bootstrap placeholder)             *
@echo *                                                                       *
@echo * To build on a Intel Linux machine                                     *
@echo * 1) Ensure you have a GCC C compiler suite to generate 32-bit code     *
@echo * 2) Ensure you have Free Pascal (www.freepascal.org) version 3.2       *
@echo * 3) Transfer the generated folder tress to the Intel Linux machine     *
@echo *    **** Ensure dos2unix is installed and available on the Linux box   *
@echo *    **** makefile uses dos2unix to give i77.grammar Linux line endings *
@echo *                                                                       *
@echo * 4) On the Intel Linux machine:                                        *
@echo *      Step 1: cd to the lib folder                                     *
@echo *      Step 2: "make bootstrap"                                         *
@echo *      Step 3: cd to the compiler folder                                *
@echo *      Step 4: "make bootstrap"                                         *
@echo *                                                                       *
@echo *  Once a working IMP compiler environment is active                    *
@echo *  then you can extend the library and pass1,pass2,pass3                *
@echo *  Always build the library before the compiler                         *
@echo *                                                                       *
@echo *  To rebuild the library                                               *
@echo *      Step 1: cd to the lib folder                                     *
@echo *      Step 2: "make"                                                   *
@echo *    Once satisfied with the amended libary                             *
@echo *      Step 3: "make install"                                           *
@echo *                                                                       *
@echo *  To rebuild the compiler                                              *
@echo *      Step 1: cd to the compiler folder                                *
@echo *      Step 2: "make"                                                   *
@echo *    Once satisfied with the amended compiler passes                    *
@echo *      Step 3: "make install"                                           *
@echo *                                                                       *
@echo *  If all is well with the rebuild of lib and compiler                  *
@echo *      Step 1: cd to the lib folder                                     *
@echo *      Step 2: "make superclean"                                        *
@echo *      Step 3: cd to the compiler folder                                *
@echo *      Step 4: "make superclean"                                        *
@echo *                                                                       *
@echo *      This will remove all intermediate build files                    *
@echo *                                                                       *
@echo * 5) The tools folder contains utilities to manipulate the various      *
@echo *    intermediate files generated by the compiler                       *
@echo *    Use the makefile in the tools folder to build these tools          *
@echo *    (Only build the tools AFTER the "bootstrap" phase)                 *
@echo *                                                                       *
@echo * NB Always take a backup of the source folders and the installed       *
@echo *    compiler, library and include folders. Just in case!!!             *
@echo *                                                                       *
@echo * The README in the main folder has some useful info                    *
@echo *                                                                       *
@echo * PS Don't forget the documents in the ../docs folder                   *
@echo *                                                                       *
@echo *************************************************************************
@echo.
@exit/b

:showhelp
@echo.
@echo *************************************************************************
@echo *                                                                       *
@echo *  To generate a bootstrap IMP compiler for Linux                       *
@echo *      1) Create a DOS shell                                            *
@echo *      2) cd to the <dos_install_home>\release\bin folder               *   
@echo *         where <dos_install_home> is the "Windows" folder containing   *
@echo *         the IMP compiler                                              *
@echo *      3) run setenv.bat                                                *
@echo *         to access the "Windows" IMP compiler binaries                 *
@echo *      4) cd to <install_home>\source folder                            *
@echo *         This contains the makelinux.bat Windows build script          *
@echo *      5) Decide on a "Windows" folder to use as a target directory     *
@echo *         This <target_home> Windows folder tree can be copied to a     *
@echo *         Linux system                                                  *
@echo *      6) run makelinux <target_home>                                   *
@echo *         Instructions on how to bootstrap the IMP compiler on Linux    *
@echo *         are given at the end of running "makelinux"                   *
@echo *      7) Copy the <target_home> folder across to a Linux machine       *
@echo *         (winscp is a useful utility for folder transfer)              *         
@echo *      8) Follow the instructions mentioned in step 6.                  *
@echo *                                                                       *
@echo *  At this point an IMP compiler for Linux should be available.         *
@echo *                                                                       *
@echo *  If there are problems with step 8                                    *
@echo *      1) Ensure ALL text files moved to the Linux machine have the     *
@echo *         UNIX line ending of <LF> and not the Windows <CR><LF>         *
@echo *         line ending                                                   *
@echo *         (Use the Unix/Linux command dos2unix fo the file conversion)  *
@echo *      2) The makefiles in the compiler,lib folders might need          *
@echo *         "tweaking" if the target Linux machine has a different        *
@echo *         "install" or "archive" command                                *
@echo *                                                                       *
@echo *  NB The tools folder contains the source code of various utilities    *
@echo *     to manipulate the intermediate files generated by the compiler.   *
@echo *     The makefiles in the tools sub-folder will build these tools      *
@echo *     These Pascal utilities need the Free Pascal compiler suite        *
@echo *     (see www.freepascal.org, version 3.2 and later)                   *
@echo *     (Only build the tools AFTER the "bootstrap" phase)                *
@echo *                                                                       *
@echo *  NB Always take a backup of the source folders and the                *
@echo *     installed compiler, library and include folders                   *
@echo *     Just in case!!!                                                   *
@echo *                                                                       *
@echo *  The README in the main folder has some useful info                   *
@echo *                                                                       *
@echo *  PS Don't forget the documents in the ../docs folder                  *
@echo *                                                                       *
@echo *************************************************************************
@echo.
@exit/b

:the_end
@endlocal
