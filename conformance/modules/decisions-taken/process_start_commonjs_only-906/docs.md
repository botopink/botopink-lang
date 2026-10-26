# Decision 906 — `io.process.start(cmd, args, cwd: ?string, env: string[])`: `env` is `NAME=value` entries added to the parent's environment, no shell, the first `=` ending the name, an entry with no `=` or an empty name answered `Error(Other(message))` naming it; the function exists on commonJS alone — a call reaching it on erlang, beam or wasm is refused at the call, `std-unsupported-on-target` (518 (4), 503), the module importable and `run` / `spawn` unchanged; amends B-161's built answer.

[cells/process_start_commonjs_only/src/main.bp](cells/process_start_commonjs_only/src/main.bp)
