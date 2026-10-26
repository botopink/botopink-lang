{module, std@io@clock}.
{exports, [{nowMillis, 0}, {monotonicMillis, 0}, {formatIso8601, 1}, {measureMillis, 1}, {parseIso8601, 1}, {toCivil, 1}, {offsetMinutes, 1}, {millis, 1}, {seconds, 1}, {minutes, 1}, {hours, 1}, {add, 2}, {toMillis, 1}, {parseDuration, 1}, {sleep, 1}, {deadline, 1}, {isExpired, 1}, {'__bp_priv__string_parseInt', 1}, {'__bp_priv__string_slice', 3}, {'__bp_priv__checkRfc3339Domain', 2}, {'__bp_priv__durationCount', 1}, {'__bp_priv__durationProblem', 2}, {'__bp_priv__durationRefusal', 1}, {'__bp_priv__durationUnit', 1}, {'__bp_priv__earliestRfc3339Millis', 0}, {'__bp_priv__largestExactMillis', 0}, {'__bp_priv__latestRfc3339Millis', 0}, {'__bp_priv__unitMillis', 1}, {'__bp_priv__wide', 1}]}.
{attributes, []}.
{labels, 386}.
%%% std/io/clock (was std/time) — wall-clock primitives, cross-backend.
%%% 
%%% Reference:
%%%   Node.js  — https://nodejs.org/api/  (the `Date` global, the
%%%              `Date.now()` static method in particular)
%%%   Erlang   — https://www.erlang.org/doc/man/erlang.html#system_time-1
%%%              (`erlang:system_time(Unit)` — `Unit` may be an integer
%%%              divisor `1`, `1000`, `1000000`, `1000000000`)
%%% 
%%% `nowMillis()` returns Unix epoch milliseconds on every backend. The
%%% implementation lowers to `Date.now(1000)` on Node — `Date.now/0`
%%% silently ignores the extra arg (JS variadic) — and to
%%% `erlang:system_time(1000)` on Erlang, where the integer `1000`
%%% selects the millisecond unit. The split exists because the bare-symbol
%%% `#[compiler.external(.<Target>)]` form cannot inject a literal atom-style unit on the
%%% Erlang side without a richer template (tracked under
%%% prim-op-annotation); the integer divisor form is universal and
%%% keeps the call signature 1-arg. The `#[compiler.external(.<Target>)]`
%%% annotation form (typed-enum) is the canonical surface.
%%% 
%%% `monotonicMillis()` returns the host's monotonic clock in
%%% milliseconds — `performance.now()` on Node (DOM high-res timestamp,
%%% floating point but assignable to the `i64` return on a backend that
%%% has no integer-only clock without a chained `Math.floor`), and
%%% `erlang:monotonic_time(1000)` on Erlang (integer divisor selects
%%% milliseconds, matching the `nowMillis()` shape).
%%% 
%%% `measureMillis<T>(body)` composes `nowMillis()` calls — pure
%%% botopink, no host call beyond what `nowMillis()` already lowers.
%%% 
%%% `sleep(ms)` blocks the caller (1.0.10-beta front 01): `Atomics.wait`
%%% on Node, `timer:sleep/1` on Erlang. It is synchronous on purpose — the
%%% `Async` spelling (`delay`) lives in `std/async`.
%%% 
%%% Front 01 also adds the calendar half below the readings: `parseIso8601`
%%% (RFC 3339, offset required), `toCivil` (UTC breakdown, ISO weekday),
%%% `offsetMinutes` (host timezone), the `Duration` builders and
%%% `deadline`/`isExpired`. Front 23 moves the file to `io/clock.bp`.
%%% 
%%% `formatIso8601(epochMillis)` renders an RFC-3339 / ISO-8601 string
%%% for an epoch-milliseconds reading. Node uses `new Date($0).toISOString()`
%%% (chained host call, §A2-wired); Erlang supplies `[{unit, millisecond}]` to
%%% `calendar:system_time_to_rfc3339/2`. The output is byte-identical on every
%%% target, `YYYY-MM-DDTHH:MM:SS.sssZ`, milliseconds always (decision 849).
% Internal: read the host's current millisecond clock. The `unit`
% argument is `1000` for millis; Node `Date.now` ignores it, Erlang
% `erlang:system_time/1` uses it as the divisor selector.
% Milliseconds since the Unix epoch. Monotonic across reasonable clock
% drift on every backend; not adjusted for leap seconds.

{function, nowMillis, 0, 3}.
  {label, 2}.
    {line, [{location, "std@io@clock.erl", 1}]}.
    {func_info, {atom, std@io@clock}, {atom, nowMillis}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {integer, 1000}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, system_time, 1}, 0}.
% Internal: read the host's monotonic clock. `unit` is `1000` for
% millis on Erlang (`erlang:monotonic_time/1` uses the divisor selector);
% Node uses the §A2 commonJS template form (`performance.now($0)`)
% to keep the receiver bound — the legacy
% `#[compiler.external(.JavaScript("performance", "now"))]` form aliased `const x =
% performance.now` and stripped `this`, reding with `Value of "this"
% must be of type Performance` at the first call site. The template
% renders inline at every call to `monotonicTimeWithUnit(N)`.
% The answer is an `i64`: `performance.now()` is a fractional millisecond
% count, truncated to its whole milliseconds (decision 319's canonical form).
% Monotonic milliseconds — the host's monotonic clock, suitable for
% elapsed-time measurements (use `nowMillis()` for the wall clock).
% Two consecutive `monotonicMillis()` reads on the same backend are
% non-decreasing; the relative scale matches `nowMillis()` (millisecond
% units). On Node the absolute origin is the Unix epoch (`Date.now()`)
% until §A2 wires `performance.now()`; on Erlang it is the host's
% monotonic origin (`erlang:monotonic_time/1`).

{function, monotonicMillis, 0, 5}.
  {label, 4}.
    {line, [{location, "std@io@clock.erl", 2}]}.
    {func_info, {atom, std@io@clock}, {atom, monotonicMillis}, 0}.
  {label, 5}.
    {allocate, 0, 0}.
    {move, {integer, 1000}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, monotonic_time, 1}, 0}.
% Render `epochMillis` as an ISO-8601 / RFC-3339 timestamp string.
% Node: `new Date($0).toISOString()` (renders `YYYY-MM-DDTHH:MM:SS.sssZ`).
% Erlang: `calendar:system_time_to_rfc3339/2` with the `millisecond` unit and
% the `Z` offset on the millis as they are (decision 849): milliseconds are
% always written, `YYYY-MM-DDTHH:MM:SS.sssZ`, as Node's are. The `Z` offset keeps
% `calendar` from reading the host's local time, which ERTS refuses before 1902.
% Its domain is RFC 3339's (decision 497): past it the call aborts,
% naming the value, on every target (`checkRfc3339Domain`).

{function, formatIso8601, 1, 7}.
  {label, 6}.
    {line, [{location, "std@io@clock.erl", 3}]}.
    {func_info, {atom, std@io@clock}, {atom, formatIso8601}, 1}.
  {label, 7}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"formatIso8601">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call, 2, {f, 13}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 63}, 1}.
% The domain of `formatIso8601`, `toCivil` and `offsetMinutes` (decision
% 497): the epochs RFC 3339 writes, 0000-01-01T00:00:00Z …
% 9999-12-31T23:59:59.999Z, the same on every target. ECMAScript's `Date`
% holds a wider range and Erlang's `calendar` a different one, so the bound
% is checked here, before the host is reached.

{function, earliestRfc3339Millis, 0, 9}.
  {label, 8}.
    {line, [{location, "std@io@clock.erl", 4}]}.
    {func_info, {atom, std@io@clock}, {atom, earliestRfc3339Millis}, 0}.
  {label, 9}.
    {allocate, 0, 0}.
    {move, {integer, -62167219200000}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, latestRfc3339Millis, 0, 11}.
  {label, 10}.
    {line, [{location, "std@io@clock.erl", 5}]}.
    {func_info, {atom, std@io@clock}, {atom, latestRfc3339Millis}, 0}.
  {label, 11}.
    {allocate, 0, 0}.
    {move, {integer, 253402300799999}, {x, 0}}.
    {deallocate, 0}.
    return.
% Internal: abort when `epochMillis` is past RFC 3339's domain, naming the
% function and the value.

{function, checkRfc3339Domain, 2, 13}.
  {label, 12}.
    {line, [{location, "std@io@clock.erl", 6}]}.
    {func_info, {atom, std@io@clock}, {atom, checkRfc3339Domain}, 2}.
  {label, 13}.
    {allocate, 11, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {call, 0, {f, 9}}.
    {test, is_lt, {f, 65}, [{y, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 66}}.
  {label, 65}.
    {move, {atom, false}, {x, 0}}.
  {label, 66}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 67}, [{x, 1}, {atom, true}]}.
    {call, 0, {f, 11}}.
    {test, is_lt, {f, 69}, [{x, 0}, {y, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 70}}.
  {label, 69}.
    {move, {atom, false}, {x, 0}}.
  {label, 70}.
    {jump, {f, 68}}.
  {label, 67}.
    {move, {atom, true}, {x, 0}}.
  {label, 68}.
    {test, is_eq, {f, 64}, [{x, 0}, {atom, true}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<" is past RFC 3339's range, -62167219200000 to 253402300799999">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<": ">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"clock.">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 74}}.
    {call, 1, {f, 72}}.
    {jump, {f, 107}}.
  {label, 64}.
  {label, 107}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 11}.
    return.
% Measure how long `body` takes to evaluate, in milliseconds. Returns
% the body's result paired with the elapsed time. Uses `nowMillis()`
% (the wall clock) rather than `monotonicMillis()` for cross-backend
% f64/i64 unifier symmetry — both readings are i64-typed, so the
% difference stays in the integer arithmetic path on every target.

{function, measureMillis, 1, 15}.
  {label, 14}.
    {line, [{location, "std@io@clock.erl", 7}]}.
    {func_info, {atom, std@io@clock}, {atom, measureMillis}, 1}.
  {label, 15}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 0, {f, 3}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_fun, 0}.
    {move, {x, 0}, {y, 2}}.
    {call, 0, {f, 3}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {y, 1}], {x, 0}}.
    {test, is_ge, {f, 108}, [{x, 0}, {integer, -9223372036854775808}]}.
    {test, is_ge, {f, 108}, [{integer, 9223372036854775807}, {x, 0}]}.
    {jump, {f, 109}}.
  {label, 108}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i64 at src/io/clock.bp:138:31">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 109}.
    {move, {x, 0}, {y, 3}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 2}, {y, 3}]}}.
    {deallocate, 4}.
    return.
% ── 1.0.10-beta front 01 additions ──────────────────────────────────────────
% 
% Parsing, the civil breakdown, the host timezone offset, durations,
% deadlines and `sleep`. The readings above are not edited.
% A UTC calendar breakdown of an epoch reading. `month` is 1–12, `day`
% 1–31, `weekday` ISO-8601 (Monday = 1 … Sunday = 7).
% A span of time in milliseconds. Built by `millis`/`seconds`/`minutes`/
% `hours`, combined by `add`, read back by `toMillis`.
% Parse an RFC 3339 timestamp (`2024-02-29T12:34:56Z`,
% `2024-02-29T12:34:56.789+02:00`) into epoch milliseconds. The date, the
% time AND the offset are required — a timestamp without an offset has no
% single instant, so it is an `Error`, not a guess at the host timezone.
% Node: `Date.parse` accepts far more than RFC 3339 (`"2024"`, `"Feb 1"`),
% so the template checks the RFC 3339 shape first, then parses; a shape or a
% date it refuses is its raise.
% Erlang: `calendar:rfc3339_to_system_time/2` in milliseconds; it raises on
% a malformed string.
% Both run under `result: true` (decisions 431, 490); `parseIso8601` makes
% the host's raise `ClockError.NotRfc3339` (decision 486).
% What `parseIso8601` refuses (decision 486).

{function, parseIso8601, 1, 17}.
  {label, 16}.
    {line, [{location, "std@io@clock.erl", 8}]}.
    {func_info, {atom, std@io@clock}, {atom, parseIso8601}, 1}.
  {label, 17}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 111}}.
    {test, is_tagged_tuple, {f, 127}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 2}.
    return.
    {jump, {f, 126}}.
  {label, 127}.
    {test, is_tagged_tuple, {f, 128}, [{x, 0}, 2, {atom, error}]}.
    {move, {atom, std@io@clock@@ClockError__v__notrfc3339}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 2}.
    return.
    {jump, {f, 126}}.
  {label, 128}.
    {case_end, {x, 0}}.
  {label, 126}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 2}.
    return.
% The UTC civil breakdown of `epochMillis`.
% Node: the `getUTC*` readers of a `Date`; `getUTCDay` counts Sunday = 0,
% rotated to ISO (Monday = 1).
% Erlang: `calendar:system_time_to_universal_time/2` + `day_of_the_week/3`
% (already Monday = 1).

{function, toCivil, 1, 19}.
  {label, 18}.
    {line, [{location, "std@io@clock.erl", 9}]}.
    {func_info, {atom, std@io@clock}, {atom, toCivil}, 1}.
  {label, 19}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"toCivil">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call, 2, {f, 13}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 130}}.
    {move, {atom, std@io@clock@@Civil}, {x, 1}}.
    {move, {literal, [year, month, day, hour, minute, second, weekday]}, {x, 2}}.
    {call_last, 3, {f, 140}, 1}.
% The host timezone's offset from UTC at `epochMillis`, in minutes EAST of
% UTC (`+02:00` is `120`) — the sign RFC 3339 writes. Node's
% `getTimezoneOffset` counts minutes WEST, so the template negates it.
% Erlang: local minus universal time of the same instant. ERTS reads no
% local time before 1902 (`universaltime_to_localtime` is a `badarg`), so an
% earlier instant is read at 1902-01-01T00:00:00Z — the zone's offset there,
% its local mean time in most zones.

{function, offsetMinutes, 1, 21}.
  {label, 20}.
    {line, [{location, "std@io@clock.erl", 10}]}.
    {func_info, {atom, std@io@clock}, {atom, offsetMinutes}, 1}.
  {label, 21}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"offsetMinutes">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call, 2, {f, 13}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 151}, 1}.
% Internal: an `i32` read as an `i64` — std's `toI64()` (decision 319), which
% every `i32` fits, so no host cell is crossed.

{function, wide, 1, 23}.
  {label, 22}.
    {line, [{location, "std@io@clock.erl", 11}]}.
    {func_info, {atom, std@io@clock}, {atom, wide}, 1}.
  {label, 23}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 163}, 1}.

{function, millis, 1, 25}.
  {label, 24}.
    {line, [{location, "std@io@clock.erl", 12}]}.
    {func_info, {atom, std@io@clock}, {atom, millis}, 1}.
  {label, 25}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 23}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@clock@@Duration}, {x, 0}]}}.
    {deallocate, 1}.
    return.

{function, seconds, 1, 27}.
  {label, 26}.
    {line, [{location, "std@io@clock.erl", 13}]}.
    {func_info, {atom, std@io@clock}, {atom, seconds}, 1}.
  {label, 27}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 23}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 1000}, {x, 0}}.
    {call, 1, {f, 23}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 1}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 174}, [{x, 0}, {integer, -9223372036854775808}]}.
    {test, is_ge, {f, 174}, [{integer, 9223372036854775807}, {x, 0}]}.
    {jump, {f, 175}}.
  {label, 174}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i64 at src/io/clock.bp:239:37">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 175}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@clock@@Duration}, {x, 0}]}}.
    {deallocate, 3}.
    return.

{function, minutes, 1, 29}.
  {label, 28}.
    {line, [{location, "std@io@clock.erl", 14}]}.
    {func_info, {atom, std@io@clock}, {atom, minutes}, 1}.
  {label, 29}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 23}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 60000}, {x, 0}}.
    {call, 1, {f, 23}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 1}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 176}, [{x, 0}, {integer, -9223372036854775808}]}.
    {test, is_ge, {f, 176}, [{integer, 9223372036854775807}, {x, 0}]}.
    {jump, {f, 177}}.
  {label, 176}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i64 at src/io/clock.bp:243:37">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 177}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@clock@@Duration}, {x, 0}]}}.
    {deallocate, 3}.
    return.

{function, hours, 1, 31}.
  {label, 30}.
    {line, [{location, "std@io@clock.erl", 15}]}.
    {func_info, {atom, std@io@clock}, {atom, hours}, 1}.
  {label, 31}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 23}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 3600000}, {x, 0}}.
    {call, 1, {f, 23}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 1}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 178}, [{x, 0}, {integer, -9223372036854775808}]}.
    {test, is_ge, {f, 178}, [{integer, 9223372036854775807}, {x, 0}]}.
    {jump, {f, 179}}.
  {label, 178}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i64 at src/io/clock.bp:247:37">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 179}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@clock@@Duration}, {x, 0}]}}.
    {deallocate, 3}.
    return.

{function, add, 2, 33}.
  {label, 32}.
    {line, [{location, "std@io@clock.erl", 16}]}.
    {func_info, {atom, std@io@clock}, {atom, add}, 2}.
  {label, 33}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 180}, [{x, 0}, 2, {atom, std@io@clock@@Duration}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 180}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 181}, [{x, 0}, 2, {atom, std@io@clock@@Duration}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 181}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 183}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@clock@@Duration}, {x, 0}]}}.
    {deallocate, 2}.
    return.

{function, toMillis, 1, 35}.
  {label, 34}.
    {line, [{location, "std@io@clock.erl", 17}]}.
    {func_info, {atom, std@io@clock}, {atom, toMillis}, 1}.
  {label, 35}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 185}, [{x, 0}, 2, {atom, std@io@clock@@Duration}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 185}.
    {deallocate, 1}.
    return.
% ── 1.0.11-beta front 97: a duration written as text ────────────────────────
% Internal: the largest millisecond count `parseDuration` answers — 2^53 - 1
% (decision 498). A duration is handed on as a timer delay or a JSON number,
% both `f64`, which stop counting by one past 2^53; an `i64` itself is exact
% past it on every target (decision 319).

{function, largestExactMillis, 0, 37}.
  {label, 36}.
    {line, [{location, "std@io@clock.erl", 18}]}.
    {func_info, {atom, std@io@clock}, {atom, largestExactMillis}, 0}.
  {label, 37}.
    {allocate, 0, 0}.
    {move, {integer, 9007199254740991}, {x, 0}}.
    {deallocate, 0}.
    return.
% Internal: the unit `text` ends in — `ms` before `s`, since `5ms` ends in
% both — and `""` when it ends in none of the five.

{function, durationUnit, 1, 39}.
  {label, 38}.
    {line, [{location, "std@io@clock.erl", 19}]}.
    {func_info, {atom, std@io@clock}, {atom, durationUnit}, 1}.
  {label, 39}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"ms">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 188}}.
    {test, is_eq, {f, 186}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"ms">>}, {x, 0}}.
    {jump, {f, 202}}.
  {label, 186}.
    {move, {literal, <<"s">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 188}}.
    {test, is_eq, {f, 203}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"s">>}, {x, 0}}.
    {jump, {f, 204}}.
  {label, 203}.
    {move, {literal, <<"m">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 188}}.
    {test, is_eq, {f, 205}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"m">>}, {x, 0}}.
    {jump, {f, 206}}.
  {label, 205}.
    {move, {literal, <<"h">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 188}}.
    {test, is_eq, {f, 207}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"h">>}, {x, 0}}.
    {jump, {f, 208}}.
  {label, 207}.
    {move, {literal, <<"d">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 188}}.
    {test, is_eq, {f, 209}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"d">>}, {x, 0}}.
    {jump, {f, 210}}.
  {label, 209}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 210}.
  {label, 208}.
  {label, 206}.
  {label, 204}.
  {label, 202}.
    {deallocate, 1}.
    return.
% Internal: the milliseconds of one `unit` of `durationUnit`.

{function, unitMillis, 1, 41}.
  {label, 40}.
    {line, [{location, "std@io@clock.erl", 20}]}.
    {func_info, {atom, std@io@clock}, {atom, unitMillis}, 1}.
  {label, 41}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"ms">>}, {x, 0}}.
    {test, is_eq_exact, {f, 211}, [{y, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {call, 1, {f, 23}}.
    {jump, {f, 212}}.
  {label, 211}.
    {move, {literal, <<"s">>}, {x, 0}}.
    {test, is_eq_exact, {f, 213}, [{y, 0}, {x, 0}]}.
    {move, {integer, 1000}, {x, 0}}.
    {call, 1, {f, 23}}.
    {jump, {f, 214}}.
  {label, 213}.
    {move, {literal, <<"m">>}, {x, 0}}.
    {test, is_eq_exact, {f, 215}, [{y, 0}, {x, 0}]}.
    {move, {integer, 60000}, {x, 0}}.
    {call, 1, {f, 23}}.
    {jump, {f, 216}}.
  {label, 215}.
    {move, {literal, <<"h">>}, {x, 0}}.
    {test, is_eq_exact, {f, 217}, [{y, 0}, {x, 0}]}.
    {move, {integer, 3600000}, {x, 0}}.
    {call, 1, {f, 23}}.
    {jump, {f, 218}}.
  {label, 217}.
    {move, {integer, 86400000}, {x, 0}}.
    {call, 1, {f, 23}}.
  {label, 218}.
  {label, 216}.
  {label, 214}.
  {label, 212}.
    {deallocate, 1}.
    return.

{function, durationProblem, 2, 43}.
  {label, 42}.
    {line, [{location, "std@io@clock.erl", 21}]}.
    {func_info, {atom, std@io@clock}, {atom, durationProblem}, 2}.
  {label, 43}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"\" ">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"clock.parseDuration: \"">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 74}, 3}.
% Internal: the count `digits` spells — digits `0`–`9` only, no sign — or
% `-1` when it is not that and `-2` when it is but is beyond 2^53 - 1.

{function, durationCount, 1, 45}.
  {label, 44}.
    {line, [{location, "std@io@clock.erl", 22}]}.
    {func_info, {atom, std@io@clock}, {atom, durationCount}, 1}.
  {label, 45}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"+">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 219}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 220}}.
  {label, 219}.
    {move, {atom, true}, {x, 0}}.
  {label, 220}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 221}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"-">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 223}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 224}}.
  {label, 223}.
    {move, {atom, true}, {x, 0}}.
  {label, 224}.
    {jump, {f, 222}}.
  {label, 221}.
    {move, {atom, true}, {x, 0}}.
  {label, 222}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq, {f, 225}, [{x, 0}, {atom, true}]}.
    {gc_bif, '-', {f, 0}, 0, [{integer, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 226}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 226}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 227}}.
  {label, 226}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/io/clock.bp:307:31">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 227}.
    {call_last, 1, {f, 23}, 6}.
  {label, 225}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 229}}.
    {test, is_tagged_tuple, {f, 231}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {jump, {f, 230}}.
  {label, 231}.
    {test, is_tagged_tuple, {f, 232}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 3}}.
    {move, {literal, <<"is out of range">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 3}, {x, 0}}.
    {call, 2, {f, 188}}.
    {test, is_eq, {f, 233}, [{x, 0}, {atom, true}]}.
    {gc_bif, '-', {f, 0}, 0, [{integer, 0}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 235}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 235}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 236}}.
  {label, 235}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/io/clock.bp:311:55">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 236}.
    {jump, {f, 234}}.
  {label, 233}.
    {gc_bif, '-', {f, 0}, 0, [{integer, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 237}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 237}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 238}}.
  {label, 237}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/io/clock.bp:311:66">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 238}.
  {label, 234}.
    {call, 1, {f, 23}}.
    {jump, {f, 230}}.
  {label, 232}.
    {case_end, {x, 0}}.
  {label, 230}.
    {deallocate, 6}.
    return.
% The milliseconds a duration spells: digits, then ONE unit — `ms`, `s`, `m`
% (minutes), `h` or `d` — and nothing else: `"30s"` is `30000`, `"250ms"` is
% `250`, `"0s"` is `0`. Refused, as an `Error` naming the text: no unit
% (`"30"`), a fraction (`"1.5s"`), a sign, whitespace anywhere (`"30 s"`), an
% uppercase unit (`"30S"`), two units (`"1h30m"`), the empty string — the
% stricter of the two parsers this replaces — and a duration beyond
% 2^53 - 1 milliseconds, which a timer delay or a JSON number (an `f64`)
% would not hold exactly (decision 498).

{function, parseDuration, 1, 47}.
  {label, 46}.
    {line, [{location, "std@io@clock.erl", 23}]}.
    {func_info, {atom, std@io@clock}, {atom, parseDuration}, 1}.
  {label, 47}.
    {allocate, 19, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 39}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 242}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 242}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 2}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 243}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 243}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 244}}.
  {label, 243}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/io/clock.bp:326:46">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 244}.
    {move, {integer, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 240}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 245}, [{y, 1}, {x, 0}]}.
    {gc_bif, '-', {f, 0}, 0, [{integer, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 247}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 247}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 248}}.
  {label, 247}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/io/clock.bp:327:40">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 248}.
    {call, 1, {f, 23}}.
    {jump, {f, 246}}.
  {label, 245}.
    {move, {y, 3}, {x, 0}}.
    {call, 1, {f, 45}}.
  {label, 246}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, '-', {f, 0}, 0, [{integer, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 250}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 250}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 251}}.
  {label, 250}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/io/clock.bp:328:25">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 251}.
    {call, 1, {f, 23}}.
    {test, is_eq_exact, {f, 249}, [{y, 4}, {x, 0}]}.
    {move, {literal, <<"is not a duration: digits, then one unit of ms, s, m, h or d">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 43}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 19}.
    return.
  {label, 249}.
    {gc_bif, '-', {f, 0}, 0, [{integer, 0}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 253}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 253}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 254}}.
  {label, 253}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/io/clock.bp:333:25">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 254}.
    {call, 1, {f, 23}}.
    {test, is_eq_exact, {f, 252}, [{y, 4}, {x, 0}]}.
    {move, {literal, <<"is out of range">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 43}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 19}.
    return.
  {label, 252}.
    {call, 0, {f, 37}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 41}}.
    {test, is_ne_exact, {f, 256}, [{x, 0}, {integer, 0}]}.
    {jump, {f, 257}}.
  {label, 256}.
    {move, {literal, {panic, <<"integer division by zero: / on i64 at src/io/clock.bp:336:38">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 257}.
    {gc_bif, 'div', {f, 0}, 1, [{y, 5}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 258}, [{x, 0}, {integer, -9223372036854775808}]}.
    {test, is_ge, {f, 258}, [{integer, 9223372036854775807}, {x, 0}]}.
    {jump, {f, 259}}.
  {label, 258}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i64 at src/io/clock.bp:336:38">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 259}.
    {test, is_lt, {f, 255}, [{x, 0}, {y, 4}]}.
    {move, {literal, <<"is out of range">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 43}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 19}.
    return.
  {label, 255}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 41}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 4}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 260}, [{x, 0}, {integer, -9223372036854775808}]}.
    {test, is_ge, {f, 260}, [{integer, 9223372036854775807}, {x, 0}]}.
    {jump, {f, 261}}.
  {label, 260}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i64 at src/io/clock.bp:338:18">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 261}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 19}.
    return.
% Block the caller for `ms` milliseconds.
% Node: `Atomics.wait` on a scratch `SharedArrayBuffer` — a synchronous
% sleep that parks the thread instead of spinning (the value never
% changes, so the wait always times out).
% Erlang: `timer:sleep/1` — parks the calling process only.

{function, sleep, 1, 61}.
  {label, 60}.
    {line, [{location, "std@io@clock.erl", 24}]}.
    {func_info, {atom, std@io@clock}, {atom, sleep}, 1}.
  {label, 61}.
    {call_only, 1, {f, 55}}.
% The epoch reading `d` from now. A deadline is an absolute wall-clock
% value, so it survives being handed to another process (a cache entry, a
% session).

{function, deadline, 1, 49}.
  {label, 48}.
    {line, [{location, "std@io@clock.erl", 25}]}.
    {func_info, {atom, std@io@clock}, {atom, deadline}, 1}.
  {label, 49}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 0, {f, 3}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 262}, [{x, 0}, 2, {atom, std@io@clock@@Duration}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 262}.
    {gc_bif, '+', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 263}, [{x, 0}, {integer, -9223372036854775808}]}.
    {test, is_ge, {f, 263}, [{integer, 9223372036854775807}, {x, 0}]}.
    {jump, {f, 264}}.
  {label, 263}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i64 at src/io/clock.bp:356:24">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 264}.
    {deallocate, 1}.
    return.
% True once the wall clock has passed `at`.

{function, isExpired, 1, 51}.
  {label, 50}.
    {line, [{location, "std@io@clock.erl", 26}]}.
    {func_info, {atom, std@io@clock}, {atom, isExpired}, 1}.
  {label, 51}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 0, {f, 3}}.
    {test, is_lt, {f, 265}, [{y, 0}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 266}}.
  {label, 265}.
    {move, {atom, false}, {x, 0}}.
  {label, 266}.
    {deallocate, 1}.
    return.
% ── tests ────────────────────────────────────────────────────────────────────
% The `Error` of `parseDuration(text)`, `""` when it parsed.

{function, durationRefusal, 1, 53}.
  {label, 52}.
    {line, [{location, "std@io@clock.erl", 27}]}.
    {func_info, {atom, std@io@clock}, {atom, durationRefusal}, 1}.
  {label, 53}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 47}}.
    {test, is_tagged_tuple, {f, 268}, [{x, 0}, 2, {atom, ok}]}.
    {move, {literal, <<"">>}, {x, 0}}.
    {jump, {f, 267}}.
  {label, 268}.
    {test, is_tagged_tuple, {f, 269}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {jump, {f, 267}}.
  {label, 269}.
    {case_end, {x, 0}}.
  {label, 267}.
    {deallocate, 2}.
    return.

{function, 'string_parseInt', 1, 229}.
  {label, 228}.
    {line, [{location, "std@io@clock.erl", 28}]}.
    {func_info, {atom, std@io@clock}, {atom, 'string_parseInt'}, 1}.
  {label, 229}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"-">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 270}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 271}}.
  {label, 270}.
    {move, {atom, true}, {x, 0}}.
  {label, 271}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 272}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"+">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 274}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 275}}.
  {label, 274}.
    {move, {atom, true}, {x, 0}}.
  {label, 275}.
    {jump, {f, 273}}.
  {label, 272}.
    {move, {atom, true}, {x, 0}}.
  {label, 273}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq, {f, 276}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call, 2, {f, 279}}.
    {jump, {f, 277}}.
  {label, 276}.
    {move, {y, 0}, {x, 0}}.
  {label, 277}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call, 1, {f, 297}}.
    {test, is_eq, {f, 295}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 316}}.
    {jump, {f, 314}}.
  {label, 295}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 334}}.
  {label, 314}.
    {deallocate, 5}.
    return.

{function, 'string_slice', 3, 240}.
  {label, 239}.
    {line, [{location, "std@io@clock.erl", 29}]}.
    {func_info, {atom, std@io@clock}, {atom, 'string_slice'}, 3}.
  {label, 240}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test, is_ne_exact, {f, 339}, [{y, 2}, {atom, undefined}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 3, {f, 341}, 3}.
  {label, 339}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 2, {f, 279}, 3}.

{function, '__bp_priv__string_parseInt', 1, 363}.
  {label, 362}.
    {line, [{location, "std@io@clock.erl", 30}]}.
    {func_info, {atom, std@io@clock}, {atom, '__bp_priv__string_parseInt'}, 1}.
  {label, 363}.
    {call_only, 1, {f, 229}}.

{function, '__bp_priv__string_slice', 3, 365}.
  {label, 364}.
    {line, [{location, "std@io@clock.erl", 31}]}.
    {func_info, {atom, std@io@clock}, {atom, '__bp_priv__string_slice'}, 3}.
  {label, 365}.
    {call_only, 3, {f, 240}}.

{function, '__bp_priv__checkRfc3339Domain', 2, 367}.
  {label, 366}.
    {line, [{location, "std@io@clock.erl", 32}]}.
    {func_info, {atom, std@io@clock}, {atom, '__bp_priv__checkRfc3339Domain'}, 2}.
  {label, 367}.
    {call_only, 2, {f, 13}}.

{function, '__bp_priv__durationCount', 1, 369}.
  {label, 368}.
    {line, [{location, "std@io@clock.erl", 33}]}.
    {func_info, {atom, std@io@clock}, {atom, '__bp_priv__durationCount'}, 1}.
  {label, 369}.
    {call_only, 1, {f, 45}}.

{function, '__bp_priv__durationProblem', 2, 371}.
  {label, 370}.
    {line, [{location, "std@io@clock.erl", 34}]}.
    {func_info, {atom, std@io@clock}, {atom, '__bp_priv__durationProblem'}, 2}.
  {label, 371}.
    {call_only, 2, {f, 43}}.

{function, '__bp_priv__durationRefusal', 1, 373}.
  {label, 372}.
    {line, [{location, "std@io@clock.erl", 35}]}.
    {func_info, {atom, std@io@clock}, {atom, '__bp_priv__durationRefusal'}, 1}.
  {label, 373}.
    {call_only, 1, {f, 53}}.

{function, '__bp_priv__durationUnit', 1, 375}.
  {label, 374}.
    {line, [{location, "std@io@clock.erl", 36}]}.
    {func_info, {atom, std@io@clock}, {atom, '__bp_priv__durationUnit'}, 1}.
  {label, 375}.
    {call_only, 1, {f, 39}}.

{function, '__bp_priv__earliestRfc3339Millis', 0, 377}.
  {label, 376}.
    {line, [{location, "std@io@clock.erl", 37}]}.
    {func_info, {atom, std@io@clock}, {atom, '__bp_priv__earliestRfc3339Millis'}, 0}.
  {label, 377}.
    {call_only, 0, {f, 9}}.

{function, '__bp_priv__largestExactMillis', 0, 379}.
  {label, 378}.
    {line, [{location, "std@io@clock.erl", 38}]}.
    {func_info, {atom, std@io@clock}, {atom, '__bp_priv__largestExactMillis'}, 0}.
  {label, 379}.
    {call_only, 0, {f, 37}}.

{function, '__bp_priv__latestRfc3339Millis', 0, 381}.
  {label, 380}.
    {line, [{location, "std@io@clock.erl", 39}]}.
    {func_info, {atom, std@io@clock}, {atom, '__bp_priv__latestRfc3339Millis'}, 0}.
  {label, 381}.
    {call_only, 0, {f, 11}}.

{function, '__bp_priv__unitMillis', 1, 383}.
  {label, 382}.
    {line, [{location, "std@io@clock.erl", 40}]}.
    {func_info, {atom, std@io@clock}, {atom, '__bp_priv__unitMillis'}, 1}.
  {label, 383}.
    {call_only, 1, {f, 41}}.

{function, '__bp_priv__wide', 1, 385}.
  {label, 384}.
    {line, [{location, "std@io@clock.erl", 41}]}.
    {func_info, {atom, std@io@clock}, {atom, '__bp_priv__wide'}, 1}.
  {label, 385}.
    {call_only, 1, {f, 23}}.

{function, '__bp_tpl_0-t/1-fun-0-', 1, 59}.
  {label, 58}.
    {func_info, {atom, std@io@clock}, {atom, '__bp_tpl_0-t/1-fun-0-'}, 1}.
  {label, 59}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, timer, sleep, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_0', 1, 55}.
  {label, 54}.
    {func_info, {atom, std@io@clock}, {atom, '__bp_tpl_0'}, 1}.
  {label, 55}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 59}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_1', 1, 63}.
  {label, 62}.
    {func_info, {atom, std@io@clock}, {atom, '__bp_tpl_1'}, 1}.
  {label, 63}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {literal, [{unit, millisecond}, {offset, [90]}]}, {x, 1}}.
    {call_ext, 2, {extfunc, calendar, system_time_to_rfc3339, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, list_to_binary, 1}, 2}.

{function, '__bp_tpl_2', 1, 72}.
  {label, 71}.
    {func_info, {atom, std@io@clock}, {atom, '__bp_tpl_2'}, 1}.
  {label, 72}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, panic}, {y, 0}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 2}.

{function, '__bp_print', 1, 76}.
  {label, 75}.
    {line, [{location, "std@io@clock.erl", 7}]}.
    {func_info, {atom, std@io@clock}, {atom, '__bp_print'}, 1}.
  {label, 76}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 80}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 80}.
  {label, 79}.
    {line, [{location, "std@io@clock.erl", 7}]}.
    {func_info, {atom, std@io@clock}, {atom, '-bp_show_top-'}, 1}.
  {label, 80}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 78}}.

{function, '-bp_show_elem-', 1, 82}.
  {label, 81}.
    {line, [{location, "std@io@clock.erl", 7}]}.
    {func_info, {atom, std@io@clock}, {atom, '-bp_show_elem-'}, 1}.
  {label, 82}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 78}}.

{function, '__bp_show', 2, 78}.
  {label, 77}.
    {line, [{location, "std@io@clock.erl", 7}]}.
    {func_info, {atom, std@io@clock}, {atom, '__bp_show'}, 2}.
  {label, 78}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 90}, [{x, 0}]}.
    {test, is_eq, {f, 89}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 89}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 90}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 91}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 82}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 93}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 91}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 91}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 93}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 92}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 92}, [{x, 0}]}.
    {test, is_ne_exact, {f, 92}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 92}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 92}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 97}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 98}}.
  {label, 97}.
    {test, is_eq_exact, {f, 94}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 98}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 78}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 92}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 82}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 40}, {x, 0}, {x, 0}}.
    {put_list, {integer, 35}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 93}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 95}, [{x, 0}]}.
    {test, is_ne_exact, {f, 95}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 95}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 96}, [{x, 0}, {atom, undefined}]}.
  {label, 94}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 84}, 2}.
  {label, 95}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 96}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 84}.
  {label, 83}.
    {line, [{location, "std@io@clock.erl", 7}]}.
    {func_info, {atom, std@io@clock}, {atom, '__bp_tagged'}, 2}.
  {label, 84}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 99}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 99}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 99}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 100}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 86}, 3}.
  {label, 100}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 86}.
  {label, 85}.
    {line, [{location, "std@io@clock.erl", 7}]}.
    {func_info, {atom, std@io@clock}, {atom, '__bp_render'}, 1}.
  {label, 86}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 101}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 101}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 102}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 102}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 88}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {y, 1}, {x, 1}, {x, 1}}.
    {put_list, {integer, 40}, {x, 1}, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-bp_render_pair-', 1, 88}.
  {label, 87}.
    {line, [{location, "std@io@clock.erl", 7}]}.
    {func_info, {atom, std@io@clock}, {atom, '-bp_render_pair-'}, 1}.
  {label, 88}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 78}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 6, 1}.
    {put_list, {y, 1}, nil, {x, 1}}.
    {put_list, {literal, <<": ">>}, {x, 1}, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-bp_stringify-', 1, 104}.
  {label, 103}.
    {line, [{location, "std@io@clock.erl", 7}]}.
    {func_info, {atom, std@io@clock}, {atom, '-bp_stringify-'}, 1}.
  {label, 104}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 105}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 105}.
    {test, is_integer, {f, 106}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 106}.
    {call, 1, {f, 80}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.

{function, '-bp_join-', 2, 74}.
  {label, 73}.
    {line, [{location, "std@io@clock.erl", 7}]}.
    {func_info, {atom, std@io@clock}, {atom, '-bp_join-'}, 2}.
  {label, 74}.
    {allocate, 1, 2}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 104}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {call_ext_last, 1, {extfunc, erlang, iolist_to_binary, 1}, 1}.

{function, '__bp_tpl_3', 1, 111}.
  {label, 110}.
    {func_info, {atom, std@io@clock}, {atom, '__bp_tpl_3'}, 1}.
  {label, 111}.
    {allocate, 12, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 3}}.
    {'try', {y, 11}, {f, 114}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, binary_to_list, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {move, {literal, [{unit, millisecond}]}, {x, 1}}.
    {call_ext, 2, {extfunc, calendar, rfc3339_to_system_time, 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 6}}.
    {try_end, {y, 11}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 117}, [{x, 0}]}.
    {test, test_arity, {f, 117}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 117}, [{x, 0}, {atom, ok}]}.
    {move, {y, 8}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 116}}.
  {label, 117}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 118}, [{x, 0}]}.
    {test, test_arity, {f, 118}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 118}, [{x, 0}, {atom, error}]}.
    {move, {y, 8}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 9}, {literal, <<"host">>}, {atom, std@failure@@HostErrorName__v__error}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 116}}.
  {label, 118}.
    {move, {y, 6}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 4}}.
    {jump, {f, 116}}.
  {label, 116}.
    {jump, {f, 115}}.
  {label, 114}.
    {try_case, {y, 11}}.
    {move, {x, 0}, {y, 5}}.
    {move, {x, 1}, {y, 6}}.
    {move, {x, 2}, {y, 7}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 7}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 123}, [{x, 0}, {atom, error}]}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {y, 9}}.
    {jump, {f, 122}}.
  {label, 123}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 124}, [{x, 0}, {atom, throw}]}.
    {move, {atom, std@failure@@HostErrorName__v__throw}, {y, 9}}.
    {jump, {f, 122}}.
  {label, 124}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 125}, [{x, 0}, {atom, exit}]}.
    {move, {atom, std@failure@@HostErrorName__v__exit}, {y, 9}}.
    {jump, {f, 122}}.
  {label, 125}.
    {move, {y, 0}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 122}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 8}, {literal, <<"host">>}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 8}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 4}}.
    {jump, {f, 120}}.
  {label, 120}.
  {label, 115}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_tpl_4-t/1-fun-0-', 1, 134}.
  {label, 133}.
    {func_info, {atom, std@io@clock}, {atom, '__bp_tpl_4-t/1-fun-0-'}, 1}.
  {label, 134}.
    {allocate, 16, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}]}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {atom, millisecond}, {x, 1}}.
    {call_ext, 2, {extfunc, calendar, system_time_to_universal_time, 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tuple, {f, 137}, [{x, 0}]}.
    {test, test_arity, {f, 137}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 8}}.
    {get_tuple_element, {x, 0}, 1, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tuple, {f, 137}, [{x, 0}]}.
    {test, test_arity, {f, 137}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 10}}.
    {get_tuple_element, {x, 0}, 1, {y, 11}}.
    {get_tuple_element, {x, 0}, 2, {y, 12}}.
    {move, {y, 10}, {y, 0}}.
    {move, {y, 11}, {y, 1}}.
    {move, {y, 12}, {y, 2}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_tuple, {f, 137}, [{x, 0}]}.
    {test, test_arity, {f, 137}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 13}}.
    {get_tuple_element, {x, 0}, 1, {y, 14}}.
    {get_tuple_element, {x, 0}, 2, {y, 15}}.
    {move, {y, 13}, {y, 3}}.
    {move, {y, 14}, {y, 4}}.
    {move, {y, 15}, {y, 5}}.
    {jump, {f, 138}}.
  {label, 137}.
    {move, {y, 7}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 138}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_ext, 3, {extfunc, calendar, day_of_the_week, 3}}.
    {move, {x, 0}, {y, 7}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{atom, year}, {y, 0}, {atom, month}, {y, 1}, {atom, day}, {y, 2}, {atom, hour}, {y, 3}, {atom, minute}, {y, 4}, {atom, second}, {y, 5}, {atom, weekday}, {y, 7}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {deallocate, 16}.
    return.

{function, '__bp_tpl_4', 1, 130}.
  {label, 129}.
    {func_info, {atom, std@io@clock}, {atom, '__bp_tpl_4'}, 1}.
  {label, 130}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 134}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_adopt', 3, 140}.
  {label, 139}.
    {line, [{location, "std@io@clock.erl", 10}]}.
    {func_info, {atom, std@io@clock}, {atom, '__bp_adopt'}, 3}.
  {label, 140}.
    {test, is_map, {f, 145}, [{x, 0}]}.
    {allocate, 1, 3}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 142}}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, {x, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, list_to_tuple, 1}, 1}.
  {label, 145}.
    {test, is_list, {f, 146}, [{x, 0}]}.
    {call_only, 3, {f, 144}}.
  {label, 146}.
    {test, is_tagged_tuple, {f, 147}, [{x, 0}, 2, {atom, ok}]}.
    {allocate, 0, 3}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {call, 3, {f, 140}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 0}]}}.
    {deallocate, 0}.
    return.
  {label, 147}.
    return.

{function, '-bp_adopt_fields-', 2, 142}.
  {label, 141}.
    {line, [{location, "std@io@clock.erl", 10}]}.
    {func_info, {atom, std@io@clock}, {atom, '-bp_adopt_fields-'}, 2}.
  {label, 142}.
    {test, is_nonempty_list, {f, 148}, [{x, 0}]}.
    {allocate, 2, 2}.
    {move, {x, 1}, {y, 1}}.
    {get_list, {x, 0}, {x, 0}, {y, 0}}.
    {move, {atom, undefined}, {x, 2}}.
    {call_ext, 3, {extfunc, maps, get, 3}}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 142}}.
    {test_heap, 2, 1}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 148}.
    {move, nil, {x, 0}}.
    return.

{function, '-bp_adopt_each-', 3, 144}.
  {label, 143}.
    {line, [{location, "std@io@clock.erl", 10}]}.
    {func_info, {atom, std@io@clock}, {atom, '-bp_adopt_each-'}, 3}.
  {label, 144}.
    {test, is_nonempty_list, {f, 149}, [{x, 0}]}.
    {allocate, 3, 3}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {get_list, {x, 0}, {x, 0}, {y, 0}}.
    {call, 3, {f, 140}}.
    {move, {y, 0}, {x, 3}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call, 3, {f, 144}}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, {x, 0}, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 149}.
    {move, nil, {x, 0}}.
    return.

{function, '__bp_tpl_5-t/1-fun-0-', 1, 155}.
  {label, 154}.
    {func_info, {atom, std@io@clock}, {atom, '__bp_tpl_5-t/1-fun-0-'}, 1}.
  {label, 155}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, -2145916800000}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {move, {atom, millisecond}, {x, 1}}.
    {call_ext, 2, {extfunc, calendar, system_time_to_universal_time, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 159}}.
  {label, 159}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, calendar, universal_time_to_local_time, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 161}}.
  {label, 161}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, calendar, datetime_to_gregorian_seconds, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, calendar, datetime_to_gregorian_seconds, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {move, {integer, 60}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, 'div', 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 5}.
    return.

{function, '__bp_tpl_5', 1, 151}.
  {label, 150}.
    {func_info, {atom, std@io@clock}, {atom, '__bp_tpl_5'}, 1}.
  {label, 151}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 155}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_6-t/1-fun-0-', 1, 167}.
  {label, 166}.
    {func_info, {atom, std@io@clock}, {atom, '__bp_tpl_6-t/1-fun-0-'}, 1}.
  {label, 167}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, -9223372036854775807}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {gc_bif, '-', {f, 169}, 2, [{x, 0}, {x, 1}], {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test, is_ge, {f, 169}, [{x, 0}, {x, 1}]}.
    {move, {integer, 9223372036854775807}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test, is_ge, {f, 169}, [{x, 0}, {x, 1}]}.
    {jump, {f, 170}}.
  {label, 170}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 169}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_binary, {f, 172}, [{x, 0}]}.
    {test_heap, 6, 0}.
    {put_list, {literal, <<" does not fit i64">>}, nil, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {put_list, {literal, <<"toI64: ">>}, {x, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 173}}.
  {label, 172}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 173}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, integer_overflow}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 2}.

{function, '__bp_tpl_6', 1, 163}.
  {label, 162}.
    {func_info, {atom, std@io@clock}, {atom, '__bp_tpl_6'}, 1}.
  {label, 163}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 167}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_add', 2, 183}.
  {label, 182}.
    {line, [{location, "std@io@clock.erl", 17}]}.
    {func_info, {atom, std@io@clock}, {atom, '__bp_add'}, 2}.
  {label, 183}.
    {test, is_binary, {f, 184}, [{x, 0}]}.
    {test, is_binary, {f, 184}, [{x, 1}]}.
    {test_heap, 4, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call_ext_only, 1, {extfunc, erlang, iolist_to_binary, 1}}.
  {label, 184}.
    {gc_bif, '+', {f, 0}, 2, [{x, 0}, {x, 1}], {x, 0}}.
    return.

{function, '__bp_tpl_7-t/2-fun-0-', 2, 192}.
  {label, 191}.
    {func_info, {atom, std@io@clock}, {atom, '__bp_tpl_7-t/2-fun-0-'}, 2}.
  {label, 192}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, byte_size, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {jump, {f, 196}}.
  {label, 196}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, byte_size, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 1}}.
    {jump, {f, 198}}.
  {label, 198}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=<', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 199}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {move, {y, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, binary, part, 3}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 4}}.
    {jump, {f, 201}}.
  {label, 199}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 200}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 4}}.
    {jump, {f, 201}}.
  {label, 200}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 5}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 201}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 7}.
    return.

{function, '__bp_tpl_7', 2, 188}.
  {label, 187}.
    {func_info, {atom, std@io@clock}, {atom, '__bp_tpl_7'}, 2}.
  {label, 188}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 192}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_8', 1, 242}.
  {label, 241}.
    {func_info, {atom, std@io@clock}, {atom, '__bp_tpl_8'}, 1}.
  {label, 242}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, length, 1}, 2}.

{function, '__bp_tpl_9-t/2-fun-0-', 2, 283}.
  {label, 282}.
    {func_info, {atom, std@io@clock}, {atom, '__bp_tpl_9-t/2-fun-0-'}, 2}.
  {label, 283}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {jump, {f, 287}}.
  {label, 287}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 1}}.
    {jump, {f, 289}}.
  {label, 289}.
    {move, {y, 3}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 291}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 290}}.
  {label, 291}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 292}, [{x, 0}, {atom, false}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 290}}.
  {label, 292}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 290}.
    {move, {y, 5}, {y, 1}}.
    {jump, {f, 294}}.
  {label, 294}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 7}.

{function, '__bp_tpl_9', 2, 279}.
  {label, 278}.
    {func_info, {atom, std@io@clock}, {atom, '__bp_tpl_9'}, 2}.
  {label, 279}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 283}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_10--t/1-fun-0--fun-1-', 1, 308}.
  {label, 307}.
    {func_info, {atom, std@io@clock}, {atom, '__bp_tpl_10--t/1-fun-0--fun-1-'}, 1}.
  {label, 308}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 48}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '>=', 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 311}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 57}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=<', 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 313}}.
  {label, 311}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 312}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 1}}.
    {jump, {f, 313}}.
  {label, 312}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 2}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 313}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_10-t/1-fun-0-', 1, 301}.
  {label, 300}.
    {func_info, {atom, std@io@clock}, {atom, '__bp_tpl_10-t/1-fun-0-'}, 1}.
  {label, 301}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {literal, <<"">>}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 304}, [{x, 0}, {atom, true}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 308}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, binary_to_list, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, all, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 306}}.
  {label, 304}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 305}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 1}}.
    {jump, {f, 306}}.
  {label, 305}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 2}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 306}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 5}.
    return.

{function, '__bp_tpl_10', 1, 297}.
  {label, 296}.
    {func_info, {atom, std@io@clock}, {atom, '__bp_tpl_10'}, 1}.
  {label, 297}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 301}, 1, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_11-t/1-fun-0-', 1, 320}.
  {label, 319}.
    {func_info, {atom, std@io@clock}, {atom, '__bp_tpl_11-t/1-fun-0-'}, 1}.
  {label, 320}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, binary_to_integer, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {y, 0}}.
    {jump, {f, 324}}.
  {label, 324}.
    {move, {integer, -9223372036854775807}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '>=', 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 325}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 9223372036854775807}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=<', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 2}}.
    {jump, {f, 327}}.
  {label, 325}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 326}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 2}}.
    {jump, {f, 327}}.
  {label, 326}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 3}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 327}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 329}, [{x, 0}, {atom, true}]}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 329}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 330}, [{x, 0}, {atom, false}]}.
    {move, {y, 1}, {x, 0}}.
    {test, is_binary, {f, 331}, [{x, 0}]}.
    {test_heap, 10, 0}.
    {put_list, {literal, <<" is out of range">>}, nil, {x, 0}}.
    {put_list, {literal, <<"\"">>}, {x, 0}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {put_list, {literal, <<"\"">>}, {x, 0}, {x, 0}}.
    {put_list, {literal, <<"parseInt: ">>}, {x, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 332}}.
  {label, 331}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 332}.
    {move, {x, 0}, {y, 3}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 3}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 330}.
    {move, {y, 2}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_11', 1, 316}.
  {label, 315}.
    {func_info, {atom, std@io@clock}, {atom, '__bp_tpl_11'}, 1}.
  {label, 316}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 320}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_12', 1, 334}.
  {label, 333}.
    {func_info, {atom, std@io@clock}, {atom, '__bp_tpl_12'}, 1}.
  {label, 334}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 337}, [{x, 0}]}.
    {test_heap, 10, 0}.
    {put_list, {literal, <<" is not an integer">>}, nil, {x, 0}}.
    {put_list, {literal, <<"\"">>}, {x, 0}, {x, 0}}.
    {put_list, {y, 0}, {x, 0}, {x, 0}}.
    {put_list, {literal, <<"\"">>}, {x, 0}, {x, 0}}.
    {put_list, {literal, <<"parseInt: ">>}, {x, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 338}}.
  {label, 337}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 338}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_13-t/3-fun-0-', 3, 345}.
  {label, 344}.
    {func_info, {atom, std@io@clock}, {atom, '__bp_tpl_13-t/3-fun-0-'}, 3}.
  {label, 345}.
    {allocate, 9, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {move, {x, 2}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 0}}.
    {jump, {f, 349}}.
  {label, 349}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 1}}.
    {jump, {f, 351}}.
  {label, 351}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 353}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 352}}.
  {label, 353}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 354}, [{x, 0}, {atom, false}]}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 352}}.
  {label, 354}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 352}.
    {move, {y, 7}, {y, 2}}.
    {jump, {f, 356}}.
  {label, 356}.
    {move, {y, 5}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 358}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 357}}.
  {label, 358}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 359}, [{x, 0}, {atom, false}]}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 357}}.
  {label, 359}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 357}.
    {move, {y, 7}, {y, 1}}.
    {jump, {f, 361}}.
  {label, 361}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {move, {y, 7}, {x, 2}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 9}.

{function, '__bp_tpl_13', 3, 341}.
  {label, 340}.
    {func_info, {atom, std@io@clock}, {atom, '__bp_tpl_13'}, 3}.
  {label, 341}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 345}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 3}, {x, 3}}.
    {call_fun, 3}.
    {deallocate, 4}.
    return.
