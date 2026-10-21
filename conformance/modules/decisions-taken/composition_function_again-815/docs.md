# Decision 815 — `Composition<T>` is a function again, `fn(scope: Scope) -> T | Async<T>`; any lambda of that type is a component without hooks and may be called by hand; a function answering a member of a union fits where one answering the union is expected; amends 809 (1), (6), 811 (2), 813 (1); where the hooks' state lives is 816's.

[cells/composition_function_again/src/main.bp](cells/composition_function_again/src/main.bp)
