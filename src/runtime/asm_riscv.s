// Copyright 2026 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// 32-bit RISC-V. Everything here uses the stack-based ABI0: the port has
// no register ABI.

#include "go_asm.h"
#include "funcdata.h"
#include "textflag.h"

// func rt0_go()
TEXT runtime·rt0_go(SB),NOSPLIT|TOPFRAME,$0
	// X2 = stack; A0 = argc; A1 = argv
	SUB	$12, X2
	MOVW	A0, 4(X2)	// argc
	MOV	A1, 8(X2)	// argv

	// create istack out of the given (operating system) stack.
	MOV	$runtime·g0(SB), g
	MOV	$(-64*1024), T0
	ADD	T0, X2, T1
	MOV	T1, g_stackguard0(g)
	MOV	T1, g_stackguard1(g)
	MOV	T1, (g_stack+stack_lo)(g)
	MOV	X2, (g_stack+stack_hi)(g)

	// update stackguard after the stack is set up
	MOV	(g_stack+stack_lo)(g), T0
	ADD	$const_stackGuard, T0
	MOV	T0, g_stackguard0(g)
	MOV	T0, g_stackguard1(g)

	// set the per-goroutine and per-mach "registers"
	MOV	$runtime·m0(SB), T0

	// save m->g0 = g0
	MOV	g, m_g0(T0)
	// save m0 to g0->m
	MOV	T0, g_m(g)

	CALL	runtime·check(SB)

	// args are already prepared
	CALL	runtime·args(SB)
	CALL	runtime·osinit(SB)
	CALL	runtime·schedinit(SB)

	// create a new goroutine to start program
	MOV	$runtime·mainPC(SB), T0		// entry
	SUB	$8, X2
	MOV	T0, 4(X2)
	MOV	ZERO, 0(X2)
	CALL	runtime·newproc(SB)
	ADD	$8, X2

	// start this M
	CALL	runtime·mstart(SB)

	WORD $0 // crash if reached
	RET

DATA	runtime·mainPC+0(SB)/4,$runtime·main(SB)
GLOBL	runtime·mainPC(SB),RODATA,$4

TEXT runtime·mstart(SB),NOSPLIT|TOPFRAME,$0
	CALL	runtime·mstart0(SB)
	RET // not reached

TEXT runtime·breakpoint(SB),NOSPLIT|NOFRAME,$0-0
	EBREAK
	RET

TEXT runtime·abort(SB),NOSPLIT|NOFRAME,$0-0
	EBREAK
	RET

TEXT runtime·asminit(SB),NOSPLIT|NOFRAME,$0-0
	RET

// func procyieldAsm(cycles uint32)
TEXT runtime·procyieldAsm(SB),NOSPLIT,$0-4
	RET

// func checkASM() bool
TEXT runtime·checkASM(SB),NOSPLIT,$0-1
	MOV	$1, T0
	MOVB	T0, ret+0(FP)
	RET

// void setg(G*); set g.
TEXT runtime·setg(SB), NOSPLIT, $0-4
	MOV	gg+0(FP), g
	RET

/*
 *  go-routine
 */

// void gogo(Gobuf*)
// restore state from Gobuf; longjmp
TEXT runtime·gogo(SB), NOSPLIT|NOFRAME, $0-4
	MOV	buf+0(FP), T0
	MOV	gobuf_g(T0), T1
	MOV	0(T1), ZERO // make sure g != nil
	JMP	gogo<>(SB)

TEXT gogo<>(SB), NOSPLIT|NOFRAME, $0
	MOV	T1, g
	MOV	gobuf_sp(T0), X2
	MOV	gobuf_lr(T0), RA
	MOV	gobuf_ctxt(T0), CTXT
	MOV	ZERO, gobuf_sp(T0)
	MOV	ZERO, gobuf_lr(T0)
	MOV	ZERO, gobuf_ctxt(T0)
	MOV	gobuf_pc(T0), T0
	JALR	ZERO, T0

// func mcall(fn func(*g))
// Switch to m->g0's stack, call fn(g).
// Fn must never return. It should gogo(&g->sched)
// to keep running g.
TEXT runtime·mcall(SB), NOSPLIT|NOFRAME, $0-4
	// Save caller state in g->sched
	MOV	X2, (g_sched+gobuf_sp)(g)
	MOV	RA, (g_sched+gobuf_pc)(g)
	MOV	ZERO, (g_sched+gobuf_lr)(g)

	// Switch to m->g0 & its stack, call fn.
	MOV	g, T2
	MOV	g_m(g), T1
	MOV	m_g0(T1), g
	BNE	g, T2, 2(PC)
	JMP	runtime·badmcall(SB)
	MOV	fn+0(FP), CTXT			// context
	MOV	0(CTXT), T1			// code pointer
	MOV	(g_sched+gobuf_sp)(g), X2	// sp = m->g0->sched.sp
	SUB	$8, X2				// room for the argument and a fake LR
	MOV	T2, 4(X2)			// arg = g
	MOV	ZERO, 0(X2)			// clear return address
	JALR	RA, T1
	JMP	runtime·badmcall2(SB)

// systemstack_switch is a dummy routine that systemstack leaves at the bottom
// of the G stack. We need to distinguish the routine that
// lives at the bottom of the G stack from the one that lives
// at the top of the system stack because the one at the top of
// the system stack terminates the stack walk (see topofstack()).
TEXT runtime·systemstack_switch(SB), NOSPLIT, $0-0
	UNDEF
	JALR	RA, ZERO	// make sure this function is not leaf
	RET

// func systemstack(fn func())
TEXT runtime·systemstack(SB), NOSPLIT, $0-4
	MOV	fn+0(FP), CTXT	// CTXT = fn
	MOV	g_m(g), T0	// T0 = m

	MOV	m_gsignal(T0), T1	// T1 = gsignal
	BEQ	g, T1, noswitch

	MOV	m_g0(T0), T1	// T1 = g0
	BEQ	g, T1, noswitch

	MOV	m_curg(T0), T2
	BEQ	g, T2, switch

	// Bad: g is not gsignal, not g0, not curg. What is it?
	// Hide call from linker nosplit analysis.
	MOV	$runtime·badsystemstack(SB), T1
	JALR	RA, T1

switch:
	// save our state in g->sched. Pretend to
	// be systemstack_switch if the G stack is scanned.
	CALL	gosave_systemstack_switch<>(SB)

	// switch to g0
	MOV	T1, g
	MOV	(g_sched+gobuf_sp)(g), T0
	MOV	T0, X2

	// call target function
	MOV	0(CTXT), T1	// code pointer
	JALR	RA, T1

	// switch back to g
	MOV	g_m(g), T0
	MOV	m_curg(T0), g
	MOV	(g_sched+gobuf_sp)(g), X2
	MOV	ZERO, (g_sched+gobuf_sp)(g)
	RET

noswitch:
	// already on system stack, just jump directly to the function
	// Using a tail call here cleans up tracebacks since we won't stop
	// at an intermediate systemstack.
	MOV	0(CTXT), T1	// code pointer
	ADD	$4, X2
	JMP	(T1)

// Save state of caller into g->sched,
// but using fake PC from systemstack_switch.
// Must only be called from functions with no locals ($0)
// or else unwinding from systemstack_switch is incorrect.
// Smashes X31.
TEXT gosave_systemstack_switch<>(SB),NOSPLIT|NOFRAME,$0
	MOV	$runtime·systemstack_switch(SB), X31
	ADD	$8, X31	// get past prologue
	MOV	X31, (g_sched+gobuf_pc)(g)
	MOV	X2, (g_sched+gobuf_sp)(g)
	MOV	ZERO, (g_sched+gobuf_lr)(g)
	// Assert ctxt is zero. See func save.
	MOV	(g_sched+gobuf_ctxt)(g), X31
	BEQ	ZERO, X31, 2(PC)
	CALL	runtime·abort(SB)
	RET

/*
 * support for morestack
 */

// Called during function prolog when more stack is needed.
// Called with return address (i.e. caller's PC) in X5 (aka T0),
// and the LR register contains the caller's LR.
//
// The traceback routines see morestack on a g0 as being
// the top of a stack (for example, morestack calling newstack
// calling the scheduler calling newm calling gc), so we must
// record an argument size. For that purpose, it has no arguments.

// func morestack()
TEXT runtime·morestack(SB),NOSPLIT|NOFRAME,$0-0
	// Called from f.
	// Set g->sched to context in f.
	MOV	X2, (g_sched+gobuf_sp)(g)
	MOV	T0, (g_sched+gobuf_pc)(g)
	MOV	RA, (g_sched+gobuf_lr)(g)
	MOV	CTXT, (g_sched+gobuf_ctxt)(g)

	// Cannot grow scheduler stack (m->g0).
	MOV	g_m(g), A0
	MOV	m_g0(A0), A1
	BNE	g, A1, 3(PC)
	CALL	runtime·badmorestackg0(SB)
	CALL	runtime·abort(SB)

	// Cannot grow signal stack (m->gsignal).
	MOV	m_gsignal(A0), A1
	BNE	g, A1, 3(PC)
	CALL	runtime·badmorestackgsignal(SB)
	CALL	runtime·abort(SB)

	// Called from f.
	// Set m->morebuf to f's caller.
	MOV	RA, (m_morebuf+gobuf_pc)(A0)	// f's caller's PC
	MOV	X2, (m_morebuf+gobuf_sp)(A0)	// f's caller's SP
	MOV	g, (m_morebuf+gobuf_g)(A0)

	// Call newstack on m->g0's stack.
	MOV	m_g0(A0), g
	MOV	(g_sched+gobuf_sp)(g), X2
	// Create a stack frame on g0 to call newstack.
	MOV	ZERO, -4(X2)	// Zero saved LR in frame
	SUB	$4, X2
	CALL	runtime·newstack(SB)

	// Not reached, but make sure the return PC from the call to newstack
	// is still in this function, and not the beginning of the next.
	UNDEF

// func morestack_noctxt()
TEXT runtime·morestack_noctxt(SB),NOSPLIT|NOFRAME,$0-0
	// Force SPWRITE. This function doesn't actually write SP,
	// but it is called with a special calling convention where
	// the caller doesn't save LR on stack but passes it as a
	// register, and the unwinder currently doesn't understand.
	// Make it SPWRITE to stop unwinding. (See issue 54332)
	MOV	X2, X2

	MOV	ZERO, CTXT
	JMP	runtime·morestack(SB)

// reflectcall: call a function with the given argument list
// func call(stackArgsType *_type, f *FuncVal, stackArgs *byte, stackArgsSize, stackRetOffset, frameSize uint32, regArgs *abi.RegArgs).
// we don't have variable-sized frames, so we use a small number
// of constant-sized-frame functions to encode a few bits of size in the pc.
// Caution: ugly multiline assembly macros in your future!

#define DISPATCH(NAME,MAXSIZE)	\
	MOV	$MAXSIZE, T1	\
	BLTU	T1, T0, 3(PC)	\
	MOV	$NAME(SB), T2;	\
	JALR	ZERO, T2
// Note: can't just "BR NAME(SB)" - bad inlining results.

TEXT reflect·call(SB), NOSPLIT, $0-0
	JMP	·reflectcall(SB)

TEXT ·reflectcall(SB), NOSPLIT|NOFRAME, $0-28
	MOVW	frameSize+20(FP), T0
	DISPATCH(runtime·call16, 16)
	DISPATCH(runtime·call32, 32)
	DISPATCH(runtime·call64, 64)
	DISPATCH(runtime·call128, 128)
	DISPATCH(runtime·call256, 256)
	DISPATCH(runtime·call512, 512)
	DISPATCH(runtime·call1024, 1024)
	DISPATCH(runtime·call2048, 2048)
	DISPATCH(runtime·call4096, 4096)
	DISPATCH(runtime·call8192, 8192)
	DISPATCH(runtime·call16384, 16384)
	DISPATCH(runtime·call32768, 32768)
	DISPATCH(runtime·call65536, 65536)
	DISPATCH(runtime·call131072, 131072)
	DISPATCH(runtime·call262144, 262144)
	DISPATCH(runtime·call524288, 524288)
	DISPATCH(runtime·call1048576, 1048576)
	DISPATCH(runtime·call2097152, 2097152)
	DISPATCH(runtime·call4194304, 4194304)
	DISPATCH(runtime·call8388608, 8388608)
	DISPATCH(runtime·call16777216, 16777216)
	DISPATCH(runtime·call33554432, 33554432)
	DISPATCH(runtime·call67108864, 67108864)
	DISPATCH(runtime·call134217728, 134217728)
	DISPATCH(runtime·call268435456, 268435456)
	DISPATCH(runtime·call536870912, 536870912)
	DISPATCH(runtime·call1073741824, 1073741824)
	MOV	$runtime·badreflectcall(SB), T2
	JALR	ZERO, T2

#define CALLFN(NAME,MAXSIZE)			\
TEXT NAME(SB), WRAPPER, $MAXSIZE-28;		\
	NO_LOCAL_POINTERS;			\
	/* copy arguments to stack */		\
	MOV	stackArgs+8(FP), A1;		\
	MOVW	stackArgsSize+12(FP), A2;	\
	MOV	X2, A3;				\
	ADD	$4, A3;				\
	ADD	A3, A2;				\
	BEQ	A3, A2, 6(PC);			\
	MOVBU	(A1), A4;			\
	ADD	$1, A1;				\
	MOVB	A4, (A3);			\
	ADD	$1, A3;				\
	JMP	-5(PC);				\
	/* call function */			\
	MOV	f+4(FP), CTXT;			\
	MOV	(CTXT), X25;			\
	PCDATA  $PCDATA_StackMapIndex, $0;	\
	JALR	RA, X25;			\
	/* copy return values back */		\
	MOV	stackArgsType+0(FP), A5;	\
	MOV	stackArgs+8(FP), A1;		\
	MOVW	stackArgsSize+12(FP), A2;	\
	MOVW	stackRetOffset+16(FP), A4;	\
	ADD	$4, X2, A3;			\
	ADD	A4, A3; 			\
	ADD	A4, A1;				\
	SUB	A4, A2;				\
	CALL	callRet<>(SB);			\
	RET

// callRet copies return values back at the end of call*. This is a
// separate function so it can allocate stack space for the arguments
// to reflectcallmove. It does not follow the Go ABI; it expects its
// arguments in registers.
TEXT callRet<>(SB), NOSPLIT, $20-0
	NO_LOCAL_POINTERS
	MOV	A5, 4(X2)
	MOV	A1, 8(X2)
	MOV	A3, 12(X2)
	MOV	A2, 16(X2)
	MOV	ZERO, 20(X2)
	CALL	runtime·reflectcallmove(SB)
	RET

CALLFN(·call16, 16)
CALLFN(·call32, 32)
CALLFN(·call64, 64)
CALLFN(·call128, 128)
CALLFN(·call256, 256)
CALLFN(·call512, 512)
CALLFN(·call1024, 1024)
CALLFN(·call2048, 2048)
CALLFN(·call4096, 4096)
CALLFN(·call8192, 8192)
CALLFN(·call16384, 16384)
CALLFN(·call32768, 32768)
CALLFN(·call65536, 65536)
CALLFN(·call131072, 131072)
CALLFN(·call262144, 262144)
CALLFN(·call524288, 524288)
CALLFN(·call1048576, 1048576)
CALLFN(·call2097152, 2097152)
CALLFN(·call4194304, 4194304)
CALLFN(·call8388608, 8388608)
CALLFN(·call16777216, 16777216)
CALLFN(·call33554432, 33554432)
CALLFN(·call67108864, 67108864)
CALLFN(·call134217728, 134217728)
CALLFN(·call268435456, 268435456)
CALLFN(·call536870912, 536870912)
CALLFN(·call1073741824, 1073741824)

// func asmcgocall(fn, arg unsafe.Pointer) int32
// There is no cgo on this port; the runtime still refers to the symbol.
TEXT ·asmcgocall(SB),NOSPLIT,$0-12
	UNDEF

// func cgocallback(fn, frame unsafe.Pointer, ctxt uintptr)
TEXT ·cgocallback(SB),NOSPLIT,$0-12
	UNDEF

// The top-most function running on a goroutine
// returns to goexit+PCQuantum*2.
TEXT runtime·goexit(SB),NOSPLIT|NOFRAME|TOPFRAME,$0-0
	WORD	$0x00000013	// NOP
	JMP	runtime·goexit1(SB)	// does not return
	// traceback from goexit1 must hit code range of goexit
	WORD	$0x00000013	// NOP

// gcWriteBarrier informs the GC about heap pointer writes.
//
// gcWriteBarrier does NOT follow the Go ABI. It accepts the
// number of bytes of buffer needed in X24, and returns a pointer
// to the buffer space in X24.
// It clobbers X31 aka T6 (the linker temp register - REG_TMP).
// The act of CALLing gcWriteBarrier will clobber RA (LR).
// It does not clobber any other general-purpose registers.
TEXT gcWriteBarrier<>(SB),NOSPLIT,$104
	// Save the registers clobbered by the fast path.
	MOV	A0, 24*4(X2)
	MOV	A1, 25*4(X2)
retry:
	MOV	g_m(g), A0
	MOV	m_p(A0), A0
	MOV	(p_wbBuf+wbBuf_next)(A0), A1
	MOV	(p_wbBuf+wbBuf_end)(A0), T6 // T6 is linker temp register (REG_TMP)
	// Increment wbBuf.next position.
	ADD	X24, A1
	// Is the buffer full?
	BLTU	T6, A1, flush
	// Commit to the larger buffer.
	MOV	A1, (p_wbBuf+wbBuf_next)(A0)
	// Make the return value (the original next position)
	SUB	X24, A1, X24
	// Restore registers.
	MOV	24*4(X2), A0
	MOV	25*4(X2), A1
	RET

flush:
	// Save all general purpose registers since these could be
	// clobbered by wbBufFlush and were not saved by the caller.
	// X0 is zero, X1 is LR, X2 is SP, X3 is GP, X4 is TP.
	// X10 and X11 are already saved; X27 is g; X31 is tmp.
	MOV	X5, 1*4(X2)
	MOV	X6, 2*4(X2)
	MOV	X7, 3*4(X2)
	MOV	X8, 4*4(X2)
	MOV	X9, 5*4(X2)
	MOV	X12, 6*4(X2)
	MOV	X13, 7*4(X2)
	MOV	X14, 8*4(X2)
	MOV	X15, 9*4(X2)
	MOV	X16, 10*4(X2)
	MOV	X17, 11*4(X2)
	MOV	X18, 12*4(X2)
	MOV	X19, 13*4(X2)
	MOV	X20, 14*4(X2)
	MOV	X21, 15*4(X2)
	MOV	X22, 16*4(X2)
	MOV	X23, 17*4(X2)
	MOV	X24, 18*4(X2)
	MOV	X25, 19*4(X2)
	MOV	X26, 20*4(X2)
	MOV	X28, 21*4(X2)
	MOV	X29, 22*4(X2)
	MOV	X30, 23*4(X2)

	CALL	runtime·wbBufFlush(SB)

	MOV	1*4(X2), X5
	MOV	2*4(X2), X6
	MOV	3*4(X2), X7
	MOV	4*4(X2), X8
	MOV	5*4(X2), X9
	MOV	6*4(X2), X12
	MOV	7*4(X2), X13
	MOV	8*4(X2), X14
	MOV	9*4(X2), X15
	MOV	10*4(X2), X16
	MOV	11*4(X2), X17
	MOV	12*4(X2), X18
	MOV	13*4(X2), X19
	MOV	14*4(X2), X20
	MOV	15*4(X2), X21
	MOV	16*4(X2), X22
	MOV	17*4(X2), X23
	MOV	18*4(X2), X24
	MOV	19*4(X2), X25
	MOV	20*4(X2), X26
	MOV	21*4(X2), X28
	MOV	22*4(X2), X29
	MOV	23*4(X2), X30
	JMP	retry

TEXT runtime·gcWriteBarrier1<ABIInternal>(SB),NOSPLIT,$0
	MOV	$4, X24
	JMP	gcWriteBarrier<>(SB)
TEXT runtime·gcWriteBarrier2<ABIInternal>(SB),NOSPLIT,$0
	MOV	$8, X24
	JMP	gcWriteBarrier<>(SB)
TEXT runtime·gcWriteBarrier3<ABIInternal>(SB),NOSPLIT,$0
	MOV	$12, X24
	JMP	gcWriteBarrier<>(SB)
TEXT runtime·gcWriteBarrier4<ABIInternal>(SB),NOSPLIT,$0
	MOV	$16, X24
	JMP	gcWriteBarrier<>(SB)
TEXT runtime·gcWriteBarrier5<ABIInternal>(SB),NOSPLIT,$0
	MOV	$20, X24
	JMP	gcWriteBarrier<>(SB)
TEXT runtime·gcWriteBarrier6<ABIInternal>(SB),NOSPLIT,$0
	MOV	$24, X24
	JMP	gcWriteBarrier<>(SB)
TEXT runtime·gcWriteBarrier7<ABIInternal>(SB),NOSPLIT,$0
	MOV	$28, X24
	JMP	gcWriteBarrier<>(SB)
TEXT runtime·gcWriteBarrier8<ABIInternal>(SB),NOSPLIT,$0
	MOV	$32, X24
	JMP	gcWriteBarrier<>(SB)

// panicBounds and panicExtend are called from compiled code when a bounds
// check fails. The registers that may hold an index are X5 to X20; the
// PCDATA of the call says which ones.
TEXT runtime·panicBounds(SB),NOSPLIT,$72-0
	NO_LOCAL_POINTERS
	// Save all 16 int registers that could have an index in them.
	// They may be pointers, but if they are they are dead.
	MOV	X5, 12(X2)
	MOV	X6, 16(X2)
	MOV	X7, 20(X2)
	MOV	X8, 24(X2)
	MOV	X9, 28(X2)
	MOV	X10, 32(X2)
	MOV	X11, 36(X2)
	MOV	X12, 40(X2)
	MOV	X13, 44(X2)
	MOV	X14, 48(X2)
	MOV	X15, 52(X2)
	MOV	X16, 56(X2)
	MOV	X17, 60(X2)
	MOV	X18, 64(X2)
	MOV	X19, 68(X2)
	MOV	X20, 72(X2)
	MOV	RA, 4(X2)	// PC immediately after call to panicBounds
	ADD	$12, X2, T0	// pointer to save area
	MOV	T0, 8(X2)
	CALL	runtime·panicBounds32<ABIInternal>(SB)
	RET

TEXT runtime·panicExtend(SB),NOSPLIT,$72-0
	NO_LOCAL_POINTERS
	MOV	X5, 12(X2)
	MOV	X6, 16(X2)
	MOV	X7, 20(X2)
	MOV	X8, 24(X2)
	MOV	X9, 28(X2)
	MOV	X10, 32(X2)
	MOV	X11, 36(X2)
	MOV	X12, 40(X2)
	MOV	X13, 44(X2)
	MOV	X14, 48(X2)
	MOV	X15, 52(X2)
	MOV	X16, 56(X2)
	MOV	X17, 60(X2)
	MOV	X18, 64(X2)
	MOV	X19, 68(X2)
	MOV	X20, 72(X2)
	MOV	RA, 4(X2)	// PC immediately after call to panicExtend
	ADD	$12, X2, T0	// pointer to save area
	MOV	T0, 8(X2)
	CALL	runtime·panicBounds32X<ABIInternal>(SB)
	RET

// func switchToCrashStack0(fn func())
TEXT runtime·switchToCrashStack0(SB), NOSPLIT, $0-4
	MOV	fn+0(FP), CTXT			// context register
	MOV	g_m(g), X11			// curm

	// set g to gcrash
	MOV	$runtime·gcrash(SB), g	// g = &gcrash
	MOV	X11, g_m(g)			// g.m = curm
	MOV	g, m_g0(X11)			// curm.g0 = g

	// switch to crashstack
	MOV	(g_stack+stack_hi)(g), X11
	SUB	$(4*8), X11
	MOV	X11, X2

	// call target function
	MOV	0(CTXT), X10
	JALR	X1, X10

	// should never return
	CALL	runtime·abort(SB)
	UNDEF

// _mul64by32 and _div64by32 are not implemented: vlrt.go takes the slow
// path on this architecture.
TEXT runtime·_mul64by32(SB), NOSPLIT, $0
	UNDEF

TEXT runtime·_div64by32(SB), NOSPLIT, $0
	UNDEF
