variable output
s" out.bin" w/o create-file throw output !

hex
F0 invert constant cond-mask
: cond-mask F and ;

decimal
: cond create 4 lshift ,
	does> @ here 1 - c@ cond-mask or here 1 - c! ;

hex
0 cond eq,
1 cond ne,
2 cond cs,
2 cond hs,
3 cond cc,
3 cond lo,
4 cond mi,
5 cond pl,
6 cond vs,
7 cond vc,
8 cond hi,
9 cond ls,
A cond ge,
B cond lt,
C cond gt,
D cond le,
E cond al,
( F is reserved for unconditional instructions )

hex
: 8bmask FF and ;
: get8b 3 lshift rshift 8bmask ;

: num, dup 0 get8b c, dup 1 get8b c, dup 2 get8b c, 3 get8b c, ;
: ins, num, al, ;

hex
0 constant r0
1 constant r1
2 constant r2
3 constant r3
4 constant r4
5 constant r5
6 constant r6
7 constant r7
8 constant r8
9 constant r9
A constant r10
B constant r11
C constant r12
D constant sp
E constant lr
F constant pc

decimal
: irot 2 / 8 lshift or ; ( or into the rm register )

: imm-shift create 5 lshift ,
	does> @ swap 7 lshift or or ; ( or into the rm register )

0 imm-shift ilsl
1 imm-shift ilsr
2 imm-shift iasr
3 imm-shift iror
: irrx 0 iror ;

: reg-shift create 5 lshift 1 4 lshift or ,
	does> @ swap 8 lshift or or ; ( or into the rm register )

0 reg-shift lsl
1 reg-shift lsr
2 reg-shift asr
3 reg-shift ror
: rrx 0 ror ;

: data-ins-rd
	12 lshift or ;

: data-ins-rn
	16 lshift or ;

: data-ins-rm or ;

: build-data-ins-r
	swap data-ins-rd swap data-ins-rn swap data-ins-rm ;

: data-ins-r create 21 lshift ,
	does> @ build-data-ins-r ins, ;

: s, here 2 - dup c@ 16 or swap c! ;

hex
0 data-ins-r and,
1 data-ins-r xor,
2 data-ins-r sub,
3 data-ins-r rsub,
4 data-ins-r add,
5 data-ins-r addc,
6 data-ins-r subc,
7 data-ins-r rsubc,
8 data-ins-r tst,
9 data-ins-r teq,
A data-ins-r cmp,
B data-ins-r cmn,
C data-ins-r orr,
D data-ins-r mov,
E data-ins-r bic,
F data-ins-r mvn,

: mov, 0 swap mov, ;

: data-ins-i12 FFF and or ;

: build-data-ins-i
	swap data-ins-rd swap data-ins-rn swap data-ins-i12 ;

decimal
: data-ins-i create 21 lshift 1 25 lshift or ,
	does> @ build-data-ins-i ins, ;

hex
0 data-ins-i andi,
1 data-ins-i xori,
2 data-ins-i subi,
3 data-ins-i rsubi,
4 data-ins-i addi,
5 data-ins-i addci,
6 data-ins-i subci,
7 data-ins-i rsubci,
8 data-ins-i tsti,
9 data-ins-i teqi,
A data-ins-i cmpi,
B data-ins-i cmni,
C data-ins-i orri,
D data-ins-i movi,
E data-ins-i bici,
F data-ins-i mvni,

( todo mul mla )

: movi, 0 swap movi, ;


decimal

: ins  4 * ;
: b-imm-mask 255 24 lshift invert and ;
: bimm24 2 rshift b-imm-mask or ;
( Relative address is calculated )
: b, 5 25 lshift swap here 8 + - bimm24 ins, ;
: bl, 11 24 lshift swap here 8 + - bimm24 ins, ; 

: ld-st-flag create 1 swap lshift ,
	does> @ or ;

( 25 ld-st-flag imm )
24 ld-st-flag pre
23 ld-st-flag up
22 ld-st-flag byte
21 ld-st-flag wb

: stri, 1 26 lshift swap data-ins-rd swap data-ins-rn swap data-ins-rm ins, ;
: ldri, 65 20 lshift swap data-ins-rd swap data-ins-rn swap data-ins-rm ins, ;
: set, 0 -rot stri, ;

: str, 3 25 lshift swap data-ins-rd swap data-ins-rn swap data-ins-rm ins, ;
: ldr, 97 20 lshift swap data-ins-rd swap data-ins-rn swap data-ins-rm ins, ;

( todo ldrh , strh )

: ldstm-bits ;
: stm, 1 27 lshift swap data-ins-rn swap ldstm-bits ins, ;
: ldm, 129 27 lshift swap data-ins-rn swap ldstm-bits ins, ;

: swp, 1 24 lshift 9 4 lshift or swap data-ins-rd swap data-ins-rm swap data-ins-rn ins, ;

: swi, 15 24 lshift or ins, ;

: cdp-in 5 lshift or ;
: cdp-rm data-ins-rm ;
: cdp-rn data-ins-rn ;
: cdp-rd data-ins-rd ;
: cdp-no 8 lshift or ;
: cdp-op 20 lshift or ;

: cdp, 14 24 lshift swap cdp-no swap cdp-op swap cdp-rd swap cdp-rn swap cdp-rm swap cdp-in ins, ;

: ldstc-imm-8 or ;
: stc, 3 26 lshift swap cdp-no swap cdp-rd swap data-ins-rn swap ldstc-imm-8 ins, ;
: ldc, 3 26 lshift 1 20 lshift or swap cdp-no swap cdp-rd swap data-ins-rn swap ldstc-imm-8 ins, ;

: mrcr-cop 21 lshift or ;

: mcr, 7 25 lshift 16 or swap cdp-no swap mrcr-cop swap cdp-rd swap cdp-rn swap cdp-rm swap cdp-in ins, ;
: mrc, 7 25 lshift 1 20 lshift or 16 or swap cdp-no swap mrcr-cop swap cdp-rd swap cdp-rn swap cdp-rm swap cdp-in ins, ;

variable _as-start

: as-start here _as-start ! ;
: as-end _as-start @ here over - output @ write-file throw ;

variable inter-vec
: blank-vec dup 0 = if exit then 1 - here b, recurse ;
: reserve-vec here inter-vec ! 8 blank-vec ;
: reset-b here inter-vec @ swap - dup allot swap b, -1 ins swap - allot ;

hex
3f200000 constant gpio-base
3f200094 constant gppud
3f200098 constant gppudclk
3f201000 constant uart-base
101f1000 constant uart-dr
3f201004 constant uart-rsrecr
3f201018 constant uart-fr
3f201024 constant uart-ibrd
3f201028 constant uart-fbrd
3f20102c constant uart-lcrh
3f201030 constant uart-cr
3f201038 constant uart-imsc
3f201044 constant uart-icr

decimal
as-start
( instruction vector table )
reserve-vec
( start of code )

create delay
	1 r0 r0 subi, s,
	delay b, ne,
	lr pc mov,

create immidiate
	4 up lr r0 ldri,
	lr pc mov,
: imm, immidiate bl, num, ;

create uart-init
	lr r11 mov,
	uart-cr imm,
	0 r1 movi,
	r0 r1 set,

	gppud imm,
	r0 r1 set,

	255 r0 movi,
	delay bl,

	gppudclk imm,
	r0 r2 mov,
	3 18 irot r1 movi,
	r0 r1 set,

	255 0 r0 movi,
	delay bl,

	r2 r0 mov,
	0 r1 movi,
	r0 r1 set,

	hex 7ff imm,
	decimal
	r0 r1 mov,
	uart-icr imm,
	r0 r1 set,

	uart-ibrd imm,
	1 r1 movi,
	r0 r1 set,

	uart-fbrd imm,
	40 r1 movi,
	r0 r1 set,

	uart-lcrh imm,
	112 r1 movi,
	r0 r1 set,

	uart-imsc imm,
	30 26 irot r1 movi,
	114 r1 r1 orri,
	r0 r1 set,

	uart-cr imm,
	3 24 irot r1 movi,
	1 r1 r1 orri,
	r0 r1 set,

	r11 pc mov,

create uart-putc
	lr r11 mov,
	r0 r1 mov,
( 	uart-fr imm,
	0 r0 r2 ldri,
	32 r2 r2 orri, s,
	here 2 ins - b, ne,
)
	uart-dr imm,
	r0 r1 set,
	r11 pc mov,

create main
( 
	5 r0 r0 r1 0 15 mrc,
	3 r1 r1 andi,
	0 r1 r1 cmpi,
	here b, ne,

	uart-init bl,
)
	97 r0 movi,
	uart-putc bl,
	13 r0 movi,
	uart-putc bl,
	10 r0 movi,
	uart-putc bl,

	here b,

( 
r0 r0 r0 add, s
r1 r2 r3 orr,
here 2 ins - b,
r1 up pre wb r2 r3 ldr,
1 r2 r3 r4 5 6 cdp,
12 swi,
1 r2 r3 r4 5 6 mrc,
1 r2 r3 4 stc,
r1 r2 r3 swp,
)
main reset-b
as-end
output @ close-file

bye
