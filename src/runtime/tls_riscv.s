// Copyright 2026 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include "go_asm.h"
#include "funcdata.h"
#include "textflag.h"

// There is no cgo on 32-bit RISC-V, so g lives only in its register and
// there is nothing to save or load.

TEXT runtime·save_g(SB),NOSPLIT|NOFRAME,$0-0
	RET

TEXT runtime·load_g(SB),NOSPLIT|NOFRAME,$0-0
	RET
