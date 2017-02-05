;----------------------------------------------------------------------------
;----------------------------------------------------------------------------

        output "sccplay3c_bas.rom"

        org 4000h
        dw  4241h,START,0,0,0,0,0,0

;	Bank 1: 6000h - 67FFh (6000h used)
;	Bank 2: 6800h - 6FFFh (6800h used)
;	Bank 3: 7000h - 77FFh (7000h used)
;	Bank 4: 7800h - 7FFFh (7800h used)


; ascii-8 mapper

Bank1:  equ      6000h
Bank2:  equ      6800h
Bank3:  equ      7000h
Bank4:  equ      7800h

; scc mapper for scc chip

sccBank3:  equ      09000h

;-------------------------------------
; Entry point
;-------------------------------------
START:
        ld		a,40
		ld		(0xF3AE),a	; screen width
        xor     a
        call    005Fh
        xor     a
		ld		(0xF3DB),a	; no key click
		call	init_mapper

		call	search_slot
		ld		de,40*9
		ld		hl,rom_slot_text
		call	message
        ld      de,40*9+10
		ld		hl,(slotvar)
		ld		h,0
        call    PrintNum

		call	search_slotram
		ld		de,40*10
		ld		hl,ram_slot_text
		call	message
        ld      de,40*10+10
		ld		hl,(slotram)
		ld		h,0
        call    PrintNum

        call    SCCsearch
		ld		de,40*8
		ld		hl,scc_slot_text
		call	message
        ld      de,40*8+10
		ld		hl,(SCC)
		ld		h,0
        call    PrintNum

		ld		a,(SCC)
		inc		a
		jr		nz,1f
		ld		de,3*40+5
		ld		hl,noSCC_text
		call	message
		ret
1:
		call	en_scc

        di

        ld      a,3Fh
        ld      (sccBank3),a

        call    SccAdjust
        call    SccInit
        call    ReplayerMute
        call    SccMute
        call    InstallIntHanlder


 ; print period from SccAdjust

        ld      hl,(Period)
        ld      de,0
        call    PrintNum

		ld		de,3*40+5
		ld		hl,instruction_text
		call	message


        ei
		ret


.halt:

; print blocks to play
        halt
        ld      hl,(NumBlocksToPlay)
        ld      de,8
        call    PrintNum

        ld      hl,(SamplePos)
        ld      de,16
        call    PrintNum

        ld      hl,(SamplePage)
        ld      h,0
        ld      de,24
        call    PrintNum

; play one sfx at time
		ld      a,(SccSfxOn)
        or      a
		call	z,effetct24
		ret

; Keyboard testing
; 2 "B" "A" ??? "/" "." "," "'" "`"
; 3 "J" "I" "H" "G" "F" "E" "D" "C"
; 4 "R" "Q" "P" "O" "N" "M" "L" "K"
; 5 "Z" "Y" "X" "W" "V" "U" "T" "S"
; 6 F3 F2  F1 CODE CAP GRAPH CTR SHIFT
; 7 RET SEL BS STOP TAB ESC F5  F4
; 8 RIGHT DOWN UP LEFT DEL INS HOME SPACE

effetct24:

		ld      de,3
2: 		push	de
 		call    checkkbd
 		ld      b,8
 		ld      c,a
1:
 		ld      a,b
 		dec     a
		add		a,d
 		ld      l,a
 		ld      a,c
 		add     a,a
 		ld      c,a
 		push    bc
 		ld      a,l
 		call    nc,ReplayerInit
 		pop     bc
 		djnz    1B
		pop		de
		ld		a,8
		add		a,d
		ld		d,a
		inc		e
		ld		a,8
		cp		e
		jr		nc,2B

 		ret
;-------------------------------------
;-------------------------------------
message:
        ld      a,e
        out     (99h),a
        ld      a,d
        and     3Fh
        or      40h
        out     (99h),a

1:		ld		a,(hl)
		and		a
		ret		z
		out     (98h),a
		inc		hl
		jr		1b
		
noSCC_text:
		db "No SCC detected.",0
instruction_text:
		db "use USR0(n) with n in 0-11 ",0
scc_slot_text:
		db	"Scc slot: ",0
rom_slot_text:
		db	"Rom slot: ",0
ram_slot_text:
		db	"Ram slot: ",0

;-------------------------------------
;-------------------------------------
InstallIntHanlder:
        di
        ld      a,0xF7
        ld      ($FD9A),a
		ld		a,(slotvar)
		ld		($FD9B),a
        ld      hl,HandleInt
        ld      ($FD9C),hl
        ld      a,0xC9
        ld      ($FD9E),a
		
		ld		hl,USR0
		ld		(0xF39A),hl

        ld      a,0xF7
        ld      (USR0+0),a
		ld		a,(slotvar)
		ld		(USR0+1),a
        ld      hl,HandleUsr
        ld      (USR0+2),hl
        ld      a,0xC9
        ld      (USR0+4),a
		
        ret
		
HandleUsr:
		ld		a,(0xF663)
		cp		2
		ret		nz
		ld      a,(SccSfxOn)		; play one sfx at time
        or      a
		ret		nz
		ld		hl,(0xF7F8)
		jp    	ReplayerInit

HandleInt:
        push    af
		call	en_scc				; scc in page 2
		
        ld      a,(SccSfxOn)
        or      a
        call    nz,ReplayerUpdate

		call	en_slot
        pop     af
		ret

;-------------------------------------
; Initialize replayer
;
; in :
; l  # of Sfx
;
;-------------------------------------
ReplayerInit:
        ld      h,0

        ld      d,h
        ld      e,l

        add     hl,hl
        add     hl,hl
        add     hl,de

        ld      de,SfxTable
        add     hl,de

        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        ld      (SamplePos),de

        ld      a,(hl)
        inc     hl
        ld      (SamplePage),a
        ld      (Bank2),a

        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      (NumBlocksToPlay),de

        ld      a,0FFh
        ld      (SccSfxOn),a

        ret

SfxTable:
         include SfxTable.asm


;-------------------------------------
; write 32 samples and moves sample pointer to next page
;-------------------------------------
		macro	my_ldir
        repeat  32
        ldi						; 18*32
        endrepeat
        bit     7,h				; 10
        jp 		z,1f			; 11
        ld      a,(SamplePage)
        inc     a
        ld      (SamplePage),a
        ld      (Bank2),a
        ld		h,060h
        ld      a,(Period)
1:		nop						; 10 dummy
		nop						; 1 cycle is missing
		endm
		
		
ReplayerUpdate:
        ld      hl,(SamplePos)
        ld      a,(Period)
        ld      de,9800h

        ;622 cycles except at bank swap

        ; phase 0
        my_ldir
        ld      (9880h),a       ; 14
		
        ; phase 1
        my_ldir
        ld      (9882h),a		; 14
		
        ; phase 2
        my_ldir
        ld      (9884h),a		; 14

        ld      (SamplePos),hl

		ld      a,00000111b     ; channels 1-3 active
        ld      (988Fh),a
        ld      hl,(NumBlocksToPlay)
        dec     hl                       ; does NOT affect Z flag
        ld      (NumBlocksToPlay),hl

        ld      a,h
        or      l
		ret		nz

;-------------------------------------
; Mute replayer
;-------------------------------------
ReplayerMute:

        xor      a
        ld      (SccSfxOn),a
        ld      (988Fh),a	; all channels inactive
        ret


;-------------------------------------
; To make rom guesseres happy
;-------------------------------------
init_mapper:
        ld     a,init_mapper/02000h-2
        ld      (Bank1),a
		inc		a
        ld      (Bank2),a
		inc		a
        ld      (Bank3),a
		inc		a
        ld      (Bank4),a
        ret

;-------------------------------------
; method that prints hl on screen
; to address de
;-------------------------------------
PrintNum:
        ld      a,e
        out     (99h),a
        ld      a,d
        and     3Fh
        or      40h
        out     (99h),a

        push    hl
        ex      de,hl

        ld      a,d
        rlca
        rlca
        rlca
        rlca
        and     15
        ld      b,0
        ld      c,a
        ld      hl,Numbers
        add     hl,bc
        ld      a,(hl)
        out     (98h),a

        ld      a,d
        and     15
        ld      b,0
        ld      c,a
        ld      hl,Numbers
        add     hl,bc
        ld      a,(hl)
        out     (98h),a

        ld      a,e
        rlca
        rlca
        rlca
        rlca
        and     15
        ld      b,0
        ld      c,a
        ld      hl,Numbers
        add     hl,bc
        ld      a,(hl)
        out     (98h),a

        ld      a,e
        and     15
        ld      b,0
        ld      c,a
        ld      hl,Numbers
        add     hl,bc
        ld      a,(hl)
        out     (98h),a

        pop     hl
        ret

Numbers:
        db  "0123456789ABCDEF"

;-------------------------------------
; Adjusts the SCC period to the frame
; rate
;-------------------------------------

Period50: equ       (3579545/32/50-1)
Period60: equ       (3579545/32*1001/(60*1000)-1)

;Period60: equ      749h

SccAdjust:
		ld      hl,Period60
		ld      (Period),hl

        ld      e,7					;    7   |   RET   SEL   BS   STOP   TAB   ESC   F5    F4
        call    checkkbd
        cp      11111011b           ; key ESC
        ret     nz

        ; press ESC at boot to start the frequency test
		; WARNING it hangs on SCC+

        ld      a,00011000b
        ld      (988Fh),a		; activate ch 4 & 5 for testing

        ld      hl,9800h+32*3   ; counter in channel 4
        ld      bc,2000h
.counter:
        ld      (hl),c
        inc     hl
        inc     c
        djnz    .counter

        ld      a,10100000b     	; rotate channel 4&5 with ch4 freq., reset wav if freq is written
        ld      (98E0h),a			; on SCC
        ld  	(98C0h),a			; cover SCC+ in SCC mode

        ld      hl,Period60-4
        in      a,(99h)
		jp		2f					; expect in C any value > 31

.loop:

1:      in      a,(99h)
        and     80h
        jp      z,1B         ; wait vblank

        ld      a,(9800h+32*3)
        cp      c
        jp      z,.end

        ld      c,31
        inc     hl

1:      in      a,(99h)
        and     80h
        jp      z,1B         ; wait vblank
2:
        ld      (9886h),hl
;        ld      (9888h),hl	; ch5 not needed
        jp      .loop
.end:
        ld      (Period),hl

        ret

;-------------------------------------
; Initialize the scc
;-------------------------------------
SccInit:
        call SccMute

        ld  	a,00100000b         ; Reset phase when freq is written
        ld  	(98E0h),a			; on SCC
        ld  	(98C0h),a			; cover SCC+ in SCC mode

        ld      a,15
        ld      (988Ah),a       ; volume ch1
        ld      (988Bh),a       ; volume ch2
        ld      (988Ch),a       ; volume ch3
		xor		a
        ld      (988Dh),a       ; volume ch4
        ld      (988Eh),a       ; experiment on ch4&5

        ld      hl,(Period)
        ld      (9880h),hl
        ld      (9882h),hl
        ld      (9884h),hl
        ld      (9886h),hl			; experiment on ch 4&5
        ld      (9888h),hl

        ret

SccMute:
        ld      hl,9800h
        ld      de,9801h
        ld      bc,32*4 -1

        ld      (hl),0
        ldir
        ret

;-------------------------------------
; checkkbd: ckeck keyboard line
; syntax:checkkbd <keyboar line #>
; in:  e
; out: l
;-------------------------------------
; i8255 ports
;
i8255porta  equ 0a8h        ; slot selection
i8255portb  equ 0a9h        ; keyboard column input
i8255portc  equ 0aah        ; leds, motor, cassette, kbd line
i8255portd  equ 0abh        ; mode select for i8255 ports A,B,C

checkkbd:
        in  a,(i8255portc)
        and 011110000B          ; upper 4 bits contain info to preserve
        or  e
        out (i8255portc),a
        in  a,(i8255portb)
        ld  l,a
        ret

; #define right (!(kbd & 128))
; #define left 	(!(kbd & 16))
; #define up 	(!(kbd & 32))
; #define down 	(!(kbd & 64))
; // space
; #define key1 	(!(kbd & 1))
; // M
; #define key2 	(!(kb2 & 4))

;  Bit_7 Bit_6 Bit_5 Bit_4 Bit_3 Bit_2 Bit_1 Bit_0
; 0 "7" "6" "5" "4" "3" "2" "1" "0"
; 1 ";" "]" "[" "\" "=" "-" "9" "8"
; 2 "B" "A" ??? "/" "." "," "'" "`"
; 3 "J" "I" "H" "G" "F" "E" "D" "C"
; 4 "R" "Q" "P" "O" "N" "M" "L" "K"
; 5 "Z" "Y" "X" "W" "V" "U" "T" "S"
; 6 F3 F2  F1 CODE CAP GRAPH CTR SHIFT
; 7 RET SEL BS STOP TAB ESC F5  F4
; 8 RIGHT DOWN UP LEFT DEL INS HOME SPACE


;-------------------------------------
; SCC and Slot management
;-------------------------------------
         include rominit64.asm
         include sccdetec.asm

;-------------------------------------
; Padding for rom player
;-------------------------------------
        ds	$6000 - $



;-------------------------------------
; Sample data
;-------------------------------------
SAMPLE_START:
         include DataTable.asm
SAMPLE_END:



;-------------------------------------
; Padding, align rom image to a power of two.
;-------------------------------------

SAMPLE_LENGTH:  equ SAMPLE_END - SAMPLE_START



        IF (SAMPLE_LENGTH <= 6000h)
        DS (06000h - SAMPLE_LENGTH)
        ELSE
        IF (SAMPLE_LENGTH <= 10000h-2000h)
        DS (0E000h - SAMPLE_LENGTH)
        ELSE
        IF (SAMPLE_LENGTH <= 1E000h)
        DS (01E000h - SAMPLE_LENGTH)
        ELSE
        IF (SAMPLE_LENGTH <= 3E000h)
        DS (03E000h - SAMPLE_LENGTH)
        ELSE
        IF (SAMPLE_LENGTH <= 7E000h)
        DS (07E000h - SAMPLE_LENGTH)
        ELSE
        DS (0FE000h - SAMPLE_LENGTH)
        ENDIF
        ENDIF
        ENDIF
        ENDIF
        ENDIF



FINISH:


;---------------------------------------------------------
; Variables
;---------------------------------------------------------
					map 0xFD09		; unused ram


SamplePos:          #	2
SamplePage:         #	1
sccslots			#	1
Period:             #	2
NumBlocksToPlay:    #	2

SccSfxOn:           #	1

slotvar:            #	1
slotram:            #	1
SCC:            	#	1
curslot:            #	1

USR0:				#	5
					endmap
					
