# Decision 414 — The render library holds every scope in plain functions: an error boundary, a not-found boundary and a `Suspense` fill are nodes of the tree holding a component value, and the renderer runs each inside its host's try with the scope its parent's `run` answered.

The example's `Page` places two boundaries as ordinary nodes of its tree. A `NotFoundBoundary` holds `<Product id={id}/>`, and an `ErrorBoundary` holds `<Price cents={cents}/>`. Each child is a component value, and `Page` writes no `try`.

The first line shows why a node is enough. `Price(cents: -1)` only makes the component, so nothing runs, and `runs` prints `0`. A component runs when the renderer calls its `run` with a scope. The renderer's plain functions do that inside the host's try: the error boundary's child under `attempt`, and the not-found boundary's child catching only the not-found signal.

The first render, `cents={1250}` and `id="p-7"`, prints the product heading and `12.50`. The second, `cents={-1}` and `id=""`, triggers both boundaries. `Product` calls `notFound()`, and its boundary renders `no such product`. `Price` panics, and its boundary renders `oops(infoFor(…))`, written with the same scope: `price unavailable` and the length of the digest, never the message. Every other node of the page still renders. The last line prints `2`, one run of `Price` per render, so the panicking run happened inside the boundary and nowhere else.

The compiler's part is a component as a lambda over its scope (388) and a component value as a prop. The boundaries and the renderer are `rakun-bpp`'s, which this repository's drafts declare no dependency on.

Cells in this repository that also bear on it: none.

[draft/main.bp](draft/main.bp)
