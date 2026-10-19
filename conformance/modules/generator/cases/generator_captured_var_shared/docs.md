# generator_captured_var_shared

The reference text this cell shows (from `conformance/docs.md`, § Iterators and streams):

> A generator's body captures the enclosing scope's variables as a closure (decision 105): a captured
> `var` is one variable on both sides. What the function writes after making the generator, or between
> two items, is what the body reads next; what the body writes is what the function reads after it — in
> the same block, in a nested one, and in a lambda.
