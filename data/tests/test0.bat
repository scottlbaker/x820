@echo off

@echo Assemble test0.asm
..\misc\bin\az80 -l test0.lst -o test0.hex test0.asm

@echo Convert test0.hex to test0.bin
..\misc\bin\hex2bin test0

@echo Convert from test0.bin to test0.hex
..\misc\bin\bin2mem test0.bin > test0.hex

@echo Run hackhex.pl
perl perl\hackhex.pl test0.hex 2048

@echo Copy test0.hex to Downloads
copy test0.hex c:\Users\scd\Downloads\x820_hex\test0.hex

@echo DONE !!

pause

