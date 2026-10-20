# init_at_call_order

The reference text this cell shows (from `conformance/docs.md`, § A top-level `comptime { … }`):

> A run-time call of a function whose every parameter is `comptime` — in `main`, in any run-time body, of this module or another — is expanded at build as every call is (decision 808 (2)): its build-only lines run at build, and the `compiler.init({ -> … })` it reaches writes the executor's body at the call, run when that line runs; under an `if` it runs only when the branch does.

<!-- example: modules/decisions-taken/comptime_init_at_call_site-808/run/src/cases/init_at_call_order -->
