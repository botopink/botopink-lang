# loaded_module

A fixture of `tests/cli_contract.sh` for `botopink cell check` (decision 982 (5)): one module whose `src/main.bp` loads a printing case and a refused one through `compiler.load`, checked as one cell, and a full cell kept beside them under `cells/`, checked on its own.

[src/main.bp](src/main.bp)
[cases/loaded_prints/src/main.bp](cases/loaded_prints/src/main.bp)
[cases/loaded_refused/src/main.bp](cases/loaded_refused/src/main.bp)
[cells/kept_cell/src/main.bp](cells/kept_cell/src/main.bp)
