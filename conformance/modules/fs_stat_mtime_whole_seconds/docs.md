# fs_stat_mtime_whole_seconds

The reference text this cell shows (from `conformance/docs.md`, § Imports):

> **`io` answers alike on every target.** `io.clock`'s `formatIso8601`,
> `toCivil` and `offsetMinutes` take the epochs RFC 3339 writes,
> 0000-01-01T00:00:00Z … 9999-12-31T23:59:59.999Z (−62167219200000 …
> 253402300799999 milliseconds), the same on every target, and past them abort
> naming the value (`clock.toCivil: 253402300800000 is past RFC 3339's range`)
> (decision 497). `fs.stat`'s `mtime` is whole seconds, as epoch milliseconds, on
> every target (decision 499). The two run where `io` has a host binding:
> commonJS, erlang and beam.
