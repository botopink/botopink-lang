# async_block_tail_value

The reference text this cell shows (from `conformance/docs.md`, § Tasks):

> - its value is its last expression written without `;` (decision 525, § Blocks),
>   a braced `case` / `if` at its end included, and `return v` **leaves the
>   block** with `v`, not the enclosing function — the block is a task of its
>   own;
