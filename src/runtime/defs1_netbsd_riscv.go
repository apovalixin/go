// Structures of NetBSD on 32-bit RISC-V, written by hand from the
// system headers. 64-bit members are aligned to 8 bytes in C but to 4 in
// Go, so the padding is explicit.

package runtime

const (
	_EINTR  = 0x4
	_EFAULT = 0xe
	_EAGAIN = 0x23

	_O_WRONLY   = 0x1
	_O_NONBLOCK = 0x4
	_O_CREAT    = 0x200
	_O_TRUNC    = 0x400
	_O_CLOEXEC  = 0x400000

	_PROT_NONE  = 0x0
	_PROT_READ  = 0x1
	_PROT_WRITE = 0x2
	_PROT_EXEC  = 0x4

	_MAP_ANON    = 0x1000
	_MAP_PRIVATE = 0x2
	_MAP_FIXED   = 0x10

	_MADV_DONTNEED = 0x4
	_MADV_FREE     = 0x6

	_SA_SIGINFO = 0x40
	_SA_RESTART = 0x2
	_SA_ONSTACK = 0x1

	_SIGHUP    = 0x1
	_SIGINT    = 0x2
	_SIGQUIT   = 0x3
	_SIGILL    = 0x4
	_SIGTRAP   = 0x5
	_SIGABRT   = 0x6
	_SIGEMT    = 0x7
	_SIGFPE    = 0x8
	_SIGKILL   = 0x9
	_SIGBUS    = 0xa
	_SIGSEGV   = 0xb
	_SIGSYS    = 0xc
	_SIGPIPE   = 0xd
	_SIGALRM   = 0xe
	_SIGTERM   = 0xf
	_SIGURG    = 0x10
	_SIGSTOP   = 0x11
	_SIGTSTP   = 0x12
	_SIGCONT   = 0x13
	_SIGCHLD   = 0x14
	_SIGTTIN   = 0x15
	_SIGTTOU   = 0x16
	_SIGIO     = 0x17
	_SIGXCPU   = 0x18
	_SIGXFSZ   = 0x19
	_SIGVTALRM = 0x1a
	_SIGPROF   = 0x1b
	_SIGWINCH  = 0x1c
	_SIGINFO   = 0x1d
	_SIGUSR1   = 0x1e
	_SIGUSR2   = 0x1f

	_FPE_INTDIV = 0x1
	_FPE_INTOVF = 0x2
	_FPE_FLTDIV = 0x3
	_FPE_FLTOVF = 0x4
	_FPE_FLTUND = 0x5
	_FPE_FLTRES = 0x6
	_FPE_FLTINV = 0x7
	_FPE_FLTSUB = 0x8

	_BUS_ADRALN = 0x1
	_BUS_ADRERR = 0x2
	_BUS_OBJERR = 0x3

	_SEGV_MAPERR = 0x1
	_SEGV_ACCERR = 0x2

	_ITIMER_REAL    = 0x0
	_ITIMER_VIRTUAL = 0x1
	_ITIMER_PROF    = 0x2

	_EV_ADD       = 0x1
	_EV_DELETE    = 0x2
	_EV_ENABLE    = 0x4
	_EV_DISABLE   = 0x8
	_EV_CLEAR     = 0x20
	_EV_RECEIPT   = 0
	_EV_ERROR     = 0x4000
	_EV_EOF       = 0x8000
	_EVFILT_READ  = 0x0
	_EVFILT_WRITE = 0x1
	_EVFILT_USER  = 0x8

	_NOTE_TRIGGER = 0x1000000
)

type sigset struct {
	__bits [4]uint32
}

type siginfo struct {
	_signo   int32
	_code    int32
	_errno   int32
	_reason  uintptr
	_reasonx [16]byte
}

type stackt struct {
	ss_sp    uintptr
	ss_size  uintptr
	ss_flags int32
}

type timespec struct {
	tv_sec  int64
	tv_nsec int32
	_       [4]byte
}

//go:nosplit
func (ts *timespec) setNsec(ns int64) {
	ts.tv_sec = int64(ns / 1e9)
	ts.tv_nsec = int32(ns % 1e9)
}

type timeval struct {
	tv_sec  int64
	tv_usec int32
	_       [4]byte
}

func (tv *timeval) set_usec(x int32) {
	tv.tv_usec = x
}

type itimerval struct {
	it_interval timeval
	it_value    timeval
}

type mcontextt struct {
	__gregs [32]uint32
	__fregs [33 * 8]byte // 32 registers and the FCSR, 8 bytes each
	__spare [7]uint32
	_       [4]byte // the structure is aligned to 8 bytes
}

type ucontextt struct {
	uc_flags    uint32
	uc_link     *ucontextt
	uc_sigmask  sigset
	uc_stack    stackt
	_           [4]byte
	uc_mcontext mcontextt
}

type keventt struct {
	ident  uint32
	filter uint32
	flags  uint32
	fflags uint32
	data   int64
	udata  *byte
	_      [4]byte
}

// Indexes into mcontextt.__gregs: X1 to X31, then the PC.
const (
	_REG_X1  = 0
	_REG_X2  = 1
	_REG_X3  = 2
	_REG_X4  = 3
	_REG_X5  = 4
	_REG_X6  = 5
	_REG_X7  = 6
	_REG_X8  = 7
	_REG_X9  = 8
	_REG_X10 = 9
	_REG_X11 = 10
	_REG_X12 = 11
	_REG_X13 = 12
	_REG_X14 = 13
	_REG_X15 = 14
	_REG_X16 = 15
	_REG_X17 = 16
	_REG_X18 = 17
	_REG_X19 = 18
	_REG_X20 = 19
	_REG_X21 = 20
	_REG_X22 = 21
	_REG_X23 = 22
	_REG_X24 = 23
	_REG_X25 = 24
	_REG_X26 = 25
	_REG_X27 = 26
	_REG_X28 = 27
	_REG_X29 = 28
	_REG_X30 = 29
	_REG_X31 = 30
	_REG_PC  = 31
)
