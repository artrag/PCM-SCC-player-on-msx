;----------------------------------------------------------------------------
	output "dsks\loader60.bin"

slotvar:	equ 0xF348
	
loader60:
		org 0xD000 - 7
		db 0xfe
		dw .start
		dw .end-1
		dw .start
.start:  	
		di 
		in	a,(0xA8)	; Leemos el registro principal de slots
		push	af		; save it
		
		ld 		h,0x40
		ld 		a,(slotvar)	;dskrom slot address
		call 	0x24			
		
		call 	START60H
		
		pop		af
		out (0xA8),a
		ret
.end:

	output "dsks\loader50.bin"
	
loader50:
		org 0xD000 - 7
		db 0xfe
		dw .start
		dw .end-1
		dw .start
.start:  	
		di 
		in	a,(0xA8)	; Leemos el registro principal de slots
		push	af		; save it
		
		ld 		h,0x40
		ld 		a,(slotvar)	;dskrom slot address
		call 	0x24			
		
		call 	START50H

		pop		af
		out (0xA8),a
		ret
.end:


;----------------------------------------------------------------------------
        output "sccplay3c_d2r.rom"

		org 	4000h
		CODE @ 	4000h


		incbin "dsks\test.rom"
		
        org 	77b5h
		CODE ! 	77b5h

; ascii-8 mapper

; Bank1:  equ      6000h		;	Bank 1: 6000h - 67FFh (6000h used)
; Bank2:  equ      6800h		;	Bank 2: 6800h - 6FFFh (6800h used)
; Bank3:  equ      7000h		;	Bank 3: 7000h - 77FFh (7000h used)
; Bank4:  equ      7800h		;	Bank 4: 7800h - 7FFFh (7800h used)

; konami 5 mapper

	; Bank 1: 5000h - 57FFh (5000h used)
	; Bank 2: 7000h - 77FFh (7000h used)
	; Bank 3: 9000h - 97FFh (9000h used)
	; Bank 4: B000h - B7FFh (B000h used)
	
Bank1:  equ      05000h		
Bank2:  equ      07000h		
Bank3:  equ      09000h		
Bank4:  equ      0B000h		
	
; scc mapper for scc chip

sccBank3:  equ      09000h


;-------------------------------------
; Entry point
;-------------------------------------
Period50: equ       (3579545/32/50-1)
Period60: equ       (3579545/32*1001/(60*1000)-1)


START60H:
		call START
		jr	1f
START50H:
		call	START
		ld      a,(SCC)		
		inc		a
		jr		z,1f		; no scc no party
		
		di
		call	en_scc

		ld      hl,Period50
		ld      (Period),hl

        call    SccInit
		
		call	en_slot

        ld      hl,ReplayerUpdate50H
        ld      ($FD9C),hl
1:
		ld      a,(SCC)		
		inc		a
		call	z,ayFX_SETUP		; no scc no party

		ld	e,7
		call checkkbd	
		and	4				; ESC
		ret	nz

		ld	a, easter_egg/02000h-2
		ld 		(Bank1),a
		jp	04000h + (easter_egg & 01FFFH) 

		
START:
		xor		a
		ld 		(Bank1),a
		inc		a
		ld 		(Bank2),a

        di
        call    SCCsearch
		inc		a
		ret		z			; no scc no party

		di
		call	en_scc

		ld      hl,Period60
		ld      (Period),hl
		
        ld      a,3Fh
        ld      (sccBank3),a

        call    SccInit
        call    ReplayerMute
		
		call	en_slot


	; 	set the USR0() function 
		ld		hl,USR0
		ld		(0xF39A),hl

        ld      a,0xF7
        ld      (USR0+0),a
		ld		a,(slotvar)
		ld		(USR0+1),a
        ld      hl,ReplayerInit
        ld      (USR0+2),hl
        ld      a,0xC9
        ld      (USR0+4),a
	
	; 	set the ISR routine	
		ld      a,0xF7
        ld      ($FD9A),a
		ld		a,(slotvar)
		ld		($FD9B),a
        ld      hl,ReplayerUpdate60H
        ld      ($FD9C),hl
        ld      a,0xC9
        ld      ($FD9E),a
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

;-------------------------------------
; Initialize replayer
;
; in :
; l  # of Sfx
;
;-------------------------------------
ReplayerInit_2:
		xor		a
		ld 		(Bank1),a
		call	2f
		ei
1:		jr		1B

ReplayerInit:
		ld		a,(0xF663)			; argument type passed to USR()
		cp		2
		ret		nz					; not an integer
		
		ld		hl,(0xF7F8)			; sfx num. in L
2:
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

        ld		a,(hl)
        inc     hl
        ld      (SamplePage),a

        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      (NumBlocksToPlay),de

        ld      a,0FFh
        ld      (SccSfxOn),a

        ret

SfxTable:
         include SfxTable4.asm
		 
ReplayerUpdate60H:
		ld      a,(SccSfxOn)		; play one sfx at time
        or      a
		ret		z

		in		a,(0xA8)	
		ex		af,af'

		ld	a,[SCC]
		ld h,#80
		call enaslt       ; switch scc slot in 8000-bfffh
		
		; ld		a,(sccslots)
		; out 	(0xA8),a		
		; ld		a,(sccsubslots)
		; ld 		(0xFFFF),a		
		call	SccReplayerUpdate
		xor		a
		ld 		(Bank1),a
		ex		af,af'
		out 	(0xA8),a		
		ret

;-------------------------------------
; write 32 samples and moves sample pointer to next page
; NTSC version == 622 cycles 
;-------------------------------------

		macro	my_ldir
        repeat  32
        ldi						; 18*32
        endrepeat

        ld     	a,h				; 5
		cp		60h				; 8
        jp 		nz,1f			; 11
		
        ld      a,(SamplePage)
        inc     a
        ld      (SamplePage),a
        ld      (Bank1),a
        ld		h,40h
1:      
		endm
		
		
				
SccReplayerUpdate:
        ld      a,(SamplePage)
        ld      (Bank1),a

        ld      hl,(SamplePos)
        ld      de,9800h

        ;622 cycles except at bank swap

        ; phase 0
        my_ldir
		ld      a,Period60 & 255	; 8
        ld      (9880h),a       	; 14
		
        ; phase 1
        my_ldir
		ld      a,Period60 & 255
        ld      (9882h),a			
		
        ; phase 2
        my_ldir
		ld      a,Period60 & 255
        ld      (9884h),a		

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
; write 32 samples and moves sample pointer to next page
; PAL version == 746 cycles 
;-------------------------------------
ReplayerUpdate50H
		ld      a,(SccSfxOn)		; play one sfx at time
        or      a
		ret		z

		in		a,(0xA8)	
		ex		af,af'

		ld	a,[SCC]
		ld h,#80
		call enaslt       ; switch scc slot in 8000-bfffh

		; ld		a,(sccslots)
		; out 	(0xA8),a		
		; ld		a,(sccsubslots)
		; ld 		(0xFFFF),a		
		call	SccReplayerUpdate50H
		xor		a
		ld 		(Bank1),a
		ex		af,af'
		out 	(0xA8),a		
		ret
		
SccReplayerUpdate50H:
        ld      a,(SamplePage)
        ld      (Bank1),a

        ld      hl,(SamplePos)
        ld      de,9800h
       
	    ;746 cycles except at bank swap
        ; phase 0		
		call	my_ldir746			; 18
		ld      a,Period50 & 255	; 8
        ld      (9880h),a       	; 14
		
		call	my_ldir746		
		ld      a,Period50 & 255
		ld      (9882h),a       
		
		call	my_ldir746		
		ld      a,Period50 & 255
		ld      (9884h),a      
        
		ld      (SamplePos),hl

		ld      a,00000111b     ; channels 1-3 active
        ld      (988Fh),a
        ld      hl,(NumBlocksToPlay)
        dec     hl                       ; does NOT affect Z flag
        ld      (NumBlocksToPlay),hl

        ld      a,h
        or      l
		ret		nz

        xor      a
        ld      (SccSfxOn),a
        ld      (988Fh),a	; all channels inactive
        ret

		
my_ldir746:						; 746, including call and instructions outside the routine
		ld	bc,17				; 11
		ldir					; 16*23+18
[15]    ldi						; 18
		
		ld     	a,h				; 5
		cp		60h				; 8
        ld      a,(SamplePage)	; 14
        ret		nz				; 12/6
		
        inc     a
        ld      (SamplePage),a
        ld      (Bank1),a
        ld		h,40h
		ret			
;-------------------------------------
; Initialize the scc
;-------------------------------------
SccInit:
        ld      hl,(Period)
        ld      (9880h),hl
        ld      (9882h),hl
        ld      (9884h),hl


        ld  	a,00100000b         ; Reset phase when freq is written
        ld  	(98E0h),a			; on SCC
        ld  	(98C0h),a			; cover SCC+ in SCC mode

        ld      a,15
        ld      (988Ah),a       ; volume ch1
        ld      (988Bh),a       ; volume ch2
        ld      (988Ch),a       ; volume ch3


SccMute:
        ld      hl,9800h
        ld      de,9801h
        ld      bc,32*4 -1

        ld      (hl),0
        ldir
        ret


;-------------------------------------
; SCC and Slot management
;-------------------------------------
		include sccdetec.asm

		; --- ayFX REPLAYER v1.2f ---

		; --- v1.2f  ayFX bank support
		; --- v1.11f If a frame volume is zero then no AYREGS update
		; --- v1.1f  Fixed volume for all ayFX streams
		; --- v1.1   Explicit priority (as suggested by AR)
		; --- v1.0f  Bug fixed (error when using noise)
		; --- v1.0   Initial release

ayFX_SETUP:	
		ld		hl,sfxbank
		; ---          ayFX replayer setup          ---
		; --- INPUT: HL -> pointer to the ayFX bank ---
		ld	[ayFX_BANK],hl			; Current ayFX bank
		ld	a,1				; Starting channel
		ld	[ayFX_CHANNEL],a		; Updated
ayFX_END:	; --- End of an ayFX stream ---
		ld	a,255				; Lowest ayFX priority
		ld	[ayFX_PRIORITY],a		; Priority saved (not playing ayFX stream)
		
	; 	set the ISR routine	
		ld      a,0xF7
        ld      ($FD9A),a
		ld		a,(slotvar)
		ld		($FD9B),a
        ld      hl,ayFX_PLAY
        ld      ($FD9C),hl
        ld      a,0xC9
        ld      ($FD9E),a
		
	; 	set the USR0() function 
		ld		hl,USR0
		ld		(0xF39A),hl

        ld      a,0xF7
        ld      (USR0+0),a
		ld		a,(slotvar)
		ld		(USR0+1),a
        ld      hl,ayFX_INIT
        ld      (USR0+2),hl
        ld      a,0xC9
        ld      (USR0+4),a
		
		ret					; Return

ayFX_INIT:	; ---     INIT A NEW ayFX STREAM     ---
		ld		a,(0xF663)			; argument type passed to USR()
		cp		2
		ret		nz					; not an integer
		
		ld		a,(0xF7F8)			; sfx num. in A
        ld      c,0

		; --- INPUT: A -> sound to be played ---
		; ---        C -> sound priority     ---
		push	bc				; Store bc in stack
		push	de				; Store de in stack
		push	hl				; Store hl in stack
		; --- Check if the index is in the bank ---
		ld	b,a				; b:=a (new ayFX stream index)
		ld	hl,[ayFX_BANK]			; Current ayFX BANK
		ld	a,[hl]				; Number of samples in the bank
		or	a				; If zero (means 256 samples)...
		jp	z,_CHECK_PRI			; ...goto _CHECK_PRI
		; The bank has less than 256 samples
		ld	a,b				; a:=b (new ayFX stream index)
		cp	[hl]				; If new index is not in the bank...
		ld	a,2				; a:=2 (error 2: Sample not in the bank)
		jp	nc,_INIT_END			; ...we can't init it
_CHECK_PRI:	; --- Check if the new priority is lower than the current one ---
		; ---   Remember: 0 = highest priority, 15 = lowest priority  ---
		ld	a,b				; a:=b (new ayFX stream index)
		ld	a,[ayFX_PRIORITY]		; a:=Current ayFX stream priority
		cp	c				; If new ayFX stream priority is lower than current one...
		ld	a,1				; a:=1 (error 1: A sample with higher priority is being played)
		jp	c,_INIT_END			; ...we don't start the new ayFX stream
		; --- Set new priority ---
		ld	a,c				; a:=New priority
		and	$0F				; We mask the priority
		ld	[ayFX_PRIORITY],a		; new ayFX stream priority saved in RAM
		; --- Calculate the pointer to the new ayFX stream ---
		ld	de,[ayFX_BANK]			; de:=Current ayFX bank
		inc	de				; de points to the increments table of the bank
		ld	l,b				; l:=b (new ayFX stream index)
		ld	h,0				; hl:=b (new ayFX stream index)
		add	hl,hl				; hl:=hl*2
		add	hl,de				; hl:=hl+de (hl points to the correct increment)
		ld	e,[hl]				; e:=lower byte of the increment
		inc	hl				; hl points to the higher byte of the correct increment
		ld	d,[hl]				; de:=increment
		add	hl,de				; hl:=hl+de (hl points to the new ayFX stream)
		ld	[ayFX_POINTER],hl		; Pointer saved in RAM
		xor	a				; a:=0 (no errors)
_INIT_END:	pop	hl				; Retrieve hl from stack
		pop	de				; Retrieve de from stack
		pop	bc				; Retrieve bc from stack
		ret					; Return

ayFX_PLAY:
		call	PT3_ROUT

        LD        HL,AYREGS+8	
		xor	a
		ld		(hl),a
		inc		hl
		ld		(hl),a
		inc		hl
		ld		(hl),a

		; --- PLAY A FRAME OF AN ayFX STREAM ---
		ld	a,[ayFX_PRIORITY]		; a:=Current ayFX stream priority
		or	a						; If priority has bit 7 on...
		ret	m						; ...return
		; --- Extract control byte from stream ---
		ld	hl,[ayFX_POINTER]		; Pointer to the current ayFX stream
		ld	c,[hl]					; c:=Control byte
		inc	hl						; Increment pointer
		; --- Check if there's new tone on stream ---
		bit	5,c						; If bit 5 c is off...
		jp	z,_CHECK_NN				; ...jump to _CHECK_NN (no new tone)
		; --- Extract new tone from stream ---
		ld	e,[hl]					; e:=lower byte of new tone
		inc	hl						; Increment pointer
		ld	d,[hl]					; d:=higher byte of new tone
		inc	hl						; Increment pointer
		ld	[ayFX_TONE],de			; ayFX tone updated
_CHECK_NN:	; --- Check if there's new noise on stream ---
		bit	6,c						; if bit 6 c is off...
		jp	z,_SETPOINTER			; ...jump to _SETPOINTER (no new noise)
		; --- Extract new noise from stream ---
		ld	a,[hl]					; a:=New noise
		inc	hl						; Increment pointer
		cp	$20						; If it's an illegal value of noise (used to mark end of stream)...
		jp	z,ayFX_END				; ...jump to ayFX_END
		ld	[ayFX_NOISE],a			; ayFX noise updated
_SETPOINTER:	; --- Update ayFX pointer ---
		ld	[ayFX_POINTER],hl		; Update ayFX stream pointer
		; --- Extract volume ---
		ld	a,c						; a:=Control byte
		and	$0F						; lower nibble
		ld	[ayFX_VOLUME],a			; ayFX volume updated
		ret	z						; Return if volume is zero (don't copy ayFX values in to AYREGS)
		; -------------------------------------
		; --- COPY ayFX VALUES IN TO AYREGS ---
		; -------------------------------------
		; --- Set noise channel ---
		bit	7,c						; If noise is off...
		jp	nz,_SETMASKS			; ...jump to _SETMASKS
		ld	a,[ayFX_NOISE]			; ayFX noise value
		ld	[AYREGS+6],a			; copied in to AYREGS (noise channel)
_SETMASKS:	; --- Set mixer masks ---
		ld	a,c						; a:=Control byte
		and	$90						; Only bits 7 and 4 (noise and tone mask for psg reg 7)
		cp	$90						; If no noise and no tone...
		ret	z						; ...return (don't copy ayFX values in to AYREGS)
		; --- Copy ayFX values in to ARYREGS ---
		rrc	a						; Rotate a to the right (1 TIME)
		rrc	a						; Rotate a to the right (2 TIMES) (OR mask)
		ld	d,$DB					; d:=Mask for psg mixer (AND mask)
		; --- Calculate next ayFX channel ---
		ld	hl,ayFX_CHANNEL			; Old ayFX playing channel
		dec	[hl]					; New ayFX playing channel
		jp	nz,_SETCHAN				; If not zero jump to _SETCHAN
		ld	[hl],3					; If zero -> set channel 3
_SETCHAN:	ld	b,[hl]				; Channel counter
_CHK1:		; --- Check if playing channel was 1 ---
		djnz	_CHK2				; Decrement and jump if channel was not 1
_PLAY_C:	; --- Play ayFX stream on channel C ---
		call	_SETMIXER			; Set PSG mixer value (a:=ayFX volume)
		ld	[AYREGS+10],a			; Volume copied in to AYREGS (channel C volume)
		bit	2,c						; If tone is off...
		ret	nz						; ...return
		ld	hl,[ayFX_TONE]			; ayFX tone value
		ld	[AYREGS+4],hl			; copied in to AYREGS (channel C tone)
		ret							; Return
_CHK2:		; --- Check if playing channel was 2 ---
		rrc	d						; Rotate right AND mask
		rrc	a						; Rotate right OR mask
		djnz	_CHK3				; Decrement and jump if channel was not 2
_PLAY_B:	; --- Play ayFX stream on channel B ---
		call	_SETMIXER			; Set PSG mixer value (a:=ayFX volume)
		ld	[AYREGS+9],a			; Volume copied in to AYREGS (channel B volume)
		bit	1,c						; If tone is off...
		ret	nz						; ...return
		ld	hl,[ayFX_TONE]			; ayFX tone value
		ld	[AYREGS+2],hl			; copied in to AYREGS (channel B tone)
		ret							; Return
_CHK3:		; --- Check if playing channel was 3 ---
		rrc	d						; Rotate right AND mask
		rrc	a						; Rotate right OR mask
_PLAY_A:	; --- Play ayFX stream on channel A ---
		call	_SETMIXER			; Set PSG mixer value (a:=ayFX volume)
		ld	[AYREGS+8],a			; Volume copied in to AYREGS (channel A volume)
		bit	0,c						; If tone is off...
		ret	nz						; ...return
		ld	hl,[ayFX_TONE]			; ayFX tone value
		ld	[AYREGS+0],hl			; copied in to AYREGS (channel A tone)
		ret							; Return
_SETMIXER:	; --- Set PSG mixer value ---
		ld	c,a						; c:=OR mask
		ld	a,[AYREGS+7]			; a:=PSG mixer value
		and	d						; AND mask
		or	c						; OR mask
		ld	[AYREGS+7],a			; PSG mixer value updated
		ld	a,[ayFX_VOLUME]			; a:=ayFX volume value
		ret							; Return
sfxbank:		
		incbin "ayFX-replayer\LOMPSG.afb"
PT3_ROUT:
        XOR A
        
        LD        HL,AYREGS+7
        set        7,(hl)        ; --- FIXES BITS 6 AND 7 OF MIXER ---
        res        6,(hl)        ; --- FIXES BITS 6 AND 7 OF MIXER ---

        LD C,0xA0
        LD HL,AYREGS
_LOUT:
        OUT (C),A
        INC C
        OUTI
        DEC C
        INC A
        CP 13
        JR NZ,_LOUT
        OUT (C),A
        LD A,(HL)
        AND A
        RET M
        INC C
        OUT (C),A
        RET
		
		db	"end"
;-------------------------------------
; Padding for rom player
;-------------------------------------
        ; ds	$8000 - $

        org 	068000h
		CODE ! 	068000h

;-------------------------------------
; Sample data
;-------------------------------------
SAMPLE_START:
         include DataTable.asm
		 
SAMPLE_END:
		org 	004800h
		CODE ! 	07A800h		
		db "image"
easter_egg:
		ld		a,5
		call	05fh
		

		ld	hl,04000h + (palette & 01FFFH)

		;Set the palette to the one HL points to...
		;Modifies: AF, BC, HL (=updated)
		;Enables the interrupts.
		
		xor	a		;Set p#pointer to zero.
		di
		out	(#99),a
		ld	a,16+128
		ei
		out	(#99),a
		ld	bc,#209A	;out 32x to port #9A
		otir
		
		di		
		xor	a
		out	(0x99),a
		ld	a,08Eh
		out	(0x99),a
		xor	a
		out	(0x99),a
		ld	a,040h
		out	(0x99),a

		
		ld		e, easter_egg/02000h-2 
		ld		d,6
2:		
		inc		e
		ld		a,e
		ld 		(Bank2),a

		ld		hl,6000h
		ld		bc,0098h
		ld		a,32
1:		otir
		dec	a
		jr	nz,1B
		
		dec	d
		jr	nz,2B

		ld		a,1
		ld 		(Bank2),a
		ld		l,8
		jp		ReplayerInit_2
		


palette:

	incbin "kaispoon\spoon.pl5",7
	
		CODE ! 	07C000h

		
spoon:		
	incbin "kaispoon\spoon.sc5",7
;-------------------------------------
; Padding, align rom image to a power of two.
;-------------------------------------

SAMPLE_LENGTH:  equ SAMPLE_END - SAMPLE_START

		DS (84000h - $)


        ; IF (SAMPLE_LENGTH <= 6000h)
        ; DS (06000h - SAMPLE_LENGTH)
        ; ELSE
        ; IF (SAMPLE_LENGTH <= 10000h-2000h)
        ; DS (0E000h - SAMPLE_LENGTH)
        ; ELSE
        ; IF (SAMPLE_LENGTH <= 1E000h)
        ; DS (01E000h - SAMPLE_LENGTH)
        ; ELSE
        ; IF (SAMPLE_LENGTH <= 3E000h)
        ; DS (03E000h - SAMPLE_LENGTH)
        ; ELSE
        ; IF (SAMPLE_LENGTH <= 7E000h)
        ; DS (07E000h - SAMPLE_LENGTH)
        ; ELSE
        ; DS (0FE000h - SAMPLE_LENGTH)
        ; ENDIF
        ; ENDIF
        ; ENDIF
        ; ENDIF
        ; ENDIF



FINISH:


;---------------------------------------------------------
; Variables
;---------------------------------------------------------
					map 0xFD09		; unused ram (145 bytes)
USR0:				#	5

SCC:            	#	1
curslot:            #	1
; sccslots:           #	1
; sccsubslots:		#	1

SccSfxOn:           #	1

SamplePos:          #	2
Period:             #	2
NumBlocksToPlay:    #	2
SamplePage:         #	1
					endmap
					
;	F87FH FNKSTR: DEFS 160		used by "key" statment
					map 0xF87F		; unused ram (160 bytes)					
		; --- ayFX REPLAYER v1.2f ---
ayFX_BANK:			#	2			; Current ayFX Bank
ayFX_PRIORITY:		#	1			; Current ayFX stream priotity
ayFX_POINTER:		#	2			; Pointer to the current ayFX stream
ayFX_TONE:			#	2			; Current tone of the ayFX stream
ayFX_NOISE:			#	1			; Current noise of the ayFX stream
ayFX_VOLUME:		#	1			; Current volume of the ayFX stream
ayFX_CHANNEL:		#	1			; PSG channel to play the ayFX stream
AYREGS:				#	14			; Ram copy of PSG registers

					endmap
					
