# index_and_slice_sugar

The reference text this cell shows (from `conformance/docs.md`, § Indexing and slicing):

> **An index is a method call.** `xs[k]` *is* `xs.at(k)`, `xs[a..b]` *is*
> `xs.slice(a, b)`, and an open end passes `null` — `xs[1..]` *is*
> `xs.slice(1, null)`, because `start..end` is a form and not a value, so there is
> nothing else to hand the method. The index expression has **no typing rule of
> its own**: its type is whatever the method answers, which for `at` is `?T`.
