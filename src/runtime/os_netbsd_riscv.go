// Copyright 2026 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package runtime

import (
	"internal/abi"
	"unsafe"
)

func lwp_mcontext_init(mc *mcontextt, stk unsafe.Pointer, mp *m, gp *g, fn uintptr) {
	mc.__gregs[_REG_PC] = uint32(abi.FuncPCABI0(lwp_tramp))
	mc.__gregs[_REG_X2] = uint32(uintptr(stk))
	mc.__gregs[_REG_X10] = uint32(uintptr(unsafe.Pointer(mp)))
	mc.__gregs[_REG_X11] = uint32(uintptr(unsafe.Pointer(gp)))
	mc.__gregs[_REG_X12] = uint32(fn)
}

func cputicks() int64 {
	// runtime·nanotime() is a poor approximation of CPU ticks that is enough for the profiler.
	return nanotime()
}
