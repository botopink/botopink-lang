/* botopink: a stand-in for <endian.h>, on the include path of Zig's
 * `@cImport` of wasm3.h only (`exposeHeaders` in ../build.zig) — never on the
 * C sources' compile.
 *
 * Zig's translate-c does not report itself as clang or as gcc >= 4.8, so
 * `source/wasm3_defs.h` falls through its byte-swap chain to
 * `#include <endian.h>`. glibc and mingw ship that header; macOS does not,
 * and the `@cImport` failed there ("'endian.h' not found"). Without
 * `__bswap_16` the header defines its portable inline swaps, which the
 * translated declarations never call on a little-endian target. The vendored
 * `source/` stays byte-identical to upstream. */
#ifndef BOTOPINK_WASM3_CIMPORT_ENDIAN_H
#define BOTOPINK_WASM3_CIMPORT_ENDIAN_H
#endif
