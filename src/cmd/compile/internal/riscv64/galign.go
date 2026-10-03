// Copyright 2016 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package riscv64

import (
	"cmd/compile/internal/ssagen"
	"cmd/internal/obj/riscv"
)

func Init(arch *ssagen.ArchInfo) {
	arch.LinkArch = &riscv.LinkRISCV64

	arch.REGSP = riscv.REG_SP
	arch.MAXWIDTH = 1 << 50

	arch.Ginsnop = ginsnop
	arch.ZeroRange = zeroRange

	arch.SSAMarkMoves = ssaMarkMoves
	arch.SSAGenValue = ssaGenValue
	arch.SSAGenBlock = ssaGenBlock
	arch.LoadRegResult = loadRegResult
	arch.SpillArgReg = spillArgReg
}

// InitRV32 sets up the back end for 32-bit RISC-V (GOARCH=riscv). It
// shares the code generator with riscv64: the SSA ops are the same and
// the assembler emits the RV32 form of each instruction.
func InitRV32(arch *ssagen.ArchInfo) {
	Init(arch)
	arch.LinkArch = &riscv.LinkRISCV
	arch.MAXWIDTH = (1 << 31) - 1
	// The baseline is RV32IMAC: no floating-point registers are assumed.
	arch.SoftFloat = true
}
