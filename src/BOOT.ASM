; BOOT.ASM -- boot sector for self-built PC-DOS 1.00 floppy.
; Target: IBM PC 5150, single-sided 160KB FAT12.
; 40 cyl, 1 head, 8 sec/track, 512 B/sector.
; Loaded by ROM-BIOS at 0000:7C00.
;
; Disk layout assumed:
;   LBA  0       boot sector
;   LBA  1..2    FAT, 2 copies of 1 sector
;   LBA  3..6    root directory, 4 sectors, 64 entries
;   LBA  7..10   IBMBIO.COM, 4 sectors
;   LBA 11..23   IBMDOS.COM, 13 sectors
;   LBA 24+      COMMAND.COM and other files
;
; Boot procedure:
;   1. reset drive
;   2. read 4 IBMBIO sectors to 0060:0000
;   3. read 13 IBMDOS sectors to 0070:0000
;   4. far jump to 0060:0000
; Each stage prints A B C as a checkpoint; ! on fatal error.

	ORG	100H
	PUT	100H

SECTRK:	EQU	8
BIOSEG:	EQU	60H
DOSEG:	EQU	80H
BIOLBA:	EQU	7
BIOCNT:	EQU	4
DOSLBA:	EQU	11
DOSCNT:	EQU	13

START:
	CLI
	XOR	AX,AX
	MOV	DS,AX
	MOV	ES,AX
	MOV	SS,AX
	MOV	SP,7C00H
	STI

	XOR	AX,AX
	XOR	DX,DX
	INT	13H

	MOV	AH,0EH
	MOV	AL,"A"
	XOR	BX,BX
	INT	10H

	MOV	AX,BIOSEG
	MOV	ES,AX
	XOR	BX,BX
	MOV	DX,BIOLBA
	MOV	CX,BIOCNT
	CALL	RDSEC
	JC	FAIL

	MOV	AH,0EH
	MOV	AL,"B"
	XOR	BX,BX
	INT	10H

	MOV	AX,DOSEG
	MOV	ES,AX
	XOR	BX,BX
	MOV	DX,DOSLBA
	MOV	CX,DOSCNT
	CALL	RDSEC
	JC	FAIL

	MOV	AH,0EH
	MOV	AL,"C"
	XOR	BX,BX
	INT	10H

	JMP	0,BIOSEG


RDSEC:
RDLP:
	PUSH	CX
	PUSH	DX

	MOV	AX,DX
	MOV	CL,SECTRK
	DIV	AL,CL
	MOV	CH,AL
	MOV	CL,AH
	INC	CL
	XOR	DX,DX

	MOV	AH,2
	MOV	AL,1
	INT	13H

	POP	DX
	POP	CX
	JC	RDFAIL

	INC	DX
	ADD	BX,512
	LOOP	RDLP

	CLC
	RET

RDFAIL:
	STC
	RET

FAIL:
	MOV	AH,0EH
	MOV	AL,"!"
	XOR	BX,BX
	INT	10H
HANG:
	HLT
	JP	HANG
