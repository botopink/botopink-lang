# std_asserts_throws_over_attempt

The reference text this cell shows (from `conformance/docs.md`, § Results):

> `testing.asserts`' `throws(body)` and `throwsWith(body, needle)` run the body
> under `attempt`, generic over what the body answers (decision 493): each is
> `Error` when the body completes, and `throwsWith` also when the caught
> `Failure`'s message does not contain `needle` — a host raise's message is the
> host's text, the erlang reason by `~tp` without its class.
