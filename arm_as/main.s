.section ".text.boot"
.global _start

include "hardware.s"

_start:
	mrc p15, #0, r1, c0, c0, #5
	and r1, r1, #3
	cmp r1, #0
	bne halt

	mov sp, #0x8000

	ldr r0, =GPIO_BASE
	ldr r1, =UART0_BASE
	mov r2, #0
	str r2, [r1, UART0_CR_OFFSET]
	str r2, [r0, GPPUD_OFFSET]
	bl delay
	mov r2, #0xc000
	str r2, [r0, GPPUDCLK0_OFFSET]
	bl delay
	mov r2, #0
	str r2, [r0, GPPUDCLK0_OFFSET]
	ldr r2, =0x7ff
	str r2, [r1, UART0_ICR_OFFSET]
	mov r2, #1
	str r2, [r1, UART0_IBRD_OFFSET]
	mov r2, #40
	str r2, [r1, UART0_FBRD_OFFSET]
	mov r2, #0x70
	str r2, [r1, UART0_LCRH_OFFSET]
	ldr r2, =0x7f2
	str r2, [r1, UART0_IMSC_OFFSET]
	ldr r2, =0x301
	str r2, [r1, UART0_CR_OFFSET]

halt:
	wfe
	b halt

delay:
	mov r12, #150
	subs r12, r12, #1
	bne delay
	mov pc, lr

// R11; top of main stack
// R12; main stack
// R13; SP - return stack
// R14; LR - top of return stack
// R15; PC
compile:
	
