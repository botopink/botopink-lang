# load_refused_on_one_target_answers_refused

The reference text this cell shows (from `conformance/docs.md`, § `compiler.load`):

> The target built may refuse the loaded package — a host binding it reaches has no implementation there (decision
> 989 (3)). That is the answer of its `run()`, never a refusal of the build, and nothing of the package runs: `kind`
> is `.Refused` when the package's manifest declares the target, `.Excluded` when its `targets` leave the target out,
> `message` the refusal's text as `botopink build` prints it on that target.
