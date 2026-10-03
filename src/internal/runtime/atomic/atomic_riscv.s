// Copyright 2026 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// 32-bit RISC-V has atomic instructions for words only. The 64-bit
// operations are done in Go under a spin lock, see atomic_riscv.go.

#include "textflag.h"

// func Cas(ptr *uint32, old, new uint32) bool
TEXT ·Cas(SB), NOSPLIT, $0-13
	MOV	ptr+0(FP), A0
	MOVW	old+4(FP), A1
	MOVW	new+8(FP), A2
cas_again:
	LRW	(A0), A3
	BNE	A3, A1, cas_fail
	SCW	A2, (A0), A4
	BNE	A4, ZERO, cas_again
	MOV	$1, A0
	MOVB	A0, ret+12(FP)
	RET
cas_fail:
	MOVB	ZERO, ret+12(FP)
	RET

TEXT ·Casint32(SB), NOSPLIT, $0-13
	JMP	·Cas(SB)

TEXT ·Casint64(SB), NOSPLIT, $0-21
	JMP	·Cas64(SB)

TEXT ·Casuintptr(SB), NOSPLIT, $0-13
	JMP	·Cas(SB)

TEXT ·CasRel(SB), NOSPLIT, $0-13
	JMP	·Cas(SB)

TEXT ·Casp1(SB), NOSPLIT, $0-13
	JMP	·Cas(SB)

// func Load(ptr *uint32) uint32
TEXT ·Load(SB), NOSPLIT|NOFRAME, $0-8
	MOV	ptr+0(FP), A0
	LRW	(A0), A0
	MOVW	A0, ret+4(FP)
	RET

// func Load8(ptr *uint8) uint8
TEXT ·Load8(SB), NOSPLIT|NOFRAME, $0-5
	MOV	ptr+0(FP), A0
	FENCE	RW, RW
	MOVBU	(A0), A1
	FENCE	R, RW
	MOVB	A1, ret+4(FP)
	RET

TEXT ·Loaduintptr(SB), NOSPLIT, $0-8
	JMP	·Load(SB)

TEXT ·Loaduint(SB), NOSPLIT, $0-8
	JMP	·Load(SB)

TEXT ·Loadp(SB), NOSPLIT, $0-8
	JMP	·Load(SB)

TEXT ·Loadint32(SB), NOSPLIT, $0-8
	JMP	·Load(SB)

TEXT ·Loadint64(SB), NOSPLIT, $0-12
	JMP	·Load64(SB)

TEXT ·LoadAcq(SB), NOSPLIT|NOFRAME, $0-8
	JMP	·Load(SB)

TEXT ·LoadAcquintptr(SB), NOSPLIT|NOFRAME, $0-8
	JMP	·Load(SB)

// func Store(ptr *uint32, val uint32)
TEXT ·Store(SB), NOSPLIT, $0-8
	MOV	ptr+0(FP), A0
	MOVW	val+4(FP), A1
	AMOSWAPW A1, (A0), ZERO
	RET

// func Store8(ptr *uint8, val uint8)
TEXT ·Store8(SB), NOSPLIT, $0-5
	MOV	ptr+0(FP), A0
	MOVBU	val+4(FP), A1
	FENCE	RW, W
	MOVB	A1, (A0)
	FENCE	RW, RW
	RET

TEXT ·Storeint32(SB), NOSPLIT, $0-8
	JMP	·Store(SB)

TEXT ·Storeint64(SB), NOSPLIT, $0-12
	JMP	·Store64(SB)

TEXT ·Storeuintptr(SB), NOSPLIT, $0-8
	JMP	·Store(SB)

TEXT ·StorepNoWB(SB), NOSPLIT, $0-8
	JMP	·Store(SB)

TEXT ·StoreRel(SB), NOSPLIT, $0-8
	JMP	·Store(SB)

TEXT ·StoreReluintptr(SB), NOSPLIT, $0-8
	JMP	·Store(SB)

// func Xchg(ptr *uint32, new uint32) uint32
TEXT ·Xchg(SB), NOSPLIT, $0-12
	MOV	ptr+0(FP), A0
	MOVW	new+4(FP), A1
	AMOSWAPW A1, (A0), A1
	MOVW	A1, ret+8(FP)
	RET

// func Xchg8(ptr *uint8, new uint8) uint8
TEXT ·Xchg8(SB), NOSPLIT, $0-9
	MOV	ptr+0(FP), A0
	MOVBU	new+4(FP), A1
	AND	$3, A0, A2
	SLL	$3, A2
	MOV	$255, A4
	SLL	A2, A4
	NOT	A4
	AND	$~3, A0
	SLL	A2, A1
xchg8_again:
	LRW	(A0), A5
	AND	A4, A5, A3
	OR	A1, A3
	SCW	A3, (A0), A6
	BNEZ	A6, xchg8_again
	SRL	A2, A5
	MOVB	A5, ret+8(FP)
	RET

TEXT ·Xchgint32(SB), NOSPLIT, $0-12
	JMP	·Xchg(SB)

TEXT ·Xchgint64(SB), NOSPLIT, $0-20
	JMP	·Xchg64(SB)

TEXT ·Xchguintptr(SB), NOSPLIT, $0-12
	JMP	·Xchg(SB)

// func Xadd(ptr *uint32, delta int32) uint32
TEXT ·Xadd(SB), NOSPLIT, $0-12
	MOV	ptr+0(FP), A0
	MOVW	delta+4(FP), A1
	AMOADDW A1, (A0), A2
	ADD	A2, A1, A0
	MOVW	A0, ret+8(FP)
	RET

TEXT ·Xadduintptr(SB), NOSPLIT, $0-12
	JMP	·Xadd(SB)

TEXT ·Xaddint32(SB), NOSPLIT, $0-12
	JMP	·Xadd(SB)

TEXT ·Xaddint64(SB), NOSPLIT, $0-20
	JMP	·Xadd64(SB)

// func And8(ptr *uint8, val uint8)
TEXT ·And8(SB), NOSPLIT, $0-5
	MOV	ptr+0(FP), A0
	MOVBU	val+4(FP), A1
	AND	$3, A0, A2
	AND	$-4, A0
	SLL	$3, A2
	XOR	$255, A1
	SLL	A2, A1
	XOR	$-1, A1
	AMOANDW A1, (A0), ZERO
	RET

// func Or8(ptr *uint8, val uint8)
TEXT ·Or8(SB), NOSPLIT, $0-5
	MOV	ptr+0(FP), A0
	MOVBU	val+4(FP), A1
	AND	$3, A0, A2
	AND	$-4, A0
	SLL	$3, A2
	SLL	A2, A1
	AMOORW	A1, (A0), ZERO
	RET

// func And(ptr *uint32, val uint32)
TEXT ·And(SB), NOSPLIT, $0-8
	MOV	ptr+0(FP), A0
	MOVW	val+4(FP), A1
	AMOANDW	A1, (A0), ZERO
	RET

// func Or(ptr *uint32, val uint32)
TEXT ·Or(SB), NOSPLIT, $0-8
	MOV	ptr+0(FP), A0
	MOVW	val+4(FP), A1
	AMOORW	A1, (A0), ZERO
	RET

// func Or32(ptr *uint32, val uint32) uint32
TEXT ·Or32(SB), NOSPLIT, $0-12
	MOV	ptr+0(FP), A0
	MOVW	val+4(FP), A1
	AMOORW	A1, (A0), A2
	MOVW	A2, ret+8(FP)
	RET

// func And32(ptr *uint32, val uint32) uint32
TEXT ·And32(SB), NOSPLIT, $0-12
	MOV	ptr+0(FP), A0
	MOVW	val+4(FP), A1
	AMOANDW	A1, (A0), A2
	MOVW	A2, ret+8(FP)
	RET

TEXT ·Anduintptr(SB), NOSPLIT, $0-12
	JMP	·And32(SB)

TEXT ·Oruintptr(SB), NOSPLIT, $0-12
	JMP	·Or32(SB)

// func spinLock(state *uint32)
TEXT ·spinLock(SB), NOSPLIT, $0-4
	MOV	state+0(FP), A0
	MOV	$1, A1
lock_again:
	AMOSWAPW A1, (A0), A2
	BNEZ	A2, lock_again
	RET

// func spinUnlock(state *uint32)
TEXT ·spinUnlock(SB), NOSPLIT, $0-4
	MOV	state+0(FP), A0
	AMOSWAPW ZERO, (A0), ZERO
	RET
