
;=======================================================
; z80 Pi calculation using the Spigot algorithm
;
; Limitations: 9674 digits of Pi
;
; Original Pascal code by: Stanley Rabinowitz
; Original z80 code by: Michael Bernard
; Modified for the x820 project by: Scott L. Baker
;
;=======================================================

debug      equ 0              ; debug mode
ndigits    equ 1000           ; digits to compute


           org  100h

startpi:   ld   hl,startmsg   ; welcome message
           call puts          ; display it
           call strttmr       ; start the timer
           ld   iy,iy0        ; init pointer
           ld   hl,ndigits    ; digits to compute
           inc  hl            ; + unit digit
           ld   (ndig),hl     ; save

           ld   de,3          ; divisor = 3
           exx
           ld   hl,0
           ld   de,0
           exx
           call lmulhl10      ; hl <= 10 * n
           call ldivhlde      ; hl /= 3
           ld   (len),hl      ; save to len

           inc  hl            ; hl <= len + 1
           ld   b,h           ; loop counter
           ld   c,l
           add  hl,hl         ; hl <= (len + 1) * 2
           ld   de,array      ; de <= array origin
           add  hl,de         ; de += (len + 1) * 2
           exx
           ld   hl,0          ; save sp to hl'
           add  hl,sp
           exx
           ld   sp,hl         ; sp <= hl
           ld   de,2          ; 2 to write
spl01:     push de            ; write 2 at sp
           dec  bc            ; dec loop counter
           ld   a,b
           or   c
           jr   nz,spl01      ; loop while counter > 0
           exx
           ld   sp,hl         ; restore sp from hl'

           xor  a
           ld   (iy+nines$),a ; counter of 9s <= 0
           ld   (iy+predg$),a ; predigit <= 0
           ld   (iy+grps$),10 ; groups counter
           ld   (iy+grpx$),6  ; digits counter
           ld   (iy+dot$),'.' ; decimal point

           ld   hl,0          ; jndx <= 0
           ld   (jndx),hl
           dec  hl            ; init decimals counter
           ld   (count),hl

forj:      ld   hl,(jndx)     ; hl <= jndx
           ex   de,hl         ; de <= jndx
           ld   hl,(ndig)     ; hl <= ndig
           or   a
           sbc  hl,de         ; hl -= de
           ld   de,3          ; de = 3 (divisor)
           exx
           ld   hl,0          ; hl' <= 0
           ld   de,0          ; de' <= 0
           exx
           call oneloop       ; base conversion
           ld   hl,(res)      ; res = 10*digit+rem
           ld   de,10
           call divhlde       ; res /= 10
           ld   (array+2),de  ; remainder in de
           ld   a,l           ; examine digit
           cp   9             ; if not 9
           jr   nz,qnot9      ;   go
           inc  (iy+nines$)   ; else count 9s
           jr   endif1        ; done
qnot9:     cp   10            ; if not 10
           jr   nz,qnot10     ;   go
           ld   a,(iy+predg$) ; else get preceding digit
           ld   (iy+predg$),0 ; clear stored value
           inc  a             ; increment digit
           call outdig        ; display it
           ld   a,(iy+nines$) ; check for 9s
           or   a
           jr   z,nozeros     ; go if none
wzeros:    xor  a             ; display 0s instead of 9s
           call outdig
           dec  (iy+nines$)   ; dec 9s counter
           jr   nz,wzeros     ; loop until 0s displayed
nozeros:   jr   endif1        ; done

qnot10:    ld   a,(iy+jndx$)  ; get jndx
           or   (iy+jndx$+1)  ; is it 0 (first loop) ?
           ld   a,(iy+predg$) ; load digit preceding 9s
           ld   (iy+predg$),l ; store new digit
           call nz,outdig     ; display if not first loop
           ld   a,(iy+nines$) ; check for 9s
           or   a
           jr   z,nonines     ; go if none
wnines:    ld   a,9           ; display 9s
           call outdig
           dec  (iy+nines$)   ; dec 9s counter
           jr   nz,wnines     ; loop until 9s displayed
nonines:

endif1:    ld   hl,(jndx)     ; get main loop counter
           inc  hl            ; increment it
           ld   (jndx),hl     ; store new value
           ld   de,(ndig)     ; compare with ndig
           or   a
           sbc  hl,de         ; jndx == n ?
           ld   a,h
           or   l
           jp   nz,forj       ; loop until yes
           ld   a,(iy+predg$) ; display preceding digit
           call outdig
           ld   a,(iy+nines$) ; display following 9s
           or   a
           jr   z,nonines2
wnines2:   ld   a,9
           call outdig
           dec  (iy+nines$)
           jr   nz,wnines2
           call stoptmr       ; stop the timer
nonines2:  ld   hl,donemsg
           call puts          ; display done message
           call readtmr       ; read the timer
           ld   hl,timemsg
           call puts          ; display time message
           jp   cmdloop       ; return to the monitor

;-------------------------------------------------------
; divide hl by de
;-------------------------------------------------------
divhlde:   xor  a             ; init loop counter
           ex   de,hl         ; divisor to hl
divl1:     inc  a             ; inc counter
           ret  z             ; overflow: return
           add  hl,hl         ; shift left divisor
           jr   nc,divl1      ; loop and check bound
           rr   h             ; restore scaled divisor
           rr   l
           ld   b,h           ; scaled divisor to bc
           ld   c,l
           ex   de,hl         ; dividend to hl
           ld   de,0          ; clear quotient
divl2:     ex   de,hl         ; shift left quotient
           add  hl,hl
           ex   de,hl
           sbc  hl,bc         ; try to sub dvdnd-dvsor
           inc  de            ; try to add 1 to quot
           jr   nc,divj2      ; if ok, go
           dec  de            ; cancel add to quot
           add  hl,bc         ; cancel subtraction
divj2:     srl  b             ; shift right divisor
           rr   c
           dec  a             ; dec loop counter
           jr   nz,divl2      ; continue while > 0
           ex   de,hl         ; quot to hl, rem to de
           ret                ; done

;-------------------------------------------------------
; long divide hl by de
;-------------------------------------------------------
ldivhlde:  ld   b,4           ; dividend byte counter
           ex   de,hl         ; divisor to hl
           exx
           ex   de,hl
           ld   a,d           ; get dividend high byte
           or   a             ; check it
           ld   a,e           ; get dividend next byte
           exx
           jr   nz,ldivj0     ; go if dvdnd not null
           dec  b             ; dec byte counter
           or   a             ; check dvdnd next byte
           jr   nz,ldivj0     ; go if dvdnd not null
           dec  b             ; dec byte counter
           or   d             ; check dvdnd next byte
           jr   nz,ldivj0     ; go if dvdnd not null
           dec  b             ; dec byte counter
ldivj0:    ld   a,b           ; mult byte count by 8
           add  a,a
           add  a,a
           add  a,a
           ld   b,a
           xor  a             ; init loop counter
ldivl1:    dec  b             ; dec byte counter
           jr   z,ldivj1      ; exit loop when zero
           inc  a             ; inc counter
           ret  z             ; overflow: return

           add  hl,hl         ; shift left divisor
           exx
           adc  hl,hl
           exx

           jr   nc,ldivl1     ; loop and check bound

ldivj1:    exx
           rr   h             ; restore scaled divisor
           rr   l
           ld   b,h           ; scaled divisor to bc
           ld   c,l
           ex   de,hl         ; dividend to hl
           ld   de,0          ; clear quotient
           exx
           rr   h             ; restore scaled divisor
           rr   l
           ld   b,h           ; scaled divisor to bc
           ld   c,l
           ex   de,hl         ; dividend to hl
           ld   de,0          ; clear quotient

ldivl2:    ex   de,hl         ; shift left quotient
           add  hl,hl
           ex   de,hl
           exx
           ex   de,hl
           adc  hl,hl
           ex   de,hl
           exx
           sbc  hl,bc         ; dvsor - dvdnd
           exx
           sbc  hl,bc
           exx
           inc  de            ; try to add 1
           jr   nc,ldivj2     ; if ok, go
           dec  de            ; cancel addition
           add  hl,bc         ; cancel subtraction
           exx
           adc  hl,bc
           exx

ldivj2:    exx
           srl  b             ; shift right divisor
           rr   c
           exx
           rr   b
           rr   c
           dec  a             ; dec loop counter
           jr   nz,ldivl2     ; continue while counter > 0
           ex   de,hl         ; quotient to hl
           exx
           ex   de,hl
           exx
           ret                ; done

;-------------------------------------------------------
; long mul hl,de (condition: hl' == 0)
; hl':hl <= hl * de':de
;-------------------------------------------------------
lmulhlde16:
           call lldbchl       ; move multiplicand
           ld   hl,0          ; product <= 0
           exx
           ld   hl,0
           exx
           ld   a,16          ; loop counter
lmull1:    exx                ; multiplicand
           srl  b
           rr   c
           exx
           rr   b
           rr   c
           call c,laddhlde    ; product += multiplicator
           ex   de,hl         ; product, hl':hl <<= 1
           add  hl,hl
           ex   de,hl
           exx
           ex   de,hl
           adc  hl,hl
           ex   de,hl
           exx
           dec  a             ; decrement loop counter
           jr   nz,lmull1     ; continue while counter > 0
           ret                ; done

;-------------------------------------------------------
; long ld bcx,hlx
; bc':bc <= hl':hl
;-------------------------------------------------------
lldbchl:   ld   b,h           ; bc <= hl
           ld   c,l
           exx
           ld   b,h           ; bc' <= hl'
           ld   c,l
           exx
           ret                ; done

;-------------------------------------------------------
; long add hlx,bcx
; hl':hl += bc':bc
;-------------------------------------------------------
laddhlbc:  add  hl,bc         ; hl += bc
           exx
           adc  hl,bc         ; hl' += bc' + carry
           exx
           ret                ; done

;-------------------------------------------------------
; long add hlx,dex
; hl':hl += de':de
;-------------------------------------------------------
laddhlde:  add  hl,de         ; hl += de
           exx
           adc  hl,de         ; hl' += de' + carry
           exx
           ret                ; done

;-------------------------------------------------------
; long add hlx,hlx
; hl':hl <<= 1
;-------------------------------------------------------
laddhlhl:  add  hl,hl         ; hl <<= 1
           exx
           adc  hl,hl         ; hl' <<= 1 with carry
           exx
           ret                ; done

;-------------------------------------------------------
; long mul hlx,10l
;-------------------------------------------------------
lmulhl10:  call lldbchl       ; bc':bc <= hl':hl
           call laddhlhl      ; hl':hl <<= 1
           call laddhlhl      ; hl':hl <<= 1
           call laddhlbc      ; hl':hl += bc':bc
           call laddhlhl      ; hl':hl <<= 1
           ret                ; done

;-------------------------------------------------------
; pi-spigot oneloop routine
;-------------------------------------------------------
oneloop:   call lmulhl10      ; indx *= 10
           call ldivhlde      ; indx /= 3
           ld   bc,16
           add  hl,bc         ; indx += 16
           ld   (indx),hl     ; update indx
           ex   de,hl         ; indx to de
           ld   hl,(len)      ; len to hl
           or   a
           sbc  hl,de         ; compare indx to len
           ex   de,hl         ; indx to hl
           jr   nc,ilelen     ; if len < indx then
           ld   hl,(len)      ;   indx <= len
ilelen:    ld   (indx),hl     ; update indx
           add  hl,hl         ; indx *= 2
           ld   de,array      ; array origin
           add  hl,de         ; array + 2 * i
           push hl
           pop  ix            ; to ix, array pointer
           ld   hl,0          ; clear res
           ld   (res),hl

rept1:     ld   hl,(res)      ; res to hl
           ld   de,(indx)     ; indx to de
           exx
           ld   hl,0          ; hl' <= de' <= 0
           ld   de,0          ;   low words only
           exx
           call lmulhlde16    ; hl':hl <= hl * de
           ex   de,hl         ; to de':de
           ld   l,(ix+0)      ; hl <= array[i]
           ld   h,(ix+1)
           exx
           ex   de,hl         ; to de':de
           ld   hl,0          ; hl' <= 0
           exx
           call lmulhl10      ; hl':hl *= 10
           call laddhlde      ; hl':hl += de':de
           push hl            ; save hl
           ld   hl,(indx)     ; indx to hl
           add  hl,hl         ; hl << 1
           dec  hl            ; hl -= 1
           ex   de,hl         ; to de
           pop  hl            ; restore hl
           exx
           ld   de,0          ; de' <= 0
           exx
           call ldivhlde      ; hl /= de
           ld   (res),hl      ; res <= quotient
           ld   (ix+0),e      ; array[i] <= remainder
           ld   (ix+1),d
           dec  ix            ; dec array pointer
           dec  ix
           ld   hl,(indx)     ; indx -= 1
           dec  hl
           ld   (indx),hl
           ld   a,h           ; check if indx != 0
           or   l
           jr   nz,rept1      ; continue if yes
           ret                ; done

;-------------------------------------------------------
; display each digit of pi, with grouping and new lines
;-------------------------------------------------------
outdig:    add  a,'0'         ; convert to ascii digit
           call putc          ; display char
           ld   a,(iy+dot$)   ; get dot if any
           ld   (iy+dot$),0   ; only once
           or   a             ; is there a dot ?
           call nz,putc       ; if yes, display it
           ld   hl,(count)    ; get counter
           inc  hl            ; increment it
           ld   (count),hl    ; save it
           dec  (iy+grpx$)    ; done with group of digits ?
           ret  nz            ; ret if yes
           ld   (iy+grpx$),5  ; reload digits counter
        ;  ld   a,' '         ; display ' '
        ;  call putc
           dec  (iy+grps$)    ; done with line of groups ?
           ret  nz            ; ret if yes
           ld   (iy+grps$),10 ; reload groups counter
           ld   hl,colsp
           call puts          ; display ': '
           ld   hl,(count)    ; get loop counter
           call puthl4        ; display it
           ld   hl,nl2sp      ; display nl + 2 spaces
           call puts
           call kbhit         ; quit if key pressed
           ret                ; done

;-------------------------------------------------------
; check for a keypress
; modifies register a
;-------------------------------------------------------
kbhit:     in   a,(uartstat)  ; get uart status
           and  rxempty       ; rx fifo empty?
           jp   z,cmdloop     ; exit if not empty
           ret                ; continue

;-------------------------------------------------------
; send a character to the uart
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
; send a string to the uart
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
; display hl in decimal
;-------------------------------------------------------
puthl4:    ld   de,1000
           call put1hl        ; display thousands
           ld   de,100
           call put1hl        ; display hundreds
           ld   de,10
           call put1hl        ; display tens
           ld   a,l
           jr   puthl1        ; display units
put1hl:    ld   a,0ffh        ; init counter
put1hl1:   inc  a             ; inc counter
           sbc  hl,de         ; try subtract
           jr   nc,put1hl1    ; loop while ok
           add  hl,de         ; revert subtract
puthl1:    add  a,'0'         ; adjust for ascii digit
           jr   putc          ; display it

;-------------------------------------------------------
; Display a in decimal
;-------------------------------------------------------
puta2:     ld   b,10
           call put1a         ; display tens
puta1:     add  a,'0'         ; adjust for ascii digit
           jr   putc          ; display units
put1a:     ld   c,0ffh        ; init counter
put1a1:    inc  c             ; inc counter
           sub  b             ; try subtract
           jr   nc,put1a1     ; loop while ok
           add  a,b           ; revert subtract
           ld   b,a           ; save
           ld   a,c           ; get digit
           call puta1         ; display it
           ld   a,b           ; restore
           ret                ; done

;-------------------------------------------------------
; Start Timer  (count-up mode)
; modifies register a
;-------------------------------------------------------
strttmr:   ld   a,0eh         ; 1 sec resolution
           out  (timecntl),a
           out  (timeicl),a   ; zero counter
           ld   a,0fh
           out  (timecntl),a  ; start
           ret

;-------------------------------------------------------
; Stop Timer  (count-up mode)
; modifies register a
;-------------------------------------------------------
stoptmr:   ld   a,0eh
           out  (timecntl),a  ; stop
           ret

;-------------------------------------------------------
; Read Timer  (count-up mode)
; timer must be stopped before reading
; hl gets the timer final count
; modifies register a
;-------------------------------------------------------
readtmr:   in   a,(timeicl)   ; read counter lo
           ld   l,a
           in   a,(timeich)   ; read counter hi
           ld   h,a
           call puthl4        ; display time
           ret

;-------------------------------------------------------
; x820 monitor entry point
;-------------------------------------------------------

cmdloop    equ  8        ; monitor warm start

;-------------------------------------------------------
; x820 register definitions
;-------------------------------------------------------

uartcntl   equ  00h       ; UART control register
uartstat   equ  01h       ; UART status  register
uartdata   equ  02h       ; UART data register
uarttest   equ  03h       ; UART test register

timecntl   equ  08h       ; timer control register
timeicl    equ  09h       ; initial count low
timeich    equ  0ah       ; initial count high

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

cr         equ 0dh        ; Carriage Return
lf         equ 0ah        ; Line Feed

;-------------------------------------------------------
; Dialog messages
;-------------------------------------------------------

startmsg:  db   cr,lf,'Z80 Pi Benchmark',cr,lf,cr,lf,0
donemsg    db   cr,lf,cr,lf,'Time = ',0
timemsg    db   ' seconds',cr,lf,0

nl2sp      db   cr,lf,'  ',0
colsp      db   ': ',0

iy0        equ  $             ; base value for iy

jndx$      equ $-iy0          ; main loop counter
jndx       ds   2
nines$     equ $-iy0          ; 9s counter
           ds   1
predg$     equ $-iy0          ; digit preceding 9s
           ds   1
dot$       equ $-iy0          ; decimal point
           ds   1
grpx$      equ $-iy0          ; digits in group counter
           ds   1
grps$      equ $-iy0          ; groups in line counter
           ds   1

ndig       ds   2             ; number of digits
indx       ds   2             ; sub loop counter
len        ds   2             ; array length
res        ds   2             ; quotient
count      ds   2             ; decimals counter

           ds   1 + low not $ ; goto next 256 byte boundary

array      equ $
arrend     equ 2*ndigits*10/3+array

           end
