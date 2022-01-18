EN 			EQU 	P3.1
RS 			EQU 	P3.0
X			EQU 	30H
TEMP 		EQU 	31H
T			EQU 	32H
U			EQU 	33H

;Temperature Sensor LM35
;ADC0808 : Resolution 20mV 
;Measures Upto 50 ^C  i.e max voltage 5V 

ORG 0000H
		JMP start

ORG 0003H
		MOV 	X,P1			;Store Digital output in X
	CALL 	OPERATION			;Temp in degree C is X * 2mV * 10  .. 20mv is resolution Of ADC and 10 is multiplication factor
	CALL	GET_DIGITS
	CALL	DISPLAY_RESULT

RETI
	
ORG 0100H
	
	start:
	
//Initialize Ports
		MOV		P2,#00H 	;output LCD Port
		MOV		P1,#0FFH  	;input ADC Port
	
//Initialize LCD 
		MOV A,#38H      
	CALL LCD_CMD
		MOV A,#0CH
	CALL LCD_CMD
		MOV A,#01H     //Display on ,cursor off, blink off
	CALL LCD_CMD

//Enable Interrupt for ADC

		SETB 	IT0		;-ve edge triggered interrupt
		SETB 	EA		;Enable Global Interrupt
		SETB 	EX0		;Enable  INT0_bar

		JMP 	$

ORG 0150H
DELAY_15MS:
		MOV 	R6,#30
delay:	MOV 	R7,#255
		DJNZ 	R7,$
		DJNZ 	R6,delay
		RET
		
ORG 	0200H
MSG_disp: 
		MOV 	A,R2
		MOV 	DPTR ,#0300H
		MOVC 	A,@A+DPTR
	CALL 	LCD_DATA
		INC 	R2
		CJNE 	A,#00H,MSG_disp

		RET

ORG 0300H
MSG: 	DB  "Temperature :",00h
			
ORG 0350H
LCD_CMD:
		MOV 	P2,A
		CLR 	RS
		SETB 	EN
	CALL 	DELAY_15ms
		CLR 	EN
		RET

ORG 0400H
LCD_DATA:
		MOV 	P2,A
		SETB 	RS
		SETB 	EN
	CALL 	DELAY_15ms
		CLR 	EN
		RET	
		
ORG 0500H
OPERATION:
		MOV 	A,X
	CALL	MULTIPLY_20
	
	CALL 	DIVIDE_100
		MOV 	TEMP,R2		;Store Result temp 
		RET
		
ORG 0550H
MULTIPLY_20:
		MOV 	B,#20
		MUL 	AB
		RET
		
ORG 0600H
DIVIDE_100:
//This function takes following parameters
//16-bit Dividend in R1(High) R0(Low)
		MOV 	R0,A
		MOV 	R1,B
//16-bit Divisor  in R3(High) R2(Low)
		MOV		R3,#00
		MOV 	R2,#100
//This Function returns following parameters
//16-bit Remainder in R1(High) R0(Low)
//16-bit Quotient in  R3(High) R2(Low)	
div16_16:
		CLR C       ;Clear carry initially
		MOV R4,#00h ;Clear R4 working variable initially
		MOV R5,#00h ;CLear R5 working variable initially
		MOV B,#00h  ;Clear B since B will count the number of left-shifted bits
div1:
		INC B      ;Increment counter for each left shift
		MOV A,R2   ;Move the current divisor low byte into the accumulator
		RLC A      ;Shift low-byte left, rotate through carry to apply highest bit to high-byte
		MOV R2,A   ;Save the updated divisor low-byte
		MOV A,R3   ;Move the current divisor high byte into the accumulator
		RLC A      ;Shift high-byte left high, rotating in carry from low-byte
		MOV R3,A   ;Save the updated divisor high-byte
		JNC div1   ;Repeat until carry flag is set from high-byte
div2:        ;Shift right the divisor
		MOV A,R3   ;Move high-byte of divisor into accumulator
		RRC A      ;Rotate high-byte of divisor right and into carry
		MOV R3,A   ;Save updated value of high-byte of divisor
		MOV A,R2   ;Move low-byte of divisor into accumulator
		RRC A      ;Rotate low-byte of divisor right, with carry from high-byte
		MOV R2,A   ;Save updated value of low-byte of divisor
		CLR C      ;Clear carry, we don't need it anymore
		MOV 07h,R1 ;Make a safe copy of the dividend high-byte
		MOV 06h,R0 ;Make a safe copy of the dividend low-byte
		MOV A,R0   ;Move low-byte of dividend into accumulator
		SUBB A,R2  ;Dividend - shifted divisor = result bit (no factor, only 0 or 1)
		MOV R0,A   ;Save updated dividend 
		MOV A,R1   ;Move high-byte of dividend into accumulator
		SUBB A,R3  ;Subtract high-byte of divisor (all together 16-bit substraction)
		MOV R1,A   ;Save updated high-byte back in high-byte of divisor
		JNC div3   ;If carry flag is NOT set, result is 1
		MOV R1,07h ;Otherwise result is 0, save copy of divisor to undo subtraction
		MOV R0,06h
div3:
		CPL C      ;Invert carry, so it can be directly copied into result
		MOV A,R4 
		RLC A      ;Shift carry flag into temporary result
		MOV R4,A   
		MOV A,R5
		RLC A
		MOV R5,A		
		DJNZ B,div2 ;Now count backwards and repeat until "B" is zero
		MOV R3,05h  ;Move result to R3/R2
		MOV R2,04h  ;Move result to R3/R2
RET

ORG 0700H
GET_DIGITS:
		MOV 	A,TEMP
		MOV 	B,#10
		
		DIV 	AB
		MOV 	T,A		;Store quotient in tens place
		MOV 	U,B		;Store remainder in units place
RET

ORG 0750H
DISPLAY_RESULT:
		MOV 	R2,#00h
	CALL 	MSG_disp

		MOV 	A,#0C7H
	CALL 	LCD_CMD
		
		MOV 	A,T
		ADD 	A,#30H
	CALL	LCD_DATA

		MOV 	A,U
		ADD 	A,#30H
	CALL	LCD_DATA

		MOV 	A,#'^'
	CALL 	LCD_DATA

		MOV 	A,#'C'
	CALL 	LCD_DATA
		
		MOV 	A,#80H
	CALL 	LCD_CMD

RET
		
END	