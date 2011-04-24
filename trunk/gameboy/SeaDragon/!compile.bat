@echo off
set path=%path%;C:\bin\RGBDS
rgbasm -omain.obj main.asm
xlink -mmap seadragon.lnk
rgbfix -v seadragon
