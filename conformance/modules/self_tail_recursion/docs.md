# self_tail_recursion

The reference text this cell shows (from `conformance/docs.md`, § Recursion):

> A function may call itself. When the call is the **whole** of a `return` — a
> *tail* call — it costs no stack: commonJS rewrites it into a loop, and erlang
> and beam run on VMs that drop the frame. The depth of a tail-recursive walk is
> bounded by the data, not by the runtime.
