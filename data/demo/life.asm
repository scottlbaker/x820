
;=======================================================
; The Game of Life
;
; A cellular automaton devised by British mathematician
; John Conway in 1970
;
; (c) Scott L. Baker     4/20/2020
;=======================================================

           org  100h

initlife:  call clrscr        ; clear the screen
           call initvars      ; initialize variables
           call initboard     ; initialize boards 1&2
           call maketab       ; create a lookup table

mainloop:  call showboard     ; display the main board
           call life          ; apply the rules of life
           call copyboard     ; copy board 2 to board 1
           call delay         ; wait a bit
           jp   mainloop      ; loop forever

;-------------------------------------------------------
; clear the screen
;-------------------------------------------------------
clrscr:    ld   hl,clrmsg
           call puts
           ret

;-------------------------------------------------------
; Initialize memory variables with zeros
;-------------------------------------------------------
initvars:  ld   hl,varstart
           ld   bc,lastvar-varstart
           ld   d,0
           call fillmem
           ret

;-------------------------------------------------------
; Initialize boards 1 and 2
;-------------------------------------------------------
initboard: ld   hl,brd1
           ld   bc,brdsiz2
           ld   d,chardead
           call fillmem
           ld   a,charalive
           call galaxy
           ret

;-------------------------------------------------------
; Create a row addresses lookup table
;-------------------------------------------------------
maketab:   ld   ix,rowtable
           ld   hl,0
           ld   de,bxw
           ld   b,bxh
maketb2:   ld   (ix),l
           inc  ix
           ld   (ix),h
           inc  ix
           add  hl,de
           djnz maketb2
           ret

;-------------------------------------------------------
; Fill memory range starting at (hl)
; with contents of d for bc locations
;-------------------------------------------------------
fillmem:   ld   (hl),d
           dec  bc
           ld   a,b
           or   c
           ret  z
           inc  hl
           jr   fillmem

;-------------------------------------------------------
; Display the contents of the board buffer 1
; only used for debug
; modifies register a,b,c, and hl
;-------------------------------------------------------
showbrd1:  ld   hl,brd1
           jr   showbrdx

;-------------------------------------------------------
; Display the contents of the board buffer 2
; only used for debug
; modifies register a,b,c, and hl
;-------------------------------------------------------
showbrd2:  ld   hl,brd2
           jr   showbrdx

;-------------------------------------------------------
; Display the contents of the board buffer 1
; with the generation and population count header
; modifies register a,b,c, and hl
;-------------------------------------------------------
showboard: call pgcounts
           ld   hl,brd1

;          fall into showbrdx

;-------------------------------------------------------
; Display the contents of a board buffer
; modifies register a,b,c, and hl
;-------------------------------------------------------
showbrdx:  ld   c,bxh
getnxtrow: ld   b,bxw
getnxtcel: ld   a,(hl)        ; get the character
           call putc          ; and print it
           inc  hl            ; move to next address
           dec  b             ; move to prev column
           jp   nz,getnxtcel  ; get next cell
           call crlf          ; print a linefeed
           dec  c             ; decrement the row
           jp   nz,getnxtrow  ; get next row
           ret

;-------------------------------------------------------
; Print generation and population counts
;-------------------------------------------------------
pgcounts:  ld   hl,genmsg
           call puts
           ld   de,(gencount)
           ld   hl,cnvbuf
           call bn2dec
           ld   hl,cnvbuf
           call puts
           ld   hl,popmsg
           call puts
           ld   de,(popcount)
           ld   hl,cnvbuf
           call bn2dec
           ld   hl,cnvbuf
           call puts
           call crlf
           ret

;-------------------------------------------------------
; Copy board 2 to board 1 then clear board 2
;-------------------------------------------------------
copyboard: ld   hl,brd2
           ld   de,brd1
           ld   bc,brdsize
           ldir

;          fall into clrboard2

;-------------------------------------------------------
; Clear board 2
;-------------------------------------------------------
clrboard2: ld   hl,brd2
           ld   bc,brdsize
           ld   d,chardead
           call fillmem
           ret

;-------------------------------------------------------
; Increment the generation count
;-------------------------------------------------------
incgen:    ld   de,(gencount)
           inc  de
           ld   (gencount),de
           ret

;-------------------------------------------------------
; Convert signed binary 16-bit number to decimal ascii
;-------------------------------------------------------
bn2dec:    xor  a
           ld   (cnvbuf + 0),a
           ld   (cnvbuf + 1),a
           ld   (cnvbuf + 2),a
           ld   (cnvbuf + 3),a
           ld   (cnvbuf + 4),a
           ld   (cnvbuf + 5),a
           ld   (cnvbuf + 6),a
           ld   (bufptr),hl
           ex   de,hl
           xor  a
           ld   (curlen),a
           ld   a,h
           ld   (ngflag),a
           or   a
           jp   p,cnvert
           ex   de,hl
           ld   hl,0
           or   a
           sbc  hl,de
cnvert:    ld   e,0
           ld   b,16
           or   a
dvloop:    rl   l
           rl   h
           rl   e
           ld   a,e
           sub  10
           ccf
           jr   nc,deccnt
           ld   e,a
deccnt:    djnz dvloop
           rl   l
           rl   h
chins:     ld   a,e
           add  a,'0'
           call insert
           ld   a,h
           or   l
           jr   nz,cnvert
exit:      ld   a,(ngflag)
           or   a
           ret  p
           ld   a,'-'
           call insert
           ret

insert:    push hl
           push af
           ld   hl,(bufptr)
           ld   d,h
           ld   e,l
           inc  de
           ld   (bufptr),de
           ld   a,(curlen)
           or   a
           jr   z,exitmr
           ld   c,a
           ld   b,0
           lddr
exitmr:    ld   a,(curlen)
           inc  a
           ld   (curlen),a
           ld   (hl),a
           ex   de,hl
           pop  af
           ld   (hl),a
           pop  hl
           ret

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
           ret

;-------------------------------------------------------
; Print a carriage return and linefeed
; modifies register a
;-------------------------------------------------------
crlf:      ld   a,cr
           call putc
           ld   a,lf
           jp   putc

;-------------------------------------------------------
; delay and check for keypress
; modifies register a
;-------------------------------------------------------
delay:     xor  a             ; zero
           out  (timeich),a   ; load timer high
           ld   a,5           ; number of ticks
           out  (timeicl),a   ; load timer low
           ld   a,05h         ; 100 msec resolution
           out  (timecntl),a  ; enable the timer
dlyloop:   call kbhit         ; exit if key pressed
           in   a,(timecntl)  ; get timer status
           and  tmrdone       ; check for timeout
           jr   z,dlyloop     ; wait for timeout
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
; apply the rules of life to all cells
; modifies a,b,c,de, and hl
;-------------------------------------------------------

life:      ld   hl,0
           ld   (popcount),hl
           ld   c,bxh-1
           ld   hl,brd1

nextrowa:  ld   b,bxw-1       ; b has col
           ld   a,c           ; c has row
           ld   (row),a
           dec  a
           ld   (r_above),a
           inc  a
           inc  a
           ld   (r_below),a

nextposa:  ld   a,b           ; b has col
           ld   (col),a
           dec  a
           ld   (c_left),a
           inc  a
           inc  a
           ld   (c_right),a

           call edgetest      ; check for wraparound
           call nbcount       ; count neighbors
           call chkrules      ; check life rules

           inc  hl            ; inc cell index
           dec  b             ; dec column count
           ld   a,b
           cp   $ff           ; check if column done
           jp   nz,nextposa   ; loop on this row

           dec  c             ; decrement row
           ld   a,c
           cp   $ff
           jp   nz,nextrowa   ; process next row

           call incgen        ; inc the gen count
           ret

;-------------------------------------------------------
; Edge tests to implement board wraparound
; modifies register a
;-------------------------------------------------------
edgetest:  ld   a,(row)
           cp   0
           jr   nz,edgetest1
           ld   a,bxh-1
           ld   (r_below),a
edgetest1: ld   a,(row)
           cp   bxh-1
           jr   nz,edgetest2
           xor  a
           ld   (r_above),a
edgetest2: ld   a,(col)
           cp   0
           jp   nz,edgetest3
           ld   a,bxw-1
           ld   (c_left),a
edgetest3: ld   a,(col)
           cp   bxw-1
           jp   nz,edge_exit
           xor  a
           ld   (c_right),a
edge_exit: ret

;-------------------------------------------------------
; count neighbors
; modifies register a
;-------------------------------------------------------
nbcount:   xor  a
           ld   (n_count),a   ; zero neighbor count
           push bc            ; save bc

           ld   a,(c_left)
           ld   b,a
           call nbcheck       ; check left

           ld   a,(c_right)
           ld   b,a
           call nbcheck       ; check right

           ld   a,(r_above)
           ld   c,a
           ld   a,(col)
           ld   b,a
           call nbcheck       ; check above

           ld   a,(c_left)
           ld   b,a
           call nbcheck       ; above left

           ld   a,(c_right)
           ld   b,a
           call nbcheck       ; above right

           ld   a,(r_below)
           ld   c,a
           ld   a,(col)
           ld   b,a
           call nbcheck       ; check below

           ld   a,(c_left)
           ld   b,a
           call nbcheck       ; below left

           ld   a,(c_right)
           ld   b,a
           call nbcheck       ; below right

           pop  bc            ; restore bc
           ret

;-------------------------------------------------------
; check for one neighbor
; modifies register a
;-------------------------------------------------------
nbcheck:   call getcell
           cp   charalive
           ret  nz

;          fall into incncnt

;-------------------------------------------------------
; inc neighbor count
; modifies register a
;-------------------------------------------------------
incncnt:   ld   a,(n_count)
           inc  a
           ld   (n_count),a
           ret

;-------------------------------------------------------
; print neighbor count
; only used for debug
;-------------------------------------------------------
prntncnt:  ld   a,(n_count)
           cp   0
           ret  z
           call prowcol       ; print row and col
           ld   a,(n_count)
           call put1hx        ; print 1 hex digit
           ld   a,' '
           jp   putc          ; print a space

;-------------------------------------------------------
; print row and column
; only used for debug
;-------------------------------------------------------
prowcol:   ld   a,c           ; c has row
           call put2hx        ; print 2 hex digits
           ld   a,' '
           call putc          ; print a space
           ld   a,b           ; b has col
           call put2hx        ; print 2 hex digits
           ld   a,' '
           jp   putc          ; print a space

;-------------------------------------------------------
; Print 2 hex digits
; only used for debug
; modifies register a
;-------------------------------------------------------
put2hx:    push af            ; save a
           rra
           rra
           rra
           rra
           call put1hx
           pop  af            ; restore a

;          fall into put1hx

;-------------------------------------------------------
; Print 1 hex digit
; only used for debug
; modifies register a
;-------------------------------------------------------
put1hx:    and  0fh
           add  a,90h
           daa
           adc  a,40h
           daa
           jp   putc

;-------------------------------------------------------
; check life rules
;
; A live cell with 2 or 3 live neighbors survives
; A dead cell with 3 live neighbors becomes live
; All other live cells die in the next generation
; All other dead cells stay dead
;
;-------------------------------------------------------
chkrules:  call getcell
           cp   chardead
           ld   a,(n_count)
           jp   z,chkrule2

chkrule1:  cp   2
           ; a live cell with 2 neighbors survives
           jp   z,markalive

chkrule2:  cp   3
           ; a live cell with 3 neighbors survives
           ; a dead cell with 3 neighbors revives
           jp   z,markalive
           ret

;-------------------------------------------------------
; Mark a cell as alive in board 2
; modifies register de
;-------------------------------------------------------
markalive: push hl
           call lookup
           ld   de,brd2       ; de has board address
           add  hl,de         ; hl has cell address
           ld   (hl),charalive
           call incrpop
;          call prntncnt      ; debug print count
           pop  hl
           ret

;-------------------------------------------------------
; increment the population
; modifies register de
;-------------------------------------------------------
incrpop:   ld   de,(popcount)
           inc  de
           ld   (popcount),de
           ret

;-------------------------------------------------------
; Get the contents of a cell in board 1
; the cell contents is returned in a
; modifies registers a,de, and hl
;-------------------------------------------------------
getcell:   push hl
           call lookup
           ld   de,brd1       ; de has board address
           add  hl,de         ; hl has cell address
           ld   a,(hl)        ; get the char
           pop  hl
           ret

;-------------------------------------------------------
; Lookup row and calculate cell address
; c has the row
; b has the column
; the cell index is returned in hl
; modifies registers a,de, and hl
;-------------------------------------------------------
lookup:    ld   h,0
           ld   l,c           ; c has row
           add  hl,hl         ; * 2
           ld   de,rowtable
           add  hl,de         ; hl has table index
           ld   a,(hl)
           ld   e,a
           inc  hl
           ld   a,(hl)
           ld   d,a
           ex   de,hl         ; hl has row address
           ld   d,0
           ld   e,b           ; de has col offset
           add  hl,de         ; hl has cell address
           ret

;-------------------------------------------------------
; Slider1 starting pattern
;-------------------------------------------------------
slider1:   ld   (brd1 + 323), a
           ld   (brd1 + 381), a
           ld   (brd1 + 382), a
           ld   (brd1 + 442), a
           ld   (brd1 + 443), a
           ret

;-------------------------------------------------------
; Slider2 starting pattern
;-------------------------------------------------------
slider2:   ld   (brd1 + 743), a
           ld   (brd1 + 801), a
           ld   (brd1 + 802), a
           ld   (brd1 + 862), a
           ld   (brd1 + 863), a
           ret

;-------------------------------------------------------
; Slider3 starting pattern
;-------------------------------------------------------
slider3:   ld   (brd1 + 341),a
           ld   (brd1 + 399),a
           ld   (brd1 + 400),a
           ld   (brd1 + 460),a
           ld   (brd1 + 461),a
           ret

;-------------------------------------------------------
; Slider4 starting pattern
;-------------------------------------------------------
slider4:   ld   (brd1 + 761),a
           ld   (brd1 + 819),a
           ld   (brd1 + 820),a
           ld   (brd1 + 880),a
           ld   (brd1 + 881),a
           ret

;-------------------------------------------------------
; Clover starting pattern
;-------------------------------------------------------
clover:    ld   (brd1 + 328), a
           ld   (brd1 + 329), a
           ld   (brd1 + 330), a
           ld   (brd1 + 332), a
           ld   (brd1 + 333), a
           ld   (brd1 + 334), a
           ld   (brd1 + 387), a
           ld   (brd1 + 391), a
           ld   (brd1 + 395), a
           ld   (brd1 + 447), a
           ld   (brd1 + 449), a
           ld   (brd1 + 453), a
           ld   (brd1 + 455), a
           ld   (brd1 + 508), a
           ld   (brd1 + 509), a
           ld   (brd1 + 511), a
           ld   (brd1 + 513), a
           ld   (brd1 + 514), a
           ld   (brd1 + 628), a
           ld   (brd1 + 629), a
           ld   (brd1 + 631), a
           ld   (brd1 + 633), a
           ld   (brd1 + 634), a
           ld   (brd1 + 687), a
           ld   (brd1 + 689), a
           ld   (brd1 + 693), a
           ld   (brd1 + 695), a
           ld   (brd1 + 747), a
           ld   (brd1 + 751), a
           ld   (brd1 + 755), a
           ld   (brd1 + 808), a
           ld   (brd1 + 809), a
           ld   (brd1 + 810), a
           ld   (brd1 + 812), a
           ld   (brd1 + 813), a
           ld   (brd1 + 814), a
           ret

;-------------------------------------------------------
; Koks Galaxy starting pattern
;-------------------------------------------------------
galaxy:    ld   (brd1 + 565),a
           ld   (brd1 + 566),a
           ld   (brd1 + 567),a
           ld   (brd1 + 568),a
           ld   (brd1 + 569),a
           ld   (brd1 + 570),a
           ld   (brd1 + 625),a
           ld   (brd1 + 626),a
           ld   (brd1 + 627),a
           ld   (brd1 + 626),a
           ld   (brd1 + 627),a
           ld   (brd1 + 628),a
           ld   (brd1 + 629),a
           ld   (brd1 + 630),a
           ld   (brd1 + 572),a
           ld   (brd1 + 573),a
           ld   (brd1 + 632),a
           ld   (brd1 + 633),a
           ld   (brd1 + 692),a
           ld   (brd1 + 693),a
           ld   (brd1 + 752),a
           ld   (brd1 + 753),a
           ld   (brd1 + 812),a
           ld   (brd1 + 813),a
           ld   (brd1 + 872),a
           ld   (brd1 + 873),a
           ld   (brd1 + 745),a
           ld   (brd1 + 746),a
           ld   (brd1 + 805),a
           ld   (brd1 + 806),a
           ld   (brd1 + 865),a
           ld   (brd1 + 866),a
           ld   (brd1 + 925),a
           ld   (brd1 + 926),a
           ld   (brd1 + 985),a
           ld   (brd1 + 986),a
           ld   (brd1 + 1045),a
           ld   (brd1 + 1046),a
           ld   (brd1 + 988),a
           ld   (brd1 + 989),a
           ld   (brd1 + 990),a
           ld   (brd1 + 991),a
           ld   (brd1 + 992),a
           ld   (brd1 + 993),a
           ld   (brd1 + 1048),a
           ld   (brd1 + 1049),a
           ld   (brd1 + 1050),a
           ld   (brd1 + 1051),a
           ld   (brd1 + 1052),a
           ld   (brd1 + 1053),a
           ret

;-------------------------------------------------------
; x820 monitor entry point
;-------------------------------------------------------

cmdloop    equ  8        ; monitor warm start

;-------------------------------------------------------
; x820 register definitions
;-------------------------------------------------------

uartcntl   equ 00h       ; UART control register
uartstat   equ 01h       ; UART status  register
uartdata   equ 02h       ; UART data register
uarttest   equ 03h       ; UART test register

timecntl   equ 08h       ; timer control register
timeicl    equ 09h       ; initial count low
timeich    equ 0ah       ; initial count high

;-------------------------------------------------------
; register bit definitions
;-------------------------------------------------------

rx_en      equ 02h       ; rx enable
tx_en      equ 01h       ; tx enable

txempty    equ 08h       ; tx fifo is empty
txfull     equ 04h       ; tx fifo is full
rxfull     equ 02h       ; rx fifo is full
rxempty    equ 01h       ; rx fifo is empty

tmrdone    equ 01h       ; timer done bit

;-------------------------------------------------------
; ascii character aliases
;-------------------------------------------------------

cr         equ 0dh       ; carriage return
lf         equ 0ah       ; line feed
esc        equ 1bh       ; escape

;-------------------------------------------------------
; board definitions
;-------------------------------------------------------

bxw        equ 60        ; width of board
bxh        equ 30        ; height of board
charalive  equ 'x'       ; denotes filled cell
chardead   equ '.'       ; denotes empty  cell

brdsize    equ bxw * bxh
brdsiz2    equ brdsize * 2
cnvbuflen  equ 8         ; for decimal conversion

;-------------------------------------------------------
; strings
;-------------------------------------------------------

clrmsg:    db   esc,'[2J'          ; clear screen
           db   esc,'[H',0         ; home cursor

genmsg:    db   esc,'[H'           ; home cursor
           db   cr,lf
           db   'generation: ',0

popmsg:    db   '    '
           db   'population: ',0

;-------------------------------------------------------
; variables located in ram
;-------------------------------------------------------

varstart   ds   1             ; must be declared first

gencount   ds   2             ; generation number
popcount   ds   2             ; current population

brd1       ds   brdsize       ; display board buffer
brd2       ds   brdsize       ; working board buffer
rowtable   ds   bxh*2         ; row address table

bufptr     ds   2             ; buffer pointer
curlen     ds   1             ; current string length
ngflag     ds   1             ; negative flag
cnvbuf     ds   cnvbuflen     ; for decimal conversion

r_above    ds   1             ; index of row above
r_below    ds   1             ; index of row below
c_left     ds   1             ; index of col left
c_right    ds   1             ; index of col right

row        ds   1             ; current row
col        ds   1             ; current column
n_count    ds   1             ; neighbor count

lastvar    db   '$$'          ; must be declared last

           end
