variable output
s" out.bin" w/o create-file throw output !

include as.f

( OS / Device constants )

0x10000 constant kernel-base

hex
3f200000 constant gpio-base
3f200094 constant gppud
3f200098 constant gppudclk
3f201000 constant uart-base
3f201000 constant uart-dr
( 101f1000 constant uart-dr )
3f201004 constant uart-rsrecr
3f201018 constant uart-fr
3f201024 constant uart-ibrd
3f201028 constant uart-fbrd
3f20102c constant uart-lcrh
3f201030 constant uart-cr
3f201038 constant uart-imsc
3f201044 constant uart-icr

decimal

( Assembler state words )
variable _as-start
: as-start here _as-start ! ;
: as-end _as-start @ here over - output @ write-file throw ;

( Device dependent assembler macros )
: adr _as-start @ - kernel-base + ; 

variable inter-vec
: blank-vec dup 0 = if exit then 1 - here b, recurse ;
: reserve-vec here inter-vec ! 8 blank-vec ;
: reset-b inter-vec @ back-b-patch ;

as-start
( instruction vector table )
reserve-vec
( start of code )

create delay
	1 r0 r0 subi, s,
	delay b, ne,
	lr pc mov,

create halt
	loop:
		wfe,
	while; al,

create immidiate
	4 up lr r0 ldri,
	lr pc mov,
	4 up lr r1 ldri,
	lr pc mov,
	4 up lr r2 ldri,
	lr pc mov,
	4 up lr r3 ldri,
	lr pc mov,
	4 up lr r4 ldri,
	lr pc mov,
	4 up lr r5 ldri,
	lr pc mov,
	4 up lr r6 ldri,
	lr pc mov,
	4 up lr r7 ldri,
	lr pc mov,
	4 up lr r8 ldri,
	lr pc mov,
	4 up lr r9 ldri,
	lr pc mov,
	4 up lr r10 ldri,
	lr pc mov,
	4 up lr r11 ldri,
	lr pc mov,
	4 up lr r12 ldri,
	lr pc mov,
	4 up lr sp ldri,
	lr pc mov,
: imm, 3 lshift immidiate + bl, num, ;

create build-interrupt-vec
	lr r11 mov,
	immidiate bl,
	here kernel-base + b,

	36 r1 movi,
	loop:
		4 pre wb r1 r0 stri,
		0 r1 cmpi,
	while; ne,

	r11 pc mov,

create uart-init
	lr r11 mov,
	uart-cr r0 imm,
	0 r1 movi,
	r0 r1 st,

	gppud r0 imm,
	r0 r1 st,

	150 r0 movi,
	delay bl,

	gppudclk r0 imm,
	3 18 irot r1 movi,
	r0 r1 st,

	150 r0 movi,
	delay bl,

	gppudclk r0 imm,
	0 r1 movi,
	r0 r1 st,

	hex 7ff r0 imm,
	decimal
	r0 r1 mov,
	uart-icr r0 imm,
	r0 r1 st,

	uart-ibrd r0 imm,
	1 r1 movi,
	r0 r1 st,

	uart-fbrd r0 imm,
	40 r1 movi,
	r0 r1 st,

	uart-lcrh r0 imm,
	112 r1 movi,
	r0 r1 st,

	uart-imsc r0 imm,
	30 26 irot r1 movi,
	114 r1 r1 orri,
	r0 r1 st,

	uart-cr r0 imm,
	3 24 irot r1 movi,
	1 r1 r1 orri,
	r0 r1 st,

	r11 pc mov,

create uart-putc
	0x4000 push,
	r0 r1 mov,

 	uart-fr r0 imm,
	0 r0 r2 ldri,
	32 r2 r2 andi, s,
	here 2 ins - b, ne,

	uart-dr r0 imm,
	r0 r1 st,
	0x8000 pop,

create uart-getc
	0x4000 push,
	r0 r1 mov,

 	uart-fr r0 imm,
	0 r0 r2 ldri,
	16 r2 r2 andi, s,
	here 2 ins - b, ne,

	uart-dr r0 imm,
	r0 r0 ld,

	uart-putc bl,
	r1 r0 mov,

	0x8000 pop,

create uart-puthex
	0x40f0 push,
	r0 r3 mov,

	28 r4 movi,
	15 r5 movi,
	loop:
		r3 r4 ror r5 r6 and,
		10 r6 r7 subi, s,
		char 0 r6 r0 addi, mi,
		char a r7 r0 addi, pl,

		uart-putc bl,
		4 r4 r4 subi, s,
	while; pl,

	0x80f0 pop,

create uart-puts
	0x4010 push,
	r0 r4 mov,

	1 byte up r4 r0 ldri,
	loop:
		uart-putc bl,
		1 byte up r4 r0 ldri,
		0 r0 cmpi,
	while; ne,

	10 r0 movi,
	uart-putc bl,
	0x8010 pop,

create test-str
	s" Hello World!" string,

( Forth interpreter construction macros )
( link format inline-str next str code )
variable last-link
: fword here adr -rot string, align
	last-link @ here !
	here adr last-link !
	4 allot here ! 4 allot ;

variable alloc-pointer

create alloc ( r0 - amount )
	alloc-pointer adr r1 imm,
	r1 r2 ld,
	r2 r0 r0 add,
	r1 r0 st,
	r2 r0 mov,

	lr pc mov,

( Forth interpreter )
( r4 - top of stack )
( sp - return stack ) ( decending pre-index )
( r11 - main stack  )
( r10 - address hand )

s" dp" fword
	alloc-pointer adr r4 imm,
	lr pc mov,

s" swap" fword
	4 pre wb r11 r1 ldri,
	4 up r11 r4 stri,
	r1 r4 mov,
	lr pc mov,

s" drop" fword
	4 pre wb r11 r4 ldri,
	lr pc mov,

s" dup" fword
	4 up r11 r4 stri,
	lr pc mov,

s" over" fword
	4 pre wb r11 r12 ldri,
	4 up r11 r4 stri,
	r12 r4 mov,
	lr pc mov,

s" !" fword
	4 pre wb r11 r1 ldri,
	r4 r1 st,
	4 pre wb r11 r4 ldri,
	lr pc mov,

s" @" fword
	r4 r4 ld,
	lr pc mov,

s" >r" fword
	4 up sp r4 stri,
	4 pre wb r11 r4 ldri,
	lr pc mov,

s" r>" fword
	4 up r11 r4 stri,
	4 pre wb sp r4 ldri,
	lr pc mov,

s" >a" fword
	r4 r10 mov,
	4 pre wb r11 r4 ldri,
	lr pc mov,

s" a>" fword
	r10 r4 mov,
	lr pc mov,

s" rot" fword
	r4 r2 mov,
	0x3 pre wb r11 ldm,
	0x6 up r11 stm,
	lr pc mov,

s" +" fword
	4 pre wb r11 r1 ldri,
	r4 r1 r4 add,
	lr pc mov,

s" -" fword
	4 pre wb r11 r1 ldri,
	r4 r1 r4 sub,
	lr pc mov,

s" =" fword
	4 pre wb r11 r1 ldri,
	r1 r4 cmp,
	0 r4 mvni,
	0 r4 movi, ne,
	lr pc mov,

s" >" fword
	4 pre wb r11 r1 ldri,
	r1 r4 cmp,
	0 r4 mvni,
	0 r4 movi, le,
	lr pc mov,

s" >=" fword
	4 pre wb r11 r1 ldri,
	r1 r4 cmp,
	0 r4 mvni,
	0 r4 movi, lt,
	lr pc mov,

s" <" fword
	4 pre wb r11 r1 ldri,
	r1 r4 cmp,
	0 r4 mvni,
	0 r4 movi, ge,
	lr pc mov,

s" <=" fword
	4 pre wb r11 r1 ldri,
	r1 r4 cmp,
	0 r4 mvni,
	0 r4 movi, gt,
	lr pc mov,

s" lshift" fword
	4 pre wb r11 r1 ldri,
	r1 r4 lsl r4 mov,
	lr pc mov,

s" rshift" fword
	4 pre wb r11 r1 ldri,
	r1 r4 lsr r4 mov,
	lr pc mov,

s" xor" fword
	4 pre wb r11 r1 ldri,
	r1 r4 r4 xor,
	lr pc mov,

s" invert" fword
	r4 r4 mvn,
	lr pc mov,

s" and" fword
	4 pre wb r11 r1 ldri,
	r1 r4 r4 and,
	lr pc mov,

s" or" fword
	4 pre wb r11 r1 ldri,
	r1 r4 r4 orr,
	lr pc mov,

s" negate" fword
	0 r4 r4 rsubi,
	lr pc mov,

s" print-hex" fword
	0x4000 push,
	r4 r0 mov,
	uart-puthex bl,
	0x8000 pop,

create forth-imm
	4 up r11 r4 stri,
	4 up lr r4 ldri,
	lr pc mov,

create str-eq
	( r0 - a )
	( r1 - b )
	( r2, r3 - temp )
	( returns status in status register )

	loop:
		1 up byte r0 r2 ldri,
		1 up byte r1 r3 ldri,
		r2 r3 cmp,
		if: ne,
			lr pc mov,
		then;
		0 r2 cmpi,
	while; ne,
	lr pc mov,

create add-word
	( r0 - string address )
	( r1 - link address )
	( returns the start of code in r0 )
	lr r12 mov,

	( Init link items )
	4 up pre r1 r0 stri,
	
	( Link new word )
	last-link adr r3 imm,
	r3 r2 ld,

	r3 r1 st,
	r1 r2 st,

	8 r1 r0 addi,
	r12 pc mov,

create find-word
	( r0 - word )
	( r5 - word backup )
	0x4030 push,
	r0 r5 mov,

	last-link adr r4 imm,
	r4 r4 ld,
	loop:
		4 pre up r4 r1 ldri,
		str-eq bl,
		if: eq,
			8 r4 r0 addi,
			0x8030 pop,
		then;
		r4 r4 ld,

		r5 r0 mov,
		0 r4 cmpi,
	while; ne,

	0 r0 movi,

	0x8030 pop,

create is-space
	0 r0 cmpi,
	halt bl, eq,

	( space )
	32 r0 cmpi,
	lr pc mov, eq,

	( newline - lf )
	10 r0 cmpi,
	lr pc mov, eq,

	( newline - cr)
	13 r0 cmpi,
	lr pc mov, eq,

	( tab )
	11 r0 cmpi,

	lr pc mov,

create next-word
	( returns start and word-aligned end in r0 and r1 )
	0x4030 push,

	alloc-pointer adr r4 imm,
	r4 r4 ld,
	r4 r5 mov,
	loop:
		uart-getc bl,
		is-space bl,
	while; eq,

	loop:
		1 up byte r4 r0 stri,
		uart-getc bl,
		is-space bl,
	while; ne,

	0 r0 movi,
	1 up byte r4 r0 stri,

	( Align to word )
	4 r4 r4 addi,
	3 r4 r4 bici,

	r5 r0 mov,
	r4 r1 mov,

	0x8030 pop,

create make-number
	( r0 - string pointer )

	0 r3 movi,
	1 up byte r0 r1 ldri,
	loop:
		48 r1 r1 subi, s,
		if: mi,
			( Fixme better error handling )
			r3 r0 mov,
			lr pc mov,
		then;
		10 r1 cmpi,
		if: ge,
			( Fixme better error handling )
			r3 r0 mov,
			lr pc mov,
		then;
		( * 5, * 2 = * 10 )
		r3 2 ilsl r3 r3 add,
		r3 1 ilsl r1 r3 add,

		1 up byte r0 r1 ldri,
		0 r1 cmpi,
	while; ne,

	r3 r0 mov,
	lr pc mov,

create semi-colon s" ;" string,

s" :" fword
	0x4070 push,
	next-word bl,

	add-word bl,
	r0 r4 mov,

	( Start function by pushing lr )
	0xe92d4000 r1 imm,
	4 up r4 r1 stri,

	( Upadate alloc pointer to avoid overwriting )
	alloc-pointer adr r5 imm,
	r5 r4 st,

	next-word bl,
	r0 r6 mov,

	loop:
		find-word bl,

		0 r0 cmpi,
		if: eq,
			r6 r0 mov,
			make-number bl,

			forth-imm adr r2 imm,

			( Construct a branch-link to the address )
			8 r4 r1 addi,
			r1 r2 r1 sub,
			r1 2 ilsr r1 mov,
			0xFF 8 irot r1 r1 bici,
			0xeb 8 irot r1 r1 orri,
			4 up r4 r1 stri,
			4 up r4 r0 stri,
		else:
			( Construct a branch-link to the address )
			8 r4 r1 addi,
			r1 r0 r1 sub,
			r1 2 ilsr r1 mov,
			0xFF 8 irot r1 r1 bici,
			0xeb 8 irot r1 r1 orri,
			4 up r4 r1 stri,
		then;

		( Upadate alloc pointer to avoid overwriting )
		r5 r4 st,

		next-word bl,
		semi-colon adr r1 imm,
		r0 r6 mov,
		str-eq bl,

		r6 r0 mov,
	while; ne,

	( Complete with popping to pc )
	0xe8bd8000 r1 imm,
	4 up r4 r1 stri,

	( Upadate alloc pointer to avoid overwriting )
	r5 r4 st,

	0x8070 pop,

create interpret
	( avoid using forth variables )
	next-word bl,
	r0 r5 mov,

	loop:
		find-word bl,
		0 r0 cmpi,
		if: ne,

			pc lr mov,
			r0 pc mov,
		else:
			4 up r11 r4 stri,
			r5 r0 mov,
			make-number bl,

			r0 r4 mov,
		then;

		next-word bl,
	while; al,

	halt b,

create main
	5 r0 r0 r1 0 15 mrc,
	3 r1 r1 andi,
	0 r1 cmpi,
	halt b, ne,

	build-interrupt-vec bl,

	kernel-base sp imm,

	uart-init bl,

	test-str adr r0 imm,
	uart-puts bl,

	0x4f3 r0 imm,
	uart-puthex bl,

	interpret bl,

	halt b,

4 alloc
here adr alloc-pointer !

main reset-b
as-end
output @ close-file

bye
