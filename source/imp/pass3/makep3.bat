@setlocal
@echo off

@rem *************************************************************************************
@rem *                                                                                   *
@rem * Build script ass-u-mes that Visual Studio (currently VS2005) shell variables for  *
@rem * for Visual C++ been set up ( by calling %VSINSTALLDIR%\VC\bin\vcvars32.bat)       *
@rem * This gives access to cl.exe, link.exe and lib.exe                                 *
@rem *                                                                                   *
@rem * This script compiles then links to generate the 3rd pass of the IMP compiler.     *
@rem * It does not currently install this 3rd pass executable. TEST, TEST, TEST before   *
@rem * deploying into the released directory (usually c:\imp2014)                        *
@rem *                                                                                   *
@rem *************************************************************************************

@if exist *.exe @del *.exe
@if exist *.obj @del *.obj

@rem we ass-u-me that a Microsoft C compiler is being used
@set option=-DMSVC

:parseargs
@if "%1"=="gcc" @goto clearoption
@rem if "%1"=="" @goto setoption
@rem if here parameter assumed to be the build folder
@goto runit

:clearoption
@rem Use this parameter for a non-Microsoft C compiler environment
@set option=
@shift
@goto parseargs

:setoption
@rem Use this parameter to indicate we are using the Microsoft C compiler, linker and libraries
@set option=-DMSVC
@shift
@goto parseargs

:runit
@cl /nologo /Gd /c /Gs /W3 /Ox -D_CRT_SECURE_NO_WARNINGS %option% /Fopass3coff.obj pass3coff.c
@if not exist pass3coff.obj @goto errorexit
@cl /nologo /Gd /c /Gs /W3 /Ox -D_CRT_SECURE_NO_WARNINGS %option% /Fopass3elf.obj pass3elf.c
@if not exist pass3elf.obj @goto errorexit

:doifreader
@cl /nologo /Gd /c /Gs /W3 /Ox ifreader.c
@if not exist ifreader.obj @goto errorexit

:dowritebig
@cl /nologo /Gd /c /Gs /W3 /Ox writebig.c
@if not exist writebig.obj @goto errorexit

:dolink
@link /nologo /stack:80000,80000 /MAPINFO:EXPORTS /OUT:pass3coff.exe /MAP:pass3coff.map pass3coff.obj ifreader.obj writebig.obj
@if not exist pass3coff.exe @goto errorexit

@link /nologo /stack:80000,80000 /MAPINFO:EXPORTS /OUT:pass3elf.exe  /MAP:pass3elf.map  pass3elf.obj  ifreader.obj writebig.obj
@if not exist pass3elf.exe @goto errorexit
@goto end

:errorexit
@echo "There was a problem building pass3.EXE - please read the error messages and correct the problem"

:end
@endlocal
