-module(std@math).
-compile({no_auto_import,[abs/1, floor/1, round/1, trunc/1, ceil/1]}).
-export([ceil/1, sign/1, clamp/3, pow/2, cbrt/1, exp/1, ln/1, log2/1, log10/1, hypot/2, sin/1, cos/1, tan/1, asin/1, acos/1, atan/1, atan2/2, sinh/1, cosh/1, tanh/1, pi/0, e/0, tau/0, sqrt2/0, ln2/0, ln10/0, log2e/0, log10e/0, abs/1, floor/1, round/1, trunc/1, minF/2, maxF/2, sqrt/1, '__bp_priv__roundHalfUp'/1, '__bp_priv__timesHuge'/2, '__bp_priv__twoTo'/1, '__bp_priv__exponentOf'/1, '__bp_priv__subnormalBits'/1, '__bp_priv__highWord'/1, '__bp_priv__lowWord'/1, '__bp_priv__fromWords'/2, '__bp_priv__withLowZero'/1, '__bp_priv__signBit'/1, '__bp_priv__isZero'/1, '__bp_priv__exponentField'/1, '__bp_priv__expBody'/1, '__bp_priv__expm1Body'/1, '__bp_priv__logSpecial'/1, '__bp_priv__logScaled'/2, '__bp_priv__logMantissaBits'/1, '__bp_priv__lnBody'/1, '__bp_priv__logOnePlusTail'/1, '__bp_priv__log2Body'/1, '__bp_priv__log10Body'/1, '__bp_priv__sumError'/3, '__bp_priv__productError'/3, '__bp_priv__unitInFirstPlace'/1, '__bp_priv__sumRoundedToOdd'/2, '__bp_priv__fusedMultiplyAdd'/3, '__bp_priv__wholeKind'/1, '__bp_priv__powBody'/2, '__bp_priv__powExp'/3, '__bp_priv__powInvc'/1, '__bp_priv__powLogc'/1, '__bp_priv__powLogctail'/1, '__bp_priv__expHead'/1, '__bp_priv__expTail'/1, '__bp_priv__remPio2'/2, '__bp_priv__kernelCos'/2, '__bp_priv__kernelSin'/3, '__bp_priv__kernelTan'/3, '__bp_priv__quadrantOf'/1, '__bp_priv__sinBody'/1, '__bp_priv__cosBody'/1, '__bp_priv__tanBody'/1, '__bp_priv__asinPoly'/1, '__bp_priv__asinBody'/1, '__bp_priv__acosBody'/1, '__bp_priv__atanBody'/1, '__bp_priv__atan2Body'/2, '__bp_priv__sinhBody'/1, '__bp_priv__coshBody'/1, '__bp_priv__tanhBody'/1]).

%%% std/math — math functions and constants (cross-backend).

%%% 

%%% Reference:

%%%   Node.js  — https://nodejs.org/api/  (the `Math` global)

%%%   Erlang   — https://www.erlang.org/doc/apps/stdlib/math.html

%%% 

%%% Surface mirrors the intersection of `Math.*` (JS) and `math:*` (Erlang).

%%% `floor`/`ceil`/`trunc`/`round` return `f64` (both Node and Erlang return

%%% floating-point on the host, and staying in `f64` keeps mixed arithmetic

%%% from running into i32/i64 unification issues in pure-botopink

%%% derivations). Constants live as `pub val`; every host-bound fn carries

%%% `#[compiler.external(.<Target>(…))]` per backend, and `#[compiler.stage(.Any)]`: a pure

%%% primitive runs at build as when the program runs (decision 376 (4)).

% ── constants ────────────────────────────────────────────────────────────────

pi() ->
    3.141592653589793.

e() ->
    2.718281828459045.

tau() ->
    6.283185307179586.

sqrt2() ->
    1.4142135623730951.

ln2() ->
    0.6931471805599453.

ln10() ->
    2.302585092994046.

log2e() ->
    1.4426950408889634.

log10e() ->
    0.4342944819032518.

% ── arithmetic + rounding ────────────────────────────────────────────────────

% `abs` works on `f64`. Integer abs lives on the numeric tower

% (`primitives.bp` Signed). `minF`/`maxF` are the float variants — the

% generic ones live on `Number`.

%% external fn abs -> erlang template
abs(X) ->
    erlang:abs(X).

%% external fn floor -> erlang template
floor(X) ->
    math:floor(X).

%% external fn round -> erlang template
round(X) ->
    erlang:round(X).

%% external fn trunc -> erlang template
trunc(X) ->
    erlang:trunc(X).

% `ceil(x) = -floor(-x)` — a pure-botopink derivation that avoids the

% erlang inline-arithmetic template (no `math:ceil/1` BIF exists pre-OTP-26).

ceil(X) ->
    (0.0 - math:floor((0.0 - X))).

% `sign` returns -1.0, 0.0, or 1.0 depending on the input's sign.

% Pure-botopink; sidesteps the inline-case template the spec describes.

sign(X) ->
    case (X > 0.0) of
        true ->
            1.0;
        false ->
            case (X < 0.0) of
                true ->
                    (0.0 - 1.0);
                false ->
                    0.0
            end
    end.

%% external fn minF -> erlang template
minF(A, B) ->
    erlang:min(A, B).

%% external fn maxF -> erlang template
maxF(A, B) ->
    erlang:max(A, B).

clamp(X, Lo, Hi) ->
    erlang:max(Lo, erlang:min(Hi, X)).

% ── powers + roots + exp/log ─────────────────────────────────────────────────

%% external fn sqrt -> erlang template
sqrt(X) ->
    math:sqrt(X).

% Every target runs std's body (decision 610: a function whose every target

% runs botopink is a bodied `fn`).

pow(X, Y) ->
    powBody(X, Y).

% `cbrt(x)` via `pow(x, 1/3)`, honouring sign for negatives. Pure-botopink;

% node has `Math.cbrt` but the erlang side has no BIF — composition is uniform.

cbrt(X) ->
    case (X >= 0.0) of
        true ->
            pow(X, 0.3333333333333333);
        false ->
            (0.0 - pow((0.0 - X), 0.3333333333333333))
    end.

exp(X) ->
    expBody(X).

ln(X) ->
    lnBody(X).

log2(X) ->
    log2Body(X).

log10(X) ->
    log10Body(X).

% `hypot(x, y) = sqrt(x*x + y*y)` — pure-botopink composition.

hypot(X, Y) ->
    math:sqrt(((X * X) + (Y * Y))).

% ── trigonometry ─────────────────────────────────────────────────────────────

sin(X) ->
    sinBody(X).

cos(X) ->
    cosBody(X).

tan(X) ->
    tanBody(X).

asin(X) ->
    asinBody(X).

acos(X) ->
    acosBody(X).

atan(X) ->
    atanBody(X).

atan2(Y, X) ->
    atan2Body(Y, X).

sinh(X) ->
    sinhBody(X).

cosh(X) ->
    coshBody(X).

tanh(X) ->
    tanhBody(X).

% ── the bodies (decisions 238, 263) ────────────────────────────────────────

% Each transcendental's `fn:` binding names one of these private bodies:

% erlang, beam and wasm run them, so a transcendental answers the same bits

% on every target and every OS — not the platform libm OTP's `math:*` calls,

% which differs by an ulp between glibc and Apple's (`tan(1.0)`, `asin(0.5)`).

% commonJS keeps `Math.*`, because they are a port of the fdlibm code (Sun

% Microsystems, 1993) Node's V8 answers `Math.*` with

% (`deps/v8/src/base/ieee754.cc`): the same operations in the same order, so

% every target's answer is the commonJS answer bit for bit. `pow` is the one

% commonJS runs too (below). fdlibm reads and writes the two 32-bit words of

% a double; botopink has no bit operation, so the words are read and written

% with arithmetic that is exact (`highWord`, `lowWord`, `fromWords`,

% `withLowZero`). One part is not ported: the reduction of a trigonometric

% argument beyond 2^19·π/2 (`__kernel_rem_pio2`), which panics rather than

% answer a wrong value. wasm has an instruction for `abs`, `floor`, `trunc`,

% `sqrt`, `minF` and `maxF` (`op:`), which every target leaves to its host:

% IEEE 754 makes them exact.

% `Math.round`: V8's `Float64RoundUp(x)`, less one when that is more than a

% half above `x` — a half rounds UP (`round(2.5)` is 3, `round(-2.5)` is -2)

% and `-0.4` answers `-0`. `f64.nearest` rounds a half to even, which is why

% this is not an `op:`.

roundHalfUp(X) ->
    Up = ((-1.0) * math:floor(((-1.0) * X))),
    case ((Up - 0.5) > X) of
        true ->
            (Up - 1.0);
        false ->
            Up
    end.

% `s · h · h`: an overflow to ±Infinity (`h` = 1e300) or an underflow to ±0

% (`h` = 1e-300) as fdlibm writes them, with `h` a parameter so no target

% folds the product at compile time.

timesHuge(S, H) ->
    ((S * H) * H).

% 2^k for a whole k in -1074..1023 — every step exact.

twoTo(K) ->
    R = 1.0,
    N = K,
    {R@3, N@3} = (fun __BpLoop({R@1, N@1}) ->
        case (N@1 >= 32.0) of
            true ->
                R@2 = (R@1 * 4294967296.0),
                N@2 = (N@1 - 32.0),
                __BpLoop({R@2, N@2});
            _ -> {R@1, N@1}
        end
    end)({R, N}),
    {R@6, N@6} = (fun __BpLoop({R@4, N@4}) ->
        case (N@4 >= 1.0) of
            true ->
                R@5 = (R@4 * 2.0),
                N@5 = (N@4 - 1.0),
                __BpLoop({R@5, N@5});
            _ -> {R@4, N@4}
        end
    end)({R@3, N@3}),
    {R@9, N@9} = (fun __BpLoop({R@7, N@7}) ->
        case (N@7 =< (-32.0)) of
            true ->
                R@8 = (R@7 * 2.3283064365386963e-10),
                N@8 = (N@7 + 32.0),
                __BpLoop({R@8, N@8});
            _ -> {R@7, N@7}
        end
    end)({R@6, N@6}),
    {R@12, N@12} = (fun __BpLoop({R@10, N@10}) ->
        case (N@10 =< (-1.0)) of
            true ->
                R@11 = (R@10 * 0.5),
                N@11 = (N@10 + 1.0),
                __BpLoop({R@11, N@11});
            _ -> {R@10, N@10}
        end
    end)({R@9, N@9}),
    R@12.

% e with 2^e ≤ ax < 2^(e+1), for a positive finite ax.

exponentOf(Ax) ->
    V = Ax,
    E = 0.0,
    {V@3, E@3} = (fun __BpLoop({V@1, E@1}) ->
        case (V@1 >= 4294967296.0) of
            true ->
                V@2 = (V@1 * 2.3283064365386963e-10),
                E@2 = (E@1 + 32.0),
                __BpLoop({V@2, E@2});
            _ -> {V@1, E@1}
        end
    end)({V, E}),
    {V@6, E@6} = (fun __BpLoop({V@4, E@4}) ->
        case (V@4 >= 2.0) of
            true ->
                V@5 = (V@4 * 0.5),
                E@5 = (E@4 + 1.0),
                __BpLoop({V@5, E@5});
            _ -> {V@4, E@4}
        end
    end)({V@3, E@3}),
    {V@9, E@9} = (fun __BpLoop({V@7, E@7}) ->
        case (V@7 < 2.3283064365386963e-10) of
            true ->
                V@8 = (V@7 * 4294967296.0),
                E@8 = (E@7 - 32.0),
                __BpLoop({V@8, E@8});
            _ -> {V@7, E@7}
        end
    end)({V@6, E@6}),
    {V@12, E@12} = (fun __BpLoop({V@10, E@10}) ->
        case (V@10 < 1.0) of
            true ->
                V@11 = (V@10 * 2.0),
                E@11 = (E@10 - 1.0),
                __BpLoop({V@11, E@11});
            _ -> {V@10, E@10}
        end
    end)({V@9, E@9}),
    E@12.

% The 52-bit significand of a subnormal |x| as a whole number.

subnormalBits(Ax) ->
    (((Ax * twoTo(1000.0))) * twoTo(74.0)).

% fdlibm's `hx & 0x7fffffff`: the high 32-bit word of |x| as a whole number.

highWord(X) ->
    case (X =/= X) of
        true ->
            2146959360.0;
        _ ->
            Ax = erlang:abs(X),
            case isZero(Ax) of
                true ->
                    0.0;
                _ ->
                    case (Ax > 1.7976931348623157e308) of
                        true ->
                            2146435072.0;
                        _ ->
                            E = exponentOf(Ax),
                            case (E < (-1022.0)) of
                                true ->
                                    math:floor((subnormalBits(Ax) / 4294967296.0));
                                _ ->
                                    M = (Ax * twoTo((0.0 - E))),
                                    ((((E + 1023.0)) * 1048576.0) + math:floor((((M - 1.0)) * 1048576.0)))
                            end
                    end
            end
    end.

% fdlibm's low word: the low 32 bits of |x|'s significand.

lowWord(X) ->
    Ax = erlang:abs(X),
    case (((X =/= X) orelse isZero(Ax)) orelse (Ax > 1.7976931348623157e308)) of
        true ->
            0.0;
        _ ->
            E = exponentOf(Ax),
            Bits = case (E < (-1022.0)) of
                true ->
                    subnormalBits(Ax);
                false ->
                    ((((Ax * twoTo((0.0 - E))) - 1.0)) * 4503599627370496.0)
            end,
            (Bits - (math:floor((Bits / 4294967296.0)) * 4294967296.0))
    end.

% The positive double whose words are `hw` (below the sign) and `lw`.

fromWords(Hw, Lw) ->
    Ef = math:floor((Hw / 1048576.0)),
    Frac = ((((Hw - (Ef * 1048576.0))) * 4294967296.0) + Lw),
    case isZero(Ef) of
        true ->
            (((Frac * twoTo((-1000.0)))) * twoTo((-74.0)));
        _ ->
            (((1.0 + (Frac / 4503599627370496.0))) * twoTo((Ef - 1023.0)))
    end.

% fdlibm's `SET_LOW_WORD(x, 0)`.

withLowZero(X) ->
    V = fromWords(highWord(X), 0.0),
    case signBit(X) of
        true ->
            ((-1.0) * V);
        false ->
            V
    end.

% Whether `v` carries a minus sign — `-0.0` included (fdlibm's `hx < 0`).

% commonJS and wasm compare `-0.0` equal to `0.0` and tell the two apart by

% `1 / v`; erlang and beam compare them unequal (`=:=`) and have no `1 / 0`.

signBit(V) ->
    case (V < 0.0) of
        true ->
            true;
        _ ->
            case (V > 0.0) of
                true ->
                    false;
                _ ->
                    case ((V =:= 0.0) andalso (V =:= (-0.0))) of
                        true ->
                            ((1.0 / '__bp_nz'(V, <<"division by zero: / on f64 at src/math.bp:293:43">>)) < 0.0);
                        _ ->
                            (V =:= (-0.0))
                    end
            end
    end.

% Whether `v` is `0.0` or `-0.0` — on every target: `v == 0.0` is false for

% `-0.0` on erlang and beam (`=:=`).

isZero(V) ->
    ((V >= 0.0) andalso (V =< 0.0)).

% The exponent field of x's high word (`(hx >> 20) & 0x7ff`).

exponentField(X) ->
    math:floor((highWord(X) / 1048576.0)).

% ── exp, expm1 ───────────────────────────────────────────────────────────────

expBody(X) ->
    try
        Hx = highWord(X),
        Neg = signBit(X),
        case (Hx >= 1082535490.0) of
            true ->
                case (Hx >= 2146435072.0) of
                    true ->
                        case (X =/= X) of
                            true ->
                                erlang:throw({'__bp_try', (X + X)});
                            _ -> ok
                        end,
                        erlang:throw({'__bp_try', case Neg of
                            true ->
                                0.0;
                            false ->
                                X
                        end});
                    _ -> ok
                end,
                case (X > 7.09782712893383973096e+02) of
                    true ->
                        erlang:throw({'__bp_try', timesHuge(1.0, 1.0e300)});
                    _ -> ok
                end,
                case (X < (-7.45133219101941108420e+02)) of
                    true ->
                        erlang:throw({'__bp_try', timesHuge(1.0, 9.33263618503218878990e-302)});
                    _ -> ok
                end;
            _ -> ok
        end,
        Hi = 0.0,
        Lo = 0.0,
        K = 0.0,
        R = X,
        {Hi@6, Lo@6, K@6, R@2} = case (Hx > 1071001154.0) of
            true ->
                {Hi@5, Lo@5, K@5} = case (Hx < 1072734898.0) of
                    true ->
                        case (X =:= 1.0) of
                            true ->
                                erlang:throw({'__bp_try', 2.718281828459045});
                            _ -> ok
                        end,
                        {Hi@3, Lo@3, K@3} = case Neg of
                            true ->
                                Hi@1 = (X + 6.93147180369123816490e-01),
                                Lo@1 = (-1.90821492927058770002e-10),
                                K@1 = (-1.0),
                                {Hi@1, Lo@1, K@1};
                            _ ->
                                Hi@2 = (X - 6.93147180369123816490e-01),
                                Lo@2 = 1.90821492927058770002e-10,
                                K@2 = 1.0,
                                {Hi@2, Lo@2, K@2}
                        end,
                        {Hi@3, Lo@3, K@3};
                    _ ->
                        Half = case Neg of
                            true ->
                                (-0.5);
                            false ->
                                0.5
                        end,
                        K@4 = erlang:trunc(((1.44269504088896338700e+00 * X) + Half)),
                        Hi@4 = (X - (K@4 * 6.93147180369123816490e-01)),
                        Lo@4 = (K@4 * 1.90821492927058770002e-10),
                        {Hi@4, Lo@4, K@4}
                end,
                R@1 = (Hi@5 - Lo@5),
                {Hi@5, Lo@5, K@5, R@1};
            _ ->
                case (Hx < 1043333120.0) of
                    true ->
                        erlang:throw({'__bp_try', (1.0 + X)});
                    _ -> ok
                end,
                {Hi, Lo, K, R}
        end,
        T = (R@2 * R@2),
        Twopk = case (K@6 >= (-1021.0)) of
            true ->
                twoTo(K@6);
            false ->
                twoTo((K@6 + 1000.0))
        end,
        C = (R@2 - (T * ((1.66666666666666019037e-01 + (T * (((-2.77777777770155933842e-03) + (T * ((6.61375632143793436117e-05 + (T * (((-1.65339022054652515390e-06) + (T * 4.13813679705723846039e-08)))))))))))))),
        case isZero(K@6) of
            true ->
                (1.0 - (((((R@2 * C)) / '__bp_nz'(((C - 2.0)), <<"division by zero: / on f64 at src/math.bp:358:42">>)) - R@2)));
            _ ->
                Y = (1.0 - ((((Lo@6 - (((R@2 * C)) / '__bp_nz'(((2.0 - C)), <<"division by zero: / on f64 at src/math.bp:359:34">>)))) - Hi@6))),
                case (K@6 >= (-1021.0)) of
                    true ->
                        case (K@6 =:= 1024.0) of
                            true ->
                                ((Y * 2.0) * 8.988465674311579539e307);
                            _ ->
                                (Y * Twopk)
                        end;
                    _ ->
                        ((Y * Twopk) * 9.33263618503218878990e-302)
                end
        end
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

expm1Body(X) ->
    try
        Hx = highWord(X),
        Neg = signBit(X),
        case (Hx >= 1078159482.0) of
            true ->
                case (Hx >= 1082535490.0) of
                    true ->
                        case (Hx >= 2146435072.0) of
                            true ->
                                case (X =/= X) of
                                    true ->
                                        erlang:throw({'__bp_try', (X + X)});
                                    _ -> ok
                                end,
                                erlang:throw({'__bp_try', case Neg of
                                    true ->
                                        (-1.0);
                                    false ->
                                        X
                                end});
                            _ -> ok
                        end,
                        case (X > 7.09782712893383973096e+02) of
                            true ->
                                erlang:throw({'__bp_try', timesHuge(1.0, 1.0e300)});
                            _ -> ok
                        end;
                    _ -> ok
                end,
                case (Neg andalso ((X + 1.0e-300) < 0.0)) of
                    true ->
                        erlang:throw({'__bp_try', (1.0e-300 - 1.0)});
                    _ -> ok
                end;
            _ -> ok
        end,
        K = 0.0,
        R = X,
        C = 0.0,
        {K@6, R@2, C@2} = case (Hx > 1071001154.0) of
            true ->
                Hi = 0.0,
                Lo = 0.0,
                {Hi@5, Lo@5, K@5} = case (Hx < 1072734898.0) of
                    true ->
                        {Hi@3, Lo@3, K@3} = case (not Neg) of
                            true ->
                                Hi@1 = (X - 6.93147180369123816490e-01),
                                Lo@1 = 1.90821492927058770002e-10,
                                K@1 = 1.0,
                                {Hi@1, Lo@1, K@1};
                            _ ->
                                Hi@2 = (X + 6.93147180369123816490e-01),
                                Lo@2 = (-1.90821492927058770002e-10),
                                K@2 = (-1.0),
                                {Hi@2, Lo@2, K@2}
                        end,
                        {Hi@3, Lo@3, K@3};
                    _ ->
                        Half = case Neg of
                            true ->
                                (-0.5);
                            false ->
                                0.5
                        end,
                        K@4 = erlang:trunc(((1.44269504088896338700e+00 * X) + Half)),
                        Hi@4 = (X - (K@4 * 6.93147180369123816490e-01)),
                        Lo@4 = (K@4 * 1.90821492927058770002e-10),
                        {Hi@4, Lo@4, K@4}
                end,
                R@1 = (Hi@5 - Lo@5),
                C@1 = (((Hi@5 - R@1)) - Lo@5),
                {K@5, R@1, C@1};
            _ ->
                case (Hx < 1016070144.0) of
                    true ->
                        erlang:throw({'__bp_try', X});
                    _ -> ok
                end,
                {K, R, C}
        end,
        Hfx = (0.5 * R@2),
        Hxs = (R@2 * Hfx),
        R1 = (1.0 + (Hxs * (((-3.33333333333331316428e-02) + (Hxs * ((1.58730158725481460165e-03 + (Hxs * (((-7.93650757867487942473e-05) + (Hxs * ((4.00821782732936239552e-06 + (Hxs * (-2.01099218183624371326e-07))))))))))))))),
        T = (3.0 - (R1 * Hfx)),
        E = (Hxs * ((((R1 - T)) / '__bp_nz'(((6.0 - (R@2 * T))), <<"division by zero: / on f64 at src/math.bp:418:29">>)))),
        case isZero(K@6) of
            true ->
                (R@2 - (((R@2 * E) - Hxs)));
            _ ->
                Twopk = twoTo(K@6),
                E@1 = ((R@2 * ((E - C@2))) - C@2),
                E@2 = (E@1 - Hxs),
                case (K@6 =:= (-1.0)) of
                    true ->
                        ((0.5 * ((R@2 - E@2))) - 0.5);
                    _ ->
                        case (K@6 =:= 1.0) of
                            true ->
                                case (R@2 < (-0.25)) of
                                    true ->
                                        ((-2.0) * ((E@2 - ((R@2 + 0.5)))));
                                    false ->
                                        (1.0 + (2.0 * ((R@2 - E@2))))
                                end;
                            _ ->
                                case ((K@6 =< (-2.0)) orelse (K@6 > 56.0)) of
                                    true ->
                                        Y = (1.0 - ((E@2 - R@2))),
                                        Scaled = case (K@6 =:= 1024.0) of
                                            true ->
                                                ((Y * 2.0) * 8.98846567431158e+307);
                                            false ->
                                                (Y * Twopk)
                                        end,
                                        (Scaled - 1.0);
                                    _ ->
                                        case (K@6 < 20.0) of
                                            true ->
                                                T2 = fromWords((1072693248.0 - twoTo((21.0 - K@6))), 0.0),
                                                (((T2 - ((E@2 - R@2)))) * Twopk);
                                            _ ->
                                                T3 = fromWords((((1023.0 - K@6)) * 1048576.0), 0.0),
                                                (((((R@2 - ((E@2 + T3)))) + 1.0)) * Twopk)
                                        end
                                end
                        end
                end
        end
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

% ── logarithms ───────────────────────────────────────────────────────────────

% fdlibm's answer for what is not a positive finite number.

logSpecial(X) ->
    case ((X =/= X) orelse (X > 1.7976931348623157e308)) of
        true ->
            (X + X);
        _ ->
            case (X < 0.0) of
                true ->
                    (((X - X)) / '__bp_nz'(((X - X)), <<"division by zero: / on f64 at src/math.bp:447:33">>));
                _ ->
                    ((-1.0) / '__bp_nz'(((X * X)), <<"division by zero: / on f64 at src/math.bp:448:17">>))
            end
    end.

% `x` with its exponent set to 0 (or -1, when the mantissa's high bits pass

% √2's — fdlibm's `(hx + 0x95f64) & 0x100000`), and how much the exponent

% moved: `logScaled(x, 0)` answers the scaled `x`, `logScaled(x, 1)` the `k`.

logScaled(X, Which) ->
    K = 0.0,
    V = X,
    {K@2, V@2} = case (X < 2.2250738585072014e-308) of
        true ->
            K@1 = (-54.0),
            V@1 = (X * 1.80143985094819840000e+16),
            {K@1, V@1};
        _ ->
            {K, V}
    end,
    Hw = highWord(V@2),
    Ef = math:floor((Hw / 1048576.0)),
    M20 = (Hw - (Ef * 1048576.0)),
    Up = ((M20 + 614244.0) >= 1048576.0),
    Carry = case Up of
        true ->
            1.0;
        false ->
            0.0
    end,
    K@3 = (((K@2 + Ef) - 1023.0) + Carry),
    case (Which > 0.5) of
        true ->
            K@3;
        _ ->
            Field = case Up of
                true ->
                    1071644672.0;
                false ->
                    1072693248.0
            end,
            fromWords((Field + M20), lowWord(V@2))
    end.

% The high mantissa bits (`hx & 0xfffff`) the scaled `x` came from.

logMantissaBits(X) ->
    V = case (X < 2.2250738585072014e-308) of
        true ->
            (X * 1.80143985094819840000e+16);
        false ->
            X
    end,
    Hw = highWord(V),
    (Hw - (math:floor((Hw / 1048576.0)) * 1048576.0)).

lnBody(X) ->
    case (((X =/= X) orelse (X =< 0.0)) orelse (X > 1.7976931348623157e308)) of
        true ->
            logSpecial(X);
        _ ->
            K = logScaled(X, 1.0),
            F = (logScaled(X, 0.0) - 1.0),
            M20 = logMantissaBits(X),
            Ln2Hi = 6.93147180369123816490e-01,
            Ln2Lo = 1.90821492927058770002e-10,
            case ((M20 >= 1048574.0) orelse isZero(M20)) of
                true ->
                    case isZero(F) of
                        true ->
                            case isZero(K) of
                                true ->
                                    0.0;
                                false ->
                                    ((K * Ln2Hi) + (K * Ln2Lo))
                            end;
                        _ ->
                            Rr = ((F * F) * ((0.5 - (0.33333333333333333 * F)))),
                            case isZero(K) of
                                true ->
                                    (F - Rr);
                                false ->
                                    ((K * Ln2Hi) - ((((Rr - (K * Ln2Lo))) - F)))
                            end
                    end;
                _ ->
                    S = (F / '__bp_nz'(((2.0 + F)), <<"division by zero: / on f64 at src/math.bp:494:15">>)),
                    Z = (S * S),
                    W = (Z * Z),
                    T1 = (W * ((3.999999999940941908e-01 + (W * ((2.222219843214978396e-01 + (W * 1.531383769920937332e-01))))))),
                    T2 = (Z * ((6.666666666666735130e-01 + (W * ((2.857142874366239149e-01 + (W * ((1.818357216161805012e-01 + (W * 1.479819860511658591e-01)))))))))),
                    Rr@1 = (T2 + T1),
                    case ((M20 >= 398458.0) andalso (M20 =< 440401.0)) of
                        true ->
                            Hfsq = ((0.5 * F) * F),
                            case isZero(K) of
                                true ->
                                    (F - ((Hfsq - (S * ((Hfsq + Rr@1))))));
                                false ->
                                    ((K * Ln2Hi) - ((((Hfsq - (((S * ((Hfsq + Rr@1))) + (K * Ln2Lo))))) - F)))
                            end;
                        _ ->
                            case isZero(K) of
                                true ->
                                    (F - (S * ((F - Rr@1))));
                                false ->
                                    ((K * Ln2Hi) - (((((S * ((F - Rr@1))) - (K * Ln2Lo))) - F)))
                            end
                    end
            end
    end.

% fdlibm's `k_log1p(f)`.

logOnePlusTail(F) ->
    S = (F / '__bp_nz'(((2.0 + F)), <<"division by zero: / on f64 at src/math.bp:523:15">>)),
    Z = (S * S),
    W = (Z * Z),
    T1 = (W * ((3.999999999940941908e-01 + (W * ((2.222219843214978396e-01 + (W * 1.531383769920937332e-01))))))),
    T2 = (Z * ((6.666666666666735130e-01 + (W * ((2.857142874366239149e-01 + (W * ((1.818357216161805012e-01 + (W * 1.479819860511658591e-01)))))))))),
    Hfsq = ((0.5 * F) * F),
    (S * ((Hfsq + ((T2 + T1))))).

log2Body(X) ->
    case (((X =/= X) orelse (X =< 0.0)) orelse (X > 1.7976931348623157e308)) of
        true ->
            logSpecial(X);
        _ ->
            case (X =:= 1.0) of
                true ->
                    0.0;
                _ ->
                    Y = logScaled(X, 1.0),
                    F = (logScaled(X, 0.0) - 1.0),
                    Hfsq = ((0.5 * F) * F),
                    R = logOnePlusTail(F),
                    Hi = withLowZero((F - Hfsq)),
                    Lo = ((((F - Hi)) - Hfsq) + R),
                    ValHi = (Hi * 1.44269504072144627571e+00),
                    ValLo = ((((Lo + Hi)) * 1.67517131648865118353e-10) + (Lo * 1.44269504072144627571e+00)),
                    W = (Y + ValHi),
                    (((ValLo + ((((Y - W)) + ValHi)))) + W)
            end
    end.

log10Body(X) ->
    case (((X =/= X) orelse (X =< 0.0)) orelse (X > 1.7976931348623157e308)) of
        true ->
            logSpecial(X);
        _ ->
            case (X =:= 1.0) of
                true ->
                    0.0;
                _ ->
                    K = 0.0,
                    V = X,
                    {K@2, V@2} = case (X < 2.2250738585072014e-308) of
                        true ->
                            K@1 = (-54.0),
                            V@1 = (X * 1.80143985094819840000e+16),
                            {K@1, V@1};
                        _ ->
                            {K, V}
                    end,
                    Hw = highWord(V@2),
                    Ef = math:floor((Hw / 1048576.0)),
                    K@3 = ((K@2 + Ef) - 1023.0),
                    I = case (K@3 < 0.0) of
                        true ->
                            1.0;
                        false ->
                            0.0
                    end,
                    Scaled = fromWords(((Hw - (Ef * 1048576.0)) + (((1023.0 - I)) * 1048576.0)), lowWord(V@2)),
                    Y = (K@3 + I),
                    Z = ((Y * 3.69423907715893078616e-13) + (4.34294481903251816668e-01 * lnBody(Scaled))),
                    (Z + (Y * 3.01029995663611771306e-01))
            end
    end.

% ── pow ──────────────────────────────────────────────────────────────────────

% glibc's `pow` (`sysdeps/ieee754/dbl-64/e_pow.c`, the algorithm since glibc

% 2.28, from Arm's optimized-routines) as x86-64 glibc runs it: the

% `__ieee754_pow_fma` build, whose compiler fused each `a * b + c` it could

% into one rounding. Every target runs this body (decision 259), so a pow is

% the same bits everywhere and Linux's `Math.pow` and `math:pow` bit for bit:

% `pow(158.42161580281933, 2.853827476501465)` is `1896229.4525711867`.

% log|x| is carried in double-double from a 128-entry table (`powInvc`,

% `powLogc`, `powLogctail` — glibc's `__pow_log_data`), e^(y·log|x|) from the

% 128 values of 2^(j/128) (`expHead`, `expTail` — `__exp_data`); the tables

% are glibc 2.44's, read from its libm. glibc's word operations are exact

% arithmetic here and each fused multiply-add is computed exactly

% (`fusedMultiplyAdd`). The special values are glibc's, after ECMA-262's two

% (`pow(x, NaN)` and `pow(±1, ±Infinity)` are NaN, where C answers 1), so

% commonJS answers what `Math.pow` answered.

% a + b − s exactly, for s the rounded sum (Knuth's two-sum).

sumError(A, B, S) ->
    Bb = (S - A),
    (((A - ((S - Bb)))) + ((B - Bb))).

% a·b − p exactly, for p the rounded product (Dekker's two-product).

productError(A, B, P) ->
    Ca = (134217729.0 * A),
    Ah = (Ca - ((Ca - A))),
    Al = (A - Ah),
    Cb = (134217729.0 * B),
    Bh = (Cb - ((Cb - B))),
    Bl = (B - Bh),
    (((((((Ah * Bh) - P)) + (Ah * Bl)) + (Al * Bh))) + (Al * Bl)).

% The power of two of s's leading bit, for a normal s ≠ 0 (Rump, Zimmermann,

% Boldo and Melquiond's `ufp`: φ = 2^52 + 1, ψ = 1 − 2^-53).

unitInFirstPlace(S) ->
    Q = (4503599627370497.0 * S),
    R = (0.9999999999999999 * Q),
    erlang:abs((Q - R)).

% a + b rounded to odd: the exact sum when it is a double, else the one of

% its two neighbours whose last significand bit is 1.

sumRoundedToOdd(A, B) ->
    S = (A + B),
    Err = sumError(A, B, S),
    case isZero(Err) of
        true ->
            S;
        _ ->
            F = unitInFirstPlace(S),
            Ulp = (F * 2.220446049250313e-16),
            Mag = erlang:abs(S),
            M = (Mag / '__bp_nz'(Ulp, <<"division by zero: / on f64 at src/math.bp:629:17">>)),
            case ((M - (2.0 * math:floor((M * 0.5)))) =:= 1.0) of
                true ->
                    S;
                _ ->
                    Away = (((Err > 0.0)) =:= ((S > 0.0))),
                    Stepped = case Away of
                        true ->
                            (Mag + Ulp);
                        false ->
                            case (Mag =:= F) of
                                true ->
                                    (Mag - (Ulp * 0.5));
                                false ->
                                    (Mag - Ulp)
                            end
                    end,
                    case (S > 0.0) of
                        true ->
                            Stepped;
                        false ->
                            ((-1.0) * Stepped)
                    end
            end
    end.

% fma(a, b, c): a·b + c rounded once (Boldo and Melquiond's emulation — the

% exact product, a two-sum, one sum rounded to odd, one rounding to nearest).

fusedMultiplyAdd(A, B, C) ->
    Uh = (A * B),
    Ul = productError(A, B, Uh),
    Th = (C + Uh),
    Tl = sumError(C, Uh, Th),
    (Th + sumRoundedToOdd(Tl, Ul)).

% 0 when `y` is not a whole number, 1 when it is odd, 2 when it is even

% (glibc's `checkint`).

wholeKind(Y) ->
    case (math:floor(Y) =/= Y) of
        true ->
            0.0;
        _ ->
            case (erlang:abs(Y) >= 9007199254740992.0) of
                true ->
                    2.0;
                _ ->
                    Half = (Y * 0.5),
                    case (math:floor(Half) =:= Half) of
                        true ->
                            2.0;
                        false ->
                            1.0
                    end
            end
    end.

powBody(X, Y) ->
    case (Y =/= Y) of
        true ->
            Y;
        _ ->
            Ax = erlang:abs(X),
            Ay = erlang:abs(Y),
            Inf = 1.7976931348623157e308,
            case ((Ay > Inf) andalso (Ax =:= 1.0)) of
                true ->
                    (Y - Y);
                _ ->
                    case (isZero(Y) orelse (X =:= 1.0)) of
                        true ->
                            1.0;
                        _ ->
                            case (X =/= X) of
                                true ->
                                    (X + Y);
                                _ ->
                                    case (Ay > Inf) of
                                        true ->
                                            case (((Ax < 1.0)) =:= ((Y > 0.0))) of
                                                true ->
                                                    0.0;
                                                false ->
                                                    Ay
                                            end;
                                        _ ->
                                            Odd = (wholeKind(Y) =:= 1.0),
                                            Nx = signBit(X),
                                            case (isZero(Ax) orelse (Ax > Inf)) of
                                                true ->
                                                    % ±0 and ±Infinity: x², negated for an odd power of a negative x
                                                    X2 = case (Nx andalso Odd) of
                                                        true ->
                                                            ((-1.0) * ((X * X)));
                                                        false ->
                                                            (X * X)
                                                    end,
                                                    case (Y < 0.0) of
                                                        true ->
                                                            (1.0 / '__bp_nz'(X2, <<"division by zero: / on f64 at src/math.bp:674:33">>));
                                                        false ->
                                                            X2
                                                    end;
                                                _ ->
                                                    case (Nx andalso isZero(wholeKind(Y))) of
                                                        true ->
                                                            (((X - X)) / '__bp_nz'(((X - X)), <<"division by zero: / on f64 at src/math.bp:676:52">>));
                                                        _ ->
                                                            case ((Ay < 2.710505431213761e-20) orelse (Ay >= 9.223372036854776e18)) of
                                                                true ->
                                                                    case (Ax =:= 1.0) of
                                                                        true ->
                                                                            1.0;
                                                                        _ ->
                                                                            case (Ay < 2.710505431213761e-20) of
                                                                                true ->
                                                                                    case (Ax > 1.0) of
                                                                                        true ->
                                                                                            (1.0 + Y);
                                                                                        false ->
                                                                                            (1.0 - Y)
                                                                                    end;
                                                                                _ ->
                                                                                    case (((Ax > 1.0)) =:= ((Y > 0.0))) of
                                                                                        true ->
                                                                                            timesHuge(1.0, 1.0e300);
                                                                                        false ->
                                                                                            timesHuge(1.0, 1.0e-300)
                                                                                    end
                                                                            end
                                                                    end;
                                                                _ ->
                                                                    % log|x| = k·ln2 + log c + log1p(z/c − 1), |x| = 2^k·z with z in
                                                                    % [0x1.69555p-1, 0x1.69555p0) and c near the middle of z's subinterval
                                                                    Sub = (Ax < 2.2250738585072014e-308),
                                                                    Xs = case Sub of
                                                                        true ->
                                                                            (Ax * 4503599627370496.0);
                                                                        false ->
                                                                            Ax
                                                                    end,
                                                                    E = exponentOf(Xs),
                                                                    M = (Xs * twoTo((0.0 - E))),
                                                                    Big = (M >= 1.4114580154418945),
                                                                    Z = case Big of
                                                                        true ->
                                                                            (M * 0.5);
                                                                        false ->
                                                                            M
                                                                    end,
                                                                    Kz = case Big of
                                                                        true ->
                                                                            (E + 1.0);
                                                                        false ->
                                                                            E
                                                                    end,
                                                                    K = case Sub of
                                                                        true ->
                                                                            (Kz - 52.0);
                                                                        false ->
                                                                            Kz
                                                                    end,
                                                                    I = case (Z < 1.0) of
                                                                        true ->
                                                                            math:floor((((Z - 0.7057290077209473)) * 256.0));
                                                                        false ->
                                                                            math:floor(((((Z - 1.0)) * 128.0) + 75.3333740234375))
                                                                    end,
                                                                    Invc = powInvc(I),
                                                                    Logc = powLogc(I),
                                                                    Zc = (Z * Invc),
                                                                    R = (((Zc - 1.0)) + productError(Z, Invc, Zc)),
                                                                    T1 = ((K * 0.6931471805598903) + Logc),
                                                                    T2 = (T1 + R),
                                                                    Lo1 = fusedMultiplyAdd(K, 5.497923018708371e-14, powLogctail(I)),
                                                                    Lo2 = ((T1 - T2) + R),
                                                                    Ar = ((-0.5) * R),
                                                                    Ar2 = (R * Ar),
                                                                    Ar3 = (R * Ar2),
                                                                    Lhi = (T2 + Ar2),
                                                                    Lo3 = productError(Ar, R, Ar2),
                                                                    Lo4 = ((T2 - Lhi) + Ar2),
                                                                    Q = fusedMultiplyAdd(Ar2, fusedMultiplyAdd(Ar2, fusedMultiplyAdd(R, 1.0000415263675542, (-1.142909628459501)), fusedMultiplyAdd(R, (-0.6666666663487739), 0.7999999995323976)), fusedMultiplyAdd(R, 0.5000000000000007, (-0.6666666666666679))),
                                                                    Llo = fusedMultiplyAdd(Ar3, Q, (((Lo1 + Lo2) + Lo3) + Lo4)),
                                                                    L = (Lhi + Llo),
                                                                    Ltail = ((Lhi - L) + Llo),
                                                                    % e^(y·log|x|), y·log|x| carried as ehi + elo
                                                                    Ehi = (Y * L),
                                                                    Elo = fusedMultiplyAdd(Y, Ltail, productError(Y, L, Ehi)),
                                                                    powExp(Ehi, Elo, (Nx andalso Odd))
                                                            end
                                                    end
                                            end
                                    end
                            end
                    end
            end
    end.

% glibc's `exp_inline`: ±e^(x + xtail), the sign minus when `neg`.

powExp(X, Xtail, Neg) ->
    S = case Neg of
        true ->
            (-1.0);
        false ->
            1.0
    end,
    Ax = erlang:abs(X),
    case (Ax < 5.551115123125783e-17) of
        true ->
            (S * ((1.0 + X)));
        _ ->
            case (Ax >= 1024.0) of
                true ->
                    case (X < 0.0) of
                        true ->
                            timesHuge(S, 1.0e-300);
                        false ->
                            timesHuge(S, 1.0e300)
                    end;
                _ ->
                    % x = k·ln2/128 + r, e^x = 2^(k/128)·e^r, j = k mod 128
                    Kd = (fusedMultiplyAdd(184.6649652337873, X, 6755399441055744.0) - 6755399441055744.0),
                    R = (fusedMultiplyAdd(Kd, (-1.2864023111638346e-14), fusedMultiplyAdd(Kd, (-0.005415212348111709), X)) + Xtail),
                    J = (Kd - (128.0 * math:floor((Kd / 128.0)))),
                    R2 = (R * R),
                    Tmp = fusedMultiplyAdd((R2 * R2), fusedMultiplyAdd(R, 0.008333335853059549, 0.0416666808410674), fusedMultiplyAdd(R2, fusedMultiplyAdd(R, 0.16666666666665886, 0.49999999999996786), (expTail(J) + R))),
                    N = (((Kd - J)) / 128.0),
                    case (Ax < 512.0) of
                        true ->
                            Scale = ((S * expHead(J)) * twoTo(N)),
                            fusedMultiplyAdd(Scale, Tmp, Scale);
                        _ ->
                            % glibc's `specialcase`: the scale's exponent kept in range, then the
                            % result scaled — rounded once more in the subnormal range
                            case (Kd > 0.0) of
                                true ->
                                    Big = ((S * expHead(J)) * twoTo((N - 1009.0))),
                                    (5.486124068793689e303 * fusedMultiplyAdd(Big, Tmp, Big));
                                _ ->
                                    Scale@1 = ((S * expHead(J)) * twoTo((N + 1022.0))),
                                    St = (Scale@1 * Tmp),
                                    V = (Scale@1 + St),
                                    case (erlang:abs(V) >= 1.0) of
                                        true ->
                                            (2.2250738585072014e-308 * V);
                                        _ ->
                                            One = case (V < 0.0) of
                                                true ->
                                                    (-1.0);
                                                false ->
                                                    1.0
                                            end,
                                            Lo0 = ((Scale@1 - V) + St),
                                            Hi = (One + V),
                                            Lo = (((One - Hi) + V) + Lo0),
                                            W = (((Hi + Lo)) - One),
                                            Wz = case ((W > 0.0) orelse (W < 0.0)) of
                                                true ->
                                                    W;
                                                false ->
                                                    (S * 0.0)
                                            end,
                                            (2.2250738585072014e-308 * Wz)
                                    end
                            end
                    end
            end
    end.

% `__pow_log_data.tab[i].invc`: 1/c for the i-th of the 128 subintervals of

% [0x1.69555p-1, 0x1.69555p0) — a number of few bits, so z/c − 1 is exact.

powInvc(I) ->
    case (I < 64.0) of
        true ->
            case (I < 32.0) of
                true ->
                    case (I < 16.0) of
                        true ->
                            case (I < 8.0) of
                                true ->
                                    case (I < 4.0) of
                                        true ->
                                            case (I < 2.0) of
                                                true ->
                                                    case (I < 1.0) of
                                                        true ->
                                                            1.4140625;
                                                        false ->
                                                            1.40625
                                                    end;
                                                false ->
                                                    case (I < 3.0) of
                                                        true ->
                                                            1.3984375;
                                                        false ->
                                                            1.390625
                                                    end
                                            end;
                                        false ->
                                            case (I < 6.0) of
                                                true ->
                                                    case (I < 5.0) of
                                                        true ->
                                                            1.3828125;
                                                        false ->
                                                            1.375
                                                    end;
                                                false ->
                                                    case (I < 7.0) of
                                                        true ->
                                                            1.3671875;
                                                        false ->
                                                            1.359375
                                                    end
                                            end
                                    end;
                                false ->
                                    case (I < 12.0) of
                                        true ->
                                            case (I < 10.0) of
                                                true ->
                                                    case (I < 9.0) of
                                                        true ->
                                                            1.3515625;
                                                        false ->
                                                            1.34375
                                                    end;
                                                false ->
                                                    case (I < 11.0) of
                                                        true ->
                                                            1.3359375;
                                                        false ->
                                                            1.3359375
                                                    end
                                            end;
                                        false ->
                                            case (I < 14.0) of
                                                true ->
                                                    case (I < 13.0) of
                                                        true ->
                                                            1.328125;
                                                        false ->
                                                            1.3203125
                                                    end;
                                                false ->
                                                    case (I < 15.0) of
                                                        true ->
                                                            1.3125;
                                                        false ->
                                                            1.3046875
                                                    end
                                            end
                                    end
                            end;
                        false ->
                            case (I < 24.0) of
                                true ->
                                    case (I < 20.0) of
                                        true ->
                                            case (I < 18.0) of
                                                true ->
                                                    case (I < 17.0) of
                                                        true ->
                                                            1.296875;
                                                        false ->
                                                            1.2890625
                                                    end;
                                                false ->
                                                    case (I < 19.0) of
                                                        true ->
                                                            1.2890625;
                                                        false ->
                                                            1.28125
                                                    end
                                            end;
                                        false ->
                                            case (I < 22.0) of
                                                true ->
                                                    case (I < 21.0) of
                                                        true ->
                                                            1.2734375;
                                                        false ->
                                                            1.265625
                                                    end;
                                                false ->
                                                    case (I < 23.0) of
                                                        true ->
                                                            1.2578125;
                                                        false ->
                                                            1.25
                                                    end
                                            end
                                    end;
                                false ->
                                    case (I < 28.0) of
                                        true ->
                                            case (I < 26.0) of
                                                true ->
                                                    case (I < 25.0) of
                                                        true ->
                                                            1.25;
                                                        false ->
                                                            1.2421875
                                                    end;
                                                false ->
                                                    case (I < 27.0) of
                                                        true ->
                                                            1.234375;
                                                        false ->
                                                            1.2265625
                                                    end
                                            end;
                                        false ->
                                            case (I < 30.0) of
                                                true ->
                                                    case (I < 29.0) of
                                                        true ->
                                                            1.2265625;
                                                        false ->
                                                            1.21875
                                                    end;
                                                false ->
                                                    case (I < 31.0) of
                                                        true ->
                                                            1.2109375;
                                                        false ->
                                                            1.203125
                                                    end
                                            end
                                    end
                            end
                    end;
                false ->
                    case (I < 48.0) of
                        true ->
                            case (I < 40.0) of
                                true ->
                                    case (I < 36.0) of
                                        true ->
                                            case (I < 34.0) of
                                                true ->
                                                    case (I < 33.0) of
                                                        true ->
                                                            1.203125;
                                                        false ->
                                                            1.1953125
                                                    end;
                                                false ->
                                                    case (I < 35.0) of
                                                        true ->
                                                            1.1875;
                                                        false ->
                                                            1.1875
                                                    end
                                            end;
                                        false ->
                                            case (I < 38.0) of
                                                true ->
                                                    case (I < 37.0) of
                                                        true ->
                                                            1.1796875;
                                                        false ->
                                                            1.171875
                                                    end;
                                                false ->
                                                    case (I < 39.0) of
                                                        true ->
                                                            1.171875;
                                                        false ->
                                                            1.1640625
                                                    end
                                            end
                                    end;
                                false ->
                                    case (I < 44.0) of
                                        true ->
                                            case (I < 42.0) of
                                                true ->
                                                    case (I < 41.0) of
                                                        true ->
                                                            1.15625;
                                                        false ->
                                                            1.1484375
                                                    end;
                                                false ->
                                                    case (I < 43.0) of
                                                        true ->
                                                            1.1484375;
                                                        false ->
                                                            1.140625
                                                    end
                                            end;
                                        false ->
                                            case (I < 46.0) of
                                                true ->
                                                    case (I < 45.0) of
                                                        true ->
                                                            1.140625;
                                                        false ->
                                                            1.1328125
                                                    end;
                                                false ->
                                                    case (I < 47.0) of
                                                        true ->
                                                            1.125;
                                                        false ->
                                                            1.125
                                                    end
                                            end
                                    end
                            end;
                        false ->
                            case (I < 56.0) of
                                true ->
                                    case (I < 52.0) of
                                        true ->
                                            case (I < 50.0) of
                                                true ->
                                                    case (I < 49.0) of
                                                        true ->
                                                            1.1171875;
                                                        false ->
                                                            1.109375
                                                    end;
                                                false ->
                                                    case (I < 51.0) of
                                                        true ->
                                                            1.109375;
                                                        false ->
                                                            1.1015625
                                                    end
                                            end;
                                        false ->
                                            case (I < 54.0) of
                                                true ->
                                                    case (I < 53.0) of
                                                        true ->
                                                            1.1015625;
                                                        false ->
                                                            1.09375
                                                    end;
                                                false ->
                                                    case (I < 55.0) of
                                                        true ->
                                                            1.0859375;
                                                        false ->
                                                            1.0859375
                                                    end
                                            end
                                    end;
                                false ->
                                    case (I < 60.0) of
                                        true ->
                                            case (I < 58.0) of
                                                true ->
                                                    case (I < 57.0) of
                                                        true ->
                                                            1.078125;
                                                        false ->
                                                            1.078125
                                                    end;
                                                false ->
                                                    case (I < 59.0) of
                                                        true ->
                                                            1.0703125;
                                                        false ->
                                                            1.0625
                                                    end
                                            end;
                                        false ->
                                            case (I < 62.0) of
                                                true ->
                                                    case (I < 61.0) of
                                                        true ->
                                                            1.0625;
                                                        false ->
                                                            1.0546875
                                                    end;
                                                false ->
                                                    case (I < 63.0) of
                                                        true ->
                                                            1.0546875;
                                                        false ->
                                                            1.046875
                                                    end
                                            end
                                    end
                            end
                    end
            end;
        false ->
            case (I < 96.0) of
                true ->
                    case (I < 80.0) of
                        true ->
                            case (I < 72.0) of
                                true ->
                                    case (I < 68.0) of
                                        true ->
                                            case (I < 66.0) of
                                                true ->
                                                    case (I < 65.0) of
                                                        true ->
                                                            1.046875;
                                                        false ->
                                                            1.0390625
                                                    end;
                                                false ->
                                                    case (I < 67.0) of
                                                        true ->
                                                            1.0390625;
                                                        false ->
                                                            1.03125
                                                    end
                                            end;
                                        false ->
                                            case (I < 70.0) of
                                                true ->
                                                    case (I < 69.0) of
                                                        true ->
                                                            1.03125;
                                                        false ->
                                                            1.0234375
                                                    end;
                                                false ->
                                                    case (I < 71.0) of
                                                        true ->
                                                            1.015625;
                                                        false ->
                                                            1.015625
                                                    end
                                            end
                                    end;
                                false ->
                                    case (I < 76.0) of
                                        true ->
                                            case (I < 74.0) of
                                                true ->
                                                    case (I < 73.0) of
                                                        true ->
                                                            1.0078125;
                                                        false ->
                                                            1.0078125
                                                    end;
                                                false ->
                                                    case (I < 75.0) of
                                                        true ->
                                                            1.0;
                                                        false ->
                                                            1.0
                                                    end
                                            end;
                                        false ->
                                            case (I < 78.0) of
                                                true ->
                                                    case (I < 77.0) of
                                                        true ->
                                                            0.9921875;
                                                        false ->
                                                            0.984375
                                                    end;
                                                false ->
                                                    case (I < 79.0) of
                                                        true ->
                                                            0.9765625;
                                                        false ->
                                                            0.96875
                                                    end
                                            end
                                    end
                            end;
                        false ->
                            case (I < 88.0) of
                                true ->
                                    case (I < 84.0) of
                                        true ->
                                            case (I < 82.0) of
                                                true ->
                                                    case (I < 81.0) of
                                                        true ->
                                                            0.9609375;
                                                        false ->
                                                            0.953125
                                                    end;
                                                false ->
                                                    case (I < 83.0) of
                                                        true ->
                                                            0.9453125;
                                                        false ->
                                                            0.94140625
                                                    end
                                            end;
                                        false ->
                                            case (I < 86.0) of
                                                true ->
                                                    case (I < 85.0) of
                                                        true ->
                                                            0.93359375;
                                                        false ->
                                                            0.92578125
                                                    end;
                                                false ->
                                                    case (I < 87.0) of
                                                        true ->
                                                            0.91796875;
                                                        false ->
                                                            0.9140625
                                                    end
                                            end
                                    end;
                                false ->
                                    case (I < 92.0) of
                                        true ->
                                            case (I < 90.0) of
                                                true ->
                                                    case (I < 89.0) of
                                                        true ->
                                                            0.90625;
                                                        false ->
                                                            0.8984375
                                                    end;
                                                false ->
                                                    case (I < 91.0) of
                                                        true ->
                                                            0.89453125;
                                                        false ->
                                                            0.88671875
                                                    end
                                            end;
                                        false ->
                                            case (I < 94.0) of
                                                true ->
                                                    case (I < 93.0) of
                                                        true ->
                                                            0.8828125;
                                                        false ->
                                                            0.875
                                                    end;
                                                false ->
                                                    case (I < 95.0) of
                                                        true ->
                                                            0.87109375;
                                                        false ->
                                                            0.86328125
                                                    end
                                            end
                                    end
                            end
                    end;
                false ->
                    case (I < 112.0) of
                        true ->
                            case (I < 104.0) of
                                true ->
                                    case (I < 100.0) of
                                        true ->
                                            case (I < 98.0) of
                                                true ->
                                                    case (I < 97.0) of
                                                        true ->
                                                            0.859375;
                                                        false ->
                                                            0.8515625
                                                    end;
                                                false ->
                                                    case (I < 99.0) of
                                                        true ->
                                                            0.84765625;
                                                        false ->
                                                            0.83984375
                                                    end
                                            end;
                                        false ->
                                            case (I < 102.0) of
                                                true ->
                                                    case (I < 101.0) of
                                                        true ->
                                                            0.8359375;
                                                        false ->
                                                            0.83203125
                                                    end;
                                                false ->
                                                    case (I < 103.0) of
                                                        true ->
                                                            0.82421875;
                                                        false ->
                                                            0.8203125
                                                    end
                                            end
                                    end;
                                false ->
                                    case (I < 108.0) of
                                        true ->
                                            case (I < 106.0) of
                                                true ->
                                                    case (I < 105.0) of
                                                        true ->
                                                            0.8125;
                                                        false ->
                                                            0.80859375
                                                    end;
                                                false ->
                                                    case (I < 107.0) of
                                                        true ->
                                                            0.8046875;
                                                        false ->
                                                            0.80078125
                                                    end
                                            end;
                                        false ->
                                            case (I < 110.0) of
                                                true ->
                                                    case (I < 109.0) of
                                                        true ->
                                                            0.79296875;
                                                        false ->
                                                            0.7890625
                                                    end;
                                                false ->
                                                    case (I < 111.0) of
                                                        true ->
                                                            0.78515625;
                                                        false ->
                                                            0.78125
                                                    end
                                            end
                                    end
                            end;
                        false ->
                            case (I < 120.0) of
                                true ->
                                    case (I < 116.0) of
                                        true ->
                                            case (I < 114.0) of
                                                true ->
                                                    case (I < 113.0) of
                                                        true ->
                                                            0.7734375;
                                                        false ->
                                                            0.76953125
                                                    end;
                                                false ->
                                                    case (I < 115.0) of
                                                        true ->
                                                            0.765625;
                                                        false ->
                                                            0.76171875
                                                    end
                                            end;
                                        false ->
                                            case (I < 118.0) of
                                                true ->
                                                    case (I < 117.0) of
                                                        true ->
                                                            0.7578125;
                                                        false ->
                                                            0.75390625
                                                    end;
                                                false ->
                                                    case (I < 119.0) of
                                                        true ->
                                                            0.74609375;
                                                        false ->
                                                            0.7421875
                                                    end
                                            end
                                    end;
                                false ->
                                    case (I < 124.0) of
                                        true ->
                                            case (I < 122.0) of
                                                true ->
                                                    case (I < 121.0) of
                                                        true ->
                                                            0.73828125;
                                                        false ->
                                                            0.734375
                                                    end;
                                                false ->
                                                    case (I < 123.0) of
                                                        true ->
                                                            0.73046875;
                                                        false ->
                                                            0.7265625
                                                    end
                                            end;
                                        false ->
                                            case (I < 126.0) of
                                                true ->
                                                    case (I < 125.0) of
                                                        true ->
                                                            0.72265625;
                                                        false ->
                                                            0.71875
                                                    end;
                                                false ->
                                                    case (I < 127.0) of
                                                        true ->
                                                            0.71484375;
                                                        false ->
                                                            0.7109375
                                                    end
                                            end
                                    end
                            end
                    end
            end
    end.

% `__pow_log_data.tab[i].logc`: log c, its last bits rounded away so

% k·ln2hi + logc is exact.

powLogc(I) ->
    case (I < 64.0) of
        true ->
            case (I < 32.0) of
                true ->
                    case (I < 16.0) of
                        true ->
                            case (I < 8.0) of
                                true ->
                                    case (I < 4.0) of
                                        true ->
                                            case (I < 2.0) of
                                                true ->
                                                    case (I < 1.0) of
                                                        true ->
                                                            (-0.3464667673462145);
                                                        false ->
                                                            (-0.34092658697056777)
                                                    end;
                                                false ->
                                                    case (I < 3.0) of
                                                        true ->
                                                            (-0.3353555419211034);
                                                        false ->
                                                            (-0.3297532863724655)
                                                    end
                                            end;
                                        false ->
                                            case (I < 6.0) of
                                                true ->
                                                    case (I < 5.0) of
                                                        true ->
                                                            (-0.32411946865420305);
                                                        false ->
                                                            (-0.31845373111855224)
                                                    end;
                                                false ->
                                                    case (I < 7.0) of
                                                        true ->
                                                            (-0.31275571000389846);
                                                        false ->
                                                            (-0.3070250352949415)
                                                    end
                                            end
                                    end;
                                false ->
                                    case (I < 12.0) of
                                        true ->
                                            case (I < 10.0) of
                                                true ->
                                                    case (I < 9.0) of
                                                        true ->
                                                            (-0.3012613305781997);
                                                        false ->
                                                            (-0.2954642128938758)
                                                    end;
                                                false ->
                                                    case (I < 11.0) of
                                                        true ->
                                                            (-0.28963329258306203);
                                                        false ->
                                                            (-0.28963329258306203)
                                                    end
                                            end;
                                        false ->
                                            case (I < 14.0) of
                                                true ->
                                                    case (I < 13.0) of
                                                        true ->
                                                            (-0.28376817313062475);
                                                        false ->
                                                            (-0.27786845100342816)
                                                    end;
                                                false ->
                                                    case (I < 15.0) of
                                                        true ->
                                                            (-0.2719337154836694);
                                                        false ->
                                                            (-0.2659635484970977)
                                                    end
                                            end
                                    end
                            end;
                        false ->
                            case (I < 24.0) of
                                true ->
                                    case (I < 20.0) of
                                        true ->
                                            case (I < 18.0) of
                                                true ->
                                                    case (I < 17.0) of
                                                        true ->
                                                            (-0.25995752443691345);
                                                        false ->
                                                            (-0.25391520998095984)
                                                    end;
                                                false ->
                                                    case (I < 19.0) of
                                                        true ->
                                                            (-0.25391520998095984);
                                                        false ->
                                                            (-0.2478361639045943)
                                                    end
                                            end;
                                        false ->
                                            case (I < 22.0) of
                                                true ->
                                                    case (I < 21.0) of
                                                        true ->
                                                            (-0.2417199368871934);
                                                        false ->
                                                            (-0.23556607131274632)
                                                    end;
                                                false ->
                                                    case (I < 23.0) of
                                                        true ->
                                                            (-0.22937410106487732);
                                                        false ->
                                                            (-0.22314355131425145)
                                                    end
                                            end
                                    end;
                                false ->
                                    case (I < 28.0) of
                                        true ->
                                            case (I < 26.0) of
                                                true ->
                                                    case (I < 25.0) of
                                                        true ->
                                                            (-0.22314355131425145);
                                                        false ->
                                                            (-0.21687393830063684)
                                                    end;
                                                false ->
                                                    case (I < 27.0) of
                                                        true ->
                                                            (-0.21056476910735);
                                                        false ->
                                                            (-0.2042155414286526)
                                                    end
                                            end;
                                        false ->
                                            case (I < 30.0) of
                                                true ->
                                                    case (I < 29.0) of
                                                        true ->
                                                            (-0.2042155414286526);
                                                        false ->
                                                            (-0.19782574332987224)
                                                    end;
                                                false ->
                                                    case (I < 31.0) of
                                                        true ->
                                                            (-0.19139485299967873);
                                                        false ->
                                                            (-0.18492233849406148)
                                                    end
                                            end
                                    end
                            end
                    end;
                false ->
                    case (I < 48.0) of
                        true ->
                            case (I < 40.0) of
                                true ->
                                    case (I < 36.0) of
                                        true ->
                                            case (I < 34.0) of
                                                true ->
                                                    case (I < 33.0) of
                                                        true ->
                                                            (-0.18492233849406148);
                                                        false ->
                                                            (-0.1784076574728033)
                                                    end;
                                                false ->
                                                    case (I < 35.0) of
                                                        true ->
                                                            (-0.17185025692663203);
                                                        false ->
                                                            (-0.17185025692663203)
                                                    end
                                            end;
                                        false ->
                                            case (I < 38.0) of
                                                true ->
                                                    case (I < 37.0) of
                                                        true ->
                                                            (-0.1652495728952772);
                                                        false ->
                                                            (-0.15860503017665906)
                                                    end;
                                                false ->
                                                    case (I < 39.0) of
                                                        true ->
                                                            (-0.15860503017665906);
                                                        false ->
                                                            (-0.15191604202584585)
                                                    end
                                            end
                                    end;
                                false ->
                                    case (I < 44.0) of
                                        true ->
                                            case (I < 42.0) of
                                                true ->
                                                    case (I < 41.0) of
                                                        true ->
                                                            (-0.1451820098444614);
                                                        false ->
                                                            (-0.13840232285906495)
                                                    end;
                                                false ->
                                                    case (I < 43.0) of
                                                        true ->
                                                            (-0.13840232285906495);
                                                        false ->
                                                            (-0.131576357788731)
                                                    end
                                            end;
                                        false ->
                                            case (I < 46.0) of
                                                true ->
                                                    case (I < 45.0) of
                                                        true ->
                                                            (-0.131576357788731);
                                                        false ->
                                                            (-0.12470347850091912)
                                                    end;
                                                false ->
                                                    case (I < 47.0) of
                                                        true ->
                                                            (-0.11778303565643);
                                                        false ->
                                                            (-0.11778303565643)
                                                    end
                                            end
                                    end
                            end;
                        false ->
                            case (I < 56.0) of
                                true ->
                                    case (I < 52.0) of
                                        true ->
                                            case (I < 50.0) of
                                                true ->
                                                    case (I < 49.0) of
                                                        true ->
                                                            (-0.11081436634026431);
                                                        false ->
                                                            (-0.10379679368168127)
                                                    end;
                                                false ->
                                                    case (I < 51.0) of
                                                        true ->
                                                            (-0.10379679368168127);
                                                        false ->
                                                            (-0.09672962645856842)
                                                    end
                                            end;
                                        false ->
                                            case (I < 54.0) of
                                                true ->
                                                    case (I < 53.0) of
                                                        true ->
                                                            (-0.09672962645856842);
                                                        false ->
                                                            (-0.089612158689647)
                                                    end;
                                                false ->
                                                    case (I < 55.0) of
                                                        true ->
                                                            (-0.08244366921110213);
                                                        false ->
                                                            (-0.08244366921110213)
                                                    end
                                            end
                                    end;
                                false ->
                                    case (I < 60.0) of
                                        true ->
                                            case (I < 58.0) of
                                                true ->
                                                    case (I < 57.0) of
                                                        true ->
                                                            (-0.07522342123763792);
                                                        false ->
                                                            (-0.07522342123763792)
                                                    end;
                                                false ->
                                                    case (I < 59.0) of
                                                        true ->
                                                            (-0.06795066190852594);
                                                        false ->
                                                            (-0.06062462181648698)
                                                    end
                                            end;
                                        false ->
                                            case (I < 62.0) of
                                                true ->
                                                    case (I < 61.0) of
                                                        true ->
                                                            (-0.06062462181648698);
                                                        false ->
                                                            (-0.053244514518837605)
                                                    end;
                                                false ->
                                                    case (I < 63.0) of
                                                        true ->
                                                            (-0.053244514518837605);
                                                        false ->
                                                            (-0.045809536031242715)
                                                    end
                                            end
                                    end
                            end
                    end
            end;
        false ->
            case (I < 96.0) of
                true ->
                    case (I < 80.0) of
                        true ->
                            case (I < 72.0) of
                                true ->
                                    case (I < 68.0) of
                                        true ->
                                            case (I < 66.0) of
                                                true ->
                                                    case (I < 65.0) of
                                                        true ->
                                                            (-0.045809536031242715);
                                                        false ->
                                                            (-0.038318864302141264)
                                                    end;
                                                false ->
                                                    case (I < 67.0) of
                                                        true ->
                                                            (-0.038318864302141264);
                                                        false ->
                                                            (-0.03077165866670839)
                                                    end
                                            end;
                                        false ->
                                            case (I < 70.0) of
                                                true ->
                                                    case (I < 69.0) of
                                                        true ->
                                                            (-0.03077165866670839);
                                                        false ->
                                                            (-0.023167059281490765)
                                                    end;
                                                false ->
                                                    case (I < 71.0) of
                                                        true ->
                                                            (-0.015504186535963527);
                                                        false ->
                                                            (-0.015504186535963527)
                                                    end
                                            end
                                    end;
                                false ->
                                    case (I < 76.0) of
                                        true ->
                                            case (I < 74.0) of
                                                true ->
                                                    case (I < 73.0) of
                                                        true ->
                                                            (-0.0077821404420319595);
                                                        false ->
                                                            (-0.0077821404420319595)
                                                    end;
                                                false ->
                                                    case (I < 75.0) of
                                                        true ->
                                                            0.0;
                                                        false ->
                                                            0.0
                                                    end
                                            end;
                                        false ->
                                            case (I < 78.0) of
                                                true ->
                                                    case (I < 77.0) of
                                                        true ->
                                                            0.007843177461040796;
                                                        false ->
                                                            0.01574835696817445
                                                    end;
                                                false ->
                                                    case (I < 79.0) of
                                                        true ->
                                                            0.023716526617363343;
                                                        false ->
                                                            0.03174869831457272
                                                    end
                                            end
                                    end
                            end;
                        false ->
                            case (I < 88.0) of
                                true ->
                                    case (I < 84.0) of
                                        true ->
                                            case (I < 82.0) of
                                                true ->
                                                    case (I < 81.0) of
                                                        true ->
                                                            0.039845908547249564;
                                                        false ->
                                                            0.048009219186383234
                                                    end;
                                                false ->
                                                    case (I < 83.0) of
                                                        true ->
                                                            0.056239718322899535;
                                                        false ->
                                                            0.06038051098892083
                                                    end
                                            end;
                                        false ->
                                            case (I < 86.0) of
                                                true ->
                                                    case (I < 85.0) of
                                                        true ->
                                                            0.06871389254808946;
                                                        false ->
                                                            0.07711730334438016
                                                    end;
                                                false ->
                                                    case (I < 87.0) of
                                                        true ->
                                                            0.08559193033545398;
                                                        false ->
                                                            0.08985632912185793
                                                    end
                                            end
                                    end;
                                false ->
                                    case (I < 92.0) of
                                        true ->
                                            case (I < 90.0) of
                                                true ->
                                                    case (I < 89.0) of
                                                        true ->
                                                            0.09844007281321865;
                                                        false ->
                                                            0.10709813555638448
                                                    end;
                                                false ->
                                                    case (I < 91.0) of
                                                        true ->
                                                            0.11145544092528326;
                                                        false ->
                                                            0.12022742699821265
                                                    end
                                            end;
                                        false ->
                                            case (I < 94.0) of
                                                true ->
                                                    case (I < 93.0) of
                                                        true ->
                                                            0.12464244520731427;
                                                        false ->
                                                            0.13353139262449076
                                                    end;
                                                false ->
                                                    case (I < 95.0) of
                                                        true ->
                                                            0.13800567301939282;
                                                        false ->
                                                            0.14701474296180095
                                                    end
                                            end
                                    end
                            end
                    end;
                false ->
                    case (I < 112.0) of
                        true ->
                            case (I < 104.0) of
                                true ->
                                    case (I < 100.0) of
                                        true ->
                                            case (I < 98.0) of
                                                true ->
                                                    case (I < 97.0) of
                                                        true ->
                                                            0.15154989812720032;
                                                        false ->
                                                            0.16068238169043525
                                                    end;
                                                false ->
                                                    case (I < 99.0) of
                                                        true ->
                                                            0.16528009093906348;
                                                        false ->
                                                            0.17453941635187675
                                                    end
                                            end;
                                        false ->
                                            case (I < 102.0) of
                                                true ->
                                                    case (I < 101.0) of
                                                        true ->
                                                            0.17920142945774842;
                                                        false ->
                                                            0.18388527877016259
                                                    end;
                                                false ->
                                                    case (I < 103.0) of
                                                        true ->
                                                            0.1933193110035063;
                                                        false ->
                                                            0.19806991376208316
                                                    end
                                            end
                                    end;
                                false ->
                                    case (I < 108.0) of
                                        true ->
                                            case (I < 106.0) of
                                                true ->
                                                    case (I < 105.0) of
                                                        true ->
                                                            0.20763936477828793;
                                                        false ->
                                                            0.21245865121420593
                                                    end;
                                                false ->
                                                    case (I < 107.0) of
                                                        true ->
                                                            0.21730127569003344;
                                                        false ->
                                                            0.22216746534115828
                                                    end
                                            end;
                                        false ->
                                            case (I < 110.0) of
                                                true ->
                                                    case (I < 109.0) of
                                                        true ->
                                                            0.2319714654378231;
                                                        false ->
                                                            0.2369097470783572
                                                    end;
                                                false ->
                                                    case (I < 111.0) of
                                                        true ->
                                                            0.24187253642048745;
                                                        false ->
                                                            0.2468600779315011
                                                    end
                                            end
                                    end
                            end;
                        false ->
                            case (I < 120.0) of
                                true ->
                                    case (I < 116.0) of
                                        true ->
                                            case (I < 114.0) of
                                                true ->
                                                    case (I < 113.0) of
                                                        true ->
                                                            0.2569104137850218;
                                                        false ->
                                                            0.26197371574153294
                                                    end;
                                                false ->
                                                    case (I < 115.0) of
                                                        true ->
                                                            0.2670627852490952;
                                                        false ->
                                                            0.27217788591576664
                                                    end
                                            end;
                                        false ->
                                            case (I < 118.0) of
                                                true ->
                                                    case (I < 117.0) of
                                                        true ->
                                                            0.27731928541618345;
                                                        false ->
                                                            0.28248725557466514
                                                    end;
                                                false ->
                                                    case (I < 119.0) of
                                                        true ->
                                                            0.29290401643288533;
                                                        false ->
                                                            0.29815337231912054
                                                    end
                                            end
                                    end;
                                false ->
                                    case (I < 124.0) of
                                        true ->
                                            case (I < 122.0) of
                                                true ->
                                                    case (I < 121.0) of
                                                        true ->
                                                            0.3034304294199046;
                                                        false ->
                                                            0.30873548164959175
                                                    end;
                                                false ->
                                                    case (I < 123.0) of
                                                        true ->
                                                            0.3140688276249648;
                                                        false ->
                                                            0.31943077076641657
                                                    end
                                            end;
                                        false ->
                                            case (I < 126.0) of
                                                true ->
                                                    case (I < 125.0) of
                                                        true ->
                                                            0.3248216194012912;
                                                        false ->
                                                            0.33024168687052224
                                                    end;
                                                false ->
                                                    case (I < 127.0) of
                                                        true ->
                                                            0.3356912916381134;
                                                        false ->
                                                            0.3411707574027787
                                                    end
                                            end
                                    end
                            end
                    end
            end
    end.

% `__pow_log_data.tab[i].logctail`: log c − logc.

powLogctail(I) ->
    case (I < 64.0) of
        true ->
            case (I < 32.0) of
                true ->
                    case (I < 16.0) of
                        true ->
                            case (I < 8.0) of
                                true ->
                                    case (I < 4.0) of
                                        true ->
                                            case (I < 2.0) of
                                                true ->
                                                    case (I < 1.0) of
                                                        true ->
                                                            5.929407345889625e-15;
                                                        false ->
                                                            (-2.544157440035963e-14)
                                                    end;
                                                false ->
                                                    case (I < 3.0) of
                                                        true ->
                                                            (-3.443525940775045e-14);
                                                        false ->
                                                            (-2.500123826022799e-15)
                                                    end
                                            end;
                                        false ->
                                            case (I < 6.0) of
                                                true ->
                                                    case (I < 5.0) of
                                                        true ->
                                                            (-8.929337133850617e-15);
                                                        false ->
                                                            1.7625431312172662e-14
                                                    end;
                                                false ->
                                                    case (I < 7.0) of
                                                        true ->
                                                            1.5688303180062087e-15;
                                                        false ->
                                                            2.9655274673691784e-14
                                                    end
                                            end
                                    end;
                                false ->
                                    case (I < 12.0) of
                                        true ->
                                            case (I < 10.0) of
                                                true ->
                                                    case (I < 9.0) of
                                                        true ->
                                                            3.7923164802093147e-14;
                                                        false ->
                                                            3.993416384387844e-14
                                                    end;
                                                false ->
                                                    case (I < 11.0) of
                                                        true ->
                                                            1.9352855826489123e-14;
                                                        false ->
                                                            1.9352855826489123e-14
                                                    end
                                            end;
                                        false ->
                                            case (I < 14.0) of
                                                true ->
                                                    case (I < 13.0) of
                                                        true ->
                                                            (-1.9852665484979036e-14);
                                                        false ->
                                                            (-2.814323765595281e-14)
                                                    end;
                                                false ->
                                                    case (I < 15.0) of
                                                        true ->
                                                            2.7643769993528702e-14;
                                                        false ->
                                                            (-4.025092402293806e-14)
                                                    end
                                            end
                                    end
                            end;
                        false ->
                            case (I < 24.0) of
                                true ->
                                    case (I < 20.0) of
                                        true ->
                                            case (I < 18.0) of
                                                true ->
                                                    case (I < 17.0) of
                                                        true ->
                                                            (-1.2621729398885316e-14);
                                                        false ->
                                                            (-3.600176732637335e-15)
                                                    end;
                                                false ->
                                                    case (I < 19.0) of
                                                        true ->
                                                            (-3.600176732637335e-15);
                                                        false ->
                                                            1.3029797173308663e-14
                                                    end
                                            end;
                                        false ->
                                            case (I < 22.0) of
                                                true ->
                                                    case (I < 21.0) of
                                                        true ->
                                                            4.8230289429940886e-14;
                                                        false ->
                                                            (-2.0592242769647135e-14)
                                                    end;
                                                false ->
                                                    case (I < 23.0) of
                                                        true ->
                                                            3.149265065191484e-14;
                                                        false ->
                                                            4.169796584527195e-14
                                                    end
                                            end
                                    end;
                                false ->
                                    case (I < 28.0) of
                                        true ->
                                            case (I < 26.0) of
                                                true ->
                                                    case (I < 25.0) of
                                                        true ->
                                                            4.169796584527195e-14;
                                                        false ->
                                                            2.2477465222466186e-14
                                                    end;
                                                false ->
                                                    case (I < 27.0) of
                                                        true ->
                                                            3.6507188831790577e-16;
                                                        false ->
                                                            (-3.827767260205414e-14)
                                                    end
                                            end;
                                        false ->
                                            case (I < 30.0) of
                                                true ->
                                                    case (I < 29.0) of
                                                        true ->
                                                            (-3.827767260205414e-14);
                                                        false ->
                                                            (-4.7641388950792196e-14)
                                                    end;
                                                false ->
                                                    case (I < 31.0) of
                                                        true ->
                                                            4.9278276214647115e-14;
                                                        false ->
                                                            4.9485167661250996e-14
                                                    end
                                            end
                                    end
                            end
                    end;
                false ->
                    case (I < 48.0) of
                        true ->
                            case (I < 40.0) of
                                true ->
                                    case (I < 36.0) of
                                        true ->
                                            case (I < 34.0) of
                                                true ->
                                                    case (I < 33.0) of
                                                        true ->
                                                            4.9485167661250996e-14;
                                                        false ->
                                                            (-1.5003333854266542e-14)
                                                    end;
                                                false ->
                                                    case (I < 35.0) of
                                                        true ->
                                                            (-2.7194441649495324e-14);
                                                        false ->
                                                            (-2.7194441649495324e-14)
                                                    end
                                            end;
                                        false ->
                                            case (I < 38.0) of
                                                true ->
                                                    case (I < 37.0) of
                                                        true ->
                                                            (-2.99659267292569e-14);
                                                        false ->
                                                            2.0472357800461955e-14
                                                    end;
                                                false ->
                                                    case (I < 39.0) of
                                                        true ->
                                                            2.0472357800461955e-14;
                                                        false ->
                                                            3.879296723063646e-15
                                                    end
                                            end
                                    end;
                                false ->
                                    case (I < 44.0) of
                                        true ->
                                            case (I < 42.0) of
                                                true ->
                                                    case (I < 41.0) of
                                                        true ->
                                                            (-3.6506824353335045e-14);
                                                        false ->
                                                            (-5.4183331379008994e-14)
                                                    end;
                                                false ->
                                                    case (I < 43.0) of
                                                        true ->
                                                            (-5.4183331379008994e-14);
                                                        false ->
                                                            1.1729485484531301e-14
                                                    end
                                            end;
                                        false ->
                                            case (I < 46.0) of
                                                true ->
                                                    case (I < 45.0) of
                                                        true ->
                                                            1.1729485484531301e-14;
                                                        false ->
                                                            (-3.811763084710266e-14)
                                                    end;
                                                false ->
                                                    case (I < 47.0) of
                                                        true ->
                                                            4.654729747598445e-14;
                                                        false ->
                                                            4.654729747598445e-14
                                                    end
                                            end
                                    end
                            end;
                        false ->
                            case (I < 56.0) of
                                true ->
                                    case (I < 52.0) of
                                        true ->
                                            case (I < 50.0) of
                                                true ->
                                                    case (I < 49.0) of
                                                        true ->
                                                            (-2.5799991283069902e-14);
                                                        false ->
                                                            3.7700471749674615e-14
                                                    end;
                                                false ->
                                                    case (I < 51.0) of
                                                        true ->
                                                            3.7700471749674615e-14;
                                                        false ->
                                                            1.7306161136093256e-14
                                                    end
                                            end;
                                        false ->
                                            case (I < 54.0) of
                                                true ->
                                                    case (I < 53.0) of
                                                        true ->
                                                            1.7306161136093256e-14;
                                                        false ->
                                                            (-4.012913552726574e-14)
                                                    end;
                                                false ->
                                                    case (I < 55.0) of
                                                        true ->
                                                            2.7541708360737882e-14;
                                                        false ->
                                                            2.7541708360737882e-14
                                                    end
                                            end
                                    end;
                                false ->
                                    case (I < 60.0) of
                                        true ->
                                            case (I < 58.0) of
                                                true ->
                                                    case (I < 57.0) of
                                                        true ->
                                                            5.0396178134370583e-14;
                                                        false ->
                                                            5.0396178134370583e-14
                                                    end;
                                                false ->
                                                    case (I < 59.0) of
                                                        true ->
                                                            1.8195060030168815e-14;
                                                        false ->
                                                            5.213620639136504e-14
                                                    end
                                            end;
                                        false ->
                                            case (I < 62.0) of
                                                true ->
                                                    case (I < 61.0) of
                                                        true ->
                                                            5.213620639136504e-14;
                                                        false ->
                                                            2.532168943117445e-14
                                                    end;
                                                false ->
                                                    case (I < 63.0) of
                                                        true ->
                                                            2.532168943117445e-14;
                                                        false ->
                                                            (-5.148849572685811e-14)
                                                    end
                                            end
                                    end
                            end
                    end
            end;
        false ->
            case (I < 96.0) of
                true ->
                    case (I < 80.0) of
                        true ->
                            case (I < 72.0) of
                                true ->
                                    case (I < 68.0) of
                                        true ->
                                            case (I < 66.0) of
                                                true ->
                                                    case (I < 65.0) of
                                                        true ->
                                                            (-5.148849572685811e-14);
                                                        false ->
                                                            4.6652946995830086e-15
                                                    end;
                                                false ->
                                                    case (I < 67.0) of
                                                        true ->
                                                            4.6652946995830086e-15;
                                                        false ->
                                                            (-4.529814257790929e-14)
                                                    end
                                            end;
                                        false ->
                                            case (I < 70.0) of
                                                true ->
                                                    case (I < 69.0) of
                                                        true ->
                                                            (-4.529814257790929e-14);
                                                        false ->
                                                            (-4.361324067851568e-14)
                                                    end;
                                                false ->
                                                    case (I < 71.0) of
                                                        true ->
                                                            (-1.7274567499706107e-15);
                                                        false ->
                                                            (-1.7274567499706107e-15)
                                                    end
                                            end
                                    end;
                                false ->
                                    case (I < 76.0) of
                                        true ->
                                            case (I < 74.0) of
                                                true ->
                                                    case (I < 73.0) of
                                                        true ->
                                                            (-2.298941004620351e-14);
                                                        false ->
                                                            (-2.298941004620351e-14)
                                                    end;
                                                false ->
                                                    case (I < 75.0) of
                                                        true ->
                                                            0.0;
                                                        false ->
                                                            0.0
                                                    end
                                            end;
                                        false ->
                                            case (I < 78.0) of
                                                true ->
                                                    case (I < 77.0) of
                                                        true ->
                                                            (-1.4902732911301337e-14);
                                                        false ->
                                                            (-3.527980389655325e-14)
                                                    end;
                                                false ->
                                                    case (I < 79.0) of
                                                        true ->
                                                            (-4.730054772033249e-14);
                                                        false ->
                                                            7.580310369375161e-15
                                                    end
                                            end
                                    end
                            end;
                        false ->
                            case (I < 88.0) of
                                true ->
                                    case (I < 84.0) of
                                        true ->
                                            case (I < 82.0) of
                                                true ->
                                                    case (I < 81.0) of
                                                        true ->
                                                            (-4.9893776716773285e-14);
                                                        false ->
                                                            (-2.262629393030674e-14)
                                                    end;
                                                false ->
                                                    case (I < 83.0) of
                                                        true ->
                                                            (-2.345674491018699e-14);
                                                        false ->
                                                            (-1.3352588834854848e-14)
                                                    end
                                            end;
                                        false ->
                                            case (I < 86.0) of
                                                true ->
                                                    case (I < 85.0) of
                                                        true ->
                                                            (-3.765296820388875e-14);
                                                        false ->
                                                            5.1128335719851986e-14
                                                    end;
                                                false ->
                                                    case (I < 87.0) of
                                                        true ->
                                                            (-5.046674438470119e-14);
                                                        false ->
                                                            3.1218748807418837e-15
                                                    end
                                            end
                                    end;
                                false ->
                                    case (I < 92.0) of
                                        true ->
                                            case (I < 90.0) of
                                                true ->
                                                    case (I < 89.0) of
                                                        true ->
                                                            3.3871241029241416e-14;
                                                        false ->
                                                            (-1.7376727386423858e-14)
                                                    end;
                                                false ->
                                                    case (I < 91.0) of
                                                        true ->
                                                            3.957125899799804e-14;
                                                        false ->
                                                            (-5.2849453521890294e-14)
                                                    end
                                            end;
                                        false ->
                                            case (I < 94.0) of
                                                true ->
                                                    case (I < 93.0) of
                                                        true ->
                                                            (-3.767012502308738e-14);
                                                        false ->
                                                            3.1859736349078334e-14
                                                    end;
                                                false ->
                                                    case (I < 95.0) of
                                                        true ->
                                                            5.0900642926060466e-14;
                                                        false ->
                                                            8.710783796122478e-15
                                                    end
                                            end
                                    end
                            end
                    end;
                false ->
                    case (I < 112.0) of
                        true ->
                            case (I < 104.0) of
                                true ->
                                    case (I < 100.0) of
                                        true ->
                                            case (I < 98.0) of
                                                true ->
                                                    case (I < 97.0) of
                                                        true ->
                                                            6.157896229122976e-16;
                                                        false ->
                                                            3.821577743916796e-14
                                                    end;
                                                false ->
                                                    case (I < 99.0) of
                                                        true ->
                                                            3.9440046718453496e-14;
                                                        false ->
                                                            2.2924522154618074e-14
                                                    end
                                            end;
                                        false ->
                                            case (I < 102.0) of
                                                true ->
                                                    case (I < 101.0) of
                                                        true ->
                                                            (-3.742530094732263e-14);
                                                        false ->
                                                            (-2.5223102140407338e-14)
                                                    end;
                                                false ->
                                                    case (I < 103.0) of
                                                        true ->
                                                            (-1.0320443688698849e-14);
                                                        false ->
                                                            1.0634128304268335e-14
                                                    end
                                            end
                                    end;
                                false ->
                                    case (I < 108.0) of
                                        true ->
                                            case (I < 106.0) of
                                                true ->
                                                    case (I < 105.0) of
                                                        true ->
                                                            (-4.3425422595242564e-14);
                                                        false ->
                                                            (-1.2527395755711364e-14)
                                                    end;
                                                false ->
                                                    case (I < 107.0) of
                                                        true ->
                                                            (-5.204008743405884e-14);
                                                        false ->
                                                            (-3.979844515951702e-15)
                                                    end
                                            end;
                                        false ->
                                            case (I < 110.0) of
                                                true ->
                                                    case (I < 109.0) of
                                                        true ->
                                                            (-4.7955860343296286e-14);
                                                        false ->
                                                            5.015686013791602e-16
                                                    end;
                                                false ->
                                                    case (I < 111.0) of
                                                        true ->
                                                            (-7.252318953240293e-16);
                                                        false ->
                                                            2.4688324156011588e-14
                                                    end
                                            end
                                    end
                            end;
                        false ->
                            case (I < 120.0) of
                                true ->
                                    case (I < 116.0) of
                                        true ->
                                            case (I < 114.0) of
                                                true ->
                                                    case (I < 113.0) of
                                                        true ->
                                                            5.465121253624792e-15;
                                                        false ->
                                                            4.102651071698446e-14
                                                    end;
                                                false ->
                                                    case (I < 115.0) of
                                                        true ->
                                                            (-4.996736502345936e-14);
                                                        false ->
                                                            4.903580708156347e-14
                                                    end
                                            end;
                                        false ->
                                            case (I < 118.0) of
                                                true ->
                                                    case (I < 117.0) of
                                                        true ->
                                                            5.089628039500759e-14;
                                                        false ->
                                                            1.1782016386565151e-14
                                                    end;
                                                false ->
                                                    case (I < 119.0) of
                                                        true ->
                                                            4.727452940514406e-14;
                                                        false ->
                                                            (-4.4204083338755686e-14)
                                                    end
                                            end
                                    end;
                                false ->
                                    case (I < 124.0) of
                                        true ->
                                            case (I < 122.0) of
                                                true ->
                                                    case (I < 121.0) of
                                                        true ->
                                                            1.548345993498083e-14;
                                                        false ->
                                                            2.1522127491642888e-14
                                                    end;
                                                false ->
                                                    case (I < 123.0) of
                                                        true ->
                                                            1.1054030169005386e-14;
                                                        false ->
                                                            (-5.534326352070679e-14)
                                                    end
                                            end;
                                        false ->
                                            case (I < 126.0) of
                                                true ->
                                                    case (I < 125.0) of
                                                        true ->
                                                            (-5.351646604259541e-14);
                                                        false ->
                                                            5.4612144489920215e-14
                                                    end;
                                                false ->
                                                    case (I < 127.0) of
                                                        true ->
                                                            2.8136969901227338e-14;
                                                        false ->
                                                            (-1.156568624616423e-14)
                                                    end
                                            end
                                    end
                            end
                    end
            end
    end.

% 2^(j/128) rounded to the nearest double (`__exp_data.tab[2j + 1]` with

% its exponent bits restored).

expHead(J) ->
    case (J < 64.0) of
        true ->
            case (J < 32.0) of
                true ->
                    case (J < 16.0) of
                        true ->
                            case (J < 8.0) of
                                true ->
                                    case (J < 4.0) of
                                        true ->
                                            case (J < 2.0) of
                                                true ->
                                                    case (J < 1.0) of
                                                        true ->
                                                            1.0;
                                                        false ->
                                                            1.0054299011128027
                                                    end;
                                                false ->
                                                    case (J < 3.0) of
                                                        true ->
                                                            1.0108892860517005;
                                                        false ->
                                                            1.016378314910953
                                                    end
                                            end;
                                        false ->
                                            case (J < 6.0) of
                                                true ->
                                                    case (J < 5.0) of
                                                        true ->
                                                            1.0218971486541166;
                                                        false ->
                                                            1.0274459491187637
                                                    end;
                                                false ->
                                                    case (J < 7.0) of
                                                        true ->
                                                            1.0330248790212284;
                                                        false ->
                                                            1.0386341019613787
                                                    end
                                            end
                                    end;
                                false ->
                                    case (J < 12.0) of
                                        true ->
                                            case (J < 10.0) of
                                                true ->
                                                    case (J < 9.0) of
                                                        true ->
                                                            1.0442737824274138;
                                                        false ->
                                                            1.0499440858006872
                                                    end;
                                                false ->
                                                    case (J < 11.0) of
                                                        true ->
                                                            1.0556451783605572;
                                                        false ->
                                                            1.061377227289262
                                                    end
                                            end;
                                        false ->
                                            case (J < 14.0) of
                                                true ->
                                                    case (J < 13.0) of
                                                        true ->
                                                            1.0671404006768237;
                                                        false ->
                                                            1.0729348675259756
                                                    end;
                                                false ->
                                                    case (J < 15.0) of
                                                        true ->
                                                            1.0787607977571199;
                                                        false ->
                                                            1.0846183622133092
                                                    end
                                            end
                                    end
                            end;
                        false ->
                            case (J < 24.0) of
                                true ->
                                    case (J < 20.0) of
                                        true ->
                                            case (J < 18.0) of
                                                true ->
                                                    case (J < 17.0) of
                                                        true ->
                                                            1.0905077326652577;
                                                        false ->
                                                            1.0964290818163769
                                                    end;
                                                false ->
                                                    case (J < 19.0) of
                                                        true ->
                                                            1.102382583307841;
                                                        false ->
                                                            1.1083684117236787
                                                    end
                                            end;
                                        false ->
                                            case (J < 22.0) of
                                                true ->
                                                    case (J < 21.0) of
                                                        true ->
                                                            1.1143867425958924;
                                                        false ->
                                                            1.1204377524096067
                                                    end;
                                                false ->
                                                    case (J < 23.0) of
                                                        true ->
                                                            1.1265216186082418;
                                                        false ->
                                                            1.1326385195987192
                                                    end
                                            end
                                    end;
                                false ->
                                    case (J < 28.0) of
                                        true ->
                                            case (J < 26.0) of
                                                true ->
                                                    case (J < 25.0) of
                                                        true ->
                                                            1.1387886347566916;
                                                        false ->
                                                            1.1449721444318042
                                                    end;
                                                false ->
                                                    case (J < 27.0) of
                                                        true ->
                                                            1.1511892299529827;
                                                        false ->
                                                            1.1574400736337511
                                                    end
                                            end;
                                        false ->
                                            case (J < 30.0) of
                                                true ->
                                                    case (J < 29.0) of
                                                        true ->
                                                            1.1637248587775775;
                                                        false ->
                                                            1.1700437696832502
                                                    end;
                                                false ->
                                                    case (J < 31.0) of
                                                        true ->
                                                            1.1763969916502812;
                                                        false ->
                                                            1.182784710984341
                                                    end
                                            end
                                    end
                            end
                    end;
                false ->
                    case (J < 48.0) of
                        true ->
                            case (J < 40.0) of
                                true ->
                                    case (J < 36.0) of
                                        true ->
                                            case (J < 34.0) of
                                                true ->
                                                    case (J < 33.0) of
                                                        true ->
                                                            1.189207115002721;
                                                        false ->
                                                            1.1956643920398273
                                                    end;
                                                false ->
                                                    case (J < 35.0) of
                                                        true ->
                                                            1.202156731452703;
                                                        false ->
                                                            1.2086843236265816
                                                    end
                                            end;
                                        false ->
                                            case (J < 38.0) of
                                                true ->
                                                    case (J < 37.0) of
                                                        true ->
                                                            1.215247359980469;
                                                        false ->
                                                            1.2218460329727576
                                                    end;
                                                false ->
                                                    case (J < 39.0) of
                                                        true ->
                                                            1.22848053610687;
                                                        false ->
                                                            1.2351510639369334
                                                    end
                                            end
                                    end;
                                false ->
                                    case (J < 44.0) of
                                        true ->
                                            case (J < 42.0) of
                                                true ->
                                                    case (J < 41.0) of
                                                        true ->
                                                            1.241857812073484;
                                                        false ->
                                                            1.2486009771892048
                                                    end;
                                                false ->
                                                    case (J < 43.0) of
                                                        true ->
                                                            1.255380757024691;
                                                        false ->
                                                            1.2621973503942507
                                                    end
                                            end;
                                        false ->
                                            case (J < 46.0) of
                                                true ->
                                                    case (J < 45.0) of
                                                        true ->
                                                            1.2690509571917332;
                                                        false ->
                                                            1.275941778396392
                                                    end;
                                                false ->
                                                    case (J < 47.0) of
                                                        true ->
                                                            1.2828700160787783;
                                                        false ->
                                                            1.2898358734066657
                                                    end
                                            end
                                    end
                            end;
                        false ->
                            case (J < 56.0) of
                                true ->
                                    case (J < 52.0) of
                                        true ->
                                            case (J < 50.0) of
                                                true ->
                                                    case (J < 49.0) of
                                                        true ->
                                                            1.2968395546510096;
                                                        false ->
                                                            1.3038812651919358
                                                    end;
                                                false ->
                                                    case (J < 51.0) of
                                                        true ->
                                                            1.3109612115247644;
                                                        false ->
                                                            1.318079601266064
                                                    end
                                            end;
                                        false ->
                                            case (J < 54.0) of
                                                true ->
                                                    case (J < 53.0) of
                                                        true ->
                                                            1.3252366431597413;
                                                        false ->
                                                            1.3324325470831615
                                                    end;
                                                false ->
                                                    case (J < 55.0) of
                                                        true ->
                                                            1.339667524053303;
                                                        false ->
                                                            1.3469417862329458
                                                    end
                                            end
                                    end;
                                false ->
                                    case (J < 60.0) of
                                        true ->
                                            case (J < 58.0) of
                                                true ->
                                                    case (J < 57.0) of
                                                        true ->
                                                            1.3542555469368927;
                                                        false ->
                                                            1.3616090206382248
                                                    end;
                                                false ->
                                                    case (J < 59.0) of
                                                        true ->
                                                            1.3690024229745905;
                                                        false ->
                                                            1.3764359707545302
                                                    end
                                            end;
                                        false ->
                                            case (J < 62.0) of
                                                true ->
                                                    case (J < 61.0) of
                                                        true ->
                                                            1.383909881963832;
                                                        false ->
                                                            1.3914243757719262
                                                    end;
                                                false ->
                                                    case (J < 63.0) of
                                                        true ->
                                                            1.3989796725383112;
                                                        false ->
                                                            1.4065759938190154
                                                    end
                                            end
                                    end
                            end
                    end
            end;
        false ->
            case (J < 96.0) of
                true ->
                    case (J < 80.0) of
                        true ->
                            case (J < 72.0) of
                                true ->
                                    case (J < 68.0) of
                                        true ->
                                            case (J < 66.0) of
                                                true ->
                                                    case (J < 65.0) of
                                                        true ->
                                                            1.4142135623730951;
                                                        false ->
                                                            1.4218926021691656
                                                    end;
                                                false ->
                                                    case (J < 67.0) of
                                                        true ->
                                                            1.42961333839197;
                                                        false ->
                                                            1.4373759974489824
                                                    end
                                            end;
                                        false ->
                                            case (J < 70.0) of
                                                true ->
                                                    case (J < 69.0) of
                                                        true ->
                                                            1.4451808069770467;
                                                        false ->
                                                            1.4530279958490526
                                                    end;
                                                false ->
                                                    case (J < 71.0) of
                                                        true ->
                                                            1.460917794180647;
                                                        false ->
                                                            1.4688504333369818
                                                    end
                                            end
                                    end;
                                false ->
                                    case (J < 76.0) of
                                        true ->
                                            case (J < 74.0) of
                                                true ->
                                                    case (J < 73.0) of
                                                        true ->
                                                            1.4768261459394993;
                                                        false ->
                                                            1.4848451658727524
                                                    end;
                                                false ->
                                                    case (J < 75.0) of
                                                        true ->
                                                            1.4929077282912648;
                                                        false ->
                                                            1.5010140696264256
                                                    end
                                            end;
                                        false ->
                                            case (J < 78.0) of
                                                true ->
                                                    case (J < 77.0) of
                                                        true ->
                                                            1.5091644275934228;
                                                        false ->
                                                            1.5173590411982147
                                                    end;
                                                false ->
                                                    case (J < 79.0) of
                                                        true ->
                                                            1.5255981507445384;
                                                        false ->
                                                            1.533881997840956
                                                    end
                                            end
                                    end
                            end;
                        false ->
                            case (J < 88.0) of
                                true ->
                                    case (J < 84.0) of
                                        true ->
                                            case (J < 82.0) of
                                                true ->
                                                    case (J < 81.0) of
                                                        true ->
                                                            1.5422108254079407;
                                                        false ->
                                                            1.550584877685
                                                    end;
                                                false ->
                                                    case (J < 83.0) of
                                                        true ->
                                                            1.559004400237837;
                                                        false ->
                                                            1.567469639965553
                                                    end
                                            end;
                                        false ->
                                            case (J < 86.0) of
                                                true ->
                                                    case (J < 85.0) of
                                                        true ->
                                                            1.5759808451078865;
                                                        false ->
                                                            1.5845382652524937
                                                    end;
                                                false ->
                                                    case (J < 87.0) of
                                                        true ->
                                                            1.593142151342267;
                                                        false ->
                                                            1.6017927556826934
                                                    end
                                            end
                                    end;
                                false ->
                                    case (J < 92.0) of
                                        true ->
                                            case (J < 90.0) of
                                                true ->
                                                    case (J < 89.0) of
                                                        true ->
                                                            1.6104903319492543;
                                                        false ->
                                                            1.6192351351948637
                                                    end;
                                                false ->
                                                    case (J < 91.0) of
                                                        true ->
                                                            1.6280274218573478;
                                                        false ->
                                                            1.6368674497669644
                                                    end
                                            end;
                                        false ->
                                            case (J < 94.0) of
                                                true ->
                                                    case (J < 93.0) of
                                                        true ->
                                                            1.645755478153965;
                                                        false ->
                                                            1.6546917676561943
                                                    end;
                                                false ->
                                                    case (J < 95.0) of
                                                        true ->
                                                            1.6636765803267364;
                                                        false ->
                                                            1.6727101796415966
                                                    end
                                            end
                                    end
                            end
                    end;
                false ->
                    case (J < 112.0) of
                        true ->
                            case (J < 104.0) of
                                true ->
                                    case (J < 100.0) of
                                        true ->
                                            case (J < 98.0) of
                                                true ->
                                                    case (J < 97.0) of
                                                        true ->
                                                            1.681792830507429;
                                                        false ->
                                                            1.6909247992693053
                                                    end;
                                                false ->
                                                    case (J < 99.0) of
                                                        true ->
                                                            1.7001063537185235;
                                                        false ->
                                                            1.709337763100463
                                                    end
                                            end;
                                        false ->
                                            case (J < 102.0) of
                                                true ->
                                                    case (J < 101.0) of
                                                        true ->
                                                            1.718619298122478;
                                                        false ->
                                                            1.7279512309618377
                                                    end;
                                                false ->
                                                    case (J < 103.0) of
                                                        true ->
                                                            1.7373338352737062;
                                                        false ->
                                                            1.746767386199169
                                                    end
                                            end
                                    end;
                                false ->
                                    case (J < 108.0) of
                                        true ->
                                            case (J < 106.0) of
                                                true ->
                                                    case (J < 105.0) of
                                                        true ->
                                                            1.7562521603732995;
                                                        false ->
                                                            1.7657884359332727
                                                    end;
                                                false ->
                                                    case (J < 107.0) of
                                                        true ->
                                                            1.7753764925265212;
                                                        false ->
                                                            1.785016611318935
                                                    end
                                            end;
                                        false ->
                                            case (J < 110.0) of
                                                true ->
                                                    case (J < 109.0) of
                                                        true ->
                                                            1.7947090750031072;
                                                        false ->
                                                            1.804454167806624
                                                    end;
                                                false ->
                                                    case (J < 111.0) of
                                                        true ->
                                                            1.8142521755003989;
                                                        false ->
                                                            1.8241033854070534
                                                    end
                                            end
                                    end
                            end;
                        false ->
                            case (J < 120.0) of
                                true ->
                                    case (J < 116.0) of
                                        true ->
                                            case (J < 114.0) of
                                                true ->
                                                    case (J < 113.0) of
                                                        true ->
                                                            1.8340080864093424;
                                                        false ->
                                                            1.843966568958626
                                                    end;
                                                false ->
                                                    case (J < 115.0) of
                                                        true ->
                                                            1.8539791250833855;
                                                        false ->
                                                            1.864046048397789
                                                    end
                                            end;
                                        false ->
                                            case (J < 118.0) of
                                                true ->
                                                    case (J < 117.0) of
                                                        true ->
                                                            1.8741676341103;
                                                        false ->
                                                            1.8843441790323345
                                                    end;
                                                false ->
                                                    case (J < 119.0) of
                                                        true ->
                                                            1.8945759815869656;
                                                        false ->
                                                            1.9048633418176741
                                                    end
                                            end
                                    end;
                                false ->
                                    case (J < 124.0) of
                                        true ->
                                            case (J < 122.0) of
                                                true ->
                                                    case (J < 121.0) of
                                                        true ->
                                                            1.9152065613971474;
                                                        false ->
                                                            1.925605943636125
                                                    end;
                                                false ->
                                                    case (J < 123.0) of
                                                        true ->
                                                            1.9360617934922943;
                                                        false ->
                                                            1.9465744175792332
                                                    end
                                            end;
                                        false ->
                                            case (J < 126.0) of
                                                true ->
                                                    case (J < 125.0) of
                                                        true ->
                                                            1.9571441241754002;
                                                        false ->
                                                            1.9677712232331759
                                                    end;
                                                false ->
                                                    case (J < 127.0) of
                                                        true ->
                                                            1.978456026387951;
                                                        false ->
                                                            1.9891988469672663
                                                    end
                                            end
                                    end
                            end
                    end
            end
    end.

% `__exp_data.tab[2j]`: 2^(j/128) / expHead(j) − 1.

expTail(J) ->
    case (J < 64.0) of
        true ->
            case (J < 32.0) of
                true ->
                    case (J < 16.0) of
                        true ->
                            case (J < 8.0) of
                                true ->
                                    case (J < 4.0) of
                                        true ->
                                            case (J < 2.0) of
                                                true ->
                                                    case (J < 1.0) of
                                                        true ->
                                                            0.0;
                                                        false ->
                                                            9.447885451727066e-17
                                                    end;
                                                false ->
                                                    case (J < 3.0) of
                                                        true ->
                                                            (-1.507066976926039e-17);
                                                        false ->
                                                            (-5.679155082825012e-17)
                                                    end
                                            end;
                                        false ->
                                            case (J < 6.0) of
                                                true ->
                                                    case (J < 5.0) of
                                                        true ->
                                                            4.9997448722726326e-17;
                                                        false ->
                                                            (-4.823683599994895e-17)
                                                    end;
                                                false ->
                                                    case (J < 7.0) of
                                                        true ->
                                                            7.357846871247418e-18;
                                                        false ->
                                                            5.773230223741951e-17
                                                    end
                                            end
                                    end;
                                false ->
                                    case (J < 12.0) of
                                        true ->
                                            case (J < 10.0) of
                                                true ->
                                                    case (J < 9.0) of
                                                        true ->
                                                            8.189317638195515e-17;
                                                        false ->
                                                            5.326891139980878e-17
                                                    end;
                                                false ->
                                                    case (J < 11.0) of
                                                        true ->
                                                            1.6665881442326747e-18;
                                                        false ->
                                                            (-1.128113245461828e-17)
                                                    end
                                            end;
                                        false ->
                                            case (J < 14.0) of
                                                true ->
                                                    case (J < 13.0) of
                                                        true ->
                                                            (-7.402825309426177e-17);
                                                        false ->
                                                            (-3.578659767309563e-18)
                                                    end;
                                                false ->
                                                    case (J < 15.0) of
                                                        true ->
                                                            (-6.170654745608695e-17);
                                                        false ->
                                                            2.919139999949279e-17
                                                    end
                                            end
                                    end
                            end;
                        false ->
                            case (J < 24.0) of
                                true ->
                                    case (J < 20.0) of
                                        true ->
                                            case (J < 18.0) of
                                                true ->
                                                    case (J < 17.0) of
                                                        true ->
                                                            (-2.7939114859515733e-17);
                                                        false ->
                                                            (-5.399285355184285e-17)
                                                    end;
                                                false ->
                                                    case (J < 19.0) of
                                                        true ->
                                                            4.776959425256223e-17;
                                                        false ->
                                                            (-7.927701432338473e-17)
                                                    end
                                            end;
                                        false ->
                                            case (J < 22.0) of
                                                true ->
                                                    case (J < 21.0) of
                                                        true ->
                                                            9.341710609905046e-17;
                                                        false ->
                                                            (-5.534520675707472e-17)
                                                    end;
                                                false ->
                                                    case (J < 23.0) of
                                                        true ->
                                                            4.585670326662351e-17;
                                                        false ->
                                                            2.8582430411116143e-17
                                                    end
                                            end
                                    end;
                                false ->
                                    case (J < 28.0) of
                                        true ->
                                            case (J < 26.0) of
                                                true ->
                                                    case (J < 25.0) of
                                                        true ->
                                                            7.826573258636076e-17;
                                                        false ->
                                                            4.053626906769216e-17
                                                    end;
                                                false ->
                                                    case (J < 27.0) of
                                                        true ->
                                                            2.823784425951061e-17;
                                                        false ->
                                                            (-7.882802262487991e-17)
                                                    end
                                            end;
                                        false ->
                                            case (J < 30.0) of
                                                true ->
                                                    case (J < 29.0) of
                                                        true ->
                                                            3.2904726646008416e-17;
                                                        false ->
                                                            (-1.5792094703347882e-18)
                                                    end;
                                                false ->
                                                    case (J < 31.0) of
                                                        true ->
                                                            4.721368121170128e-17;
                                                        false ->
                                                            1.3045277096919659e-17
                                                    end
                                            end
                                    end
                            end
                    end;
                false ->
                    case (J < 48.0) of
                        true ->
                            case (J < 40.0) of
                                true ->
                                    case (J < 36.0) of
                                        true ->
                                            case (J < 34.0) of
                                                true ->
                                                    case (J < 33.0) of
                                                        true ->
                                                            3.3484623336251524e-17;
                                                        false ->
                                                            3.8611199774925664e-17
                                                    end;
                                                false ->
                                                    case (J < 35.0) of
                                                        true ->
                                                            5.527550048505249e-17;
                                                        false ->
                                                            (-3.927184172445234e-17)
                                                    end
                                            end;
                                        false ->
                                            case (J < 38.0) of
                                                true ->
                                                    case (J < 37.0) of
                                                        true ->
                                                            (-6.346552106729483e-17);
                                                        false ->
                                                            (-8.684417614865944e-17)
                                                    end;
                                                false ->
                                                    case (J < 39.0) of
                                                        true ->
                                                            (-1.5456342819397733e-17);
                                                        false ->
                                                            (-8.70763476495455e-17)
                                                    end
                                            end
                                    end;
                                false ->
                                    case (J < 44.0) of
                                        true ->
                                            case (J < 42.0) of
                                                true ->
                                                    case (J < 41.0) of
                                                        true ->
                                                            3.750854201303127e-17;
                                                        false ->
                                                            (-6.616854503526488e-17)
                                                    end;
                                                false ->
                                                    case (J < 43.0) of
                                                        true ->
                                                            (-5.346099009198751e-18);
                                                        false ->
                                                            (-2.443726321015018e-17)
                                                    end
                                            end;
                                        false ->
                                            case (J < 46.0) of
                                                true ->
                                                    case (J < 45.0) of
                                                        true ->
                                                            2.1023049675215714e-18;
                                                        false ->
                                                            7.771067937501065e-17
                                                    end;
                                                false ->
                                                    case (J < 47.0) of
                                                        true ->
                                                            1.3357510088834541e-17;
                                                        false ->
                                                            6.938291696959204e-17
                                                    end
                                            end
                                    end
                            end;
                        false ->
                            case (J < 56.0) of
                                true ->
                                    case (J < 52.0) of
                                        true ->
                                            case (J < 50.0) of
                                                true ->
                                                    case (J < 49.0) of
                                                        true ->
                                                            1.9572585293112036e-17;
                                                        false ->
                                                            6.632256961675804e-17
                                                    end;
                                                false ->
                                                    case (J < 51.0) of
                                                        true ->
                                                            (-5.478069123926778e-17);
                                                        false ->
                                                            (-4.140839310392624e-17)
                                                    end
                                            end;
                                        false ->
                                            case (J < 54.0) of
                                                true ->
                                                    case (J < 53.0) of
                                                        true ->
                                                            (-2.1571477251208752e-17);
                                                        false ->
                                                            (-3.8287766552120535e-17)
                                                    end;
                                                false ->
                                                    case (J < 55.0) of
                                                        true ->
                                                            6.663804589232195e-17;
                                                        false ->
                                                            2.3936187400285282e-17
                                                    end
                                            end
                                    end;
                                false ->
                                    case (J < 60.0) of
                                        true ->
                                            case (J < 58.0) of
                                                true ->
                                                    case (J < 57.0) of
                                                        true ->
                                                            5.68648095791174e-17;
                                                        false ->
                                                            1.1264523354521684e-18
                                                    end;
                                                false ->
                                                    case (J < 59.0) of
                                                        true ->
                                                            7.007875046906994e-17;
                                                        false ->
                                                            (-5.0119214278381254e-17)
                                                    end
                                            end;
                                        false ->
                                            case (J < 62.0) of
                                                true ->
                                                    case (J < 61.0) of
                                                        true ->
                                                            (-4.8923067513522756e-17);
                                                        false ->
                                                            (-3.5260089953269434e-17)
                                                    end;
                                                false ->
                                                    case (J < 63.0) of
                                                        true ->
                                                            (-6.872303720902018e-17);
                                                        false ->
                                                            5.001446664133532e-18
                                                    end
                                            end
                                    end
                            end
                    end
            end;
        false ->
            case (J < 96.0) of
                true ->
                    case (J < 80.0) of
                        true ->
                            case (J < 72.0) of
                                true ->
                                    case (J < 68.0) of
                                        true ->
                                            case (J < 66.0) of
                                                true ->
                                                    case (J < 65.0) of
                                                        true ->
                                                            (-6.835808657661922e-17);
                                                        false ->
                                                            (-1.1307344092910212e-17)
                                                    end;
                                                false ->
                                                    case (J < 67.0) of
                                                        true ->
                                                            (-8.416011634717156e-18);
                                                        false ->
                                                            (-2.9247977035436566e-17)
                                                    end
                                            end;
                                        false ->
                                            case (J < 70.0) of
                                                true ->
                                                    case (J < 69.0) of
                                                        true ->
                                                            (-2.092304381843353e-17);
                                                        false ->
                                                            (-3.9778645875427124e-17)
                                                    end;
                                                false ->
                                                    case (J < 71.0) of
                                                        true ->
                                                            (-3.833464968654295e-17);
                                                        false ->
                                                            5.763611164480894e-17
                                                    end
                                            end
                                    end;
                                false ->
                                    case (J < 76.0) of
                                        true ->
                                            case (J < 74.0) of
                                                true ->
                                                    case (J < 73.0) of
                                                        true ->
                                                            (-2.3591094770850053e-17);
                                                        false ->
                                                            7.260074661098575e-17
                                                    end;
                                                false ->
                                                    case (J < 75.0) of
                                                        true ->
                                                            9.50689710108796e-18;
                                                        false ->
                                                            (-4.272956133839906e-17)
                                                    end
                                            end;
                                        false ->
                                            case (J < 78.0) of
                                                true ->
                                                    case (J < 77.0) of
                                                        true ->
                                                            (-6.735219232374683e-17);
                                                        false ->
                                                            (-2.8396044410430936e-17)
                                                    end;
                                                false ->
                                                    case (J < 79.0) of
                                                        true ->
                                                            (-7.226635472101257e-17);
                                                        false ->
                                                            5.786121003395918e-17
                                                    end
                                            end
                                    end
                            end;
                        false ->
                            case (J < 88.0) of
                                true ->
                                    case (J < 84.0) of
                                        true ->
                                            case (J < 82.0) of
                                                true ->
                                                    case (J < 81.0) of
                                                        true ->
                                                            5.1548301170786783e-17;
                                                        false ->
                                                            (-9.416257568878152e-18)
                                                    end;
                                                false ->
                                                    case (J < 83.0) of
                                                        true ->
                                                            2.4253985766689806e-17;
                                                        false ->
                                                            (-6.604314051707707e-17)
                                                    end
                                            end;
                                        false ->
                                            case (J < 86.0) of
                                                true ->
                                                    case (J < 85.0) of
                                                        true ->
                                                            (-6.432131775424189e-18);
                                                        false ->
                                                            (-1.2204007601863921e-17)
                                                    end;
                                                false ->
                                                    case (J < 87.0) of
                                                        true ->
                                                            (-6.336161863401293e-17);
                                                        false ->
                                                            (-3.7800879246373815e-17)
                                                    end
                                            end
                                    end;
                                false ->
                                    case (J < 92.0) of
                                        true ->
                                            case (J < 90.0) of
                                                true ->
                                                    case (J < 89.0) of
                                                        true ->
                                                            1.5341410053603723e-17;
                                                        false ->
                                                            1.2932855580427452e-17
                                                    end;
                                                false ->
                                                    case (J < 91.0) of
                                                        true ->
                                                            (-4.123367330661149e-17);
                                                        false ->
                                                            4.703083974463456e-17
                                                    end
                                            end;
                                        false ->
                                            case (J < 94.0) of
                                                true ->
                                                    case (J < 93.0) of
                                                        true ->
                                                            (-6.152602891550265e-17);
                                                        false ->
                                                            5.827849326195279e-17
                                                    end;
                                                false ->
                                                    case (J < 95.0) of
                                                        true ->
                                                            3.540948262646183e-17;
                                                        false ->
                                                            (-3.2741571320938764e-17)
                                                    end
                                            end
                                    end
                            end
                    end;
                false ->
                    case (J < 112.0) of
                        true ->
                            case (J < 104.0) of
                                true ->
                                    case (J < 100.0) of
                                        true ->
                                            case (J < 98.0) of
                                                true ->
                                                    case (J < 97.0) of
                                                        true ->
                                                            4.875160526227062e-17;
                                                        false ->
                                                            (-5.718569790077838e-17)
                                                    end;
                                                false ->
                                                    case (J < 99.0) of
                                                        true ->
                                                            (-4.719539664590972e-18);
                                                        false ->
                                                            (-5.773451958805706e-17)
                                                    end
                                            end;
                                        false ->
                                            case (J < 102.0) of
                                                true ->
                                                    case (J < 101.0) of
                                                        true ->
                                                            (-1.0772487078934056e-17);
                                                        false ->
                                                            (-6.221808618533911e-17)
                                                    end;
                                                false ->
                                                    case (J < 103.0) of
                                                        true ->
                                                            1.821405440362259e-17;
                                                        false ->
                                                            (-6.155536546227639e-17)
                                                    end
                                            end
                                    end;
                                false ->
                                    case (J < 108.0) of
                                        true ->
                                            case (J < 106.0) of
                                                true ->
                                                    case (J < 105.0) of
                                                        true ->
                                                            1.685487290628973e-17;
                                                        false ->
                                                            5.3581249177694816e-17
                                                    end;
                                                false ->
                                                    case (J < 107.0) of
                                                        true ->
                                                            3.621615935336894e-17;
                                                        false ->
                                                            8.588379527574144e-18
                                                    end
                                            end;
                                        false ->
                                            case (J < 110.0) of
                                                true ->
                                                    case (J < 109.0) of
                                                        true ->
                                                            1.01562190116415e-17;
                                                        false ->
                                                            (-2.869134889187244e-17)
                                                    end;
                                                false ->
                                                    case (J < 111.0) of
                                                        true ->
                                                            (-5.495118966122005e-17);
                                                        false ->
                                                            (-5.56965572431627e-17)
                                                    end
                                            end
                                    end
                            end;
                        false ->
                            case (J < 120.0) of
                                true ->
                                    case (J < 116.0) of
                                        true ->
                                            case (J < 114.0) of
                                                true ->
                                                    case (J < 113.0) of
                                                        true ->
                                                            1.790126907604513e-17;
                                                        false ->
                                                            (-3.2211766346200164e-17)
                                                    end;
                                                false ->
                                                    case (J < 115.0) of
                                                        true ->
                                                            5.265370768556274e-17;
                                                        false ->
                                                            3.5089866402403033e-17
                                                    end
                                            end;
                                        false ->
                                            case (J < 118.0) of
                                                true ->
                                                    case (J < 117.0) of
                                                        true ->
                                                            (-3.266924100901318e-17);
                                                        false ->
                                                            (-4.3657593008079375e-17)
                                                    end;
                                                false ->
                                                    case (J < 119.0) of
                                                        true ->
                                                            1.7963932659833022e-17;
                                                        false ->
                                                            3.4300925275214166e-17
                                                    end
                                            end
                                    end;
                                false ->
                                    case (J < 124.0) of
                                        true ->
                                            case (J < 122.0) of
                                                true ->
                                                    case (J < 121.0) of
                                                        true ->
                                                            (-5.545065618639427e-17);
                                                        false ->
                                                            (-5.149009745457733e-17)
                                                    end;
                                                false ->
                                                    case (J < 123.0) of
                                                        true ->
                                                            5.336805878514151e-17;
                                                        false ->
                                                            3.498978661192973e-17
                                                    end
                                            end;
                                        false ->
                                            case (J < 126.0) of
                                                true ->
                                                    case (J < 125.0) of
                                                        true ->
                                                            4.5784915277060095e-17;
                                                        false ->
                                                            (-5.241934575393899e-17)
                                                    end;
                                                false ->
                                                    case (J < 127.0) of
                                                        true ->
                                                            2.0414278897578303e-17;
                                                        false ->
                                                            4.124842848606488e-18
                                                    end
                                            end
                                    end
                            end
                    end
            end
    end.

% ── trigonometry ─────────────────────────────────────────────────────────────

% fdlibm's `__ieee754_rem_pio2` for |x| up to 2^19·π/2: `which` 0 answers the

% quadrant n, 1 and 2 the remainder's head and tail. A larger |x| needs

% `__kernel_rem_pio2`, which is not ported — refused by a panic.

remPio2(X, Which) ->
    Neg = signBit(X),
    Ix = highWord(X),
    N = 0.0,
    Y0 = X,
    Y1 = 0.0,
    {N@8, Y0@17, Y1@11} = case (Ix =< 1072243195.0) of
        true ->
            N@1 = 0.0,
            {N@1, Y0, Y1};
        _ ->
            {Y0@16, Y1@10, N@7} = case (Ix < 1073928572.0) of
                true ->
                    Sgn = case Neg of
                        true ->
                            (-1.0);
                        false ->
                            1.0
                    end,
                    Z = (X - (Sgn * 1.57079632673412561417e+00)),
                    {Y0@3, Y1@3, Z@2} = case (Ix =/= 1073291771.0) of
                        true ->
                            Y0@1 = (Z - (Sgn * 6.07710050650619224932e-11)),
                            Y1@1 = (((Z - Y0@1)) - (Sgn * 6.07710050650619224932e-11)),
                            {Y0@1, Y1@1, Z};
                        _ ->
                            Z@1 = (Z - (Sgn * 6.07710050630396597660e-11)),
                            Y0@2 = (Z@1 - (Sgn * 2.02226624879595063154e-21)),
                            Y1@2 = (((Z@1 - Y0@2)) - (Sgn * 2.02226624879595063154e-21)),
                            {Y0@2, Y1@2, Z@1}
                    end,
                    N@2 = Sgn,
                    {Y0@3, Y1@3, N@2};
                _ ->
                    {N@6, Y0@15, Y1@9} = case (Ix =< 1094263291.0) of
                        true ->
                            T = erlang:abs(X),
                            N@3 = erlang:trunc(((T * 6.36619772367581382433e-01) + 0.5)),
                            R = (T - (N@3 * 1.57079632673412561417e+00)),
                            W = (N@3 * 6.07710050650619224932e-11),
                            {Y0@10, W@7, R@5} = case ((N@3 < 32.0) andalso (Ix =/= highWord((N@3 * 1.5707963267948966)))) of
                                true ->
                                    Y0@4 = (R - W),
                                    {Y0@4, W, R};
                                _ ->
                                    J = math:floor((Ix / 1048576.0)),
                                    Y0@5 = (R - W),
                                    {W@6, R@4, Y0@9} = case ((J - exponentField(Y0@5)) > 16.0) of
                                        true ->
                                            Tt = R,
                                            W@1 = (N@3 * 6.07710050630396597660e-11),
                                            R@1 = (Tt - W@1),
                                            W@2 = ((N@3 * 2.02226624879595063154e-21) - ((((Tt - R@1)) - W@1))),
                                            Y0@6 = (R@1 - W@2),
                                            {Tt@2, W@5, R@3, Y0@8} = case ((J - exponentField(Y0@6)) > 49.0) of
                                                true ->
                                                    Tt@1 = R@1,
                                                    W@3 = (N@3 * 2.02226624871116645580e-21),
                                                    R@2 = (Tt@1 - W@3),
                                                    W@4 = ((N@3 * 8.47842766036889956997e-32) - ((((Tt@1 - R@2)) - W@3))),
                                                    Y0@7 = (R@2 - W@4),
                                                    {Tt@1, W@4, R@2, Y0@7};
                                                _ ->
                                                    {Tt, W@2, R@1, Y0@6}
                                            end,
                                            {W@5, R@3, Y0@8};
                                        _ ->
                                            {W, R, Y0@5}
                                    end,
                                    {Y0@9, W@6, R@4}
                            end,
                            Y1@4 = (((R@5 - Y0@10)) - W@7),
                            {Y0@12, Y1@6, N@5} = case Neg of
                                true ->
                                    Y0@11 = ((-1.0) * Y0@10),
                                    Y1@5 = ((-1.0) * Y1@4),
                                    N@4 = ((-1.0) * N@3),
                                    {Y0@11, Y1@5, N@4};
                                _ ->
                                    {Y0@10, Y1@4, N@3}
                            end,
                            {N@5, Y0@12, Y1@6};
                        _ ->
                            {Y0@14, Y1@8} = case (Ix >= 2146435072.0) of
                                true ->
                                    Y0@13 = (X - X),
                                    Y1@7 = Y0@13,
                                    {Y0@13, Y1@7};
                                _ ->
                                    erlang:error({panic, <<"math: a trigonometric argument beyond 2^19 \x{C2}\x{B7} \x{CF}\x{80}/2 is not reduced on wasm">>}),
                                    {Y0, Y1}
                            end,
                            {N, Y0@14, Y1@8}
                    end,
                    {Y0@15, Y1@9, N@6}
            end,
            {N@7, Y0@16, Y1@10}
    end,
    case (Which < 0.5) of
        true ->
            N@8;
        false ->
            case (Which < 1.5) of
                true ->
                    Y0@17;
                false ->
                    Y1@11
            end
    end.

kernelCos(X, Y) ->
    Ix = highWord(X),
    case (Ix < 1044381696.0) of
        true ->
            1.0;
        _ ->
            Z = (X * X),
            R = (Z * ((4.16666666666666019037e-02 + (Z * (((-1.38888888888741095749e-03) + (Z * ((2.48015872894767294178e-05 + (Z * (((-2.75573143513906633035e-07) + (Z * ((2.08757232129817482790e-09 + (Z * (-1.13596475577881948265e-11))))))))))))))))),
            case (Ix < 1070805811.0) of
                true ->
                    (1.0 - (((0.5 * Z) - (((Z * R) - (X * Y))))));
                _ ->
                    Qx = case (Ix > 1072234496.0) of
                        true ->
                            0.28125;
                        false ->
                            fromWords((Ix - 2097152.0), 0.0)
                    end,
                    Iz = ((0.5 * Z) - Qx),
                    A = (1.0 - Qx),
                    (A - ((Iz - (((Z * R) - (X * Y))))))
            end
    end.

kernelSin(X, Y, Iy) ->
    case (highWord(X) < 1044381696.0) of
        true ->
            X;
        _ ->
            Z = (X * X),
            V = (Z * X),
            R = (8.33333333332248946124e-03 + (Z * (((-1.98412698298579493134e-04) + (Z * ((2.75573137070700676789e-06 + (Z * (((-2.50507602534068634195e-08) + (Z * 1.58969099521155010221e-10))))))))))),
            case isZero(Iy) of
                true ->
                    (X + (V * (((-1.66666666666666324348e-01) + (Z * R)))));
                _ ->
                    (X - (((((Z * (((0.5 * Y) - (V * R)))) - Y)) - (V * (-1.66666666666666324348e-01)))))
            end
    end.

% fdlibm's `__kernel_tan`: tan(x + y) for `iy` 1, -1/tan(x + y) for -1.

kernelTan(X0, Y0, Iy) ->
    Neg = signBit(X0),
    Ix = highWord(X0),
    case (Ix < 1043333120.0) of
        true ->
            case ((isZero(Ix) andalso isZero(lowWord(X0))) andalso (Iy =:= (-1.0))) of
                true ->
                    (1.0 / '__bp_nz'(erlang:abs(X0), <<"division by zero: / on f64 at src/math.bp:1960:24">>));
                _ ->
                    case (Iy =:= 1.0) of
                        true ->
                            X0;
                        _ ->
                            W0 = (X0 + Y0),
                            Z0 = withLowZero(W0),
                            V0 = (Y0 - ((Z0 - X0))),
                            A0 = ((-1.0) / '__bp_nz'(W0, <<"division by zero: / on f64 at src/math.bp:1965:23">>)),
                            T0 = withLowZero(A0),
                            S0 = (1.0 + (T0 * Z0)),
                            (T0 + (A0 * ((S0 + (T0 * V0)))))
                    end
            end;
        _ ->
            X = X0,
            Y = Y0,
            Big = (Ix >= 1072010280.0),
            {X@4, Y@4} = case Big of
                true ->
                    {X@2, Y@2} = case Neg of
                        true ->
                            X@1 = ((-1.0) * X),
                            Y@1 = ((-1.0) * Y),
                            {X@1, Y@1};
                        _ ->
                            {X, Y}
                    end,
                    Zb = (7.85398163397448278999e-01 - X@2),
                    Wb = (3.06161699786838301793e-17 - Y@2),
                    X@3 = (Zb + Wb),
                    Y@3 = 0.0,
                    {X@3, Y@3};
                _ ->
                    {X, Y}
            end,
            Z = (X@4 * X@4),
            W = (Z * Z),
            R = (1.33333333333201242699e-01 + (W * ((2.18694882948595424599e-02 + (W * ((3.59207910759131235356e-03 + (W * ((5.88041240820264096874e-04 + (W * ((7.81794442939557092300e-05 + (W * (-1.85586374855275456654e-05))))))))))))))),
            V = (Z * ((5.39682539762260521377e-02 + (W * ((8.86323982359930005737e-03 + (W * ((1.45620945432529025516e-03 + (W * ((2.46463134818469906812e-04 + (W * ((7.14072491382608190305e-05 + (W * 2.59073051863633712884e-05)))))))))))))))),
            S = (Z * X@4),
            R@1 = (Y@4 + (Z * (((S * ((R + V))) + Y@4)))),
            R@2 = (R@1 + (3.33333333333334091986e-01 * S)),
            Ww = (X@4 + R@2),
            case Big of
                true ->
                    Sign = case Neg of
                        true ->
                            (-1.0);
                        false ->
                            1.0
                    end,
                    (Sign * ((Iy - (2.0 * ((X@4 - ((((Ww * Ww) / '__bp_nz'(((Ww + Iy)), <<"division by zero: / on f64 at src/math.bp:2013:49">>)) - R@2))))))));
                _ ->
                    case (Iy =:= 1.0) of
                        true ->
                            Ww;
                        _ ->
                            Z2 = withLowZero(Ww),
                            V2 = (R@2 - ((Z2 - X@4))),
                            A = ((-1.0) / '__bp_nz'(Ww, <<"division by zero: / on f64 at src/math.bp:2018:18">>)),
                            T = withLowZero(A),
                            S2 = (1.0 + (T * Z2)),
                            (T + (A * ((S2 + (T * V2)))))
                    end
            end
    end.

% n mod 4 in 0..3 (fdlibm's `n & 3`).

quadrantOf(N) ->
    (N - (4.0 * math:floor((N * 0.25)))).

sinBody(X) ->
    Ix = highWord(X),
    case (Ix =< 1072243195.0) of
        true ->
            kernelSin(X, 0.0, 0.0);
        _ ->
            case (Ix >= 2146435072.0) of
                true ->
                    (X - X);
                _ ->
                    Q = quadrantOf(remPio2(X, 0.0)),
                    Y0 = remPio2(X, 1.0),
                    Y1 = remPio2(X, 2.0),
                    case (Q < 0.5) of
                        true ->
                            kernelSin(Y0, Y1, 1.0);
                        false ->
                            case (Q < 1.5) of
                                true ->
                                    kernelCos(Y0, Y1);
                                false ->
                                    case (Q < 2.5) of
                                        true ->
                                            ((-1.0) * kernelSin(Y0, Y1, 1.0));
                                        false ->
                                            ((-1.0) * kernelCos(Y0, Y1))
                                    end
                            end
                    end
            end
    end.

cosBody(X) ->
    Ix = highWord(X),
    case (Ix =< 1072243195.0) of
        true ->
            kernelCos(X, 0.0);
        _ ->
            case (Ix >= 2146435072.0) of
                true ->
                    (X - X);
                _ ->
                    Q = quadrantOf(remPio2(X, 0.0)),
                    Y0 = remPio2(X, 1.0),
                    Y1 = remPio2(X, 2.0),
                    case (Q < 0.5) of
                        true ->
                            kernelCos(Y0, Y1);
                        false ->
                            case (Q < 1.5) of
                                true ->
                                    ((-1.0) * kernelSin(Y0, Y1, 1.0));
                                false ->
                                    case (Q < 2.5) of
                                        true ->
                                            ((-1.0) * kernelCos(Y0, Y1));
                                        false ->
                                            kernelSin(Y0, Y1, 1.0)
                                    end
                            end
                    end
            end
    end.

tanBody(X) ->
    Ix = highWord(X),
    case (Ix =< 1072243195.0) of
        true ->
            kernelTan(X, 0.0, 1.0);
        _ ->
            case (Ix >= 2146435072.0) of
                true ->
                    (X - X);
                _ ->
                    Odd = (quadrantOf(remPio2(X, 0.0)) - (2.0 * math:floor((quadrantOf(remPio2(X, 0.0)) * 0.5)))),
                    kernelTan(remPio2(X, 1.0), remPio2(X, 2.0), (1.0 - (2.0 * Odd)))
            end
    end.

asinPoly(T) ->
    P = (T * ((1.66666666666666657415e-01 + (T * (((-3.25565818622400915405e-01) + (T * ((2.01212532134862925881e-01 + (T * (((-4.00555345006794114027e-02) + (T * ((7.91534994289814532176e-04 + (T * 3.47933107596021167570e-05)))))))))))))))),
    Q = (1.0 + (T * (((-2.40339491173441421878e+00) + (T * ((2.02094576023350569471e+00 + (T * (((-6.88283971605453293030e-01) + (T * 7.70381505559019352791e-02))))))))))),
    (P / '__bp_nz'(Q, <<"division by zero: / on f64 at src/math.bp:2093:14">>)).

asinBody(X) ->
    Ix = highWord(X),
    case (Ix >= 1072693248.0) of
        true ->
            case ((Ix =:= 1072693248.0) andalso isZero(lowWord(X))) of
                true ->
                    ((X * 1.57079632679489655800e+00) + (X * 6.12323399573676603587e-17));
                _ ->
                    (((X - X)) / '__bp_nz'(((X - X)), <<"division by zero: / on f64 at src/math.bp:2102:24">>))
            end;
        _ ->
            case (Ix < 1071644672.0) of
                true ->
                    case (Ix < 1044381696.0) of
                        true ->
                            X;
                        _ ->
                            (X + (X * asinPoly((X * X))))
                    end;
                _ ->
                    W = (1.0 - erlang:abs(X)),
                    T = (W * 0.5),
                    S = math:sqrt(T),
                    Res = 0.0,
                    Res@3 = case (Ix >= 1072640819.0) of
                        true ->
                            Res@1 = (1.57079632679489655800e+00 - (((2.0 * ((S + (S * asinPoly(T))))) - 6.12323399573676603587e-17))),
                            Res@1;
                        _ ->
                            Ws = withLowZero(S),
                            C = (((T - (Ws * Ws))) / '__bp_nz'(((S + Ws)), <<"division by zero: / on f64 at src/math.bp:2117:31">>)),
                            P = (((2.0 * S) * asinPoly(T)) - ((6.12323399573676603587e-17 - (2.0 * C)))),
                            Q = (7.85398163397448278999e-01 - (2.0 * Ws)),
                            Res@2 = (7.85398163397448278999e-01 - ((P - Q))),
                            Res@2
                    end,
                    case (X > 0.0) of
                        true ->
                            Res@3;
                        false ->
                            ((-1.0) * Res@3)
                    end
            end
    end.

acosBody(X) ->
    Ix = highWord(X),
    Pio2Hi = 1.57079632679489655800e+00,
    Pio2Lo = 6.12323399573676603587e-17,
    case (Ix >= 1072693248.0) of
        true ->
            case ((Ix =:= 1072693248.0) andalso isZero(lowWord(X))) of
                true ->
                    case (X > 0.0) of
                        true ->
                            0.0;
                        false ->
                            (3.14159265358979311600e+00 + (2.0 * Pio2Lo))
                    end;
                _ ->
                    (((X - X)) / '__bp_nz'(((X - X)), <<"division by zero: / on f64 at src/math.bp:2135:24">>))
            end;
        _ ->
            case (Ix < 1071644672.0) of
                true ->
                    case (Ix =< 1012924416.0) of
                        true ->
                            (Pio2Hi + Pio2Lo);
                        _ ->
                            (Pio2Hi - ((X - ((Pio2Lo - (X * asinPoly((X * X))))))))
                    end;
                _ ->
                    case (X < 0.0) of
                        true ->
                            Z = (((1.0 + X)) * 0.5),
                            S = math:sqrt(Z),
                            W = ((asinPoly(Z) * S) - Pio2Lo),
                            (3.14159265358979311600e+00 - (2.0 * ((S + W))));
                        _ ->
                            Z@1 = (((1.0 - X)) * 0.5),
                            S@1 = math:sqrt(Z@1),
                            Df = withLowZero(S@1),
                            C = (((Z@1 - (Df * Df))) / '__bp_nz'(((S@1 + Df)), <<"division by zero: / on f64 at src/math.bp:2150:27">>)),
                            W@1 = ((asinPoly(Z@1) * S@1) + C),
                            (2.0 * ((Df + W@1)))
                    end
            end
    end.

atanBody(X) ->
    try
        Ix = highWord(X),
        Neg = signBit(X),
        case (Ix >= 1141899264.0) of
            true ->
                case (X =/= X) of
                    true ->
                        (X + X);
                    _ ->
                        case Neg of
                            true ->
                                ((-1.57079632679489655800e+00) - 6.12323399573676603587e-17);
                            false ->
                                (1.57079632679489655800e+00 + 6.12323399573676603587e-17)
                        end
                end;
            _ ->
                Id = (-1.0),
                T = X,
                {Id@8, T@8} = case (Ix < 1071382528.0) of
                    true ->
                        case (Ix < 1044381696.0) of
                            true ->
                                erlang:throw({'__bp_try', X});
                            _ -> ok
                        end,
                        {Id, T};
                    _ ->
                        Ax = erlang:abs(X),
                        {Id@7, T@7} = case (Ix < 1072889856.0) of
                            true ->
                                {Id@3, T@3} = case (Ix < 1072037888.0) of
                                    true ->
                                        Id@1 = 0.0,
                                        T@1 = ((((2.0 * Ax) - 1.0)) / '__bp_nz'(((2.0 + Ax)), <<"division by zero: / on f64 at src/math.bp:2174:38">>)),
                                        {Id@1, T@1};
                                    _ ->
                                        Id@2 = 1.0,
                                        T@2 = (((Ax - 1.0)) / '__bp_nz'(((Ax + 1.0)), <<"division by zero: / on f64 at src/math.bp:2177:32">>)),
                                        {Id@2, T@2}
                                end,
                                {Id@3, T@3};
                            _ ->
                                {Id@6, T@6} = case (Ix < 1073971200.0) of
                                    true ->
                                        Id@4 = 2.0,
                                        T@4 = (((Ax - 1.5)) / '__bp_nz'(((1.0 + (1.5 * Ax))), <<"division by zero: / on f64 at src/math.bp:2181:28">>)),
                                        {Id@4, T@4};
                                    _ ->
                                        Id@5 = 3.0,
                                        T@5 = ((-1.0) / '__bp_nz'(Ax, <<"division by zero: / on f64 at src/math.bp:2184:22">>)),
                                        {Id@5, T@5}
                                end,
                                {Id@6, T@6}
                        end,
                        {Id@7, T@7}
                end,
                Z = (T@8 * T@8),
                W = (Z * Z),
                S1 = (Z * ((3.33333333333329318027e-01 + (W * ((1.42857142725034663711e-01 + (W * ((9.09088713343650656196e-02 + (W * ((6.66107313738753120669e-02 + (W * ((4.97687799461593236017e-02 + (W * 1.62858201153657823623e-02)))))))))))))))),
                S2 = (W * (((-1.99999999998764832476e-01) + (W * (((-1.11111104054623557880e-01) + (W * (((-7.69187620504482999495e-02) + (W * (((-5.83357013379057348645e-02) + (W * (-3.65315727442169155270e-02)))))))))))))),
                case (Id@8 < 0.0) of
                    true ->
                        (T@8 - (T@8 * ((S1 + S2))));
                    _ ->
                        Hi = case (Id@8 < 0.5) of
                            true ->
                                4.63647609000806093515e-01;
                            false ->
                                case (Id@8 < 1.5) of
                                    true ->
                                        7.85398163397448278999e-01;
                                    false ->
                                        case (Id@8 < 2.5) of
                                            true ->
                                                9.82793723247329054082e-01;
                                            false ->
                                                1.57079632679489655800e+00
                                        end
                                end
                        end,
                        Lo = case (Id@8 < 0.5) of
                            true ->
                                2.26987774529616870924e-17;
                            false ->
                                case (Id@8 < 1.5) of
                                    true ->
                                        3.06161699786838301793e-17;
                                    false ->
                                        case (Id@8 < 2.5) of
                                            true ->
                                                1.39033110312309984516e-17;
                                            false ->
                                                6.12323399573676603587e-17
                                        end
                                end
                        end,
                        Zz = (Hi - (((((T@8 * ((S1 + S2))) - Lo)) - T@8))),
                        case Neg of
                            true ->
                                ((-1.0) * Zz);
                            false ->
                                Zz
                        end
                end
        end
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

atan2Body(Y, X) ->
    case ((X =/= X) orelse (Y =/= Y)) of
        true ->
            (X + Y);
        _ ->
            case (X =:= 1.0) of
                true ->
                    atanBody(Y);
                _ ->
                    PiV = 3.1415926535897931160E+00,
                    PiLo = 1.2246467991473531772E-16,
                    HalfPi = 1.5707963267948965580E+00,
                    QuarterPi = 7.8539816339744827900E-01,
                    Ny = signBit(Y),
                    Nx = signBit(X),
                    My = case Ny of
                        true ->
                            1.0;
                        false ->
                            0.0
                    end,
                    Mx = case Nx of
                        true ->
                            2.0;
                        false ->
                            0.0
                    end,
                    M = '__bp_add'(My, Mx),
                    case isZero(Y) of
                        true ->
                            case (M < 1.5) of
                                true ->
                                    Y;
                                false ->
                                    case (M < 2.5) of
                                        true ->
                                            PiV;
                                        false ->
                                            ((-1.0) * PiV)
                                    end
                            end;
                        _ ->
                            case isZero(X) of
                                true ->
                                    case Ny of
                                        true ->
                                            ((-1.0) * HalfPi);
                                        false ->
                                            HalfPi
                                    end;
                                _ ->
                                    Ix = highWord(X),
                                    Iy = highWord(Y),
                                    case (Ix =:= 2146435072.0) of
                                        true ->
                                            case (Iy =:= 2146435072.0) of
                                                true ->
                                                    case (M < 0.5) of
                                                        true ->
                                                            QuarterPi;
                                                        false ->
                                                            case (M < 1.5) of
                                                                true ->
                                                                    ((-1.0) * QuarterPi);
                                                                false ->
                                                                    case (M < 2.5) of
                                                                        true ->
                                                                            (3.0 * QuarterPi);
                                                                        false ->
                                                                            ((-3.0) * QuarterPi)
                                                                    end
                                                            end
                                                    end;
                                                _ ->
                                                    case (M < 0.5) of
                                                        true ->
                                                            0.0;
                                                        false ->
                                                            case (M < 1.5) of
                                                                true ->
                                                                    ((-1.0) * 0.0);
                                                                false ->
                                                                    case (M < 2.5) of
                                                                        true ->
                                                                            PiV;
                                                                        false ->
                                                                            ((-1.0) * PiV)
                                                                    end
                                                            end
                                                    end
                                            end;
                                        _ ->
                                            case (Iy =:= 2146435072.0) of
                                                true ->
                                                    case Ny of
                                                        true ->
                                                            ((-1.0) * HalfPi);
                                                        false ->
                                                            HalfPi
                                                    end;
                                                _ ->
                                                    K = math:floor((((Iy - Ix)) / 1048576.0)),
                                                    Mm = M,
                                                    Z = 0.0,
                                                    {Z@5, Mm@2} = case (K > 60.0) of
                                                        true ->
                                                            Z@1 = (HalfPi + (0.5 * PiLo)),
                                                            Mm@1 = (M - (2.0 * math:floor((M * 0.5)))),
                                                            {Z@1, Mm@1};
                                                        _ ->
                                                            Z@4 = case (Nx andalso (K < (-60.0))) of
                                                                true ->
                                                                    Z@2 = 0.0,
                                                                    Z@2;
                                                                _ ->
                                                                    Z@3 = atanBody(erlang:abs((Y / '__bp_nz'(X, <<"division by zero: / on f64 at src/math.bp:2273:65">>)))),
                                                                    Z@3
                                                            end,
                                                            {Z@4, Mm}
                                                    end,
                                                    case (Mm@2 < 0.5) of
                                                        true ->
                                                            Z@5;
                                                        false ->
                                                            case (Mm@2 < 1.5) of
                                                                true ->
                                                                    ((-1.0) * Z@5);
                                                                false ->
                                                                    case (Mm@2 < 2.5) of
                                                                        true ->
                                                                            (PiV - ((Z@5 - PiLo)));
                                                                        false ->
                                                                            (((Z@5 - PiLo)) - PiV)
                                                                    end
                                                            end
                                                    end
                                            end
                                    end
                            end
                    end
            end
    end.

% ── hyperbolic functions ─────────────────────────────────────────────────────

sinhBody(X) ->
    H = case (X < 0.0) of
        true ->
            (-0.5);
        false ->
            0.5
    end,
    Ax = erlang:abs(X),
    case (Ax < 22.0) of
        true ->
            case (Ax < 3.725290298461914e-9) of
                true ->
                    X;
                _ ->
                    T = expm1Body(Ax),
                    case (Ax < 1.0) of
                        true ->
                            (H * (((2.0 * T) - ((T * T) / '__bp_nz'(((T + 1.0)), <<"division by zero: / on f64 at src/math.bp:2292:51">>)))));
                        _ ->
                            (H * ((T + (T / '__bp_nz'(((T + 1.0)), <<"division by zero: / on f64 at src/math.bp:2293:27">>)))))
                    end
            end;
        _ ->
            case (Ax < 709.7822265625) of
                true ->
                    (H * expBody(Ax));
                _ ->
                    case (Ax =< 710.4758600739439) of
                        true ->
                            W = expBody((0.5 * Ax)),
                            T@1 = (H * W),
                            (T@1 * W);
                        _ ->
                            (X * 1.0e307)
                    end
            end
    end.

coshBody(X) ->
    Ix = highWord(X),
    case (Ix < 1071001155.0) of
        true ->
            T = expm1Body(erlang:abs(X)),
            W = (1.0 + T),
            case (Ix < 1015021568.0) of
                true ->
                    W;
                _ ->
                    (1.0 + (((T * T)) / '__bp_nz'(((W + W)), <<"division by zero: / on f64 at src/math.bp:2310:30">>)))
            end;
        _ ->
            case (Ix < 1077280768.0) of
                true ->
                    T@1 = expBody(erlang:abs(X)),
                    ((0.5 * T@1) + (0.5 / '__bp_nz'(T@1, <<"division by zero: / on f64 at src/math.bp:2314:30">>)));
                _ ->
                    case (Ix < 1082535490.0) of
                        true ->
                            (0.5 * expBody(erlang:abs(X)));
                        _ ->
                            case (erlang:abs(X) =< 710.4758600739439) of
                                true ->
                                    W@1 = expBody((0.5 * erlang:abs(X))),
                                    T@2 = (0.5 * W@1),
                                    (T@2 * W@1);
                                _ ->
                                    case (Ix >= 2146435072.0) of
                                        true ->
                                            (X * X);
                                        _ ->
                                            timesHuge(1.0, 1.0e300)
                                    end
                            end
                    end
            end
    end.

tanhBody(X) ->
    try
        Ix = highWord(X),
        Neg = signBit(X),
        case (Ix >= 2146435072.0) of
            true ->
                case (not Neg) of
                    true ->
                        ((1.0 / '__bp_nz'(X, <<"division by zero: / on f64 at src/math.bp:2329:50">>)) + 1.0);
                    false ->
                        ((1.0 / '__bp_nz'(X, <<"division by zero: / on f64 at src/math.bp:2329:69">>)) - 1.0)
                end;
            _ ->
                Z = 0.0,
                Z@5 = case (Ix < 1077280768.0) of
                    true ->
                        case (Ix < 1043333120.0) of
                            true ->
                                erlang:throw({'__bp_try', X});
                            _ -> ok
                        end,
                        Z@3 = case (Ix >= 1072693248.0) of
                            true ->
                                T = expm1Body((2.0 * erlang:abs(X))),
                                Z@1 = (1.0 - (2.0 / '__bp_nz'(((T + 2.0)), <<"division by zero: / on f64 at src/math.bp:2335:27">>))),
                                Z@1;
                            _ ->
                                T@1 = expm1Body(((-2.0) * erlang:abs(X))),
                                Z@2 = ((((-1.0) * T@1)) / '__bp_nz'(((T@1 + 2.0)), <<"division by zero: / on f64 at src/math.bp:2338:28">>)),
                                Z@2
                        end,
                        Z@3;
                    _ ->
                        Z@4 = (1.0 - 1.0e-300),
                        Z@4
                end,
                case (not Neg) of
                    true ->
                        Z@5;
                    false ->
                        ((-1.0) * Z@5)
                end
        end
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

% ── tests ────────────────────────────────────────────────────────────────────















'__bp_add'(A, B) when erlang:is_binary(A), erlang:is_binary(B) -> <<A/binary, B/binary>>;
'__bp_add'(A, B) -> A + B.

-compile({inline,['__bp_nz'/2]}).
'__bp_nz'(B, What) when B == 0 -> erlang:error({panic, What});
'__bp_nz'(B, _) -> B.

'__bp_priv__roundHalfUp'(A0) -> roundHalfUp(A0).

'__bp_priv__timesHuge'(A0, A1) -> timesHuge(A0, A1).

'__bp_priv__twoTo'(A0) -> twoTo(A0).

'__bp_priv__exponentOf'(A0) -> exponentOf(A0).

'__bp_priv__subnormalBits'(A0) -> subnormalBits(A0).

'__bp_priv__highWord'(A0) -> highWord(A0).

'__bp_priv__lowWord'(A0) -> lowWord(A0).

'__bp_priv__fromWords'(A0, A1) -> fromWords(A0, A1).

'__bp_priv__withLowZero'(A0) -> withLowZero(A0).

'__bp_priv__signBit'(A0) -> signBit(A0).

'__bp_priv__isZero'(A0) -> isZero(A0).

'__bp_priv__exponentField'(A0) -> exponentField(A0).

'__bp_priv__expBody'(A0) -> expBody(A0).

'__bp_priv__expm1Body'(A0) -> expm1Body(A0).

'__bp_priv__logSpecial'(A0) -> logSpecial(A0).

'__bp_priv__logScaled'(A0, A1) -> logScaled(A0, A1).

'__bp_priv__logMantissaBits'(A0) -> logMantissaBits(A0).

'__bp_priv__lnBody'(A0) -> lnBody(A0).

'__bp_priv__logOnePlusTail'(A0) -> logOnePlusTail(A0).

'__bp_priv__log2Body'(A0) -> log2Body(A0).

'__bp_priv__log10Body'(A0) -> log10Body(A0).

'__bp_priv__sumError'(A0, A1, A2) -> sumError(A0, A1, A2).

'__bp_priv__productError'(A0, A1, A2) -> productError(A0, A1, A2).

'__bp_priv__unitInFirstPlace'(A0) -> unitInFirstPlace(A0).

'__bp_priv__sumRoundedToOdd'(A0, A1) -> sumRoundedToOdd(A0, A1).

'__bp_priv__fusedMultiplyAdd'(A0, A1, A2) -> fusedMultiplyAdd(A0, A1, A2).

'__bp_priv__wholeKind'(A0) -> wholeKind(A0).

'__bp_priv__powBody'(A0, A1) -> powBody(A0, A1).

'__bp_priv__powExp'(A0, A1, A2) -> powExp(A0, A1, A2).

'__bp_priv__powInvc'(A0) -> powInvc(A0).

'__bp_priv__powLogc'(A0) -> powLogc(A0).

'__bp_priv__powLogctail'(A0) -> powLogctail(A0).

'__bp_priv__expHead'(A0) -> expHead(A0).

'__bp_priv__expTail'(A0) -> expTail(A0).

'__bp_priv__remPio2'(A0, A1) -> remPio2(A0, A1).

'__bp_priv__kernelCos'(A0, A1) -> kernelCos(A0, A1).

'__bp_priv__kernelSin'(A0, A1, A2) -> kernelSin(A0, A1, A2).

'__bp_priv__kernelTan'(A0, A1, A2) -> kernelTan(A0, A1, A2).

'__bp_priv__quadrantOf'(A0) -> quadrantOf(A0).

'__bp_priv__sinBody'(A0) -> sinBody(A0).

'__bp_priv__cosBody'(A0) -> cosBody(A0).

'__bp_priv__tanBody'(A0) -> tanBody(A0).

'__bp_priv__asinPoly'(A0) -> asinPoly(A0).

'__bp_priv__asinBody'(A0) -> asinBody(A0).

'__bp_priv__acosBody'(A0) -> acosBody(A0).

'__bp_priv__atanBody'(A0) -> atanBody(A0).

'__bp_priv__atan2Body'(A0, A1) -> atan2Body(A0, A1).

'__bp_priv__sinhBody'(A0) -> sinhBody(A0).

'__bp_priv__coshBody'(A0) -> coshBody(A0).

'__bp_priv__tanhBody'(A0) -> tanhBody(A0).
