# load_library_entry_root

Decision 993 (1): `compiler.load` compiles a package from the entry its manifest's `src` and `entry` name (`lib/root.bp` here), never a fixed `src/main.bp`; a manifest naming an entry that is not there is `load-not-a-package`, naming that entry.

[src/main.bp](src/main.bp)
