variable output
s" out.bin" w/o create-file throw output !

include as.fth

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
	lr r11 mov,
	r0 r1 mov,

 	uart-fr r0 imm,
	0 r0 r2 ldri,
	32 r2 r2 andi, s,
	here 2 ins - b, ne,

	uart-dr r0 imm,
	r0 r1 st,
	r11 pc mov,

create uart-puthex
	lr r10 mov,
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

	r10 pc mov,

create uart-puts
	lr r10 mov,
	r0 r3 mov,

	1 byte up r3 r0 ldri,
	loop:
		uart-putc bl,
		1 byte up r3 r0 ldri,
		0 r0 cmpi,
	while; ne,

	10 r0 movi,
	uart-putc bl,
	r10 pc mov,

( memory allocator )
( The allocator uses the tlsf algorithm for managaing allocations )
( 
	Checks for the end of ram are avoided by placing fake allocated blocks at the
	start and end of ram:
	A S A ; A - alloced S - start block / rest of ram
	The 'free' blocks are not placed in the free block table - to avoid ever
	allocating them.

	Structure layout :
	both
	size cell includes bit flag allocated
	previous-block cell
	free only
	next-free-block cell
	prev-free-block cell
)

create tlsf-table
( sizes from 16 bytes to 1 gb )
( 8 divisions per size)
28 8 * 4 * zalloc
create fl-bitmap
4 zalloc
create sl-bitmap
28 8 * zalloc

create tlsf-free
	( r0 - address to free )

	( r1 current size of block to free )
	( r2 other block )
	( r3 size of other block )
	0xf0 push,

	( try to merge next )
	r0 r1 ld,
	r0 r1 r2 add,

	r2 r3 ld,
	1 r3 tsti,
	if: ne,
		( remove next from free list as size has changed )
		( r4 next block from r3 )
		( r5 previous block from r3 )
		8 pre up r2 r4 ldri,
		12 pre up r2 r5 ldri,

		0 r4 cmpi,
		12 pre up r4 r5 stri, ne,

		0 r5 cmpi,
		8 pre up r5 r4 stri, ne,

		( link next block )
		r3 r2 r2 add,
		4 pre up r2 r0 stri,
		
		( add sizes )
		r3 r1 r1 add,
		1 r1 r1 andi,
	then;

	( try to merge previous )
	4 pre up r0 r2 ldri,

	r2 r3 ld,
	1 r3 tsti,
	if: ne,
		( remove previous from free list as size has changed )
		8 pre up r2 r4 ldri,
		12 pre up r2 r5 ldri,

		0 r4 cmpi,
		12 pre up r4 r5 stri, ne,

		0 r5 cmpi,
		8 pre up r5 r4 stri, ne,

		( link next block )
		r1 r0 r0 add,
		4 pre up r0 r2 stri,

		( add sizes )
		r3 r1 r1 add,
		1 r1 r1 andi,

		r2 r0 mov,
	then;

	( return to free list )
	( r2 fl index )
	( r3 sl index )
	( r4 combined index )
	r1 r2 clz,
	36 r2 r2 rsubi, s,
	halt b, mi,

	8 r2 r3 subi,
	r1 r3 lsr r3 mov,
	7 r3 r3 andi,

	r2 3 ilsl r3 r4 add,
	tlsf-table adr r5 imm,
	r4 pre up r5 r6 ldr,

	( link the new block )
	8 pre up r0 r6 stri,
	12 pre up r6 r0 stri,

	r4 pre up r5 r0 str,

	( set the bitmap flags )
	( r4 bit ) ( r5 address)
	1 r4 movi,
	r4 r2 lsl r4 mov,
	fl-bitmap adr r5 imm,
	r5 r6 ld,
	r4 r6 r4 orr,
	r5 r3 st,

	1 r4 movi,
	r4 r3 lsl r4 mov,
	sl-bitmap adr r5 imm,
	r2 up pre byte r5 r6 ldr,
	r3 r6 r3 orr,
	r2 up pre byte r5 r3 str,

	0xf0 pop,
	lr pc mov,

create tlsf-alloc
	( r0 size )
	0xff0 push,

	16 r0 r0 addi,

	( r1 fl index )
	( r2 sl index )
	r0 r1 clz,
	36 r1 r1 rsubi, s,
	halt b, mi,

	8 r1 r2 subi,
	r0 r2 lsr r2 mov,
	7 r2 r2 andi,

	( r3 bit )
	( r4 fl-bitmap address )
	( r5 fl-bitmap )
	( r9 resize test bit )
	1 r3 movi,
	r3 r1 lsl r3 mov,
	fl-bitmap adr r4 imm,
	r4 r5 ld,
	r3 r5 tst,
	( find smallest availible fl class )
	if: ne,
		1 r9 movi,
		0 r2 movi,

		loop:
			1 r1 r1 addi,
			r3 1 ilsl r3 mov,
			2 6 irot r3 cmpi,
			if: gt,
				( fixme better error case handling)
				halt b,
			then;

			r3 r5 tst,
		while; ne,
	then;

	( r6 bit )
	( r7 sl-bitmap address )
	( r8 sl-bitmap )
	1 r6 movi,
	r6 r2 lsl r6 movi,
	sl-bitmap adr r7 imm,
	r1 up pre byte r7 r8 ldr,
	r6 r8 tst,

	( find smallest second level class )
	1 r9 movi, ne,
	if: ne,
		loop:
			1 r2 r2 addi,
			r6 1 ilsl r6 mov,
			8 r3 cmpi,
			if: gt,
				( fixme better error case handling)
				halt b,
			then;

			r6 r8 tst,
		while; ne,
	then;

	( r10 tlsf index address )
	( r11 allocation block )
	( r1 combined index )
	tlsf-table adr 10 imm,
	r1 3 ilsl r2 r1 add,
	r1 up pre r10 r11 ldr,

	( unlink the allocation block )
	8 up pre r11 r12 ldri,
	0 r12 cmp,
	if: ne,
		r1 up pre r10 r12 str,
		( bits are not needed for blanking, so can be re-used )
		0 r3 movi,
		12 up pre r12 r3 stri,
	else:
		r6 r8 r8 xor,
		r2 up pre byte r7 r8 str,
		0 r8 cmp,
		r3 r5 r5 xor, ne,
		r4 r5 st, ne,
	then;
	( registers r1 - r8 are now free )

	0 r9 cmpi, ( r9 is now free )
	if: ne,
		( create allocated block and free )
		( r12 new block )
		r0 r11 r12 add,
		( r1 old -> new block size )
		r11 r1 ld,
		( set next physical block to have new block as previous )
		r11 r1 r9 add,
		4 up pre r9 r12 str,


		( shorten old block )
		r11 r0 st,
		( set new block size )
		r0 r1 r1 sub,
		r12 r1 st,
		4 up pre r12 r11 str,
		( r0 - r4 clobbered )

		r12 r0 mov,
		tlsf-free bl,
	then;

	r11 r0 mov,

	0xff0 pop,
	lr pc mov,

create tlsf-init
	( r0 address to start )
	( r1 address to end )
	0x40fc push,

	( set up low end buffer )
	8 r2 movi,
	0 r3 movi,

	0xc up wb r0 stm,

	( set up high end buffer )
	( 8 r2 movi, )
	r0 r3 mov,

	0xc pre wb r1 stm,

	( set up initial block as alloced to allow for adding to table using free )
	r0 r1 r2 sub,
	8 r0 r3 subi,

	0x3c up r0 stm,

	( add to freelist table )
	tlsf-free bl,

	0x40fc pop,
	lr pc mov,

create test-str
	s" Hello World!" string,

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

	halt b,

main reset-b
as-end
output @ close-file

bye
