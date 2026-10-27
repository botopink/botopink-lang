# Decision 451 — The seeded random's stream is std-wasm's; the entropy stays the host's; a build never draws unseeded.

[refused/src/cases/comptime_random_unseeded/mod.bp](cases/comptime_random_unseeded/src/main.bp)
[refused/src/cases/decorator_helper_raise_located/mod.bp](cases/decorator_helper_raise_located/src/main.bp)
[cases/std_random_on_every_target/src/main.bp](cases/std_random_on_every_target/src/main.bp)

Proved also by [comptime_random_float_unseeded](../unseeded_random_refused_at_build-456/cases/comptime_random_float_unseeded/src/main.bp)
Proved also by [decorator_random_float_unseeded](../unseeded_random_refused_at_build-456/cases/decorator_random_float_unseeded/src/main.bp)
