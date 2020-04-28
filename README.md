# Summary

The x820 project is an FPGA implementation of a z80 computer system

The hardware part of the project includes:

- a z80 CPU
- a simple UART
- a 24-bit random number generator
- a 16-bit timer

The software part of the project includes:

- a Monitor with the capability to load and run demo programs
- some demo programs

The project was inspired by the Xerox 820 computer system (circa 1981).
However it is not hardware compatible with the Xerox 820.

# Hardware

## Z80 CPU

I wrote this Verilog model based solely on published information from Zilog data books. I used the YAZE preliminary instruction test to validate the model , but I have not yet run any of the more extensive Z80 test suites. I made no effort to match the instruction cycle times, so programs that depend on that won&#39;t work, but since it runs at a 50 MHz clock speed in the DE10, those programs wouldn&#39;t work anyway. I did not implement the undocumented Z80 instructions.

## UART

The UART is generic and not modeled after any existing UART.
The baud rate is fixed at 115200

The x820 I/O space register addresses are:

- uartcntl equ 00h ; control register
- uartstat equ 01h ; status register
- uartdata equ 02h ; data register

The UART control register bit definitions are

- rx\_en equ 02h ; rx enable
- tx\_en equ 01h ; tx enable

The UART status register bit definitions are

- txempty equ 08h ; tx fifo is empty
- txfull equ 04h ; tx fifo is full
- rxfull equ 02h ; rx fifo is full
- rxempty equ 01h ; rx fifo is empty

## Random Number Generator

This is a 24-bit pseudo-random counter.

The RNG I/O space register addresses are:

- rndgen0 equ 04h ; data register 0
- rndgen1 equ 05h ; data register 1
- rndgen2 equ 06h ; data register 2

The RNG control register bit definitions are

- rng\_en equ 01h ; rng enable

## 16-bit Timer

The timer is generic and not modeled after any existing UART

The timer I/O space register addresses are:

- timecntl equ 08h ; timer control/status register
- timeicl equ 09h ; initial count low
- timeich equ 0ah ; initial count high

The timer control register bit definitions are:

- tmres1 equ 04h ; timer resolution
- tmres0 equ 02h ; timer resolution
- tmrdone equ 01h ; timer done bit

The timer resolution definitions are:

- tmres = 00 for 1 msec resolution
- tmres = 01 for 10 msec resolution
- tmres = 10 for 100 msec resolution
- tmres = 11 for 1 sec resolution

# The Monitor

The monitor has the following commands

- h       :: print help message
- b       :: boot (jump to 0x100)
- t       :: run memory test
- p       :: program load
- g addr  :: jump to addr
- d addr  :: dump memory starting at addr
- i port  :: read from input port
- o port  :: write to output port

# Demo Programs

The following demo programs are included in this repo:

- blinky.asm -- blink the DE10 LEDs at 1Hz rate
- 99bottles.asm -- a program that uses BDOS calls to print strings
- life.asm -- Conway&#39;s Game of Life
- basic.asm -- Tiny BASIC
- piCalc.asm -- A Pi calculation algorithm
- lunar.asm -- A text-based Lunar Lander game

To load a demo program, use the monitor program load command and then use your terminal emulator file send command to upload the hex file.
The demo program hex files are located in the data/monitor/hex directory
The monitor load command loads the hex file starting at memory location 100h
Once loaded use the monitor goto command to start the program.  (g 0100)

# Required hardware

- Terasic DE10-nano -- available from: [terasic.com](https://www.terasic.com.tw/en/)
- Serial to USB adapter -- available on Amazon

The serial adapter is connected to the DE10-nano on these pins

- PIN\_AE22 -- txd from DE10 to adapter
- PIN\_AF21 -- rxd from adapter to DE10

# Required software \*\*

- hex2bin.exe -- converts Intel hex format to binary format
- bin2mem.exe -- converts binary format to simple hex format
- hackhex.pl -- creates a monitor load format hex file
- Intel/Altera Quartus Programmer -- google Quartus download
- Perl -- to run the above Perl script
- z80 assembler -- I used az80 [retrotechnology.com](http://www.retrotechnology.com/restore/az80.html)
- terminal emulator -- I used TeraTerm

\* The first 3 programs on this list are included in the repo. The others you can download from their respective sites.

\*\* The quartus/output\_files chain1.cdf file can be used to configure the Quartus programmer.

# NOTES:

I have not included the Verilog RTL source code in this repo. At some point in the future I may release it. The repo does include the files needed to program the FPGA, and to run the demo programs. You can also write and run your own programs on the x820. Let me know if you develop any cool demos :)

All development was done on a Windows-10 system.

