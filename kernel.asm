;	;Version 0.1.2
;	;History:
;	;0.0.0: first kernel, uses 8 tasks and tasklock.  [UNSTABLE][ALPHA]
;	;0.1.0: task purge switch added, uses addresses $02-$09 to skip a respective task.  Simplified jump table therefore.  [STABLE][ALPHA]
;	;0.1.1: does vector loading virtually, increasing other source driver support.  [STABLE][ALPHA]
;	;0.1.2: can no longer be locked and stopped at the same time.  This restarts the program without a stop flag, but is still locked.  [STABLE][ALPHA]
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
	LDA #$00
	STA taskl
	LDX #$02
setupl
	STA $00,X
	INX
	CPX #$2A
	BNE setupl
	LDA #$07
	STA taskp
call
	SEI
	INC taskp
	LDA taskp
	CMP #$00
	BEQ task0j
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
	LDA $22
	PHA
	LDA $0A
	LDX $12
	LDY $1A
	PLP
	JMP task0
task1r
	LDA $02
	CMP #$00
	BNE task2r
	LDA $22
	PHA
	LDA $0A
	LDX $12
	LDY $1A
	PLP
	JMP task1
task2r
	LDA $02
	CMP #$00
	BNE task3r
	LDA $22
	PHA
	LDA $0A
	LDX $12
	LDY $1A
	PLP
	JMP task2
task3r
	LDA $02
	CMP #$00
	BNE task4r
	LDA $22
	PHA
	LDA $0A
	LDX $12
	LDY $1A
	PLP
	JMP task3
task4r
	LDA $02
	CMP #$00
	BNE task5r
	LDA $22
	PHA
	LDA $0A
	LDX $12
	LDY $1A
	PLP
	JMP task4
task5r
	LDA $02
	CMP #$00
	BNE task6r
	LDA $22
	PHA
	LDA $0A
	LDX $12
	LDY $1A
	PLP
	JMP task5
task6r
	LDA $02
	CMP #$00
	BNE task7r
	LDA $22
	PHA
	LDA $0A
	LDX $12
	LDY $1A
	PLP
	JMP task6
task7r
	LDA $02
	CMP #$00
	BNE task8r
	LDA $22
	PHA
	LDA $0A
	LDX $12
	LDY $1A
	PLP
	JMP task7
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
	PLX
	PLX
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
