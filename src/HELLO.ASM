; HELLO.ASM -- minimal diagnostic boot sector for IBM 5150.
; If this boots on the real 5150, the floppy format/media/write are
; all fine and the issue with hybrid.img is in DOS code path.
; If this does NOT boot, the issue is purely the disk surface or
; geometry that 5150 BIOS cannot read.
;
; Behavior:
;   - DOES NOT set video mode (would hang on MDA if we forced CGA mode 3)
;   - print banner "5150 OK" via INT 10H fn 0Eh teletype (works on any card)
;   - print drive number from BIOS DL
;   - halt forever
;
; SCP ASM gotchas: CRLF + 1AH terminator, double quote literals,
; numbers decimal unless H suffix.

	ORG	100H
	PUT	100H

START:
	;Save drive number (BIOS passes drive in DL on entry)
	MOV	AH,DL

	;Set up minimal stack — DS=ES=SS=0, SP=7C00 grows down.
	;DO NOT touch video mode: CGA INT 10h AX=3 hangs on MDA.
	CLI
	XOR	AX,AX
	MOV	DS,AX
	MOV	ES,AX
	MOV	SS,AX
	MOV	SP,7C00H
	STI

	;CRLF first (in case current cursor is mid-screen)
	MOV	AL,13
	CALL	PUT
	MOV	AL,10
	CALL	PUT

	;Banner "5150 OK"
	MOV	AL,"5"
	CALL	PUT
	MOV	AL,"1"
	CALL	PUT
	MOV	AL,"5"
	CALL	PUT
	MOV	AL,"0"
	CALL	PUT
	MOV	AL," "
	CALL	PUT
	MOV	AL,"O"
	CALL	PUT
	MOV	AL,"K"
	CALL	PUT
	MOV	AL,13
	CALL	PUT
	MOV	AL,10
	CALL	PUT

	;Print "DRV="
	MOV	AL,"D"
	CALL	PUT
	MOV	AL,"R"
	CALL	PUT
	MOV	AL,"V"
	CALL	PUT
	MOV	AL,"="
	CALL	PUT

	;Print drive number as ASCII digit (saved in AH at start)
	MOV	AL,AH
	ADD	AL,"0"
	CALL	PUT

	MOV	AL,13
	CALL	PUT
	MOV	AL,10
	CALL	PUT

	;Print "READY"
	MOV	AL,"R"
	CALL	PUT
	MOV	AL,"E"
	CALL	PUT
	MOV	AL,"A"
	CALL	PUT
	MOV	AL,"D"
	CALL	PUT
	MOV	AL,"Y"
	CALL	PUT

HANG:
	HLT
	JP	HANG

;INT 10H teletype: works on CGA, MDA, EGA, VGA — any video card.
;BL=foreground color is ignored on MDA, harmless.
PUT:
	PUSH	AX
	PUSH	BX
	MOV	AH,0EH
	XOR	BX,BX
	INT	10H
	POP	BX
	POP	AX
	RET
