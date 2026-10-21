# index_tuple_literal

The reference text this cell shows (from `conformance/docs.md`, § Indexing and slicing):

> A **tuple** is the one exception, and its reason is the rule's: `t[0]` needs a
> *constant* index and answers a type *per position*, which `at(key: K) -> ?V`
> cannot say with a single `V`. A tuple index is checked directly — `t[0]` is
> `i32` and `t[1]` is `string` below, neither of them optional, and an index the
> type has no position for is refused where it is written.
