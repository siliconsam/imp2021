@setlocal
@echo off
@set COM_HOME=%~dp0
@set COM_HOME=%COM_HOME:~0,-1%

@rem This script has an ASS-U-ME that the Free Pascal compiler is installed.
@rem If not then refer to http://www.freepascal.org for relevant downloads

@rem Now build the various tools
@rem First the various ibj tools written in IMP or Free Pascal
@cd %COM_HOME%\ibj
@rem Tool to read IBJ data in text form and generate an IBJ file
@fpc -gl assemble2ibj.pas
@rem Tool to read a COFF object file and generate debug info
@fpc -gl coff2dump.pas
@rem Tool to read an IBJ file and generate a textual equivalent
@fpc -gl ibj2assemble.pas
@rem Tool to read an IBJ file and generate a COFF file
@rem this is a Pascal version of the C program pass3
@fpc -gl ibj2coff.pas
@rem Tool to read an IBJ file, compact it by eliminating unused external symbols
@fpc -gl ibj2compact.pas
@rem Equivalent tool to ibj2compact.pas but written in IMP
@call imp32 slimibj

@rem Next the various tools to manipulate icd files
@cd %COM_HOME%\icd

@rem Tools which read/write ICD files
@fpc -gl assemble2icd.pas
@fpc -gl icd2assemble.pas
@fpc -gl icd2dump.pas
@fpc -gl trimdump.pas

@cd %COM_HOME%
@endlocal
