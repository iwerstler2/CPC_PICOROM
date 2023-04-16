TXT_OUTPUT: 	EQU $BB5A
IO_PORT:		EQU $DFFC
CMD_PICOLOAD	EQU $FF
CMD_LED:		EQU $FE
CMD_CFGLOAD:	EQU $FD
CMD_CFGSAVE:	EQU $FC
CMD_464:		EQU 3
CMD_6128:		EQU 4
CMD_664:		EQU 5
CMD_FW31:		EQU 6
CMD_ROMIN:		EQU $10
CMD_ROMOUT:		EQU $11



		org $c000
		defb    1       ; background rom
		defb    0
		defb    0
		defb    1
		defw NAME_TABLE
		jp INIT
		jp BOOT
		jp LED
		jp ROM_DIR
		jp GO_464
		jp GO_664
		jp GO_6128
		jp GO_FW31
		jp ROMIN
		jp ROMOUT
		jp ROMLIST
		jp CFGLOAD
		jp CFGSAVE

		
		ALIGN $100
RESP_BUF:
		; RESP_BUF
		; 0 - sequence number, increased by Pico for each response
		; 1 - status code. 0=OK
		; 2 - data type. 1 = 0 terminated string
		; 3.. data
		DEFS $100, 0

		ASSERT RESP_BUF == $100

NAME_TABLE:	
		defm  "PICO RO",'M'+128
		defm  "PICOLOA", 'D'+128
		defm  "LE", 'D'+128
		defm  "ROMDI", 'R'+128
		defm  "CPC46", '4'+128
		defm  "CPC66", '4'+128
		defm  "CPC612", '8'+128
		defm  "FW3", '1'+128
		defm  "ROMI", 'N'+128
		defm  "ROMOU", 'T'+128
		defm  "ROMLIS",'T'+128
		defm  "CFGLOA",'D'+128
		defm  "CFGSAV",'E'+128
		defb    0

; 
		MACRO CMD_1P cmd, invalid_msg
		LOCAL wait, invalid
		cp a, 1		; num params
		jp	nz,	invalid
		ld hl, RESP_BUF
		ld a, (hl)		; get current sequence number in A
		ld BC, IO_PORT
		out (c), c
		ld c, cmd
		out (c),c
		ld c,(IX)	; param
		out (c), c
.wait
		cp (hl)			; wait for the sequence number to be updated
		jr z,wait
		ret
.invalid
		ld hl, invalid_msg
		call disp_str
		ret
		ENDM

;
		MACRO CMD_0P_NOWAIT cmd
		ld BC, IO_PORT 	; command prefix
		out (c), c
		ld c, cmd 	; command byte
		out (c), c
		ret
		ENDM


INIT:	
		push HL
		ld HL, START_MSG
		call disp_str
		pop HL
		ret
		
START_MSG:	
		defm  " Pico ROM v0.0.1",0x0d,0x0a,0x0d,0x0a,0x00

IP_MSG:	
		defm  "Invalid parameters",0x0d,0x0a,0x0d,0x0a,0x00


LED:		CMD_1P CMD_LED, IP_MSG
CFGSAVE:	CMD_1P CMD_CFGSAVE, IP_MSG
CFGLOAD:	CMD_1P CMD_CFGLOAD, IP_MSG

BOOT:		CMD_0P_NOWAIT CMD_PICOLOAD
GO_464: 	CMD_0P_NOWAIT CMD_464
GO_664: 	CMD_0P_NOWAIT CMD_664
GO_6128: 	CMD_0P_NOWAIT CMD_6128
GO_FW31: 	CMD_0P_NOWAIT CMD_FW31



ROM_DIR:
		ld hl, RESP_BUF
		ld a, (hl)		; get current sequence number in A
		ld BC, IO_PORT 	; command prefix
		out (c), c
		ld BC, $DF01 	; command byte
		out (c), c
WAIT:
		cp (hl)			; wait for the sequence number to be updated
		jr z, WAIT
		inc hl		; point to status code 
		ld a, (hl)
		or a
		jr nz,  ROM_DIR_DONE
		inc hl		; skip data type # FIXME
		inc hl		; point to start of response
		call disp_str
		call cr_nl
		; get next
		ld hl, RESP_BUF
		ld a, (hl)		; get current sequence number in A
		ld BC, IO_PORT	; command prefix
		out (c), c
		ld BC, $DF02 	; command byte
		out (c), c
		jr		WAIT
ROM_DIR_DONE:
		call cr_nl
		ret

ROMIN:
		cp	2
		jr	nz, RI_USAGE
		ld BC, IO_PORT 	; command prefix
		out (c), c
		ld C, $10 	; command byte
		out (c), c
		ld C, (IX+0)
		out (c), c
		ld C, (IX+2)
		out (c), c
		jr	RI_DONE
RI_USAGE:
		ld hl, RI_U_MSG
		call disp_str
RI_DONE:
		ret
RI_U_MSG:
		defm  " Usage |ROMIN,<ROM SLOT>,<ROM Number>",0x0d,0x0a,0x0d,0x0a,0x00

ROMOUT:		CMD_1P CMD_ROMOUT, RO_U_MSG
RO_U_MSG:
		defm  " Usage |ROMOUT,<ROM SLOT>",0x0d,0x0a,0x0d,0x0a,0x00

ROMLIST:
		ret

cr_nl:
		push af
		ld A, 0x0d
		call TXT_OUTPUT
		ld A, 0x0a
		call TXT_OUTPUT
		pop af
		ret

disp_str:	; display 0 terminated string, pointed to by HL
		push af
disp_str1:	
		ld A, (HL)
		call TXT_OUTPUT
		inc HL
		or A
		jr nz, disp_str1
		pop af
		ret
END:
		DEFS $4000-END