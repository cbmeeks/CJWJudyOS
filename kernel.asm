
; This kernel was rewritten by Andrew Jacobs (Thanks Andrew!)
; Version 1.0.0: First preemptive multitasking kernel release.
; Use tasks in chunks of 7K starting at $1000 (not all has to be used as ROM; you can leave all of it as RAM if you'd like, too.)
; 8 round-robin tasks supported.
; Task handling library.
; I/O library (super simple, single byte after call).
		.opt 	Proc65c02,CaseSensitive

;===============================================================================
; Constants
;-------------------------------------------------------------------------------
		
STACK		=	$0100

;===============================================================================
; Memory Areas
;-------------------------------------------------------------------------------
		.org	$00
		
TASKNO		.ds	1		; The current task 0-7
TASKLK		.ds	1		; Bit map of stopped tasks
TASKSP		.ds	8		; Inactive task stack pointer values
		
;===============================================================================
; Power On Reset
;-------------------------------------------------------------------------------
		
		.org	$f000
		
		.start	*
		
RESET:		sei			; Reset flags (in case of JMP ($FFFC))
		cld
		
		ldy	#7		; Initialise task stacks
.Init		ldx	INITSP,Y
		stx	TASKSP,Y
		tya			; Convert task number
		asl			; .. to index for PC
		tay
		stz	STACK+1,x	; Clear initial Y
		stz	STACK+2,x	; Clear initial X
		stz	STACK+3,x	; Clear initial A
		stz	STACK+4,x	; Clear initial P
		lda	INITPC+0,y	; Set initial task PC
		sta	STACK+5,x
		lda	INITPC+1,y
		sta	STACK+6,x
		tya			; Recover task number
		lsr
		tay
		dey			; Repeat for all tasks
		bpl	.Init
		txs			; Set the initial stack
		stz	TASKNO		; .. and task number
		stz	TASKLK		; All tasks runnable
		
		ply			; Start the first task
		plx
		pla
		rti

;-------------------------------------------------------------------------------

; Switch to another task
		
TaskYield:	brk			; Cause an interrup to switch task
		nop
		rts			; Continue the original task
		
; Make the task indicated by A runnable

TaskStart:	and	#7		; Ensure task number in range	
		pha
		tax			; Convert to bit mask
		lda	MASKS,x
		trb	TASKLK		; And mark as runnable
		pla
		rts

; Cause this task to be stopped

TaskStopSelf:	lda	TASKNO		; Stop the calling task

; Make the task indicated by A un-runnable

TaskStop:	and	#7		; Ensure task number in range
		pha
		tax			; Convert to bit mask
		lda	MASKS,x
		tsb	TASKLK		; And mark as stopped
		pla
		
		cmp	TASKNO		; Stopped the running task?
		beq	TaskYield	; Yes, switch to another
		rts			; Continue
		
;-------------------------------------------------------------------------------

; Initial stack pointer values for each task

INITSP:		.byte 	$ff-6,$df-6,$bf-6,$9f-6
		.byte	$7f-6,$5f-6,$3f-6,$1f-6  

; Initial task entry points

INITPC:		.word	$1000,$2C00,$4800,$6400
		.word	$8000,$9C00,$B800,$D400

; Bit masks

MASKS:		.byte	1,2,4,8,16,32,64,128

;===============================================================================
; Interrupt Handler
;-------------------------------------------------------------------------------	

IRQ:		pha			; Save tasks A,X & Y
		phx
		phy
		
.Handle		; Handle hardware interrupts here. Exit to .Done if not
		; switching task due to timer or BRK

		ldy	TASKNO		; Save the tasks stack
		tsx
		stx	TASKSP,y
		
.Loop		iny			; Find the next task
		cpy	#8
		bcc	.Skip
		ldy	#0
.Skip
		cpy	TASKNO		; Back at original Task?
		bne	.Test
		
		; If no tasks are runnable then wait until a hardware
		; interrupt occurs and hope that it will make a task
		; runnable.
		
		; wai			; Not supported in the simulator
		bra	.Handle
		

.Test		tya			; No, is the task runnable?
		tax		
		lda	MASKS,y
		and	TASKLK
		bne	.Loop		; No
	
		sty	TASKNO		; Found a new task
		ldx	TASKSP,y	; Load its stack pointer
		txs
		
.Done		ply			; Restore its registers
		plx
		pla	
NMI:		rti			; And continue
	
		
;===============================================================================
; Simulator Output Routines
;-------------------------------------------------------------------------------

IO_AREA		=	$e000
IO_CLS		= 	IO_AREA+0
IO_PUTC		=	IO_AREA+1
IO_PUTR		=	IO_AREA+2
IO_PUTH		=	IO_AREA+3
IO_GETC		=	IO_AREA+4


OutCh:		sta	IO_PUTR
		rts	

;===============================================================================
; Vectors
;-------------------------------------------------------------------------------

		.org	$fffa
	
		.word	NMI
		.word	RESET
		.word	IRQ

		.end
