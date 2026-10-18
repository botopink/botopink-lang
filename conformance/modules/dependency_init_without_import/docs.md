# dependency_init_without_import

The reference text this cell shows (from `conformance/docs.md`, § Decorators):

> A declared dependency is part of the program (decision 660): every module of
> every package `botopink.json` declares — and of every package those declare —
> joins the build, and its executors join the init list whether or not
> anything imports it; `import` brings names into scope and nothing else. The
> init list runs package by package in dependency order: a package that
> depends on nothing first, a package after every package it depends on, the
> ones with the most levels of dependencies last; two packages of one level in
> the order their dependant's `botopink.json` lists them; inside a package,
> modules in dependency order and declarations in source order. Every
> dependency's executors run before the program's own.
