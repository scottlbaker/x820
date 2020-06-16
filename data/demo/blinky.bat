@echo off

@echo Assemble blinky.asm
..\misc\bin\az80 -l blinky.lst -o blinky.hex blinky.asm

@echo Convert blinky.hex to blinky.bin
..\misc\bin\hex2bin blinky

@echo Convert from blinky.bin to blinky.hex
..\misc\bin\bin2mem blinky.bin > blinky.hex

@echo Run hackhex.pl
perl perl\hackhex.pl blinky.hex 500

@echo Copy blinky.hex to Downloads
copy blinky.hex c:\Users\scd\Downloads\x820_hex\blinky.hex

@echo DONE !!

pause

