# lowering_call_marked

The reference text this cell shows (from `conformance/docs.md`, § `opaque` types):

> The compiler's own lowering is admitted to build an `opaque` type or call a method without
> `pub` by a mark on the call node it writes, never by where the call stands. A name starting
> `__bp_` is the compiler's: a hand-written call of one, as of the lowering's
> `__bp_load_module`, is `reserved-name`, at the call.
