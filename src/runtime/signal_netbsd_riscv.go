// Copyright 2026 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package runtime

import "unsafe"

type sigctxt struct {
	info *siginfo
	ctxt unsafe.Pointer
}

//go:nosplit
//go:nowritebarrierrec
func (c *sigctxt) regs() *mcontextt {
	return (*mcontextt)(unsafe.Pointer(&(*ucontextt)(c.ctxt).uc_mcontext))
}

func (c *sigctxt) ra() uint32  { return c.regs().__gregs[_REG_X1] }
func (c *sigctxt) sp() uint32  { return c.regs().__gregs[_REG_X2] }
func (c *sigctxt) gp() uint32  { return c.regs().__gregs[_REG_X3] }
func (c *sigctxt) tp() uint32  { return c.regs().__gregs[_REG_X4] }
func (c *sigctxt) t0() uint32  { return c.regs().__gregs[_REG_X5] }
func (c *sigctxt) t1() uint32  { return c.regs().__gregs[_REG_X6] }
func (c *sigctxt) t2() uint32  { return c.regs().__gregs[_REG_X7] }
func (c *sigctxt) s0() uint32  { return c.regs().__gregs[_REG_X8] }
func (c *sigctxt) s1() uint32  { return c.regs().__gregs[_REG_X9] }
func (c *sigctxt) a0() uint32  { return c.regs().__gregs[_REG_X10] }
func (c *sigctxt) a1() uint32  { return c.regs().__gregs[_REG_X11] }
func (c *sigctxt) a2() uint32  { return c.regs().__gregs[_REG_X12] }
func (c *sigctxt) a3() uint32  { return c.regs().__gregs[_REG_X13] }
func (c *sigctxt) a4() uint32  { return c.regs().__gregs[_REG_X14] }
func (c *sigctxt) a5() uint32  { return c.regs().__gregs[_REG_X15] }
func (c *sigctxt) a6() uint32  { return c.regs().__gregs[_REG_X16] }
func (c *sigctxt) a7() uint32  { return c.regs().__gregs[_REG_X17] }
func (c *sigctxt) s2() uint32  { return c.regs().__gregs[_REG_X18] }
func (c *sigctxt) s3() uint32  { return c.regs().__gregs[_REG_X19] }
func (c *sigctxt) s4() uint32  { return c.regs().__gregs[_REG_X20] }
func (c *sigctxt) s5() uint32  { return c.regs().__gregs[_REG_X21] }
func (c *sigctxt) s6() uint32  { return c.regs().__gregs[_REG_X22] }
func (c *sigctxt) s7() uint32  { return c.regs().__gregs[_REG_X23] }
func (c *sigctxt) s8() uint32  { return c.regs().__gregs[_REG_X24] }
func (c *sigctxt) s9() uint32  { return c.regs().__gregs[_REG_X25] }
func (c *sigctxt) s10() uint32 { return c.regs().__gregs[_REG_X26] }
func (c *sigctxt) s11() uint32 { return c.regs().__gregs[_REG_X27] }
func (c *sigctxt) t3() uint32  { return c.regs().__gregs[_REG_X28] }
func (c *sigctxt) t4() uint32  { return c.regs().__gregs[_REG_X29] }
func (c *sigctxt) t5() uint32  { return c.regs().__gregs[_REG_X30] }
func (c *sigctxt) t6() uint32  { return c.regs().__gregs[_REG_X31] }

//go:nosplit
//go:nowritebarrierrec
func (c *sigctxt) pc() uint32 { return c.regs().__gregs[_REG_PC] }

func (c *sigctxt) sigcode() uint32 { return uint32(c.info._code) }
func (c *sigctxt) sigaddr() uint32 { return uint32(c.info._reason) }

func (c *sigctxt) set_pc(x uint32) { c.regs().__gregs[_REG_PC] = x }
func (c *sigctxt) set_ra(x uint32) { c.regs().__gregs[_REG_X1] = x }
func (c *sigctxt) set_sp(x uint32) { c.regs().__gregs[_REG_X2] = x }
func (c *sigctxt) set_g(x uint32)  { c.regs().__gregs[_REG_X27] = x }

func (c *sigctxt) set_sigcode(x uint32) { c.info._code = int32(x) }
func (c *sigctxt) set_sigaddr(x uint32) {
	c.info._reason = uintptr(x)
}
