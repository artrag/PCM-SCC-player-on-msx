
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

		defpage	0,4000h,2000h
		defpage	1,6000h,2000h
		defpage	2..64
		
		; defpage	2,6000h,2000h
		; defpage	3..47
		
		; defpage	48,4000h,2000h
		; defpage	49,6000h,2000h
		; defpage	50..64

		page 	0..47
		
Bank1:  equ      6000h		;	Bank 1: 6000h - 67FFh (6000h used)
Bank2:  equ      6800h		;	Bank 2: 6800h - 6FFFh (6800h used)
Bank3:  equ      7000h		;	Bank 3: 7000h - 77FFh (7000h used)
Bank4:  equ      7800h		;	Bank 4: 7800h - 7FFFh (7800h used)

        output "sccplay3c_d2r.rom"
		incbin "dsks\test.rom"
		

		
		CODE ! 7800h

		
START50H:
		ld	a,:init50Hz
		ld	(Bank1),a
		jp	init50Hz
START60H:
		ld	a,:init60Hz
		ld	(Bank1),a
		jp	init60Hz
		
		page 48
		code @ 4000h, # 2000h
init50Hz:	
		ret
init60Hz:
		ret