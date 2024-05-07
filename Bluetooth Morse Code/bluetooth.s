	.data

prompt1:	.string "Pairing Mode Avticated", 0
on_off:		.byte 0



	.text
	.global bluetooth
	.global UART0_Handler
	.global Timer0_Handler

ptr_to_prompt:	.word prompt1
ptr_to_on_off:	.word on_off



bluetooth:
	PUSH {lr}

	BL uart_init
	BL uart_interrupt_init
	BL SW1_RGB_Init
	BL Timer0_Init

	ldr r0, ptr_to_prompt
	LDRB r0, [r0]
	BL output_string

start:
	B start


	POP {lr}
	MOV pc, lr

;-------------------------HANDLERS--------------------------------------------------
Timer0_Handler:

	PUSH {r4,r5,r6,r7,r8,r9,r10,r11,lr}

	;clear timer interrupt flag
	MOV r0, #0x0000
	MOVT r0, #0x4003
	LDRB r1, [r0, #0x024]
	ORR r1, r1, #1
	STRB r1, [r0, #0x024]

	;RGB LED Address
	MOV r1, #0x5000
	MOVT r1, #0x4002

check:
	LDR r4, ptr_to_on_off
	LDRB r5, [r4]
	CMP r5, #0
	BEQ off
	B on


off:
	;Data register for RGB LED
	MOV r2, #0
	STRB r2, [r1, #0x3FC]
	B exit_handle

on:
	;Data register for RGB LED
	LDRB r2, [r1, #0x3FC]
	ORR r2, r2, #2
	STRB r2, [r1, #0x3FC]
	B exit_handle

exit_handle:

	POP {r4,r5,r6,r7,r8,r9,r10,r11,lr}
	BX lr


;-------------------------INITIALIZATIONS----------------------------------------------
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
SW1_RGB_Init:
    PUSH {lr}

    ;Code below turns on clock for port F
	MOV r0, #0xE608
	MOVT r0, #0x400F

	LDRB r1, [r0]
	ORR r1, r1, #32
	STRB r1, [r0]

	;Set pin F4 to be an Input and F1-F3 as Ouputs
	MOV r0, #0x5000			;Load port F address
    MOVT r0, #0x4002

	LDRB r1, [r0, #0x400]
	AND r1, r1, #0xEF  ;for intput
    ORR r1, r1, #14    ;for output
	STRB r1, [r0, #0x400]

	;Set pin F1-F4 to be Digital
	LDRB r1, [r0, #0x51C]
	ORR r1, r1, #0x1E
	STRB r1, [r0, #0x51C]

	;Turn on pullup resistor for pin F4
	LDRB r1, [r0, #0x510]
	ORR r1, r1, #16
	STRB r1, [r0, #0x510]

	;Make interrupt for SW1 edge sensitive
	LDRB r1, [r0,#0x404]
	AND r1, r1, #0xEF
	STRB r1, [r0, #0x404]

	;Make interrupt for SW1 double edge triggering
	LDRB r1, [r0,#0x408]
	AND r1, r1, #0xFF
	STRB r1, [r0, #0x408]

;Not needed for double edge triggering
	;Make interrupt for SW1 falling edge trigger
	;LDRB r1, [r0,#0x40C]
	;AND r1, r1, #0xEF
	;STRB r1, [r0, #0x40C]

	;Enable intterupt for SW1 Tiva
	LDRB r1, [r0,#0x410]
	ORR r1, r1, #0x10
	STRB r1, [r0, #0x410]

	;Clear intterupt flag for SW1 Tiva to allow a different interrupt to activate if needed
	LDRB r1, [r0,#0x41C]
	ORR r1, r1, #0x10
	STRB r1, [r0, #0x41C]

	;Allow GPIO Port F to use interrupts
	MOV r0, #0xE100
	MOVT r0, #0xE000

	LDRB r1, [r0, #3]
	ORR r1, r1, #0x40
	STRB r1, [r0, #3]

    POP {lr}
	MOV pc, lr

uart1_init:
	PUSH {lr}

	;Enables clock for UART1
	MOV r0, #0xE618
	MOVT r0, #0x400F

	LDR r1, [r0]
	ORR r1, r1, #2
	STR r1, [r0]

	;Enables clock for PORTB
	MOV r0, #0xE608
	MOVT r0, #0x400F
	LDR r1, [r0]
	ORR r1, r1, #2
	STR r1, [r0]
	;Disables UART1 control
	MOV r0, #0xD030
	MOVT r0, #0x4000
	MOV r1, #0
	STR r1, [r0]
	;Sets the Baud Rate for UART1_IBRD_R to 115,200
	MOV r0, #0xD024
	MOVT r0, #0x4000
	MOV r1, #8
	STR r1, [r0]
	;Sets the Baud Rate for UART1_FBRD_R to 115,200
	MOV r0, #0xD028
	MOVT r0, #0x4000
	MOV r1, #44
	STR r1, [r0]
	;Ensures we are using the system clock
	MOV r0, #0xDFC8
	MOVT r0, #0x4000
	MOV r1, #0
	STR r1, [r0]
	;Sets the word length to 8 bits with 1 stop bit and no parity bits
	MOV r0, #0xD02C
	MOVT r0, #0x4000
	MOV r1, #0x60
	STR r1, [r0]
	;Enables UART1 Control
	MOV r0, #0xD030
	MOVT r0, #0x4000
	MOV r1, #0x301
	STR r1, [r0]

	;Sets PA0 to Digital Port
	MOV r0, #0xD51C
	MOVT r0, #0x4000
	LDR r1, [r0]
	ORR r1, r1, #0x03
	STR r1, [r0]
	;Sets PA1 to Digital Port
	MOV r0, #0xD420
	MOVT r0, #0x4000
	LDR r1, [r0]
	ORR r1, r1, #0x03
	STR r1, [r0]
	;Configures PA0 and PA1 for UART0
	MOV r0, #0xD52C
	MOVT r0, #0x4000
	LDR r1, [r0]
	ORR r1, r1, #0x11
	STR r1, [r0]


	POP {lr}
	MOV pc, lr

uart0_init:
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

	;Sets PB0 to Digital Port
	MOV r0, #0x551C
	MOVT r0, #0x4000
	LDR r1, [r0]
	ORR r1, r1, #0x03
	STR r1, [r0]
	;Sets PB1 to Digital Port
	MOV r0, #0x5420
	MOVT r0, #0x4000
	LDR r1, [r0]
	ORR r1, r1, #0x03
	STR r1, [r0]
	;Configures PB0 and PB1 for UART1
	MOV r0, #0x452C
	MOVT r0, #0x4000
	LDR r1, [r0]
	ORR r1, r1, #0x11
	STR r1, [r0]


	POP {lr}
	MOV pc, lr

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
