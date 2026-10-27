# two_modules_and_dependency

A package of two modules (`main`, `util`) with a dependency of two modules (`root`, `util`): each module is written
once, flat, under its `<pkg>@<path>` name, and the program answers as it did with mirrored subfolders — the two
`util` modules are two files, never one (decision 1015).
