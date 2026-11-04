# children_array_walk

A record field typed by an array of the record itself is walked by `for` and recursed into on every
target (decision 857 (1)): the cell that guarded the walk of the retired compiler-known `Children`.
