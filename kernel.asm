;	;Version 0.2.0
;	;History:
;	;0.0.0: first kernel, uses 8 tasks and tasklock.  [UNSTABLE][ALPHA]
;	;0.1.0: task purge switch added, uses addresses $02-$09 to skip a respective task.  Simplified jump table therefore.  [STABLE][ALPHA]
;	;0.1.1: does vector loading virtually, increasing other source driver support.  [UNSTABLE][ALPHA]
;	;0.1.2: can no longer be locked and stopped at the same time.  This restarts the program without a stop flag, but is still locked.  [UNSTABLE][ALPHA]
;	;0.2.0: stores pushed address on interrupt of unlocked task into $2A to $39.  [UNSTABLE][ALPHA]
;	;0.2.1: fixed addressing issues from Version 0.1.0.  [UNSTABLE][ALPHA]
;	;0.2.2: fixed jmp trying to be a rti on function call since 0.2.0, filling the stack infinitely.  [STABLE][ALPHA]
taskl = $00
taskp = $01
task0 = $7000
task1 = $8000
task2 = $9000
task3 = $A000
task4 = $B000
task5 = $C000
task6 = $D000
task7 = $E000
 .START $F000
 .ORG $F000
setup	
	LDA #$F0
	STA $FFFA
	STA $FFFC
	LDA #<irq
	STA $FFFE
	LDA #>irq
	STA $FFFF
	SEI
	LDA #$60
	LDX #0
setupl0
	ADC #$10
	STA $32,X
	STZ $2A,X
	INX
	CPX #8
	BNE setupl0
	LDA #$00
	STA taskl
	LDX #$02
setupl1
	STA $00,X
	INX
	CPX #$2A
	BNE setupl1
	LDA #$07
	STA taskp
		LDY #$00
call
	SEI
	INC taskp
	LDA taskp
	CMP #$01
	BEQ task1j
	CMP #$02
	BEQ task2j
	CMP #$03
	BEQ task3j
	CMP #$04
	BEQ task4j
	CMP #$05
	BEQ task5j
	CMP #$06
	BEQ task6j
	CMP #$07
	BEQ task7j
	LDA #$00
	STA taskp
	JMP task0j
task0j
	JMP task0r
task1j
	JMP task1r
task2j
	JMP task2r
task3j
	JMP task3r
task4j
	JMP task4r
task5j
	JMP task5r
task6j
	JMP task6r
task7j
	JMP task7r
task0r
	LDA $02
	CMP #$00
	BNE task1r
	LDA $32
	PHA
	LDA $2A
	PHA
	LDA $22
	PHA
	LDA $0A
	LDX $12
	LDY $1A
	PLP
	RTS
task1r
	LDA $03
	CMP #$00
	BNE task2r
	LDA $33
	PHA
	LDA $2B
	PHA
	LDA $23
	PHA
	LDA $0B
	LDX $13
	LDY $1B
	PLP
	RTS
task2r
	LDA $04
	CMP #$00
	BNE task3r
	LDA $34
	PHA
	LDA $2C
	PHA
	LDA $24
	PHA
	LDA $0C
	LDX $14
	LDY $1C
	PLP
	RTS
task3r
	LDA $05
	CMP #$00
	BNE task4r
	LDA $35
	PHA
	LDA $2D
	PHA
	LDA $25
	PHA
	LDA $0D
	LDX $15
	LDY $1D
	PLP
	RTS
task4r
	LDA $06
	CMP #$00
	BNE task5r
	LDA $36
	PHA
	LDA $2E
	PHA
	LDA $26
	PHA
	LDA $0E
	LDX $16
	LDY $1E
	PLP
	RTS
task5r
	LDA $07
	CMP #$00
	BNE task6r
	LDA $37
	PHA
	LDA $2F
	PHA
	LDA $27
	PHA
	LDA $0F
	LDX $17
	LDY $1F
	PLP
	RTS
task6r
	LDA $08
	CMP #$00
	BNE task7r
	LDA $38
	PHA
	LDA $30
	PHA
	LDA $28
	PHA
	LDA $10
	LDX $18
	LDY $20
	PLP
	RTS
task7r
	LDA $09
	CMP #$00
	BNE task8r
	LDA $39
	PHA
	LDA $31
	PHA
	LDA $29
	PHA
	LDA $11
	LDX $19
	LDY $21
	PLP
	RTS
task8r
	JMP task0r
irq
	PHA
	PHX
	PHY
	LDA taskl
	CMP #$00
	BEQ cont
test
	LDX taskp
	LDA $02,X
	CMP #$00
	BEQ good
	STZ $02,X
	TXA
	ADC #$07
	LSR
	LSR
	LSR
	LSR
	PLY
	STY $0A,X
	PLY
	STY $12,X
	PLY
	STY $1A,X
	PLY
	STY $22,X
	PLY
	PLY
	PHA
	LDA #$00
	PHA
	LDA $22,X
	PHA
	LDA #$00
	LDX #$00
	LDY #$00
good
	PLA
	PLX
	PLY
	RTI
cont
	PLA
	STA $0A,X
	PLA
	STA $12,X
	PLA
	STA $1A,X
	PLA
	STA $22,X
	TXA
	TAY
	PLX
	STX $2A,Y
	PLX
	STX $32,Y
	LDX #>call
	LDY #<call
	PHX
	PHY
	LDA #$00
	PHA
	LDA #$00
	LDX #$00
	LDY #$00
	RTI
