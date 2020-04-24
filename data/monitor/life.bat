@echo off

@echo Assemble life.asm
az80 -l life.lst -o life.hex life.asm

@echo Convert life.hex to life.bin
hex2bin life

@echo Convert from life.bin to life.hex
bin2mem life.bin > life.hex

@echo Run hackhex.pl
perl perl\hackhex.pl life.hex 5000

@echo Copy life.hex to Downloads
copy life.hex hex\life.hex

@echo DONE !!

pause

