# Decision 498 — `clock.parseDuration` keeps its 2^53 − 1 ms bound: a duration is handed on as an `f64`.

The example parses five durations with `clock.parseDuration`. `30s` is `30000` ms. `9007199254740991ms`, which is 2^53 − 1, is the largest count accepted, and one millisecond more is an `Error` saying it is out of range. The bound applies to the product and not to the digits: `104249991d` is accepted, at `9007199222400000` ms, while `104249992d` would pass 2^53 − 1 and is refused. The bound is set by where a duration goes next, a timer delay or a JSON number, and both are `f64`, which stops counting by one past 2^53.

Cells in this repository that also bear on it: `modules/decisions-taken/clock_rfc3339_domain-497/cells/clock_rfc3339_domain`.

[draft/main.bp](draft/main.bp)
