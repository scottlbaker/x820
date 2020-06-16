
;=======================================================
; test0.asm - z80 basic instruction tests
;
; Derived from YAZE preliminary test
; Modified for the x820 project by: Scott L. Baker
;=======================================================

           org  100h

start:     ld   de,msg0       ; print test name
           ld   c,9
           call monbdos

           ld   a,1
           cp   2             ; test compare and
           jp   z,tsterr      ; z/nz conditional jump
           cp   1
           jp   nz,tsterr
           jp   lab0          ; test unconditional jump
           halt               ; should never get here

lab0:      call lab2          ; test call
lab1:      jp   tsterr        ; fail

lab2:      pop  hl            ; check return address
           ld   a,h
           cp   high lab1
           jp   z,lab3
           jp   tsterr
lab3:      ld   a,l
           cp   low lab1
           jp   z,lab4
           jp   tsterr

;-------------------------------------------------------
; test presence of all registers
;-------------------------------------------------------

lab4:      ld   sp,regs1
           pop  af
           pop  bc
           pop  de
           pop  hl
           ex   af,af'
           exx
           pop  af
           pop  bc
           pop  de
           pop  hl
           pop  ix
           pop  iy
           ld   sp,regs2+20
           push iy
           push ix
           push hl
           push de
           push bc
           push af
           ex   af,af'
           exx
           push hl
           push de
           push bc
           push af

;-------------------------------------------------------
; test access to memory via (hl)
;-------------------------------------------------------

           ld   hl,hlval
           ld   a,(hl)
           cp   0a5h
           jp   nz,tsterr
           ld   hl,hlval+1
           ld   a,(hl)
           cp   03ch
           jp   nz,tsterr

;-------------------------------------------------------
; test unconditional return
;-------------------------------------------------------

           ld   hl,reta
           push hl
           ret
           jp   tsterr

;-------------------------------------------------------
; test instructions needed for hex output
;-------------------------------------------------------

reta:      ld   a,255
           and  15
           cp   15
           jp   nz,tsterr
           ld   a,05ah
           and  15
           cp   00ah
           jp   nz,tsterr
           rrca
           cp   005h
           jp   nz,tsterr
           rrca
           cp   082h
           jp   nz,tsterr
           rrca
           cp   041h
           jp   nz,tsterr
           rrca
           cp   0a0h
           jp   nz,tsterr
           ld   hl,01234h
           push hl
           pop  bc
           ld   a,b
           cp   012h
           jp   nz,tsterr
           ld   a,c
           cp   034h
           jp   nz,tsterr

;-------------------------------------------------------
; test conditional call, ret, jp, jr
;-------------------------------------------------------

           ld   hl,4
           push hl
           pop  af
           call pe,lab1pe
           jp   tsterr
lab1pe:    pop  hl
           ld   hl,0d7h xor 4
           push hl
           pop  af
           call po,lab2pe
           jp   tsterr
lab2pe:    pop  hl
           ld   hl,lab3pe
           push hl
           ld   hl,4
           push hl
           pop  af
           ret  pe
           jp   tsterr
lab3pe:    ld   hl,lab4pe
           push hl
           ld   hl,0d7h xor 4
           push hl
           pop  af
           ret  po
           jp   tsterr
lab4pe:    ld   hl,4
           push hl
           pop  af
           jp   pe,lab5pe
           jp   tsterr
lab5pe:    ld   hl,0d7h xor 4
           push hl
           pop  af
           jp   po,lab6pe
           jp   tsterr
lab6pe:

;-------------------------------------------------------
; test conditional m,p call, ret, jp, jr
;-------------------------------------------------------

           ld   hl,080h
           push hl
           pop  af
           call m,lab1m
           jp   tsterr
lab1m:     pop  hl
           ld   hl,0d7h xor 080h
           push hl
           pop  af
           call p,lab2m
           jp   tsterr
lab2m:     pop  hl
           ld   hl,lab3m
           push hl
           ld   hl,080h
           push hl
           pop  af
           ret  m
           jp   tsterr
lab3m:     ld   hl,lab4m
           push hl
           ld   hl,0d7h xor 080h
           push hl
           pop  af
           ret  p
           jp   tsterr
lab4m:     ld   hl,080h
           push hl
           pop  af
           jp   m,lab5m
           jp   tsterr
lab5m:     ld   hl,0d7h xor 080h
           push hl
           pop  af
           jp   p,lab6m
           jp   tsterr
lab6m:

;-------------------------------------------------------
; test conditional z,nz call, ret, jp, jr
;-------------------------------------------------------

           ld   hl,040h
           push hl
           pop  af
           call z,lab1z
           jp   tsterr
lab1z:     pop  hl
           ld   hl,0d7h xor 040h
           push hl
           pop  af
           call nz,lab2z
           jp   tsterr
lab2z:     pop  hl
           ld   hl,lab3z
           push hl
           ld   hl,040h
           push hl
           pop  af
           ret  z
           jp   tsterr
lab3z:     ld   hl,lab4z
           push hl
           ld   hl,0d7h xor 040h
           push hl
           pop  af
           ret  nz
           jp   tsterr
lab4z:     ld   hl,040h
           push hl
           pop  af
           jp   z,lab5z
           jp   tsterr
lab5z:     ld   hl,0d7h xor 040h
           push hl
           pop  af
           jp   nz,lab6z
           jp   tsterr
lab6z:     ld   hl,040h
           push hl
           pop  af
           jr   z,lab7z
           jp   tsterr
lab7z:     ld   hl,0d7h xor 040h
           push hl
           pop  af
           jr   nz,lab8z
           jp   tsterr
lab8z:

;-------------------------------------------------------
; test conditional c,nc call, ret, jp, jr
;-------------------------------------------------------

           ld   hl,1
           push hl
           pop  af
           call c,lab1c
           jp   tsterr
lab1c:     pop  hl
           ld   hl,0d7h xor 1
           push hl
           pop  af
           call nc,lab2c
           jp   tsterr
lab2c:     pop  hl
           ld   hl,lab3c
           push hl
           ld   hl,1
           push hl
           pop  af
           ret  c
           jp   tsterr
lab3c:     ld   hl,lab4c
           push hl
           ld   hl,0d7h xor 1
           push hl
           pop  af
           ret  nc
           jp   tsterr
lab4c:     ld   hl,1
           push hl
           pop  af
           jp   c,lab5c
           jp   tsterr
lab5c:     ld   hl,0d7h xor 1
           push hl
           pop  af
           jp   nc,lab6c
           jp   tsterr
lab6c:     ld   hl,1
           push hl
           pop  af
           jr   c,lab7c
           jp   tsterr
lab7c:     ld   hl,0d7h xor 1
           push hl
           pop  af
           jr   nc,lab8c
           jp   tsterr
lab8c:

;-------------------------------------------------------
; test indirect jumps
;-------------------------------------------------------

           ld   hl,lab5
           jp   (hl)
           jp   tsterr
lab5:      ld   hl,lab6
           push hl
           pop  ix
           jp   (ix)
           jp   tsterr
lab6:      ld   hl,lab7
           push hl
           pop  iy
           jp   (iy)
           jp   tsterr

;-------------------------------------------------------
; djnz (and (partially) inc a, inc hl)
;-------------------------------------------------------

lab7:      ld   a,0a5h
           ld   b,4
lab8:      rrca
           djnz lab8
           cp   05ah
           jp   nz,tsterr
           ld   b,16
lab9:      inc  a
           djnz lab9
           cp   06ah
           jp   nz,tsterr
           ld   b,0
           ld   hl,0
lab10:     inc  hl
           djnz lab10
           ld   a,h
           cp   1
           jp   nz,tsterr
           ld   a,l
           cp   0
           jp   nz,tsterr

;-------------------------------------------------------
; relative addressing with ix
;-------------------------------------------------------

           ld   ix,hlval
           ld   a,(ix)
           cp   0a5h
           jp   nz,tsterr
           ld   a,(ix+1)
           cp   03ch
           jp   nz,tsterr
           inc  ix
           ld   a,(ix-1)
           cp   0a5h
           jp   nz,tsterr
           ld   ix,hlval-126
           ld   a,(ix+127)
           cp   03ch
           jp   nz,tsterr
           ld   ix,hlval+128
           ld   a,(ix-128)
           cp   0a5h
           jp   nz,tsterr

;-------------------------------------------------------
; relative addressing with iy
;-------------------------------------------------------

           ld   iy,hlval
           ld   a,(iy)
           cp   0a5h
           jp   nz,tsterr
           ld   a,(iy+1)
           cp   03ch
           jp   nz,tsterr
           inc  iy
           ld   a,(iy-1)
           cp   0a5h
           jp   nz,tsterr
           ld   iy,hlval-126
           ld   a,(iy+127)
           cp   03ch
           jp   nz,tsterr
           ld   iy,hlval+128
           ld   a,(iy-128)
           cp   0a5h
           jp   nz,tsterr

allok:     ld   de,msg1
           ld   c,9
           call monbdos
           ld   de,0xc001
           ld   hl,0xd00d
           jp   cmdloop       ; exit to monitor

tsterr:    ld   de,msg2
           ld   c,9
           call monbdos
           ld   de,0xdead
           ld   hl,0xbeef
           jp   cmdloop       ; exit to monitor


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

msg0       db   cr,lf,'Running Z80 test 0',cr,lf,'$'
msg1       db   'Test PASSED',cr,lf,'$'
msg2       db   'Test FAILED',cr,lf,'$'

;-------------------------------------------------------
; test data
;-------------------------------------------------------

regs1:     db   01h,02h,03h,04h,05h,06h,07h,08h,09h,0ah
           db   0bh,0ch,0dh,0eh,0fh,10h,11h,12h,13h,14h

regs2:     db   01h,02h,03h,04h,05h,06h,07h,08h,09h,0ah
           db   0bh,0ch,0dh,0eh,0fh,10h,11h,12h,13h,14h

hlval:     db   0a5h,03ch

           ; skip to the next page boundary
           org  (($+255)/256)*256

hextab:    db   '0123456789abcdef'
           ds   240

;-------------------------------------------------------
; reserved for stack
;-------------------------------------------------------

           ds   32
tos        dw   0             ; top of stack

           end
