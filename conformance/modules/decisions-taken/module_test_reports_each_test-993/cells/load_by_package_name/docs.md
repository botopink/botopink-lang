# load_by_package_name

Decision 993 (2): `compiler.load(package: "greeter")` loads the package named `greeter` by name, as a `git` dependency of that name resolves; the `Module` carries the manifest's name and the directory the lookup found, and `run()` prints through the package's own `main`.

[src/main.bp](src/main.bp)
