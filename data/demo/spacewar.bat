@echo off

@echo Assemble spacewar.asm
..\misc\bin\az80 -l spacewar.lst -o spacewar.hex spacewar.asm

@echo Convert spacewar.hex to spacewar.bin
..\misc\bin\hex2bin spacewar

@echo Convert from spacewar.bin to spacewar.hex
..\misc\bin\bin2mem spacewar.bin > spacewar.hex

@echo Copy spacewar.hex to ..\ram.hex
copy /y spacewar.hex ..\ram.hex

@echo Run hackhex.pl
perl ..\misc\perl\hackhex.pl spacewar.hex 4000

@echo Copy spacewar.hex to Downloads
copy spacewar.hex c:\Users\scd\Downloads\x820_hex\spacewar.hex

@echo DONE !!

pause

