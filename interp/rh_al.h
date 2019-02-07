/*******************************************************************************
* Copyright 2017 James RH Ellis
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal 
* in the Software without restriction, including without limitation the rights 
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
* copies of the Software, and to permit persons to whom the Software is 
* furnished to do so, subject to the following conditions:
* 
* The above copyright notice and this permission notice shall be included in all 
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
* SOFTWARE.
*******************************************************************************/

#ifndef RH_AL_H
#define RH_AL_H

#include <stdlib.h>
#include <string.h>

#define RH_AL_MAKE(NAME, TYPE)					 		\
	RH_AL_DEF(NAME, TYPE);							\
	RH_AL_IMPL(NAME, TYPE);

// Useful iteration macro
#define rh_al_for(iter, al, code)						\
if (al.items)									\
	for (size_t __i = 0;__i < al.top;++__i) {				\
		iter = al.items[__i];						\
		code }

#define RH_AL_DEF(NAME, TYPE) 							\
typedef struct {								\
	size_t size;								\
	size_t top;								\
										\
	TYPE *items;								\
} NAME;										\

#define RH_AL_IMPL(NAME, TYPE)							\
static inline size_t NAME##_resize(NAME *al, size_t to) {			\
	if (!to || al->top > to) {						\
		return 0;							\
	}									\
										\
	TYPE *new = realloc(al->items, to * sizeof(TYPE));			\
	if (!new) {								\
		return 0;							\
	}									\
										\
	al->items = new;							\
	al->size = to;								\
										\
	return al->size;							\
}										\
										\
static inline void NAME##_free(NAME *al) {					\
	free(al->items);							\
}										\
										\
static inline NAME NAME##_new(size_t size) {					\
	NAME ret = {0};								\
	NAME##_resize(&ret, size);						\
	return ret;								\
}										\
										\
static inline NAME NAME##_clone(NAME *al) {					\
	if (!al->items || !al->top) {						\
		return (NAME) {0};						\
	}									\
										\
	NAME ret = {0};								\
	NAME##_resize(&ret, al->size);						\
	memcpy(ret.items, al->items, al->top * sizeof(*al->items));		\
	return ret;								\
}										\
										\
static inline TYPE NAME##_peek(NAME *al) {					\
	return al->items[al->top -1];						\
}										\
										\
static inline TYPE *NAME##_rpeek(NAME *al) {					\
	if (!al->top) {								\
		return NULL;							\
	}									\
	return &al->items[al->top -1];						\
}										\
										\
static inline int NAME##_push(NAME *al, TYPE push) {				\
	if (al->top == al->size							\
	&& !NAME##_resize(al, (al->size?:1) * 2)) {				\
		return 0;							\
	}									\
										\
	al->items[al->top++] = push;						\
	return 1;								\
}										\
										\
static inline TYPE NAME##_pop(NAME *al) {					\
	if (!al->top) {								\
		return (TYPE) {0};						\
	}									\
										\
	return al->items[--al->top];						\
}										\
										\
static inline TYPE NAME##_view(NAME *al, size_t pos) {				\
	if (pos >= al->top) {							\
		return (TYPE) {0};						\
	}									\
										\
	return al->items[pos];							\
}										\

#endif
