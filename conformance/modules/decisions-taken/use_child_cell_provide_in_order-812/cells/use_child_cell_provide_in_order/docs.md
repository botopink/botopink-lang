# use_child_cell_provide_in_order

Decision 812, as 816 (6) amends it: `use c` resolves `c` under a child cell made at the `use`, and
a returned component under one too; a `use provide` writes the body's cell in the order written —
a component resolved at an earlier `use` reads the default, one resolved after it the provided
value —, and a child's own provides reach its subtree alone, never its parent's later reads nor its
siblings.

[src/main.bp](src/main.bp)
