# Decision 606 — No `#[builtin]` and no `@name`: the types and behaviors a program reaches without an import are declared in `primitives.bp`; what the compiler does is a member of `compiler`; the two std functions left are imported.

`print` and `panic` are the two std functions a program imports (`import {io.terminal.print} from "std";`). The case `print_local_shadows_import` binds a local named `print` inside one function while the module still calls the imported `print` outside it: the local reads as the local, the import still binds the calls, and std's `io/terminal` module is part of the build on every target.

[cases/print_local_shadows_import](cases/print_local_shadows_import/docs.md)
