# Decision 349 — `log` owns the sinks; rakun and onze only integrate.

The `logging` module plays the part the decision gives the `log` library: it owns the levels, the record, the `Sink` behavior and the sinks themselves — here a console sink with a minimum level — and its one host dependency, `print`, is a binding std gives on every target, never one bound on some targets only, so the module imports on every build. The program, in the part rakun and `rakun-ssr` play, only chooses a sink, configures it (`Level.Info`) and installs it at boot, then logs through a named `Logger`. It prints `INFO app.request started` and `ERROR app.request [req-7] failed`; the `Debug` record is below the sink's level and is not shown. The correlation id is a field of the record, the one piece a framework adds.

[draft/main.bp](draft/main.bp) · [draft/logging.bp](draft/logging.bp)
