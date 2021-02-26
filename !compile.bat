@echo off

rem Cleanup
if exist main.obj del main.obj
if exist seadragon.gb del seadragon.gb

rem Define ESCchar to use in ANSI escape sequences
rem https://stackoverflow.com/questions/2048509/how-to-echo-with-different-colors-in-the-windows-command-line
for /F "delims=#" %%E in ('"prompt #$E# & for %%E in (1) do rem"') do set "ESCchar=%%E"

set path=%path%;C:\bin\RGBDS

rgbasm -omain.obj main.asm
@if errorlevel 1 goto Failed

rgblink -dmg -o seadragon.gb main.obj
@if errorlevel 1 goto Failed

rgbfix -v -p 0 seadragon.gb
@if errorlevel 1 goto Failed

@echo %ESCchar%[92mSUCCESS%ESCchar%[0m
exit

:Failed
@echo off
echo %ESCchar%[91mFAILED%ESCchar%[0m
exit /b
