
;=======================================================
; 99 Bottles of Beer :: A silly demo program that uses
; CP/M BDOS calls to print strings. The original 8080
; code was written by Elroy Sullivan and Barry Goode.
; It was translated to z80 assembly by Scott L. Baker
;=======================================================

           org  100h

botloop:   ld   de,cnts       ; Load ASCII number address
           ld   a,(cntn)      ; Load number of bottles to A
           sbc  a,10          ; Set carry if less than 10
           jr   nc,jp1        ; > 9 so print both digits
           inc  de            ; Inc DE to skip high digit
jp1:       ld   c,xprint
           call bdos

           ; >>>>>> bottles of beer on the wall,
           ld   de,str1
           ld   c,xprint
           call bdos
           ; >>>>>> xx
           ld   de,cnts       ; Load ASCII number address
           ld   a,(cntn)      ; Load number of bottles to A
           sbc  a,10          ; Set carry flag if less than 10
           jr   nc,jp2        ; > 9 so print both digits
           inc  de            ; Inc DE to skip high digit
jp2:       ld   c,xprint
           call bdos
           ; >>>>>> bottles of beer
           ld   de,str2
           ld   c,xprint
           call bdos
           ; >>>>>> CR/LF
           ld   de,crlf
           ld   c,xprint
           call bdos
           ; >>>>>> Take one down, pass it around,
           ld   de,str3
           ld   c,xprint
           call bdos

           ; Decrement our bottle counter

           ld   a,(cntn)      ; Load number of bottles to A
           dec  a             ; Decrease bottles
           ld   (cntn),a      ; Save number of bottles from A

           ; See if we're done

           cp   1             ; Make sure the zero flag is correct
           jr   z,lastbotl    ; See if there's only one more bottle

           ; Patch up the counter string

           ld   hl,cnts       ; address of counter ptr in HL
           ex   de,hl         ; Swap DE and HL
           ld   hl,ascn       ; Put address of table in HL
           ld   b,0           ; Zero the B (high) register
           ld   c,a           ; Put bottles into C (low)
           add  hl,bc         ; Creates table ptr
           add  hl,bc         ; 2 chars per table entry
           ld   b,(hl)        ; Put first char from table into B
           ex   de,hl         ; Swap DE and HL
           ld   (hl),b        ; Copy first char to string
           inc  hl            ; Inc counter ptr
           ex   de,hl         ; Swap DE and HL
           inc  hl            ; Inc table ptr
           ld   b,(hl)        ; Put second ASCII char in B
           ex   de,hl         ; Swap DE and HL
           ld   (hl),b        ; Copy second char to string

           ; Print out remainder of second line

           ; >>>>>> xx
           ld   de,cnts       ; Load ASCII number address
           ld   a,(cntn)      ; Load number of bottles to A
           sbc  a,10          ; Set carry flag if less than 10
           jr   nc,jp3        ; Greater than 9 so print both digits
           inc  de            ; Inc DE to skip high digit (space)
jp3:       ld   c,xprint
           call bdos

           ; >>>>>> bottles of beer on the wall
           ld   de,str4
           ld   c,xprint
           call bdos

           ; >>>>>> CR/LF
           ld   de,crlf
           ld   c,xprint
           call bdos

           jp   botloop       ; Loop until done

           ; finish the second line from above

           ; >>>>>> 1 bottle of beer on the wall
lastbotl:  ld   de,end0
           ld   c,xprint
           call bdos
           ; >>>>>> CR/LF
           ld   de,crlf
           ld   c,xprint
           call bdos
           ; >>>>>> 1 bottle of beer on the wall,
           ld   de,end1
           ld   c,xprint
           call bdos
           ; >>>>>> 1 bottle of beer
           ld   de,end2
           ld   c,xprint
           call bdos
           ; >>>>>> CR/LF
           ld   de,crlf
           ld   c,xprint
           call bdos
           ; >>>>>> Take one down, pass it around,
           ld   de,str3
           ld   c,xprint
           call bdos
           ; >>>>>> No more bottles of beer on the wall
           ld   de,end4
           ld   c,xprint
           call bdos
           ; >>>>>> CR/LF
           ld   de,crlf
           ld   c,xprint
           call bdos

           jp   cmdloop       ; Return to monitor


;-------------------------------------------------------
; definitions and storage
;-------------------------------------------------------

bdos       equ  5             ; BDOS address
xprint     equ  9             ; BDOS print function
cmdloop    equ  8             ; monitor warm start

;-------------------------------------------------------
; strings
;-------------------------------------------------------

cntn:      db   99            ; Bottle counter
cnts:      db   '99 $'        ; Bottle counter string

str1:      db   'bottles of beer on the wall, $'
str2:      db   'bottles of beer$'
str3:      db   'Take one down, pass it around, $'
str4:      db   'bottles of beer on the wall',0dh,0ah,'$'

end0:      db   '1 bottle of beer on the wall',0dh,0ah,'$'
end1:      db   '1 bottle of beer on the wall, $'
end2:      db   '1 bottle of beer$'
end4:      db   'no more bottles of beer on the wall',0dh,0ah,'$'

ascn:      db   ' 0 1 2 3 4 5 6 7 8 910111213141516171819'
           db   '2021222324252627282930313233343536373839'
           db   '4041424344454647484950515253545556575859'
           db   '6061626364656667686970717273747576777879'
           db   '8081828384858687888990919293949596979899'

crlf:      db   0dh,0ah,'$'

           end
