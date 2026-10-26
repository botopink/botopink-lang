-module(std@io@clock).
-export([nowMillis/0, monotonicMillis/0, formatIso8601/1, measureMillis/1, parseIso8601/1, toCivil/1, offsetMinutes/1, millis/1, seconds/1, minutes/1, hours/1, add/2, toMillis/1, parseDuration/1, deadline/1, isExpired/1, sleep/1, '__bp_priv__earliestRfc3339Millis'/0, '__bp_priv__latestRfc3339Millis'/0, '__bp_priv__checkRfc3339Domain'/2, '__bp_priv__wide'/1, '__bp_priv__largestExactMillis'/0, '__bp_priv__durationUnit'/1, '__bp_priv__unitMillis'/1, '__bp_priv__durationProblem'/2, '__bp_priv__durationCount'/1, '__bp_priv__durationRefusal'/1, '__bp_priv__string_parseInt'/1, '__bp_priv__string_slice'/3]).

%% behavior string

%% behavior bool

%% behavior Integer

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

%% external fn systemTimeWithUnit -> erlang template

% Milliseconds since the Unix epoch. Monotonic across reasonable clock

% drift on every backend; not adjusted for leap seconds.

nowMillis() ->
    erlang:system_time(1000).

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

%% external fn monotonicTimeWithUnit -> erlang template

% Monotonic milliseconds — the host's monotonic clock, suitable for

% elapsed-time measurements (use `nowMillis()` for the wall clock).

% Two consecutive `monotonicMillis()` reads on the same backend are

% non-decreasing; the relative scale matches `nowMillis()` (millisecond

% units). On Node the absolute origin is the Unix epoch (`Date.now()`)

% until §A2 wires `performance.now()`; on Erlang it is the host's

% monotonic origin (`erlang:monotonic_time/1`).

monotonicMillis() ->
    erlang:monotonic_time(1000).

% Render `epochMillis` as an ISO-8601 / RFC-3339 timestamp string.

% Node: `new Date($0).toISOString()` (renders `YYYY-MM-DDTHH:MM:SS.sssZ`).

% Erlang: `calendar:system_time_to_rfc3339/2` with the `millisecond` unit and

% the `Z` offset on the millis as they are (decision 849): milliseconds are

% always written, `YYYY-MM-DDTHH:MM:SS.sssZ`, as Node's are. The `Z` offset keeps

% `calendar` from reading the host's local time, which ERTS refuses before 1902.

% Its domain is RFC 3339's (decision 497): past it the call aborts,

% naming the value, on every target (`checkRfc3339Domain`).

%% external fn formatIso8601Host -> erlang template

formatIso8601(EpochMillis) ->
    checkRfc3339Domain(<<"formatIso8601">>, EpochMillis),
    list_to_binary(calendar:system_time_to_rfc3339(EpochMillis, [{unit, millisecond}, {offset, "Z"}])).

% The domain of `formatIso8601`, `toCivil` and `offsetMinutes` (decision

% 497): the epochs RFC 3339 writes, 0000-01-01T00:00:00Z …

% 9999-12-31T23:59:59.999Z, the same on every target. ECMAScript's `Date`

% holds a wider range and Erlang's `calendar` a different one, so the bound

% is checked here, before the host is reached.

earliestRfc3339Millis() ->
    (-62167219200000).

latestRfc3339Millis() ->
    253402300799999.

% Internal: abort when `epochMillis` is past RFC 3339's domain, naming the

% function and the value.

checkRfc3339Domain(What, EpochMillis) ->
    case ((EpochMillis < earliestRfc3339Millis()) orelse (EpochMillis > latestRfc3339Millis())) of
        true ->
            erlang:error({panic, iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [<<"clock.">>, What, <<": ">>, erlang:integer_to_binary(EpochMillis), <<" is past RFC 3339's range, -62167219200000 to 253402300799999">>])))});
        _ -> ok
    end.

% Measure how long `body` takes to evaluate, in milliseconds. Returns

% the body's result paired with the elapsed time. Uses `nowMillis()`

% (the wall clock) rather than `monotonicMillis()` for cross-backend

% f64/i64 unifier symmetry — both readings are i64-typed, so the

% difference stays in the integer arithmetic path on every target.

measureMillis(Body) ->
    Start = nowMillis(),
    Result = Body(),
    Elapsed = '__bp_int'((nowMillis() - Start), -9223372036854775808, 9223372036854775807, <<"integer overflow: - on i64 at src/io/clock.bp:138:31">>),
    {Result, Elapsed}.

% ── 1.0.10-beta front 01 additions ──────────────────────────────────────────

% 

% Parsing, the civil breakdown, the host timezone offset, durations,

% deadlines and `sleep`. The readings above are not edited.

% A UTC calendar breakdown of an epoch reading. `month` is 1–12, `day`

% 1–31, `weekday` ISO-8601 (Monday = 1 … Sunday = 7).

%% type Civil: year, month, day, hour, minute, second, weekday

% A span of time in milliseconds. Built by `millis`/`seconds`/`minutes`/

% `hours`, combined by `add`, read back by `toMillis`.

%% type Duration: millis

%% import HostError

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

%% external fn parseIso8601Host -> erlang template

% What `parseIso8601` refuses (decision 486).

%% type ClockError
%%   NotRfc3339

parseIso8601(S) ->
    case (fun(__BpA0) -> try (calendar:rfc3339_to_system_time(binary_to_list(__BpA0), [{unit, millisecond}])) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(S) of
        {ok, V} ->
            {ok, V};
        {error, _} ->
            {error, std@io@clock@@ClockError__v__notrfc3339}
    end.

% The UTC civil breakdown of `epochMillis`.

% Node: the `getUTC*` readers of a `Date`; `getUTCDay` counts Sunday = 0,

% rotated to ISO (Monday = 1).

% Erlang: `calendar:system_time_to_universal_time/2` + `day_of_the_week/3`

% (already Monday = 1).

%% external fn toCivilHost -> erlang template

toCivil(EpochMillis) ->
    checkRfc3339Domain(<<"toCivil">>, EpochMillis),
    '__bp_adopt'((fun(__M) -> {{__Y, __Mo, __D}, {__H, __Mi, __S}} = calendar:system_time_to_universal_time(__M, millisecond), #{year => __Y, month => __Mo, day => __D, hour => __H, minute => __Mi, second => __S, weekday => calendar:day_of_the_week(__Y, __Mo, __D)} end)(EpochMillis), std@io@clock@@Civil, [year, month, day, hour, minute, second, weekday]).

% The host timezone's offset from UTC at `epochMillis`, in minutes EAST of

% UTC (`+02:00` is `120`) — the sign RFC 3339 writes. Node's

% `getTimezoneOffset` counts minutes WEST, so the template negates it.

% Erlang: local minus universal time of the same instant. ERTS reads no

% local time before 1902 (`universaltime_to_localtime` is a `badarg`), so an

% earlier instant is read at 1902-01-01T00:00:00Z — the zone's offset there,

% its local mean time in most zones.

%% external fn offsetMinutesHost -> erlang template

offsetMinutes(EpochMillis) ->
    checkRfc3339Domain(<<"offsetMinutes">>, EpochMillis),
    (fun(__M) -> __U = calendar:system_time_to_universal_time(erlang:max(__M, -2145916800000), millisecond), __L = calendar:universal_time_to_local_time(__U), (calendar:datetime_to_gregorian_seconds(__L) - calendar:datetime_to_gregorian_seconds(__U)) div 60 end)(EpochMillis).

% Internal: an `i32` read as an `i64` — std's `toI64()` (decision 319), which

% every `i32` fits, so no host cell is crossed.

wide(N) ->
    (fun(__V) when __V >= -9223372036854775807 - 1, __V =< 9223372036854775807 -> __V; (__V) -> erlang:error({integer_overflow, <<"toI64: ", (integer_to_binary(__V))/binary, " does not fit i64">>}) end)(N).

millis(N) ->
    {std@io@clock@@Duration, wide(N)}.

seconds(N) ->
    {std@io@clock@@Duration, '__bp_int'((wide(N) * wide(1000)), -9223372036854775808, 9223372036854775807, <<"integer overflow: * on i64 at src/io/clock.bp:239:37">>)}.

minutes(N) ->
    {std@io@clock@@Duration, '__bp_int'((wide(N) * wide(60000)), -9223372036854775808, 9223372036854775807, <<"integer overflow: * on i64 at src/io/clock.bp:243:37">>)}.

hours(N) ->
    {std@io@clock@@Duration, '__bp_int'((wide(N) * wide(3600000)), -9223372036854775808, 9223372036854775807, <<"integer overflow: * on i64 at src/io/clock.bp:247:37">>)}.

add(A, B) ->
    {std@io@clock@@Duration, '__bp_add'(erlang:element(2, A), erlang:element(2, B))}.

toMillis(D) ->
    erlang:element(2, D).

% ── 1.0.11-beta front 97: a duration written as text ────────────────────────

% Internal: the largest millisecond count `parseDuration` answers — 2^53 - 1

% (decision 498). A duration is handed on as a timer delay or a JSON number,

% both `f64`, which stop counting by one past 2^53; an `i64` itself is exact

% past it on every target (decision 319).

largestExactMillis() ->
    9007199254740991.

% Internal: the unit `text` ends in — `ms` before `s`, since `5ms` ends in

% both — and `""` when it ends in none of the five.

durationUnit(Text) ->
    case (fun(__S, __X) -> __N = byte_size(__S), __M = byte_size(__X), (__M =< __N) andalso (binary:part(__S, __N - __M, __M) =:= __X) end)(Text, <<"ms">>) of
        true ->
            <<"ms">>;
        false ->
            case (fun(__S, __X) -> __N = byte_size(__S), __M = byte_size(__X), (__M =< __N) andalso (binary:part(__S, __N - __M, __M) =:= __X) end)(Text, <<"s">>) of
                true ->
                    <<"s">>;
                false ->
                    case (fun(__S, __X) -> __N = byte_size(__S), __M = byte_size(__X), (__M =< __N) andalso (binary:part(__S, __N - __M, __M) =:= __X) end)(Text, <<"m">>) of
                        true ->
                            <<"m">>;
                        false ->
                            case (fun(__S, __X) -> __N = byte_size(__S), __M = byte_size(__X), (__M =< __N) andalso (binary:part(__S, __N - __M, __M) =:= __X) end)(Text, <<"h">>) of
                                true ->
                                    <<"h">>;
                                false ->
                                    case (fun(__S, __X) -> __N = byte_size(__S), __M = byte_size(__X), (__M =< __N) andalso (binary:part(__S, __N - __M, __M) =:= __X) end)(Text, <<"d">>) of
                                        true ->
                                            <<"d">>;
                                        false ->
                                            <<"">>
                                    end
                            end
                    end
            end
    end.

% Internal: the milliseconds of one `unit` of `durationUnit`.

unitMillis(Unit) ->
    case (Unit =:= <<"ms">>) of
        true ->
            wide(1);
        false ->
            case (Unit =:= <<"s">>) of
                true ->
                    wide(1000);
                false ->
                    case (Unit =:= <<"m">>) of
                        true ->
                            wide(60000);
                        false ->
                            case (Unit =:= <<"h">>) of
                                true ->
                                    wide(3600000);
                                false ->
                                    wide(86400000)
                            end
                    end
            end
    end.

durationProblem(Text, What) ->
    iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [<<"clock.parseDuration: \"">>, Text, <<"\" ">>, What]))).

% Internal: the count `digits` spells — digits `0`–`9` only, no sign — or

% `-1` when it is not that and `-2` when it is but is beyond 2^53 - 1.

durationCount(Digits) ->
    Signed = ((string:prefix(Digits, <<"+">>) =/= nomatch) orelse (string:prefix(Digits, <<"-">>) =/= nomatch)),
    case Signed of
        true ->
            wide('__bp_int'((0 - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/io/clock.bp:307:31">>));
        _ ->
            case string_parseInt(Digits) of
                {ok, N} ->
                    N;
                {error, Reason} ->
                    wide(case (fun(__S, __X) -> __N = byte_size(__S), __M = byte_size(__X), (__M =< __N) andalso (binary:part(__S, __N - __M, __M) =:= __X) end)(Reason, <<"is out of range">>) of
                        true ->
                            '__bp_int'((0 - 2), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/io/clock.bp:311:55">>);
                        false ->
                            '__bp_int'((0 - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/io/clock.bp:311:66">>)
                    end)
            end
    end.

% The milliseconds a duration spells: digits, then ONE unit — `ms`, `s`, `m`

% (minutes), `h` or `d` — and nothing else: `"30s"` is `30000`, `"250ms"` is

% `250`, `"0s"` is `0`. Refused, as an `Error` naming the text: no unit

% (`"30"`), a fraction (`"1.5s"`), a sign, whitespace anywhere (`"30 s"`), an

% uppercase unit (`"30S"`), two units (`"1h30m"`), the empty string — the

% stricter of the two parsers this replaces — and a duration beyond

% 2^53 - 1 milliseconds, which a timer delay or a JSON number (an `f64`)

% would not hold exactly (decision 498).

parseDuration(Text) ->
    Unit = durationUnit(Text),
    Digits = string_slice(Text, 0, '__bp_int'((erlang:length(unicode:characters_to_list(Text)) - erlang:length(unicode:characters_to_list(Unit))), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/io/clock.bp:326:46">>)),
    Count = case (Unit =:= <<"">>) of
        true ->
            wide('__bp_int'((0 - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/io/clock.bp:327:40">>));
        false ->
            durationCount(Digits)
    end,
    case (Count =:= wide('__bp_int'((0 - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/io/clock.bp:328:25">>))) of
        true ->
            {error, durationProblem(Text, <<"is not a duration: digits, then one unit of ms, s, m, h or d">>)};
        _ ->
            case (Count =:= wide('__bp_int'((0 - 2), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/io/clock.bp:333:25">>))) of
                true ->
                    {error, durationProblem(Text, <<"is out of range">>)};
                _ ->
                    % Compared before multiplying: a count as long as `i64` allows would
                    % overflow the product, which aborts the program, never answers.
                    case (Count > '__bp_int'((largestExactMillis() div '__bp_nz'(unitMillis(Unit), <<"integer division by zero: / on i64 at src/io/clock.bp:336:38">>)), -9223372036854775808, 9223372036854775807, <<"integer overflow: / on i64 at src/io/clock.bp:336:38">>)) of
                        true ->
                            {error, durationProblem(Text, <<"is out of range">>)};
                        _ ->
                            {ok, '__bp_int'((Count * unitMillis(Unit)), -9223372036854775808, 9223372036854775807, <<"integer overflow: * on i64 at src/io/clock.bp:338:18">>)}
                    end
            end
    end.

% Block the caller for `ms` milliseconds.

% Node: `Atomics.wait` on a scratch `SharedArrayBuffer` — a synchronous

% sleep that parks the thread instead of spinning (the value never

% changes, so the wait always times out).

% Erlang: `timer:sleep/1` — parks the calling process only.

%% external fn sleep -> erlang template
sleep(Ms) ->
    (fun(__T) -> timer:sleep(__T), undefined end)(Ms).

% The epoch reading `d` from now. A deadline is an absolute wall-clock

% value, so it survives being handed to another process (a cache entry, a

% session).

deadline(D) ->
    '__bp_int'((nowMillis() + erlang:element(2, D)), -9223372036854775808, 9223372036854775807, <<"integer overflow: + on i64 at src/io/clock.bp:356:24">>).

% True once the wall clock has passed `at`.

isExpired(At) ->
    (nowMillis() > At).

% ── tests ────────────────────────────────────────────────────────────────────












% The `Error` of `parseDuration(text)`, `""` when it parsed.

durationRefusal(Text) ->
    case parseDuration(Text) of
        {ok, _} ->
            <<"">>;
        {error, Reason} ->
            Reason
    end.






string_parseInt(Self) ->
    Signed = ((string:prefix(Self, <<"-">>) =/= nomatch) orelse (string:prefix(Self, <<"+">>) =/= nomatch)),
    Digits = case Signed of
        true ->
            (fun(__S, __A) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __B = case __A < 0 of true -> erlang:max(__N + __A, 0); false -> erlang:min(__A, __N) end, unicode:characters_to_binary(lists:nthtail(__B, __L)) end)(Self, 1);
        false ->
            Self
    end,
    case (fun(__S) -> (__S =/= <<>>) andalso lists:all(fun(__C) -> (__C >= 48) andalso (__C =< 57) end, binary_to_list(__S)) end)(Digits) of
        true ->
            (fun(__S) -> __N = binary_to_integer(__S), case (__N >= -9223372036854775807 - 1) andalso (__N =< 9223372036854775807) of true -> {ok, __N}; false -> {error, <<"parseInt: ", 34, __S/binary, 34, " is out of range">>} end end)(Self);
        false ->
            {error, <<"parseInt: ", 34, (Self)/binary, 34, " is not an integer">>}
    end.

string_slice(Self, Start, End) ->
    case (End =/= undefined) of
        true ->
            (fun(__S, __A, __E) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __B = case __A < 0 of true -> erlang:max(__N + __A, 0); false -> erlang:min(__A, __N) end, __F = case __E < 0 of true -> erlang:max(__N + __E, 0); false -> erlang:min(__E, __N) end, unicode:characters_to_binary(lists:sublist(__L, __B + 1, erlang:max(__F - __B, 0))) end)(Self, Start, End);
        false ->
            (fun(__S, __A) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __B = case __A < 0 of true -> erlang:max(__N + __A, 0); false -> erlang:min(__A, __N) end, unicode:characters_to_binary(lists:nthtail(__B, __L)) end)(Self, Start)
    end.

'__bp_add'(A, B) when erlang:is_binary(A), erlang:is_binary(B) -> <<A/binary, B/binary>>;
'__bp_add'(A, B) -> A + B.

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

-compile({inline,['__bp_nz'/2]}).
'__bp_nz'(B, What) when B == 0 -> erlang:error({panic, What});
'__bp_nz'(B, _) -> B.

'__bp_adopt'(V, T, Ks) when erlang:is_map(V) -> erlang:list_to_tuple([T | [maps:get(K, V, undefined) || K <- Ks]]);
'__bp_adopt'(V, T, Ks) when erlang:is_list(V) -> ['__bp_adopt'(E, T, Ks) || E <- V];
'__bp_adopt'({ok, V}, T, Ks) -> {ok, '__bp_adopt'(V, T, Ks)};
'__bp_adopt'(V, _, _) -> V.

'__bp_priv__earliestRfc3339Millis'() -> earliestRfc3339Millis().

'__bp_priv__latestRfc3339Millis'() -> latestRfc3339Millis().

'__bp_priv__checkRfc3339Domain'(A0, A1) -> checkRfc3339Domain(A0, A1).

'__bp_priv__wide'(A0) -> wide(A0).

'__bp_priv__largestExactMillis'() -> largestExactMillis().

'__bp_priv__durationUnit'(A0) -> durationUnit(A0).

'__bp_priv__unitMillis'(A0) -> unitMillis(A0).

'__bp_priv__durationProblem'(A0, A1) -> durationProblem(A0, A1).

'__bp_priv__durationCount'(A0) -> durationCount(A0).

'__bp_priv__durationRefusal'(A0) -> durationRefusal(A0).

'__bp_priv__string_parseInt'(A0) -> string_parseInt(A0).

'__bp_priv__string_slice'(A0, A1, A2) -> string_slice(A0, A1, A2).
