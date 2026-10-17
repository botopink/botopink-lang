# array_range_and_repeat

The reference text this cell shows (from `conformance/docs.md`, § Arrays):

> `Array.range(start, stop)` is the integers of `[start, stop)`, empty when
> `stop <= start`; `Array.repeat(value, times)` is `times` copies of `value`, empty
> when `times <= 0`. A result costs its own length in memory, a long one too, and so
> does `xs.fill(v)`, which is `Array.repeat(v, xs.length)`:
