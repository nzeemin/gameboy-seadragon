@echo off
echo ; Sea Dragon for GameBoy > landscape.hdr
echo ; Landscape data >> landscape.hdr
echo ; >> landscape.hdr
echo LandscapeData: >> landscape.hdr
LandMapConv.exe ..\Tiled\SeaDragon0.tmx landscape0.inc
LandMapConv.exe ..\Tiled\SeaDragon1.tmx landscape1.inc
LandMapConv.exe ..\Tiled\SeaDragon2.tmx landscape2.inc
copy landscape.hdr+landscape0.inc+landscape1.inc+landscape2.inc landscape.inc
echo LandscapeDataEnd: >> landscape.inc
