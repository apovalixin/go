// Copyright 2026 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Written by hand after preempt_riscv64.s: mkpreempt.go does not know the
// 32-bit port yet. Floating point is soft, so only the integer registers
// are saved.

#include "go_asm.h"
#include "textflag.h"

TEXT ·asyncPreempt(SB),NOSPLIT|NOFRAME,$0-0
	MOV X1, -104(X2)
	SUB $104, X2
	MOV X5, 4(X2)
	MOV X6, 8(X2)
	MOV X7, 12(X2)
	MOV X8, 16(X2)
	MOV X9, 20(X2)
	MOV X10, 24(X2)
	MOV X11, 28(X2)
	MOV X12, 32(X2)
	MOV X13, 36(X2)
	MOV X14, 40(X2)
	MOV X15, 44(X2)
	MOV X16, 48(X2)
	MOV X17, 52(X2)
	MOV X18, 56(X2)
	MOV X19, 60(X2)
	MOV X20, 64(X2)
	MOV X21, 68(X2)
	MOV X22, 72(X2)
	MOV X23, 76(X2)
	MOV X24, 80(X2)
	MOV X25, 84(X2)
	MOV X26, 88(X2)
	MOV X28, 92(X2)
	MOV X29, 96(X2)
	MOV X30, 100(X2)
	CALL ·asyncPreempt2(SB)
	MOV 100(X2), X30
	MOV 96(X2), X29
	MOV 92(X2), X28
	MOV 88(X2), X26
	MOV 84(X2), X25
	MOV 80(X2), X24
	MOV 76(X2), X23
	MOV 72(X2), X22
	MOV 68(X2), X21
	MOV 64(X2), X20
	MOV 60(X2), X19
	MOV 56(X2), X18
	MOV 52(X2), X17
	MOV 48(X2), X16
	MOV 44(X2), X15
	MOV 40(X2), X14
	MOV 36(X2), X13
	MOV 32(X2), X12
	MOV 28(X2), X11
	MOV 24(X2), X10
	MOV 20(X2), X9
	MOV 16(X2), X8
	MOV 12(X2), X7
	MOV 8(X2), X6
	MOV 4(X2), X5
	MOV 104(X2), X1
	MOV (X2), X31
	ADD $108, X2
	JMP (X31)
