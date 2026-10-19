# Decision 509 — One code cache, the CLI's, for every target; what a test exercises never comes from it.

The program is its own package with one dependency, std: it counts the words of a sentence with std's `Dict` and joins a path with std's `path`, printing `2 2 1` and `src/main.bp`. Every time it is built, run, tested or checked as a cell, this package — the one under test — is analysed, generated, compiled and run from its source; only std's compiled modules may come from the code cache, under a key of their input bytes and the tool's version, and they are materialised into this program's own output, never run in place. A test's result is never cached: a second run runs again. In a workspace the cache is the workspace root's `.botopinkbuild/cache/`, so every cell of `conformance/modules/` shares one cache of std.

[draft/main.bp](draft/main.bp)
