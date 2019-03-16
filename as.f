: cond-mask 0xF and ;

variable cond-invert
: cond-invert? cond-invert @ 0 cond-invert ! ;
: cond-invert 0x10 cond-invert ! ;

decimal
: cond create 4 lshift ,
	does> @ cond-invert? xor here 1 - c@ cond-mask or here 1 - c! ;

hex
( opposite condition is always the inverse of bit 0 )
0 cond eq,	( equal z == 0 )
1 cond ne,	( not equal z == 1 )
2 cond cs,	( unsigned higher or same / carry set c == 1 )
2 cond hs,	( unsigned higher or same / carry set c == 1 )
3 cond cc,	( unsigned lower / carry clear c == 0 )
3 cond lo,	( unsigned lower / carry clear c == 0 )
4 cond mi,	( negative / minus n == 1 )
5 cond pl,	( positive / plus n == 0 )
6 cond vs,	( signed overflow / v set v == 1 )
7 cond vc,	( no signed overflow / v clear v == 0 )
8 cond hi,	( unsigned higher c == 1 and z == 0 )
9 cond ls,	( unsigned lower or same c == 0 and z == 1 )
A cond ge,	( signed greater than or equal n == v )
B cond lt,	( signed less than n != v )
C cond gt,	( signed greater than z == 0 and n == v )
D cond le,	( signed less than or equal z == 1 and n != v )
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
: mvn, 0 swap mvn, ;
: tst, 0 tst, s, ;
: teq, 0 teq, s, ;
: cmp, 0 cmp, s, ;
: cmn, 0 cmn, s, ;

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

: movi, 0 swap movi, ;
: mvni, 0 swap mvni, ;
: tsti, 0 tsti, s, ;
: teqi, 0 teqi, s, ;
: cmpi, 0 cmpi, s, ;
: cmni, 0 cmni, s, ;
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
: st, 0 up -rot stri, ;
: ld, 0 up -rot ldri, ;

: str, 3 25 lshift swap data-ins-rd swap data-ins-rn swap data-ins-rm ins, ;
: ldr, 97 20 lshift swap data-ins-rd swap data-ins-rn swap data-ins-rm ins, ;

( todo ldrh , strh )

: ldstm-bits or ;
: stm, 1 27 lshift swap data-ins-rn swap ldstm-bits ins, ;
: ldm, 129 20 lshift swap data-ins-rn swap ldstm-bits ins, ;

: push, pre wb sp stm, ;
: pop, up wb sp ldm, ;

( todo mul mla )

( Control and dsp extension space )

: clz, 0xb 21 lshift 1 4 lshift or 0xf 16 lshift or 0xf 8 lshift or swap data-ins-rd swap data-ins-rm ins, ;

: cpsr 0 ;
: spsr 1 22 lshift ;

: msr-flags ( spsr or cpsr ) or ;
: mrs, 1 24 lshift 0xf 16 lshift or swap data-ins-rd swap msr-flags ins, ; 

: msr-flag create 1 swap lshift ,
	does> @ or ;

16 msr-flag c
17 msr-flag x
18 msr-flag s
19 msr-flag f

: msr, 9 21 lshift 0xf 12 lshift or swap msr-flags swap data-ins-rm or ins, ; 
: msri, 25 21 lshift 0xf 12 lshift or swap msr-flags swap data-ins-i12 or ins, ; 

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

: wfe, 0x320f002 ins, ;

( Higher level branching constructs )
: allot-to ( to ) here - allot ;
: back-b-patch ( to patch )
	here >r
	allot-to
	here 3 + c@ >r
	b,
	r> here 1 - c!
	r> allot-to ;

: loop: here ;
: while; b, ;

: while: here ;
: do: here here b, swap ;
: end; b, here swap back-b-patch ;

: if: here here b, cond-invert ;
: else: here here b, here rot back-b-patch ;
: then; here swap back-b-patch ;

: drop-char dup c@ c, 1 + ;
: string, dup 0 = if 0 c, drop drop exit then 1 - >r drop-char r> recurse ;

: zalloc dup 0 = if drop exit then 1 - 0 c, recurse ; 
