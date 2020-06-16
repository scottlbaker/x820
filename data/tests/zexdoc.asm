
;=======================================================
; zexdoc.asm - Z80 instruction set exerciser
;
; Copyright (c) 1994  Frank D. Cringle
; Modified for the x820 project by: Scott L. Baker
;=======================================================
;
; For the purposes of this test program, the machine
; state consists of:
;
;       a 2 byte memory operand, followed by
;       the registers iy,ix,hl,de,bc,af,sp
;
; The program tests instructions by cycling through a
; sequence of machine states, executing the
; test instruction for each one and running a 32-bit crc
; over the resulting machine states. At the end of the
; sequence the crc is compared to an expected value that
; was found empirically on a real Z80.
;
; A test case is defined by a descriptor consisting of:
;
;       a flag mask byte,
;       the base case,
;       the incement vector,
;       the shift vector,
;       the expected crc,
;       a short descriptive message.
;
; The flag mask byte is used to prevent undefined flag
; bits from influencing the results. Documented flags
; are as per Mostek Z80 Technical Manual.
;
; The next three parts of the descriptor are 20 byte
; vectors corresponding to a 4 byte instruction and a
; 16 byte machine state. The first part is the base case
; which is the first test case of the sequence. This
; base is then modified according to the next 2 vectors.
; Each 1 bit in the increment vector specifies a bit to
; be cycled in the form of a binary counter. For instance
; if the byte corresponding to the accumulator is set
; to 0ffh in the increment vector, the test will be
; repeated for all 256 values of the accumulator. Note
; that 1 bits don't have to be contiguous. The number of
; test cases 'caused' by the increment vector is equal to
; 2^(number of 1 bits). The shift vector is similar,
; but specifies a set of bits in the test case that are
; to be successively inverted. Thus the shift vector
; causes a number of test cases equal to the number of
; 1 bits in it.
;
; The total number of test cases is the product of those
; caused by the counter and shift vectors and can easily
; become unweildy. Each individual test case can take a
; few milliseconds to execute, due to the overhead of
; test setup and crc calculation, so test design is a
; compromise between coverage and execution time.
;
;=======================================================
;
; This program is free software; you can redistribute
; it and/or modify it under the terms of the GNU
; General Public License as published by the Free
; Software Foundation; either version 2 of the License
; or (at your option) any later version.
;
; This program is distributed in the hope that it
; will be useful, but WITHOUT ANY WARRANTY; without
; even the implied warranty of MERCHANTABILITY or
; FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
; General Public License for more details.
;
; You should have received a copy of the GNU General
; Public License along with this program; if not
; write to the Free Software Foundation, Inc.
; 675 Mass Ave, Cambridge, MA 02139, USA.
;
;=======================================================

           org  100h

           jp   start

msbt:      ds   14            ; machine state
spbt:      ds    2            ; stack pointer

start:     ld   hl,(6)
           ld   sp,hl
           ld   de,msg1       ; print the
           ld   c,9           ; sign-on message
           call bdos

           ld   hl,tests      ; first test case
loop:      ld   a,(hl)
           inc  hl
           or   (hl)
           jp   z,done        ; end of list ?
           dec  hl
           call stt
           jp   loop

done:      ld   de,msg2       ; print the
           ld   c,9           ; completed message
           call bdos
           jp   cmdloop       ; back to monitor

tests:     dw   daa
           dw   cpl
           dw   scf
           dw   ccf
           dw   adc16
           dw   add16
           dw   add16x
           dw   add16y
           dw   alu8i
           dw   alu8r
           dw   alu8rx
           dw   alu8x
           dw   bitx
           dw   bitz80
           dw   cpd1
           dw   cpi1
           dw   inca
           dw   incb
           dw   incbc
           dw   incc
           dw   incd
           dw   incde
           dw   ince
           dw   inch
           dw   inchl
           dw   incix
           dw   inciy
           dw   incl
           dw   incm
           dw   incsp
           dw   incx
           dw   incxh
           dw   incxl
           dw   incyh
           dw   incyl
           dw   ld161
           dw   ld162
           dw   ld163
           dw   ld164
           dw   ld165
           dw   ld166
           dw   ld167
           dw   ld168
           dw   ld16im
           dw   ld16ix
           dw   ld8bd
           dw   ld8im
           dw   ld8imx
           dw   ld8ix1
           dw   ld8ix2
           dw   ld8ix3
           dw   ld8ixy
           dw   ld8rr
           dw   ld8rrx
           dw   lda
           dw   ldd1
           dw   ldd2
           dw   ldi1
           dw   ldi2
           dw   neg
           dw   rld
           dw   rot8080
           dw   rotxy
           dw   rotz80
           dw   srz80
           dw   srzx
           dw   st8ix1
           dw   st8ix2
           dw   st8ix3
           dw   stabd
           dw   0

;---------------------------------------------------------
; start of test descriptors
;---------------------------------------------------------

; <adc,sbc> hl,<bc,de,hl,sp> (38,912 cycles)
adc16:     db   0c7h          ; flag mask

           db   0edh,042h,0,0
           dw   0832ch,04f88h,0f22bh,0b339h,07e1fh,01563h
           db   0d3h
           db   089h
           dw   0465eh

           db   0,038h,0,0
           dw   0,0,0,0f821h,0,0
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   0,0,0,-1,-1,-1
           db   0d7h
           db   0
           dw   -1

           db   0f8h,0b4h,0eah,0a9h; expected crc
           db   '<adc,sbc> hl,<bc,de,hl,sp>'
           db   '....$'

; add hl,<bc,de,hl,sp> (19,456 cycles)
add16:     db   0c7h          ; flag mask

           db   09h,0,0,0
           dw   0c4a5h,0c4c7h,0d226h,0a050h,058eah,08566h
           db   0c6h
           db   0deh
           dw   09bc9h

           db   030h,0,0,0
           dw   0,0,0,0f821h,0,0
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   0,0,0,-1,-1,-1
           db   0d7h
           db   0
           dw   -1

           db   089h,0fdh,0b6h,035h; expected crc
           db   'add hl,<bc,de,hl,sp>'
           db   '..........$'

; add ix,<bc,de,ix,sp> (19,456 cycles)
add16x:    db   0c7h          ; flag mask

           db   0ddh,09h,0,0
           dw   0ddach,0c294h,0635bh,033d3h,06a76h,0fa20h
           db   094h
           db   068h
           dw   036f5h

           db   0,030h,0,0
           dw   0,0,0f821h,0,0,0
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   0,0,-1,0,-1,-1
           db   0d7h
           db   0
           dw   -1

           db   0c1h,033h,079h,00bh; expected crc
           db   'add ix,<bc,de,ix,sp>'
           db   '..........$'

; add iy,<bc,de,iy,sp> (19,456 cycles)
add16y:    db   0c7h          ; flag mask

           db   0fdh,09h,0,0
           dw   0c7c2h,0f407h,051c1h,03e96h,00bf4h,0510fh
           db   092h
           db   01eh
           dw   071eah

           db   0,030h,0,0
           dw   0,0f821h,0,0,0,0
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   0,-1,0,0,-1,-1
           db   0d7h
           db   0
           dw   -1

           db   0e8h,081h,07bh,09eh; expected crc
           db   'add iy,<bc,de,iy,sp>'
           db   '..........$'

; aluop a,nn (28,672 cycles)
alu8i:     db   0d7h          ; flag mask

           db   0c6h,0,0,0
           dw   09140h,07e3ch,07a67h,0df6dh,05b61h,00b29h
           db   010h
           db   066h
           dw   085b2h

           db   038h,0,0,0
           dw   0,0,0,0,0,0
           db   0
           db   -1
           dw   0

           db   0,-1,0,0
           dw   0,0,0,0,0,0
           db   0d7h
           db   0
           dw   0

           db   048h,079h,093h,060h; expected crc
           db   'aluop a,nn'
           db   '....................$'

; aluop a,<b,c,d,e,h,l,(hl),a> (753,664 cycles)
alu8r:     db   0d7h          ; flag mask

           db   080h,0,0,0
           dw   0c53eh,0573ah,04c4dh,msbt,0e309h,0a666h
           db   0d0h
           db   03bh
           dw   0adbbh

           db   03fh,0,0,0
           dw   0,0,0,0,0,0
           db   0
           db   -1
           dw   0

           db   0,0,0,0
           dw   0ffh,0,0,0,-1,-1
           db   0d7h
           db   0
           dw   0

           db   0feh,043h,0b0h,016h; expected crc
           db   'aluop a,<b,c,d,e,h,l,(hl),a>'
           db   '..$'

; aluop a,<ixh,ixl,iyh,iyl> (376,832 cycles)
alu8rx:    db   0d7h          ; flag mask

           db   0ddh,084h,0,0
           dw   0d6f7h,0c76eh,0accfh,02847h,022ddh,0c035h
           db   0c5h
           db   038h
           dw   0234bh

           db   020h,039h,0,0
           dw   0,0,0,0,0,0
           db   0
           db   -1
           dw   0

           db   0,0,0,0
           dw   0ffh,0,0,0,-1,-1
           db   0d7h
           db   0
           dw   0

           db   0a4h,002h,06dh,05ah; expected crc
           db   'aluop a,<ixh,ixl,iyh,iyl>'
           db   '.....$'

; aluop a,(<ix,iy>+1) (229,376 cycles)
alu8x:     db   0d7h          ; flag mask

           db   0ddh,086h,1,0
           dw   090b7h,msbt-1,msbt-1,032fdh,0406eh,0c1dch
           db   045h
           db   06eh
           dw   0e5fah

           db   020h,038h,0,0
           dw   0,1,1,0,0,0
           db   0
           db   -1
           dw   0

           db   0,0,0,0
           dw   0ffh,0,0,0,0,0
           db   0d7h
           db   0
           dw   0

           db   0e8h,049h,067h,06eh; expected crc
           db   'aluop a,(<ix,iy>+1)'
           db   '...........$'

; bit n,(<ix,iy>+1) (2048 cycles)
bitx:      db   053h          ; flag mask

           db   0ddh,0cbh,1,046h
           dw   02075h,msbt-1,msbt-1,03cfch,0a79ah,03d74h
           db   051h
           db   027h
           dw   0ca14h

           db   020h,0,0,038h
           dw   0,0,0,0,0,0
           db   053h
           db   0
           dw   0

           db   0,0,0,0
           dw   0ffh,0,0,0,0,0
           db   0
           db   0
           dw   0

           db   0a8h,0eeh,008h,067h; expected crc
           db   'bit n,(<ix,iy>+1)'
           db   '.............$'

; bit n,<b,c,d,e,h,l,(hl),a> (49,152 cycles)
bitz80:    db   053h          ; flag mask

           db   0cbh,040h,0,0
           dw   03ef1h,09dfch,07acch,msbt,0be61h,07a86h
           db   050h
           db   024h
           dw   01998h

           db   0,03fh,0,0
           dw   0,0,0,0,0,0
           db   053h
           db   0
           dw   0

           db   0,0,0,0
           dw   0ffh,0,0,0,-1,-1
           db   0
           db   -1
           dw   0

           db   07bh,055h,0e6h,0c8h; expected crc
           db   'bit n,<b,c,d,e,h,l,(hl),a>'
           db   '....$'

; cpd<r> (1) (6144 cycles)
cpd1:      db   0d7h          ; flag mask

           db   0edh,0a9h,0,0
           dw   0c7b6h,072b4h,018f6h,msbt+17,08dbdh,1
           db   0c0h
           db   030h
           dw   094a3h

           db   0,010h,0,0
           dw   0,0,0,0,0,010
           db   0
           db   -1
           dw   0

           db   0,0,0,0
           dw   0,0,0,0,0,0
           db   0d7h
           db   0
           dw   0

           db   0a8h,07eh,06ch,0fah; expected crc
           db   'cpd<r>'
           db   '........................$'

; cpi<r> (1) (6144 cycles)
cpi1:      db   0d7h          ; flag mask

           db   0edh,0a1h,0,0
           dw   04d48h,0af4ah,0906bh,msbt,04e71h,1
           db   093h
           db   06ah
           dw   0907ch

           db   0,010h,0,0
           dw   0,0,0,0,0,010
           db   0
           db   -1
           dw   0

           db   0,0,0,0
           dw   0,0,0,0,0,0
           db   0d7h
           db   0
           dw   0

           db   006h,0deh,0b3h,056h; expected crc
           db   'cpi<r>'
           db   '........................$'

; <daa>
daa:       db   0d7h          ; flag mask

           db   027h,0,0,0
           dw   02141h,009fah,01d60h,0a559h,08d5bh,09079h
           db   004h
           db   08eh
           dw   0299dh

           db   0,0,0,0
           dw   0,0,0,0,0,0
           db   0d7h
           db   -1
           dw   0

           db   0,0,0,0
           dw   0,0,0,0,0,0
           db   0
           db   0
           dw   0

           db   0a4h,061h,015h,058h; expected crc
           db   '<daa>'
           db   '.........................$'

; <cpl>
cpl:       db   0d7h          ; flag mask

           db   02fh,0,0,0
           dw   02141h,009fah,01d60h,0a559h,08d5bh,09079h
           db   004h
           db   08eh
           dw   0299dh

           db   0,0,0,0
           dw   0,0,0,0,0,0
           db   0d7h
           db   -1
           dw   0

           db   0,0,0,0
           dw   0,0,0,0,0,0
           db   0
           db   0
           dw   0

           db   0a2h,021h,05ah,002h; expected crc
           db   '<cpl>'
           db   '.........................$'

; <scf>
scf:       db   0d7h          ; flag mask

           db   037h,0,0,0
           dw   02141h,009fah,01d60h,0a559h,08d5bh,09079h
           db   004h
           db   08eh
           dw   0299dh

           db   0,0,0,0
           dw   0,0,0,0,0,0
           db   0d7h
           db   -1
           dw   0

           db   0,0,0,0
           dw   0,0,0,0,0,0
           db   0
           db   0
           dw   0

           db   001h,0dfh,0b7h,07ch; expected crc
           db   '<scf>'
           db   '.........................$'

; <ccf>
ccf:       db   0d7h          ; flag mask

           db   03fh,0,0,0
           dw   02141h,009fah,01d60h,0a559h,08d5bh,09079h
           db   004h
           db   08eh
           dw   0299dh

           db   0,0,0,0
           dw   0,0,0,0,0,0
           db   0d7h
           db   -1
           dw   0

           db   0,0,0,0
           dw   0,0,0,0,0,0
           db   0
           db   0
           dw   0

           db   008h,0d2h,00fh,0e0h; expected crc
           db   '<ccf>'
           db   '.........................$'

; <inc,dec> a (3072 cycles)
inca:      db   0d7h          ; flag mask

           db   03ch,0,0,0
           dw   04adfh,0d5d8h,0e598h,08a2bh,0a7b0h,0431bh
           db   044h
           db   05ah
           dw   0d030h

           db   1,0,0,0
           dw   0,0,0,0,0,0
           db   0
           db   -1
           dw   0

           db   0,0,0,0
           dw   0,0,0,0,0,0
           db   0d7h
           db   0
           dw   0

           db   0d1h,088h,015h,0a4h; expected crc
           db   '<inc,dec> a'
           db   '...................$'

; <inc,dec> b (3072 cycles)
incb:      db   0d7h          ; flag mask

           db   04h,0,0,0
           dw   0d623h,0432dh,07a61h,08180h,05a86h,01e85h
           db   086h
           db   058h
           dw   09bbbh

           db   1,0,0,0
           dw   0,0,0,0,0,0ff00h
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   0,0,0,0,0,0
           db   0d7h
           db   0
           dw   0

           db   05fh,068h,022h,064h; expected crc
           db   '<inc,dec> b'
           db   '...................$'

; <inc,dec> bc (1536 cycles)
incbc:     db   0d7h          ; flag mask

           db   03h,0,0,0
           dw   0cd97h,044abh,08dc9h,0e3e3h,011cch,0e8a4h
           db   002h
           db   049h
           dw   02a4dh

           db   08h,0,0,0
           dw   0,0,0,0,0,0f821h
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   0,0,0,0,0,0
           db   0d7h
           db   0
           dw   0

           db   0d2h,0aeh,03bh,0ech; expected crc
           db   '<inc,dec> bc'
           db   '..................$'

; <inc,dec> c (3072 cycles)
incc:      db   0d7h          ; flag mask

           db   0ch,0,0,0
           dw   0d789h,00935h,0055bh,09f85h,08b27h,0d208h
           db   095h
           db   005h
           dw   00660h

           db   1,0,0,0
           dw   0,0,0,0,0,0ffh
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   0,0,0,0,0,0
           db   0d7h
           db   0
           dw   0

           db   0c2h,084h,055h,04ch; expected crc
           db   '<inc,dec> c'
           db   '...................$'

; <inc,dec> d (3072 cycles)
incd:      db   0d7h          ; flag mask

           db   014h,0,0,0
           dw   0a0eah,05fbah,065fbh,0981ch,038cch,0debch
           db   043h
           db   05ch
           dw   003bdh

           db   1,0,0,0
           dw   0,0,0,0,0ff00h,0
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   0,0,0,0,0,0
           db   0d7h
           db   0
           dw   0

           db   045h,023h,0deh,010h; expected crc
           db   '<inc,dec> d'
           db   '...................$'

; <inc,dec> de (1536 cycles)
incde:     db   0d7h          ; flag mask

           db   013h,0,0,0
           dw   0342eh,0131dh,028c9h,00acah,09967h,03a2eh
           db   092h
           db   0f6h
           dw   09d54h

           db   08h,0,0,0
           dw   0,0,0,0,0f821h,0
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   0,0,0,0,0,0
           db   0d7h
           db   0
           dw   0

           db   0aeh,0c6h,0d4h,02ch; expected crc
           db   '<inc,dec> de'
           db   '..................$'

; <inc,dec> e (3072 cycles)
ince:      db   0d7h          ; flag mask

           db   01ch,0,0,0
           dw   0602fh,04c0dh,02402h,0e2f5h,0a0f4h,0a10ah
           db   013h
           db   032h
           dw   05925h

           db   1,0,0,0
           dw   0,0,0,0,0ffh,0
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   0,0,0,0,0,0
           db   0d7h
           db   0
           dw   0

           db   0e1h,075h,0afh,0cch; expected crc
           db   '<inc,dec> e'
           db   '...................$'

; <inc,dec> h (3072 cycles)
inch:      db   0d7h          ; flag mask

           db   024h,0,0,0
           dw   01506h,0f2ebh,0e8ddh,0262bh,011a6h,0bc1ah
           db   017h
           db   006h
           dw   02818h

           db   1,0,0,0
           dw   0,0,0,0ff00h,0,0
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   0,0,0,0,0,0
           db   0d7h
           db   0
           dw   0

           db   01ch,0edh,084h,07dh; expected crc
           db   '<inc,dec> h'
           db   '...................$'

; <inc,dec> hl (1536 cycles)
inchl:     db   0d7h          ; flag mask

           db   023h,0,0,0
           dw   0c3f4h,007a5h,01b6dh,04f04h,0e2c2h,0822ah
           db   057h
           db   0e0h
           dw   0c3e1h

           db   08h,0,0,0
           dw   0,0,0,0f821h,0,0
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   0,0,0,0,0,0
           db   0d7h
           db   0
           dw   0

           db   0fch,00dh,06dh,04ah; expected crc
           db   '<inc,dec> hl'
           db   '..................$'

; <inc,dec> ix (1536 cycles)
incix:     db   0d7h          ; flag mask

           db   0ddh,023h,0,0
           dw   0bc3ch,00d9bh,0e081h,0adfdh,09a7fh,096e5h
           db   013h
           db   085h
           dw   00be2h

           db   0,08h,0,0
           dw   0,0,0f821h,0,0,0
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   0,0,0,0,0,0
           db   0d7h
           db   0
           dw   0

           db   0a5h,04dh,0beh,031h; expected crc
           db   '<inc,dec> ix'
           db   '..................$'

; <inc,dec> iy (1536 cycles)
inciy:     db   0d7h          ; flag mask

           db   0fdh,023h,0,0
           dw   09402h,0637ah,03182h,0c65ah,0b2e9h,0abb4h
           db   016h
           db   0f2h
           dw   06d05h

           db   0,08h,0,0
           dw   0,0f821h,0,0,0,0
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   0,0,0,0,0,0
           db   0d7h
           db   0
           dw   0

           db   050h,05dh,051h,0a3h; expected crc
           db   '<inc,dec> iy'
           db   '..................$'

; <inc,dec> l (3072 cycles)
incl:      db   0d7h          ; flag mask

           db   02ch,0,0,0
           dw   08031h,0a520h,04356h,0b409h,0f4c1h,0dfa2h
           db   0d1h
           db   03ch
           dw   03ea2h

           db   1,0,0,0
           dw   0,0,0,0ffh,0,0
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   0,0,0,0,0,0
           db   0d7h
           db   0
           dw   0

           db   056h,0cdh,006h,0f3h; expected crc
           db   '<inc,dec> l'
           db   '...................$'

; <inc,dec> (hl) (3072 cycles)
incm:      db   0d7h          ; flag mask

           db   034h,0,0,0
           dw   0b856h,00c7ch,0e53eh,msbt,0877eh,0da58h
           db   015h
           db   05ch
           dw   01f37h

           db   1,0,0,0
           dw   0ffh,0,0,0,0,0
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   0,0,0,0,0,0
           db   0d7h
           db   0
           dw   0

           db   0b8h,03ah,0dch,0efh; expected crc
           db   '<inc,dec> (hl)'
           db   '................$'

; <inc,dec> sp (1536 cycles)
incsp:     db   0d7h          ; flag mask

           db   033h,0,0,0
           dw   0346fh,0d482h,0d169h,0deb6h,0a494h,0f476h
           db   053h
           db   002h
           dw   0855bh

           db   08h,0,0,0
           dw   0,0,0,0,0,0
           db   0
           db   0
           dw   0f821h

           db   0,0,0,0
           dw   0,0,0,0,0,0
           db   0d7h
           db   0
           dw   0

           db   05dh,0ach,0d5h,027h; expected crc
           db   '<inc,dec> sp'
           db   '..................$'

; <inc,dec> (<ix,iy>+1) (6144 cycles)
incx:      db   0d7h          ; flag mask

           db   0ddh,034h,1,0
           dw   0fa6eh,msbt-1,msbt-1,02c28h,08894h,05057h
           db   016h
           db   033h
           dw   0286fh

           db   020h,1,0,0
           dw   0ffh,0,0,0,0,0
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   0,0,0,0,0,0
           db   0d7h
           db   0
           dw   0

           db   020h,058h,014h,070h; expected crc
           db   '<inc,dec> (<ix,iy>+1)'
           db   '.........$'

; <inc,dec> ixh (3072 cycles)
incxh:     db   0d7h          ; flag mask

           db   0ddh,024h,0,0
           dw   0b838h,0316ch,0c6d4h,03e01h,08358h,015b4h
           db   081h
           db   0deh
           dw   04259h

           db   0,1,0,0
           dw   0,0ff00h,0,0,0,0
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   0,0,0,0,0,0
           db   0d7h
           db   0
           dw   0

           db   06fh,046h,036h,062h; expected crc
           db   '<inc,dec> ixh'
           db   '.................$'

; <inc,dec> ixl (3072 cycles)
incxl:     db   0d7h          ; flag mask

           db   0ddh,02ch,0,0
           dw   04d14h,07460h,076d4h,006e7h,032a2h,0213ch
           db   0d6h
           db   0d7h
           dw   099a5h

           db   0,1,0,0
           dw   0,0ffh,0,0,0,0
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   0,0,0,0,0,0
           db   0d7h
           db   0
           dw   0

           db   002h,07bh,0efh,02ch; expected crc
           db   '<inc,dec> ixl'
           db   '.................$'

; <inc,dec> iyh (3072 cycles)
incyh:     db   0d7h          ; flag mask

           db   0ddh,024h,0,0
           dw   02836h,09f6fh,09116h,061b9h,082cbh,0e219h
           db   092h
           db   073h
           dw   0a98ch

           db   0,1,0,0
           dw   0ff00h,0,0,0,0,0
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   0,0,0,0,0,0
           db   0d7h
           db   0
           dw   0

           db   02dh,096h,06ch,0f3h; expected crc
           db   '<inc,dec> iyh'
           db   '.................$'

; <inc,dec> iyl (3072 cycles)
incyl:     db   0d7h          ; flag mask

           db   0ddh,02ch,0,0
           dw   0d7c6h,062d5h,0a09eh,07039h,03e7eh,09f12h
           db   090h
           db   0d9h
           dw   0220fh

           db   0,1,0,0
           dw   0ffh,0,0,0,0,0
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   0,0,0,0,0,0
           db   0d7h
           db   0
           dw   0

           db   0fbh,0cbh,0bah,095h; expected crc
           db   '<inc,dec> iyl'
           db   '.................$'

; ld <bc,de>,(nnnn) (32 cycles)
ld161:     db   0d7h          ; flag mask

           db   0edh,04bh,low msbt,high msbt
           dw   0f9a8h,0f559h,093a4h,0f5edh,06f96h,0d968h
           db   086h
           db   0e6h
           dw   04bd8h

           db   0,010h,0,0
           dw   0,0,0,0,0,0
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   -1,0,0,0,0,0
           db   0
           db   0
           dw   0

           db   04dh,045h,0a9h,0ach; expected crc
           db   'ld <bc,de>,(nnnn)'
           db   '.............$'

; ld hl,(nnnn) (16 cycles)
ld162:     db   0d7h          ; flag mask

           db   02ah,low msbt,high msbt,0
           dw   09863h,07830h,02077h,0b1feh,0b9fah,0abb8h
           db   004h
           db   006h
           dw   06015h

           db   0,0,0,0
           dw   0,0,0,0,0,0
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   -1,0,0,0,0,0
           db   0
           db   0
           dw   0

           db   05fh,097h,024h,087h; expected crc
           db   'ld hl,(nnnn)'
           db   '..................$'

; ld sp,(nnnn) (16 cycles)
ld163:     db   0d7h          ; flag mask

           db   0edh,07bh,low msbt,high msbt
           dw   08dfch,057d7h,02161h,0ca18h,0c185h,027dah
           db   083h
           db   01eh
           dw   0f460h

           db   0,0,0,0
           dw   0,0,0,0,0,0
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   -1,0,0,0,0,0
           db   0
           db   0
           dw   0

           db   07ah,0ceh,0a1h,01bh; expected crc
           db   'ld sp,(nnnn)'
           db   '..................$'

; ld <ix,iy>,(nnnn) (32 cycles)
ld164:     db   0d7h          ; flag mask

           db   0ddh,02ah,low msbt,high msbt
           dw   0ded7h,0a6fah,0f780h,0244ch,087deh,0bcc2h
           db   016h
           db   063h
           dw   04c96h

           db   020h,0,0,0
           dw   0,0,0,0,0,0
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   -1,0,0,0,0,0
           db   0
           db   0
           dw   0

           db   085h,08bh,0f1h,06dh; expected crc
           db   'ld <ix,iy>,(nnnn)'
           db   '.............$'

; ld (nnnn),<bc,de> (64 cycles)
ld165:     db   0d7h          ; flag mask

           db   0edh,043h,low msbt,high msbt
           dw   01f98h,0844dh,0e8ach,0c9edh,0c95dh,08f61h
           db   080h
           db   03fh
           dw   0c7bfh

           db   0,010h,0,0
           dw   0,0,0,0,0,0
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   0,0,0,0,-1,-1
           db   0
           db   0
           dw   0

           db   064h,01eh,087h,015h; expected crc
           db   'ld (nnnn),<bc,de>'
           db   '.............$'

; ld (nnnn),hl (16 cycles)
ld166:     db   0d7h          ; flag mask

           db   022h,low msbt,high msbt,0
           dw   0d003h,07772h,07f53h,03f72h,064eah,0e180h
           db   010h
           db   02dh
           dw   035e9h

           db   0,0,0,0
           dw   0,0,0,0,0,0
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   0,0,0,-1,0,0
           db   0
           db   0
           dw   0

           db   0a3h,060h,08bh,047h; expected crc
           db   'ld (nnnn),hl'
           db   '..................$'

; ld (nnnn),sp (16 cycles)
ld167:     db   0d7h          ; flag mask

           db   0edh,073h,low msbt,high msbt
           dw   0c0dch,0d1d6h,0ed5ah,0f356h,0afdah,06ca7h
           db   044h
           db   09fh
           dw   03f0ah

           db   0,0,0,0
           dw   0,0,0,0,0,0
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   0,0,0,0,0,0
           db   0
           db   0
           dw   -1

           db   016h,058h,05fh,0d7h; expected crc
           db   'ld (nnnn),sp'
           db   '..................$'

; ld (nnnn),<ix,iy> (64 cycles)
ld168:     db   0d7h          ; flag mask

           db   0ddh,022h,low msbt,high msbt
           dw   06cc3h,00d91h,06900h,08ef8h,0e3d6h,0c3f7h
           db   0c6h
           db   0d9h
           dw   0c2dfh

           db   020h,0,0,0
           dw   0,0,0,0,0,0
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   0,-1,-1,0,0,0
           db   0
           db   0
           dw   0

           db   0bah,010h,02ah,06bh; expected crc
           db   'ld (nnnn),<ix,iy>'
           db   '.............$'

; ld <bc,de,hl,sp>,nnnn (64 cycles)
ld16im:    db   0d7h          ; flag mask

           db   1,0,0,0
           dw   05c1ch,02d46h,08eb9h,06078h,074b1h,0b30eh
           db   046h
           db   0d1h
           dw   030cch

           db   030h,0,0,0
           dw   0,0,0,0,0,0
           db   0
           db   0
           dw   0

           db   0,0ffh,0ffh,0
           dw   0,0,0,0,0,0
           db   0
           db   0
           dw   0

           db   0deh,039h,019h,069h; expected crc
           db   'ld <bc,de,hl,sp>,nnnn'
           db   '.........$'

; ld <ix,iy>,nnnn (32 cycles)
ld16ix:    db   0d7h          ; flag mask

           db   0ddh,021h,0,0
           dw   087e8h,02006h,0bd12h,0b69bh,07253h,0a1e5h
           db   051h
           db   013h
           dw   0f1bdh

           db   020h,0,0,0
           dw   0,0,0,0,0,0
           db   0
           db   0
           dw   0

           db   0,0,0ffh,0ffh
           dw   0,0,0,0,0,0
           db   0
           db   0
           dw   0

           db   022h,07dh,0d5h,025h; expected crc
           db   'ld <ix,iy>,nnnn'
           db   '...............$'

; ld a,<(bc),(de)> (44 cycles)
ld8bd:     db   0d7h          ; flag mask

           db   00ah,0,0,0
           dw   0b3a8h,01d2ah,07f8eh,042ach,msbt,msbt
           db   0c6h
           db   0b1h
           dw   0ef8eh

           db   010h,0,0,0
           dw   0,0,0,0,0,0
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   0ffh,0,0,0,0,0
           db   0d7h
           db   -1
           dw   0

           db   0b0h,081h,089h,035h; expected crc
           db   'ld a,<(bc),(de)>'
           db   '..............$'

; ld <b,c,d,e,h,l,(hl),a>,nn (64 cycles)
ld8im:     db   0d7h          ; flag mask

           db   06h,0,0,0
           dw   0c407h,0f49dh,0d13dh,00339h,0de89h,07455h
           db   053h
           db   0c0h
           dw   05509h

           db   038h,0,0,0
           dw   0,0,0,0,0,0
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   0,0,0,0,0,0
           db   0
           db   -1
           dw   0

           db   0f1h,0dah,0b5h,056h; expected crc
           db   'ld <b,c,d,e,h,l,(hl),a>,nn'
           db   '....$'

; ld (<ix,iy>+1),nn (32 cycles)
ld8imx:    db   0d7h          ; flag mask

           db   0ddh,036h,1,0
           dw   01b45h,msbt-1,msbt-1,0d5c1h,061c7h,0bdc4h
           db   0c0h
           db   085h
           dw   0cd16h

           db   020h,0,0,0
           dw   0,0,0,0,0,0
           db   0
           db   0
           dw   0

           db   0,0,0,0ffh
           dw   0,0,0,0,0,0
           db   0
           db   -1
           dw   0

           db   026h,0dbh,047h,07eh; expected crc
           db   'ld (<ix,iy>+1),nn'
           db   '.............$'

; ld <b,c,d,e>,(<ix,iy>+1) (512 cycles)
ld8ix1:    db   0d7h          ; flag mask

           db   0ddh,046h,1,0
           dw   0d016h,msbt-1,msbt-1,04260h,07f39h,00404h
           db   097h
           db   04ah
           dw   0d085h

           db   020h,018h,0,0
           dw   0,1,1,0,0,0
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   -1,0,0,0,0,0
           db   0
           db   0
           dw   0

           db   0cch,011h,006h,0a8h; expected crc
           db   'ld <b,c,d,e>,(<ix,iy>+1)'
           db   '......$'

; ld <h,l>,(<ix,iy>+1) (256 cycles)
ld8ix2:    db   0d7h          ; flag mask

           db   0ddh,066h,1,0
           dw   084e0h,msbt-1,msbt-1,09c52h,0a799h,049b6h
           db   093h
           db   000h
           dw   0eeadh

           db   020h,008h,0,0
           dw   0,1,1,0,0,0
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   -1,0,0,0,0,0
           db   0
           db   0
           dw   0

           db   0fah,02ah,04dh,003h; expected crc
           db   'ld <h,l>,(<ix,iy>+1)'
           db   '..........$'

; ld a,(<ix,iy>+1) (128 cycles)
ld8ix3:    db   0d7h          ; flag mask

           db   0ddh,07eh,1,0
           dw   0d8b6h,msbt-1,msbt-1,0c612h,0df07h,09cd0h
           db   043h
           db   0a6h
           dw   0a0e5h

           db   020h,0,0,0
           dw   0,1,1,0,0,0
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   -1,0,0,0,0,0
           db   0
           db   0
           dw   0

           db   0a5h,0e9h,0ach,064h; expected crc
           db   'ld a,(<ix,iy>+1)'
           db   '..............$'

; ld <ixh,ixl,iyh,iyl>,nn (32 cycles)
ld8ixy:    db   0d7h          ; flag mask

           db   0ddh,026h,0,0
           dw   03c53h,04640h,0e179h,07711h,0c107h,01afah
           db   081h
           db   0adh
           dw   05d9bh

           db   020h,08h,0,0
           dw   0,0,0,0,0,0
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   0,0,0,0,0,0
           db   0
           db   -1
           dw   0

           db   024h,0e8h,082h,08bh; expected crc
           db   'ld <ixh,ixl,iyh,iyl>,nn'
           db   '.......$'

; ld <b,c,d,e,h,l,a>,<b,c,d,e,h,l,a> (3456 cycles)
ld8rr:     db   0d7h          ; flag mask

           db   040h,0,0,0
           dw   072a4h,0a024h,061ach,msbt,082c7h,0718fh
           db   097h
           db   08fh
           dw   0ef8eh

           db   03fh,0,0,0
           dw   0,0,0,0,0,0
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   0ffh,0,0,0,-1,-1
           db   0d7h
           db   -1
           dw   0

           db   074h,04bh,001h,018h; expected crc
           db   'ld <bcdehla>,<bcdehla>'
           db   '........$'

; ld <b,c,d,e,ixy,a>,<b,c,d,e,ixy,a> (6912 cycles)
ld8rrx:    db   0d7h          ; flag mask
           db   0ddh,040h,0,0
           dw   0bcc5h,msbt,msbt,msbt,02fc2h,098c0h
           db   083h
           db   01fh
           dw   03bcdh

           db   020h,03fh,0,0
           dw   0,0,0,0,0,0
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   0ffh,0,0,0,-1,-1
           db   0d7h
           db   -1
           dw   0

           db   047h,08bh,0a3h,06bh; expected crc
           db   'ld <bcdexya>,<bcdexya>'
           db   '........$'

; ld a,(nnnn) / ld (nnnn),a (44 cycles)
lda:       db   0d7h          ; flag mask

           db   032h,low msbt,high msbt,0
           dw   0fd68h,0f4ech,044a0h,0b543h,00653h,0cdbah
           db   0d2h
           db   04fh
           dw   01fd8h

           db   08h,0,0,0
           dw   0,0,0,0,0,0
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   0ffh,0,0,0,0,0
           db   0d7h
           db   -1
           dw   0

           db   0c9h,026h,02dh,0e5h; expected crc
           db   'ld a,(nnnn) / ld (nnnn),a'
           db   '.....$'

; ldd<r> (1) (44 cycles)
ldd1:      db   0d7h          ; flag mask

           db   0edh,0a8h,0,0
           dw   09852h,068fah,066a1h,msbt+3,msbt+1,1
           db   0c1h
           db   068h
           dw   020b7h

           db   0,010h,0,0
           dw   0,0,0,0,0,0
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   -1,0,0,0,0,0
           db   0d7h
           db   0
           dw   0

           db   094h,0f4h,027h,069h; expected crc
           db   'ldd<r> (1)'
           db   '....................$'

; ldd<r> (2) (44 cycles)
ldd2:      db   0d7h          ; flag mask

           db   0edh,0a8h,0,0
           dw   0f12eh,0eb2ah,0d5bah,msbt+3,msbt+1,2
           db   047h
           db   0ffh
           dw   0fbe4h

           db   0,010h,0,0
           dw   0,0,0,0,0,0
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   -1,0,0,0,0,0
           db   0d7h
           db   0
           dw   0

           db   05ah,090h,07eh,0d4h; expected crc
           db   'ldd<r> (2)'
           db   '....................$'

; ldi<r> (1) (44 cycles)
ldi1:      db   0d7h          ; flag mask

           db   0edh,0a0h,0,0
           dw   0fe30h,003cdh,06058h,msbt+2,msbt,1
           db   004h
           db   060h
           dw   02688h

           db   0,010h,0,0
           dw   0,0,0,0,0,0
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   -1,0,0,0,0,0
           db   0d7h
           db   0
           dw   0

           db   09ah,0bdh,0f6h,0b5h; expected crc
           db   'ldi<r> (1)'
           db   '....................$'

; ldi<r> (2) (44 cycles)
ldi2:      db   0d7h          ; flag mask

           db   0edh,0a0h,0,0
           dw   04aceh,0c26eh,0b188h,msbt+2,msbt,2
           db   014h
           db   02dh
           dw   0a39fh

           db   0,010h,0,0
           dw   0,0,0,0,0,0
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   -1,0,0,0,0,0
           db   0d7h
           db   0
           dw   0

           db   0ebh,059h,089h,01bh; expected crc
           db   'ldi<r> (2)'
           db   '....................$'

; neg (16,384 cycles)
neg:       db   0d7h          ; flag mask

           db   0edh,044h,0,0
           dw   038a2h,05f6bh,0d934h,057e4h,0d2d6h,04642h
           db   043h
           db   05ah
           dw   009cch

           db   0,0,0,0
           dw   0,0,0,0,0,0
           db   0d7h
           db   -1
           dw   0

           db   0,0,0,0
           dw   0,0,0,0,0,0
           db   0
           db   0
           dw   0

           db   06ah,03ch,03bh,0bdh; expected crc
           db   'neg'
           db   '...........................$'

; <rld,rrd> (7168 cycles)
rld:       db   0d7h          ; flag mask

           db   0edh,067h,0,0
           dw   091cbh,0c48bh,0fa62h,msbt,0e720h,0b479h
           db   040h
           db   006h
           dw   08ae2h

           db   0,08h,0,0
           dw   0ffh,0,0,0,0,0
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   0,0,0,0,0,0
           db   0d7h
           db   -1
           dw   0

           db   095h,05bh,0a3h,026h; expected crc
           db   '<rrd,rld>'
           db   '.....................$'

; <rlca,rrca,rla,rra> (6144 cycles)
rot8080:   db   0d7h          ; flag mask

           db   07h,0,0,0
           dw   0cb92h,06d43h,00a90h,0c284h,00c53h,0f50eh
           db   091h
           db   0ebh
           dw   040fch

           db   018h,0,0,0
           dw   0,0,0,0,0,0
           db   0
           db   -1
           dw   0

           db   0,0,0,0
           dw   0,0,0,0,0,0
           db   0d7h
           db   0
           dw   0

           db   025h,013h,030h,0aeh; expected crc
           db   '<rlca,rrca,rla,rra>'
           db   '...........$'

; shift/rotate (<ix,iy>+1) (416 cycles)
rotxy:     db   0d7h          ; flag mask

           db   0ddh,0cbh,1,06h
           dw   0ddafh,msbt-1,msbt-1,0ff3ch,0dbf6h,094f4h
           db   082h
           db   080h
           dw   061d9h

           db   020h,0,0,038h
           dw   0,0,0,0,0,0
           db   080h
           db   0
           dw   0

           db   0,0,0,0
           dw   0ffh,0,0,0,0,0
           db   057h
           db   0
           dw   0

           db   071h,03ah,0cdh,081h; expected crc
           db   'shf/rot (<ix,iy>+1)'
           db   '...........$'

; shift/rotate <b,c,d,e,h,l,(hl),a> (6784 cycles)
rotz80:    db   0d7h          ; flag mask

           db   0cbh,0,0,0
           dw   0ccebh,05d4ah,0e007h,msbt,01395h,030eeh
           db   043h
           db   078h
           dw   03dadh

           db   0,03fh,0,0
           dw   0,0,0,0,0,0
           db   080h
           db   0
           dw   0

           db   0,0,0,0
           dw   0ffh,0,0,0,-1,-1
           db   057h
           db   -1
           dw   0

           db   0ebh,060h,04dh,058h; expected crc
           db   'shf/rot <b,c,d,e,h,l,(hl),a>'
           db   '..$'

; <set,res> n,<b,c,d,e,h,l,(hl),a> (7936 cycles)
srz80:     db   0d7h          ; flag mask

           db   0cbh,080h,0,0
           dw   02cd5h,097abh,039ffh,msbt,0d14bh,06ab2h
           db   053h
           db   027h
           dw   0b538h

           db   0,07fh,0,0
           dw   0,0,0,0,0,0
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   0ffh,0,0,0,-1,-1
           db   0d7h
           db   -1
           dw   0

           db   08bh,057h,0f0h,008h; expected crc
           db   '<set,res> n,<bcdehl(hl)a>'
           db   '.....$'

; <set,res> n,(<ix,iy>+1) (1792 cycles)
srzx:      db   0d7h          ; flag mask

           db   0ddh,0cbh,1,086h
           dw   0fb44h,msbt-1,msbt-1,0ba09h,068beh,032d8h
           db   010h
           db   05eh
           dw   0a867h

           db   020h,0,0,078h
           dw   0,0,0,0,0,0
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   0ffh,0,0,0,0,0
           db   0d7h
           db   0
           dw   0

           db   0cch,063h,0f9h,08ah; expected crc
           db   '<set,res> n,(<ix,iy>+1)'
           db   '.......$'

; ld (<ix,iy>+1),<b,c,d,e> (1024 cycles)
st8ix1:    db   0d7h          ; flag mask

           db   0ddh,070h,1,0
           dw   0270dh,msbt-1,msbt-1,0b73ah,0887bh,099eeh
           db   086h
           db   070h
           dw   0ca07h

           db   020h,003h,0,0
           dw   0,1,1,0,0,0
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   0,0,0,0,-1,-1
           db   0
           db   0
           dw   0

           db   004h,062h,06ah,0bfh; expected crc
           db   'ld (<ix,iy>+1),<b,c,d,e>'
           db   '......$'

; ld (<ix,iy>+1),<h,l> (256 cycles)
st8ix2:    db   0d7h          ; flag mask

           db   0ddh,074h,1,0
           dw   0b664h,msbt-1,msbt-1,0e8ach,0b5f5h,0aafeh
           db   012h
           db   010h
           dw   09566h

           db   020h,1,0,0
           dw   0,1,1,0,0,0
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   0,0,0,-1,0,0
           db   0
           db   0
           dw   0

           db   06ah,01ah,088h,031h; expected crc
           db   'ld (<ix,iy>+1),<h,l>'
           db   '..........$'

; ld (<ix,iy>+1),a (64 cycles)
st8ix3:    db   0d7h          ; flag mask

           db   0ddh,077h,1,0
           dw   067afh,msbt-1,msbt-1,04f13h,00644h,0bcd7h
           db   050h
           db   0ach
           dw   05fafh

           db   020h,0,0,0
           dw   0,1,1,0,0,0
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   0,0,0,0,0,0
           db   0
           db   -1
           dw   0

           db   0cch,0beh,05ah,096h; expected crc
           db   'ld (<ix,iy>+1),a'
           db   '..............$'

; ld (<bc,de>),a (96 cycles)
stabd:     db   0d7h          ; flag mask

           db   02h,0,0,0
           dw   0c3bh,0b592h,06cffh,0959eh,msbt,msbt+1
           db   0c1h
           db   021h
           dw   0bde7h

           db   018h,0,0,0
           dw   0,0,0,0,0,0
           db   0
           db   0
           dw   0

           db   0,0,0,0
           dw   -1,0,0,0,0,0
           db   0
           db   -1
           dw   0

           db   07ah,04ch,011h,04fh; expected crc
           db   'ld (<bc,de>),a'
           db   '................$'

;---------------------------------------------------------
; end of test descriptors
;---------------------------------------------------------

; start test pointed to by (hl)
stt:       push hl
           ld   a,(hl)        ; get pointer to test
           inc  hl
           ld   h,(hl)
           ld   l,a
           ld   a,(hl)        ; flag mask
           ld   (flgmsk+1),a
           inc  hl
           push hl
           ld   de,20
           add  hl,de         ; point to incmask
           ld   de,counter
           call initmask
           pop  hl
           push hl
           ld   de,20+20
           add  hl,de         ; point to scanmask
           ld   de,shifter
           call initmask
           ld   hl,shifter
           ld   (hl),1        ; first bit
           pop  hl
           push hl
           ld   de,iut        ; copy initial instruction
           ld   bc,4
           ldir
           ld   de,msbt       ; copy initial machine state
           ld   bc,16
           ldir
           ld   de,20+20+4    ; skip incmask, scanmask and expcrc
           add  hl,de
           ex   de,hl
           ld   c,9
           call bdos          ; show test name
           call initcrc       ; initialise crc
           ; test loop
tlp:       ld   a,(iut)
           cp   076h          ; avoid halt intructions
           jp   z,tlp2
           and  0dfh
           cp   0ddh
           jp   nz,tlp1
           ld   a,(iut+1)
           cp   076h
tlp1:      call nz,test       ; execute the test instruction
tlp2:      call count         ; increment the counter
           call nz,shift      ; shift the scan bit
           pop  hl            ; pointer to test case
           jp   z,tlp3        ; done if shift returned NZ
           ld   de,20+20+20
           add  hl,de         ; point to expected crc
           call cmpcrc
           ld   de,okmsg
           jp   z,tlpok
           ld   de,ermsg1
           ld   c,9
           call bdos
           call phex8
           ld   de,ermsg2
           ld   c,9
           call bdos
           ld   hl,crcval
           call phex8
           ld   de,crlf
tlpok:     ld   c,9
           call bdos
           pop  hl
           inc  hl
           inc  hl
           ret

tlp3:      push hl
           ld   a,1           ; init count and shift scanners
           ld   (cntbit),a
           ld   (shfbit),a
           ld   hl,counter
           ld   (cntbyt),hl
           ld   hl,shifter
           ld   (shfbyt),hl

           ld   b,4           ; bytes in iut field
           pop  hl            ; pointer to test case
           push hl
           ld   de,iut
           call setup         ; setup iut
           ld   b,16          ; bytes in machine state
           ld   de,msbt
           call setup         ; setup machine state
           jp   tlp

; setup a field of the test case
; b  = number of bytes
; hl = pointer to base case
; de = destination
setup:     call subyte
           inc  hl
           dec  b
           jp   nz,setup
           ret

subyte:    push bc
           push de
           push hl
           ld   c,(hl)        ; get base byte
           ld   de,20
           add  hl,de         ; point to incmask
           ld   a,(hl)
           cp   0
           jp   z,subshf
           ld   b,8           ; 8 bits
subclp:    rrca
           push af
           ld   a,0
           call c,nxtcbit     ; get next counter bit if mask bit was set
           xor  c             ; flip bit if counter bit was set
           rrca
           ld   c,a
           pop  af
           dec  b
           jp   nz,subclp
           ld   b,8
subshf:    ld   de,20
           add  hl,de         ; point to shift mask
           ld   a,(hl)
           cp   0
           jp   z,substr
           ld   b,8           ; 8 bits
sbshf1:    rrca
           push af
           ld   a,0
           call c,nxtsbit     ; get next shifter bit if mask bit was set
           xor  c             ; flip bit if shifter bit was set
           rrca
           ld   c,a
           pop  af
           dec  b
           jp   nz,sbshf1
substr:    pop  hl
           pop  de
           ld   a,c
           ld   (de),a        ; mangled byte to destination
           inc  de
           pop  bc
           ret

; get next counter bit in low bit of a
cntbit:    ds   1
cntbyt:    ds   2

nxtcbit:   push bc
           push hl
           ld   hl,(cntbyt)
           ld   b,(hl)
           ld   hl,cntbit
           ld   a,(hl)
           ld   c,a
           rlca
           ld   (hl),a
           cp   1
           jp   nz,ncb1
           ld   hl,(cntbyt)
           inc  hl
           ld   (cntbyt),hl
ncb1:      ld   a,b
           and  c
           pop  hl
           pop  bc
           ret  z
           ld   a,1
           ret

; get next shifter bit in low bit of a
shfbit:    ds   1
shfbyt:    ds   2

nxtsbit:   push bc
           push hl
           ld   hl,(shfbyt)
           ld   b,(hl)
           ld   hl,shfbit
           ld   a,(hl)
           ld   c,a
           rlca
           ld   (hl),a
           cp   1
           jp   nz,nsb1
           ld   hl,(shfbyt)
           inc  hl
           ld   (shfbyt),hl
nsb1:      ld   a,b
           and  c
           pop  hl
           pop  bc
           ret  z
           ld   a,1
           ret


; clear memory at hl, bc bytes
clrmem:    push af
           push bc
           push de
           push hl
           ld   (hl),0
           ld   d,h
           ld   e,l
           inc  de
           dec  bc
           ldir
           pop  hl
           pop  de
           pop  bc
           pop  af
           ret

; initialise counter or shifter
; de = pointer to work area for counter or shifter
; hl = pointer to mask
initmask:
           push de
           ex   de,hl
           ld   bc,20+20
           call clrmem        ; clear work area
           ex   de,hl
           ld   b,20          ; byte counter
           ld   c,1           ; first bit
           ld   d,0           ; bit counter
imlp:      ld   e,(hl)
imlp1:     ld   a,e
           and  c
           jp   z,imlp2
           inc  d
imlp2:     ld   a,c
           rlca
           ld   c,a
           cp   1
           jp   nz,imlp1
           inc  hl
           dec  b
           jp   nz,imlp
           ; got number of 1-bits in mask in reg d
           ld   a,d
           and  0f8h
           rrca
           rrca
           rrca               ; divide by 8 (get byte offset)
           ld   l,a
           ld   h,0
           ld   a,d
           and  7             ; bit offset
           inc  a
           ld   b,a
           ld   a,080h
imlp3:     rlca
           dec  b
           jp   nz,imlp3
           pop  de
           add  hl,de
           ld   de,20
           add  hl,de
           ld   (hl),a
           ret

; multi-byte counter
count:     push bc
           push de
           push hl
           ld   hl,counter    ; 20 byte counter starts here
           ld   de,20         ; somewhere in here is the stop bit
           ex   de,hl
           add  hl,de
           ex   de,hl
cntlp:     inc  (hl)
           ld   a,(hl)
           cp   0
           jp   z,cntlp1      ; overflow to next byte
           ld   b,a
           ld   a,(de)
           and  b             ; test for terminal value
           jp   z,cntend
           ld   (hl),0        ; reset to zero
cntend:    pop  bc
           pop  de
           pop  hl
           ret

cntlp1:    inc  hl
           inc  de
           jp   cntlp


; multi-byte shifter
shift:     push bc
           push de
           push hl
           ld   hl,shifter    ; 20 byte shift register starts here
           ld   de,20         ; somewhere in here is the stop bit
           ex   de,hl
           add  hl,de
           ex   de,hl
shflp:     ld   a,(hl)
           or   a
           jp   z,shflp1
           ld   b,a
           ld   a,(de)
           and  b
           jp   nz,shlpe
           ld   a,b
           rlca
           cp   1
           jp   nz,shflp2
           ld   (hl),0
           inc  hl
           inc  de
shflp2:    ld   (hl),a
           xor  a             ; set Z
shlpe:     pop  hl
           pop  de
           pop  bc
           ret
shflp1:    inc  hl
           inc  de
           jp   shflp

counter:   ds   2*20
shifter:   ds   2*20

; test harness
test:      push af
           push bc
           push de
           push hl
           if   0
               ld   de,crlf
               ld   c,9
               call bdos
               ld   hl,iut
               ld   b,4
               call hexstr
               ld   e,' '
               ld   c,2
               call bdos
               ld   b,16
               ld   hl,msbt
               call hexstr
           endif
           di                 ; disable interrupts
           ld   (spsav),sp    ; save stack pointer
           ld   sp,msbt+2     ; point to test-case machine state
           pop  iy            ; and load all regs
           pop  ix
           pop  hl
           pop  de
           pop  bc
           pop  af
           ld   sp,(spbt)
iut:       ds   4             ; max 4 byte instruction under test
           ld   (spat),sp     ; save stack pointer
           ld   sp,spat
           push af            ; save other registers
           push bc
           push de
           push hl
           push ix
           push iy
           ld   sp,(spsav)    ; restore stack pointer
           ei                 ; enable interrupts
           ld   hl,(msbt)     ; copy memory operand
           ld   (msat),hl
           ld   hl,flgsat     ; flags after test
           ld   a,(hl)
flgmsk:    and  0d7h          ; mask-out irrelevant bits (self-modified code!)
           ld   (hl),a
           ld   b,16          ; total of 16 bytes of state
           ld   de,msat
           ld   hl,crcval
tcrc:      ld   a,(de)
           inc  de
           call updcrc        ; accumulate crc of this test case
           dec  b
           jp   nz,tcrc
           if   0
               ld   e,' '
               ld   c,2
               call bdos
               ld   hl,crcval
               call phex8
               ld   de,crlf
               ld   c,9
               call bdos
               ld   hl,msat
               ld   b,16
               call hexstr
               ld   de,crlf
               ld   c,9
               call bdos
           endif
           pop  hl
           pop  de
           pop  bc
           pop  af
           ret

; machine state after test
msat:      ds   14            ; memop,iy,ix,hl,de,bc,af
spat:      ds   2             ; stack pointer after test
flgsat:         equ spat-2    ; flags

spsav:     ds   2             ; saved stack pointer

; display hex string (pointer in hl, byte count in b)
hexstr:    ld   a,(hl)
           call phex2
           inc  hl
           dec  b
           jp   nz,hexstr
           ret

; display hex
; display the big-endian 32-bit value pointed to by hl
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

; display byte in a
phex2:     push af
           rrca
           rrca
           rrca
           rrca
           call phex1
           pop  af
; fall through

; display low nibble in a
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
           call bdos
           pop  hl
           pop  de
           pop  bc
           pop  af
           ret

bdos       push af
           push bc
           push de
           push hl
           call monbdos
           pop  hl
           pop  de
           pop  bc
           pop  af
           ret

; compare crc
; hl points to value to compare to crcval
cmpcrc:    push bc
           push de
           push hl
           ld   de,crcval
           ld   b,4
cclp:      ld   a,(de)
           cp   (hl)
           jp   nz,cce
           inc  hl
           inc  de
           dec  b
           jp   nz,cclp
cce:       pop  hl
           pop  de
           pop  bc
           ret

; 32-bit crc routine
; entry: a contains next byte, hl points to crc
; exit:  crc updated
updcrc:    push af
           push bc
           push de
           push hl
           push hl
           ld   de,3
           add  hl,de         ; point to low byte of old crc
           xor  (hl)          ; xor with new byte
           ld   l,a
           ld   h,0
           add  hl,hl         ; use result as index into table of 4 byte entries
           add  hl,hl
           ex   de,hl
           ld   hl,crctab
           add  hl,de         ; point to selected entry in crctab
           ex   de,hl
           pop  hl
           ld   bc,4          ; c = byte count, b = accumulator
crclp:     ld   a,(de)
           xor  b
           ld   b,(hl)
           ld   (hl),a
           inc  de
           inc  hl
           dec  c
           jp   nz,crclp
           if   0
               ld   hl,crcval
               call phex8
               ld   de,crlf
               ld   c,9
               call bdos
           endif
           pop  hl
           pop  de
           pop  bc
           pop  af
           ret

initcrc:   push af
           push bc
           push hl
           ld   hl,crcval
           ld   a,0ffh
           ld   b,4
icrclp:    ld   (hl),a
           inc  hl
           dec  b
           jp   nz,icrclp
           pop  hl
           pop  bc
           pop  af
           ret

crcval     ds   4

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
; x820 monitor entry point
;-------------------------------------------------------

cmdloop    equ  8         ; monitor warm start
monbdos    equ  5         ; monitor bdos entry point

;-------------------------------------------------------
; ascii character aliases
;-------------------------------------------------------

cr         equ  0dh       ; carriage return
lf         equ  0ah       ; linefeed

;-------------------------------------------------------
; strings
;-------------------------------------------------------

msg1:      db   'Z80 instruction exerciser',cr,lf,'$'
msg2:      db   'Tests complete$'
okmsg:     db   '  OK',cr,lf,'$'
ermsg1:    db   '  ERROR **** crc expected:$'
ermsg2:    db   ' found:$'
crlf:      db   cr,lf,'$'

           end
