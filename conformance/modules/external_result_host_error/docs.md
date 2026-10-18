# external_result_host_error

The reference text this cell shows (from `conformance/docs.md`, § Host bindings):

> A host call that can fail answers a `Result` only when its binding writes
> `result: true`: the return is then `Result<T, HostError>` (or a `Task` of
> one), and every way the host fails becomes `Error(HostError(…))`.
>
> `HostError(message, kind, name, detail)`: `kind` is always `"host"`; `name` is
> the same on every target — a JavaScript `Error` and an erlang `error` raise, or an
> erlang host answering `{error, R}`, are `HostErrorName.Error`, any other thrown
> value and an erlang `throw` are `HostErrorName.Throw`, an erlang `exit` is
> `HostErrorName.Exit`; `message` is the host's text (`e.message`, else
> `String(e)`; the erlang reason by `~tp`); `detail` is the host's stack, which a
> backend may leave empty. An erlang host's `{ok, V}` or plain value is `Ok(V)`.
