# modules — explicit module tree (mod / pub mod)

A tour of the Rust-style module system. The package declares its tree from a
root instead of the compiler compiling every `.bp` under `src/`.

```
src/
  main.bp          ← binary root: declares `pub mod geometry; pub mod shapes;`
  geometry.bp      ← leaf module (sibling file)        — pub mod geometry
  shapes/
    mod.bp         ← folder index (the `shapes` module) — pub mod shapes
    circle.bp      ← submodule                          — pub mod circle (public)
    helpers.bp     ← submodule                          — mod helpers (private)
```

- `mod Name;` resolves a sibling `Name.bp` **or** a folder index `Name/mod.bp`.
- `pub mod` re-exports through the parent; a plain `mod` is private to its
  declaring module's subtree — `helpers` is used by `shapes/mod.bp` (inside the
  subtree) but importing it from `main.bp` would fail the path-visibility rule.
- Imports follow the tree: `from "shapes.circle"` is the module path
  `shapes/circle`.

## Run

```sh
botopink run
# 12
# circle
# 7
```

The tree can also be generated from a flat `src/` layout with `botopink migrate`.
