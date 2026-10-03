// Copyright 2026 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include "textflag.h"

// See memmove Go doc for important implementation constraints.

// func memmove(to, from unsafe.Pointer, n uintptr)
//
// Pointers are copied a word at a time, never byte by byte, so that the
// garbage collector does not see half a pointer: words are used whenever
// both addresses are aligned.
TEXT runtime·memmove(SB),NOSPLIT,$0-12
	MOV	to+0(FP), X10
	MOV	from+4(FP), X11
	MOV	n+8(FP), X12
	BEQ	X10, X11, done
	BEQZ	X12, done

	OR	X10, X11, X13
	AND	$3, X13	// both aligned to a word?

	// Copy backward if the destination is above the source.
	BLTU	X11, X10, backward

	ADD	X11, X12, X14	// end of from
	BNEZ	X13, fbytes
	AND	$~3, X12, X15
	ADD	X11, X15, X15	// end of the whole words
fwords:
	BGEU	X11, X15, fbytes
	MOVW	(X11), X16
	MOVW	X16, (X10)
	ADD	$4, X11
	ADD	$4, X10
	JMP	fwords
fbytes:
	BGEU	X11, X14, done
	MOVBU	(X11), X16
	MOVB	X16, (X10)
	ADD	$1, X11
	ADD	$1, X10
	JMP	fbytes

backward:
	MOV	X11, X14	// start of from
	ADD	X12, X11	// end of from
	ADD	X12, X10	// end of to
	BNEZ	X13, bbytes
	// The starts are word aligned; copy the tail bytes first so that the
	// ends are aligned too.
btail:
	AND	$3, X11, X15
	BEQZ	X15, bwords
	ADD	$-1, X11
	ADD	$-1, X10
	MOVBU	(X11), X16
	MOVB	X16, (X10)
	JMP	btail
bwords:
	BGEU	X14, X11, done
	ADD	$-4, X11
	ADD	$-4, X10
	MOVW	(X11), X16
	MOVW	X16, (X10)
	JMP	bwords
bbytes:
	BGEU	X14, X11, done
	ADD	$-1, X11
	ADD	$-1, X10
	MOVBU	(X11), X16
	MOVB	X16, (X10)
	JMP	bbytes
done:
	RET
