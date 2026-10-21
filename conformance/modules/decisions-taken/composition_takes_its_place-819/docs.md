# Decision 819 — A `Composition` takes its place with its scope, `fn(scope: Scope, key: Place) -> T | Async<T>`, and opens its own cell from them; a place is a number — each written call's within its declaration, and each value that call makes in a render counted on — or the `#[key(…)]` in the item's stead; a call by hand is safe since its place travels with it; amends 815 (1), (3), 817 (1), (2), 818 (1), (2).

[cells/composition_takes_its_place/src/main.bp](cells/composition_takes_its_place/src/main.bp)
