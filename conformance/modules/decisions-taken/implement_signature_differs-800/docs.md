# Decision 800 — Every implementor of a contract is checked against it, on every member — a required one and an overridden `default fn` alike, std's types and a program's: the same number of parameters, each parameter's type and the return type identical with `Self` read as the implementing type; labels, parameter names and defaults free; a difference refused at the member, `implement-signature-differs`, naming both signatures.

[cases/implement_signature_differs/src/main.bp](cases/implement_signature_differs/src/main.bp)
[cases/implement_signature_differs_default_fn/src/main.bp](cases/implement_signature_differs_default_fn/src/main.bp)
[cases/implement_signature_differs_extension_block/src/main.bp](cases/implement_signature_differs_extension_block/src/main.bp)
[cases/implement_signature_differs_no_variance/src/main.bp](cases/implement_signature_differs_no_variance/src/main.bp)
[cases/implement_signature_same/src/main.bp](cases/implement_signature_same/src/main.bp)
