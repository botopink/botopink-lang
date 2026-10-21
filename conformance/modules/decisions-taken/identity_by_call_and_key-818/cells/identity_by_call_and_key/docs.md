# identity_by_call_and_key

Decision 818: every `use` that answers a value takes a child cell at its place, and a component's
identity is the call that made it, with a `#[key(…)]` written before it when there is one (818 (3)).
Two calls in an `if` are two cells; a keyed list reordered keeps each item's memo; a generic
component at two sites keeps two cells.

[src/main.bp](src/main.bp)
