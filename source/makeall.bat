@setlocal
@echo off
@set COM_HOME=%~dp0
@set IMP_DEV_SOURCE=%COM_HOME:~0,-1%

@rem ass-u-me that a Microsoft C compiler is being used
@set compiler=msvc
@rem force the user to provide a target directory
@set target=
@rem default to installing the tools/utilities
@set tools=hammer
@rem default to installing the tests
@set tests=validate

:parseargs
@if "%1"=="-gcc"    @goto usegcc
@if "%1"=="-msvc"   @goto usemsvc
@if "%1"=="-target" @goto usetarget
@if "%1"=="-tools"  @goto notools
@if "%1"=="-tests"  @goto notests
@rem if here parameter assumed to be the build folder
@goto runit

:usegcc
@rem Use this parameter to indicate we are using a non-Microsoft C compiler
@set compiler=gcc
@shift
@goto parseargs

:usemsvc
@rem Use this parameter to indicate we are using the Microsoft C compiler, linker and libraries
@set compiler=msvc
@shift
@goto parseargs

:usetarget
@rem we expect a "value" after the -target "parameter"
@shift
@rem so get the value. (should be a directory nme)
@rem however, don't check! Invalid value has it's own penalty!
@set target=%1
@rem consume the "directory" name
@shift
@rem parse the next option
@goto parseargs

:notools
@shift
@rem say we don't want to build the associated various tools
@rem Actually any non-empty value for tools will do, but ho hum!
@set tools=
@goto parseargs

:notests
@shift
@rem say we want to build the associated various tools
@rem Actually any non-empty value for tools will do, but ho hum!
@set tests=
@goto parseargs

:runit
@if "%target%"=="" @set target=%1
@if "%target%"=="" @goto nofolder

@rem Now set up the compiler build environment folder tree
@rem The location of IMP_DEV_BUILD is passed as a parameter to this build script
@rem This is to ensure you don't mess up the source folder
@set IMP_TARGET=%target%

@rem We should check that clearing the target build tree
@rem doesn't partially destroy the source folder
@rem But ho hum!

@rem Now to ensure we have a clean build area
@if     exist %IMP_TARGET%                      @rmdir/S/Q %IMP_TARGET%
@rem now create the build folder tree
@if not exist %IMP_TARGET%                      @mkdir %IMP_TARGET%
@goto build_compiler

:build_compiler
@rem This script makes a major ASS-U-ME that an existing variant of the imp compiler exists!
@rem currently we are upto version IMP2021x

@rem create the "release" folder tree
@set IMP_DEV_RELEASE=%IMP_TARGET%\release
@if not exist %IMP_DEV_RELEASE%                 @mkdir %IMP_DEV_RELEASE%
@if not exist %IMP_DEV_RELEASE%\bin             @mkdir %IMP_DEV_RELEASE%\bin
@if not exist %IMP_DEV_RELEASE%\docs            @mkdir %IMP_DEV_RELEASE%\docs
@if not exist %IMP_DEV_RELEASE%\include         @mkdir %IMP_DEV_RELEASE%\include
@if not exist %IMP_DEV_RELEASE%\lib             @mkdir %IMP_DEV_RELEASE%\lib

@rem create the temporary build folder tree
@set IMP_DEV_TEMP=%IMP_TARGET%\source
@if not exist %IMP_DEV_TEMP%                    @mkdir %IMP_DEV_TEMP%
@if not exist %IMP_DEV_TEMP%\imp                @mkdir %IMP_DEV_TEMP%\imp
@if not exist %IMP_DEV_TEMP%\imp\compiler       @mkdir %IMP_DEV_TEMP%\imp\compiler
@if not exist %IMP_DEV_TEMP%\imp\lib            @mkdir %IMP_DEV_TEMP%\imp\lib
@if not exist %IMP_DEV_TEMP%\imp\pass3          @mkdir %IMP_DEV_TEMP%\imp\pass3
@if not exist %IMP_DEV_TEMP%\imp\scripts        @mkdir %IMP_DEV_TEMP%\imp\scripts

@rem Now build the compiler etc in a temporary location
@copy %IMP_DEV_SOURCE%\imp\*.bat                %IMP_DEV_TEMP%\imp\*                     > nul
@copy %IMP_DEV_SOURCE%\imp\compiler\*.grammar   %IMP_DEV_TEMP%\imp\compiler\*.grammar    > nul
@copy %IMP_DEV_SOURCE%\imp\compiler\*.bat       %IMP_DEV_TEMP%\imp\compiler\*.bat        > nul
@copy %IMP_DEV_SOURCE%\imp\compiler\*.imp       %IMP_DEV_TEMP%\imp\compiler\*.imp        > nul
xcopy/S/E %IMP_DEV_SOURCE%\imp\lib              %IMP_DEV_TEMP%\imp\lib                   > nul
xcopy/S/E %IMP_DEV_SOURCE%\imp\pass3            %IMP_DEV_TEMP%\imp\pass3                 > nul
xcopy/S/E %IMP_DEV_SOURCE%\imp\scripts          %IMP_DEV_TEMP%\imp\scripts               > nul

echo.
echo                    ***********************************
echo                    * Compiler suite being installed. *
echo                    ***********************************
echo.

@cd %IMP_DEV_TEMP%
@rem Build the libraries, lexer/parser generator and the three passes of the compiler 
@call %IMP_DEV_TEMP%\imp\makeimp %usecompiler%

@rem now to "issue"/release the newly built library, compiler, scripts and documents
@rem Issue the new library
copy %IMP_DEV_TEMP%\imp\lib\libi77.lib         %IMP_DEV_RELEASE%\lib\libi77.lib         > nul
rem Issue the new include
copy %IMP_DEV_TEMP%\imp\lib\stdperm.imp        %IMP_DEV_RELEASE%\include\stdperm.imp    > nul
@rem Issue the run script, takeon, pass1, pass2 sections of the compiler
copy %IMP_DEV_TEMP%\imp\scripts\*              %IMP_DEV_RELEASE%\bin\*                  > nul
copy %IMP_DEV_TEMP%\imp\compiler\*.exe         %IMP_DEV_RELEASE%\bin\*.exe              > nul
@rem the versions of pass3
copy %IMP_DEV_TEMP%\imp\pass3\*.exe            %IMP_DEV_RELEASE%\bin\*.exe              > nul
@rem issue the documents
copy %IMP_DEV_SOURCE%\docs\imp77.pdf           %IMP_DEV_RELEASE%\docs\imp77.pdf         > nul
copy %IMP_DEV_SOURCE%\docs\ascii.txt           %IMP_DEV_RELEASE%\docs\ascii.txt         > nul
copy %IMP_DEV_SOURCE%\docs\icode1v3.txt        %IMP_DEV_RELEASE%\docs\icode1v3.txt      > nul
copy %IMP_DEV_SOURCE%\docs\psr_thesis.txt      %IMP_DEV_RELEASE%\docs\psr_thesis.txt    > nul

echo.
echo                    *********************************
echo                    * Compiler suite now installed. *
echo                    *********************************
echo.

:end_build_compiler
@goto build_tests

:build_tests
@rem Did we make a request for the various compiler tests?
@if "%tests%"=="" @goto no_build_tests

echo.
echo                    ***********************************
echo                    * Compiler tests being installed. *
echo                    ***********************************
echo.

@rem Now set up the compiler/utility test files
if not exist %IMP_DEV_TEMP%\tests              @mkdir %IMP_DEV_TEMP%\tests              > nul
if not exist %IMP_DEV_TEMP%\tests\examples     @mkdir %IMP_DEV_TEMP%\tests\examples     > nul
xcopy/S/E %IMP_DEV_SOURCE%\tests\examples      %IMP_DEV_TEMP%\tests\examples            > nul
copy %IMP_DEV_SOURCE%\tests\*                  %IMP_DEV_TEMP%\tests\*                   > nul

echo.
echo                    *********************************
echo                    * Compiler tests now installed. *
echo                    *********************************
echo.

:end_build_tests
@goto build_tools

:no_build_tests
@echo.
@echo                   *****************************************
@echo                   * Compiler tests will NOT be installed. *
@echo                   *****************************************
@echo.
@goto build_tools


:build_tools
@rem Did we make a request for the various tools?
@if "%tools%"=="" @goto no_build_tools

echo.
echo                    ***********************************
echo                    * Compiler tools being installed. *
echo                    ***********************************
echo.

@rem Now for the various tool utilities
@if not exist %IMP_DEV_TEMP%\tools              @mkdir %IMP_DEV_TEMP%\tools
xcopy/S/E %IMP_DEV_SOURCE%\tools               %IMP_DEV_TEMP%\tools                     > nul

@cd %IMP_DEV_TEMP%\tools
@rem Build the tools
@call %IMP_DEV_TEMP%\tools\maketools

@rem Issue the tools
copy %IMP_DEV_TEMP%\tools\ibj\*.exe            %IMP_DEV_RELEASE%\bin\*                  > nul
copy %IMP_DEV_TEMP%\tools\icd\*.exe            %IMP_DEV_RELEASE%\bin\*                  > nul

echo.
echo                    *********************************
echo                    * Compiler tools now installed. *
echo                    *********************************
echo.

:end_build_tools
@rem All the requested compiler options have been set up
@goto end_of_build

:no_build_tools
@echo.
@echo                   *****************************************
@echo                   * Compiler tools will NOT be installed. *
@echo                   *****************************************
@echo.
@rem All the requested compiler options have been set up
@goto end_of_build

:end_of_build

@cd %IMP_DEV_SOURCE%

@goto exit

:nofolder
echo                    **************************************************
echo                    **** ERROR **** No build target directory given! *
echo                    **************************************************

:exit
@endlocal
