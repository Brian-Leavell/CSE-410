	.data

color:			.byte	1
prompt:			.string "Select your starting color :)", 0
prompt1:			.string "Red (1)", 0
prompt2:			.string "Blue (2)", 0
prompt3:			.string "Purple (3)", 0
prompt4:			.string "Green (4)", 0
prompt5:			.string "Yellow (5)", 0
prompt6:			.string "White (6)", 0
num_string			.string "             ", 0

	.text
	.global pulsationfr
	.global Timer_Handler


GPIODATA:		.equ	0x3FC		; Offset for GPIO Data Register
ptr_to_color:	.word color
ptr_to_prompt:	.word prompt
ptr_to_prompt1:	.word prompt1
ptr_to_prompt2:	.word prompt2
ptr_to_prompt3:	.word prompt3
ptr_to_prompt4:	.word prompt4
ptr_to_prompt5:	.word prompt5
ptr_to_prompt6:	.word prompt6
ptr_to_num_string:		.word num_string


;MAIN SUBROUTINE
;PIN 1 = RED
;PIN 2 = BLUE
;PIN 3 = GREEN
pulsationfr:
	PUSH {lr}

	BL uart_init
	BL gpio_btn_and_LEDS_init
	BL pwm_init

	ldr r4, ptr_to_prompt
	MOV r0, r4
	BL output_string
	ldr r5, ptr_to_prompt1
	MOV r0, r5
	BL output_string
	ldr r6, ptr_to_prompt2
	MOV r0, r6
	BL output_string
	ldr r7, ptr_to_prompt3
	MOV r0, r7
	BL output_string
	ldr r8, ptr_to_prompt4
	MOV r0, r8
	BL output_string
	ldr r9, ptr_to_prompt5
	MOV r0, r9
	BL output_string
	ldr r10, ptr_to_prompt6
	MOV r0, r10
	BL output_string


	ldr r9, ptr_to_num_string
	MOV r0, r9	;Stores whatever user enters into memory
	BL read_string
	MOV r0, r9	;read_string destroys r0 so we have to put the address of the stored string back for string2int
	BL string2int

	CMP r0, #1
	BEQ red_start
	CMP r0, #2
	BEQ blue_start
	CMP r0, #3
	BEQ purple_start
	CMP r0, #4
	BEQ green_start
	CMP r0, #5
	BEQ yellow_start
	CMP r0, #6
	BEQ white_start

red_start:
	ldr r0, ptr_to_color
	MOV r1, #1
	STRB r1, [r0]
	BL Timer_Init
	B loop

blue_start:
	ldr r0, ptr_to_color
	MOV r1, #2
	STRB r1, [r0]
	BL Timer_Init
	B loop
green_start:
	ldr r0, ptr_to_color
	MOV r1, #4
	STRB r1, [r0]
	BL Timer_Init
	B loop
yellow_start:
	ldr r0, ptr_to_color
	MOV r1, #5
	STRB r1, [r0]
	BL Timer_Init
	B loop
purple_start:
	ldr r0, ptr_to_color
	MOV r1, #3
	STRB r1, [r0]
	BL Timer_Init
	B loop
white_start:
	ldr r0, ptr_to_color
	MOV r1, #6
	STRB r1, [r0]
	BL Timer_Init
	B loop


loop:
	B loop


	POP {lr}
	MOV pc, lr



pwm_init:
	PUSH {lr}







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


gpio_btn_and_LEDS_init:

	PUSH {lr}

	;RGB
	;Enable clock for port F*
	MOV r0, #0xE608
	MOVT r0, #0x400F

	LDR r1, [r0]
	ORR r1, r1, #32
	STR r1, [r0]

	;Set pins F1-F3 to be Outputs*
	MOV r0, #0x5400
	MOVT r0, #0x4002

	LDRB r1, [r0]
	ORR r1, r1, #14
	STRB r1, [r0]

	;Set pins F1-F3 to be Digital
	MOV r0, #0x551C
	MOVT r0, #0x4002

	LDRB r1, [r0]
	ORR r1, r1, #0xE
	STRB r1, [r0]

	BL not_a_fork_bomb

	POP {lr}
	MOV pc, lr


Timer_Init:

  PUSH {lr}

  ;Connects clock to Timer1 by writing a 1 to bit 0
  MOV r0, #0xE604
  MOVT r0, #0x400F
  LDRB r1, [r0]
  ORR r1, r1, #1
  STRB r1, [r0]

  ;Connects clock to Timer2 by writing a 1 to bit 1
  MOV r0, #0xE604
  MOVT r0, #0x400F
  LDRB r1, [r0]
  ORR r1, r1, #2
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

  ;Disables timer2 by writing a 0 to bit 1
  MOV r0, #0x1000
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

  ;for timer1 address
  MOV r0, #0x0000
  MOVT r0, #0x4003

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

  ;Interrupt Servicing, clears interrupt
  ;LDRB r1, [r0, #0x024]
  ;ORR r1, r1, #1
  ;STRB r1, [r0, #0x024]

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

  ;Enables timer by writing a 1 to bit 0
  MOV r0, #0x1000
  MOVT r0, #0x4003
  LDRB r1, [r0, #0x00C]
  ORR r1, r1, #1
  STRB r1, [r0, #0x00C]

  ;set initial interrupt period to 1 second
  MOV r1, #0x2400
  MOVT r1, #0x00F4
  ;MOV r1, #0xD400
  ;MOVT r1, #0x0030
  STR r1, [r0, #0x028]

  POP {lr}

  MOV pc, lr



Timer_Handler:

	PUSH {r4,r5,r6,r7,r8,r9,r10,r11,lr}

	;clear timer interrupt flag
	MOV r0, #0x0000
	MOVT r0, #0x4003
	LDRB r1, [r0, #0x024]
	ORR r1, r1, #1
	STRB r1, [r0, #0x024]

	MOV r1, #0x5000
	MOVT r1, #0x4002

;PIN 1 = RED
;PIN 2 = BLUE
;PIN 3 = GREEN

	;Color Checker
	LDR r0, ptr_to_color
	LDRB r0, [r0]
	CMP r0, #1
	BEQ red
	CMP r0, #2
	BEQ blue
	CMP r0, #3
	BEQ purple
	CMP r0, #4
	BEQ green
	CMP r0, #5
	BEQ yellow
	CMP r0, #6
	BEQ white
	CMP r0, #7
	BEQ off



red:
	LDRB r2, [r1, #0x3FC]
	BFI r2, r0, #1, #3
	STRB r2, [r1, #0x3FC]
	LDR r0, ptr_to_color
	MOV r1, #2
	STRB r1, [r0]
	B done

blue:
	LDRB r2, [r1, #0x3FC]
	BFI r2, r0, #1, #3
	STRB r2, [r1, #0x3FC]
	LDR r0, ptr_to_color
	MOV r1, #3
	STRB r1, [r0]
	B done

green:
	LDRB r2, [r1, #0x3FC]
	BFI r2, r0, #1, #3
	STRB r2, [r1, #0x3FC]
	LDR r0, ptr_to_color
	MOV r1, #5
	STRB r1, [r0]
	B done

yellow:
	LDRB r2, [r1, #0x3FC]
	BFI r2, r0, #1, #3
	STRB r2, [r1, #0x3FC]
	LDR r0, ptr_to_color
	MOV r1, #6
	STRB r1, [r0]
	B done

purple:
	LDRB r2, [r1, #0x3FC]
	BFI r2, r0, #1, #3
	STRB r2, [r1, #0x3FC]
	LDR r0, ptr_to_color
	MOV r1, #4
	STRB r1, [r0]
	B done

white:
	MOV r0, #7
	LDRB r2, [r1, #0x3FC]
	BFI r2, r0, #1, #3
	STRB r2, [r1, #0x3FC]
	LDR r0, ptr_to_color
	MOV r1, #7
	STRB r1, [r0]
	B done

off:
	MOV r0, #0
	LDRB r2, [r1, #0x3FC]
	BFI r2, r0, #1, #3
	STRB r2, [r1, #0x3FC]
	LDR r0, ptr_to_color
	MOV r1, #1
	STRB r1, [r0]
	B done


done:
	POP {r4,r5,r6,r7,r8,r9,r10,r11,lr}


	BX lr       	; Return

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

	; Your code for your read_character routine is placed here
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
