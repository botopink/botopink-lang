# targets_default_is_dependencies_intersection

A program that writes no `"targets"` over `beamkit`, which declares `erlang` alone, holds `erlang` alone (decision 770): it runs there and prints `distance 7`, and its builds for `commonJS`, `beam` and `wasm` are refused `dependency-target-missing` at `beamkit`'s line.
