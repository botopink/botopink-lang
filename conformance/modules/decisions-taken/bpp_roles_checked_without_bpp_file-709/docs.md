# Decision 709 — The `bpp` roles are checked whenever the manifest's key is present, `.bpp` file or not, on every `build` / `check` / `run` / `test`; a key that cannot be honoured is refused where it is written.

The example is a program with no `.bpp` file. Its manifest's `"bpp"` key names a package, and the key's roles are checked on every `build`, `check`, `run` and `test` all the same. A package that holds no `#[bpp.html]` function is refused at the key in `botopink.json`, before anything runs. A draft carries no manifest, so the key and its refusal wait for the promoted cell; as a draft the program builds and prints `no markup`.

Cells in this repository that also bear on it: `modules/bpp_file_without_key`, `modules/bpp_roles_found`.

[draft/main.bp](draft/main.bp)
