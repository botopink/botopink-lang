# modules/atomvm

Vendored snapshot of [AtomVM](https://github.com/atomvm/AtomVM) — a lightweight Erlang VM that executes BEAM bytecode. Packaged as a self-contained Zig module; see [`./AGENTS.md`](AGENTS.md) for the integration contract.

## Pinned version

- **Tag**: `v0.6.5`
- **Commit**: `(shallow clone — see upstream)`
- **Upstream**: https://github.com/atomvm/AtomVM
- **License**: Apache-2.0 OR LGPL-2.1-or-later (see `LICENSE`)

## What's vendored

Only `src/libAtomVM/` (the core VM) and `src/platforms/generic_unix/lib/`
(the Linux/macOS/FreeBSD sys layer). The following upstream content is
intentionally excluded — it ships embedded platform ports, demos, tests and
CMake fixtures we don't need:

- `src/platforms/emscripten/` (web target)
- `src/platforms/esp32/` (ESP32 microcontroller)
- `src/platforms/rp2040/` (Raspberry Pi Pico)
- `src/platforms/stm32/` (STM32 microcontroller)
- `libs/` (Erlang stdlib — compiled into BEAM at build time)
- `examples/` (upstream example programs)
- `tests/` (upstream test suite)
- `tools/` (packbeam, uf2tool)
- `doc/` (upstream docs)
- `.github/` (upstream CI)
- `CMakeLists.txt`, `CMakeModules/`, `version.cmake` (replaced by botopink's `build.zig`)
- `code-queries/`, `.reuse/`, `.clang-format*`

## How we build it

The module's own [`build.zig`](build.zig) exposes `link(b, compile)` +
`exposeHeaders(b, mod)` to the root workspace `build.zig`, which links these
C sources into every binary that imports `compiler-core`:

**Core (28 `.c` files):**
```
atom.c atomshashtable.c atom_table.c avmpack.c bif.c bitstring.c context.c
debug.c defaultatoms.c dictionary.c externalterm.c globalcontext.c iff.c
interop.c mailbox.c memory.c module.c nifs.c port.c posix_nifs.c
refc_binary.c resources.c scheduler.c stacktrace.c term.c timer_list.c
unicode.c valueshashtable.c
```

**Platform (10 `.c` files):**
```
mapped_file.c otp_socket_platform.c platform_defaultatoms.c platform_nifs.c
smp.c socket_driver.c sys.c inet.c otp_net.c otp_socket.c
```

Compile flags: `-std=c11 -Os -DAVM_NO_SMP`. SMP is disabled — comptime
evaluation is single-threaded. mbedTLS is not linked, so crypto/SSL NIFs
are excluded at compile time via `ATOMVM_HAS_MBEDTLS` guards.

## Upgrading

1. Download the new upstream tag's `src/libAtomVM/` and
   `src/platforms/generic_unix/lib/` trees.
2. Replace `modules/atomvm/source/libAtomVM/` and
   `modules/atomvm/source/platforms/generic_unix/lib/` with them
   (byte-for-byte).
3. If the file list changed, update the `atomvm_core_srcs` and
   `atomvm_platform_srcs` arrays in `build.zig`.
4. Re-generate hash files: `gperf -t bifs.gperf > bifs_hash.h` and
   `gperf -t nifs.gperf > nifs_hash.h` inside `source/libAtomVM/`.
5. Update `avm_version.h` version string and `atomvm_version.h` defines.
6. Update this file's pinned version + commit hash.
7. `zig build test` on Linux + macOS.
