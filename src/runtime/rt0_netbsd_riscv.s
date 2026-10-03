// Copyright 2026 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include "textflag.h"

// The kernel starts a program with A1 pointing to its struct ps_strings:
//
//	char **ps_argvstr;
//	int    ps_nargvstr;
//	char **ps_envstr;
//	int    ps_nenvstr;
//
// The stack pointer is aligned and need not point at argc.
TEXT _rt0_riscv_netbsd(SB),NOSPLIT|NOFRAME,$0
	MOVW	4(A1), A0	// argc
	MOV	0(A1), A1	// argv
	JMP	main(SB)

TEXT main(SB),NOSPLIT|NOFRAME,$0
	MOV	$runtime·rt0_go(SB), T0
	JALR	ZERO, T0
