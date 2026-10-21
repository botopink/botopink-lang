# Decision 790 — `cell check` becomes a botopink program — `conformance/check/`, run on commonJS — that runs `botopink build` and `botopink run` per package and target through `io.process`, builds the `.snap` records from the console, compares and writes `.new`, never accepting (67); it replaces the CLI's `botopink cell check` once its snapshots equal the CLI's byte for byte over the whole suite; B-157 piece 5 waits on it.

[cells/std_io_process_start/src/main.bp](cells/std_io_process_start/src/main.bp)
[cells/std_io_process_start_parallel/src/main.bp](cells/std_io_process_start_parallel/src/main.bp)
[cells/std_io_process_start_refused_off_node/src/main.bp](cells/std_io_process_start_refused_off_node/src/main.bp)
