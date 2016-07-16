@echo off

pushd .

cd ..\MainProgram\Resources
call "build_resources (brcc32).bat"

cd ..\Delphi
dcc32.exe -Q -B AppKiller.dpr

REM cd ..\Resources
REM call "build resources (windres).bat"

cd ..\Lazarus
lazbuild -B --bm=Release_win_x86 AppKiller.lpi
lazbuild -B --bm=Release_win_x64 AppKiller.lpi
lazbuild -B --bm=Debug_win_x86 AppKiller.lpi
lazbuild -B --bm=Debug_win_x64 AppKiller.lpi

popd