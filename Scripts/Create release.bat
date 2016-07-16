@echo off

if exist ..\Release rd ..\Release /s /q

mkdir ..\Release

copy ..\readme.txt ..\Release\readme.txt

copy ..\MainProgram\Delphi\Release\win_x86\AppKiller.exe "..\Release\AppKiller[D32].exe"

copy ..\MainProgram\Lazarus\Release\win_x86\AppKiller.exe "..\Release\AppKiller[L32].exe"

copy ..\MainProgram\Lazarus\Release\win_x64\AppKiller.exe "..\Release\AppKiller[L64].exe"