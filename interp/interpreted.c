// This is an interpreted forth-like programming language to bootstrap
// my lower level forth-like programmign language

// This is designed to be hosted on a c based os, and most functionality
// is provided through c interop

#include "rh_al.h"
#include "rh_hash.h"

typedef unsigned char ins;

enum func {
	F_INTER,
	F_C,
};

typedef struct func {
	char type;
	union {
	size_t cfunc(size_t top);
	ins *ifunc;
	};
} func;

RH_MAKE_AL(func_al, func);
RH_MAKE_HASH(func_map, char *, int, rh_string_hash, rh_string_eq, 0.9);

enum ins {
	I_NOP,
	I_END,
	I_ADD,
	I_SUB,
	I_POP,
	I_IMM8,
	I_IMM16,
	I_IMM32,
	I_IMM64,
	I_LOAD8,
	I_LOAD16,
	I_LOAD32,
	I_LOAD64,
	I_STORE8,
	I_STORE16,
	I_STORE32,
	I_STORE64,
	I_CALL,
	I_RET,
	I_SWAP,
};

func_map func_dict;
func_al reg;

void register_func(func f, char *name) {
	size_t pos = reg.top;
	func_al_push(&reg, f);
	func_map_set(func_dict, name, pos);
}

size_t stacks[2048];
int main(int argn, char **argv) {
	size_t *stack = stacks;
	size_t *return_stack = stacks + sizeof(stacks) / sizeof(*stacks);
	// Keep the top of the stack in a register to reduce number of load/stores
	size_t top = 0;

	ins *pc = compile(args[1]);

	while (1) {
		switch (*ins++.op) {
		case I_END:
			goto EXIT;
		case I_ADD:
			top += *(stack--);
			break;
		case I_SUB:
			top -= *(stack--);
			break;
		case I_POP:
			top = *(stack--);
			break;
		case I_IMM8:
			*(++stack) = top;
			top = *(pc++);
			break;
		case I_IMM16:
			*(++stack) = top;
			top = *(pc++);
			top = (top << 8) | *(pc++);
			break;
		case I_IMM32:
			*(++stack) = top;
			top = *(pc++);
			top = (top << 8) | *(pc++);
			top = (top << 8) | *(pc++);
			top = (top << 8) | *(pc++);
			break;
		case I_IMM64:
			*(++stack) = top;
			top = *(pc++);
			top = (top << 8) | *(pc++);
			top = (top << 8) | *(pc++);
			top = (top << 8) | *(pc++);
			top = (top << 8) | *(pc++);
			top = (top << 8) | *(pc++);
			top = (top << 8) | *(pc++);
			top = (top << 8) | *(pc++);
			break;
		case I_LOAD8:
			*(++stack) = top;
			top= *(uint8_t*)top;
			break;
		case I_LOAD16:
			*(++stack) = top;
			top= *(uint16_t*)top;
			break;
		case I_LOAD32:
			*(++stack) = top;
			top= *(uint32_t*)top;
			break;
		case I_LOAD64:
			*(++stack) = top;
			top= *(uint64_t*)top;
		case I_STORE8:
			uint8_t *p = *(stack--);
			*p = top;
			top = (size_t)p;
			break;
		case I_STORE16:
			uint16_t *p = *(stack--);
			*p = top;
			top = (size_t)p;
			break;
		case I_STORE32:
			uint32_t *p = *(stack--);
			*p = top;
			top = (size_t)p;
			break;
		case I_STORE64:
			uint64_t *p = *(stack--);
			*p = top;
			top = (size_t)p;
			break;
		case I_CALL:
			size_t i = *(pc++);
			i = (i << 8) | *(pc++);
			func p = reg.items[i];
			switch (p.type) {
			case F_C:
				top = p.cfunc(top);
				break;
			case F_INTER:
				*(--return_stack) = pc;
				pc = p.ifunc;
				break;
			default:
				goto EXIT;
			}
			break;
		case I_RET:
			pc = *(return_stack++);
			break;
		case I_SWAP:
			size_t temp = top;
			top = *(stack-1);
			*(stack-1) = temp;
			break;
		default:
			goto EXIT;
		}
	}

	EXIT:
}
