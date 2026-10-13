# external_result_erlang_exit

The reference text this cell shows (from `conformance/docs.md`, § Host bindings):

> `HostError(message, kind, name, detail)`: `kind` is always `"host"`; `name` is
> the same on every target — a JavaScript `Error` and an erlang `error` raise, or an
> erlang host answering `{error, R}`, are `HostErrorName.Error`, any other thrown
> value and an erlang `throw` are `HostErrorName.Throw`, an erlang `exit` is
> `HostErrorName.Exit`; `message` is the host's text (`e.message`, else
> `String(e)`; the erlang reason by `~tp`); `detail` is the host's stack, which a
> backend may leave empty. An erlang host's `{ok, V}` or plain value is `Ok(V)`.
>
> An erlang host names the class of each raise, and `exit` is the erlang host's
> alone:
