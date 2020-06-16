@echo off

@echo Assemble piCalc.asm
..\misc\bin\az80 -l piCalc.lst -o piCalc.hex piCalc.asm

@echo Convert piCalc.hex to piCalc.bin
..\misc\bin\hex2bin piCalc

@echo Convert from piCalc.bin to piCalc.hex
..\misc\bin\bin2mem piCalc.bin > piCalc.hex

@echo Run hackhex.pl
perl perl\hackhex.pl piCalc.hex 2500

@echo Copy piCalc.hex to Downloads
copy piCalc.hex c:\Users\scd\Downloads\x820_hex\piCalc.hex

@echo DONE !!

pause

