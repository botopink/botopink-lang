# clock_iso8601_millis_always

The reference text this cell shows (from `conformance/docs.md`, § Imports):

> `io.clock`'s `formatIso8601` answers `YYYY-MM-DDTHH:MM:SS.sssZ` on every target, the
> milliseconds always written, a whole second ending `.000` (decision 849); `parseIso8601` reads
> both widths. It runs where `io` has a host binding: commonJS, erlang and beam.
