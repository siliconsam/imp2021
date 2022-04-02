@setlocal
@echo off

@if exist *.assemble del *.assemble
@if exist *.cod      del *.cod
@if exist *.dump     del *.dump
@if exist *.exe      del *.exe
@if exist *.ibj      del *.ibj
@if exist *.icd      del *.icd
@if exist *.lst      del *.lst
@if exist *.obj      del *.obj

@call imp32 -c -Fc -Fs -Fi baggins
@call imp32 -c -Fc -Fs -Fi testpcsimple
@call imp32 -c -Fc -Fs -Fi testpcrecord
@call imp32 -c -Fc -Fs -Fi testpcstring
@call imp32 -c -Fc -Fs -Fi teststreams
@call imp32 -c -Fc -Fs -Fi dynamicarraylong

@call imp32link testpcsimple baggins
@call imp32link testpcrecord baggins
@call imp32link testpcstring baggins
@call imp32link teststreams
@call imp32link dynamicarraylong

@testpcsimple
@testpcrecord
@testpcstring
@dynamicarraylong

:exit
@endlocal
