@echo off

@echo Assemble blinky.asm
az80 -l blinky.lst -o blinky.hex blinky.asm

@echo Convert blinky.hex to blinky.bin
hex2bin blinky

@echo Convert from blinky.bin to blinky.hex
bin2mem blinky.bin > blinky.hex

@echo Run hackhex.pl
perl perl\hackhex.pl blinky.hex 500

@echo Copy blinky.hex to Downloads
copy blinky.hex hex\blinky.hex

@echo DONE !!

pause

