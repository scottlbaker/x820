
;=======================================================
; A test program for the x820 FPGA z80 computer system
; Send a counting pattern to the LEDs on the
; DE10 FPGA development board
;
; (c) Scott L. Baker  2020
;=======================================================

           org  100h

           call inittm1       ; initialize the timer
           call inituart      ; init the UART
           ld   c,0           ; initialize the LED value

ledloop:   in   a,(timecntl)  ; read the timer
           and  tmrdone       ; check timer status
           jp   z,ledloop     ; loop

blink:     call inittm1       ; re-init the timer
           ld   a,c           ; LED count value
           out  (diagleds),a  ; write to LEDs
           inc  c             ; count
           call kbhit         ; exit on key pressed
           jp   ledloop       ; loop forever

;---------------------------------------------------
; Initialize the timer
; modifies register a
;---------------------------------------------------
inittm1:   ld   a,1           ; l sec timeout
           out  (timeicl),a
           ld   a,07h         ; 1 sec resolution
           out  (timecntl),a  ; enable the timer
           ret

;-------------------------------------------------------
; Initialize the UART
; modifies register a
;-------------------------------------------------------
inituart:  ld   a,3           ; enable tx and rx
           out  (uartcntl),a
           ret

;-------------------------------------------------------
; check for a keypress
; modifies register a
;-------------------------------------------------------
kbhit:     in   a,(uartstat)  ; get uart status
           and  rxempty       ; rx fifo empty?
           jr   z,kbexit      ; exit if not empty
           ret                ; return to blink loop
kbexit:    in   a,(uartdata)  ; get the character
           jp   cmdloop       ; exit to monitor

;-------------------------------------------------------
; monitor entry point
;-------------------------------------------------------

cmdloop    equ  8             ; monitor warm start

;-------------------------------------------------------
; x820 register definitions
;-------------------------------------------------------

uartcntl   equ  00h       ; UART control register
uartstat   equ  01h       ; UART status  register
uartdata   equ  02h       ; UART data register
uarttest   equ  03h       ; UART test register

rndgen0    equ  04h       ; RNG data register 0
rndgen1    equ  05h       ; RNG data register 1
rndgen2    equ  06h       ; RNG data register 2

timecntl   equ  08h       ; timer control register
timeicl    equ  09h       ; initial count low
timeich    equ  0ah       ; initial count high

diagleds   equ  0ch       ; LED data register

;-------------------------------------------------------
; register bit definitions
;-------------------------------------------------------

rx_en      equ  02h       ; rx enable
tx_en      equ  01h       ; tx enable

txempty    equ  08h       ; tx fifo is empty
txfull     equ  04h       ; tx fifo is full
rxfull     equ  02h       ; rx fifo is full
rxempty    equ  01h       ; rx fifo is empty

tmrdone    equ  01h       ; timer done bit

;-------------------------------------------------------
; ascii character aliases
;-------------------------------------------------------

cr         equ  0dh       ; carriage return
lf         equ  0ah       ; linefeed
esc        equ  1bh       ; escape
bs         equ  08h       ; backspace
ws         equ  20h       ; space

           db   '$$'      ; end of file

           end

