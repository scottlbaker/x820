@echo off

@echo Assemble monitor.asm
..\misc\bin\az80 -l monitor.lst -o monitor.hex monitor.asm

@echo Convert monitor.hex to monitor.bin
..\misc\bin\hex2bin monitor

@echo Convert from monitor.bin to ..\monitor.hex
..\misc\bin\bin2mem monitor.bin > ..\monitor.hex

@echo DONE !!

pause
