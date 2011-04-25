@echo off

set path=%path%;C:\bin\RGBDS

rgbasm -omain.obj main.asm
IF ERRORLEVEL 1 GOTO END

xlink -mmap seadragon.lnk
IF ERRORLEVEL 1 GOTO END

rgbfix -v seadragon
IF ERRORLEVEL 1 GOTO END

echo SUCCESSED

:END