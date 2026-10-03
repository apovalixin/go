// Copyright 2026 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include "textflag.h"
#include "funcdata.h"

// makeFuncStub is the code half of the function returned by MakeFunc.
// See the comment on the declaration of makeFuncStub in makefunc.go
// for more details.
// No arg size here, runtime pulls arg map out of the func value.
TEXT ·makeFuncStub(SB),(NOSPLIT|WRAPPER),$20
	NO_LOCAL_POINTERS
	MOV	CTXT, 4(X2)
	MOV	$argframe+0(FP), T0
	MOV	T0, 8(X2)
	MOVB	ZERO, 20(X2)
	ADD	$20, X2, T0
	MOV	T0, 12(X2)
	MOV	ZERO, 16(X2)
	CALL	·callReflect(SB)
	RET

// methodValueCall is the code half of the function returned by makeMethodValue.
// See the comment on the declaration of methodValueCall in makefunc.go
// for more details.
// No arg size here; runtime pulls arg map out of the func value.
TEXT ·methodValueCall(SB),(NOSPLIT|WRAPPER),$20
	NO_LOCAL_POINTERS
	MOV	CTXT, 4(X2)
	MOV	$argframe+0(FP), T0
	MOV	T0, 8(X2)
	MOVB	ZERO, 20(X2)
	ADD	$20, X2, T0
	MOV	T0, 12(X2)
	MOV	ZERO, 16(X2)
	CALL	·callMethod(SB)
	RET
