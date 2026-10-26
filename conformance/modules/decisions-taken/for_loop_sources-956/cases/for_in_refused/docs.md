# for_in_refused

There is no `for x in xs` (decision 956 (4)): the item is the block's parameter. `for c in g.iter() { … }` is refused `for-in-loop` at the binder, the caption naming `for xs { x -> … }`.
