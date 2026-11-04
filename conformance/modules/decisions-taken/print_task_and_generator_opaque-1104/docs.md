# print_task_and_generator_opaque-1104

Decision 1104 — a task (`Async<T>`) and a generator (`Iter<T>`, `AsyncIter<T>`) have no printed text: `print` of a value whose static type is one of them — directly, or through a generic parameter the call binds to one — is refused at build on all four targets, naming the type and the call (`print-task` / `print-generator`); no fixed text and no target's native inspect. One reaching an `unknown` slot (through a generic body compiled once for every instantiation) keeps the dynamic case's named panic (`panic: wasm cannot print a … value`), the same text on every target; wasm's static path closes with the build refusal instead.

[cases/print_task_refused_at_build/src/main.bp](cases/print_task_refused_at_build/src/main.bp)
[cases/print_generator_refused_at_build/src/main.bp](cases/print_generator_refused_at_build/src/main.bp)
[cases/print_generator_through_unknown_panics/src/main.bp](cases/print_generator_through_unknown_panics/src/main.bp)
