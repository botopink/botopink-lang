# Decision 816 — The hooks' state lives in the node's scope cell, by the order of the `use`s, and a cell is kept from one render to the next while the same component stands at the same place — as React keeps a fiber; `return c` gets a child cell too; the render library keeps a mounted tree's root; amends 771, 809 (9), 812 (2), 815.

[cells/hooks_state_by_tree_place/src/main.bp](cells/hooks_state_by_tree_place/src/main.bp)
