# Decision 802 — No hole is the language's (577 (5) restored): a template reads its text raw and decides its syntax, and reaches the caller's names through `compiler.lookup(e, name) -> ?Node`; `compiler.holes`, `compiler.isSyntax` and the `Syntax` node go; in `code` a `Node` value is spliced as that node; reverses 637's caller-hole half and 638, amends 669, 686 and 801.

[cells/template_method_receiver_code/src/main.bp](cells/template_method_receiver_code/src/main.bp)
