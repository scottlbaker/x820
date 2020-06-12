
;=======================================================
; z80 Lunar Lander Game     Version 1.0
;
; A simple VT100 text game simulating a lunar landing
; inspired by a game called Lunar which was written
; in 1969 in a DEC language called FOCAL and which
; ran on a PDP-8. This version was written for the
; x820 FPGA z80 computer system
;
; (c) Scott L. Baker  2020
;=======================================================

           org  100h

start:     call initgame      ; initialize the game
gameloop:  call prntline      ; print current status
           call checker       ; landing checker
           call calculate     ; calculate next state
           call kbhit         ; quit if key pressed
           call inctime       ; increment time
           jr   gameloop      ; loop until done

;-------------------------------------------------------
; Initialize the game
; registers bc, de, and hl are modified
;-------------------------------------------------------
initgame:  ld   hl,initmsg    ; print
           call puts          ; welcome message
           ld   hl,hdrmsg     ; print
           call puts          ; header
           ld   de,time       ; initialize variables
           ld   hl,xtime
           ld   bc,10
           ldir
           ret

;-------------------------------------------------------
; Print the current status
; registers 
;-------------------------------------------------------
prntline:  ld   hl,time       ; time
           ld   b,2
           call printvar
           ld   b,3           ; speed
           call printvar
           ld   b,2           ; fuel
           call printvar
           ld   b,4           ; height
           call printvar
           call get3s         ; get 3 digit string
           call puthl4        ; burn
           call crlf
           ret

;-------------------------------------------------------
; Print a RAM variable
; modifies registers a, b, de, and hl
;-------------------------------------------------------
printvar:  push hl
           ld   e,(hl)
           inc hl
           ld   d,(hl)
           ld   h,d
           ld   l,e
           call puthl4
           call space
           pop  hl
           inc hl
           inc hl
           ret

;-------------------------------------------------------
; Increment time RAM variable by 10 seconds
; modifies register a
;-------------------------------------------------------
inctime:   ld   hl,time
           ld   e,(hl)
           inc  hl
           ld   d,(hl)
           ld   hl,10
           add  hl,de
           ld   d,h
           ld   e,l
           ld   hl,time
           ld   (hl),e
           inc  hl
           ld   (hl),d
           ret

;-------------------------------------------------------
; Next state calculations
;-------------------------------------------------------
calculate: call nxtspeed
           call nxtfuel
           call nxthite
           ret

;-------------------------------------------------------
; Calculate next speed
; modifies registers bc, de, and hl
;-------------------------------------------------------
nxtspeed:  ld   hl,speed
           ld   e,(hl)
           inc  hl
           ld   d,(hl)
           ld   hl,burn
           ld   c,(hl)
           inc  hl
           ld   b,(hl)
           ld   hl,100        ; gravity
           add  hl,de         ; + speed
           sbc  hl,bc         ; - burn
           push hl
           pop  de
           ld   hl,speed      ; new speed
           ld   (hl),e
           inc  hl
           ld   (hl),d
           ret

;-------------------------------------------------------
; Calculate next fuel
; modifies registers bc, de, and hl
;-------------------------------------------------------
nxtfuel:   ld   hl,fuel
           ld   e,(hl)
           inc  hl
           ld   d,(hl)
           ld   hl,burn
           ld   c,(hl)
           inc  hl
           ld   b,(hl)
           push de
           pop  hl
           xor  a             ; clear carry
           sbc  hl,bc         ; fuel - burn
           push hl
           pop  de
           jp   m,nxtfx2      ; negative fuel
           ld   a,d
           or   e
           jp   z,nxtfx2      ; zero fuel

nxtfx1:    ld   hl,fuel       ; update fuel
           ld   (hl),e
           inc  hl
           ld   (hl),d
           ret

nxtfx2:    ld   hl,fuelmsg    ; no fuel !!
           call puts
           jp   cmdloop


;-------------------------------------------------------
; Calculate next height
; modifies registers bc, de, and hl
;-------------------------------------------------------
nxthite:   ld   hl,height
           ld   e,(hl)
           inc  hl
           ld   d,(hl)
           ld   hl,speed
           ld   c,(hl)
           inc  hl
           ld   b,(hl)
           push de
           pop  hl
           xor  a             ; clear carry
           sbc  hl,bc         ; height - speed
           jp   m,nxthtx2     ; negative
           push hl
           pop  de
nxthtx1:   ld   hl,height     ; new height
           ld   (hl),e
           inc  hl
           ld   (hl),d
           ret

nxthtx2:   ld   de,0          ; zero height
           jp   nxthtx1

;-------------------------------------------------------
; Landing checker
;
; if landed and ..
;   speed < 100 then good landing
;   speed < 500 then survive but stranded
;   speed > 500 then no survivors
;-------------------------------------------------------
checker:   ld   hl,height     ; height
           ld   e,(hl)
           inc  hl
           ld   a,(hl)
           or   e             ; if not landed
           ret  nz            ; then return

checkx1:   ld   hl,speed      ; we are landed
           ld   e,(hl)        ; check the speed
           inc  hl
           ld   d,(hl)
           push de
           pop  hl
           push hl
           ld   de,100
           sbc  hl,de
           pop  hl
           jr   c,checkx3
           ld   de,500
           sbc  hl,de
           jr   c,checkx2
           ld   hl,deadmsg    ; no survivors !!
           call puts
           jp   cmdloop
checkx2:   ld   hl,bentmsg    ; bent lander !!
           call puts
           jp   cmdloop
checkx3:   ld   hl,goodmsg    ; good landing !!
           call puts
           jp   cmdloop

;-------------------------------------------------------
; display hl in decimal
;-------------------------------------------------------
puthl4:    ld   a,h
           and  80h           ; check sign bit
           jr   z,puthx1      ; skip if positive
           push hl            ; else negate hl
           pop  de
           ld   hl,0
           xor  a             ; clear carry
           sbc  hl,de
           ld   a,'-'         ; print minus sign
           call putc
           jr   puthx2
puthx1:    ld   de,-10000
           call puthx3
puthx2:    ld   de,-1000
           call puthx3
           ld   de,-100
           call puthx3
           ld   e,-10
           call puthx3
           ld   e,-1
puthx3:    ld   a,'0'-1
puthx4:    inc  a
           add  hl,de
           jr   c,puthx4
           sbc  hl,de
           jr   putc

;-------------------------------------------------------
; Print a carriage return and linefeed
; modifies register a
;-------------------------------------------------------
crlf:      ld   a,cr
           call putc
           ld   a,lf
           jp   putc

;-------------------------------------------------------
; Print (b) space characters
; modifies registers a and b
;-------------------------------------------------------
space:     ld   a,' '
           call putc
           dec  b
           ret  z
           jr   space

;-------------------------------------------------------
; check for a keypress
; modifies register a
;-------------------------------------------------------
kbhit:     in   a,(uartstat)  ; get uart status
           and  rxempty       ; rx fifo empty?
           jp   z,cmdloop     ; exit if not empty
           ret                ; continue

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
; Get a character from the UART
; modifies register a
;-------------------------------------------------------
getc:      in   a,(uartstat)  ; get uart status
           and  rxempty       ; rx fifo empty?
           jr   nz,getc       ; wait if empty
           in   a,(uartdata)  ; get a character
           ret

;-------------------------------------------------------
; Get a string of 3 digits from the UART
; modifies registers a and hl
;-------------------------------------------------------
get3s:     ld   hl,linbuf     ; address of line buffer
           ld   b,3           ; get 3 digits
get3x:     call getc          ; get a character
           cp   ctrlc         ; if control-c
           jp   z,cmdloop     ; exit to monitor
           call isdigit       ; is it a digit?
           jr   nc,get3x      ; ignore non-digits
           call putc          ; echo the character
           ld   (hl),a        ; write to line buffer
           inc  hl            ; increment pointer
           dec  b
           jr   z,cnvd2h      ; convert when done
           jr   get3x         ; repeat

;-------------------------------------------------------
; convert decimal ascii in buffer to hex
; modifies registers a, b, de, and hl
;-------------------------------------------------------
cnvd2h:    ld   hl,linbuf     ; address of line buffer
           ld   a,(hl)        ; 100-place digit
           sub  30h           ; remove ascii offset
           ld   de,0
           ld   ix,0
           ld   b,100
           ld   e,a
cnvlp1:    add  ix,de
           dec  b
           jr   nz,cnvlp1
           inc  hl
           ld   a,(hl)        ; 10-place digit
           sub  30h           ; remove ascii offset
           ld   b,10
           ld   e,a
cnvlp2:    add  ix,de
           dec  b
           jr   nz,cnvlp2
           inc  hl
           ld   a,(hl)        ; 1-place digit
           sub  30h           ; remove ascii offset
           ld   e,a
           add  ix,de
           push ix
           pop  hl            ; result in hl
           ld   de,200
           xor  a             ; clear carry
           sbc  hl,de
           jr   c,cnvdnx      ; if > 200 then
           ld   ix,200        ; force max 200
cnvdnx:    push ix
           pop  de            ; result in de
           call wrtburn       ; update burn variable
           call over3s        ; backup cursor
           push ix
           pop  hl            ; result in hl
           ret

;-------------------------------------------------------
; Write the burn variable
; modifies register hl
;-------------------------------------------------------
wrtburn:   ld   hl,burn
           ld   (hl),e
           inc  hl
           ld   (hl),d
           ret

;-------------------------------------------------------
; Backup 3 spaces for overwrite of burn rate
; modifies register a
;-------------------------------------------------------
over3s:    ld   a,bs
           call putc
           ld   a,bs
           call putc
           ld   a,bs
           jp   putc

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
; x820 monitor entry point
;-------------------------------------------------------

cmdloop    equ  8         ; monitor warm start

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

;-------------------------------------------------------
; x820 register bit definitions
;-------------------------------------------------------

rx_en      equ  02h       ; rx enable
tx_en      equ  01h       ; tx enable

txempty    equ  08h       ; tx fifo is empty
txfull     equ  04h       ; tx fifo is full
rxfull     equ  02h       ; rx fifo is full
rxempty    equ  01h       ; rx fifo is empty

;-------------------------------------------------------
; ascii character aliases
;-------------------------------------------------------

cr         equ  0dh       ; carriage return
lf         equ  0ah       ; linefeed
bs         equ  08h       ; backspace
ctrlc      equ  03h       ; control-c

;-------------------------------------------------------
; Strings and messages
;-------------------------------------------------------

initmsg    db   cr,lf,'  -- Lunar Lander Simulation --',cr,lf,cr,lf
           db   'The AGC has failed so you must manually',cr,lf
           db   'update the burn rate every 10 seconds',cr,lf
           db   'to a value between 0 and 200 (kg/sec)',cr,lf
           db   cr,lf,cr,lf,0

hdrmsg     db   'Time   Speed   Fuel   Height   Burn',cr,lf
           db   '-----  -----   -----  ------   -----',cr,lf,0

goodmsg    db  cr,lf,'You have safely landed on the moon'
           db  cr,lf,'Congratulations!!',cr,lf,0
deadmsg    db  cr,lf,'Your spaceship has crashed'
           db  cr,lf,'There were no survivors',cr,lf,0
bentmsg    db  cr,lf,'Your spaceship has crashed'
           db  cr,lf,'Good luck getting back home',cr,lf,0
fuelmsg    db  cr,lf,'There is no fuel left and'
           db  cr,lf,'you are lost in space',cr,lf,0

;-------------------------------------------------------
; RAM variables
;-------------------------------------------------------

negval     db  0          ; negative value

linbuf     ds  4          ; line buffer

time       ds  2
speed      ds  2
fuel       ds  2
height     ds  2
burn       ds  2

xtime      dw  0
xspeed     dw  1000
xfuel      dw  8000
xheight    dw  10000
xburn      dw  0

           end
