# import_module_paths

The reference text this cell shows (from `conformance/docs.md`, § Imports):

> `from "<name>"` names a **package** — std or a dependency declared in
> `botopink.json` — and nothing else (decision 206). A module of the importing package is imported by its path
> inside the braces, with no `from`. An import always names where its names come
> from (decision 337): an item with no `from` whose first segment names no module
> of the package — `import {perimeter};` — is `shorthand-import` at the item, its
> fix written (below).
