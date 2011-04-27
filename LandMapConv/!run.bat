@echo off
echo ; Sea Dragon for GameBoy > landscape.hdr
echo ; Landscape data >> landscape.hdr
echo ; >> landscape.hdr
echo LandscapeData: >> landscape.hdr
LandMapConv.exe ..\Tiled\SeaDragon0.tmx landscape0.inc
LandMapConv.exe ..\Tiled\SeaDragon1.tmx landscape1.inc
LandMapConv.exe ..\Tiled\SeaDragon2.tmx landscape2.inc
LandMapConv.exe ..\Tiled\SeaDragon3.tmx landscape3.inc
LandMapConv.exe ..\Tiled\SeaDragon4.tmx landscape4.inc
LandMapConv.exe ..\Tiled\SeaDragon5.tmx landscape5.inc
LandMapConv.exe ..\Tiled\SeaDragon6.tmx landscape6.inc
copy landscape.hdr+landscape0.inc+landscape1.inc+landscape2.inc+landscape3.inc+landscape4.inc+landscape5.inc+landscape6.inc landscape.inc
echo LandscapeDataEnd: >> landscape.inc
