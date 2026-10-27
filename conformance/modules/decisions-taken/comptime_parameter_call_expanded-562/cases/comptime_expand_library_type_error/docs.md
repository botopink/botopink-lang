# comptime_expand_library_type_error

The reference text this cell shows (from `conformance/docs.md`, § Typed meta (decision 298), The hooks a function reaches — `decl.hooks`):

> A refusal of that code is located in the declaring module, where the refused
> code is written, and the call it was expanded at is its `called from` line:
> `shout(7)` writes `count.toUpper()` over an `i32`.

Refused at `greeter/root.bp:8:18`, the `toUpper` call in the library, with `shout(7)` (`src/main.bp:9:5`) as the `called from` line.

<!-- example: modules/decisions-taken/comptime_parameter_call_expanded-562/cases/comptime_expand_library_type_error -->
