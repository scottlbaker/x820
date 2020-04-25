@echo off

@echo Assemble basic.asm
az80 -l basic.lst -o basic.hex basic.asm

@echo Convert basic.hex to basic.bin
hex2bin basic

@echo Convert from basic.bin to basic.hex
bin2mem basic.bin > basic.hex

@echo Run hackhex.pl
perl perl\hackhex.pl basic.hex 2500

@echo Copy basic.hex to Downloads
copy basic.hex c:\Users\scd\Downloads\x820_hex\basic.hex

@echo DONE !!

pause

