	.data

nib:				.byte   0
num:				.byte   0xC0, 0xF9, 0xA4, 0xB0, 0x99, 0x92, 0x82, 0xF8, 0x80, 0x90
offset:				.word 0

prompt:			.string  "7 Segment Display Test :)", 0
prompt1:			.string "Press ESC to Exit JK DONT", 0
usr_string:			.string "                                ", 0

	.text
	.global sev_seg
	.global UART0_Handler
	.global Timer0_Handler
	.global Timer1_Handler

ptr_to_nib:	    .word nib
ptr_to_offset:	.word offset
ptr_to_num:	    .word num

ptr_to_prompt:	.word prompt
ptr_to_prompt1: .word prompt1

ptr_to_usr_string:		.word usr_string

sev_seg:
    PUSH {lr}

    BL uart_init
   ; BL uart_interrupt_init
    BL spi_init
    BL Timer0_Init
    BL Timer1_Init

	;Unlatch before
	;GPIO Port C Data Register Address
	MOV r5, #0x63FC
	MOVT r5, #0x4000

	LDR r6, [r5]
	BIC r6, r6, #0x40
	STR r6, [r5]


	;Clear Screen
	MOV r0, #0xC
	BL output_character

	;Menu Display stuff
	ldr r4, ptr_to_prompt
	MOV r0, r4
	BL output_string
	ldr r4, ptr_to_prompt1
	MOV r0, r4
	BL output_string



start:
	B start

	;ldr r5, ptr_to_usr_string
	;MOV r0, r5
	;BL read_string

exit:
    POP {lr}
    MOV pc, lr
;------------------------------------------------------------------------------------

spi_transmit:
    PUSH {lr}
    PUSH {r4, r5}

    MOV r4, #0xA000
    MOVT r4, #0x4000

;Polling loop to see if SPI is ready to transmit
ready_to_send:
	LDR r1, [r4, #0x00C]
	AND r1, r1, #0x10		;Isolate bit 4
	CMP r1, #0
	BNE ready_to_send

translate:

	STRH r0, [r4, #0x008]		;Places user entered byte into SSDIR register to start transmission

loop:
	LDR r1, [r4, #0x00C]
	AND r1, r1, #0x10		;Isolate bit 4
	CMP r1, #0
	BNE loop

latch:
	;GPIO Port C Data Register Address
	MOV r5, #0x63FC
	MOVT r5, #0x4000

	LDR r6, [r5]
	BIC r6, r6, #0xFF
	ORR r6, r6, #0x80
	STR r6, [r5]
	BL not_a_fork_bomb
	B unlatch

unlatch:
	;GPIO Port C Data Register Address
	MOV r5, #0x63FC
	MOVT r5, #0x4000

	LDR r6, [r5]
	BIC r6, r6, #0x80
	STR r6, [r5]
	B exit_spi


exit_spi:

	MOV r8, #0
	STRB r8, [r7]

	POP {r4, r5}
	POP {lr}
	MOV pc, lr
;---------------------------------------------
modulo:

    PUSH {lr}
    PUSH {r1}

	MOV r1, #10
    SDIV r0, r0, r1
    MULT r0, r0, r1
    SUB r0, r5, r0      ;gives remainder

	POP {r1}
    POP {lr}
    MOV pc, lr


;-------------------------------Handlers--------------------------------
;This handles changing digits on 87 segment display
Timer0_Handler:

	PUSH {r4,r5,r6,r7,r8,r9,r10,r11,lr}
	PUSH {r0, r1, r2}

	;clear timer interrupt flag
	MOV r0, #0x0000
	MOVT r0, #0x4003
	LDRB r1, [r0, #0x024]
	ORR r1, r1, #1
	STRB r1, [r0, #0x024]

	ldr r0, ptr_to_offset
	LDR r1, [r0]
	ADD r1, r1, #1
	STR r1, [r0]

	;ADD r3, r3, #1

exit_handle:

	POP {r0, r1, r2}
	POP {r4,r5,r6,r7,r8,r9,r10,r11,lr}
	BX lr

;-----------------------------------------------------------------------------
;This strobes the 4 displays
Timer1_Handler:

	PUSH {r4,r5,r6,r7,r8,r9,r10,r11,lr}

	;clear timer interrupt flag
	MOV r0, #0x1000
	MOVT r0, #0x4003
	LDRB r1, [r0, #0x024]
	ORR r1, r1, #1
	STRB r1, [r0, #0x024]

	ldr r10, ptr_to_num  ;list of numbers

	ldr r4, ptr_to_offset
	LDR r5, [r4]		;current value that should be displayed

	;Digit stuff
	MOV r9, #10


;Move data into R0 for modulo
;R5 needs to be div 10 and modded
disp_1:
	MOV r0, r5
	BL modulo
	LDRB r7, [r10, r0]		;load value from num list with offset of first digit
	LSL r7, r7, #8
	ORR r7, r7, #0x0001
	MOV r0, r7
	BL spi_transmit

disp_2:
	SDIV r5, r5, r9     ;divide by 10
	MOV r0, r5
	BL modulo
	LDRB r7, [r10, r0]
	LSL r7, r7, #8
	ORR r7, r7, #0x0002
	MOV r0, r7
	BL spi_transmit

disp_3:
	SDIV r5, r5, r9
	MOV r0, r5
	BL modulo
	LDRB r7, [r10, r0]
	LSL r7, r7, #8
	ORR r7, r7, #0x0004
	MOV r0, r7
	BL spi_transmit

disp_4:
	SDIV r5, r5, r9
	MOV r0, r5
	BL modulo
	LDRB r7, [r10, r0]
	LSL r7, r7, #8
	ORR r7, r7, #0x0008
	MOV r0, r7
	BL spi_transmit



exitthing:
	POP {r4,r5,r6,r7,r8,r9,r10,r11,lr}
	BX lr

;----------------------------------------------------------------------------

;DONT USE RN
UART0_Handler:

	PUSH {r4,r5,r6,r7,r8,r9,r10,r11,lr}

	;clear the interrupt flag
	MOV r0, #0xC000
	MOVT r0, #0x4000
	LDRB r1, [r0, #0x044]
	ORR r1, r1, #0x10
	STRB r1, [r0, #0x044]

	;WHEN PERSON PUSHES BUTTON DO SOMETHING
	BL read_character ;returns data in r0
	BL spi_transmit
	BL output_character

	POP {r4,r5,r6,r7,r8,r9,r10,r11,lr}

	BX lr       	; Return

;-----------------------------Initializations----------------------------
spi_init:
	PUSH {lr}

	;RCGSSI Address
	MOV r0, #0xE000
	MOVT r0, #0x400F

	;Enable SSI2 clock (offset 61C)
	LDRB r1, [r0, #0x61C]
	ORR r1, r1, #4
	STRB r1, [r0, #0x61C]

	;Enable clock for GPIO Port B, C, and D
	LDRB r1, [r0, #0x608]
	ORR r1, r1, #0xE
	STRB r1, [r0, #0x608]

	;Port B Base Address
	MOV r0, #0x5000
	MOVT r0, #0x4000

	;Enable port B pin 4 & 7 as digital
	LDRB r1, [r0, #0x400]
	ORR r1, #0x90
	STRB r1, [r0, #0x400]

	;Enable port B pin 4 & 7 as output
	LDRB r1, [r0, #0x51C]
	ORR r1, r1, #0x90
	STRB r1, [r0, #0x51C]

	;Changes AFSEL Reg for pins 4 and 7 by writing a 1 to it
	LDRB r1, [r0, #0x420]
	ORR r1, r1, #0x90
	STRB r1, [r0, #0x420]

	;Pick Alternate Function by writing 2 to pins 4 & 7 to use SPI
	LDR r1, [r0, #0x52C]
	BIC r1, #0xF0000000 ;clear bits first
	BIC r1, #0xF0000	;clear bits first
	ORR r1, r1, #0x20000000
	ORR r1, r1, #0x20000
	STR r1, [r0, #0x52C]

	;GPIO Port C Address
	MOV r0, #0x6000
	MOVT r0, #0x4000

	;Enable port C pin 6 as digital
	LDRB r1, [r0, #0x400]
	ORR r1, #0x40
	STRB r1, [r0, #0x400]
	;Enable port C pin 6 as output
	LDRB r1, [r0, #0x51C]
	ORR r1, r1, #0x40
	STRB r1, [r0, #0x51C]

	;Enable Port C pin 7 as GPIO digital output        <----------------------------
	;THIS IS FOR CHIP SELECT BETWEEN 2 SHIFT REGISTERS <----------------Important
	LDRB r1, [r0, #0x400]
	ORR r1, #0x80
	STRB r1, [r0, #0x400]
	LDRB r1, [r0, #0x51C]
	ORR r1, r1, #0x80
	STRB r1, [r0, #0x51C]

	;SSI2 Base Addr: 0x4000A000
	MOV r0, #0xA000
	MOVT r0, #0x4000

	;Disable SSI2 to configure it as master
	;Start by disabling SSE by writing 0 to bit 1,
	;Write 0 to bit 2 (MS) to configure as master
	LDRB r1, [r0, #0x004] ;004 = SSICR1 offset
	BIC r1, r1, #6
	STRB r1, [r0, #0x004]

	;Configure SPI Clock to use system clock by writing 0
	LDRB r1, [r0, #0xFC8] ;FC8 = SSICC offset
	BIC r1, r1, #0xF
	STRB r1, [r0, #0xFC8]

	;Set SPI Clock divisior to 4MHz (Divide by 4)
	LDRB r1, [r0, #0x010]
	BIC r1, r1, #0xF
	ORR r1, r1, #4
	STRB r1, [r0, #0x010]

	;Configure SPI Data Size to 16-bit by writing F to DSS
	LDRB r1, [r0]
	;BIC r1, r1, #0xF
	ORR r1, r1, #0xF
	STRB r1, [r0]

	;Reenable SPI
	LDRB r1, [r0, #0x004]
	ORR r1, r1, #2
	STRB r1, [r0, #0x004]

	POP {lr}
	MOV pc, lr

;----------------------------------------------------------------------------------

uart_init:
	PUSH {lr}

;Enables clock for UART0
	MOV r0, #0xE618
	MOVT r0, #0x400F
	MOV r1, #1
	STR r1, [r0]
;Enables clock for PORTA
	MOV r0, #0xE608
	MOVT r0, #0x400F
	MOV r1, #1
	STR r1, [r0]
;Disables UART0 control
	MOV r0, #0xC030
	MOVT r0, #0x4000
	MOV r1, #0
	STR r1, [r0]
	;Sets the Baud Rate for UART0_IBRD_R to 115,200
	MOV r0, #0xC024
	MOVT r0, #0x4000
	MOV r1, #8
	STR r1, [r0]
	;Sets the Baud Rate for UART0_FBRD_R to 115,200
	MOV r0, #0xC028
	MOVT r0, #0x4000
	MOV r1, #44
	STR r1, [r0]
	;Ensures we are using the system clock
	MOV r0, #0xCFC8
	MOVT r0, #0x4000
	MOV r1, #0
	STR r1, [r0]
	;Sets the word length to 8 bits with 1 stop bit and no parity bits
	MOV r0, #0xC02C
	MOVT r0, #0x4000
	MOV r1, #0x60
	STR r1, [r0]
	;Enables UART0 Control
	MOV r0, #0xC030
	MOVT r0, #0x4000
	MOV r1, #0x301
	STR r1, [r0]

	;Sets PA0 to Digital Port
	MOV r0, #0x451C
	MOVT r0, #0x4000
	LDR r1, [r0]
	ORR r1, r1, #0x03
	STR r1, [r0]
	;Sets PA1 to Digital Port
	MOV r0, #0x4420
	MOVT r0, #0x4000
	LDR r1, [r0]
	ORR r1, r1, #0x03
	STR r1, [r0]
	;Configures PA0 and PA1 for UART0
	MOV r0, #0x452C
	MOVT r0, #0x4000
	LDR r1, [r0]
	ORR r1, r1, #0x11
	STR r1, [r0]

	POP {lr}
	mov pc, lr

;-------------------------------------------------------------------------------

uart_interrupt_init:

	PUSH {lr}

;Loads UARTIM address
	MOV r0, #0xC000
	MOVT r0, #0x4000

	;Sets RIXM for UART
	LDR r1, [r0, #0x038]
	ORR r1, r1, #0x10
	STR r1, [r0, #0x038]

	;Clear UART Interrupt
	LDRB r1, [r0, #0x044]
	ORR r1, r1, #0x10
	STRB r1, [r0, #0x044]

	;Configures processor to allow UART to interrupt processor
	;Load Interrupt Set Enable Register
	MOV r0, #0xE000
	MOVT r0, #0xE000

	LDRB r1, [r0, #0x100]
	ORR r1, r1, #0x20
	STRB r1, [r0, #0x100]

	POP {lr}
	MOV pc, lr

;-----------------------------------------------------------------------------
;Configures timer 1
Timer1_Init:

  PUSH {lr}

  ;Connects clock to Timer1 by writing a 1 to bit 1
  MOV r0, #0xE604
  MOVT r0, #0x400F
  LDRB r1, [r0]
  ORR r1, r1, #2
  STRB r1, [r0]

  ;Disables timer1 by writing a 0 to bit 0
  MOV r0, #0x1000
  MOVT r0, #0x4003
  LDRB r1, [r0, #0x00C]
  BFC r1, #0, #1
  STRB r1, [r0, #0x00C]

  ;Set Timer1 to 32-bit mode
  LDRB r1, [r0]
  BFC r1, #0, #3
  ;ORR r1, r1, #1
  STRB r1, [r0]

  ;Set Timer1 to be in periodic mode
  LDRB r1, [r0, #0x004]
  BFC r1, #0, #2
  ORR r1, r1, #0x2
  STRB r1, [r0, #0x004]

  ;set initial interrupt period to 1 second
  MOV r1, #0x0640
  MOVT r1, #0x0000
  STR r1, [r0, #0x028]


  ;Enable Timer1 to interrupt processor
  LDRB r1, [r0, #0x018]
  ORR r1, r1, #1
  STRB r1, [r0, #0x018]


  ;Configure processor to allow Timer1 to interrupt (Write 1 to bit 21 for Timer1A)
  MOV r0, #0xE000
  MOVT r0, #0xE000
  LDR r1, [r0, #0x100]
  ORR r1, r1, #0x200000
  STR r1, [r0, #0x100]

  ;Interrupt Servicing, clears interrupt
  MOV r0, #0x1000
  MOVT r0, #0x4003
  LDRB r1, [r0, #0x024]
  ORR r1, r1, #1
  STRB r1, [r0, #0x024]

  ;Enables timer1 by writing a 1 to bit 0
  LDRB r1, [r0, #0x00C]
  ORR r1, r1, #1
  STRB r1, [r0, #0x00C]

  POP {lr}
  MOV pc, lr

;------------------------------------------------------------------------------------------
Timer0_Init:

  PUSH {lr}

  ;Connects clock to Timer0 by writing a 1 to bit 0
  MOV r0, #0xE604
  MOVT r0, #0x400F
  LDRB r1, [r0]
  ORR r1, r1, #1
  STRB r1, [r0]

  ;Disables Timer0 by writing a 0 to bit 0
  MOV r0, #0x0000
  MOVT r0, #0x4003
  LDRB r1, [r0, #0x00C]
  BFC r1, #0, #1
  STRB r1, [r0, #0x00C]

  ;Set Timer0 to 32-bit mode
  LDRB r1, [r0]
  BFC r1, #0, #3
  ;ORR r1, r1, #1
  STRB r1, [r0]

  ;Set Timer0 to be in periodic mode
  LDRB r1, [r0, #0x004]
  BFC r1, #0, #2
  ORR r1, r1, #0x2
  STRB r1, [r0, #0x004]

  ;set initial interrupt period (MODIFY THIS LINE TO MAKE FASTER/SLOWER)
  ;MOV r1, #0x6A00
  ;MOVT r1, #0x0018
  MOV r1, #0xFFFF
  MOVT r1, #0x000A
  STR r1, [r0, #0x028]


  ;Enable Timer0 to interrupt processor
  LDRB r1, [r0, #0x018]
  ORR r1, r1, #1
  STRB r1, [r0, #0x018]


  ;Configure processor to allow Timer0 to interrupt
  MOV r0, #0xE000
  MOVT r0, #0xE000
  LDR r1, [r0, #0x100]
  ORR r1, r1, #0x80000
  STR r1, [r0, #0x100]

  ;Interrupt Servicing, clears interrupt
  MOV r0, #0x0000
  MOVT r0, #0x4003
  LDRB r1, [r0, #0x024]
  ORR r1, r1, #1
  STRB r1, [r0, #0x024]

  ;Enables timer0 by writing a 1 to bit 0
  MOV r0, #0x0000
  MOVT r0, #0x4003
  LDRB r1, [r0, #0x00C]
  ORR r1, r1, #1
  STRB r1, [r0, #0x00C]


  POP {lr}

  MOV pc, lr

;---------------------------------------------------------------------------------------

;--------------------------------OLD CODE-----------------------------------------------

simple_read_character:

	PUSH {lr}   ; Store register lr on stack

	MOV r1, #0xC000				;Load from mem the UART Data Register
	MOVT r1, #0x4000

	LDRB r2, [r1]				;Grab the first byte, "data" section holding the character that was pressed on the keyboard
	MOV r0, r2					;Pass to r0 for output character can use it

	POP {lr}
	MOV PC,LR      	; Return

;-----------------------------------------------------------------------------------------

output_character:
	PUSH {lr}   ; Store register lr on stack
	PUSH {r3}

		; Your code for your output_character routine is placed here

	MOV r1, #0xC018; load bottom of flag register address into r1
	MOVT r1, #0x4000; load top of flag register address into r1
	MOV r2, #0xC000; load bottom of data register address into r2
	MOVT r2, #0x4000; load top of data register address into r2

mysillylittlelabel:
	LDRB r3, [r1]; load value in flag register into r3
	AND r3, r3, #0x20; mask to get value of TxFF
	CMP r3, #0; see if TxFF is zero yet
	BNE mysillylittlelabel; if TxFF is not zero yet, load and check agaiN
	CMP r0, #0xD
	BEQ fixreturn
	STRB r0, [r2]; if TxFF is zero, store value of r0 in data register
	B afterfixreturn
fixreturn:
	STRB r0, [r2]
	MOV r0, #0xA
	B mysillylittlelabel
afterfixreturn:
	POP {r3}
	POP {lr}
	mov pc, lr

;------------------------------------------------------------------------

not_a_fork_bomb:;runs a ton of instructions to give time for the pull up register to actually set. Is actually not a fork bomb just a loop
	PUSH {lr}
	PUSH{r0}
	PUSH{r1}

	MOV r0, #0x00FF
	MOV r1, #0

perhaps_a_fork_bomb:
	SUB r0, r0, #1
	CMP r0, r1
	BEQ nomorefork
	B perhaps_a_fork_bomb

nomorefork:
	POP {r1}
	POP {r0}
	POP {lr}

	MOV pc, lr

	POP {lr}
	MOV pc, lr

;------------------------------------------------------------------------

read_string:
  PUSH {lr}; reads standard input and stores at address beginning at r0
  MOV r1, r0

read_stringloop:
  PUSH {r1}
  BL read_character;get the character
  BL output_character;print the character
  POP {r1}
  CMP r0, #0xA;check character for enter
  BEQ RSend;if enter, store null byte instead
  STRB r0, [r1];store byte if not enter
  ADD r1, r1, #1;increment memory store pointer
  B read_stringloop

RSend:
  MOV r0, #0
  STRB r0, [r1];store null byte
  POP{lr}
  MOV pc, lr

;---------------------------------------------------------------------------------------------------------------------------------------------------------------

read_character:
	PUSH {lr}   ; Store register lr on stack
	PUSH {r3}


	MOV r1, #0xC018				;These two lines move the flag data register address from mem into r1
	MOVT r1, #0x4000

rcharloop:
	LDRB r3, [r1]				;Offset to reach TxFF and TxFE
	AND r3, r3, #0x10			;AND Logic to isolate bit stored in TxFE register

	CMP r3, #0					;If 0, flag is set and register is holding a value
	BEQ gotit
	B rcharloop						;Reload and AND again if flag is a 1, meaning register is empty

gotit:
	MOV r1, #0xC000				;Load from mem the UART Data Register
	MOVT r1, #0x4000

	LDRB r3, [r1]				;Grab the first byte, "data" section holding the character that was pressed on the keyboard
	MOV r0, r3					;Pass to r0 for output character can use it

	POP {r3}
	POP {lr}
	mov pc, lr

;-----------------------------------------------------------------------------------------

string2int:
	PUSH {lr}   ; Store register lr on stack
	PUSH {r3}

	MOV r2, #0	;This keeps track of the decimal, ensuring the individual digits get added properly into the correct 10s spot
	MOV r3, #10	;Constant allowing us to multiply by 10 inside of loop

s2iloop:
	LDRB r1, [r0]	;Loads the first digit from memory

	CMP r1, #0x00		;Check is value in r1 is ASCII Null, which means it's the end of the number
	BEQ FINISH		;This means the string is over, as a NULL byte indicates the end of the string

	MUL r2, r2, r3	;Move decimal to the right 1
	SUB	r1, r1, #48	;Converts ASCII value to its true value
	ADD r2, r2, r1	;Places value into r2 before decimal is moved again
	ADD r0, r0, #0x1 ;Increment pointer to go to next digit in memory

	B s2iloop

FINISH:
	MOV r0, r2

	POP {r3}
	POP {lr}
	mov pc, lr
;-----------------------------------------------------------------------------------------

output_string:
	PUSH {lr};prints the null terminated string starting at address in r0 to standard output
	MOV r1, r0; put mem adress in r1 since r0 will be changed

OSloop:
	LDRB r0, [r1]; get byte at mem pointer
	CMP r0, #0; check to see if null byte hit
	BEQ OSend
	PUSH {r1}
	BL output_character
	POP {r1}
	ADD r1, r1, #1; increment memory pointer to next digit
	B OSloop

OSend:
	MOV r0, #0xD; if null byte, load value for "enter" instead
	BL output_character
	POP {lr}
	MOV pc, lr

.end
