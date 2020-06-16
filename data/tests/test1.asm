
;=======================================================
; test1.asm :: z80 selftest
;
; (c) Scott L. Baker  2020
;=======================================================

           org  100h

           ld   de,initmsg    ; print init header
           ld   c,9
           call monbdos

;-------------------------------------------------------
; test presence of all registers
;-------------------------------------------------------

           ld   de,premsg     ; print test name
           ld   c,9
           call monbdos

           ld   sp,regs1
           pop  af
           pop  bc
           pop  de
           pop  hl
           pop  ix
           pop  iy
           ld   sp,regs3
           push iy
           push ix
           push hl
           push de
           push bc
           push af

           ld   sp,tos
           ld   b,12
           ld   de,regs1
           ld   hl,regs2
           call cmprx

;-------------------------------------------------------
;
; add a,a
; add a,b
; add a,c
; add a,d
; add a,e
; add a,h
; add a,l
;
; add a,n
; add a,(hl)
; add a,(ix+n)
; add a,(iy+n)
;
; add hl,bc
; add hl,de
; add hl,hl
; add hl,sp
;
;-------------------------------------------------------

           ld   de,addmsg     ; print test name
           ld   c,9
           call monbdos

           call initcrc       ; initialize crc
           call initvar       ; initialize variables

           xor  a
           ld   c,0ffh
add1:      add  a,a
           call updcrc        ; update crc
           inc  a
           dec  c
           jr   nz,add1

           xor  a
           ld   b,a
           ld   c,0ffh
add2:      add  a,b
           call updcrc        ; update crc
           inc  b
           dec  c
           jr   nz,add2

           xor  a
           ld   d,a
           cpl
           ld   c,0ffh
add4:      add  a,d
           call updcrc        ; update crc
           dec  d
           inc  a
           dec  c
           jr   nz,add4

           xor  a
           ld   e,a
           cpl
           ld   c,0ffh
add5:      add  a,e
           call updcrc        ; update crc
           inc  e
           dec  a
           dec  c
           jr   nz,add5

           xor  a
           ld   h,a
           cpl
           ld   c,0ffh
add6:      add  a,h
           call updcrc        ; update crc
           inc  h
           xor  a
           dec  c
           jr   nz,add6

           xor  a
           ld   c,0ffh
add8:      add  a,55h
           call updcrc        ; update crc
           inc  a
           dec  c
           jr   nz,add8

           ld   hl,dummy2
           xor  a
           ld   b,a
           ld   c,0ffh
add9:      ld   (hl),b
           add  a,(hl)
           call updcrc        ; update crc
           inc  a
           dec  b
           dec  c
           jr   nz,add9

           ld   ix,dummy1
           xor  a
           ld   b,a
           ld   c,0ffh
add10:     ld   (hl),b
           add  a,(ix+1)
           call updcrc        ; update crc
           inc  a
           dec  b
           dec  c
           jr   nz,add10

           ld   iy,dummy1
           xor  a
           ld   b,a
           ld   c,0ffh
add11:     ld   (hl),b
           add  a,(iy+1)
           call updcrc        ; update crc
           inc  a
           dec  b
           dec  c
           jr   nz,add11

           ld   hl,0
           ld   bc,0
add12:     add  hl,bc
           ld   a,h
           call updcrc        ; update upper crc
           ld   a,l
           call updcrc2       ; update lower crc
           inc  b
           inc  c
           jr   nz,add12

           ld   hl,addcrc     ; check !!
           call cmpcrc        ; -----

;-------------------------------------------------------
;
; adc a,a
; adc a,b
; adc a,c
; adc a,d
; adc a,e
; adc a,h
; adc a,l
;
; adc a,n
; adc a,(hl)
; adc a,(ix+n)
; adc a,(iy+n)
;
; adc hl,bc
; adc hl,de
; adc hl,hl
; adc hl,sp
;
;-------------------------------------------------------

           ld   de,adcmsg     ; print test name
           ld   c,9
           call monbdos

           call initcrc       ; initialize crc
           call initvar       ; initialize variables

           xor  a
           ld   c,0ffh
adc1:      adc  a,a
           call updcrc        ; update crc
           inc  a
           dec  c
           jr   nz,adc1

           xor  a
           ld   b,a
           ld   c,0ffh
adc2:      adc  a,b
           call updcrc        ; update crc
           inc  b
           dec  c
           jr   nz,adc2

           xor  a
           ld   d,a
           cpl
           ld   c,0ffh
adc4:      adc  a,d
           call updcrc        ; update crc
           dec  d
           inc  a
           dec  c
           jr   nz,adc4

           xor  a
           ld   e,a
           cpl
           ld   c,0ffh
adc5:      adc  a,e
           call updcrc        ; update crc
           inc  e
           dec  a
           dec  c
           jr   nz,adc5

           xor  a
           ld   h,a
           cpl
           ld   c,0ffh
adc6:      adc  a,h
           call updcrc        ; update crc
           inc  h
           xor  a
           dec  c
           jr   nz,adc6

           xor  a
           ld   c,0ffh
adc8:      adc  a,55h
           call updcrc        ; update crc
           inc  a
           dec  c
           jr   nz,adc8

           ld   hl,dummy2
           xor  a
           ld   b,a
           ld   c,0ffh
adc9:      ld   (hl),b
           adc  a,(hl)
           call updcrc        ; update crc
           inc  a
           dec  b
           dec  c
           jr   nz,adc9

           ld   ix,dummy1
           xor  a
           ld   b,a
           ld   c,0ffh
adc10:     ld   (hl),b
           adc  a,(ix+1)
           call updcrc        ; update crc
           inc  a
           dec  b
           dec  c
           jr   nz,adc10

           ld   iy,dummy1
           xor  a
           ld   b,a
           ld   c,0ffh
adc11:     ld   (hl),b
           adc  a,(iy+1)
           call updcrc        ; update crc
           inc  a
           dec  b
           dec  c
           jr   nz,adc11

           ld   hl,0
           ld   bc,0
adc12:     adc  hl,bc
           ld   a,h
           call updcrc        ; update upper crc
           ld   a,l
           call updcrc2       ; update lower crc
           inc  b
           inc  c
           jr   nz,adc12

           ld   hl,adccrc     ; check !!
           call cmpcrc        ; -----

;-------------------------------------------------------
;
; sub a
; sub b
; sub c
; sub d
; sub e
; sub h
; sub l
;
; sub n
; sub (hl)
; sub (ix+n)
; sub (iy+n)
;
; sub hl,bc
; sub hl,de
; sub hl,hl
; sub hl,sp
;
;-------------------------------------------------------

           ld   de,submsg     ; print test name
           ld   c,9
           call monbdos

           call initcrc       ; initialize crc
           call initvar       ; initialize variables

           xor  a
           ld   c,0ffh
sub1:      sub  a
           call updcrc        ; update crc
           inc  a
           dec  c
           jr   nz,sub1

           xor  a
           ld   b,a
           ld   c,0ffh
sub2:      sub  b
           call updcrc        ; update crc
           inc  b
           dec  c
           jr   nz,sub2

           xor  a
           ld   d,a
           cpl
           ld   c,0ffh
sub4:      sub  d
           call updcrc        ; update crc
           dec  d
           inc  a
           dec  c
           jr   nz,sub4

           xor  a
           ld   e,a
           cpl
           ld   c,0ffh
sub5:      sub  e
           call updcrc        ; update crc
           inc  e
           dec  a
           dec  c
           jr   nz,sub5

           xor  a
           ld   h,a
           cpl
           ld   c,0ffh
sub6:      sub  h
           call updcrc        ; update crc
           inc  h
           xor  a
           dec  c
           jr   nz,sub6

           xor  a
           ld   c,0ffh
sub8:      sub  55h
           call updcrc        ; update crc
           inc  a
           dec  c
           jr   nz,sub8

           ld   hl,dummy2
           xor  a
           ld   b,a
           ld   c,0ffh
sub9:      ld   (hl),b
           sub  (hl)
           call updcrc        ; update crc
           inc  a
           dec  b
           dec  c
           jr   nz,sub9

           ld   ix,dummy1
           xor  a
           ld   b,a
           ld   c,0ffh
sub10:     ld   (hl),b
           sub  (ix+1)
           call updcrc        ; update crc
           inc  a
           dec  b
           dec  c
           jr   nz,sub10

           ld   iy,dummy1
           xor  a
           ld   b,a
           ld   c,0ffh
sub11:     ld   (hl),b
           sub  (iy+1)
           call updcrc        ; update crc
           inc  a
           dec  b
           dec  c
           jr   nz,sub11

           ld   hl,subcrc     ; check !!
           call cmpcrc        ; -----

;-------------------------------------------------------
;
; sbc a,a
; sbc a,b
; sbc a,c
; sbc a,d
; sbc a,e
; sbc a,h
; sbc a,l
;
; sbc a,n
; sbc a,(hl)
; sbc a,(ix+n)
; sbc a,(iy+n)
;
; sbc hl,bc
; sbc hl,de
; sbc hl,hl
; sbc hl,sp
;
;=======================================================

           ld   de,sbcmsg     ; print test name
           ld   c,9
           call monbdos

           call initcrc       ; initialize crc
           call initvar       ; initialize variables

           xor  a
           ld   c,0ffh
sbc1:      sbc  a,a
           call updcrc        ; update crc
           inc  a
           dec  c
           jr   nz,sbc1

           xor  a
           ld   b,a
           ld   c,0ffh
sbc2:      sbc  a,b
           call updcrc        ; update crc
           inc  b
           dec  c
           jr   nz,sbc2

           xor  a
           ld   d,a
           cpl
           ld   c,0ffh
sbc4:      sbc  a,d
           call updcrc        ; update crc
           dec  d
           inc  a
           dec  c
           jr   nz,sbc4

           xor  a
           ld   e,a
           cpl
           ld   c,0ffh
sbc5:      sbc  a,e
           call updcrc        ; update crc
           inc  e
           dec  a
           dec  c
           jr   nz,sbc5

           xor  a
           ld   h,a
           cpl
           ld   c,0ffh
sbc6:      sbc  a,h
           call updcrc        ; update crc
           inc  h
           xor  a
           dec  c
           jr   nz,sbc6

           xor  a
           ld   c,0ffh
sbc8:      sbc  a,55h
           call updcrc        ; update crc
           inc  a
           dec  c
           jr   nz,sbc8

           ld   hl,dummy2
           xor  a
           ld   b,a
           ld   c,0ffh
sbc9:      ld   (hl),b
           sbc  a,(hl)
           call updcrc        ; update crc
           inc  a
           dec  b
           dec  c
           jr   nz,sbc9

           ld   ix,dummy1
           xor  a
           ld   b,a
           ld   c,0ffh
sbc10:     ld   (hl),b
           sbc  a,(ix+1)
           call updcrc        ; update crc
           inc  a
           dec  b
           dec  c
           jr   nz,sbc10

           ld   iy,dummy1
           xor  a
           ld   b,a
           ld   c,0ffh
sbc11:     ld   (hl),b
           sbc  a,(iy+1)
           call updcrc        ; update crc
           inc  a
           dec  b
           dec  c
           jr   nz,sbc11

           ld   hl,0
           ld   bc,0
sbc12:     sbc  hl,bc
           ld   a,h
           call updcrc        ; update upper crc
           ld   a,l
           call updcrc2       ; update lower crc
           inc  b
           inc  c
           jr   nz,sbc12

           ld   hl,sbccrc     ; check !!
           call cmpcrc        ; -----

;-------------------------------------------------------
;
;  and   a
;  and   1
;  and   (hl)
;  and   (ix+1)
;  and   (iy+1)
;
;  or    a
;  or    1
;  or    (hl)
;  or    (ix+1)
;  or    (iy+1)
;
;  xor   a
;  xor   1
;  xor   (hl)
;  xor   (ix+1)
;  xor   (iy+1)
;
;-------------------------------------------------------

           ld   de,logmsg     ; print test name
           ld   c,9
           call monbdos

           call initcrc       ; initialize crc
           call initvar       ; initialize variables

and1:      and  (hl)
           ld   a,(hl)
           call updcrc        ; update crc

           and  (ix+1)
           ld   a,(ix+1)
           call updcrc        ; update crc

           and  (iy+1)
           ld   a,(iy+1)
           call updcrc        ; update crc

           and  a
           call updcrc        ; update crc

           and  b
           ld   a,b
           call updcrc        ; update crc

           and  c
           ld   a,c
           call updcrc        ; update crc

           and  d
           ld   a,d
           call updcrc        ; update crc

           and  e
           ld   a,e
           call updcrc        ; update crc

           and  h
           ld   a,h
           call updcrc        ; update crc

           and  l
           ld   a,l
           call updcrc        ; update crc

or1:       or   (hl)
           ld   a,(hl)
           call updcrc        ; update crc

           or   (ix+1)
           ld   a,(ix+1)
           call updcrc        ; update crc

           or   (iy+1)
           ld   a,(iy+1)
           call updcrc        ; update crc

           or   a
           call updcrc        ; update crc

           or   b
           ld   a,b
           call updcrc        ; update crc

           or   c
           ld   a,c
           call updcrc        ; update crc

           or   d
           ld   a,d
           call updcrc        ; update crc

           or   e
           ld   a,e
           call updcrc        ; update crc

           or   h
           ld   a,h
           call updcrc        ; update crc

           or   l
           ld   a,l
           call updcrc        ; update crc

xor1:      xor  (hl)
           ld   a,(hl)
           call updcrc        ; update crc

           xor  (ix+1)
           ld   a,(ix+1)
           call updcrc        ; update crc

           xor  (iy+1)
           ld   a,(iy+1)
           call updcrc        ; update crc

           xor  a
           call updcrc        ; update crc

           xor  b
           ld   a,b
           call updcrc        ; update crc

           xor  c
           ld   a,c
           call updcrc        ; update crc

           xor  d
           ld   a,d
           call updcrc        ; update crc

           xor  e
           ld   a,e
           call updcrc        ; update crc

           xor  h
           ld   a,h
           call updcrc        ; update crc

           xor  l
           ld   a,l
           call updcrc        ; update crc

           ld   hl,logcrc     ; check !!
           call cmpcrc        ; -----

;-------------------------------------------------------
;
;  inc   a
;  inc   (hl)
;  inc   (ix+1)
;  inc   (iy+1)
;  inc   ix
;  inc   iy
;  inc   bc
;  inc   de
;  inc   hl
;  inc   sp
;
;-------------------------------------------------------

           ld   de,incmsg     ; print test name
           ld   c,9
           call monbdos

           call initcrc       ; initialize crc
           call initvar       ; initialize variables

inc1:      inc  (hl)
           ld   a,(hl)
           call updcrc        ; update crc

           inc  (ix+1)
           ld   a,(ix+1)
           call updcrc        ; update crc

           inc  (iy+1)
           ld   a,(iy+1)
           call updcrc        ; update crc

           inc  ix
           inc  (ix+1)
           ld   a,(ix+1)
           call updcrc        ; update crc

           inc  iy
           inc  (iy+1)
           ld   a,(iy+1)
           call updcrc        ; update crc

           inc  bc
           ld   a,b
           call updcrc        ; update crc
           ld   a,c
           call updcrc2       ; update crc

           inc  de
           ld   a,d
           call updcrc        ; update crc
           ld   a,e
           call updcrc2       ; update crc

           inc  hl
           ld   a,h
           call updcrc        ; update crc
           ld   a,l
           call updcrc2       ; update crc

           inc  sp
           ld   (dummy1),sp
           dec  sp            ; restore sp
           ld   a,(dummy1)
           call updcrc        ; update crc
           ld   a,(dummy2)
           call updcrc2       ; update crc

           inc  a
           call updcrc        ; update crc

           inc  b
           ld   a,b
           call updcrc        ; update crc

           inc  c
           ld   a,c
           call updcrc        ; update crc

           inc  d
           ld   a,d
           call updcrc        ; update crc

           inc  e
           ld   a,e
           call updcrc        ; update crc

           inc  h
           ld   a,h
           call updcrc        ; update crc

           inc  l
           ld   a,l
           call updcrc        ; update crc

           ld   hl,inccrc     ; check !!
           call cmpcrc        ; -----

;-------------------------------------------------------
;  dec   a
;  dec   (hl)
;  dec   (ix+1)
;  dec   (iy+1)
;  dec   ix
;  dec   iy
;  dec   bc
;  dec   de
;  dec   hl
;  dec   sp
;
;-------------------------------------------------------

           ld   de,decmsg     ; print test name
           ld   c,9
           call monbdos

           call initcrc       ; initialize crc
           call initvar       ; initialize variables

dec1:      dec  (hl)
           ld   a,(hl)
           call updcrc        ; update crc

           dec  (ix+1)
           ld   a,(ix+1)
           call updcrc        ; update crc

           dec  (iy+1)
           ld   a,(iy+1)
           call updcrc        ; update crc

           dec  ix
           dec  (ix+1)
           ld   a,(ix+1)
           call updcrc        ; update crc

           dec  iy
           dec  (iy+1)
           ld   a,(iy+1)
           call updcrc        ; update crc

           dec  bc
           ld   a,b
           call updcrc        ; update crc
           ld   a,c
           call updcrc2       ; update crc

           dec  de
           ld   a,d
           call updcrc        ; update crc
           ld   a,e
           call updcrc2       ; update crc

           dec  hl
           ld   a,h
           call updcrc        ; update crc
           ld   a,l
           call updcrc2       ; update crc

           dec  sp
           ld   (dummy1),sp
           inc  sp            ; restore sp
           ld   a,(dummy1)
           call updcrc        ; update crc
           ld   a,(dummy2)
           call updcrc2       ; update crc

           dec  a
           call updcrc        ; update crc

           dec  b
           ld   a,b
           call updcrc        ; update crc

           dec  c
           ld   a,c
           call updcrc        ; update crc

           dec  d
           ld   a,d
           call updcrc        ; update crc

           dec  e
           ld   a,e
           call updcrc        ; update crc

           dec  h
           ld   a,h
           call updcrc        ; update crc

           dec  l
           ld   a,l
           call updcrc        ; update crc

           ld   hl,deccrc     ; check !!
           call cmpcrc        ; -----

           jp   cmdloop       ; exit to monitor

;-------------------------------------------------------
; End of test code
;-------------------------------------------------------

allok:     ld   de,pasxmsg
           ld   c,9
           call monbdos
           ret

tsterr:    ld   de,errxmsg
           ld   c,9
           call monbdos
           ld   hl,crcval
           call phex8
           ld   de,crlfmsg
           ld   c,9
           call monbdos
           ret

;-------------------------------------------------------
; compare crc
;-------------------------------------------------------
cmpcrc:    ld   b,4
           ld   de,crcval

;-------------------------------------------------------
; compare data in memory
; hl points to value to compare
;-------------------------------------------------------
cmprx:     ld   a,(de)
           cp   (hl)
           jr   nz,tsterr     ; mismatch
           inc  hl
           inc  de
           dec  b
           jr   nz,cmprx
           jr   allok         ; match

;-------------------------------------------------------
; 32-bit crc routine (with z80 flags)
;-------------------------------------------------------
updcrc:    push af
           push bc
           push af
           pop  bc
           ld   a,c
           and  0d7h          ; mask f5,f3 flags
           call updcrc2       ; update flag crc
           pop  bc
           pop  af
           call updcrc2       ; update a reg crc
           ret

;-------------------------------------------------------
; 32-bit crc routine
; entry: a contains next byte
; exit:  crc updated
;-------------------------------------------------------
updcrc2:   push af
           push bc
           push de
           push hl
           ld   hl,crcval
           ld   de,3
           add  hl,de         ; low byte of old crc
           xor  (hl)          ; xor with new byte
           ld   l,a
           ld   h,0
           add  hl,hl         ; scale * 4
           add  hl,hl         ; table index
           ex   de,hl
           ld   hl,crctab
           add  hl,de
           ex   de,hl         ; de points to table entry
           ld   hl,crcval     ; hl points to crc
           ld   bc,4          ; c = count
crclp:     ld   a,(de)        ; get table entry
           ld   b,(hl)        ; get old crc
           xor  b             ; create new crc
           ld   (hl),a        ; store new crc
           inc  de            ; inc table pointer
           inc  hl            ; inc crc pointer
           dec  c             ; dec counter
           jr   nz,crclp
           pop  hl
           pop  de
           pop  bc
           pop  af
           ret

;-------------------------------------------------------
; initialize CRC
;-------------------------------------------------------
initcrc:   ld   hl,crcval
           ld   a,0ffh
           ld   b,4
icrclp:    ld   (hl),a
           inc  hl
           dec  b
           jr   nz,icrclp
           ret

;-------------------------------------------------------
; initialize dummy values and registers
;-------------------------------------------------------
initvar:   ld   hl,dummy1
           ld   a,0feh
           ld   c,017h
           ld   b,8
ivarlp:    ld   (hl),a        ; init dummy vars
           inc  hl
           sub  c
           dec  b
           jr   nz,ivarlp
           ld   bc,0          ; init registers
           ld   de,0
           push bc
           pop  af
           ld   hl,dummy4
           ld   ix,dummy4
           ld   iy,dummy4
           ret

;-------------------------------------------------------
; display the 32-bit value pointed to by hl
;-------------------------------------------------------
phex8:     push af
           push bc
           push hl
           ld   b,4
ph8lp:     ld   a,(hl)
           call phex2
           inc  hl
           dec  b
           jp   nz,ph8lp
           pop  hl
           pop  bc
           pop  af
           ret

;-------------------------------------------------------
; display byte in a
;-------------------------------------------------------
phex2:     push af
           rrca
           rrca
           rrca
           rrca
           call phex1
           pop  af

;-------------------------------------------------------
; display low nibble in a
;-------------------------------------------------------
phex1:     push af
           push bc
           push de
           push hl
           and  0fh
           cp   10
           jp   c,ph11
           add  a,'a'-'9'-1
ph11:      add  a,'0'
           ld   e,a
           ld   c,2
           call monbdos
           pop  hl
           pop  de
           pop  bc
           pop  af
           ret

;-------------------------------------------------------
; x820 monitor entry point
;-------------------------------------------------------

cmdloop         equ 8         ; monitor warm start
monbdos         equ 5         ; monitor bdos entry point

;-------------------------------------------------------
; ascii character aliases
;-------------------------------------------------------

cr              equ 0dh       ; carriage return
lf              equ 0ah       ; linefeed
esc             equ 1bh       ; escape

;-------------------------------------------------------
; strings
;-------------------------------------------------------

initmsg    db   cr,lf,'Running Z80 test 1'
           db   cr,lf,cr,lf,'$'

premsg     db   'PRE   test .. $'
addmsg     db   'ADD   test .. $'
adcmsg     db   'ADC   test .. $'
submsg     db   'SUB   test .. $'
sbcmsg     db   'SBC   test .. $'
logmsg     db   'LOGIC test .. $'
incmsg     db   'INC   test .. $'
decmsg     db   'DEC   test .. $'

pasxmsg    db   'PASSED',cr,lf,'$'
errxmsg    db   'FAILED  crc = $'
crlfmsg    db   cr,lf,'$'


           org  800h

;-------------------------------------------------------
; calculated crc
;-------------------------------------------------------

crcval     ds   4

;-------------------------------------------------------
; expected CRC values
;-------------------------------------------------------

addcrc     db   0dch,026h,098h,040h
adccrc     db   00fh,0f0h,06ch,0bbh
subcrc     db   0bch,096h,016h,095h
sbccrc     db   05bh,02eh,03bh,092h
logcrc     db   0b1h,0fbh,07ch,0abh
inccrc     db   06bh,09bh,0c4h,07bh
deccrc     db   0ach,04ch,06ch,0cfh

;-------------------------------------------------------
; variable storage
;-------------------------------------------------------

dummy1     db   0
dummy2     db   0
dummy3     db   0
dummy4     db   0
dummy5     db   0
dummy6     db   0
dummy7     db   0
dummy8     db   0

;-------------------------------------------------------
; test data
;-------------------------------------------------------

regs1:     db   01h,02h,03h,04h,05h,06h
           db   07h,08h,09h,0ah,0bh,0ch

regs2:     db   00h,00h,00h,00h,00h,00h
           db   00h,00h,00h,00h,00h,00h

regs3:     db   00h

;-------------------------------------------------------
; CRC lookup table
;-------------------------------------------------------
crctab:    db   000h,000h,000h,000h
           db   077h,007h,030h,096h
           db   0eeh,00eh,061h,02ch
           db   099h,009h,051h,0bah
           db   007h,06dh,0c4h,019h
           db   070h,06ah,0f4h,08fh
           db   0e9h,063h,0a5h,035h
           db   09eh,064h,095h,0a3h
           db   00eh,0dbh,088h,032h
           db   079h,0dch,0b8h,0a4h
           db   0e0h,0d5h,0e9h,01eh
           db   097h,0d2h,0d9h,088h
           db   009h,0b6h,04ch,02bh
           db   07eh,0b1h,07ch,0bdh
           db   0e7h,0b8h,02dh,007h
           db   090h,0bfh,01dh,091h
           db   01dh,0b7h,010h,064h
           db   06ah,0b0h,020h,0f2h
           db   0f3h,0b9h,071h,048h
           db   084h,0beh,041h,0deh
           db   01ah,0dah,0d4h,07dh
           db   06dh,0ddh,0e4h,0ebh
           db   0f4h,0d4h,0b5h,051h
           db   083h,0d3h,085h,0c7h
           db   013h,06ch,098h,056h
           db   064h,06bh,0a8h,0c0h
           db   0fdh,062h,0f9h,07ah
           db   08ah,065h,0c9h,0ech
           db   014h,001h,05ch,04fh
           db   063h,006h,06ch,0d9h
           db   0fah,00fh,03dh,063h
           db   08dh,008h,00dh,0f5h
           db   03bh,06eh,020h,0c8h
           db   04ch,069h,010h,05eh
           db   0d5h,060h,041h,0e4h
           db   0a2h,067h,071h,072h
           db   03ch,003h,0e4h,0d1h
           db   04bh,004h,0d4h,047h
           db   0d2h,00dh,085h,0fdh
           db   0a5h,00ah,0b5h,06bh
           db   035h,0b5h,0a8h,0fah
           db   042h,0b2h,098h,06ch
           db   0dbh,0bbh,0c9h,0d6h
           db   0ach,0bch,0f9h,040h
           db   032h,0d8h,06ch,0e3h
           db   045h,0dfh,05ch,075h
           db   0dch,0d6h,00dh,0cfh
           db   0abh,0d1h,03dh,059h
           db   026h,0d9h,030h,0ach
           db   051h,0deh,000h,03ah
           db   0c8h,0d7h,051h,080h
           db   0bfh,0d0h,061h,016h
           db   021h,0b4h,0f4h,0b5h
           db   056h,0b3h,0c4h,023h
           db   0cfh,0bah,095h,099h
           db   0b8h,0bdh,0a5h,00fh
           db   028h,002h,0b8h,09eh
           db   05fh,005h,088h,008h
           db   0c6h,00ch,0d9h,0b2h
           db   0b1h,00bh,0e9h,024h
           db   02fh,06fh,07ch,087h
           db   058h,068h,04ch,011h
           db   0c1h,061h,01dh,0abh
           db   0b6h,066h,02dh,03dh
           db   076h,0dch,041h,090h
           db   001h,0dbh,071h,006h
           db   098h,0d2h,020h,0bch
           db   0efh,0d5h,010h,02ah
           db   071h,0b1h,085h,089h
           db   006h,0b6h,0b5h,01fh
           db   09fh,0bfh,0e4h,0a5h
           db   0e8h,0b8h,0d4h,033h
           db   078h,007h,0c9h,0a2h
           db   00fh,000h,0f9h,034h
           db   096h,009h,0a8h,08eh
           db   0e1h,00eh,098h,018h
           db   07fh,06ah,00dh,0bbh
           db   008h,06dh,03dh,02dh
           db   091h,064h,06ch,097h
           db   0e6h,063h,05ch,001h
           db   06bh,06bh,051h,0f4h
           db   01ch,06ch,061h,062h
           db   085h,065h,030h,0d8h
           db   0f2h,062h,000h,04eh
           db   06ch,006h,095h,0edh
           db   01bh,001h,0a5h,07bh
           db   082h,008h,0f4h,0c1h
           db   0f5h,00fh,0c4h,057h
           db   065h,0b0h,0d9h,0c6h
           db   012h,0b7h,0e9h,050h
           db   08bh,0beh,0b8h,0eah
           db   0fch,0b9h,088h,07ch
           db   062h,0ddh,01dh,0dfh
           db   015h,0dah,02dh,049h
           db   08ch,0d3h,07ch,0f3h
           db   0fbh,0d4h,04ch,065h
           db   04dh,0b2h,061h,058h
           db   03ah,0b5h,051h,0ceh
           db   0a3h,0bch,000h,074h
           db   0d4h,0bbh,030h,0e2h
           db   04ah,0dfh,0a5h,041h
           db   03dh,0d8h,095h,0d7h
           db   0a4h,0d1h,0c4h,06dh
           db   0d3h,0d6h,0f4h,0fbh
           db   043h,069h,0e9h,06ah
           db   034h,06eh,0d9h,0fch
           db   0adh,067h,088h,046h
           db   0dah,060h,0b8h,0d0h
           db   044h,004h,02dh,073h
           db   033h,003h,01dh,0e5h
           db   0aah,00ah,04ch,05fh
           db   0ddh,00dh,07ch,0c9h
           db   050h,005h,071h,03ch
           db   027h,002h,041h,0aah
           db   0beh,00bh,010h,010h
           db   0c9h,00ch,020h,086h
           db   057h,068h,0b5h,025h
           db   020h,06fh,085h,0b3h
           db   0b9h,066h,0d4h,009h
           db   0ceh,061h,0e4h,09fh
           db   05eh,0deh,0f9h,00eh
           db   029h,0d9h,0c9h,098h
           db   0b0h,0d0h,098h,022h
           db   0c7h,0d7h,0a8h,0b4h
           db   059h,0b3h,03dh,017h
           db   02eh,0b4h,00dh,081h
           db   0b7h,0bdh,05ch,03bh
           db   0c0h,0bah,06ch,0adh
           db   0edh,0b8h,083h,020h
           db   09ah,0bfh,0b3h,0b6h
           db   003h,0b6h,0e2h,00ch
           db   074h,0b1h,0d2h,09ah
           db   0eah,0d5h,047h,039h
           db   09dh,0d2h,077h,0afh
           db   004h,0dbh,026h,015h
           db   073h,0dch,016h,083h
           db   0e3h,063h,00bh,012h
           db   094h,064h,03bh,084h
           db   00dh,06dh,06ah,03eh
           db   07ah,06ah,05ah,0a8h
           db   0e4h,00eh,0cfh,00bh
           db   093h,009h,0ffh,09dh
           db   00ah,000h,0aeh,027h
           db   07dh,007h,09eh,0b1h
           db   0f0h,00fh,093h,044h
           db   087h,008h,0a3h,0d2h
           db   01eh,001h,0f2h,068h
           db   069h,006h,0c2h,0feh
           db   0f7h,062h,057h,05dh
           db   080h,065h,067h,0cbh
           db   019h,06ch,036h,071h
           db   06eh,06bh,006h,0e7h
           db   0feh,0d4h,01bh,076h
           db   089h,0d3h,02bh,0e0h
           db   010h,0dah,07ah,05ah
           db   067h,0ddh,04ah,0cch
           db   0f9h,0b9h,0dfh,06fh
           db   08eh,0beh,0efh,0f9h
           db   017h,0b7h,0beh,043h
           db   060h,0b0h,08eh,0d5h
           db   0d6h,0d6h,0a3h,0e8h
           db   0a1h,0d1h,093h,07eh
           db   038h,0d8h,0c2h,0c4h
           db   04fh,0dfh,0f2h,052h
           db   0d1h,0bbh,067h,0f1h
           db   0a6h,0bch,057h,067h
           db   03fh,0b5h,006h,0ddh
           db   048h,0b2h,036h,04bh
           db   0d8h,00dh,02bh,0dah
           db   0afh,00ah,01bh,04ch
           db   036h,003h,04ah,0f6h
           db   041h,004h,07ah,060h
           db   0dfh,060h,0efh,0c3h
           db   0a8h,067h,0dfh,055h
           db   031h,06eh,08eh,0efh
           db   046h,069h,0beh,079h
           db   0cbh,061h,0b3h,08ch
           db   0bch,066h,083h,01ah
           db   025h,06fh,0d2h,0a0h
           db   052h,068h,0e2h,036h
           db   0cch,00ch,077h,095h
           db   0bbh,00bh,047h,003h
           db   022h,002h,016h,0b9h
           db   055h,005h,026h,02fh
           db   0c5h,0bah,03bh,0beh
           db   0b2h,0bdh,00bh,028h
           db   02bh,0b4h,05ah,092h
           db   05ch,0b3h,06ah,004h
           db   0c2h,0d7h,0ffh,0a7h
           db   0b5h,0d0h,0cfh,031h
           db   02ch,0d9h,09eh,08bh
           db   05bh,0deh,0aeh,01dh
           db   09bh,064h,0c2h,0b0h
           db   0ech,063h,0f2h,026h
           db   075h,06ah,0a3h,09ch
           db   002h,06dh,093h,00ah
           db   09ch,009h,006h,0a9h
           db   0ebh,00eh,036h,03fh
           db   072h,007h,067h,085h
           db   005h,000h,057h,013h
           db   095h,0bfh,04ah,082h
           db   0e2h,0b8h,07ah,014h
           db   07bh,0b1h,02bh,0aeh
           db   00ch,0b6h,01bh,038h
           db   092h,0d2h,08eh,09bh
           db   0e5h,0d5h,0beh,00dh
           db   07ch,0dch,0efh,0b7h
           db   00bh,0dbh,0dfh,021h
           db   086h,0d3h,0d2h,0d4h
           db   0f1h,0d4h,0e2h,042h
           db   068h,0ddh,0b3h,0f8h
           db   01fh,0dah,083h,06eh
           db   081h,0beh,016h,0cdh
           db   0f6h,0b9h,026h,05bh
           db   06fh,0b0h,077h,0e1h
           db   018h,0b7h,047h,077h
           db   088h,008h,05ah,0e6h
           db   0ffh,00fh,06ah,070h
           db   066h,006h,03bh,0cah
           db   011h,001h,00bh,05ch
           db   08fh,065h,09eh,0ffh
           db   0f8h,062h,0aeh,069h
           db   061h,06bh,0ffh,0d3h
           db   016h,06ch,0cfh,045h
           db   0a0h,00ah,0e2h,078h
           db   0d7h,00dh,0d2h,0eeh
           db   04eh,004h,083h,054h
           db   039h,003h,0b3h,0c2h
           db   0a7h,067h,026h,061h
           db   0d0h,060h,016h,0f7h
           db   049h,069h,047h,04dh
           db   03eh,06eh,077h,0dbh
           db   0aeh,0d1h,06ah,04ah
           db   0d9h,0d6h,05ah,0dch
           db   040h,0dfh,00bh,066h
           db   037h,0d8h,03bh,0f0h
           db   0a9h,0bch,0aeh,053h
           db   0deh,0bbh,09eh,0c5h
           db   047h,0b2h,0cfh,07fh
           db   030h,0b5h,0ffh,0e9h
           db   0bdh,0bdh,0f2h,01ch
           db   0cah,0bah,0c2h,08ah
           db   053h,0b3h,093h,030h
           db   024h,0b4h,0a3h,0a6h
           db   0bah,0d0h,036h,005h
           db   0cdh,0d7h,006h,093h
           db   054h,0deh,057h,029h
           db   023h,0d9h,067h,0bfh
           db   0b3h,066h,07ah,02eh
           db   0c4h,061h,04ah,0b8h
           db   05dh,068h,01bh,002h
           db   02ah,06fh,02bh,094h
           db   0b4h,00bh,0beh,037h
           db   0c3h,00ch,08eh,0a1h
           db   05ah,005h,0dfh,01bh
           db   02dh,002h,0efh,08dh

;-------------------------------------------------------
; reserved for stack
;-------------------------------------------------------
           ds   32
tos        dw   0             ; top of stack

           end
