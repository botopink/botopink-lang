# Decision 451 — The seeded random's stream is std-wasm's; the entropy stays the host's; a build never draws unseeded.

[refused/src/cases/comptime_random_unseeded/mod.bp](refused/src/cases/comptime_random_unseeded/mod.bp)
[refused/src/cases/decorator_helper_raise_located/mod.bp](refused/src/cases/decorator_helper_raise_located/mod.bp)
[cells/std_random_on_every_target/src/main.bp](cells/std_random_on_every_target/src/main.bp)

Proved also by [comptime_random_float_unseeded](../unseeded_random_refused_at_build-456/refused/src/cases/comptime_random_float_unseeded/mod.bp)
Proved also by [decorator_random_float_unseeded](../unseeded_random_refused_at_build-456/refused/src/cases/decorator_random_float_unseeded/mod.bp)
