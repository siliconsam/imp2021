@setlocal
@set COM_HOME=%~dp0
@set SOURCE_HOME=%COM_HOME:~0,-1%

@rem ass-u-me a Microsoft C compiler will be used
@rem so set the appropriate define directive
@set option=-DMSVC

@rem if a gcc C compiler then clear the appropriate directive
@if "%1"=="gcc"   @set option=

@rem if a Microsoft C compiler then set the appropriate directive
@if "%1"=="msvc"  @set option=-DMSVC

@rem Oh! we forgot to say which C compiler
@rem default to use a Microsoft C compiler and set appropriate directive
@if "%1"==""      @set option=-DMSVC

@cd %SOURCE_HOME%\pass3
@call %SOURCE_HOME%\pass3\makep3 %option%

@cd %SOURCE_HOME%\lib
@call %SOURCE_HOME%\lib\makelib %option%

@cd %SOURCE_HOME%\compiler
@call %SOURCE_HOME%\compiler\makep1_2

@cd %SOURCE_HOME%
@goto end

:end
@endlocal
