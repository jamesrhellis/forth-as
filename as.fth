variable output
s" out.bin" w/o open-file throw output !

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

: ins, dup 0 get8b c, dup 1 get8b c, dup 2 get8b c, 3 get8b c, al, ;

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
: imm-shift create 7 lshift ,
	does> @ swap 5 lshift or or ; ( or into the rm register )

0 imm-shift lsl
1 imm-shift lsr
2 imm-shift asr
3 imm-shift ror
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

: s here 2 - dup c@ 16 or swap c! ;

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

: data-ins-i12 3FF and or ;

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

: stri, 1 26 lshift swap data-ins-rd swap data-ins-rn swap data-ins-i12 ins, ;
: ldri, 65 20 lshift swap data-ins-rd swap data-ins-rn swap data-ins-i12 ins, ;

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

as-start
( instruction vector table )
here 8 ins + b,
here b,
here b,
here b,
here b,
here b,
here b,
here b,
( start of code )

5 r0 r0 r1 0 15 mrc,
3 r1 r1 andi,
0 r1 r1 cmpi,
here b, ne,

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
as-end
output @ close-file

