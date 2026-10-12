# panic_library_message

### A library's `@panic` message reaches stderr unchanged on every target

A library aborts with a message it built: quotes, a concatenated name, a non-ASCII
dash. The program's stderr carries that text, whole and unchanged, on commonJS,
erlang, beam and wasm; what surrounds it (a stack trace, a trap notice) is the
runtime's own. The exit status is non-zero and is not pinned.
