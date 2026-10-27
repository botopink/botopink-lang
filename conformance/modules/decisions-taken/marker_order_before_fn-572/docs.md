# Decision 572 — A marker sits next to `fn`: `#[…] [pub] [default] <marker> fn`

Every marked declaration writes its words in one order: annotations, then `pub`, then `default` when there is one, then the marker, then `fn` — `#[serverAction] pub async fn count(…)`, `pub iter fn lines(…)`, `pub async fn main()`, as Rust writes `pub async fn` and JavaScript `export async function`. The program prints `2`, `a,b` and `6`. Any other order — `async pub fn`, `pub fn async` — is a parse error at the marker, and `botopink format` writes this order. On a lambda the marker sits inside the brace, before the parameters (`{ async x -> … }`), the form decision 584 gave it.

Cells in this repository that also bear on it: `modules/decisions-taken/body_marker_whole_return_type-553/cases/marker_fn_forms`, `modules/decisions-taken/body_marker_whole_return_type-553/cases/marker_on_declaration`.

[draft/main.bp](draft/main.bp) · [draft/comptime/actions.bp](draft/comptime/actions.bp)
