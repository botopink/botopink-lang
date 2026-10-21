# init_at_call_body_block

The reference text this cell shows (from `conformance/docs.md`, § A top-level `comptime { … }`):

> A `comptime { … }` written in a function body that calls one runs at build and writes the executor's body where the block is, inside the enclosing function, run each time it runs (decision 808 (4)).

<!-- example: modules/decisions-taken/comptime_init_at_call_site-808/run/src/cases/init_at_call_body_block -->
