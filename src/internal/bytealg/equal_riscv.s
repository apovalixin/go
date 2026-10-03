// Copyright 2026 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include "go_asm.h"
#include "textflag.h"

// func memequal(a, b unsafe.Pointer, size uintptr) bool
TEXT runtime·memequal(SB),NOSPLIT,$0-13
	MOV	a+0(FP), X10
	MOV	b+4(FP), X11
	MOV	size+8(FP), X12
	MOV	$ret+12(FP), X13
	JMP	memeqbody<>(SB)

// func memequal_varlen(a, b unsafe.Pointer) bool
TEXT runtime·memequal_varlen(SB),NOSPLIT,$0-9
	MOV	a+0(FP), X10
	MOV	b+4(FP), X11
	MOV	4(CTXT), X12	// compiler stores size at offset 4 in the closure
	MOV	$ret+8(FP), X13
	JMP	memeqbody<>(SB)

// X10, X11: the two regions; X12: length; X13: address of the result byte.
TEXT memeqbody<>(SB),NOSPLIT|NOFRAME,$0-0
	BEQ	X10, X11, eq
	ADD	X10, X12, X14	// end of a
	// Compare by words while both pointers are word aligned.
	OR	X10, X11, X15
	AND	$3, X15
	BNEZ	X15, bytes
	AND	$~3, X12, X15
	ADD	X10, X15, X15	// end of the whole words
words:
	BEQ	X10, X15, bytes
	MOVW	(X10), X16
	MOVW	(X11), X17
	BNE	X16, X17, ne
	ADD	$4, X10
	ADD	$4, X11
	JMP	words
bytes:
	BEQ	X10, X14, eq
	MOVBU	(X10), X16
	MOVBU	(X11), X17
	BNE	X16, X17, ne
	ADD	$1, X10
	ADD	$1, X11
	JMP	bytes
eq:
	MOV	$1, X15
	MOVB	X15, (X13)
	RET
ne:
	MOVB	ZERO, (X13)
	RET
