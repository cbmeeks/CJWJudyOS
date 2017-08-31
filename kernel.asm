;	;Version 0.4.1
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
;	;0.4.0: shortened the jump routine by A LOT!  [STABLE][ALPHA]
;	;0.4.1: shifted the stackp page back one byte to its original position; had it elsewhere during testing.  [STABLE][ALPHA]
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
	STA $3E,X
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
	LDA #$FF	;load an overflowing taskp value to use it to automatically goto task0j
	STA taskp
	LDY #$00	;clear Y
call
	SEI		;set interrupt when we are here again and again.
	INC taskp	;increment the task pointer
	LDY taskp	;load it into the accumulator, which its value is used in a DEA test spanning across all taskXr's.
	CPY #8		;if we overflowed, transfer it back to #0 and retry.
	BEQ redo
	LDA $02,Y	;see if this task sent the stop flag.
	BNE call	;we increment to the next task here if that is a yes.
	LDX $3D,Y
	TXS
	LDA $32,Y	;load the previous return address and push it properly to RTS.
	PHA
	LDA $2A,Y
	PHA
	LDA $22,Y	;this will be pulled back to set the ps after all registers are loaded.
	PHA
	TYA		;start reloading addresses, which a and y will be done indirectly.
	TAX
	LDY $1A,X
	LDX $12,Y
	ADC #$0A	;add to the minimum accumulator address.
	STA tempa	;store the new pointer.
	LDA #$00	;store the rest of the pointers.
	STA tempx
	LDA (tempa)
	RTI		;return to the task as if it were interrupted, pulling the raw address and ps.
redo
	LDA #$FF
	STA taskp
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
