# Decision 344 — A git dependency may name a package inside its repository: `"subdir"`.

A git dependency may name one package inside the repository it clones, through `"subdir"`, and the key exists only beside `"git"`. The example's manifest, [draft/botopink.json](draft/botopink.json), declares `rakun-web` as `{"path": "deps/rakun", "subdir": "modules/rakun-web"}`: a `subdir` on a path dependency. The manifest is refused there, located at the `subdir` key, before any module is read. The well-formed form is `{"git": "https://github.com/botopink/rakun", "ref": "v1.0", "subdir": "modules/rakun-web"}`. It clones the repository at `ref` once, reads the package at `modules/rakun-web`, resolves that package's own `path` dependencies inside the same checkout (so its siblings come at the same `ref`), and shares the checkout with any other dependency on the same repository at the same `ref`. The other refusals are located in the manifest the same way: a `subdir` that is absolute or leaves the checkout through `..`; one with no `botopink.json`, or whose manifest is a workspace; and one repository asked for at two `ref`s, naming both dependencies. `main.bp` only prints, since the program never builds.

Cells in this repository that bear on it: none yet.

[draft/main.bp](draft/main.bp)
