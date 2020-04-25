
;=======================================================
;
;               Tiny Basic
;               by Li-Chen Wang
;               circa May, 1976
;               all wrongs reserved
;
;               Modified for x820 demo
;               by Scott L. Baker
;
;=======================================================

;-------------------------------------------------------
;
; zero page subroutines
;
; The 8080/Z80 architecture had a set of rst instructions
; (rst 0 through rst 7) that could be used instead of
; the three byte call instruction for 8 subroutines
; in page 0 thus saving program time and space.
;
; The original Tiny Basic used use rst 0 through rst 7
; for commonly used subroutines. In the X820 project
; by convention programs are loaded at 100h, so it is
; not possible to use this optimization and we
; do not use the rst instructions except for rst 0
; which is used to return to the monitor.
;
;-------------------------------------------------------

           jp   start         ; jump to the begin

           org  100h

start:     ld   sp,stack      ; cold start
           ld   a,0ffh
           jp   init

crlf:      ld   a,0dh         ; crlf

rst2:
outc:
           push af            ; outc or rst 2
           ld   a,(ocsw)      ; print character only
           or   a             ; if ocsw switch is on
           jp   oc2           ; rest of this is at oc2

rst3:
expr:
           call expr2         ; expr or rst 3
           push hl            ; evaluate an expression
           jp   expr1         ; rest of it at expr1
           db   'w'

rst4:
comp:
           ld   a,h           ; comp or rst 4
           cp   d             ; compare hl with de
           ret  nz            ; return correct c and
           ld   a,l           ; z flags
           cp   e             ; but old a is lost
           ret
           db   'an'

rst5:
ignblk:
ss1:       ld   a,(de)        ; ignblk/rst 5
           cp   20h           ; ignore blanks
           ret  nz            ; in text (where de->)
           inc  de            ; and return the first
           jp   ss1           ; non-blank char. in a

rst6:
finish:
           pop  af            ; finish/rst 6
           call fin           ; check end of command
           jp   qwhat         ; print "what?" if wrong
           db   'g'

rst7:
tstv:
           call ignblk        ; tstv or rst 7
           sub  40h           ; test variables
           ret  c             ; c:not a variable
           jp   nz,tv1        ; not "@" array
           inc  de            ; it is the "@" array
           call parn          ;@ should be followed
           add  hl,hl         ; by (expr) as its index
           jp   c,qhow        ; is index too big?
           push de            ; will it overwrite
           ex   de,hl         ; text?
           call size          ; find size of free
           call comp          ; and check that
           jp   c,asorry      ; if so, say "sorry"
           ld   hl,varbgn     ; if not get address
           call subde         ; of @(expr) and put it
           pop  de            ; in hl
           ret                ; c flag is cleared
tv1:       cp   1bh           ; not @, is it a to z?
           ccf                ; if not return c flag
           ret  c
           inc  de            ; if a through z
           ld   hl,varbgn     ; compute address of
           rlca               ; that variable
           add  a,l           ; and return it in hl
           ld   l,a           ; with c flag cleared
           ld   a,0
           adc  a,h
           ld   h,a
           ret

rst1:
tstc:
           ex   (sp),hl       ; tstc or rst 1
           call ignblk        ; ignore blanks and
           cp   (hl)          ; test character
tc1:       inc  hl            ; compare the byte that
           jp   z,tc2         ; follows the rst inst.
           push bc            ; with the text (de->)
           ld   c,(hl)        ; if not =, add the 2nd
           ld   b,0           ; byte that follows the
           add  hl,bc         ; rst to the old pc
           pop  bc            ; i.e., do a relative
           dec  de            ; jump if not =
tc2:       inc  de            ; if =, skip those bytes
           inc  hl            ; and continue
           ex   (sp),hl
           ret

tstnum:    ld   hl,0          ; tstnum
           ld   b,h           ; test if the text is
           call ignblk        ; a number
tn1:       cp   30h           ; if not, return 0 in
           ret  c             ; b and hl
           cp   3ah           ; if numbers, convert
           ret  nc            ; to binary in hl and
           ld   a,0f0h        ; set b to # of digits
           and  h             ; if h>255, there is no
           jp   nz,qhow       ; room for next digit
           inc  b             ; b counts # of digits
           push bc
           ld   b,h           ; hl=10*hl+(new digit)
           ld   c,l
           add  hl,hl         ; where 10* is done by
           add  hl,hl         ; shift and add
           add  hl,bc
           add  hl,hl
           ld   a,(de)        ; and (digit) is from
           inc  de            ; stripping the ascii
           and  0fh           ; code
           add  a,l
           ld   l,a
           ld   a,0
           adc  a,h
           ld   h,a
           pop  bc
           ld   a,(de)        ; do this digit after
           jp   p,tn1         ; digit. s says overflow
qhow:      push de            ; error "how?"
ahow:      ld   de,how
           jp   error
how:       db   'how?'
           db   cr
ok:        db   'OK'
           db   cr
what:      db   'what?'
           db   cr
sorry:     db   'sorry'
           db   cr

;-------------------------------------------------------
;
; The main loop collects the Tiny Basic program and
; stores it in the memory
;
; At start it prints out OK and initializes some
; internal variables then prompts > and reads a line
; If the line starts with a non-zero number, this is
; the line number. The line number and the rest of the
; line including cr is stored memory. If a line with
; the same line number is already there, the it is
; replaced by the new one. If the rest of the line
; consists of a cr only, it is not stored and any
; existing line with the same line number is deleted
;
; After a line is inserted, replaced, or deleted
; the program loops back and asks for another line
; This loop will be terminated when it reads a line
; with zero or no line number and control is
; transfered to direct
;
; Tiny Basic program save area starts at the memory
; location labeled txtbgn and ends at txtend
; We always fill this area starting at txtbgn
; The unfilled portion is pointed by the content
; of a memory location labeled txtunf.
;
; The memory location currnt points to the line number
; that is currently being interpreted. While we are in
; this loop or while we are interpreting a direct
; command (see next section) currnt should point to 0
;
;-------------------------------------------------------

rstart:    ld   sp,stack
st1:       call crlf          ; and jump to here
           ld   de,ok         ; de->string
           sub  a             ; a=0
           call prtstg        ; print string until cr
           ld   hl,st2+1      ; literal 0
           ld   (currnt),hl   ; current->line # = 0
st2:       ld   hl,0
           ld   (lopvar),hl
           ld   (stkgos),hl
st3:       ld   a,3eh         ; prompt '>' and
           call getln         ; read a line
           push de            ; de->end of line
           ld   de,buffer     ; de->beginning of line
           call tstnum        ; test if it is a number
           call ignblk
           ld   a,h           ; hl=value of the # or
           or   l             ; 0 if no # was found
           pop  bc            ; bc->end of line
           jp   z,direct
           dec  de            ; backup de and save
           ld   a,h           ; value of line # there
           ld   (de),a
           dec  de
           ld   a,l
           ld   (de),a
           push bc            ; bc,de->begin, end
           push de
           ld   a,c
           sub  e
           push af            ; a=# of bytes in line
           call fndln         ; find this line in save
           push de            ; area, de->save area
           jp   nz,st4        ; nz:not found, insert
           push de            ; z:found, delete it
           call fndnxt        ; find next line
           ; de->next line
           pop  bc            ; bc->line to be deleted
           ld   hl,(txtunf)   ; hl->unfilled save area
           call mvup          ; move up to delete
           ld   h,b           ; txtunf->unfilled area
           ld   l,c
           ld   (txtunf),hl   ; update
st4:       pop  bc            ; get ready to insert
           ld   hl,(txtunf)   ; but first check if
           pop  af            ; the length of new line
           push hl            ; is 3 (line # and cr)
           cp   3             ; then do not insert
           jp   z,rstart      ; must clear the stack
           add  a,l           ; compute new txtunf
           ld   l,a
           ld   a,0
           adc  a,h
           ld   h,a           ; hl->new unfilled area
           ld   de,txtend     ; check to see if there
           call comp          ; is enough space
           jp   nc,qsorry     ; sorry, no room for it
           ld   (txtunf),hl   ; ok, update txtunf
           pop  de            ; de->old unfilled area
           call mvdown
           pop  de            ; de->begin, hl->end
           pop  hl
           call mvup          ; move new line to save
           jp   st3           ; area

;-------------------------------------------------------
; Execute direct and statement commands.
; Control is transfered to these points via the
; command table lookup code of direct and exec in last
; section. after the command is executed, control is
; transfered to others sections as follows:
;
; for list, new, and stop: go back to rstart
; for run: go execute the first stored line if any, else
; go back to rstart.
; for goto and gosub: go execute the target line.
; for return and next: go back to saved return line.
; for all others: if current -> 0, go to rstart, else
; go execute next command (this is done in finish)
;-------------------------------------------------------

;-------------------------------------------------------
;
; new, stop, run, and  goto
;
; new(cr) sets txtunf to point to txtbgn
; stop(cr) goes back to rstart
; run(cr) finds the first stored line, store its address
; (in current), and start execute it. note that only those
; commands in tab2 are legal for stored program.
;
; there are 3 more entries in run:
; runnxl finds next line, stores its addr. and executes it.
; runtsl stores the address of this line and executes it.
; runsml continues the execution on same line.
;
; goto expr(cr) evaluates the expression, find the target
; line, and jump to runtsl to do it
;-------------------------------------------------------


new:       call endchk        ; new(cr)
           ld   hl,txtbgn
           ld   (txtunf),hl

stop:      call endchk        ; stop(cr)
           jp   rstart

bye:       call endchk        ; run(cr)
           rst  00h

run:       call endchk        ; run(cr)
           ld   de,txtbgn     ; first saved line

runnxl:    ld   hl,0          ; runnxl
           call fndlp         ; find whatever line #
           jp   c,rstart      ; c:passed txtunf, quit

runtsl:    ex   de,hl         ; runtsl
           ld   (currnt),hl   ; set 'current'->line #
           ex   de,hl
           inc  de            ; bump pass line #
           inc  de

runsml:    call chkio         ; runsml
           ld   hl,tab2-1     ; find command in tab2
           jp   exec          ; and execute it

goto:      call expr          ; goto expr
           push de            ; save for error routine
           call endchk        ; must find a cr
           call fndln         ; find the target line
           jp   nz,ahow       ; no such line #
           pop  af            ; clear the push de
           jp   runtsl        ; go do it

;-------------------------------------------------------
;
; list and print
;
; list has two forms:; list(cr) lists all saved lines
; list #(cr) start list at this line number
; you can stop the listing by control c key
;
; print command is print ....; or print ....(cr)
; where .... is a list of expresions, formats, back-
; arrows, and strings. these items are seperated by commas.
;
; a format is a pound sign followed by a number. it controls
; the number of spaces the value of a expresion is going to
; be printed. it stays effective for the rest of the print
; command unless changed by another format. if no format is
; specified, 6 positions will be used.
;
; a string is quoted in a pair of single quotes or a pair of
; double quotes.
;
; a back-arrow means generate a (cr) without (lf)
;
; a (crlf) is generated after the entire list has been
; printed or if the list is a null list. however if the list
; ended with a comma, no (crlf) is generated.
;-------------------------------------------------------

list:      call tstnum        ; test if there is a #
           call endchk        ; if no # we get a 0
           call fndln         ; find this or next line
ls1:       jp   c,rstart      ; c:passed txtunf
           call prtln         ; print the line
           call chkio         ; stop if hit control-c
           call fndlp         ; find next line
           jp   ls1           ; and loop back

print:     ld   c,6           ; c = # of spaces
           call tstc          ; if null list & "
           db   3bh
           db   pr2-$-1
           call crlf          ; give cr-lf and
           jp   runsml        ; continue same line
pr2:       call tstc          ; if null list (cr)
           db   cr
           db   pr0-$-1
           call crlf          ; also give cr-lf and
           jp   runnxl        ; go to next line
pr0:       call tstc          ; else is it format?
           db   '#'
           db   pr1-$-1
           call expr          ; yes, evaluate expr.
           ld   c,l           ; and save it in c
           jp   pr3           ; look for more to print
pr1:       call qtstg         ; or is it a string?
           jp   pr8           ; if not, must be expr.
pr3:       call tstc          ; if ",", go find next
           db   ","
           db   pr6-$-1
           call fin           ; in the list.
           jp   pr0           ; list continues
pr6:       call crlf          ; list ends
           call finish
pr8:       call expr          ; evaluate the expr
           push bc
           call prtnum        ; print the value
           pop  bc
           jp   pr3           ; more to print?

;-------------------------------------------------------
;
; gosub and return
;
; gosub expr; or gosub expr (cr) is like the goto
; command, except that the current text pointer, stack pointer
; etc. are save so that execution can be continued after the
; subroutine return. in order that gosub can be nested
; (and even recursive), the save area must be stacked.
; the stack pointer is saved in stkgos, the old stkgos is
; saved in the stack. if we are in the main routine, stkgos
; is zero (this was done by the main section of the code),
; but we still save it as a flag for no further returns.
;
; return(cr) undos everything that gosub did, and thus
; return the execution to the command after the most recent
; gosub. if stkgos is zero, it indicates that we
; never had a gosub and is thus an error
;-------------------------------------------------------

gosub:     call pusha         ; save the current "for"
           call expr          ; parameters
           push de            ; and text pointer
           call fndln         ; find the target line
           jp   nz,ahow       ; not there. say "how?"
           ld   hl,(currnt)   ; found it, save old
           push hl            ;'currnt' old 'stkgos'
           ld   hl,(stkgos)
           push hl
           ld   hl,0          ; and load new ones
           ld   (lopvar),hl
           add  hl,sp
           ld   (stkgos),hl
           jp   runtsl        ; then run that line
return:    call endchk        ; there must be a cr
           ld   hl,(stkgos)   ; old stack pointer
           ld   a,h           ; 0 means not exist
           or   l
           jp   z,qwhat       ; so, we say: "what?"
           ld   sp,hl         ; else, restore it
           pop  hl
           ld   (stkgos),hl   ; and the old 'stkgos'
           pop  hl
           ld   (currnt),hl   ; and the old 'currnt'
           pop  de            ; old text pointer
           call popa          ; old "for" parameters
           call finish        ; and we are back home

;-------------------------------------------------------
;
; for & next
;
; there are two forms:
;  1) for var=exp1 to exp2 step exp3
;  2) for var=exp1 to exp2
;
; tbi will find the variable var, and set its value to the
; current value of exp1. It also evaluates exp2 and exp3
; and save all these together with the text pointer etc in
; the for save area, which consists of lopvar, lopinc,
; loplmt, lopln, and loppt. If there is already some-
; thing in the save area (this is indicated by a non-zero
; lopvar), then the old save area is saved in the stack
; before the new one overwrites it.
; tbi will then dig in the stack and find out if this same
; variable was used in another currently active for loop.
; If that is the case then the old for loop is deactivated
; (purged from the stack..)
;
; next var serves as the logical end of the for loop
; The control variable var is checked with the lopvar
; If they are not the same, tbi digs in
; the stack to find the right one and purges all those that
; did not match. Either way, tbi then adds the step to
; that variable and check the result with the limit.
; If it is within the limit, control loops back to the
; command following the for. if outside the limit, the
; save area is purged and execution continues.
;-------------------------------------------------------

for:       call pusha         ; save the old save area
           call setval        ; set the control var.
           dec  hl            ; hl is its address
           ld   (lopvar),hl   ; save that
           ld   hl,tab5-1     ; use 'exec' to look
           jp   exec          ; for the word 'to'
fr1:       call expr          ; evaluate the limit
           ld   (loplmt),hl   ; save that
           ld   hl,tab6-1     ; use 'exec' to look
           jp   exec          ; for the word 'step'
fr2:       call expr          ; found it, get step
           jp   fr4
fr3:       ld   hl,1h         ; not found, set to 1
fr4:       ld   (lopinc),hl   ; save that too
fr5:       ld   hl,(currnt)   ; save current line #
           ld   (lopln),hl
           ex   de,hl         ; and text pointer
           ld   (loppt),hl
           ld   bc,0ah        ; dig into stack to
           ld   hl,(lopvar)   ; find 'lopvar'
           ex   de,hl
           ld   h,b
           ld   l,b           ; hl=0 now
           add  hl,sp         ; here is the stack
           db   3eh
fr7:       add  hl,bc         ; each level is 10 deep
           ld   a,(hl)        ; get that old 'lopvar'
           inc  hl
           or   (hl)
           jp   z,fr8         ; 0 says no more in it
           ld   a,(hl)
           dec  hl
           cp   d             ; same as this one?
           jp   nz,fr7
           ld   a,(hl)        ; the other half?
           cp   e
           jp   nz,fr7
           ex   de,hl         ; yes, found one
           ld   hl,0h
           add  hl,sp         ; try to move sp
           ld   b,h
           ld   c,l
           ld   hl,0ah
           add  hl,de
           call mvdown        ; and purge 10 words
           ld   sp,hl         ; in the stack
fr8:       ld   hl,(loppt)    ; job done, restore de
           ex   de,hl
           call finish        ; and continue

next:      call tstv          ; get address of var.
           jp   c,qwhat       ; no variable, "what?"
           ld   (varnxt),hl   ; yes, save it
nx0:       push de            ; save text pointer
           ex   de,hl
           ld   hl,(lopvar)   ; get var. in 'for'
           ld   a,h
           or   l             ; 0 says never had one
           jp   z,awhat       ; so we ask: "what?"
           call comp          ; else we check them
           jp   z,nx3         ; ok, they agree
           pop  de            ; no, let's see
           call popa          ; purge current loop
           ld   hl,(varnxt)   ; and pop one level
           jp   nx0           ; go check again
nx3:       ld   e,(hl)        ; come here when agreed
           inc  hl
           ld   d,(hl)        ; de=value of var.
           ld   hl,(lopinc)
           push hl
           ld   a,h
           xor  d
           ld   a,d
           add  hl,de         ; add one step
           jp   m,nx4
           xor  h
           jp   m,nx5
nx4:       ex   de,hl
           ld   hl,(lopvar)   ; put it back
           ld   (hl),e
           inc  hl
           ld   (hl),d
           ld   hl,(loplmt)   ; hl->limit
           pop  af            ; old hl
           or   a
           jp   p,nx1         ; step > 0
           ex   de,hl         ; step < 0
nx1:       call ckhlde        ; compare with limit
           pop  de            ; restore text pointer
           jp   c,nx2         ; outside limit
           ld   hl,(lopln)    ; within limit, go
           ld   (currnt),hl   ; back to the saved
           ld   hl,(loppt)    ;'currnt' and text
           ex   de,hl         ; pointer
           call finish
nx5:       pop  hl
           pop  de
nx2:       call popa          ; purge this loop
           call finish

;-------------------------------------------------------
;
; rem, if, input, let, and deflt
;
; rem can be followed by anything and is ignored by tbi.
; tbi treats it like an if with a false condition.
;
; if is followed by an expr. as a condition and one or more
; commands (including other ifs) seperated by semi-colons.
; note that the word then is not used. tbi evaluates the
; expr. if it is non-zero, execution continues. if the
; expr. is zero, the commands that follows are ignored and
; execution continues at the next line.
;
; input command is like the print command, and is followed
; by a list of items. if the item is a string in single or
; double quotes, or is a back-arrow, it has the same effect as
; in print. if an item is a variable, this variable name is
; printed out followed by a colon. then tbi waits for an
; expr. to be typed in. the variable is then set to the
; value of this expr. if the variable is proceded by a string
; (again in single or double quotes), the string will be
; printed followed by a colon. tbi then waits for input expr.
; and set the variable to the value of the expr.
;
; if the input expr. is invalid, tbi will print what?,
; how? or sorry and reprint the prompt and redo the input.
; the execution will not terminate unless you type ctrl-c.
; this is handled in inperr.
;
; let is followed by a list of items seperated by commas.
; each item consists of a variable, an equal sign, and an expr.
; tbi evaluates the expr. and set the variable to that value.
; tbi will also handle let command without the word let.
; this is done by deflt.
;-------------------------------------------------------

rem:       ld   hl,0h         ; rem
           db   3eh           ; this is like 'if 0'

iff:       call expr          ; if
           ld   a,h           ; is the expr.=0?
           or   l
           jp   nz,runsml     ; no, continue
           call fndskp        ; yes, skip rest of line
           jp   nc,runtsl     ; and run the next line
           jp   rstart        ; if no next, re-start

inperr:    ld   hl,(stkinp)   ; inperr
           ld   sp,hl         ; restore old sp
           pop  hl            ; and old 'currnt'
           ld   (currnt),hl
           pop  de            ; and old text pointer
           pop  de            ; redo input

input:     ; input
ip1:       push de            ; save in case of error
           call qtstg         ; is next item a string?
           jp   ip2           ; no
           call tstv          ; yes, but followed by a
           jp   c,ip4         ; variable?   no.
           jp   ip3           ; yes.  input variable
ip2:       push de            ; save for 'prtstg'
           call tstv          ; must be variable now
           jp   c,qwhat       ;"what?" it is not?
           ld   a,(de)        ; get ready for 'prtstr'
           ld   c,a
           sub  a
           ld   (de),a
           pop  de
           call prtstg        ; print string as prompt
           ld   a,c           ; restore text
           dec  de
           ld   (de),a
ip3:       push de            ; save text pointer
           ex   de,hl
           ld   hl,(currnt)   ; also save 'currnt'
           push hl
           ld   hl,ip1        ; a negative number
           ld   (currnt),hl   ; as a flag
           ld   hl,0h         ; save sp too
           add  hl,sp
           ld   (stkinp),hl
           push de            ; old hl
           ld   a,3ah         ; print this too
           call getln         ; and get a line
           ld   de,buffer     ; points to buffer
           call expr          ; evaluate input
           nop                ; can be 'call endchk'
           nop
           nop
           pop  de            ; ok, get old hl
           ex   de,hl
           ld   (hl),e        ; save value in var.
           inc  hl
           ld   (hl),d
           pop  hl            ; get old 'currnt'
           ld   (currnt),hl
           pop  de            ; and old text pointer
ip4:       pop  af            ; purge junk in stack
           call tstc          ; is next ch. ','?
           db   ","
           db   ip5-$-1
           jp   ip1           ; yes, more items.
ip5:       call finish

deflt:     ld   a,(de)        ;  deflt
           cp   cr            ; empty line is ok
           jp   z,lt1         ; else it is 'let'

let:       call setval        ; let
           call tstc          ; set value to var.
           db   ","
           db   lt1-$-1
           jp   let           ; item by item
lt1:       call finish        ; until finish

;-------------------------------------------------------
;
; expr
;
; expr evaluates arithmetical or logical expressions.
;    <expr>::<expr2>
;    <expr2><relop><expr2>
; where <relop> is one of the operators in tab8 and the
; result of these operations is 1 if true and 0 if false.
; <expr2>::=(+ or -)<expr3>(+ or -<expr3>)(....)
; where () are optional and (....) are optional repeats.
; <expr3>::=<expr4>(* or /><expr4>)(....)
; <expr4>::=<variable>
;           <function>
;           (<expr>)
; <expr> is recursive so that variable @ can have an <expr>
; as index, functions can have an <expr> as arguments, and
; <expr4> can be an <expr> in paranthese.
;-------------------------------------------------------

expr1:     ld   hl,tab8-1     ; lookup rel.op.
           jp   exec          ; go do it
xp11:      call xp18          ; rel.op.">="
           ret  c             ; no, return hl=0
           ld   l,a           ; yes, return hl=1
           ret
xp12:      call xp18          ; rel.op."#"
           ret  z             ; false, return hl=0
           ld   l,a           ; true, return hl=1
           ret
xp13:      call xp18          ; rel.op.">"
           ret  z             ; false
           ret  c             ; also false, hl=0
           ld   l,a           ; true, hl=1
           ret
xp14:      call xp18          ; rel.op."<="
           ld   l,a           ; set hl=1
           ret  z             ; rel. true, return
           ret  c
           ld   l,h           ; else set hl=0
           ret
xp15:      call xp18          ; rel.op."="
           ret  nz            ; false, return hl=0
           ld   l,a           ; else set hl=1
           ret
xp16:      call xp18          ; rel.op."<"
           ret  nc            ; false, return hl=0
           ld   l,a           ; else set hl=1
           ret
xp17:      pop  hl            ; not .rel.op
           ret                ; return hl=<expr2>
xp18:      ld   a,c           ; subroutine for all
           pop  hl            ; rel.op.'s
           pop  bc
           push hl            ; reverse top of stack
           push bc
           ld   c,a
           call expr2         ; get 2nd <expr2>
           ex   de,hl         ; value in de now
           ex   (sp),hl       ; 1st <expr2> in hl
           call ckhlde        ; compare 1st with 2nd
           pop  de            ; restore text pointer
           ld   hl,0h         ; set hl=0, a=1
           ld   a,1
           ret

expr2:     call tstc          ; negative sign?
           db   '-'
           db   xp21-$-1
           ld   hl,0h         ; yes, fake '0-'
           jp   xp26          ; treat like subtract
xp21:      call tstc          ; positive sign? ignore
           db   '+'
           db   xp22-$-1
xp22:      call expr3         ; 1st <expr3>
xp23:      call tstc          ; add?
           db   '+'
           db   xp25-$-1
           push hl            ; yes, save value
           call expr3         ; get 2nd <expr3>
xp24:      ex   de,hl         ; 2nd in de
           ex   (sp),hl       ; 1st in hl
           ld   a,h           ; compare sign
           xor  d
           ld   a,d
           add  hl,de
           pop  de            ; restore text pointer
           jp   m,xp23        ; 1st and 2nd sign differ
           xor  h             ; 1st and 2nd sign equal
           jp   p,xp23        ; so is result
           jp   qhow          ; else we have overflow
xp25:      call tstc          ; subtract?
           db   '-'
           db   xp42-$-1
xp26:      push hl            ; yes, save 1st <expr3>
           call expr3         ; get 2nd <expr3>
           call chgsgn        ; negate
           jp   xp24          ; and add them

expr3:     call expr4         ; get 1st <expr4>
xp31:      call tstc          ; multiply?
           db   '*'
           db   xp34-$-1
           push hl            ; yes, save 1st
           call expr4         ; and get 2nd <expr4>
           ld   b,0h          ; clear b for sign
           call chksgn        ; check sign
           ex   (sp),hl       ; 1st in hl
           call chksgn        ; check sign of 1st
           ex   de,hl
           ex   (sp),hl
           ld   a,h           ; is hl > 255 ?
           or   a
           jp   z,xp32        ; no
           ld   a,d           ; yes, how about de
           or   d
           ex   de,hl         ; put smaller in hl
           jp   nz,ahow       ; also >, will overflow
xp32:      ld   a,l           ; this is dumb
           ld   hl,0h         ; clear result
           or   a             ; add and count
           jp   z,xp35
xp33:      add  hl,de
           jp   c,ahow        ; overflow
           dec  a
           jp   nz,xp33
           jp   xp35          ; finished
xp34:      call tstc          ; divide?
           db   '/'
           db   xp42-$-1
           push hl            ; yes, save 1st <expr4>
           call expr4         ; and get the second one
           ld   b,0h          ; clear b for sign
           call chksgn        ; check sign of 2nd
           ex   (sp),hl       ; get 1st in hl
           call chksgn        ; check sign of 1st
           ex   de,hl
           ex   (sp),hl
           ex   de,hl
           ld   a,d           ; divide by 0?
           or   e
           jp   z,ahow        ; say "how?"
           push bc            ; else save sign
           call divide        ; use subroutine
           ld   h,b           ; result in hl now
           ld   l,c
           pop  bc            ; get sign back
xp35:      pop  de            ; and text pointer
           ld   a,h           ; hl must be +
           or   a
           jp   m,qhow        ; else it is overflow
           ld   a,b
           or   a
           call m,chgsgn      ; change sign if needed
           jp   xp31          ; look for more terms

expr4:     ld   hl,tab4-1     ; find function in tab4
           jp   exec          ; and go do it
xp40:      call tstv          ; no, not a function
           jp   c,xp41        ; nor a variable
           ld   a,(hl)        ; variable
           inc  hl
           ld   h,(hl)        ; value in hl
           ld   l,a
           ret
xp41:      call tstnum        ; or is it a number
           ld   a,b           ;# of digit
           or   a
           ret  nz            ; ok
parn:      call tstc
           db   '('
           db   xp43-$-1
           call expr          ;"(expr)"
           call tstc
           db   ')'
           db   xp43-$-1
xp42:      ret
xp43:      jp   qwhat         ; else say: "what?"

rnd:       call parn          ; rnd(expr)
           ld   a,h           ; expr must be +
           or   a
           jp   m,qhow
           or   l             ; and non-zero
           jp   z,qhow
           push de            ; save both
           push hl
           ld   hl,(ranpnt)   ; get memory as random
           ld   de,lstrom     ; number
           call comp
           jp   c,ra1         ; wrap around if last
           ld   hl,start
ra1:       ld   e,(hl)
           inc  hl
           ld   d,(hl)
           ld   (ranpnt),hl
           pop  hl
           ex   de,hl
           push bc
           call divide        ; rnd(n)=mod(m,n)+1
           pop  bc
           pop  de
           inc  hl
           ret

abs:       call parn          ; abs(expr)
           dec  de
           call chksgn        ; check sign
           inc  de
           ret

size:      ld   hl,(txtunf)   ; size
           push de            ; get the number of free
           ex   de,hl         ; bytes between 'txtunf'
           ld   hl,varbgn     ; and 'varbgn'
           call subde
           pop  de
           ret

;-------------------------------------------------------
;
; divide  subde  chksgn  chgsgn  & ckhlde
;
; divide divides hl by de, result in bc, remainder in hl
;
; subde subtracts de from hl (hl = hl - de)
;
; chksgn checks sign of hl. if +, no change. if -, change
; sign and flip sign of b.
;
; chgsgn checks sign n of hl and b unconditionally.
;
; ckhlde checks sign of hl and de. if different, hl and de
; are interchanged. if same sign, not interchanged. either
; case, hl de are then compared to set the flags.
;-------------------------------------------------------

divide:    push hl            ; divide
           ld   l,h           ; divide h by de
           ld   h,0
           call dv1
           ld   b,c           ; save result in b
           ld   a,l           ;(reminder+l)/de
           pop  hl
           ld   h,a
dv1:       ld   c,0ffh        ; result in c
dv2:       inc  c             ; dumb routine
           call subde         ; divide by subtract
           jp   nc,dv2        ; and count
           add  hl,de
           ret

subde:     ld   a,l           ; subde
           sub  e             ; substract de from
           ld   l,a           ; hl
           ld   a,h
           sbc  a,d
           ld   h,a
           ret

chksgn:    ld   a,h           ; chksgn
           or   a             ; check sign of hl
           ret  p             ; if -, change sign

chgsgn:    ld   a,h           ; chgsgn
           push af
           cpl                ; change sign of hl
           ld   h,a
           ld   a,l
           cpl
           ld   l,a
           inc  hl
           pop  af
           xor  h
           jp   p,qhow
           ld   a,b           ; and also flip b
           xor  80h
           ld   b,a
           ret

ckhlde:    ld   a,h
           xor  d             ; same sign?
           jp   p,ck1         ; yes, compare
           ex   de,hl         ; no, xch and comp
ck1:       call comp
           ret

;-------------------------------------------------------
;
; setval  fin  endchk  & error (& friends)
;
; setval expects a variable, followed by an equal sign and
; then an expr. it evaluates the expr. and set the variable
; to that value.
;
; fin checks the end of a command. if it ended with ;,
; execution continues. if it ended with a cr, it finds the
; next line and continue from there.
;
; endchk checks if a command is ended with cr. this is
; required in certain commands. (goto, return, and stop etc.)
;
; error prints the string pointed by de (and ends with cr).
; it then prints the line pointed by currnt with a ?
; inserted at where the old text pointer (should be on top
; of the stack) points to. execution of tb is stopped
; and tbi is restarted. however, if currnt -> zero
; (indicating a direct command), the direct command is not
; printed. and if currnt -> negative # (indicating input
; command), the input line is not printed and execution is
; not terminated but continued at inperr.
;
; related to error are the following:
; qwhat saves text pointer in stack and get message what?
; awhat just get message what? and jump to error.
; qsorry and asorry do same kind of thing.
; ahow and ahow in the zero page section also do this.
;-------------------------------------------------------

setval:    call tstv          ; setval
           jp   c,qwhat       ;"what?" no variable
           push hl            ; save address of var.
           call tstc          ; pass "=" sign
           db   '='
           db   sv1-$-1
           call expr          ; evaluate expr.
           ld   b,h           ; value is in bc now
           ld   c,l
           pop  hl            ; get address
           ld   (hl),c        ; save value
           inc  hl
           ld   (hl),b
           ret
sv1:       jp   qwhat         ; no "=" sign

fin:       call tstc          ; fin
           db   3bh
           db   fi1-$-1
           pop  af            ;"
           jp   runsml        ; continue same line
fi1:       call tstc          ; not "
           db   cr
           db   fi2-$-1
           pop  af            ; yes, purge ret. addr.
           jp   runnxl        ; run next line
fi2:       ret                ; else return to caller

endchk:    call ignblk        ; endchk
           cp   cr            ; end with cr?
           ret  z             ; ok, else say: "what?"

qwhat:     push de            ; qwhat
awhat:     ld   de,what       ; awhat
error:     sub  a             ; error
           call prtstg        ; print 'what?', 'how?'
           pop  de            ; or 'sorry'
           ld   a,(de)        ; save the character
           push af            ; at where old de ->
           sub  a             ; and put a 0 there
           ld   (de),a
           ld   hl,(currnt)   ; get current line #
           push hl
           ld   a,(hl)        ; check the value
           inc  hl
           or   (hl)
           pop  de
           jp   z,rstart      ; if zero, just restart
           ld   a,(hl)        ; if negative,
           or   a
           jp   m,inperr      ; redo input
           call prtln         ; else print the line
           dec  de            ; upto where the 0 is
           pop  af            ; restore the character
           ld   (de),a
           ld   a,'?'         ; print a "?"
           call outc
           sub  a             ; and the rest of the
           call prtstg        ; line
           jp   rstart        ; then restart

qsorry:    push de            ; qsorry
asorry:    ld   de,sorry      ; asorry
           jp   error

;-------------------------------------------------------
;
; getln, fndln, fndlnp, fndnxt, and fndskp
;
; getln first prints the char in a, then it fills the
; the buffer and echos it. It ignores lf and nulls,
; but still echos them back. rub-out is used to cause
; it to delete the last character and alt-mod is used
; to delete the whole line. cr signals the end of a
; line and causes getln to return
;
; fndln finds a line with a given line number (in hl)
; in the text save area. de is used as the text pointer
; if the line is found, de will point to the beginning
; of that line (i.e., the low byte of the line#), and
; flags are nc & z. if that line is not there and a line
; with a higher line# is found, de points to there
; and flags are nc & nz. if we reached the end of text
; save area and cannot find the line, flags are c & nz

; fndln will initialize de to the beginning of the text save
; area to start the search. some other entries of this
; routine will not initialize de and do the search
;
; fndlnp will start with de and search for the line#
; fndnxt will bump de by 2, find a cr and then start search
; fndskp use de to find a cr, and then start search
;
;-------------------------------------------------------

getln:     call outc          ; getln
           ld   de,buffer     ; prompt and init.
gl1:       call chkio         ; check keyboard
           jp   nz,gl1        ; no input, wait
           cp   7fh           ; delete last character?
           jp   z,gl3         ; yes
           call outc          ; input, echo back
           cp   0ah           ; ignore lf
           jp   z,gl1
           or   a             ; ignore null
           jp   z,gl1
           cp   7dh           ; delete the whole line?
           jp   z,gl4         ; yes
           ld   (de),a        ; else save input
           inc  de            ; and bump pointer
           cp   0dh           ; was it cr?
           ret  z             ; yes, end of line
           ld   a,e           ; else more free room?
           cp   bufend and 0ffh
           jp   nz,gl1        ; yes, get next input
gl3:       ld   a,e           ; delete last character
           cp   buffer and 0ffh
           jp   z,gl4         ; no, redo whole line
           dec  de            ; yes, backup pointer
           ld   a,'\'         ; and echo a back-slash
           call outc
           jp   gl1           ; go get next input
gl4:       call crlf          ; redo entire line
           ld   a,05eh        ; cr, lf and up-arrow
           jp   getln

fndln:     ld   a,h           ; fndln
           or   a             ; check sign of hl
           jp   m,qhow        ; it cannot be -
           ld   de,txtbgn     ; init text pointer

fndlp:     ; fdlnp
fl1:       push hl            ; save line #
           ld   hl,(txtunf)   ; check if we passed end
           dec  hl
           call comp
           pop  hl            ; get line # back
           ret  c             ; c,nz passed end
           ld   a,(de)        ; we did not, get byte 1
           sub  l             ; is this the line?
           ld   b,a           ; compare low order
           inc  de
           ld   a,(de)        ; get byte 2
           sbc  a,h           ; compare high order
           jp   c,fl2         ; no, not there yet
           dec  de            ; else we either found
           or   b             ; it, or it is not there
           ret                ; nc,z:found, nc,nz:no

fndnxt:    ; fndnxt
           inc  de            ; find next line
fl2:       inc  de            ; just passed byte 1 & 2

fndskp:    ld   a,(de)        ; fndskp
           cp   cr            ; try to find cr
           jp   nz,fl2        ; keep looking
           inc  de            ; found cr, skip over
           jp   fl1           ; check if end of text

;-------------------------------------------------------
;
; prtstg  qtstg  prtnum  & prtln
;
; prtstg prints a string pointed by de. it stops printing
; and returns to caller when either a cr is printed or when
; the next byte is the same as what was in a (given by the
; caller). old a is stored in b, old b is lost.
;
; qtstg looks for a back-arrow, single quote, or double
; quote. if none of these, return to caller. if back-arrow,
; output a cr without a lf. if single or double quote, print
; the string in the quote and demands a matching unquote.
; after the printing the next 3 bytes of the caller is skipped
; over (usually a jump instruction.
;
; prtnum prints the number in hl. leading blanks are added
; if needed to pad the number of spaces to the number in c.
; however, if the number of digits is larger than the # in
; c, all digits are printed anyway. negative sign is also
; printed and counted in, positive sign is not.
;
; prtln prints a saved text line with the line number
;-------------------------------------------------------

prtstg:    ld   b,a           ; prtstg
ps1:       ld   a,(de)        ; get a character
           inc  de            ; bump pointer
           cp   b             ; same as old a?
           ret  z             ; yes, return
           call outc          ; else print it
           cp   cr            ; was it a cr?
           jp   nz,ps1        ; no, next
           ret                ; yes, return

qtstg:     call tstc          ; qtstg
           db   22h
           db   qt3-$-1
           ld   a,22h         ; it is a "
qt1:       call prtstg        ; print until another
           cp   cr            ; was last one a cr?
           pop  hl            ; return address
           jp   z,runnxl      ; was cr, run next line
qt2:       inc  hl            ; skip 3 bytes on return
           inc  hl
           inc  hl
           jp   (hl)          ; return
qt3:       call tstc          ; is it a '?
           db   27h
           db   qt4-$-1
           ld   a,27h         ; yes, do the same
           jp   qt1           ; as in "
qt4:       call tstc          ; is it back-arrow?
           db   5fh
           db   qt5-$-1
           ld   a,08dh        ; yes, cr without lf
           call outc          ; do it twice to give
           call outc          ; tty enough time
           pop  hl            ; return address
           jp   qt2
qt5:       ret                ; none of above

prtnum:    ld   b,0           ; prtnum
           call chksgn        ; check sign
           jp   p,pn1         ; no sign
           ld   b,'-'         ; b=sign
           dec  c             ;'-' takes space
pn1:       push de            ; save
           ld   de,0ah        ; decimal
           push de            ; save as a flag
           dec  c             ; c=spaces
           push bc            ; save sign & space
pn2:       call divide        ; divide hl by 10
           ld   a,b           ; result 0?
           or   c
           jp   z,pn3         ; yes, we got all
           ex   (sp),hl       ; no, save remainder
           dec  l             ; and count space
           push hl            ; hl is old bc
           ld   h,b           ; move result to bc
           ld   l,c
           jp   pn2           ; and divide by 10
pn3:       pop  bc            ; we got all digits in
pn4:       dec  c             ; the stack
           ld   a,c           ; look at space count
           or   a
           jp   m,pn5         ; no leading blanks
           ld   a,' '         ; leading blanks
           call outc
           jp   pn4           ; more?
pn5:       ld   a,b           ; print sign
           or   a
           call nz,10h
           ld   e,l           ; last remainder in e
pn6:       ld   a,e           ; check digit in e
           cp   0ah           ; 10 is flag for no more
           pop  de
           ret  z             ; if so, return
           add  a,30h         ; else convert to ascii
           call outc          ; and print the digit
           jp   pn6           ; go back for more

prtln:     ld   a,(de)        ; prtln
           ld   l,a           ; low order line #
           inc  de
           ld   a,(de)        ; high order
           ld   h,a
           inc  de
           ld   c,4h          ; print 4 digit line #
           call prtnum
           ld   a,' '         ; followed by a blank
           call outc
           sub  a             ; and then the next
           call prtstg
           ret

;-------------------------------------------------------
;
; mvup  mvdown  popa  & pusha
;
; mvup moves a block up from where de-> to where bc-> until
; de = hl
;
; mvdown moves a block down from where de-> to where hl->
; until de = bc
;
; popa restores the for loop variable save area from the
; stack
;
; pusha stacks the for loop variable save area into the
; stack
;-------------------------------------------------------

mvup:      call comp          ; mvup
           ret  z             ; de = hl, return
           ld   a,(de)        ; get one byte
           ld   (bc),a        ; move it
           inc  de            ; increase both pointers
           inc  bc
           jp   mvup          ; until done

mvdown:    ld   a,b           ; mvdown
           sub  d             ; test if de = bc
           jp   nz,md1        ; no, go move
           ld   a,c           ; maybe, other byte?
           sub  e
           ret  z             ; yes, return
md1:       dec  de            ; else move a byte
           dec  hl            ; but first decrease
           ld   a,(de)        ; both pointers and
           ld   (hl),a        ; then do it
           jp   mvdown        ; loop back

popa:      pop  bc            ; bc = return addr.
           pop  hl            ; restore lopvar, but
           ld   (lopvar),hl   ;=0 means no more
           ld   a,h
           or   l
           jp   z,pp1         ; yep, go return
           pop  hl            ; nop, restore others
           ld   (lopinc),hl
           pop  hl
           ld   (loplmt),hl
           pop  hl
           ld   (lopln),hl
           pop  hl
           ld   (loppt),hl
pp1:       push bc            ; bc = return addr.
           ret

pusha:     ld   hl,stklmt     ; pusha
           call chgsgn
           pop  bc            ; bc=return address
           add  hl,sp         ; is stack near the top?
           jp   nc,qsorry     ; yes, sorry for that
           ld   hl,(lopvar)   ; else save loop var's
           ld   a,h           ; but if lopvar is 0
           or   l             ; that will be all
           jp   z,pu1
           ld   hl,(loppt)    ; else, more to save
           push hl
           ld   hl,(lopln)
           push hl
           ld   hl,(loplmt)
           push hl
           ld   hl,(lopinc)
           push hl
           ld   hl,(lopvar)
pu1:       push hl
           push bc            ; bc = return addr.
           ret

;-------------------------------------------------------
;
; outc and chkio
;
; These are the only I/O routines in tbi.
;
; outc sends out a char to the UART
; If ocsw=0 outc will just return to the caller
; If ocsw is not 0 outc will output the byte in a
; If the output byte is a cr or lf it is also send out
; Only the flags may be changed at return
; All registers are restored
;
; chkio checks the input. If no input, it will return
; to the caller with the z flag set. If there is input
; the z flag is cleared and the input byte is in a
; If a control-o is read, the ocsw switch will flip
; If a control-c is read, the tbi will restart
;
;-------------------------------------------------------

init:      ld   (ocsw),a
           ld   d,19h
patlop:
           call crlf
           dec  d
           jp   nz,patlop
           sub  a
           ld   de,msg1
           call prtstg
           ld   hl,start
           ld   (ranpnt),hl
           ld   hl,txtbgn
           ld   (txtunf),hl
           jp   rstart
oc2:       jp   nz,oc3        ; it is on
           pop  af            ; it is off
           ret                ; restore af and return
oc3:       in   a,(uartstat)  ; get uart status
           and  txfull        ; tx fifo full?
           jr   nz,oc3        ; wait if full
           pop  af            ; restore a
           out  (uartdata),a  ; put a character
           cp   cr            ; was it cr?
           ret  nz            ; no, finished
           ld   a,lf          ; yes, we send lf too
           call outc          ; this is recursive
           ld   a,cr          ; get cr back in a
           ret

chkio:     in   a,(uartstat)  ; get uart status
           and  rxempty       ; rx fifo empty?
           ret  nz            ; return if empty
           in   a,(uartdata)  ; get a character
           and  7fh           ; mask bit 7 off
           cp   0fh           ; is it control-o?
           jp   nz,ci1        ; no, more checking
           ld   a,(ocsw)      ; control-o flips ocsw
           cpl                ; on to off, off to on
           ld   (ocsw),a
           jp   chkio         ; get another input
ci1:       cp   3h            ; is it control-c?
           jp   z,rstart      ; yes, restart tbi
           cp   a
           ret                ; return with z set

msg1:      db   'Tiny Basic - Version 1.0',cr

;-------------------------------------------------------
;
; tables  direct  & exec
;
; this section of the code tests a string against a table.
; when a match is found, control is transfered to the section
; of code according to the table.
;
; at exec, de should point to the string and hl should point
; to the table-1. at direct, de should point to the string.
; hl will be set up to point to tab1-1, which is the table of
; all direct and statement commands.
;
; a . in the string will terminate the test and the partial
; match will be considered as a match. e.g., p., pr.,
; pri., prin., or print will all match print.
;
; the table consists of any number of items. each item
; is a string of characters with bit 7 set to 0 and
; a jump address stored hi-low with bit 7 of the high
; byte set to 1.
;
; end of table is an item with a jump address only. if the
; string does not match any of the other items, it will
; match this null item as default.
;-------------------------------------------------------

tab1:      ; direct commands
           db   'list'
           db   list  shr 8 + 128
           db   list  and 0ffh
           db   'run'
           db   run  shr 8 + 128
           db   run  and 0ffh
           db   'new'
           db   new  shr 8 + 128
           db   new  and 0ffh
           db   'bye'
           db   bye  shr 8 + 128
           db   bye  and 0ffh

tab2:      ; direct/statement
           db   'next'
           db   next  shr 8 + 128
           db   next  and 0ffh
           db   'let'
           db   let  shr 8 + 128
           db   let  and 0ffh
           db   'if'
           db   iff  shr 8 + 128
           db   iff  and 0ffh
           db   'goto'
           db   goto  shr 8 + 128
           db   goto  and 0ffh
           db   'gosub'
           db   gosub  shr 8 + 128
           db   gosub  and 0ffh
           db   'return'
           db   return  shr 8 + 128
           db   return  and 0ffh
           db   'rem'
           db   rem  shr 8 + 128
           db   rem  and 0ffh
           db   'for'
           db   for  shr 8 + 128
           db   for  and 0ffh
           db   'input'
           db   input  shr 8 + 128
           db   input  and 0ffh
           db   'print'
           db   print  shr 8 + 128
           db   print  and 0ffh
           db   'stop'
           db   stop  shr 8 + 128
           db   stop  and 0ffh
           db   deflt  shr 8 + 128
           db   deflt  and 0ffh

tab4:      ; functions
           db   'rnd'
           db   rnd  shr 8 + 128
           db   rnd  and 0ffh
           db   'abs'
           db   abs  shr 8 + 128
           db   abs  and 0ffh
           db   'size'
           db   size  shr 8 + 128
           db   size  and 0ffh
           db   xp40  shr 8 + 128
           db   xp40  and 0ffh

tab5:      ;"to" in "for"
           db   'to'
           db   fr1  shr 8 + 128
           db   fr1  and 0ffh
           db   qwhat  shr 8 + 128
           db   qwhat  and 0ffh

tab6:      ;"step" in "for"
           db   'step'
           db   fr2  shr 8 + 128
           db   fr2  and 0ffh
           db   fr3  shr 8 + 128
           db   fr3  and 0ffh

tab8:      ; relation operators
           db   '>='
           db   xp11  shr 8 + 128
           db   xp11  and 0ffh
           db   '#'
           db   xp12  shr 8 + 128
           db   xp12  and 0ffh
           db   '>'
           db   xp13  shr 8 + 128
           db   xp13  and 0ffh
           db   '='
           db   xp15  shr 8 + 128
           db   xp15  and 0ffh
           db   '<='
           db   xp14  shr 8 + 128
           db   xp14  and 0ffh
           db   '<'
           db   xp16  shr 8 + 128
           db   xp16  and 0ffh
           db   xp17  shr 8 + 128
           db   xp17  and 0ffh

direct:    ld   hl,tab1-1     ; direct

exec:      ; exec
ex0:       call ignblk        ; ignore leading blanks
           push de            ; save pointer
ex1:       ld   a,(de)        ; if found '.' in string
           inc  de            ; before any mismatch
           cp   2eh           ; we declare a match
           jp   z,ex3
           inc  hl            ; hl->table
           cp   (hl)          ; if match, test next
           jp   z,ex1
           ld   a,07fh        ; else see if bit 7
           dec  de            ; of table is set, which
           cp   (hl)          ; is the jump addr. (hi)
           jp   c,ex5         ; c:yes, matched
ex2:       inc  hl            ; nc:no, find jump addr.
           cp   (hl)
           jp   nc,ex2
           inc  hl            ; bump to next tab. item
           pop  de            ; restore string pointer
           jp   ex0           ; test against next item
ex3:       ld   a,07fh        ; partial match, find
ex4:       inc  hl            ; jump addr., which is
           cp   (hl)          ; flagged by bit 7
           jp   nc,ex4
ex5:       ld   a,(hl)        ; load hl with the jump
           inc  hl            ; address from the table
           ld   l,(hl)
           and  7fh           ; mask off bit 7
           ld   h,a
           pop  af            ; clean up the gabage
           jp   (hl)          ; and we go do it

;-------------------------------------------------------
; x820 register definitions
;-------------------------------------------------------

uartcntl   equ  00h       ; UART control register
uartstat   equ  01h       ; UART status  register
uartdata   equ  02h       ; UART data register

txfull     equ  04h       ; tx fifo is full
rxempty    equ  01h       ; rx fifo is empty

;-------------------------------------------------------
; ascii character aliases
;-------------------------------------------------------

bksp       equ  08h       ; back space
tab        equ  09h       ; horizontal tab
cr         equ  0dh       ; carriage return
lf         equ  0ah       ; line feed
ctrlc      equ  03h       ; control-c
ctrlg      equ  07h       ; control-g
ctrlk      equ  0bh       ; control-k
ctrlo      equ  0fh       ; control-o
ctrlq      equ  11h       ; control-q
ctrlr      equ  12h       ; control-r
ctrls      equ  13h       ; control-s
ctrlu      equ  15h       ; control-u
esc        equ  1bh       ; escape
del        equ  7fh       ; delete


lstrom:    ; all above can be rom

           org  1000h         ; here down must be ram

ocsw:      ds   1             ; switch for output
currnt:    ds   2             ; points to current line
stkgos:    ds   2             ; saves sp in 'gosub'
varnxt:    ds   2             ; temp storage
stkinp:    ds   2             ; saves sp in 'input'
lopvar:    ds   2             ;'for' loop save area
lopinc:    ds   2             ; increment
loplmt:    ds   2             ; limit
lopln:     ds   2             ; line number
loppt:     ds   2             ; text pointer
ranpnt:    ds   2             ; random number pointer
txtunf:    ds   2             ;->unfilled text area
txtbgn:    ds   2             ; text save area begins

           org  1100h

txtend:    ds   0             ; text save area ends
varbgn:    ds   55            ; variable @(0)
buffer:    ds   64            ; input buffer
bufend:    ds   1             ; buffer ends
stklmt:    ds   1             ; top limit for stack

           org  2000h

stack:     ds   0             ; top of stack

           end
