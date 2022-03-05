@set COM_HOME=%~dp0
@set IMP_INSTALL_HOME=%COM_HOME:~0,-5%

@rem Now to add in the Pascal compiler (Free Pascal for preference)
@set FPC_HOME=c:\utils\FPC
@set FPC_VERSION=3.2.2
@set FPC_BIN_HOME=%FPC_HOME%\%FPC_VERSION%\bin\i386-win32

@set path=%IMP_INSTALL_HOME%\bin;^
%FPC_BIN_HOME%;%path%

@set libpath=%IMP_INSTALL_HOME%\lib;^
%libpath%

@set dircmd=/ognes

@title="IMP77 Development Window %IMP_INSTALL_HOME%"
