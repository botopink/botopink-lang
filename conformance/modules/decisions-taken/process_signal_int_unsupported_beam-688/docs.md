# Decision 688 — `onSignal(.Int, f)` answers `Error(Unsupported)` on erlang and beam, where the VM keeps `SIGINT` for its break handler; `forwardSignals` skips `Int` there; `Int` stays in the shared enum.

The example asks for a handler on `Int` and on `Term`, and prints what each `onSignal` answered. The answer for `Int` depends on the target, as the decision says. On commonJS `onSignal(.Int, f)` installs the handler and prints `installed`. On erlang and beam the VM keeps `SIGINT` for its break handler, so the call answers `Error(Unsupported(…))` and the program prints `unsupported`. `Term` installs on every one of the three. `Int` stays a variant of the shared `Signal` enum, so the program is the same text on every target, and `forwardSignals` skips `Int` where it is unsupported instead of failing. The terminal's Ctrl-C still reaches a spawned child through the process group. The cell's snapshot holds the commonJS answer, with erlang and beam as declared departures.

The program prints `Int installed` (`Int unsupported` on erlang and beam), then `Term installed`.

Cells in this repository that bear on it: `modules/decisions-taken/std_cli_host_primitives-506/cases/std_io_signal_handlers`, `modules/decisions-taken/std_cli_host_primitives-506/cases/std_io_process_forward_signals`.

[draft/main.bp](draft/main.bp)
