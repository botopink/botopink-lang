# syntax_fn_tree_names_writer_imports

The code a template or a `syntax` expression function builds resolves each name in the module that wrote it, the names
that module imports included (decisions 170, 578, 719): `kit`'s trees name `unit` and the namespace `units` of its own
package, std's `pow` and the namespace `math`, and the caller in another package, which imports none of them, reaches
each where `kit` does. The caller's own `unit` captures nothing in the tree; the hole `n + 1` is the caller's code.
