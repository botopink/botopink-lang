# Decision 671 — A field's default travels with the field into every derived type and resolves where it was written (669); there is no "closed" default.

The example declares `Link` in [draft/links.bp](draft/links.bp), with `rel` defaulting to `defaultRel()`, a private function of that module. `main` derives `NoHref = Type.omit(Link, .href)` in another module. The derived type copies `rel` together with its default. The default is still `links.bp`'s code, resolved where it was written, and the generated code calls `defaultRel` qualified, so `NoHref().rel` prints `noopener`, as `Link(href: "/x").rel` does. `main` cannot name `defaultRel` and does not need to. There is no "closed" default that a derived type would refuse: the one limit is that a default names only what its own module sees. A decorator that rebuilds a type hands each default on unchanged, through `compiler.Field.defaultValue`.

The program prints `noopener`, `noopener` and `/x`.

Cells in this repository that bear on it: `modules/derived_type_imported`, `modules/derived_type_two_packages`, `modules/default_argument_across_modules`.

[draft/main.bp](draft/main.bp)
