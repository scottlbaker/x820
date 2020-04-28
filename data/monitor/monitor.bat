@echo off

@echo Assemble monitor.asm
az80 -l monitor.lst -o monitor.hex monitor.asm

@echo Convert monitor.hex to monitor.bin
hex2bin monitor

@echo Convert from monitor.bin to ram.hex
bin2mem monitor.bin > ram.hex

@echo Copy ram.hex to ..
copy /y ram.hex ..

@echo DONE !!

pause
