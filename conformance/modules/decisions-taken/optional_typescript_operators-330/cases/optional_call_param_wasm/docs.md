# optional_call_param_wasm

The reference text this cell shows (from `conformance/docs.md`, § Optionals):

> `f?.(args)` over a function answering a plain `T` is a `?T`, a present `0`
> included.

The call `f?.(3) ?? -1` over a parameter `f: ?fn(i32) -> i32` answers `4` when a
function is held and `-1` on `null`, both in a plain function and in a lambda whose
parameter another function types, on every target (wasm included).
