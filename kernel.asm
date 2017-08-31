;	;Version 0.3.5
;	;History:
;	;0.0.0: first kernel, uses 8 tasks and tasklock.  [UNSTABLE][ALPHA]
;	;0.1.0: task purge switch added, uses addresses $02-$09 to skip a respective task.  Simplified jump table therefore.  [STABLE][ALPHA]
;	;0.1.1: does vector loading virtually, increasing other source driver support.  [UNSTABLE][ALPHA]
;	;0.1.2: can no longer be locked and stopped at the same time.  This restarts the program without a stop flag, but is still locked.  [UNSTABLE][ALPHA]
;	;0.2.0: stores pushed address on interrupt of unlocked task into $2A to $39.  [UNSTABLE][ALPHA]
;	;0.2.1: fixed addressing issues from Version 0.1.0.  [UNSTABLE][ALPHA]
;	;0.2.2: fixed jmp trying to be a rti on function call since 0.2.0, filling the stack infinitely.  [BROKEN][ALPHA]
;	;0.2.3: fixed unstable SEI at setup, some bad code, and optimized the code A LOT.  [BROKEN][ALPHA]
;	;0.3.0: added a split stack.  Split stacks will save the processing time to switch tasks that have stacks.  [BROKEN][ALPHA]
;	;0.3.1: fixed the crash on 0.2.3 and up.  [BROKEN][ALPHA]
;	;0.3.2: fixed the crash on 0.2.2 and up.  [BROKEN][ALPHA]
;	;0.3.3: removed moving the stack pointer to $FF on interrupt.  [BROKEN][ALPHA]
;	;0.3.4: fixed RTI memory leak for Stack Pointer.  [STABLE][ALPHA]
;	;0.3.5: doubled the stack size of the 8 tasks.  (8x32 Bytes)  [STABLE][ALPHA]
taskl = $00
taskp = $01
;	;taskdone = $02 to $09
;	;taskrega = $0A to $11
;	;taskregx = $12 to $19
;	;taskregy = $1A to $21
;	;taskregps = $22 to $29
;	;taskloadr = $2A to $31
;	;taskhiadr = $32 to $39
;	;stackp = $3D to $44
tempa = $3A
tempx = $3B
tempy = $3C
;	;stack is divided into 8 parts of 32 bytes.  Each task must NOT go over this limit.
task0 = $7000
task1 = $8000
task2 = $9000
task3 = $A000
task4 = $B000
task5 = $C000
task6 = $D000
task7 = $E000
 .START $F000		;set the beginning address of the PC to here, because kernels should start first.
 .ORG $F000
setup	
	SEI
	LDA #$F0	;load a reset vector for NMI and RST.
	STA $FFFA
	STA $FFFC
	LDA #<irq	;load an IRQ vector for IRQ.
	STA $FFFE
	LDA #>irq
	STA $FFFF
	LDA #$60	;get ready to point to the high byte of the task addresses
	LDX #0
setupl0
	ADC #$10	;add $10 to increment by an entire page.  use the Accumulator for the high byte of the address
	STA $31,X	;in this loop, we are storing default addresses to the stored IRQ pointer table.
	STZ $29,X	;this just makes sure to zero out the low bytes in the addresses.
	INX		;increment X.
	CPX #$08	;test for 0 in X.
	BNE setupl0	
	LDX #0		;now let's do the same with the default stack pointer memories, incrementing by $20 instead of $10.
	LDA #$1F	
setupl2
	STA $3D,X
	ADC #$20
	INX
	CPX #$08
	BNE setupl2
	LDA #$00	;this just makes sure we no longer locked on reboot, and the value is used after STA taskl.
	STA taskl
	LDX #$27	;get ready to use X as an incrementer AND an index.
setupl1
	STA $01,X	
	DEX
	BNE setupl1
	LDA #$07	;load an overflowing taskp value to use it to automatically goto task0j
	STA taskp
	LDY #$00	;clear Y
call
	SEI		;set interrupt when we are here again and again.
	INC taskp	;increment the task pointer
	LDA taskp	;load it into the accumulator, which its value is used in a DEA test spanning across all taskXr's.
task0r
	BNE task1r	;we won't need a DEA test here, but if it isn't zero, jump to the next test.
	LDA $02		;see if this task sent the stop flag.
	BNE task1r	;we branch to the next task here if that is a yes.
	LDX $3D
	TXS
	LDA $32		;load the previous return address and push it properly to RTS.
	PHA
	LDA $2A
	PHA
	LDA $22		;this will be pulled back to set the ps after all registers are loaded.
	PHA
	LDA $0A		;load the previous registers' values used in the task.
	LDX $12
	LDY $1A
	RTI
task1r
	DEA		;these next 7 blocks of code are the same thing, except the taskXr is incremented, and so are the zero page addresses.
	BNE task2r
	LDA $03
	BNE task2r
	LDX $3E
	TXS
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
	DEA
	BNE task3r
	LDX $3F
	TXS
	LDA $04
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
	DEA
	BNE task4r
	LDA $05
	BNE task4r
	LDX $40
	TXS
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
	DEA
	BNE task5r
	LDA $06
	BNE task5r
	LDX $41
	TXS
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
	DEA
	BNE task6r
	LDA $07
	BNE task6r
	LDX $42
	TXS
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
	DEA
	BNE task7r
	LDA $08
	BNE task7r
	LDX $43
	TXS
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
	DEA
	BNE task8r
	LDA $09
	BNE task8r
	LDX $44
	TXS
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
	LDA #$00	;we failed to find the right task from task1r and up, so let's set the taskp to zero because this always means we overflowed ($08 and up) upo
	STA taskp
	JMP task0r	;retry the process.  note that infinite loops mean a crash.
irq
	PHA		;it is time for irq handling, so let's push the registers.
	PHX
	PHY
	LDA taskl	;if the task lock is inactive, then let's return to the scheduler
	BEQ cont
	LDX taskp	;the task lock is active, and since we dont want the lock AND the stop flag active, test the stop flag for each task.
	LDA $02,X	;is the task not stopped, and if so, return to it
	BEQ good
	STZ $02,X	;both flags are active, so lets unstop the task and reset its return address.
	TXA
	ADC #$08	;this will calculate the high byte of the address we want to reset to.
	LSR
	LSR
	LSR
	LSR
	PLY		;let's pull the registers and store them in a temporary spot to reveal the address pointer.
	STY $0A,X
	PLY
	STY $12,X
	PLY
	STY $1A,X
	PLY
	STY $22,X
	PLY		;throw away the address pointer to be used on RTI.
	PLY
	STX tempx	;lets store the X and Y registers temporarily.
	STY tempy
	TSX		;but before that, load the stack pointer and store it in the proper spot.
	LDY taskp
	STX $3D,Y
	LDX tempx	;reload the registers.  The RTI address is at the current stack pointer.
	LDY tempy
	PHA		;replace it with the high byte calculated and a low byte of $00.
	ADC #$1F	;add an entire page plus $0F to reset the stack.
	STA $3D,X
	LDA #$00
	PHA
	LDA $22,X	;load back the ps.
	PHA
	LDA #$00	;clear all registers, because we reset the task.
	PHA
	PHA
	PHA
good
	PLA
	PLX
	PLY
	STA tempa	;store the registers temporarily again to gandle the stack pointer.
	STX tempx
	STY tempy
	LDA taskp
	LDA tempa	;reload the registers.
	LDX tempx
	LDY tempy
	RTI		;return from interrupt.
cont
	PLA		;let's pull the registers and store them in a temporary spot to reveal the address pointer.
	STA $0A,X
	PLA
	STA $12,X
	PLA
	STA $1A,X
	PLA
	STA $22,X
	TXA		;we loaded the task pointer before this block of code, so transfer it to the Y register.
	TAY
	PLX		;pull the previous address of the task to use for later calling when we return.
	STX $2A,Y
	PLX
	STX $32,Y
	STX tempx	;lets store the X and Y registers temporarily.
	STY tempy
	TSX		;but before that, load the stack pointer and store it in the proper spot.
	LDY taskp
	STX $3D,Y
	LDX tempx	;reload the registers.  The RTI address is at the current stack pointer.
	LDY tempy
	LDX #>call	;push the address of the "call" label so we can return to the task scheduler.
	LDY #<call
	PHX
	PHY
	LDA #$00	;push a blank ps.
	PHA
	LDA #$00	;clear all registers because we will need them in the task scheduler.
	LDX #$00
	LDY #$00
	RTI		;return to the "call" label.
