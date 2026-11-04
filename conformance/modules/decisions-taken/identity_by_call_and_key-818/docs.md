# Decision 818 — Every `use` that answers a value takes a child cell at its place; a component's identity is the call that made it — its site, numbered within the enclosing declaration —, with a `#[key(…)]` written at the call when there is one; no type argument is part of it; amends 816 (1), 817 (2), (4).

[cases/identity_by_call_and_key/src/main.bp](cases/identity_by_call_and_key/src/main.bp)

[cases/key_not_component/src/main.bp](cases/key_not_component/src/main.bp)

[cases/key_type/src/main.bp](cases/key_type/src/main.bp)
