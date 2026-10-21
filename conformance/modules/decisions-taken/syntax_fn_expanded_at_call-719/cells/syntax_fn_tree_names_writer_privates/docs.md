# syntax_fn_tree_names_writer_privates

The code a template or a `syntax` expression function builds resolves each name in the module that wrote it (decisions
170, 578, 719, 859): `kit`'s tree names its private function `boxOf`, its private value `factor` and `Box`'s private
method `scaled`, and the call from another package reaches them, neither unbound nor `method-not-pub`. The caller's own
`factor` and `boxOf` capture nothing in the tree; the hole `x + factor` is the caller's code and reads the caller's
`factor`.
