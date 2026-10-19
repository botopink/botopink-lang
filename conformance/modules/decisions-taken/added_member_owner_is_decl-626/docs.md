# Decision 626 — (a): inside a member a decorator adds, the owner is `decl` — the annotated declaration as code (613), so `decl.make()` is `ServerConfig.make()` —; and a decorator's `syntax decl` is typed by what the decorator requires of the declaration.

The decorator `configurationProperties`, declared in the build layer ([draft/comptime/config.bp](draft/comptime/config.bp)), types its handle by what it needs of the declaration: `syntax decl: Configurable`. `Configurable` lists a static `make()` and a `host()`. `ServerConfig` has both, so the annotation is accepted, and the check is structural: the type writes no `implement Configurable`.

Inside the member it adds, `check`, the owner is `decl`, the annotated declaration as code, so `decl.make()` is `ServerConfig.make()`. The member reads `prefix` too, a `comptime` parameter spliced as the literal `"server"`. `ServerConfig.check()` prints `server: localhost`. `Self` gains no second meaning there: a method's receiver stays `self: Self`, and the owner's statics are reached through `decl`. A type annotated with `#[configurationProperties]` and lacking `make()` is refused at the annotation, naming the missing member.

Cells in this repository that bear on it: `modules/decl_member_owner`, `modules/init_executor_handle_typed`, `modules/init_executor_handle_on_type`.

[draft/main.bp](draft/main.bp)
