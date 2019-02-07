// This is the bootstrap compiler for my forht like programming language
// This would be in a concatenative programming langauge, however there
// do not seem to be any implimentations that can be installed through
// the void linux package manger

// Concat sample
// : [ find-word find-modifiers args-format ] loop sting-end until
// : string-end load-char not
// : find-word as-word-dict match-form-start
// : find-modifiers [ word-modifier-dict match-from-start ] loop not until
// : args-format word-formats formats-parse format-word-emit
// : format-word-emit word-format call

#include <stdio.h>

// Statically allocated stack space for the program
size_t stack[1024];
size_t return_stack[1024];

int main(int argn, char **argv) {

}

