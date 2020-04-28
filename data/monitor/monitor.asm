
;=======================================================
; x820 Monitor ROM   Version 1.0
;
; A monitor for the x820 FPGA z80 computer system
; This project was inspired by the Xerox 820 computer
; system (circa 1981)
;
; (c) Scott L. Baker  2020
;=======================================================

           org  0

           jp   moninit       ; monitor init
           ds   2
           jp   cpmbdos       ; CP/M BDOS
           jp   cmdloop       ; monitor command

simode     equ  0             ; 1=sim 0=synthesis

rom        equ  0f000h        ; start of rom

           org  rom

;-------------------------------------------------------
; Monitor entry point
;-------------------------------------------------------
moninit:   di                 ; disable interrupts
           ld   sp,tos        ; init the stack pointer
           call inituart      ; init the UART
           call inittm0       ; init timer
           call clrscr        ; clear the screen
           call help          ; print help message

cmdloop:   call prompt        ; print a prompt string
           call getc          ; get a character
           call search        ; lookup command
           jr   nz,badcmd     ; z=0 if search fails
           call putc
           call callx         ; call command routine
           jr   cmdloop       ; loop forever
badcmd:    call what          ; unknown command
           jr   cmdloop       ; loop forever

callx:     jp   (ix)          ; jump to code @ ix

dbhalt:    halt               ; debug halt


;-------------------------------------------------------
; Command table
;-------------------------------------------------------
cmdtab:    db   'o'           ; call oport
           db   'i'           ; call iport
           db   'd'           ; call mdmp
           db   'g'           ; call goto
           db   'p'           ; call pload
           db   't'           ; call mtest
           db   'b'           ; call boot
           db   'h'           ; call help

           dw   help          ; print help message
           dw   boot          ; jump to 0100h
           dw   mtest         ; run memory test
           dw   pload         ; program loader
           dw   goto          ; jump to memory location
           dw   mdump         ; dump memory
           dw   iport         ; read from input port
           dw   oport         ; write to output port

cmdsiz     equ  $-cmdtab

;-------------------------------------------------------
; Search the command table
; modifies registers bc and hl
;-------------------------------------------------------
search:    ld   hl,cmdtab     ; point to command table
           ld   bc,cmdsiz/3   ; command table size
           call tolower       ; convert to lower case
           cpir               ; search table
           ret  nz            ; exit if search fails
           add  hl,bc
           add  hl,bc         ; add residue from cpir
           add  hl,bc         ; to hl 3 times to get
           ld   c,(hl)        ; address from table
           inc  hl
           ld   b,(hl)
           push bc
           pop  ix            ; ix has call address
           ret                ; z=1 if command found

;-------------------------------------------------------
; Boot command (start program at 0100h)
;-------------------------------------------------------
boot:      call crlf          ; print linefeed
           jp   0100h         ; jump to 0100h

;-------------------------------------------------------
; Memory test command
;-------------------------------------------------------
mtest:     ld   b,0           ; init pass count
           ld   e,0f0h        ; stop  at f000h
           ld   h,01h
           ld   l,00h         ; start at 0100h
           ld   a,1
           out  (rndgen0),a   ; enable random numbers
mtloop:    in   a,(rndgen0)   ; get a random number
           ld   c,a           ; save in c
           ld   (hl),a        ; store a in (hl)
           xor  a             ; clear a
           ld   a,(hl)        ; load a from (hl)
           cp   c             ; they should match
           jr   nz,mterr      ; exit if they dont
           inc  hl            ; next location
           ld   a,h
           cp   e             ; check for last page
           jr   nz,mtloop     ; loop
           jp   pass          ; print pass message
mterr:     jp   error         ; print error message

;-------------------------------------------------------
; Goto location command
;-------------------------------------------------------
goto:      call space         ; print a space
           ld   a,4           ; 4 ascii chars
           call gethex        ; get the address
           ret  c             ; exit if error
           push bc            ; bc has the address
           pop  ix            ; now ix has the address
           call crlf          ; print linefeed
           jp   (ix)          ; jump to code @ ix

;-------------------------------------------------------
; Memory dump command
;-------------------------------------------------------
mdump:     call space         ; print a space
           ld   a,4           ; 4 ascii chars
           call gethex        ; get the address
           ret  c             ; exit if error
           call crlf          ; print linefeed
           ld   de,20h        ; dump 32x16 bytes
           push bc            ; bc has the start address
           pop  hl            ; now hl has the address
mdmp1:     call put4hs        ; print start address
           call space         ; print a space
           ld   b,10h         ; 16-byte inner loop
mdmp2:     ld   a,(hl)        ; get a data byte @ hl
           inc  hl
           call put2hs        ; print the data in hex
           djnz mdmp2         ; repeat 16 times
           call crlf          ; print linefeed
           dec  de            ; decrement count
           ld   a,d
           or   e             ; check iteration count
           jr   nz,mdmp1      ; and loop if not zero
           ret

;-------------------------------------------------------
; Read from input port command
;-------------------------------------------------------
iport:     call space         ; print a space
           ld   a,2           ; 2 ascii chars
           call gethex        ; get the port number
           jr   c,iportx      ; exit if error
           call crlf          ; print linefeed
           ld   c,b
           in   a,(c)         ; get data from port
           call put2hx        ; print the data
           ret
iportx:    jp   error

;-------------------------------------------------------
; Write to output port command
;-------------------------------------------------------
oport:     call space         ; print a space
           ld   a,2           ; 2 ascii chars
           call gethex        ; get the port number
           jr   c,oportx      ; exit if error
           push bc            ; save port number
           call space         ; print a space
           ld   a,2           ; 2 ascii chars
           call gethex        ; get the data
           jr   c,oportx      ; exit if error
           ld   a,b           ; save the data to output
           pop  bc            ; restore port number
           ld   c,b           ; c gets the port number
           out  (c),a         ; output data
           ret
oportx:    jp   error

;-------------------------------------------------------
; Program load command
;-------------------------------------------------------
pload:     call ilprt         ; print a message
           db   cr,lf,'Start program load',cr,lf,0
           ld   hl,0          ; clear CRC
           ld   (crc16),hl
           ld   hl,0100h      ; load dest address
ploop:     push hl            ; save hl
           ld   a,82h         ; 2 ascii chars
           call gethex        ; with magic bit set
           pop  hl            ; restore hl
           jr   c,plexit      ; exit if not hex
           ld   (hl),b        ; store data
           call calcrc        ; calculate CRC too
           inc  hl            ; inc dest address
           call getc          ; get linefeed
           jp   ploop         ; loop until done
plexit:    call rxbyt1        ; purge data
           jp   nc,plexit     ; carry means timeout
           call ilprt         ; print a message
           db   'CRC = ',0
           ld   hl,(crc16)
           call put4hs        ; print 16-bit CRC
           call crlf          ; print linefeed
           jp   cmdloop       ; jump to monitor

;-------------------------------------------------------
; 16-bit CRC calculations
;   modifies a,de
;-------------------------------------------------------
calcrc:    push bc
           push hl
           ld   a,b           ; b has the new byte
           ld   hl,(crc16)    ; get CRC so far
           xor  h             ; XOR into CRC top byte
           ld   h,a
           ld   de,1021h
           ld   b,8           ; prepare to rot 8 bits
crotlp:    add  hl,hl         ; 16-bit shift
           jp   nc,cclr       ; skip if bit 15 was 0
           ld   a,h           ; CRC=CRC xor 1021H
           xor  d
           ld   h,a
           ld   a,l
           xor  e
           ld   l,a
cclr:      dec  b
           jp   nz,crotlp     ; rotate 8 times
           ld   (crc16),hl    ; save CRC so far
           pop  hl
           pop  bc
           ret

;----------------------------------------------------
; Initialize the timer high to zero
; modifies register a
;----------------------------------------------------
inittm0:   xor  a
           out  (timeich),a   ; load timer high
           ret

;----------------------------------------------------
; Initialize the timer
; on entry:
;   a has the timeout value
; on exit:
;   modifies register a
;----------------------------------------------------
inittm1:   out  (timeicl),a   ; load timer low
           ld   a,07h         ; 1 sec resolution
           out  (timecntl),a  ; enable the timer
           ret

;-------------------------------------------------------
; Print hex digits
; modifies register a
;-------------------------------------------------------
put4hs:    ld   a,h           ; register h
           call put2hx        ; print 2 hex digits
           ld   a,l           ; register l
put2hs:    call put2hx        ; print 2 hex digits
           jp   space         ; print a space

put2hx:    push af            ; save a
           rra
           rra
           rra
           rra
           call putnib
           pop  af
putnib:    and  0fh
           add  a,90h
           daa
           adc  a,40h
           daa
           jp   putc

;-------------------------------------------------------
; Initialize the UART
; modifies register a
;-------------------------------------------------------
inituart:  ld   a,3           ; enable tx and rx
           out  (uartcntl),a
           ret

           IF   simode        ; sim-mode condition

;-------------------------------------------------------
; DUMMY routine  (1 of 5)
;-------------------------------------------------------
putc:      nop
           ret

;-------------------------------------------------------
; DUMMY routine  (2 of 5)
;-------------------------------------------------------
puts:      ld   a,(hl)        ; get the next char
           inc  hl            ; increment pointer
           or   a             ; check for string end
           ret  z             ; return if done
           jr   puts          ; repeat

;-------------------------------------------------------
; DUMMY routine  (3 of 5)
;-------------------------------------------------------
rxbyte:    xor  a             ; clear the carry

;          fall into getc

;-------------------------------------------------------
; DUMMY routine  (4 of 5)
;-------------------------------------------------------
getc:      push hl
           ld   hl,(ccptr)    ; get the pointer
           ld   a,(hl)        ; get the data
           inc  hl            ; increment pointer
           ld   (ccptr),hl    ; and save it
           pop  hl
           ret

;-------------------------------------------------------
; DUMMY routine  (5 of 5)
;-------------------------------------------------------
tmwait:    nop
           ret

           ELSE               ; sim-mode condition

;-------------------------------------------------------
; Send a character to the UART
; char to be sent is in register a
; no registers are modified
;-------------------------------------------------------
putc:      push af            ; save a
putcx:     in   a,(uartstat)  ; get uart status
           and  txfull        ; tx fifo full?
           jr   nz,putcx      ; wait if full
           pop  af            ; restore a
           out  (uartdata),a  ; put a character
           ret

;-------------------------------------------------------
; Send a string to the UART
; pointer to string is in register hl
; strings are terminated with null (=0)
; modifies registers a and hl
;-------------------------------------------------------
puts:      ld   a,(hl)        ; get the next char
           or   a             ; check for string end
           ret  z             ; return if done
           call putc          ; put a character
           inc  hl            ; increment pointer
           jr   puts          ; repeat

;-------------------------------------------------------
; Get a character from the UART with timeout
; modifies register a
;-------------------------------------------------------
rxbyte:    in   a,(timecntl)  ; get timer status
           and  tmrdone       ; check for timeout
           jr   z,rxbnto      ; jump if no timeout
           scf                ; else set carry and
           ret                ; return
rxbnto:    in   a,(uartstat)  ; get uart status
           and  rxempty       ; rx fifo empty?
           jr   nz,rxbyte     ; wait if empty
           in   a,(uartdata)  ; get a character
           ret

;-------------------------------------------------------
; Get a character from the UART
; modifies register a
;-------------------------------------------------------
getc:      in   a,(uartstat)  ; get uart status
           and  rxempty       ; rx fifo empty?
           jr   nz,getc       ; wait if empty
           in   a,(uartdata)  ; get a character
           ret

;----------------------------------------------------
; Timer wait loop
;----------------------------------------------------
tmwait:    in   a,(timecntl)  ; get timer status
           and  tmrdone       ; check for timeout
           jr   z,tmwait      ; wait for timeout
           ret

           ENDIF              ; sim-mode condition

;-------------------------------------------------------
; Get a string from the UART
; pointer to string buffer is in register hl
; modifies registers a and hl
;-------------------------------------------------------
gets:      ld   hl,linbuf     ; address of line buffer
           call space         ; print a space
getsx:     call getc          ; get a character
           cp   cr            ; check for string end
           jr   z,getdone     ; done
           call putc          ; echo the character
           call tolower       ; convert to lower case
           ld   (hl),a        ; write to line buffer
           inc  hl            ; increment pointer
           jr   getsx         ; repeat
getdone:   ld   (hl),0        ; terminate the string
           ret

;-------------------------------------------------------
; Print an in-line message
;-------------------------------------------------------
ilprt:     ex   (sp),hl       ; get msg addr
           ld   a,(hl)
           call puts          ; print string
           ex   (sp),hl       ; get return address
           ret

;-------------------------------------------------------
; Receive a byte with 1 second timeout
;-------------------------------------------------------
rxbyt1:    ld   a,1           ; 1-second timeout
           call inittm1       ; init the timer
           jp   rxbyte

;-------------------------------------------------------
; Convert character to lower case
; char to be tested is in register a
; modifies register a
;-------------------------------------------------------
tolower:   cp   41h           ; 'A'
           jr   c,toldone     ; done if < 'A'
           cp   5bh           ; '['
           jr   nc,toldone    ; done if > 'Z'
           xor  20h           ; else convert
toldone:   ret

;-------------------------------------------------------
; Check if char is a digit
; char to be tested is in register a
; no registers are modified
;-------------------------------------------------------
isdigit:   cp   30h           ; '0'
           jr   c,notdig1     ; non-digit if < '0'
           cp   3ah           ; ':'
           jr   nc,notdig2    ; non-digit if > '9'
           ret                ; c=1 for digit
notdig1:   ccf
notdig2:   ret                ; c=0 for non-digit

;-------------------------------------------------------
; Check if char is a hex char (a-f)
; char to be tested is in register a
; no registers are modified
;-------------------------------------------------------
isa2f:     cp   61h           ; 'a'
           jr   c,nota2f1     ; non-a2f if < 'a'
           cp   67h           ; 'g'
           jr   nc,nota2f2    ; non-digit if > 'f'
           ret                ; c=1 for a2f
nota2f1:   ccf
nota2f2:   ret                ; c=0 for non-a2f

;-------------------------------------------------------
; Check if char is a hex digit (0->f)
; char to be tested is in register a
; modifies registers b and c
;-------------------------------------------------------
ishex:     call isdigit       ; c=1 for digit
           jr   c,ishex1      ; c=1 for a2f
           call isa2f         ; c=1 for hex
ishex1:    ret                ; c=0 for non-hex

;-------------------------------------------------------
; Check if char is a separator
; char to be tested is in register a
; no registers are modified
;-------------------------------------------------------
issepc:    or   a             ; check for null
           ret  z             ; then check for space
           cp   20h           ; z=0 for non-separator
           ret                ; z=1 for separator

;-------------------------------------------------------
; check magic bit in d register and either
; call putc or exit -- used by gethex subroutine
;-------------------------------------------------------
xputc:     push af            ; save a
           ld   a,d           ; d has magic
           and  80h           ; check magic bit
           jr   nz,xputx      ; skip if bit set
           pop  af            ; restore a
           jp   putc          ; print char in a
xputx:     pop  af            ; restore a
           ret

;-------------------------------------------------------
; Get 2 or 4 ascii hex characters from the UART
; and write them to a buffer pointed to by hl
; the carry is set on illegal conversion
; modifies registers a,b,c,e and hl
;-------------------------------------------------------
gethex:    ld   hl,hexbuf     ; hex buffer
           ld   d,a           ; save loop counter
           and  07h           ; remove magic bit
           ld   e,a
gethex1:   call getc          ; get char from console
           call isdigit       ; check if digit
           jr   c,gethex3     ; branch if digit
           call isa2f         ; check if hex (a-f)
           jr   nc,gethexx    ; return if invalid
           call xputc         ; print the char
           sub  57h           ; hex (a-f) to binary
           jr   gethex4       ; continue
gethexx:   scf                ; set carry on error
           ret                ; error exit
gethex3:   call xputc         ; print the char
           sub  30h           ; digit to binary
gethex4:   ld   (hl),a        ; store binary value
           inc  hl            ; increment pointer
           ld   a,e           ; get the loop count
           dec  a             ; decrement it
           jr   z,gethex5     ; done if zero
           ld   e,a           ; restore loop count
           jr   gethex1       ; loop
gethex5:   ld   hl,hexbuf     ; reload the pointer
           ld   a,d
           and  07h           ; remove magic bit
           ld   d,a

;-------------------------------------------------------
; Convert 4 bytes (with ascii offsets already removed)
; pointed to by hl into a 16-bit binary address in bc
; modifies register a,b,c and hl
;-------------------------------------------------------
cnv16:     ld   a,(hl)        ; first byte
           sla  a             ; shift upper nibble
           sla  a             ; x4
           sla  a             ; x8
           sla  a             ; x16
           ld   b,a           ; save shifted result
           inc  hl
           ld   a,(hl)        ; get lower nibble
           add  a,b           ; combine nibbles
           ld   b,a           ; move msb of address to b
           ld   a,d           ; check if word or byte
           cp   2
           ret  z             ; exit if byte
           inc  hl            ; second byte
           ld   a,(hl)
           sla  a             ; shift upper nibble
           sla  a             ; x4
           sla  a             ; x8
           sla  a             ; x16
           ld   c,a           ; save shifted result
           inc  hl
           ld   a,(hl)        ; get lower nibble
           add  a,c           ; combine nibbles
           ld   c,a           ; move lsb of address to c
           ret

;-------------------------------------------------------
; CP/M BDOS jump table
;   c=2 print char
;   c=9 print string
;-------------------------------------------------------
cpmbdos:   ld   a,c
           cp   2
           jp   z,bdputc
           cp   9
           jp   z,bdputs
           ret

;-------------------------------------------------------
; Send a character to the UART
; char to be sent is in register e
; no registers are modified
;-------------------------------------------------------
bdputc:    in   a,(uartstat)  ; get uart status
           and  txfull        ; tx fifo full?
           jr   nz,bdputc     ; wait if full
           ld   a,e           ; get char in e
           out  (uartdata),a  ; put the character
           ret

;-------------------------------------------------------
; Send a string to the UART
; pointer to string is in register de
; strings are terminated with CP/M EOS (=$)
; modifies registers a and hl
;-------------------------------------------------------
bdputs:    ld   a,(de)        ; get the next char
           cp   '$'           ; check for string end
           ret  z             ; return if done
           call putc          ; put a character
           inc  de            ; increment pointer
           jr   bdputs        ; repeat
           ret

;-------------------------------------------------------
; Clear the screen
; modifies registers a and hl
;-------------------------------------------------------
clrscr:    ld   hl,vtclr
           jp   puts

;-------------------------------------------------------
; Print help message
; modifies registers a and hl
;-------------------------------------------------------
help:      ld   hl,helpmsg
           jp   puts

;-------------------------------------------------------
; Print error message
; modifies registers a and hl
;-------------------------------------------------------
error:     ld   hl,errmsg
           jp   puts

;-------------------------------------------------------
; Print pass message
; modifies registers a and hl
;-------------------------------------------------------
pass:      ld   hl,passmsg
           jp   puts

;-------------------------------------------------------
; Print a debug message
; modifies registers a and hl
;-------------------------------------------------------
debug:     ld   hl,dbgmsg
           jp   puts

;-------------------------------------------------------
; Print a prompt
; modifies registers a and hl
;-------------------------------------------------------
prompt:    ld   hl,iprompt
           jp   puts

;-------------------------------------------------------
; Overstrike and backspace
; modifies registers a and hl
;-------------------------------------------------------
overstk:   ld   hl,ovstk
           jp   puts

;-------------------------------------------------------
; Input a character and echo it
; modifies register a
;-------------------------------------------------------
echo:      call getc
           jp   putc

;-------------------------------------------------------
; Print unknown command message
; modifies register a
;-------------------------------------------------------
what:      ld   a,'?'
           jp   putc

;-------------------------------------------------------
; Print a space character
; modifies register a
;-------------------------------------------------------
space:     ld   a,' '
           jp   putc

;-------------------------------------------------------
; Print a carriage return and linefeed
; modifies register a
;-------------------------------------------------------
crlf:      ld   a,cr
           call putc
           ld   a,lf
           jp   putc

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
; x820 register bit definitions
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

;-------------------------------------------------------
; strings and messages
;-------------------------------------------------------

iprompt    db   cr,lf,'> ',0

ovstk      db   ' ',bs,0

vtclr      db   esc,'[2J'     ; clear screen
           db   esc,'[H'      ; home cursor
           db   0

helpmsg    db   cr,lf
           db   'x820 Monitor - Version 1.0',cr,lf
           db   cr,lf
           db   'h        :: print help message',cr,lf
           db   'b        :: jump to 0100h',cr,lf
           db   't        :: run memory test',cr,lf
           db   'p        :: program load',cr,lf
           db   'g <addr> :: jump to location',cr,lf
           db   'd <addr> :: dump memory',cr,lf
           db   'i <port> :: read from input port',cr,lf
           db   'o <port> :: write to output port',cr,lf
           db   0

dbgmsg     db   '  debug message'
           db   cr,lf
           db   0

errmsg     db   '  error occurred'
           db   cr,lf
           db   0

passmsg    db   '  OK'
           db   cr,lf
           db   0

           IF   simode        ; sim-mode condition

;-------------------------------------------------------
; data for dummy/debug getc routine
;-------------------------------------------------------

ccptr      dw   ccbuf

ccbuf      db   'g'           ; goto command
           db   '0'
           db   '0'
           db   '0'
           db   '0'

           db   'p'           ; load command
           db   cr
           db   '0'           ; first data
           db   cr
           db   '1'
           db   cr
           db   '0'
           db   cr
           db   '2'
           db   cr
           db   '0'
           db   cr
           db   '3'
           db   cr
           db   '0'
           db   cr
           db   '4'
           db   cr
           db   '$'
           db   cr
           db   '$'           ; termination

           ENDIF              ; sim-mode condition

;-------------------------------------------------------
; reserved RAM
;-------------------------------------------------------

           db   20h           ; line buffer space
linbuf     ds   80            ; line buffer
hexbuf     ds   4             ; hex conversion buffer

escflg     ds   1             ; console escape flag
coflag     ds   1             ; console output toggle
last       ds   2             ; mdump last address
crc16      dw   0             ; 16-bit CRC

;-------------------------------------------------------
; reserved for stack
;-------------------------------------------------------
           ds   32
tos        dw   0             ; top of stack

           end
