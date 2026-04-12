# stdlib

Standard library for botopink programs.

## Files

| File | Role |
|---|---|
| `botopink.json` | Package metadata |
| `src/prelude.zig` | Registers stdlib bindings into the type `Env` at inference time |
| `src/primitives.bp` | Primitive type declarations (`i32`, `f64`, `string`, `bool`, …) |
| `src/array.bp` | Array method declarations |
| `src/string.bp` | String method declarations |
| `src/builtins.bp` | Built-in function declarations (`@name(args...)`) |

## Usage

`inferMod.registerStdlib(&env, gpa)` in `infer.zig` loads `prelude.zig` into
the type environment before each inference pass.

## Conventions

See the root repository's `../../AGENTS.md` for core architecture and testing guidelines.
