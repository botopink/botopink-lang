# io_fs_same_on_every_target

The reference text this cell shows (from `conformance/docs.md`, § The file system, `io.fs`):

> `io.fs` is the same on commonJS, erlang, beam and wasm (decision 992): on wasm the runner preopens the root and the
> working directory (`wasmtime run --dir`, no flag of the user's), a relative path is read against the working directory
> and an absolute one as it is, and the answers and the errors are the other targets'.
