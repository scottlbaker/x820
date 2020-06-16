@echo off

@echo Assemble zexdoc.asm
..\misc\bin\az80 -l zexdoc.lst -o zexdoc.hex zexdoc.asm

@echo Convert zexdoc.hex to zexdoc.bin
..\misc\bin\hex2bin zexdoc

@echo Convert from zexdoc.bin to zexdoc.hex
..\misc\bin\bin2mem zexdoc.bin > zexdoc.hex

@echo Run hackhex.pl
perl perl\hackhex.pl zexdoc.hex 10000

@echo Copy zexdoc.hex to Downloads
copy zexdoc.hex c:\Users\scd\Downloads\x820_hex\zexdoc.hex

@echo DONE !!

pause

