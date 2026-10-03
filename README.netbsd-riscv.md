# Go for NetBSD on 32-bit RISC-V (GOOS=netbsd GOARCH=riscv)

This branch adds an experimental port of Go 1.27.1 to 32-bit RISC-V
running NetBSD. It is not part of upstream Go and has not been proposed
there.

## Status

Tested only in QEMU (`qemu-system-riscv32 -M virt`, one CPU) on NetBSD 11
with a kernel patched to boot on RV32. Nothing has been run on hardware.

Working there:

- `go build std` succeeds.
- A program using fmt, encoding/json, crypto/sha256, os, time, 50
  goroutines with the garbage collector, asynchronous preemption,
  recovery from a nil dereference and TCP over loopback runs correctly.
- An HTTPS client and server in one process complete a TLS 1.3 exchange.

Not done or not tested:

- More than one CPU.
- cgo and external linking. Only static, internally linked binaries.
- Compressed instructions: RV32 code is not compressed, so binaries are
  larger than they need to be.
- Hardware floating point: all floating point is soft.
- Compiler intrinsics for atomics and bit operations: they are ordinary
  function calls.
- `go vet` does not know the architecture.
- The Go test suites have not been run.
- `golang.org/x/sys` has no netbsd/riscv files; programs that import
  `x/sys/unix` do not build.

## How it is built

The 32-bit port reuses the RISCV64 SSA op table and code generator. The
assembler builds each instruction sequence as for RV64 and rewrites it
for RV32 at the end. Only the lowering rules are separate
(`cmd/compile/internal/ssa/_gen/RISCV64rv32.rules`); 64-bit integers are
split by the generic dec64 rules and carries are computed with SLTU.

The runtime uses the stack-based ABI0 throughout. 64-bit atomics take a
spin lock, as on 32-bit MIPS. The syscall tables are copies of
netbsd/arm, whose 32-bit NetBSD layouts match; they have not been
regenerated from the riscv headers.

## Building

Build the toolchain on any host supported by Go, with Go 1.27.1 as the
bootstrap compiler:

    cd src
    GOROOT_BOOTSTRAP=$(go env GOROOT) ./make.bash

Then cross-compile:

    GOOS=netbsd GOARCH=riscv CGO_ENABLED=0 go build ./...

Run `go clean -cache` after rebuilding the compiler.
