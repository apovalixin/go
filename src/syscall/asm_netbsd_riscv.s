// Copyright 2026 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include "textflag.h"

//
// System call support for riscv, NetBSD
//

// The system call number goes in T6. The kernel returns to the instruction
// after ECALL when the call failed, with the error number in A0, and two
// instructions further when it succeeded, so ECALL is followed by exactly
// two four-byte instructions.
#define NOP4	WORD	$0x00000013

// func Syscall(trap, a1, a2, a3 uintptr) (r1, r2, err uintptr)
// func Syscall6(trap, a1, a2, a3, a4, a5, a6 uintptr) (r1, r2, err uintptr)
// func Syscall9(trap, a1, a2, a3, a4, a5, a6, a7, a8, a9 uintptr) (r1, r2, err uintptr)
// func RawSyscall(trap, a1, a2, a3 uintptr) (r1, r2, err uintptr)
// func RawSyscall6(trap, a1, a2, a3, a4, a5, a6 uintptr) (r1, r2, err uintptr)
//
// Eight argument words go in registers. No NetBSD system call takes more:
// the ninth argument of Syscall9 is padding and is dropped.

TEXT	·Syscall(SB),NOSPLIT,$0-28
	CALL	runtime·entersyscall(SB)
	MOV	trap+0(FP), T6	// syscall entry
	MOV	a1+4(FP), A0
	MOV	a2+8(FP), A1
	MOV	a3+12(FP), A2
	ECALL
	JMP	err
	NOP4
	MOV	A0, r1+16(FP)
	MOV	A1, r2+20(FP)
	MOV	ZERO, err+24(FP)
	CALL	runtime·exitsyscall(SB)
	RET
err:
	MOV	$-1, T0
	MOV	T0, r1+16(FP)
	MOV	ZERO, r2+20(FP)
	MOV	A0, err+24(FP)
	CALL	runtime·exitsyscall(SB)
	RET

TEXT	·Syscall6(SB),NOSPLIT,$0-40
	CALL	runtime·entersyscall(SB)
	MOV	trap+0(FP), T6	// syscall entry
	MOV	a1+4(FP), A0
	MOV	a2+8(FP), A1
	MOV	a3+12(FP), A2
	MOV	a4+16(FP), A3
	MOV	a5+20(FP), A4
	MOV	a6+24(FP), A5
	ECALL
	JMP	err
	NOP4
	MOV	A0, r1+28(FP)
	MOV	A1, r2+32(FP)
	MOV	ZERO, err+36(FP)
	CALL	runtime·exitsyscall(SB)
	RET
err:
	MOV	$-1, T0
	MOV	T0, r1+28(FP)
	MOV	ZERO, r2+32(FP)
	MOV	A0, err+36(FP)
	CALL	runtime·exitsyscall(SB)
	RET

TEXT	·Syscall9(SB),NOSPLIT,$0-52
	CALL	runtime·entersyscall(SB)
	MOV	trap+0(FP), T6	// syscall entry
	MOV	a1+4(FP), A0
	MOV	a2+8(FP), A1
	MOV	a3+12(FP), A2
	MOV	a4+16(FP), A3
	MOV	a5+20(FP), A4
	MOV	a6+24(FP), A5
	MOV	a7+28(FP), A6
	MOV	a8+32(FP), A7
	ECALL
	JMP	err
	NOP4
	MOV	A0, r1+40(FP)
	MOV	A1, r2+44(FP)
	MOV	ZERO, err+48(FP)
	CALL	runtime·exitsyscall(SB)
	RET
err:
	MOV	$-1, T0
	MOV	T0, r1+40(FP)
	MOV	ZERO, r2+44(FP)
	MOV	A0, err+48(FP)
	CALL	runtime·exitsyscall(SB)
	RET

TEXT	·RawSyscall(SB),NOSPLIT,$0-28
	MOV	trap+0(FP), T6	// syscall entry
	MOV	a1+4(FP), A0
	MOV	a2+8(FP), A1
	MOV	a3+12(FP), A2
	ECALL
	JMP	err
	NOP4
	MOV	A0, r1+16(FP)
	MOV	A1, r2+20(FP)
	MOV	ZERO, err+24(FP)
	RET
err:
	MOV	$-1, T0
	MOV	T0, r1+16(FP)
	MOV	ZERO, r2+20(FP)
	MOV	A0, err+24(FP)
	RET

TEXT	·RawSyscall6(SB),NOSPLIT,$0-40
	MOV	trap+0(FP), T6	// syscall entry
	MOV	a1+4(FP), A0
	MOV	a2+8(FP), A1
	MOV	a3+12(FP), A2
	MOV	a4+16(FP), A3
	MOV	a5+20(FP), A4
	MOV	a6+24(FP), A5
	ECALL
	JMP	err
	NOP4
	MOV	A0, r1+28(FP)
	MOV	A1, r2+32(FP)
	MOV	ZERO, err+36(FP)
	RET
err:
	MOV	$-1, T0
	MOV	T0, r1+28(FP)
	MOV	ZERO, r2+32(FP)
	MOV	A0, err+36(FP)
	RET
