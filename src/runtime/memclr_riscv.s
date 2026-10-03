// Copyright 2026 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include "textflag.h"

// See memclrNoHeapPointers Go doc for important implementation constraints.

// func memclrNoHeapPointers(ptr unsafe.Pointer, n uintptr)
TEXT runtime·memclrNoHeapPointers(SB),NOSPLIT,$0-8
	MOV	ptr+0(FP), X10
	MOV	n+4(FP), X11
	ADD	X10, X11, X12	// end

	// Too short to be worth aligning.
	MOV	$8, X13
	BLTU	X11, X13, bytes

	// Zero bytes up to a word boundary.
align:
	AND	$3, X10, X13
	BEQZ	X13, aligned
	MOVB	ZERO, (X10)
	ADD	$1, X10
	JMP	align

aligned:
	AND	$~3, X12, X13	// end of the whole words
words:
	BGEU	X10, X13, bytes
	MOVW	ZERO, (X10)
	ADD	$4, X10
	JMP	words

bytes:
	BGEU	X10, X12, done
	MOVB	ZERO, (X10)
	ADD	$1, X10
	JMP	bytes
done:
	RET
