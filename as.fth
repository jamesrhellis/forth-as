variable output
s" out.bin" w/o open-file throw output !

: cond create 28 lshift ,
	does> @ -1 allot here @ C@ or , ;

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
	does> @ build-data-ins-r , ;

: s -1 allot here @ 1 20 lshift and , ;

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

: data-ins-i12 or ;

: build-data-ins-i
	swap data-ins-rd swap data-ins-rn swap data-ins-i12 ;

decimal
: data-ins-i create 21 lshift 1 25 lshift and ,
	does> @ build-data-ins-i , ;

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
( Relative address is calculated )
: b, 5 25 lshift swap here 8 + - or , ;
: bl, 11 24 lshift swap here 8 + - or , ; 

: ld-st-flag create 1 swap lshift ,
	does> @ or ;

25 ld-st-flag imm
24 ld-st-flag pre
23 ld-st-flag up
22 ld-st-flag byte
21 ld-st-flag wb

: ldr, 1 26 lshift swap data-ins-rd swap data-ins-rn swap data-ins-i12 , ;
: str, 65 20 lshift swap data-ins-rd swap data-ins-rn swap data-ins-i12 , ;

( todo ldrh , strh )

: ldstm-bits ;
: stm, 1 27 lshift swap data-ins-rn swap ldstm-bits ;
: ldm, 129 27 lshift swap data-ins-rn swap ldstm-bits ;

: swp, 1 24 lshift 9 4 lshift or swap data-ins-rd swap data-ins-rn swap data-ins-rm , ;

: swi, 15 24 lshift or ;

: cdp-in 5 lshift or ;
: cdp-rm data-ins-rm ;
: cdp-rn data-ins-rn ;
: cdp-rd data-ins-rd ;
: cdp-no 8 lshift or ;
: cdp-op 20 lshift or ;

: cdp, 14 24 lshift swap cdp-no swap cdp-op swap cdp-rd swap cdp-rn swap cdp-rm swap cdp-in , ;

: ldstc-imm-8 or ;
: stc 3 26 lshift swap cdp-no swap cdp-rd swap ldstc-imm-8 , ;
: ldc 3 26 lshift 1 20 lshift or swap cdp-no swap cdp-rd swap ldstc-imm-8 , ;

: mrcr-cop 21 lshift or ;

: mrc 7 25 lshift swap cdp-no swap mrcr-cop swap cdp-rd swap cdp-rn swap cdp-rm swap cdp-in , ;

variable _as-start

: as-start here _as-start ! ;
: as-end _as-start @ here 4 - over - output @ write-file throw ;

as-start
r0 r0 r0 add,
as-end
output @ close-file

