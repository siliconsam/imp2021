@setlocal
@echo off

@set source=%1
@set parseFile=par.%1.lis
@set lexFile=lex.%1.lis

@copy/y %source%.tables.inc tables.inc

@if exist lex.%1.lis     @del lex.%1.lis
@if exist par.%1.lis     @del par.%1.lis

@if exist readtables.cod @del readtables.cod
@if exist readtables.exe @del readtables.exe
@if exist readtables.ibj @del readtables.ibj
@if exist readtables.icd @del readtables.icd
@if exist readtables.lst @del readtables.lst
@if exist readtables.obj @del readtables.obj
@if exist readtables.map @del readtables.map

@rem call the imp build script (since imp32 finishes with exit)
@call imp32 readtables

@readtables =%parsefile%,%lexfile%

@if exist readtables.cod @del readtables.cod
@if exist readtables.exe @del readtables.exe
@if exist readtables.ibj @del readtables.ibj
@if exist readtables.icd @del readtables.icd
@if exist readtables.lst @del readtables.lst
@if exist readtables.obj @del readtables.obj
@if exist readtables.map @del readtables.map

@if exist @del tables.inc

@endlocal
