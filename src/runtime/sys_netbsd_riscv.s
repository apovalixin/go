// Copyright 2026 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//
// System calls and other sys.stuff for riscv, NetBSD
//

#include "go_asm.h"
#include "go_tls.h"
#include "textflag.h"

#define CLOCK_REALTIME		0
#define CLOCK_MONOTONIC		3

#define SYS_exit			1
#define SYS_read			3
#define SYS_write			4
#define SYS_open			5
#define SYS_close			6
#define SYS_getpid			20
#define SYS_kill			37
#define SYS_munmap			73
#define SYS_madvise			75
#define SYS_fcntl			92
#define SYS_mmap			197
#define SYS___sysctl			202
#define SYS___sigaltstack14		281
#define SYS___sigprocmask14		293
#define SYS_issetugid			305
#define SYS_getcontext			307
#define SYS_setcontext			308
#define SYS__lwp_create			309
#define SYS__lwp_exit			310
#define SYS__lwp_self			311
#define SYS__lwp_kill			318
#define SYS__lwp_unpark			321
#define SYS___sigaction_sigtramp	340
#define SYS_kqueue			344
#define SYS_sched_yield			350
#define SYS___setitimer50		425
#define SYS___clock_gettime50		427
#define SYS___nanosleep50		430
#define SYS___kevent50			435
#define SYS_pipe2			453
#define SYS____lwp_park60		478

// The system call number goes in T6. The kernel returns to the instruction
// after ECALL when the call failed, with the error number in A0, and two
// instructions further when it succeeded. Every ECALL below is therefore
// followed by exactly two four-byte instructions that make up the error
// path; NOP4 fills the slots that have nothing to do.
#define SYSCALL(n)	\
	MOV	$n, T6;	\
	ECALL
#define NOP4	WORD	$0x00000013
// The instructions in the two slots are spelled as words so that the
// assembler cannot pick a two-byte encoding for them.
#define NEG_A0	WORD	$0x40a00533	// sub a0, zero, a0
#define LI_A0_M1	WORD	$0xfff00513	// addi a0, zero, -1
#define CRASH	WORD	$0	// illegal instruction

// func lwp_create(ctxt unsafe.Pointer, flags, lwpid uintptr) int32
TEXT runtime·lwp_create(SB),NOSPLIT,$0-16
	MOV	ctxt+0(FP), A0
	MOV	flags+4(FP), A1
	MOV	lwpid+8(FP), A2
	SYSCALL(SYS__lwp_create)
	NEG_A0
	NOP4
	MOVW	A0, ret+12(FP)
	RET

// A new thread starts here with A0 = m, A1 = g and A2 = fn,
// see lwp_mcontext_init.
TEXT runtime·lwp_tramp(SB),NOSPLIT|NOFRAME,$0
	BEQZ	A1, nog
	BEQZ	A2, nog
	MOV	A0, g_m(A1)
	MOV	A1, g
nog:
	JALR	RA, A2
	CRASH	// not reached

TEXT ·netbsdMstart(SB),NOSPLIT|TOPFRAME,$0
	CALL	·netbsdMstart0(SB)
	RET // not reached

TEXT runtime·osyield(SB),NOSPLIT,$0
	SYSCALL(SYS_sched_yield)
	NOP4
	NOP4
	RET

// func lwp_park(clockid, flags int32, ts *timespec, unpark int32, hint, unparkhint unsafe.Pointer) int32
TEXT runtime·lwp_park(SB),NOSPLIT,$0-28
	MOVW	clockid+0(FP), A0
	MOVW	flags+4(FP), A1
	MOV	ts+8(FP), A2
	MOVW	unpark+12(FP), A3
	MOV	hint+16(FP), A4
	MOV	unparkhint+20(FP), A5
	SYSCALL(SYS____lwp_park60)
	NOP4	// the error number is the result
	NOP4
	MOVW	A0, ret+24(FP)
	RET

// func lwp_unpark(lwp int32, hint unsafe.Pointer) int32
TEXT runtime·lwp_unpark(SB),NOSPLIT,$0-12
	MOVW	lwp+0(FP), A0
	MOV	hint+4(FP), A1
	SYSCALL(SYS__lwp_unpark)
	NOP4
	NOP4
	MOVW	A0, ret+8(FP)
	RET

// func lwp_self() int32
TEXT runtime·lwp_self(SB),NOSPLIT,$0-4
	SYSCALL(SYS__lwp_self)
	NOP4
	NOP4
	MOVW	A0, ret+0(FP)
	RET

// Exit the entire program (like C exit)
TEXT runtime·exit(SB),NOSPLIT,$0-4
	MOVW	code+0(FP), A0
	SYSCALL(SYS_exit)
	CRASH
	CRASH
	CRASH

// func exitThread(wait *atomic.Uint32)
TEXT runtime·exitThread(SB),NOSPLIT,$0-4
	MOV	wait+0(FP), A0
	// We're done using the stack.
	AMOSWAPW ZERO, (A0), ZERO
	SYSCALL(SYS__lwp_exit)
	CRASH
	CRASH
	JMP	0(PC)

// func open(name *byte, mode, perm int32) int32
TEXT runtime·open(SB),NOSPLIT,$0-16
	MOV	name+0(FP), A0
	MOVW	mode+4(FP), A1
	MOVW	perm+8(FP), A2
	SYSCALL(SYS_open)
	LI_A0_M1
	NOP4
	MOVW	A0, ret+12(FP)
	RET

// func closefd(fd int32) int32
TEXT runtime·closefd(SB),NOSPLIT,$0-8
	MOVW	fd+0(FP), A0
	SYSCALL(SYS_close)
	LI_A0_M1
	NOP4
	MOVW	A0, ret+4(FP)
	RET

// func read(fd int32, p unsafe.Pointer, n int32) int32
TEXT runtime·read(SB),NOSPLIT,$0-16
	MOVW	fd+0(FP), A0
	MOV	p+4(FP), A1
	MOVW	n+8(FP), A2
	SYSCALL(SYS_read)
	NEG_A0
	NOP4
	MOVW	A0, ret+12(FP)
	RET

// func pipe2(flags int32) (r, w int32, errno int32)
TEXT runtime·pipe2(SB),NOSPLIT,$0-16
	MOV	$r+4(FP), A0
	MOVW	flags+0(FP), A1
	SYSCALL(SYS_pipe2)
	NEG_A0
	NOP4
	MOVW	A0, errno+12(FP)
	RET

// func write1(fd uintptr, p unsafe.Pointer, n int32) int32
TEXT runtime·write1(SB),NOSPLIT,$0-16
	MOV	fd+0(FP), A0
	MOV	p+4(FP), A1
	MOVW	n+8(FP), A2
	SYSCALL(SYS_write)
	NEG_A0
	NOP4
	MOVW	A0, ret+12(FP)
	RET

// func usleep(usec uint32)
TEXT runtime·usleep(SB),NOSPLIT,$16-4
	MOVW	usec+0(FP), A2
	MOV	$1000000, A3
	DIVU	A3, A2, A4	// seconds
	REMU	A3, A2, A5	// microseconds
	MOV	$1000, A3
	MUL	A3, A5		// nanoseconds
	MOVW	A4, 4(X2)	// tv_sec, low word
	MOVW	ZERO, 8(X2)	// tv_sec, high word
	MOVW	A5, 12(X2)	// tv_nsec
	ADD	$4, X2, A0	// arg 1 - rqtp
	MOV	ZERO, A1	// arg 2 - rmtp
	SYSCALL(SYS___nanosleep50)
	NOP4
	NOP4
	RET

// func lwp_kill(tid int32, sig int)
TEXT runtime·lwp_kill(SB),NOSPLIT,$0-8
	MOVW	tid+0(FP), A0
	MOV	sig+4(FP), A1
	SYSCALL(SYS__lwp_kill)
	NOP4
	NOP4
	RET

// func raiseproc(sig uint32)
TEXT runtime·raiseproc(SB),NOSPLIT,$0-4
	SYSCALL(SYS_getpid)
	NOP4
	NOP4
	// arg 1 - pid, already in A0
	MOVW	sig+0(FP), A1
	SYSCALL(SYS_kill)
	NOP4
	NOP4
	RET

// func setitimer(mode int32, new, old *itimerval)
TEXT runtime·setitimer(SB),NOSPLIT,$0-12
	MOVW	mode+0(FP), A0
	MOV	new+4(FP), A1
	MOV	old+8(FP), A2
	SYSCALL(SYS___setitimer50)
	NOP4
	NOP4
	RET

// func walltime() (sec int64, nsec int32)
TEXT runtime·walltime(SB),NOSPLIT,$16-12
	MOV	$CLOCK_REALTIME, A0
	ADD	$4, X2, A1
	SYSCALL(SYS___clock_gettime50)
	NOP4
	NOP4
	MOVW	4(X2), A0	// sec, low word
	MOVW	8(X2), A1	// sec, high word
	MOVW	12(X2), A2	// nsec
	MOVW	A0, sec_lo+0(FP)
	MOVW	A1, sec_hi+4(FP)
	MOVW	A2, nsec+8(FP)
	RET

// func nanotime1() int64
TEXT runtime·nanotime1(SB),NOSPLIT,$16-8
	MOV	$CLOCK_MONOTONIC, A0
	ADD	$4, X2, A1
	SYSCALL(SYS___clock_gettime50)
	NOP4
	NOP4
	MOVW	4(X2), A0	// sec, low word
	MOVW	8(X2), A1	// sec, high word
	MOVW	12(X2), A2	// nsec
	// sec * 1e9 + nsec in 64 bits: A4 is the low word, A5 the high word.
	MOV	$1000000000, A3
	MUL	A3, A0, A4
	MULHU	A3, A0, A5
	MUL	A3, A1, A6
	ADD	A6, A5
	ADD	A2, A4, A6
	SLTU	A4, A6, A7	// carry
	ADD	A7, A5
	MOVW	A6, ret_lo+0(FP)
	MOVW	A5, ret_hi+4(FP)
	RET

// func getcontext(ctxt unsafe.Pointer)
TEXT runtime·getcontext(SB),NOSPLIT,$0-4
	MOV	ctxt+0(FP), A0
	SYSCALL(SYS_getcontext)
	CRASH
	NOP4
	RET

// func sigprocmask(how int32, new, old *sigset)
TEXT runtime·sigprocmask(SB),NOSPLIT,$0-12
	MOVW	how+0(FP), A0
	MOV	new+4(FP), A1
	MOV	old+8(FP), A2
	SYSCALL(SYS___sigprocmask14)
	CRASH
	NOP4
	RET

// The kernel returns from a signal handler to this trampoline with the
// stack pointer at the signal frame: a siginfo (128 bytes) followed by the
// ucontext to resume.
TEXT sigreturn_tramp<>(SB),NOSPLIT|NOFRAME,$0
	ADD	$128, X2, A0
	SYSCALL(SYS_setcontext)
	CRASH
	CRASH
	CRASH

// func sigaction(sig uint32, new, old *sigactiont)
TEXT runtime·sigaction(SB),NOSPLIT,$0-12
	MOVW	sig+0(FP), A0		// arg 1 - signum
	MOV	new+4(FP), A1		// arg 2 - nsa
	MOV	old+8(FP), A2		// arg 3 - osa
	MOV	$sigreturn_tramp<>(SB), A3	// arg 4 - tramp
	MOV	$2, A4			// arg 5 - vers
	SYSCALL(SYS___sigaction_sigtramp)
	CRASH
	NOP4
	RET

// func sigfwd(fn uintptr, sig uint32, info *siginfo, ctx unsafe.Pointer)
TEXT runtime·sigfwd(SB),NOSPLIT,$0-16
	MOVW	sig+4(FP), A0
	MOV	info+8(FP), A1
	MOV	ctx+12(FP), A2
	MOV	fn+0(FP), T1
	JALR	RA, T1
	RET

// The kernel calls the handler with A0 = signal number, A1 = siginfo and
// A2 = ucontext. All the code is Go, so g is valid in its register.
TEXT runtime·sigtramp(SB),NOSPLIT|TOPFRAME,$12
	MOVW	A0, 4(X2)
	MOV	A1, 8(X2)
	MOV	A2, 12(X2)
	CALL	runtime·sigtrampgo(SB)
	RET

// func mmap(addr unsafe.Pointer, n uintptr, prot, flags, fd int32, off uint32) (p unsafe.Pointer, err int)
TEXT runtime·mmap(SB),NOSPLIT,$0-32
	MOV	addr+0(FP), A0		// arg 1 - addr
	MOV	n+4(FP), A1		// arg 2 - len
	MOVW	prot+8(FP), A2		// arg 3 - prot
	MOVW	flags+12(FP), A3	// arg 4 - flags
	MOVW	fd+16(FP), A4		// arg 5 - fd
	MOV	ZERO, A5		// arg 6 - pad
	MOVW	off+20(FP), A6		// arg 7 - offset, low word
	MOV	ZERO, A7		// arg 7 - offset, high word
	SYSCALL(SYS_mmap)
	JMP	fail
	NOP4
	MOV	A0, p+24(FP)
	MOV	ZERO, err+28(FP)
	RET
fail:
	MOV	ZERO, p+24(FP)
	MOV	A0, err+28(FP)
	RET

// func munmap(addr unsafe.Pointer, n uintptr)
TEXT runtime·munmap(SB),NOSPLIT,$0-8
	MOV	addr+0(FP), A0
	MOV	n+4(FP), A1
	SYSCALL(SYS_munmap)
	CRASH
	NOP4
	RET

// func madvise(addr unsafe.Pointer, n uintptr, flags int32) int32
TEXT runtime·madvise(SB),NOSPLIT,$0-16
	MOV	addr+0(FP), A0
	MOV	n+4(FP), A1
	MOVW	flags+8(FP), A2
	SYSCALL(SYS_madvise)
	LI_A0_M1
	NOP4
	MOVW	A0, ret+12(FP)
	RET

// func sigaltstack(new, old *stackt)
TEXT runtime·sigaltstack(SB),NOSPLIT,$0-8
	MOV	new+0(FP), A0
	MOV	old+4(FP), A1
	SYSCALL(SYS___sigaltstack14)
	CRASH
	NOP4
	RET

// func sysctl(mib *uint32, miblen uint32, out *byte, size *uintptr, dst *byte, ndst uintptr) int32
TEXT runtime·sysctl(SB),NOSPLIT,$0-28
	MOV	mib+0(FP), A0
	MOVW	miblen+4(FP), A1
	MOV	out+8(FP), A2
	MOV	size+12(FP), A3
	MOV	dst+16(FP), A4
	MOV	ndst+20(FP), A5
	SYSCALL(SYS___sysctl)
	NEG_A0
	NOP4
	MOVW	A0, ret+24(FP)
	RET

// func kqueue() int32
TEXT runtime·kqueue(SB),NOSPLIT,$0-4
	SYSCALL(SYS_kqueue)
	NEG_A0
	NOP4
	MOVW	A0, ret+0(FP)
	RET

// func kevent(kq int32, ch *keventt, nch int32, ev *keventt, nev int32, ts *timespec) int32
TEXT runtime·kevent(SB),NOSPLIT,$0-28
	MOVW	kq+0(FP), A0
	MOV	ch+4(FP), A1
	MOVW	nch+8(FP), A2
	MOV	ev+12(FP), A3
	MOVW	nev+16(FP), A4
	MOV	ts+20(FP), A5
	SYSCALL(SYS___kevent50)
	NEG_A0
	NOP4
	MOVW	A0, ret+24(FP)
	RET

// func fcntl(fd, cmd, arg int32) (ret int32, errno int32)
TEXT runtime·fcntl(SB),NOSPLIT,$0-20
	MOVW	fd+0(FP), A0
	MOVW	cmd+4(FP), A1
	MOVW	arg+8(FP), A2
	SYSCALL(SYS_fcntl)
	JMP	fail
	NOP4
	MOVW	A0, ret+12(FP)
	MOVW	ZERO, errno+16(FP)
	RET
fail:
	MOV	$-1, A1
	MOVW	A1, ret+12(FP)
	MOVW	A0, errno+16(FP)
	RET

// func issetugid() int32
TEXT runtime·issetugid(SB),NOSPLIT,$0-4
	SYSCALL(SYS_issetugid)
	NOP4
	NOP4
	MOVW	A0, ret+0(FP)
	RET
