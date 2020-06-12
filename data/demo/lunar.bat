@echo off

@echo Assemble lunar.asm
..\misc\bin\az80 -l lunar.lst -o lunar.hex lunar.asm

@echo Convert lunar.hex to lunar.bin
..\misc\bin\hex2bin lunar

@echo Convert from lunar.bin to lunar.hex
..\misc\bin\bin2mem lunar.bin > lunar.hex

@echo Run hackhex.pl
perl perl\hackhex.pl lunar.hex 5000

@echo Copy lunar.hex to Downloads
copy lunar.hex c:\Users\scd\Downloads\x820_hex\lunar.hex

@echo DONE !!

pause

