@echo off

@echo Assemble test1.asm
..\misc\bin\az80 -l test1.lst -o test1.hex test1.asm

@echo Convert test1.hex to test1.bin
..\misc\bin\hex2bin test1

@echo Convert from test1.bin to test1.hex
..\misc\bin\bin2mem test1.bin > test1.hex

@echo Run hackhex.pl
perl perl\hackhex.pl test1.hex 4096

@echo Copy test1.hex to Downloads
copy test1.hex c:\Users\scd\Downloads\x820_hex\test1.hex

@echo DONE !!

pause

