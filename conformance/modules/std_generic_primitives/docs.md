# std_generic_primitives

The reference text this cell shows (from `conformance/docs.md`, § Imports):

> | Where | What | Answers |
> |---|---|---|
> | a `string` | `s.parseInt()` | `Result<i64, string>` — an optional `+` / `-` and digits, the whole string; anything else (`"4 2"`, `"42x"`, `"0x2A"`, `""`) is an `Error` naming the input, and so is an integer past the `i64` range, −2^63 … 2^63 − 1 |
> | a `string` | `s.parseFloat()` | `Result<f64, string>` — a sign, digits, an optional `.` with digits on both sides, an optional exponent; `.5`, `1.`, `NaN`, `Infinity` are an `Error`, an overflow too; the nearest `f64`, the one `json.decode` answers |
> | a `string` | `s.indexOf(x)`, `s.lastIndexOf(x)` | an index `s.at` and `s.slice` take, on every target (`-1` when absent) |
> | `json.Json` | `v.kindName()`, `v.isObject()`, `v.members()`, `v.field(key)`, `v.str()`, `v.items()` | the readers of a decoded value: `members` and `items` are `[]`, `str` is `""` and `field` is `null` for a value of another kind — none throws |
> | `hash` | `pbkdf2Sha256(password, salt, iterations, length)` | `length` bytes of PBKDF2-HMAC-SHA256 as unpadded base64url; the password and the salt are text |
> | `io.clock` | `parseDuration(text)` | `Result<i64, string>` — the milliseconds of digits and one unit, `ms` `s` `m` `h` `d` (`"30s"` is `30000`); `"30"`, `"1.5s"`, `"30 s"`, `"30S"` are an `Error` |
> | `async` | `RetryPolicy(maxAttempts, initialMillis, multiplier, maxMillis)`, `nextDelay(policy, attempt)`, `retry(policy, work)` | `nextDelay` is `?i64` — `initialMillis × multiplier^(attempt − 1)`, never above `maxMillis`, `null` past `maxAttempts`; `retry` runs a `fn() -> Async<Result<T, E>>` until it answers `Ok` and answers the last `Error` when every attempt failed |
> | `io.fs` | `walk(root)`, `glob(pattern, root)`, `removeTree(path)` | relative, `/`-separated, sorted paths, the same for every spelling of the root; a dangling link under `walk` is an `Error` naming it; `glob`'s `*` and `**` do not match a name starting with `.` unless the segment writes the dot, and do not descend through a link to a directory |
