
;=======================================================
; Spacewar game for the x820 FPGA z80 computer
;
; requires a Tek40xx vector graphic terminal emulator
;
; (c) Scott L. Baker  2020
;=======================================================

simode     equ  0             ; 1=sim 0=synthesis

           IF   simode        ; sim-mode condition

           org  0

           jp   init          ; initialize
           ds   2             ; not used
           jp   0             ; jp bdos
           jp   0             ; jp cmdloop
           jp   0             ; jp uart    isr
           jp   0             ; jp timer 1 isr
           jp   0             ; jp timer 2 isr

           ENDIF              ; sim-mode condition

           org  100h

init:      di                 ; disable interrupts
           ld   sp,tos        ; initialize the stack
           call inituart      ; initialize the uart
           call inittm1       ; initialize timer 1
           call inittm2       ; initialize timer 2
           call initbufx      ; initialize all buffers
           call initvars      ; init vars to zero
           call strttm1       ; start timer 1
           call strttm2       ; start timer 2

start:     call getkey        ; check for keypress
           call geometry      ; movement geometry
           call plotbuf       ; plot data to buf1
           call cmprbuf       ; if no data change
           jr   z,start       ; then do nothing
           call copybuf       ; else copy buf1 to buf2
           call putbuf        ; and send tek40xx data
           jr   start         ; repeat

;-------------------------------------------------------
; movement and rotation calculations
;-------------------------------------------------------
geometry:  call movesx1       ; move ship 1
           call movesx2       ; move ship 2
           call rotate1       ; rotate ship 1
           jp   rotate2       ; rotate ship 2

;-------------------------------------------------------
; load buf1 with next screen data
;-------------------------------------------------------
plotbuf:   ld   hl,buf1
           call plotsx1       ; plot ship 1
           call plottx1       ; plot tail 1
           call plotsx2       ; plot ship 2
           call plottx2       ; plot tail 2
           call plottp1       ; plot torpedo 1
           call plottp2       ; plot torpedo 2
           call plotstar      ; plot central star
           jp   termdata      ; terminate data

;-------------------------------------------------------
; move ship 1  (needle)
;-------------------------------------------------------
movesx1:   in   a,(tmr1ich)   ; read the timer
           or   a
           ret  z             ; return if time < 256
           call strttm1       ; re-start timer
           ld   hl,speed1     ; check the speed
           bit  0,(hl)
           jp   z,trks1tp     ; track torpedos
           ;--------------------------
           ; update x position
           ;---------------------------
           ld   h,7fh
           ld   a,(theta1)
           call cos           ; e = cos(a)
           call mul           ; h = vec * cos(a)
           ld   c,h
           sra  c
           sra  c
           sra  c
           xor  a
           bit  7,h           ; check sign bit
           jr   z,move1a
           cpl
move1a:    ld   b,a
           ld   hl,(x1)       ; old x position
           add  hl,bc
           ld   (x1),hl       ; new x position
           ld   bc,0fc20h     ; magic number
           add  hl,bc
           jr   nc,move1b
           ld   hl,0042h      ; magic number
           ld   (x1),hl       ; wrap x position
           jr   move1c
move1b:    ld   hl,(x1)
           ld   bc,0040h      ; magic number
           scf
           sbc  hl,bc
           jr   nc,move1c
           ld   hl,03d0h      ; magic number
           ld   (x1),hl       ; wrap x position
           ;---------------------------
           ; update y position
           ;---------------------------
move1c:    ld   h,7fh
           ld   a,(theta1)
           call sin           ; e = sin(a)
           call mul           ; h = vec * sin(a)
           ld   c,h
           sra  c
           sra  c
           sra  c
           xor  a
           bit  7,h           ; check sign bit
           jr   z,move1d
           cpl
move1d:    ld   b,a
           ld   hl,(y1)       ; old y position
           add  hl,bc
           ld   (y1),hl       ; new y position
           ld   bc,0fd15h     ; magic number
           add  hl,bc
           jr   nc,move1e
           ld   hl,0042h      ; magic number
           ld   (y1),hl       ; wrap y position
           jp   trks1tp       ; track torpedos
move1e:    ld   hl,(y1)
           ld   bc,0040h      ; magic number
           scf
           sbc  hl,bc
           jp   nc,trks1tp    ; track torpedos
           ld   hl,02d0h      ; magic number
           ld   (y1),hl       ; wrap y position
           jp   trks1tp       ; track torpedos

;-------------------------------------------------------
; move ship 2  (wedge)
;-------------------------------------------------------
movesx2:   in   a,(tmr2ich)   ; read the timer
           or   a
           ret  z             ; return if time < 256
           call strttm2       ; re-start timer
           ld   hl,speed2     ; check the speed
           bit  0,(hl)
           jp   z,trks2tp     ; track torpedos
           ;--------------------------
           ; update x position
           ;---------------------------
           ld   h,7fh
           ld   a,(theta2)
           call cos           ; e = cos(a)
           call mul           ; h = vec * cos(a)
           ld   c,h
           sra  c
           sra  c
           sra  c
           xor  a
           bit  7,h           ; check sign bit
           jr   z,move2a
           cpl
move2a:    ld   b,a
           ld   hl,(x2)       ; old x position
           add  hl,bc
           ld   (x2),hl       ; new x position
           ld   bc,0fc20h     ; magic number
           add  hl,bc
           jr   nc,move2b
           ld   hl,0042h      ; magic number
           ld   (x2),hl       ; wrap x position
           jr   move2c
move2b:    ld   hl,(x2)
           ld   bc,0040h      ; magic number
           scf
           sbc  hl,bc
           jr   nc,move2c
           ld   hl,03d0h      ; magic number
           ld   (x2),hl       ; wrap x position
           ;---------------------------
           ; update y position
           ;---------------------------
move2c:    ld   h,7fh
           ld   a,(theta2)
           call sin           ; e = sin(a)
           call mul           ; h = vec * sin(a)
           ld   c,h
           sra  c
           sra  c
           sra  c
           xor  a
           bit  7,h           ; check sign bit
           jr   z,move2d
           cpl
move2d:    ld   b,a
           ld   hl,(y2)       ; old y position
           add  hl,bc
           ld   (y2),hl       ; new y position
           ld   bc,0fd15h     ; magic number
           add  hl,bc
           jr   nc,move2e
           ld   hl,0042h      ; magic number
           ld   (y2),hl       ; wrap y position
           jp   trks2tp       ; track torpedos
move2e:    ld   hl,(y2)
           ld   bc,0040h      ; magic number
           scf
           sbc  hl,bc
           jp   nc,trks2tp    ; track torpedos
           ld   hl,02d0h      ; magic number
           ld   (y2),hl       ; wrap y position
           jp   trks2tp       ; track torpedos

;-------------------------------------------------------
; track ship 1 torpedos
;-------------------------------------------------------
trks1tp:   ld   iy,tp1a       ; track torpedo 1a
           call trktpd
           ld   iy,tp1b       ; track torpedo 1b
           call trktpd
           ld   iy,tp1c       ; track torpedo 1c
           jr   trktpd

;-------------------------------------------------------
; track ship 2 torpedos
;-------------------------------------------------------
trks2tp:   ld   iy,tp2a       ; track torpedo 2a
           call trktpd
           ld   iy,tp2b       ; track torpedo 2b
           call trktpd
           ld   iy,tp2c       ; track torpedo 2c
           jr   trktpd

;-------------------------------------------------------
; track a torpedo
;-------------------------------------------------------
trktpd:    call getlife
           or   a             ; set flags
           ret  z             ; skip if no torpedo
           cp   tpnew         ; new torpedo?
           jr   nz,trktpd1
           dec  a             ; decrement
           ld   (hl),a        ; torpedo life
           call torpix
           call ipangl
           call getxs         ; hl = ship x
           ld   (ix),l
           ld   (ix+1),h
           call getys         ; hl = ship y
           ld   (ix+2),l
           ld   (ix+3),h
           jr   trktpd2
trktpd1:   dec  a             ; decrement
           ld   (hl),a        ; torpedo life
           jr   nz,trktpd2    ; if life is zero
           jp   tpclr         ; then clear torpedo
           ;--------------------------
           ; update x position
           ;---------------------------
trktpd2:   ld   a,tdelta      ; get the path length
           ld   h,a
           call tpangl        ; get the angle
           call cos           ; e = cos(a)
           call mul           ; h = path * cos(a)
           ld   c,h
           sra  c
           xor  a
           bit  7,h           ; check sign bit
           jr   z,trktpd3
           cpl
trktpd3:   ld   b,a
           call uptposx
           ;---------------------------
           ; update y position
           ;---------------------------
           ld   a,tdelta      ; get the path length
           ld   h,a
           call tpangl        ; get the angle
           call sin           ; e = sin(a)
           call mul           ; h = path * sin(a)
           ld   c,h
           sra  c
           xor  a
           bit  7,h           ; check sign bit
           jr   z,trktpd4
           cpl
trktpd4:   ld   b,a
           call uptposy
           call torpix
           call filltpd       ; torpedo data
           call chkhit        ; check for hit
           ret

;-------------------------------------------------------
; check for torpedo hit
;-------------------------------------------------------
chkhit:    call getgtx       ; get target x
           ex   de,hl
           call getpdx       ; get torpedo x
           sbc  hl,de        ; compare
           call abs
           ld   a,h          ; check the upper byte
           or   a
           ret  nz
           ld   a,l          ; check the lower byte
           cp   hrad         ; c set if a < hrad
           ret  nc
           call getgty       ; get target y
           ex   de,hl
           call getpdy       ; get torpedo y
           sbc  hl,de        ; compare
           call abs
           ld   a,h          ; check the upper byte
           or   a
           ret  nz
           ld   a,l          ; check the lower byte
           cp   hrad         ; c set if a < hrad
           ret  nc

;-------------------------------------------------------
; ship was hit by a torpedo
;-------------------------------------------------------
sethit:  ; ld   a,iyl
           db   0fdh,07dh
           cp   tp2a          ; c set if a < tp2a
           jr   c,setht2
           xor  a
           cpl
setht1:    ld   (hit1),a      ; ship 1 was hit
           ld   ix,ship1
           jr   fillexp
setht2:    ld   (hit2),a      ; ship 2 was hit
           ld   ix,ship2

;-------------------------------------------------------
; fill out explosion data
; at entry ix points to either ship 1 or ship 2
;
;   ix,      iy           0        2
;   ix+ray,  iy           4        6
;   ix-ray   iy           8        10
;   ix,      iy          12        14
;   ix,      iy+ray      16        18
;   ix,      iy-ray      20        22
;   ix,      iy          24        26
;   ix+ray,  iy+ray      28        30
;   ix-ray,  iy-ray      32        34
;   ix,      iy          36        38
;   ix-ray,  iy+ray      40        42
;   ix+ray,  iy-ray      44        46
;-------------------------------------------------------
fillexp:   ld   l,(ix)
           ld   h,(ix+1)      ; hl = x
           ld   (xplode),hl
           ld   (xplode+12),hl
           ld   (xplode+16),hl
           ld   (xplode+20),hl
           ld   (xplode+24),hl
           ld   (xplode+36),hl
           ld   bc,ray3
           ld   d,h
           ld   e,l
           add  hl,bc
           ld   (xplode+4),hl
           ld   (xplode+28),hl
           ld   (xplode+44),hl
           ex   de,hl
           sbc  hl,bc
           ld   (xplode+8),hl
           ld   (xplode+32),hl
           ld   (xplode+40),hl
           ld   l,(ix+2)      ; hl = y
           ld   h,(ix+3)
           ld   (xplode+2),hl
           ld   (xplode+6),hl
           ld   (xplode+10),hl
           ld   (xplode+14),hl
           ld   (xplode+26),hl
           ld   (xplode+38),hl
           ld   d,h
           ld   e,l
           add  hl,bc
           ld   (xplode+18),hl
           ld   (xplode+30),hl
           ld   (xplode+42),hl
           ex   de,hl
           sbc  hl,bc
           ld   (xplode+22),hl
           ld   (xplode+34),hl
           ld   (xplode+46),hl
           ret

;-------------------------------------------------------
; fill out torpedo data
;-------------------------------------------------------
filltpd:   ld   l,(ix)
           ld   h,(ix+1)      ; hl = x
           ld   (ix+8),l
           ld   (ix+9),h
           inc  hl
           ld   (ix+4),l
           ld   (ix+5),h
           ld   l,(ix+2)      ; hl = y
           ld   h,(ix+3)
           ld   (ix+6),l
           ld   (ix+7),h
           ld   (ix+10),l
           ld   (ix+11),h
           ret

;-------------------------------------------------------
; get torpedo life
;-------------------------------------------------------
getlife: ; ld   a,iyl
           db   0fdh,07dh
           cp   tp1a
           jr   z,get1a       ; torpedo 1a
           cp   tp1b
           jr   z,get1b       ; torpedo 1b
           cp   tp1c
           jr   z,get1c       ; torpedo 1c
           cp   tp2a
           jr   z,get2a       ; torpedo 2a
           cp   tp2b
           jr   z,get2b       ; torpedo 2b
           cp   tp2c
           jr   z,get2c       ; torpedo 2c
get1a:     ld   hl,tlife1a
           ld   a,(hl)
           ret
get1b:     ld   hl,tlife1b
           ld   a,(hl)
           ret
get1c:     ld   hl,tlife1c
           ld   a,(hl)
           ret
get2a:     ld   hl,tlife2a
           ld   a,(hl)
           ret
get2b:     ld   hl,tlife2b
           ld   a,(hl)
           ret
get2c:     ld   hl,tlife2c
           ld   a,(hl)
           ret

;-------------------------------------------------------
; get source x1 or x2
;-------------------------------------------------------
getxs:   ; ld   a,iyl
           db   0fdh,07dh
           cp   tp2a          ; c set if a < tp2a
           jr   c,getxs1
getxs2:    ld   hl,(x2)       ; hl = x2
           ret
getxs1:    ld   hl,(x1)       ; hl = x1
           ret

;-------------------------------------------------------
; get source y1 or y2
;-------------------------------------------------------
getys:   ; ld   a,iyl
           db   0fdh,07dh
           cp   tp2a          ; c set if a < tp2a
           jr   c,getys1
getys2:    ld   hl,(y2)       ; hl = y2
           ret
getys1:    ld   hl,(y1)       ; hl = y1
           ret

;-------------------------------------------------------
; get target x1 or x2
;-------------------------------------------------------
getgtx:  ; ld   a,iyl
           db   0fdh,07dh
           cp   tp2a          ; c set if a < tp2a
           jr   c,getxt2
getxt1:    ld   hl,(x1)       ; hl = x1
           ret
getxt2:    ld   hl,(x2)       ; hl = x2
           ret

;-------------------------------------------------------
; get target y1 or y2
;-------------------------------------------------------
getgty:  ; ld   a,iyl
           db   0fdh,07dh
           cp   tp2a          ; c set if a < tp2a
           jr   c,getyt2
getyt1:    ld   hl,(y1)       ; hl = y1
           ret
getyt2:    ld   hl,(y2)       ; hl = y2
           ret

;-------------------------------------------------------
; get torpedo x
;-------------------------------------------------------
getpdx:  ; ld   a,iyl
           db   0fdh,07dh
           cp   tp1a
           jr   z,getx1a       ; torpedo 1a
           cp   tp1b
           jr   z,getx1b       ; torpedo 1b
           cp   tp1c
           jr   z,getx1c       ; torpedo 1c
           cp   tp2a
           jr   z,getx2a       ; torpedo 2a
           cp   tp2b
           jr   z,getx2b       ; torpedo 2b
           cp   tp2c
           jr   z,getx2c       ; torpedo 2c
getx1a:    ld   hl,(torp1a)
           ret
getx1b:    ld   hl,(torp1b)
           ret
getx1c:    ld   hl,(torp1c)
           ret
getx2a:    ld   hl,(torp2a)
           ret
getx2b:    ld   hl,(torp2b)
           ret
getx2c:    ld   hl,(torp2c)
           ret

;-------------------------------------------------------
; get torpedo y
;-------------------------------------------------------
getpdy:  ; ld   a,iyl
           db   0fdh,07dh
           cp   tp1a
           jr   z,gety1a       ; torpedo 1a
           cp   tp1b
           jr   z,gety1b       ; torpedo 1b
           cp   tp1c
           jr   z,gety1c       ; torpedo 1c
           cp   tp2a
           jr   z,gety2a       ; torpedo 2a
           cp   tp2b
           jr   z,gety2b       ; torpedo 2b
           cp   tp2c
           jr   z,gety2c       ; torpedo 2c
gety1a:    ld   hl,(torp1a+2)
           ret
gety1b:    ld   hl,(torp1b+2)
           ret
gety1c:    ld   hl,(torp1c+2)
           ret
gety2a:    ld   hl,(torp2a+2)
           ret
gety2b:    ld   hl,(torp2b+2)
           ret
gety2c:    ld   hl,(torp2c+2)
           ret

;-------------------------------------------------------
; clear torpedo data
;-------------------------------------------------------
tpclr:     call torpix
           xor  a
           ld   (ix),a
           ld   (ix+1),a
           ret

;-------------------------------------------------------
; get torpedo index
;-------------------------------------------------------
torpix:  ; ld   a,iyl
           db   0fdh,07dh
           cp   tp1a
           jr   z,tpix1a       ; torpedo 1a
           cp   tp1b
           jr   z,tpix1b       ; torpedo 1b
           cp   tp1c
           jr   z,tpix1c       ; torpedo 1c
           cp   tp2a
           jr   z,tpix2a       ; torpedo 2a
           cp   tp2b
           jr   z,tpix2b       ; torpedo 2b
           cp   tp2c
           jr   z,tpix2c       ; torpedo 2c
tpix1a:    ld   ix,torp1a
           ret
tpix1b:    ld   ix,torp1b
           ret
tpix1c:    ld   ix,torp1c
           ret
tpix2a:    ld   ix,torp2a
           ret
tpix2b:    ld   ix,torp2b
           ret
tpix2c:    ld   ix,torp2c
           ret

;-------------------------------------------------------
; initialize torpedo angle
;-------------------------------------------------------
ipangl:  ; ld   a,iyl
           db   0fdh,07dh
           cp   tp1a
           jr   z,ipax1a       ; torpedo 1a
           cp   tp1b
           jr   z,ipax1b       ; torpedo 1b
           cp   tp1c
           jr   z,ipax1c       ; torpedo 1c
           cp   tp2a
           jr   z,ipax2a       ; torpedo 2a
           cp   tp2b
           jr   z,ipax2b       ; torpedo 2b
           cp   tp2c
           jr   z,ipax2c       ; torpedo 2c
ipax1a:    ld   a,(theta1)
           ld   (tpang1a),a
           ret
ipax1b:    ld   a,(theta1)
           ld   (tpang1b),a
           ret
ipax1c:    ld   a,(theta1)
           ld   (tpang1c),a
           ret
ipax2a:    ld   a,(theta2)
           ld   (tpang2a),a
           ret
ipax2b:    ld   a,(theta2)
           ld   (tpang2b),a
           ret
ipax2c:    ld   a,(theta2)
           ld   (tpang2c),a
           ret

;-------------------------------------------------------
; get torpedo angle
;-------------------------------------------------------
tpangl:  ; ld   a,iyl
           db   0fdh,07dh
           cp   tp1a
           jr   z,tpax1a       ; torpedo 1a
           cp   tp1b
           jr   z,tpax1b       ; torpedo 1b
           cp   tp1c
           jr   z,tpax1c       ; torpedo 1c
           cp   tp2a
           jr   z,tpax2a       ; torpedo 2a
           cp   tp2b
           jr   z,tpax2b       ; torpedo 2b
           cp   tp2c
           jr   z,tpax2c       ; torpedo 2c
tpax1a:    ld   a,(tpang1a)
           ret
tpax1b:    ld   a,(tpang1b)
           ret
tpax1c:    ld   a,(tpang1c)
           ret
tpax2a:    ld   a,(tpang2a)
           ret
tpax2b:    ld   a,(tpang2b)
           ret
tpax2c:    ld   a,(tpang2c)
           ret

;-------------------------------------------------------
; update torpedo x position
;-------------------------------------------------------
uptposx: ; ld   a,iyl
           db   0fdh,07dh
           cp   tp1a
           jr   z,tposx1a      ; torpedo 1a
           cp   tp1b
           jr   z,tposx1b      ; torpedo 1b
           cp   tp1c
           jr   z,tposx1c      ; torpedo 1c
           cp   tp2a
           jr   z,tposx2a      ; torpedo 2a
           cp   tp2b
           jr   z,tposx2b      ; torpedo 2b
           cp   tp2c
           jr   z,tposx2c      ; torpedo 2c
tposx1a:   ld   hl,(torp1a)
           add  hl,bc
           ld   (torp1a),hl
           ret
tposx1b:   ld   hl,(torp1b)
           add  hl,bc
           ld   (torp1b),hl
           ret
tposx1c:   ld   hl,(torp1c)
           add  hl,bc
           ld   (torp1c),hl
           ret
tposx2a:   ld   hl,(torp2a)
           add  hl,bc
           ld   (torp2a),hl
           ret
tposx2b:   ld   hl,(torp2b)
           add  hl,bc
           ld   (torp2b),hl
           ret
tposx2c:   ld   hl,(torp2c)
           add  hl,bc
           ld   (torp2c),hl
           ret

;-------------------------------------------------------
; update torpedo y position
;-------------------------------------------------------
uptposy: ; ld   a,iyl
           db   0fdh,07dh
           cp   tp1a
           jr   z,tposy1a      ; torpedo 1a
           cp   tp1b
           jr   z,tposy1b      ; torpedo 1b
           cp   tp1c
           jr   z,tposy1c      ; torpedo 1c
           cp   tp2a
           jr   z,tposy2a      ; torpedo 2a
           cp   tp2b
           jr   z,tposy2b      ; torpedo 2b
           cp   tp2c
           jr   z,tposy2c      ; torpedo 2c
tposy1a:   ld   hl,(torp1a+2)
           add  hl,bc
           ld   (torp1a+2),hl
           ret
tposy1b:   ld   hl,(torp1b+2)
           add  hl,bc
           ld   (torp1b+2),hl
           ret
tposy1c:   ld   hl,(torp1c+2)
           add  hl,bc
           ld   (torp1c+2),hl
           ret
tposy2a:   ld   hl,(torp2a+2)
           add  hl,bc
           ld   (torp2a+2),hl
           ret
tposy2b:   ld   hl,(torp2b+2)
           add  hl,bc
           ld   (torp2b+2),hl
           ret
tposy2c:   ld   hl,(torp2c+2)
           add  hl,bc
           ld   (torp2c+2),hl
           ret

;-------------------------------------------------------
; rotate ship 1  (needle)
; plot order: point0 -> point3 -> point1 -> point2
;-------------------------------------------------------
rotate1:   ld   ix,ship1
           ld   a,(theta1)
           sla  a             ; angle index * 4
           sla  a
           ; -- update point 0
           ld   hl,(x1)       ; hl = x1
           ld   (ix),l
           ld   (ix+1),h
           ld   hl,(y1)       ; hl = y1
           ld   (ix+2),l
           ld   (ix+3),h
           ; -- update point 3
           ld   h,0
           ld   l,a
           ld   de,point3
           add  hl,de         ; hl = x index
           push hl
           ld   e,(hl)
           inc  hl
           ld   d,(hl)        ; de = point3
           ld   hl,(x1)       ; hl = x1
           add  hl,de         ; hl = x1 + point3
           ld   (ix+4),l
           ld   (ix+5),h
           pop  hl
           inc  hl
           inc  hl            ; hl = y index
           ld   e,(hl)
           inc  hl
           ld   d,(hl)        ; de = point3
           ld   hl,(y1)       ; hl = y1
           add  hl,de         ; hl = y1 + point3
           ld   (ix+6),l
           ld   (ix+7),h
           ; -- update point 1
           ld   h,0
           ld   l,a
           ld   de,point1
           add  hl,de         ; hl = x index
           push hl
           ld   e,(hl)
           inc  hl
           ld   d,(hl)        ; de = point1
           ld   hl,(x1)       ; hl = x1
           add  hl,de         ; hl = x1 + point1
           ld   (ix+8),l
           ld   (ix+9),h
           pop  hl
           inc  hl
           inc  hl            ; hl = y index
           ld   e,(hl)
           inc  hl
           ld   d,(hl)        ; de = point1
           ld   hl,(y1)       ; hl = y1
           add  hl,de         ; hl = y1 + point1
           ld   (ix+10),l
           ld   (ix+11),h
           ; -- update point 2
           ld   h,0
           ld   l,a
           ld   de,point2
           add  hl,de         ; hl = x index
           push hl
           ld   e,(hl)
           inc  hl
           ld   d,(hl)        ; de = point2
           ld   hl,(x1)       ; hl = x1
           add  hl,de         ; hl = x1 + point2
           ld   (ix+12),l
           ld   (ix+13),h
           pop  hl
           inc  hl
           inc  hl            ; hl = y index
           ld   e,(hl)
           inc  hl
           ld   d,(hl)        ; de = point2
           ld   hl,(y1)       ; hl = y1
           add  hl,de         ; hl = y1 + point2y
           ld   (ix+14),l
           ld   (ix+15),h

           ;---------------------------
           ; rotate tail for ship 1
           ;---------------------------

           ; -- update point 3
           ld   h,0
           ld   l,a
           ld   de,point3
           add  hl,de         ; hl = x index
           push hl
           ld   e,(hl)
           inc  hl
           ld   d,(hl)        ; de = point3
           ld   hl,(x1)       ; hl = x1
           add  hl,de         ; hl = x1 + point3
           ld   (ix+20),l
           ld   (ix+21),h
           pop  hl
           inc  hl
           inc  hl            ; hl = y index
           ld   e,(hl)
           inc  hl
           ld   d,(hl)        ; de = point3
           ld   hl,(y1)       ; hl = y1
           add  hl,de         ; hl = y1 + point3
           ld   (ix+22),l
           ld   (ix+23),h
           ; -- update point 4
           ld   h,0
           ld   l,a
           ld   de,point4
           add  hl,de         ; hl = x index
           push hl
           ld   e,(hl)
           inc  hl
           ld   d,(hl)        ; de = point4
           ld   hl,(x1)       ; hl = x1
           add  hl,de         ; hl = x1 + point4
           ld   (ix+24),l
           ld   (ix+25),h
           pop  hl
           inc  hl
           inc  hl            ; hl = y index
           ld   e,(hl)
           inc  hl
           ld   d,(hl)        ; de = point4
           ld   hl,(y1)       ; hl = y1
           add  hl,de         ; hl = y1 + point4
           ld   (ix+26),l
           ld   (ix+27),h
           ret

;-------------------------------------------------------
; rotate ship 2  (wedge)
; plot order: point0 -> point1 -> point2 -> point0
;-------------------------------------------------------
rotate2:   ld   ix,ship2
           ld   a,(theta2)
           sla  a             ; angle index * 4
           sla  a
           ; -- update point 0
           ld   hl,(x2)       ; hl = x2
           ld   (ix),l
           ld   (ix+1),h
           ld   hl,(y2)       ; hl = y2
           ld   (ix+2),l
           ld   (ix+3),h
           ; -- update point 1
           ld   h,0
           ld   l,a
           ld   de,point1
           add  hl,de         ; hl = x index
           push hl
           ld   e,(hl)
           inc  hl
           ld   d,(hl)        ; de = point1
           ld   hl,(x2)       ; hl = x2
           add  hl,de         ; hl = x2 + point1
           ld   (ix+4),l
           ld   (ix+5),h
           pop  hl
           inc  hl
           inc  hl            ; hl = y index
           ld   e,(hl)
           inc  hl
           ld   d,(hl)        ; de = point1
           ld   hl,(y2)       ; hl = y2
           add  hl,de         ; hl = y2 + point1
           ld   (ix+6),l
           ld   (ix+7),h
           ; -- update point 2
           ld   h,0
           ld   l,a
           ld   de,point2
           add  hl,de         ; hl = x index
           push hl
           ld   e,(hl)
           inc  hl
           ld   d,(hl)        ; de = point2
           ld   hl,(x2)       ; hl = x2
           add  hl,de         ; hl = x2 + point2
           ld   (ix+8),l
           ld   (ix+9),h
           pop  hl
           inc  hl
           inc  hl            ; hl = y index
           ld   e,(hl)
           inc  hl
           ld   d,(hl)        ; de = point2
           ld   hl,(y2)       ; hl = y2
           add  hl,de         ; hl = y2 + point2
           ld   (ix+10),l
           ld   (ix+11),h
           ; -- update point 0
           ld   hl,(x2)       ; hl = x2
           ld   (ix+12),l
           ld   (ix+13),h
           ld   hl,(y2)       ; hl = y2
           ld   (ix+14),l
           ld   (ix+15),h

           ;---------------------------
           ; rotate tail for ship 2
           ;---------------------------

           ; -- update point 3
           ld   h,0
           ld   l,a
           ld   de,point3
           add  hl,de         ; hl = x index
           push hl
           ld   e,(hl)
           inc  hl
           ld   d,(hl)        ; de = point3
           ld   hl,(x2)       ; hl = x2
           add  hl,de         ; hl = x2 + point3
           ld   (ix+20),l
           ld   (ix+21),h
           pop  hl
           inc  hl
           inc  hl            ; hl = y index
           ld   e,(hl)
           inc  hl
           ld   d,(hl)        ; de = point3
           ld   hl,(y2)       ; hl = y2
           add  hl,de         ; hl = y2 + point3
           ld   (ix+22),l
           ld   (ix+23),h
           ; -- update point 4
           ld   h,0
           ld   l,a
           ld   de,point4
           add  hl,de         ; hl = x index
           push hl
           ld   e,(hl)
           inc  hl
           ld   d,(hl)        ; de = point4
           ld   hl,(x2)       ; hl = x2
           add  hl,de         ; hl = x2 + point4
           ld   (ix+24),l
           ld   (ix+25),h
           pop  hl
           inc  hl
           inc  hl            ; hl = y index
           ld   e,(hl)
           inc  hl
           ld   d,(hl)        ; de = point4
           ld   hl,(y2)       ; hl = y2
           add  hl,de         ; hl = y2 + point4
           ld   (ix+26),l
           ld   (ix+27),h
           ret

;-------------------------------------------------------
; plot ship data
;-------------------------------------------------------
plotsx1:   ld   a,(hit1)
           or   a             ; plot explosion
           jp   nz,plotboom
           ld   ix,ship1      ; ship plot data
           jp   plot

plotsx2:   ld   a,(hit2)
           or   a             ; plot explosion
           jp   nz,plotboom
           ld   ix,ship2      ; ship plot data
           jp   plot

;-------------------------------------------------------
; plot tail data (when thruster is on)
;-------------------------------------------------------
plottx1:   ld   a,(thrust1)   ; is thrust on?
           bit  0,a
           ret  z             ; skip if not on
           ld   ix,tail1      ; tail plot data
           jp   plot

plottx2:   ld   a,(thrust2)   ; is thrust on?
           bit  0,a
           ret  z             ; skip if not on
           ld   ix,tail2      ; tail plot data
           jp   plot

;-------------------------------------------------------
; plot torpedo data
;-------------------------------------------------------
plottp1:   ld   a,(tlife1a)   ; is torpedo 1a active?
           or   a
           ret  z             ; skip if not active
           ld   ix,torp1a     ; else plot data
           call plot
           ld   a,(tlife1b)   ; is torpedo 1b active?
           or   a
           ret  z             ; skip if not active
           ld   ix,torp1b     ; else plot data
           call plot
           ld   a,(tlife1c)   ; is torpedo 1c active?
           or   a
           ret  z             ; skip if not active
           ld   ix,torp1c     ; else plot data
           jr   plot

plottp2:   ld   a,(tlife2a)   ; is torpedo 2a active?
           or   a
           ret  z             ; skip if not active
           ld   ix,torp2a     ; else plot data
           call plot
           ld   a,(tlife2b)   ; is torpedo 2b active?
           or   a
           ret  z             ; skip if not active
           ld   ix,torp2b     ; else plot data
           call plot
           ld   a,(tlife2c)   ; is torpedo 2c active?
           or   a
           ret  z             ; skip if not active
           ld   ix,torp2c     ; else plot data
           jr   plot

;-------------------------------------------------------
; plot explosion
;-------------------------------------------------------
plotboom:  ld   a,(endboom+1)
           cp   boomtime      ; c set if a < boomtime
           ret  nc
           ld   b,a
           ld   a,(endboom)
           ld   c,a
           inc  bc
           ld   a,c
           ld   (endboom),a
           ld   a,b
           ld   (endboom+1),a
           ld   ix,xplode     ; explosion plot data
           jr   plot

;-------------------------------------------------------
; plot central star
;-------------------------------------------------------
plotstar:  ld   ix,cstar      ; central star plot data

;-------------------------------------------------------
; plot cartesian data
;-------------------------------------------------------
plot:      ld   (hl),tgs
           inc  hl
plot1:     ld   a,(ix+3)      ; y data
           ld   d,a
           ld   a,(ix+2)
           ld   e,a
           or   d
           jp   z,plot2       ; done if data = 0
           call teky
           ld   a,(ix+1)      ; x data
           ld   d,a
           ld   a,(ix)
           ld   e,a
           call tekx
           ld   de,4
           add  ix,de
           jr   plot1
plot2:     ret

termdata:  ld   a,cr          ; cr terminate
           ld   (hl),a
           ret

;-------------------------------------------------------
; tekx and teky
;
; These routines take a 10-bit quantity in de,
; convert it to tektronix 40xx coordinates, and writes
; the two resulting bytes the buffer pointed to by hl
; This conversion algorithm is described in the Tek4010
; Users Manual (Rev B, July 1975) on page 3-8
; Note: registers a,c, and hl are overwritten
;-------------------------------------------------------
tekx:      ld   b,40h
           jr   tekxy

teky:      ld   b,60h

tekxy:     ld   a,d
           and  3
           ld   d,a
           ld   a,e
           and  0e0h      ; mask off low data
           or   d
           rlca
           rlca
           rlca
           or   20h       ; high data tag (01)
           ld   (hl),a
           inc  hl
           ld   a,e
           and  01fh
           or   b         ; low data tag
           ld   (hl),a
           inc  hl
           ret

;-------------------------------------------------------
; multiply hl = h * e
;   h must be positive; e can be negative
;   hl is the 16-bit product
;-------------------------------------------------------
mul:       xor  a
           bit  7,e       ; check sign
           jr   z,mul1    ; jump if positive
           cpl            ; negative sign
mul1:      ld   d,a
           ld   a,h
           ld   hl,0
           ld   b,8       ; iteration count
mullp:     add  hl,hl
           sla  a
           jr   nc,mul3
           add  hl,de
mul3:      djnz mullp
           ret

;-------------------------------------------------------
; sine routine
; called with input angle in a
; returns sine in e
;-------------------------------------------------------
sin:       push hl
           ld   e,a           ; de = table offset
           xor  a
           ld   d,a
           ld   hl,sintab
           add  hl,de
           ld   e,(hl)        ; e = sin(theta)
           pop  hl
           ret

;-------------------------------------------------------
; cosine routine
; called with input angle in a
; returns cosine in e
;-------------------------------------------------------
cos:       push hl
           ld   e,a           ; de = table offset
           xor  a
           ld   d,a
           ld   hl,costab
           add  hl,de
           ld   e,(hl)        ; e = cos(theta)
           pop  hl
           ret

;-------------------------------------------------------
; Initialize the UART
; modifies register a
;-------------------------------------------------------
inituart:  ld   a,3           ; enable tx and rx
           out  (uartcntl),a
           ret

;---------------------------------------------------
; Initialize timer 1
; modifies register a
;---------------------------------------------------
inittm1:   ld   a,9           ; 1 msec resolution
           out  (tmr1cntl),a  ; count up mode
           ret

;---------------------------------------------------
; Initialize timer 2
; modifies register a
;---------------------------------------------------
inittm2:   ld   a,9           ; 10 msec resolution
           out  (tmr2cntl),a  ; count up mode
           ret

;---------------------------------------------------
; Start timer 1
; modifies register a
;---------------------------------------------------
strttm1:   out  (tmr1clr),a   ; clear the count
           in   a,(tmr1cntl)  ; read control
           or   1             ; enable bit
           out  (tmr1cntl),a  ; start timer
           ret

;---------------------------------------------------
; Start timer 2
; modifies register a
;---------------------------------------------------
strttm2:   out  (tmr2clr),a   ; clear the count
           in   a,(tmr2cntl)  ; read control
           or   1             ; enable bit
           out  (tmr2cntl),a  ; start timer
           ret

;---------------------------------------------------
; Stop timer 1
; modifies register a
;---------------------------------------------------
stoptm1:   in   a,(tmr1cntl)  ; read control
           and  0feh          ; disable bit
           out  (tmr1cntl),a  ; stop timer
           ret

;---------------------------------------------------
; Stop timer 2
; modifies register a
;---------------------------------------------------
stoptm2:   in   a,(tmr2cntl)  ; read control
           and  0feh          ; disable bit
           out  (tmr2cntl),a  ; stop timer
           ret

           IF   simode        ; sim-mode condition

;-------------------------------------------------------
; DUMMY routine  (1 of 3)
;-------------------------------------------------------
getkey:    nop
           ret

;-------------------------------------------------------
; DUMMY routine  (2 of 3)
;-------------------------------------------------------
putc:      nop
           ret

;---------------------------------------------------
; DUMMY routine  (3 of 3)
;---------------------------------------------------
initbuf:   nop
           ret

           ELSE               ; sim-mode condition

;-------------------------------------------------------
; check keyboard input
;-------------------------------------------------------
getkey:    in   a,(uartstat)  ; get uart status
           and  rxempty       ; set z if has data
           ret  nz            ; return if no data
           in   a,(uartdata)  ; else get a char
           cp   ctrlc         ; set z if control-c
           jp   z,leave       ; exit program

           ld   hl,theta1     ; check ship 1 buttons
           cp   rccw1
           jr   z,rotccw      ; rotate ship1 ccw
           cp   rxcw1
           jr   z,rotcw       ; rotate ship1 cw
           cp   thrx1
           jr   z,boost1      ; activate thruster 1
           cp   ftpd1
           jp   z,fire1a      ; fire torpedo 1

           ld   hl,theta2     ; check ship 2 buttons
           cp   rccw2
           jr   z,rotccw      ; rotate ship 2 ccw
           cp   rxcw2
           jr   z,rotcw       ; rotate ship 2 cw
           cp   thrx2
           jr   z,boost2      ; activate thruster 2
           cp   ftpd2
           jp   z,fire2a      ; fire torpedo 2
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

;---------------------------------------------------
; Initialize buffer
;---------------------------------------------------
initbuf:   xor  a
           ld   b,bufsize
initbf2:   ld   (hl),a
           djnz initbf2
           ret

           ENDIF              ; sim-mode condition

;-------------------------------------------------------
; Control key routines
;-------------------------------------------------------

rotccw:    ld   a,(hl)
           inc  a             ; ccw rotate
           and  1fh           ; restrict range
           ld   (hl),a        ; to 1-15
           ret

rotcw:     ld   a,(hl)
           dec  a             ; cw rotate
           and  1fh           ; restrict range
           ld   (hl),a        ; to 1-15
           ret

boost1:    ld   hl,thrust1
           inc  (hl)
           inc  hl            ; toggle thruster 1
           ld   (hl),1        ; set speed=1
           call strttm1       ; start timer 1
           ret

boost2:    ld   hl,thrust2
           inc  (hl)
           inc  hl            ; toggle thruster 2
           ld   (hl),1        ; set speed=1
           call strttm2       ; start timer 2
           ret

fire1a:    ld   hl,tlife1a    ; check torpedo 1a
           ld   a,(hl)        ; lifetime and
           or   a             ; skip if torpedo
           jp   nz,fire1b     ; already active
           ld   (hl),tpnew    ; else new torpedo
           ret
fire1b:    ld   hl,tlife1b    ; check torpedo 1b
           ld   a,(hl)        ; lifetime and
           or   a             ; skip if torpedo
           jp   nz,fire1c     ; already active
           ld   (hl),tpnew    ; else new torpedo
           ret
fire1c:    ld   hl,tlife1c    ; check torpedo 1c
           ld   a,(hl)        ; lifetime and
           or   a             ; skip if torpedo
           ret  nz            ; already active
           ld   (hl),tpnew    ; else new torpedo
           ret

fire2a:    ld   hl,tlife2a    ; check torpedo 2a
           ld   a,(hl)        ; lifetime and
           or   a             ; skip if torpedo
           jp   nz,fire2b     ; already active
           ld   (hl),tpnew    ; else new torpedo
           ret
fire2b:    ld   hl,tlife2b    ; check torpedo 2b
           ld   a,(hl)        ; lifetime and
           or   a             ; skip if torpedo
           jp   nz,fire2c     ; already active
           ld   (hl),tpnew    ; else new torpedo
           ret
fire2c:    ld   hl,tlife2c    ; check torpedo 2c
           ld   a,(hl)        ; lifetime and
           or   a             ; skip if torpedo
           ret  nz            ; already active
           ld   (hl),tpnew    ; else new torpedo
           ret

leave:     di
           pop  af            ; cleanup the stack
           ld   a,tus         ; switch back to
           call putc          ; text mode
           call stoptm1       ; stop timer 1
           call stoptm2       ; stop timer 2
           jp   cmdloop       ; exit to monitor

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

;---------------------------------------------------
; Initialize buf1 and buf2
;---------------------------------------------------
initbufx:  ld   hl,buf1
           call initbuf
           ld   hl,buf2
           call initbuf
           ret

;---------------------------------------------------
; Initialize variables
;---------------------------------------------------
initvars:  xor  a
           ld   b,zvar2-zvar1
           ld   hl,zvar1      ; init these vars
ivars2:    ld   (hl),a        ; to zero
           inc  hl
           djnz ivars2
           ld   hl,initx1     ; init ship 1 x
           ld   (x1),hl
           ld   hl,inity1     ; init ship 1 y
           ld   (y1),hl
           ld   hl,initx2     ; init ship 2 x
           ld   (x2),hl
           ld   hl,inity2     ; init ship 2 y
           ld   (y2),hl
           ret

;---------------------------------------------------
; Compare buf1 and buf2
;---------------------------------------------------
cmprbuf:   ld   b,bufsize
           ld   hl,buf1
           ld   de,buf2
cmprbf2:   ld   a,(hl)
           ld   c,a
           ld   a,(de)
           cp   c             ; same?
           ret  nz
           cp   cr            ; end of data?
           ret  z
           inc  hl
           inc  de
           djnz cmprbf2
           ret

;---------------------------------------------------
; Copy buf1 to buf2
;---------------------------------------------------
copybuf:   ld   b,bufsize
           ld   hl,buf1
           ld   de,buf2
copybf2:   ld   a,(hl)
           ld   (de),a
           inc  hl
           inc  de
           djnz copybf2
           ret

;-------------------------------------------------------
; Send tek 40xx data to the UART
; pointer to string is in register hl
; strings are terminated with carriage return (0dh)
; modifies registers a, and hl
;-------------------------------------------------------
putbuf:    ld   a,esc
           call putc          ; clear the screen
           ld   a,ff
           call putc
           ld   hl,buf1       ; send xy data
putbf0:    ld   a,(hl)
           cp   cr            ; carriage return?
           jr   z,putbf1
           call putc          ; send a character
           inc  hl
           jr   putbf0
putbf1:    ld   hl,movcur     ; move the cursor
           call puts          ; out of the way
           ret

;-------------------------------------------------------
; absolute value of hl
;-------------------------------------------------------
abs:       bit  7,h
           ret  z
           xor  a
           sub  l
           ld   l,a
           sbc  a,a
           sub  h
           ld   h,a
           ret

;-------------------------------------------------------
; end of subroutines
;-------------------------------------------------------

;-------------------------------------------------------
; x820 address definitions
;-------------------------------------------------------

cmdloop    equ  08h           ; monitor warm start
siovec     equ  0ch           ; uart    isr address
tm1vec     equ  0fh           ; timer 1 isr address
tm2vec     equ  12h           ; timer 2 isr address
tos        equ  0ff00h        ; top of stack

;-------------------------------------------------------
; x820 register definitions
;-------------------------------------------------------

uartcntl   equ  00h           ; UART control
uartstat   equ  01h           ; UART status
uartdata   equ  02h           ; UART data

tmr1cntl   equ  08h           ; timer 1 control
tmr1icl    equ  09h           ; initial count low
tmr1ich    equ  0ah           ; initial count high
tmr1clr    equ  0bh           ; clear count

tmr2cntl   equ  0ch           ; timer 2 control
tmr2icl    equ  0dh           ; initial count low
tmr2ich    equ  0eh           ; initial count high
tmr2clr    equ  0fh           ; clear count

;-------------------------------------------------------
; x820 register bit definitions
;-------------------------------------------------------

txempty    equ  08h           ; tx fifo is empty
txfull     equ  04h           ; tx fifo is full
rxfull     equ  02h           ; rx fifo is full
rxempty    equ  01h           ; rx fifo is empty

;-------------------------------------------------------
; ascii character aliases
;-------------------------------------------------------

cr         equ  0dh           ; carriage return
lf         equ  0ah           ; linefeed
ff         equ  0ch           ; formfeed
esc        equ  1bh           ; escape
tus        equ  1fh           ; Tek 40xx text mode
tgs        equ  1dh           ; Tek 40xx graphics mode
ctrlc      equ  03h           ; control-c

;-------------------------------------------------------
; ship control characters
;-------------------------------------------------------

rccw1      equ  'a'           ; rotate ship 1 ccw
rxcw1      equ  's'           ; rotate ship 1 cw
thrx1      equ  'd'           ; activate thruster 1
ftpd1      equ  'f'           ; fire torpedo 1

rccw2      equ  'h'           ; rotate ship 2 ccw
rxcw2      equ  'j'           ; rotate ship 2 cw
thrx2      equ  'k'           ; activate thruster 2
ftpd2      equ  'l'           ; fire torpedo 2

;-------------------------------------------------------
; global equates
;-------------------------------------------------------

bufsize    equ  155           ; buffer size
tspeed     equ  09h           ; torpedo speed
tpnew      equ  0eh           ; torpedo lifetime
tdelta     equ  7fh           ; torpedo delta

;-------------------------------------------------------
; initial ship locations
;-------------------------------------------------------

initx1     equ  150           ; init ship 1 x
inity1     equ  150           ; init ship 1 y
initx2     equ  875           ; init ship 2 x
inity2     equ  640           ; init ship 2 y
starx      equ  512           ; central star x
stary      equ  395           ; central star y

;-------------------------------------------------------
; variable storage
;-------------------------------------------------------

buf1       ds   bufsize
buf2       ds   bufsize

savesp     dw   0

zvar1      equ  $
tlife1a    db   0             ; torpedo life  1a
tlife1b    db   0             ; torpedo life  1b
tlife1c    db   0             ; torpedo life  1c
tlife2a    db   0             ; torpedo life  2a
tlife2b    db   0             ; torpedo life  2b
tlife2c    db   0             ; torpedo life  2c
tpang1a    db   0             ; torpedo angle 1a
tpang1b    db   0             ; torpedo angle 1b
tpang1c    db   0             ; torpedo angle 1c
tpang2a    db   0             ; torpedo angle 2a
tpang2b    db   0             ; torpedo angle 2b
tpang2c    db   0             ; torpedo angle 2c
hit1       db   0             ; is ship 1 hit?
hit2       db   0             ; is ship 2 hit?
endboom    dw   0             ; end of explosion
thrust1    db   0             ; ship 1 thrust
speed1     db   0             ; ship 1 velocity
thrust2    db   0             ; ship 2 thrust
speed2     db   0             ; ship 2 velocity
theta1     db   0             ; ship 1 angle
theta2     db   0             ; ship 2 angle
zvar2      equ  $
x1         dw   0             ; ship 1 x
y1         dw   0             ; ship 1 y
x2         dw   0             ; ship 2 x
y2         dw   0             ; ship 2 y
zvar3      equ  $

;-------------------------------------------------------
; dimensions
;-------------------------------------------------------

ray        equ   8            ; for central star
ray2       equ   4            ; for central star
ray3       equ  12            ; for explosion
hrad       equ  17            ; torpedo hit radius
boomtime   equ  160           ; explosion duration

;-------------------------------------------------------
; torpedo codes
;-------------------------------------------------------

tp1a       equ  0             ; torpedo 1a
tp1b       equ  1             ; torpedo 1b
tp1c       equ  2             ; torpedo 1c
tp2a       equ  4             ; torpedo 2a
tp2b       equ  5             ; torpedo 2b
tp2c       equ  6             ; torpedo 2c

;-------------------------------------------------------
; Cartesian plot data
;-------------------------------------------------------

ship1      dw 0,0
           dw 0,0
           dw 0,0
           dw 0,0
           dw 0,0

tail1      dw 0,0
           dw 0,0
           dw 0,0

ship2      dw 0,0
           dw 0,0
           dw 0,0
           dw 0,0
           dw 0,0

tail2      dw 0,0
           dw 0,0
           dw 0,0

torp1a     dw 0,0
           dw 0,0
           dw 0,0
           dw 0,0

torp1b     dw 0,0
           dw 0,0
           dw 0,0
           dw 0,0

torp1c     dw 0,0
           dw 0,0
           dw 0,0
           dw 0,0

torp2a     dw 0,0
           dw 0,0
           dw 0,0
           dw 0,0

torp2b     dw 0,0
           dw 0,0
           dw 0,0
           dw 0,0

torp2c     dw 0,0
           dw 0,0
           dw 0,0
           dw 0,0

xplode     dw 0,0
           dw 0,0
           dw 0,0
           dw 0,0
           dw 0,0
           dw 0,0
           dw 0,0
           dw 0,0
           dw 0,0
           dw 0,0
           dw 0,0
           dw 0,0
           dw 0,0

cstar      dw starx,      stary
           dw starx+ray,  stary
           dw starx-ray,  stary
           dw starx,      stary
           dw starx,      stary+ray
           dw starx,      stary-ray
           dw starx,      stary
           dw starx+ray2, stary+ray2
           dw starx-ray2, stary-ray2
           dw starx,      stary
           dw starx-ray2, stary+ray2
           dw starx+ray2, stary-ray2
           dw 0,0

movcur     db tgs,3fh,7fh,3fh,5fh,0


;-------------------------------------------------------
; ship point rotate (x,y) tables
;-------------------------------------------------------

           ; Point 1 is the lower left point
point1     dw 0fff6h,0ffe2h,0fffdh,0ffe1h
           dw 00002h,0ffe1h,00008h,0ffe2h
           dw 0000eh,0ffe4h,00013h,0ffe8h
           dw 00017h,0ffech,0001bh,0fff1h
           dw 0001dh,0fff6h,0001fh,0fffdh
           dw 0001fh,00002h,0001eh,00008h
           dw 0001ch,0000eh,00018h,00013h
           dw 00014h,00017h,0000fh,0001bh
           dw 0000ah,0001dh,00003h,0001fh
           dw 0fffeh,0001fh,0fff8h,0001eh
           dw 0fff2h,0001ch,0ffedh,00018h
           dw 0ffe9h,00014h,0ffe5h,0000fh
           dw 0ffe3h,0000ah,0ffe1h,00003h
           dw 0ffe1h,0fffeh,0ffe2h,0fff8h
           dw 0ffe4h,0fff2h,0ffe8h,0ffedh
           dw 0ffech,0ffe9h,0fff1h,0ffe5h

           ; Point 2 is the lower right point
point2     dw 0000ah,0ffe2h,0000fh,0ffe5h
           dw 00014h,0ffe9h,00018h,0ffedh
           dw 0001ch,0fff2h,0001eh,0fff8h
           dw 0001fh,0fffeh,0001fh,00003h
           dw 0001eh,00009h,0001bh,0000fh
           dw 00017h,00014h,00013h,00018h
           dw 0000eh,0001ch,00008h,0001eh
           dw 00002h,0001fh,0fffdh,0001fh
           dw 0fff7h,0001eh,0fff1h,0001bh
           dw 0ffech,00017h,0ffe8h,00013h
           dw 0ffe4h,0000eh,0ffe2h,00008h
           dw 0ffe1h,00002h,0ffe1h,0fffdh
           dw 0ffe2h,0fff7h,0ffe5h,0fff1h
           dw 0ffe9h,0ffech,0ffedh,0ffe8h
           dw 0fff2h,0ffe4h,0fff8h,0ffe2h
           dw 0fffeh,0ffe1h,00003h,0ffe1h

           ; Point 3 is between 1 and 2
point3     dw 00000h,0ffe2h,00005h,0ffe3h
           dw 0000bh,0ffe5h,00010h,0ffe8h
           dw 00015h,0ffebh,00018h,0fff0h
           dw 0001bh,0fff5h,0001dh,0fffbh
           dw 0001eh,00000h,0001dh,00005h
           dw 0001bh,0000bh,00018h,00010h
           dw 00015h,00015h,00010h,00018h
           dw 0000bh,0001bh,00005h,0001dh
           dw 00000h,0001eh,0fffbh,0001dh
           dw 0fff5h,0001bh,0fff0h,00018h
           dw 0ffebh,00015h,0ffe8h,00010h
           dw 0ffe5h,0000bh,0ffe3h,00005h
           dw 0ffe2h,00000h,0ffe3h,0fffbh
           dw 0ffe5h,0fff5h,0ffe8h,0fff0h
           dw 0ffebh,0ffebh,0fff0h,0ffe8h
           dw 0fff5h,0ffe5h,0fffbh,0ffe3h


           ; Point 4 is for flame effect
point4     dw 00000h,0ffd8h,00007h,0ffd9h
           dw 0000fh,0ffdch,00016h,0ffdfh
           dw 0001ch,0ffe4h,00021h,0ffeah
           dw 00024h,0fff1h,00027h,0fff9h
           dw 00028h,00000h,00027h,00007h
           dw 00024h,0000fh,00021h,00016h
           dw 0001ch,0001ch,00016h,00021h
           dw 0000fh,00024h,00007h,00027h
           dw 00000h,00028h,0fff9h,00027h
           dw 0fff1h,00024h,0ffeah,00021h
           dw 0ffe4h,0001ch,0ffdfh,00016h
           dw 0ffdch,0000fh,0ffd9h,00007h
           dw 0ffd8h,00000h,0ffd9h,0fff9h
           dw 0ffdch,0fff1h,0ffdfh,0ffeah
           dw 0ffe4h,0ffe4h,0ffeah,0ffdfh
           dw 0fff1h,0ffdch,0fff9h,0ffd9h

;-------------------------------------------------------
; sine and cosine tables
;-------------------------------------------------------

costab     db   000h,0e8h,0d0h,0b9h,0a6h,096h,08ah,083h
           db   080h,083h,08ah,096h,0a6h,0b9h,0d0h,0e8h
           db   000h,018h,030h,047h,05ah,06ah,076h,07dh
           db   07fh,07dh,076h,06ah,05ah,047h,030h,018h

sintab     db   07fh,07dh,076h,06ah,05ah,047h,030h,018h
           db   000h,0e8h,0d0h,0b9h,0a6h,096h,08ah,083h
           db   080h,083h,08ah,096h,0a6h,0b9h,0d0h,0e8h
           db   000h,018h,030h,047h,05ah,06ah,076h,07dh

           end

