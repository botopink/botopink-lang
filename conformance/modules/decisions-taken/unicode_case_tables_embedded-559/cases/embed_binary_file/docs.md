# embed_binary_file

The reference text this cell shows (from `conformance/docs.md`, § `@embed` and `Asset`):

> The artifact carries the bytes on every target — an Erlang binary, a JS
> `Uint8Array`, a wasm data segment — and the program never reads the file when
> it runs, so a file that is not text embeds byte for byte.
