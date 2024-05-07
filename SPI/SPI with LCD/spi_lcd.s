	.data

nib:			.byte	0
prompt:			.string "Enter anything to see it appear on the LCD :)", 0
prompt1:			.string "Press ESC to Exit", 0
usr_string			.string "                                ", 0

	.text
	.global spi_lcd
	.global UART0_Handler


GPIODATA:		.equ	0x3FC		; Offset for GPIO Data Register
ptr_to_nib:	.word nib
ptr_to_prompt:	.word prompt
ptr_to_prompt1: .word prompt1


ptr_to_usr_string:		.word usr_string

spi_lcd:
    PUSH {lr}

    BL uart_init
   ; BL uart_interrupt_init
    BL spi_init


    ;LCD Init Commands (Place in r0)
    MOV r0, #0x33
    BL lcd_init
    MOV r0, #0x32
    BL lcd_init
    MOV r0, #0x28
    BL lcd_init
    MOV r0, #0x01
    BL lcd_init
    MOV r0, #0x0F
    BL lcd_init
    MOV r0, #0x06
    BL lcd_init
	MOV r0, #0x80
	BL lcd_init

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

	BL read_character
	CMP r0, #27  ;user pressed ESC
	BEQ exit
	BL output_character
	BL spi_transmit
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

	MOV r4, #0xA000
	MOVT r4, #0x4000

;Polling loop to see if SPI is ready to transmit
ready_to_send:
	LDR r1, [r4, #0x00C]
	AND r1, r1, #0x10		;Isolate bit 4
	CMP r1, #0
	BNE ready_to_send

first_nib:
	MOV r3, #0    ;Initialize it to 0
	ORR r3, r3, r0  ;Copy data into r3
	AND r3, r3, #0xF0  ;Isolate first nibble
	ORR r3, r3, #0x03  ;Set enable bit and data bit

	STRB r3, [r4, #0x008]		;Places user entered byte into SSDIR register to start transmission

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
	ORR r6, r6, #0x40
	STR r6, [r5]
	BL not_a_fork_bomb
	B unlatch

unlatch:
	;GPIO Port C Data Register Address
	MOV r5, #0x63FC
	MOVT r5, #0x4000

	LDR r6, [r5]
	BIC r6, r6, #0x40
	STR r6, [r5]

checker:
	LDR r7, ptr_to_nib
	LDRB r8, [r7]
	CMP r8, #0
	BEQ first_nib_pt2
	CMP r8, #1
	BEQ second_nib
	CMP r8, #2
	BEQ second_nib_pt2
	B exit_spi

;Polling loop to see if SPI is done transmitting
poll:
	LDR r1, [r4, #0x00C]
	AND r1, r1, #0x10		;Isolate bit 4
	CMP r1, #0
	BNE poll

first_nib_pt2:
	BIC r3, r3, #0x03

	STRB r3, [r4, #0x008]		;Places user entered byte into SSDIR register to start transmission

loop1:
	LDR r1, [r4, #0x00C]
	AND r1, r1, #0x10		;Isolate bit 4
	CMP r1, #0
	BNE loop1

	;Change byte so program knows to move on to second nibble
	;r8 should have 0 in it ->switch to 1
	;r7 has ptr to nib
	MOV r8, #1
	STRB r8, [r7]

	B latch

second_nib:
	AND r0, r0, #0x0F
	LSL r0, r0, #4
	ORR r0, r0, #0x03

	STRB r0, [r4, #0x008]		;Places user entered byte into SSDIR register to start transmission
loop2:
	LDR r1, [r4, #0x00C]
	AND r1, r1, #0x10		;Isolate bit 4
	CMP r1, #0
	BNE loop2

	;so program can go to secondnibpt2
	MOV r8, #2
	STRB r8, [r7]

	B latch

second_nib_pt2:
	BIC r0, r0, #0x03
	STRB r0, [r4, #0x008]

loop3:
	LDR r1, [r4, #0x00C]
	AND r1, r1, #0x10		;Isolate bit 4
	CMP r1, #0
	BNE loop3

	;So subroutine can exit
	MOV r8, #3
	STRB r8, [r7]

	B latch

exit_spi:

	MOV r8, #0
	STRB r8, [r7]

	POP {lr}
	MOV pc, lr


;-------------------------------Handlers--------------------------------
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

	;Configure SPI Data Size to 8-bit by writing 7 to DSS
	LDRB r1, [r0]
	BIC r1, r1, #0xF
	ORR r1, r1, #0x7
	STRB r1, [r0]

	;Configure SPI Phase and Polarity by settings bits 6 (SPO) and 7 (SPH) to 0
	;SPO 0 = CLock is low when inactive/not sending data
	;SPH 0 = Data captured on rising edge

	;LDRB r1, [r0]
	;BIC r1, r1, #0xC
	;STRB r1, [r0]

	;Reenable SPI
	LDRB r1, [r0, #0x004]
	ORR r1, r1, #2
	STRB r1, [r0, #0x004]

	POP {lr}
	MOV pc, lr

;----------------------------------------------------------------------------------
lcd_init:
	PUSH {lr}

	MOV r4, #0xA000
	MOVT r4, #0x4000

;Polling loop to see if SPI is ready to transmit
ready_to_send_lcd:
	LDR r1, [r4, #0x00C]
	AND r1, r1, #0x10		;Isolate bit 4
	CMP r1, #0
	BNE ready_to_send_lcd

first_nib_lcd:
	MOV r3, #0    ;Initialize it to 0
	ORR r3, r3, r0  ;Copy data into r3
	AND r3, r3, #0xF0  ;Isolate first nibble
	ORR r3, r3, #0x02  ;Set enable bit and data bit

	STRB r3, [r4, #0x008]		;Places user entered byte into SSDIR register to start transmission

loop5:
	LDR r1, [r4, #0x00C]
	AND r1, r1, #0x10		;Isolate bit 4
	CMP r1, #0
	BNE loop5

latch_lcd:
	;GPIO Port C Data Register Address
	MOV r5, #0x63FC
	MOVT r5, #0x4000

	LDR r6, [r5]
	BIC r6, r6, #0xFF
	ORR r6, r6, #0x40
	STR r6, [r5]
	BL not_a_fork_bomb
	B unlatch_lcd

unlatch_lcd:
	;GPIO Port C Data Register Address
	MOV r5, #0x63FC
	MOVT r5, #0x4000

	LDR r6, [r5]
	BIC r6, r6, #0x40
	STR r6, [r5]

checker_lcd:
	LDR r7, ptr_to_nib
	LDRB r8, [r7]
	CMP r8, #0
	BEQ first_nib_pt2_lcd
	CMP r8, #1
	BEQ second_nib_lcd
	CMP r8, #2
	BEQ second_nib_pt2_lcd
	B exit_spi_lcd

;Polling loop to see if SPI is done transmitting
poll_lcd:
	LDR r1, [r4, #0x00C]
	AND r1, r1, #0x10		;Isolate bit 4
	CMP r1, #0
	BNE poll_lcd

first_nib_pt2_lcd:
	BIC r3, r3, #0x02

	STRB r3, [r4, #0x008]		;Places user entered byte into SSDIR register to start transmission

loop6:
	LDR r1, [r4, #0x00C]
	AND r1, r1, #0x10		;Isolate bit 4
	CMP r1, #0
	BNE loop6

	;Change byte so program knows to move on to second nibble
	;r8 should have 0 in it ->switch to 1
	;r7 has ptr to nib
	MOV r8, #1
	STRB r8, [r7]

	B latch_lcd

second_nib_lcd:
	AND r0, r0, #0x0F
	LSL r0, r0, #4
	ORR r0, r0, #0x02

	STRB r0, [r4, #0x008]		;Places user entered byte into SSDIR register to start transmission

loop7:
	LDR r1, [r4, #0x00C]
	AND r1, r1, #0x10		;Isolate bit 4
	CMP r1, #0
	BNE loop7

	;so program can go to secondnibpt2
	MOV r8, #2
	STRB r8, [r7]

	B latch_lcd

second_nib_pt2_lcd:
	BIC r0, r0, #0x02
	STRB r0, [r4, #0x008]

loop9:
	LDR r1, [r4, #0x00C]
	AND r1, r1, #0x10		;Isolate bit 4
	CMP r1, #0
	BNE loop9

	;So subroutine can exit
	MOV r8, #3
	STRB r8, [r7]

	B latch_lcd

exit_spi_lcd:

	MOV r8, #0
	STRB r8, [r7]

	POP {lr}
	MOV pc, lr



uart_init:
	PUSH {lr}  ; Store register lr on stack

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


	MOV pc, lr

;-----------------------------------------------------------------------------

Timer_Init:

  PUSH {lr}

  ;Connects clock to Timer1 by writing a 1 to bit 0
  MOV r0, #0xE604
  MOVT r0, #0x400F
  LDRB r1, [r0]
  ORR r1, r1, #1
  STRB r1, [r0]

  ;Disables timer1 by writing a 0 to bit 0
  MOV r0, #0x0000
  MOVT r0, #0x4003
  LDRB r1, [r0, #0x00C]
  BFC r1, #0, #1
  STRB r1, [r0, #0x00C]

  ;Set Timer to 32-bit mode
  LDRB r1, [r0]
  BFC r1, #0, #3
  ;ORR r1, r1, #1
  STRB r1, [r0]

  ;Set Timer to be in periodic mode
  LDRB r1, [r0, #0x004]
  BFC r1, #0, #2
  ORR r1, r1, #0x2
  STRB r1, [r0, #0x004]

  ;set initial interrupt period to 1 second
  ;MOV r1, #0x2400
  ;MOVT r1, #0x00F4
  MOV r1, #0xD400
  MOVT r1, #0x0030
  STR r1, [r0, #0x028]


  ;Enable Timer to interrupt processor
  LDRB r1, [r0, #0x018]
  ORR r1, r1, #1
  STRB r1, [r0, #0x018]


  ;Configure processor to allow Timer to interrupt
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

  ;Enables timer by writing a 1 to bit 0
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
	POP {lr}
	mov pc, lr

;------------------------------------------------------------------------

not_a_fork_bomb:;runs a ton of instructions to give time for the pull up register to actually set. Is actually not a fork bomb just a loop
	PUSH {lr}
	PUSH{r0}
	PUSH{r1}

	MOV r0, #0x7FFF
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

	POP {lr}
	mov pc, lr

;-----------------------------------------------------------------------------------------

string2int:
	PUSH {lr}   ; Store register lr on stack

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
