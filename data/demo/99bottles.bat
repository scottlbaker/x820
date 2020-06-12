@echo off

@echo Assemble 99bottles.asm
..\misc\bin\az80 -l 99bottles.lst -o 99bottles.hex 99bottles.asm

@echo Convert 99bottles.hex to 99bottles.bin
..\misc\bin\hex2bin 99bottles

@echo Convert from 99bottles.bin to 99bottles.hex
..\misc\bin\bin2mem 99bottles.bin > 99bottles.hex

@echo Run hackhex.pl
perl perl\hackhex.pl 99bottles.hex 1000

@echo Copy 99bottles.hex to Downloads
copy 99bottles.hex c:\Users\scd\Downloads\x820_hex\99bottles.hex

@echo DONE !!

pause

