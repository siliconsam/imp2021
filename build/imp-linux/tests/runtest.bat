@setlocal
@echo off

@call imp32 -Fc -Fs -Fi baggins
@call imp32 -Fc -Fs -Fi bilbo
@call imp32 -Fc -Fs -Fi testarray
@call imp32 -Fc -Fs -Fi testcopy
@call imp32 -Fc -Fs -Fi testbadheap
@call imp32 -Fc -Fs -Fi testheap
@call imp32 -Fc -Fs -Fi testreadstring
@call imp32 -Fc -Fs -Fi testrecordformat
@call imp32 -Fc -Fs -Fi testsignal
@call imp32 -Fc -Fs -Fi testsignalx
@call imp32 -Fc -Fs -Fi teststring
@call imp32 -Fc -Fs -Fi testwrite

@call imp32 -c mcode000test
@call imp32 -c mcode000
@call imp32link mcode000test mcode000

:exit
@endlocal
