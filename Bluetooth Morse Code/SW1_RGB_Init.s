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
