# std_failure_attempt_crash

The reference text this cell shows (from `conformance/docs.md`, § Results):

> A host raise answers `host` where a host raises — commonJS, erlang and beam;
> wasm never imitates one (527 (0)). On erlang and beam its message is the reason
> printed by `~tp` without the stack, whatever the class (527 (4)), and only a binding
> declared outside std without `result: true` — a library's or the program's — marks its
> raise `host` (546): std's bindings are audited one by one (495), so a raise of one that
> the audit did not list is a `crash`, as is any raise nothing marked.
