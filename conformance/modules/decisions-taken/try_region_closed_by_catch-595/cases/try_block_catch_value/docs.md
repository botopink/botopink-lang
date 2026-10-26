# try_block_catch_value

The reference text this cell shows (from `conformance/docs.md`, § Results):

> **`try` opens a region; `catch` closes it** and handles the failure of every `try` written in it
> (decision 595). A `try` hands its failure to the nearest region holding it — a `try { … } catch …`,
> else the function, which then needs a `Result` in its return. The region is the block `try { … }`
> when it is written, else the whole expression left of the `catch`: `try e catch h` is
> `try { e } catch h`, and `(try a) + (try b) catch 0` sends both failures to the one `catch`. The
> region is an expression: its value is its last expression written without `;`, and the handler
> answers the same type. The handler is an expression (the fallback, `catch 0`), a `throw`
> (`catch throw ParseFailed` — the failure becomes the function's), a block whose value is the
> fallback (`catch { log.warn("…"); 0 }`), or a block with a binder, `catch { e -> … }` — `e` is the
> region's error, a `case` arm's binder typed by the region and never a lambda's parameter, so a
> `return` or a `throw` in the block is the enclosing function's:
