;	This is a hash table dictionary for use with a forth

;	Hash table layout
;	struct bucket {
;		size_t hash
;		size_t item
;	}
;	struct hash_table {
;		size_t size
;		size_t no_items
;		bucket *items
;	}

HASH_TABLE_SIZE equ 0
HASH_TABLE_NO_ITEMS equ 4
HASH_TABLE_ITEMS equ 8

BUCKET_HASH equ 0
BUCKET_ITEM equ 4

BUCKET_STEP equ 8
BUCKET_SHIFT_STEP equ 3

;	R0 Hashtable pointer
;	R1 Key pointer
;	R2 Value
;	R3 hash
;	r4 size
;	r5 item pointer
;	r6 intended bucket
;	r7 comparison hash

insert:
	bl string_hash
	 ldr r5, [r0, HASH_TABLE_ITEMS]
	 ldr r4, [r0, HASH_TABLE_SIZE]
	 lsr r6, r3, r4
	 add r5, r5, r6 lsr BUCKET_SHIFT_STEP
insert_test:
	 ldr r7, [r6, BUCKET_HASH]
	 cmp r7, #0
	 jeq insert_test_suc
	 cmp r3, r6
	 jeq insert_test_eq
	 cmp 


