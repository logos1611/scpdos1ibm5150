; IBMBIO.ASM -- minimal IBM PC 5150 BIOS layer for 86-DOS / PC-DOS 1.00.
; Self-made replacement for the IBM/MS IBMBIO.COM. Uses ROM-BIOS
; INT 13H, INT 10H, INT 16H, INT 17H, INT 14H. Loaded by our boot
; sector at 0060:0000. Pairs with our IBMDOS.COM at 0070:0000.
;
; SCP ASM gotchas:
;   numbers DECIMAL by default unless suffixed H
;   string/char literal must be "X" not 'X'
;   JP = JMP near; CALL/JMP off,seg = far
;   files must be CRLF + trailing 1AH (Ctrl-Z)
;   forward references in EQU expressions are unreliable -- order matters

	ORG	0
	PUT	100H

DOSSEG:	EQU	80H		;segment IBMDOS is loaded at (0x800 linear, well above IBMBIO end at ~0x760)
SECTRK:	EQU	8

;-------------- Jump table at offset 0..1D (TEN entries) --------------
;Kernel BIOSSEG layout (from kernel source):
;   offset 0..2  : DS 3 (unlabeled, INIT entry; boot sector jumps here)
;   offset 3..5  : BIOSSTAT
;   offset 6..8  : BIOSIN
;   offset 9..B  : BIOSOUT
;   offset C..E  : BIOSPRINT
;   offset F..11 : BIOSAUXIN
;   offset 12..14: BIOSAUXOUT
;   offset 15..17: BIOSREAD
;   offset 18..1A: BIOSWRITE
;   offset 1B..1D: BIOSDSKCHG
	JMP	INIT		;offset 00 - boot entry (kernel never calls)
	JMP	STATUS		;offset 03 - BIOSSTAT
	JMP	CONIN		;offset 06 - BIOSIN
	JMP	CONOUT		;offset 09 - BIOSOUT
	JMP	PRINT		;offset 0C - BIOSPRINT
	JMP	AUXIN		;offset 0F - BIOSAUXIN
	JMP	AUXOUT		;offset 12 - BIOSAUXOUT
	JMP	DREAD		;offset 15 - BIOSREAD
	JMP	DWRITE		;offset 18 - BIOSWRITE
	JMP	DCHG		;offset 1B - BIOSDSKCHG

;-------------- Console / character handlers --------------
STATUS:
	MOV	AH,1
	INT	16H
	JZ	STAT0
	OR	AL,AL
	JNZ	STAT1
	MOV	AL,1
STAT1:
	RET	L
STAT0:
	XOR	AL,AL
	RET	L

CONIN:
	XOR	AH,AH
	INT	16H
	OR	AL,AL
	JNZ	CIRET
	MOV	AL,0
CIRET:
	RET	L

CONOUT:
	PUSH	AX
	PUSH	BX
	MOV	AH,0EH
	XOR	BX,BX
	INT	10H
	POP	BX
	POP	AX
	RET	L

PRINT:
	PUSH	AX
	PUSH	DX
	XOR	AH,AH
	XOR	DX,DX
	INT	17H
	POP	DX
	POP	AX
	RET	L

AUXIN:
	PUSH	DX
	MOV	AH,2
	XOR	DX,DX
	INT	14H
	POP	DX
	RET	L

AUXOUT:
	PUSH	AX
	PUSH	DX
	MOV	AH,1
	XOR	DX,DX
	INT	14H
	POP	DX
	POP	AX
	RET	L

DCHG:
	MOV	AH,1		;disk not changed
	RET	L

;-------------- Disk read/write --------------
DREAD:
	;Marker @ to show DREAD invoked
	PUSH	AX
	PUSH	BX
	MOV	AL,"@"
	MOV	AH,0EH
	XOR	BX,BX
	INT	10H
	POP	BX
	POP	AX
	MOV	AH,2
	JP	DXFER
DWRITE:
	MOV	AH,3
DXFER:
;In:  AL=drive, AH=fn (2 read / 3 write), CX=count, DX=LBA, DS:BX=buffer
;Out: CY=0/1, AL=0/2
	PUSH	ES
	PUSH	DS
	POP	ES		;ES = DS for INT 13H buffer
	MOV	DI,AX		;preserve fn:drive across iterations

DXLP:
	PUSH	CX
	PUSH	DX

	MOV	AX,DX
	MOV	CL,SECTRK
	DIV	AL,CL		;AL=cyl, AH=sec_in_track
	MOV	CH,AL
	MOV	CL,AH
	INC	CL

	MOV	AX,DI		;recover original fn:drive
	MOV	DL,AL		;DL = drive
	MOV	DH,0
	MOV	AL,1		;one sector

	INT	13H

	POP	DX
	POP	CX
	JC	DXERR

	INC	DX
	ADD	BX,512
	LOOP	DXLP

	POP	ES
	XOR	AL,AL
	CLC
	RET	L

DXERR:
	POP	ES
	MOV	AL,2
	STC
	RET	L

;-------------- Data tables --------------
;Drive parameter table for 160 KB SSDD
DPTA:
	DW	512		;SECSIZ
	DB	1		;CLUSSIZ (sectors per cluster)
	DW	1		;FIRFAT (LBA of first FAT sector)
	DB	2		;FATCNT
	DW	64		;MAXENT (root entries)
	DW	320		;DSKSIZ -- TOTAL physical sectors (matches PC-DOS 1.00)

;Init table for DOSINIT.
;Match PC-DOS 1.00 layout: NUMDRV=4, all 4 drive pointers point to DPTA.
;Single physical drive but 4 logical letters (A,B,C,D) for floppy swapping.
INITTAB:
	DB	4		;NUMDRV
	DW	DPTA
	DW	DPTA
	DW	DPTA
	DW	DPTA
	DW	0		;max buffer (kernel reads but discards)

;FCB for COMMAND.COM
FCB:
	DB	1		;drive 1 = A: (explicit, matches SCP DOSIO convention)
	DB	"COMMAND"
	DB	" "
	DB	"COM"
	DS	25

CMDSEG:	DW	0		;COMMAND.COM segment, set during INIT

;-------------- INIT --------------
;Boot sector entered with: DS=0, ES=0, SS:SP=0:7C00, CS=0060.
;Goal: bring up DOS, load COMMAND.COM, transfer control.
INIT:
	;Immediate marker before any setup
	MOV	AL,"I"
	MOV	AH,0EH
	XOR	BX,BX
	INT	10H

	CLI
	;Stack lives in 0050:0000..0050:0100 (linear 0x500..0x600), the
	;BIOS scratch area below IBMBIO. Avoids clobbering IBMDOS at 0x700+.
	MOV	AX,50H
	MOV	SS,AX
	MOV	SP,100H
	PUSH	CS
	POP	DS
	PUSH	CS
	POP	ES
	STI

	;Marker after segment setup
	MOV	AL,"S"
	MOV	AH,0EH
	XOR	BX,BX
	INT	10H

	;Marker before far call
	MOV	AL,"K"
	MOV	AH,0EH
	XOR	BX,BX
	INT	10H

	;Far CALL DOS init at DOSSEG:0
	MOV	SI,INITTAB
	CALL	0,DOSSEG

	;DOSINIT changes DS to kernel CS during CONTINIT and never restores
	;it. Re-set DS=ES=our segment so FCB references resolve correctly.
	PUSH	CS
	POP	DS
	PUSH	CS
	POP	ES

	;Marker right after DOSINIT returns and DS restored
	MOV	AL,"X"
	MOV	AH,0EH
	XOR	BX,BX
	INT	10H

	MOV	AL,"D"
	CALL	PCH

	;Open COMMAND.COM via INT 21H fn 0FH
	MOV	DX,FCB
	MOV	AH,0FH
	INT	21H
	PUSH	AX
	MOV	AL,"O"
	MOV	AH,0EH
	XOR	BX,BX
	INT	10H
	POP	AX
	OR	AL,AL
	JNZ	BADCMD

	;Read COMMAND.COM target segment from kernel-installed INT 22h
	;vector at 0:008A. Save in CS:CMDSEG so we can FAR-JMP after load.
	XOR	AX,AX
	MOV	DS,AX
	MOV	BX,[8AH]	;BX = COMMAND.COM segment
	PUSH	CS
	POP	DS
	MOV	[CMDSEG],BX

	;Set DTA = CMDSEG:0100H so block read lands inside COMMAND segment
	;(NOT our IBMBIO segment which would corrupt our code).
	MOV	DX,100H
	PUSH	DS
	MOV	DS,BX
	MOV	AH,1AH
	INT	21H
	POP	DS

	MOV	AL,"T"
	MOV	AH,0EH
	XOR	BX,BX
	INT	10H

	;Set FCB record length 1 and random record 0
	MOV	W,[FCB+14],1
	MOV	W,[FCB+33],0
	MOV	W,[FCB+35],0

	;Block read 4 KB into CMDSEG:0100H
	MOV	CX,4096
	MOV	DX,FCB
	MOV	AH,27H
	INT	21H
	MOV	AL,"R"
	MOV	AH,0EH
	XOR	BX,BX
	INT	10H

	;Slot 0 of jump table is now permanently "JMP INIT". Kernel never
	;calls 60:0, only 60:3 (BIOSSTAT) and beyond. No rewrite needed.

	MOV	AL,"C"
	CALL	PCH

	;Far jump into COMMAND.COM at CMDSEG:0100H (saved earlier)
	MOV	DX,[CMDSEG]
	PUSH	DX
	MOV	AX,100H
	PUSH	AX
	;Set DS = CMDSEG so COMMAND.COM has proper PSP-segment DS
	MOV	DS,DX
	MOV	ES,DX
	RET	L

BADCMD:
	MOV	AL,"!"
	CALL	PCH
HANG:
	HLT
	JP	HANG

;Helper: print AL via INT 10H teletype
PCH:
	PUSH	AX
	PUSH	BX
	MOV	AH,0EH
	XOR	BX,BX
	INT	10H
	POP	BX
	POP	AX
	RET
