# run_without_main

`botopink run` of a package whose entry module declares no `fn main` refuses before running, located at the entry
module and naming that it declares no `fn main` (decision 517). The message is the same on commonJS, erlang, beam and
wasm, under the wasi (wasmtime) and the browser (node) hosts.
