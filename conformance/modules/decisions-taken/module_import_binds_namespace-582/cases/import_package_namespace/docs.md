# import_package_namespace

The reference text this cell shows (from `conformance/docs.md`, § Imports):

> A package's namespace is one form, spelled two ways: `import kit;` is `import {kit}
> from "kit"` — the namespace of the package's module `kit` (`src/kit.bp`), its items
> reached through it, the namespace called as that module's default. `import x from
> "p";` is `import {x} from "p"`, and `import x, {a} from "p";` is `import {x, a} from
> "p"`.
