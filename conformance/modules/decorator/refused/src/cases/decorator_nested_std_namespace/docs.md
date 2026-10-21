# decorator_nested_std_namespace

The reference text this cell shows (from `conformance/docs.md`, § Decorators):

> A decorator's body reaches the std modules its module imports, a nested
> namespace included (`random.seed(7)` after `import {io.random} from "std"`); a body
> whose run fails is checked with them bound, so its answer is its own error —
> never the namespace read as unbound:

`tagged` seeds `random` and reads `decl.nope`: the answer is the unknown field, at 13:18.
