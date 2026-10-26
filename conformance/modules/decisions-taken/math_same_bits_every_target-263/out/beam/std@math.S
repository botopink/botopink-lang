{module, std@math}.
{exports, [{pi, 0}, {e, 0}, {tau, 0}, {sqrt2, 0}, {ln2, 0}, {ln10, 0}, {log2e, 0}, {log10e, 0}, {abs, 1}, {floor, 1}, {round, 1}, {trunc, 1}, {ceil, 1}, {sign, 1}, {minF, 2}, {maxF, 2}, {clamp, 3}, {sqrt, 1}, {pow, 2}, {cbrt, 1}, {exp, 1}, {ln, 1}, {log2, 1}, {log10, 1}, {hypot, 2}, {sin, 1}, {cos, 1}, {tan, 1}, {asin, 1}, {acos, 1}, {atan, 1}, {atan2, 2}, {sinh, 1}, {cosh, 1}, {tanh, 1}, {'__bp_priv__acosBody', 1}, {'__bp_priv__asinBody', 1}, {'__bp_priv__asinPoly', 1}, {'__bp_priv__atan2Body', 2}, {'__bp_priv__atanBody', 1}, {'__bp_priv__cosBody', 1}, {'__bp_priv__coshBody', 1}, {'__bp_priv__expBody', 1}, {'__bp_priv__expHead', 1}, {'__bp_priv__expTail', 1}, {'__bp_priv__expm1Body', 1}, {'__bp_priv__exponentField', 1}, {'__bp_priv__exponentOf', 1}, {'__bp_priv__fromWords', 2}, {'__bp_priv__fusedMultiplyAdd', 3}, {'__bp_priv__highWord', 1}, {'__bp_priv__isZero', 1}, {'__bp_priv__kernelCos', 2}, {'__bp_priv__kernelSin', 3}, {'__bp_priv__kernelTan', 3}, {'__bp_priv__lnBody', 1}, {'__bp_priv__log10Body', 1}, {'__bp_priv__log2Body', 1}, {'__bp_priv__logMantissaBits', 1}, {'__bp_priv__logOnePlusTail', 1}, {'__bp_priv__logScaled', 2}, {'__bp_priv__logSpecial', 1}, {'__bp_priv__lowWord', 1}, {'__bp_priv__powBody', 2}, {'__bp_priv__powExp', 3}, {'__bp_priv__powInvc', 1}, {'__bp_priv__powLogc', 1}, {'__bp_priv__powLogctail', 1}, {'__bp_priv__productError', 3}, {'__bp_priv__quadrantOf', 1}, {'__bp_priv__remPio2', 2}, {'__bp_priv__roundHalfUp', 1}, {'__bp_priv__signBit', 1}, {'__bp_priv__sinBody', 1}, {'__bp_priv__sinhBody', 1}, {'__bp_priv__subnormalBits', 1}, {'__bp_priv__sumError', 3}, {'__bp_priv__sumRoundedToOdd', 2}, {'__bp_priv__tanBody', 1}, {'__bp_priv__tanhBody', 1}, {'__bp_priv__timesHuge', 2}, {'__bp_priv__twoTo', 1}, {'__bp_priv__unitInFirstPlace', 1}, {'__bp_priv__wholeKind', 1}, {'__bp_priv__withLowZero', 1}]}.
{attributes, []}.
{labels, 2123}.
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

{function, pi, 0, 3}.
  {label, 2}.
    {line, [{location, "std@math.erl", 1}]}.
    {func_info, {atom, std@math}, {atom, pi}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {float, 3.141592653589793}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, e, 0, 5}.
  {label, 4}.
    {line, [{location, "std@math.erl", 2}]}.
    {func_info, {atom, std@math}, {atom, e}, 0}.
  {label, 5}.
    {allocate, 0, 0}.
    {move, {float, 2.718281828459045}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, tau, 0, 7}.
  {label, 6}.
    {line, [{location, "std@math.erl", 3}]}.
    {func_info, {atom, std@math}, {atom, tau}, 0}.
  {label, 7}.
    {allocate, 0, 0}.
    {move, {float, 6.283185307179586}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, sqrt2, 0, 9}.
  {label, 8}.
    {line, [{location, "std@math.erl", 4}]}.
    {func_info, {atom, std@math}, {atom, sqrt2}, 0}.
  {label, 9}.
    {allocate, 0, 0}.
    {move, {float, 1.4142135623730951}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, ln2, 0, 11}.
  {label, 10}.
    {line, [{location, "std@math.erl", 5}]}.
    {func_info, {atom, std@math}, {atom, ln2}, 0}.
  {label, 11}.
    {allocate, 0, 0}.
    {move, {float, 0.6931471805599453}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, ln10, 0, 13}.
  {label, 12}.
    {line, [{location, "std@math.erl", 6}]}.
    {func_info, {atom, std@math}, {atom, ln10}, 0}.
  {label, 13}.
    {allocate, 0, 0}.
    {move, {float, 2.302585092994046}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, log2e, 0, 15}.
  {label, 14}.
    {line, [{location, "std@math.erl", 7}]}.
    {func_info, {atom, std@math}, {atom, log2e}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {move, {float, 1.4426950408889634}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, log10e, 0, 17}.
  {label, 16}.
    {line, [{location, "std@math.erl", 8}]}.
    {func_info, {atom, std@math}, {atom, log10e}, 0}.
  {label, 17}.
    {allocate, 0, 0}.
    {move, {float, 0.4342944819032518}, {x, 0}}.
    {deallocate, 0}.
    return.
% ── arithmetic + rounding ────────────────────────────────────────────────────
% `abs` works on `f64`. Integer abs lives on the numeric tower
% (`primitives.bp` Signed). `minF`/`maxF` are the float variants — the
% generic ones live on `Number`.

{function, abs, 1, 159}.
  {label, 158}.
    {line, [{location, "std@math.erl", 9}]}.
    {func_info, {atom, std@math}, {atom, abs}, 1}.
  {label, 159}.
    {call_ext_only, 1, {extfunc, erlang, abs, 1}}.

{function, floor, 1, 161}.
  {label, 160}.
    {line, [{location, "std@math.erl", 10}]}.
    {func_info, {atom, std@math}, {atom, floor}, 1}.
  {label, 161}.
    {call_ext_only, 1, {extfunc, math, floor, 1}}.

{function, round, 1, 163}.
  {label, 162}.
    {line, [{location, "std@math.erl", 11}]}.
    {func_info, {atom, std@math}, {atom, round}, 1}.
  {label, 163}.
    {call_ext_only, 1, {extfunc, erlang, round, 1}}.

{function, trunc, 1, 165}.
  {label, 164}.
    {line, [{location, "std@math.erl", 12}]}.
    {func_info, {atom, std@math}, {atom, trunc}, 1}.
  {label, 165}.
    {call_ext_only, 1, {extfunc, erlang, trunc, 1}}.
% `ceil(x) = -floor(-x)` — a pure-botopink derivation that avoids the
% erlang inline-arithmetic template (no `math:ceil/1` BIF exists pre-OTP-26).

{function, ceil, 1, 19}.
  {label, 18}.
    {line, [{location, "std@math.erl", 13}]}.
    {func_info, {atom, std@math}, {atom, ceil}, 1}.
  {label, 19}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '-', {f, 0}, 0, [{float, 0.0}, {y, 0}], {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
    {gc_bif, '-', {f, 0}, 1, [{float, 0.0}, {x, 0}], {x, 0}}.
    {deallocate, 3}.
    return.
% `sign` returns -1.0, 0.0, or 1.0 depending on the input's sign.
% Pure-botopink; sidesteps the inline-case template the spec describes.

{function, sign, 1, 21}.
  {label, 20}.
    {line, [{location, "std@math.erl", 14}]}.
    {func_info, {atom, std@math}, {atom, sign}, 1}.
  {label, 21}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_lt, {f, 172}, [{float, 0.0}, {y, 0}]}.
    {move, {float, 1.0}, {x, 0}}.
    {jump, {f, 173}}.
  {label, 172}.
    {test, is_lt, {f, 174}, [{y, 0}, {float, 0.0}]}.
    {gc_bif, '-', {f, 0}, 0, [{float, 0.0}, {float, 1.0}], {x, 0}}.
    {jump, {f, 175}}.
  {label, 174}.
    {move, {float, 0.0}, {x, 0}}.
  {label, 175}.
  {label, 173}.
    {deallocate, 1}.
    return.

{function, minF, 2, 167}.
  {label, 166}.
    {line, [{location, "std@math.erl", 15}]}.
    {func_info, {atom, std@math}, {atom, minF}, 2}.
  {label, 167}.
    {call_ext_only, 2, {extfunc, erlang, min, 2}}.

{function, maxF, 2, 169}.
  {label, 168}.
    {line, [{location, "std@math.erl", 16}]}.
    {func_info, {atom, std@math}, {atom, maxF}, 2}.
  {label, 169}.
    {call_ext_only, 2, {extfunc, erlang, max, 2}}.

{function, clamp, 3, 23}.
  {label, 22}.
    {line, [{location, "std@math.erl", 17}]}.
    {func_info, {atom, std@math}, {atom, clamp}, 3}.
  {label, 23}.
    {allocate, 5, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 2, {extfunc, erlang, max, 2}, 5}.
% ── powers + roots + exp/log ─────────────────────────────────────────────────

{function, sqrt, 1, 171}.
  {label, 170}.
    {line, [{location, "std@math.erl", 18}]}.
    {func_info, {atom, std@math}, {atom, sqrt}, 1}.
  {label, 171}.
    {call_ext_only, 1, {extfunc, math, sqrt, 1}}.
% Every target runs std's body (decision 610: a function whose every target
% runs botopink is a bodied `fn`).

{function, pow, 2, 25}.
  {label, 24}.
    {line, [{location, "std@math.erl", 19}]}.
    {func_info, {atom, std@math}, {atom, pow}, 2}.
  {label, 25}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 2, {f, 113}, 2}.
% `cbrt(x)` via `pow(x, 1/3)`, honouring sign for negatives. Pure-botopink;
% node has `Math.cbrt` but the erlang side has no BIF — composition is uniform.

{function, cbrt, 1, 27}.
  {label, 26}.
    {line, [{location, "std@math.erl", 20}]}.
    {func_info, {atom, std@math}, {atom, cbrt}, 1}.
  {label, 27}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_ge, {f, 176}, [{y, 0}, {float, 0.0}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {float, 0.3333333333333333}, {x, 1}}.
    {call, 2, {f, 25}}.
    {jump, {f, 177}}.
  {label, 176}.
    {gc_bif, '-', {f, 0}, 0, [{float, 0.0}, {y, 0}], {x, 0}}.
    {move, {float, 0.3333333333333333}, {x, 1}}.
    {call, 2, {f, 25}}.
    {gc_bif, '-', {f, 0}, 1, [{float, 0.0}, {x, 0}], {x, 0}}.
  {label, 177}.
    {deallocate, 3}.
    return.

{function, exp, 1, 29}.
  {label, 28}.
    {line, [{location, "std@math.erl", 21}]}.
    {func_info, {atom, std@math}, {atom, exp}, 1}.
  {label, 29}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 83}, 1}.

{function, ln, 1, 31}.
  {label, 30}.
    {line, [{location, "std@math.erl", 22}]}.
    {func_info, {atom, std@math}, {atom, ln}, 1}.
  {label, 31}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 93}, 1}.

{function, log2, 1, 33}.
  {label, 32}.
    {line, [{location, "std@math.erl", 23}]}.
    {func_info, {atom, std@math}, {atom, log2}, 1}.
  {label, 33}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 97}, 1}.

{function, log10, 1, 35}.
  {label, 34}.
    {line, [{location, "std@math.erl", 24}]}.
    {func_info, {atom, std@math}, {atom, log10}, 1}.
  {label, 35}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 99}, 1}.
% `hypot(x, y) = sqrt(x*x + y*y)` — pure-botopink composition.

{function, hypot, 2, 37}.
  {label, 36}.
    {line, [{location, "std@math.erl", 25}]}.
    {func_info, {atom, std@math}, {atom, hypot}, 2}.
  {label, 37}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {y, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '*', {f, 0}, 2, [{y, 1}, {y, 1}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {call_ext_last, 1, {extfunc, math, sqrt, 1}, 2}.
% ── trigonometry ─────────────────────────────────────────────────────────────

{function, sin, 1, 39}.
  {label, 38}.
    {line, [{location, "std@math.erl", 26}]}.
    {func_info, {atom, std@math}, {atom, sin}, 1}.
  {label, 39}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 137}, 1}.

{function, cos, 1, 41}.
  {label, 40}.
    {line, [{location, "std@math.erl", 27}]}.
    {func_info, {atom, std@math}, {atom, cos}, 1}.
  {label, 41}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 139}, 1}.

{function, tan, 1, 43}.
  {label, 42}.
    {line, [{location, "std@math.erl", 28}]}.
    {func_info, {atom, std@math}, {atom, tan}, 1}.
  {label, 43}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 141}, 1}.

{function, asin, 1, 45}.
  {label, 44}.
    {line, [{location, "std@math.erl", 29}]}.
    {func_info, {atom, std@math}, {atom, asin}, 1}.
  {label, 45}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 145}, 1}.

{function, acos, 1, 47}.
  {label, 46}.
    {line, [{location, "std@math.erl", 30}]}.
    {func_info, {atom, std@math}, {atom, acos}, 1}.
  {label, 47}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 147}, 1}.

{function, atan, 1, 49}.
  {label, 48}.
    {line, [{location, "std@math.erl", 31}]}.
    {func_info, {atom, std@math}, {atom, atan}, 1}.
  {label, 49}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 149}, 1}.

{function, atan2, 2, 51}.
  {label, 50}.
    {line, [{location, "std@math.erl", 32}]}.
    {func_info, {atom, std@math}, {atom, atan2}, 2}.
  {label, 51}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 2, {f, 151}, 2}.

{function, sinh, 1, 53}.
  {label, 52}.
    {line, [{location, "std@math.erl", 33}]}.
    {func_info, {atom, std@math}, {atom, sinh}, 1}.
  {label, 53}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 153}, 1}.

{function, cosh, 1, 55}.
  {label, 54}.
    {line, [{location, "std@math.erl", 34}]}.
    {func_info, {atom, std@math}, {atom, cosh}, 1}.
  {label, 55}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 155}, 1}.

{function, tanh, 1, 57}.
  {label, 56}.
    {line, [{location, "std@math.erl", 35}]}.
    {func_info, {atom, std@math}, {atom, tanh}, 1}.
  {label, 57}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 157}, 1}.
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

{function, roundHalfUp, 1, 59}.
  {label, 58}.
    {line, [{location, "std@math.erl", 36}]}.
    {func_info, {atom, std@math}, {atom, roundHalfUp}, 1}.
  {label, 59}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '*', {f, 0}, 0, [{float, -1.0}, {y, 0}], {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
    {gc_bif, '*', {f, 0}, 1, [{float, -1.0}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {float, 0.5}], {x, 0}}.
    {test, is_lt, {f, 178}, [{y, 0}, {x, 0}]}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {float, 1.0}], {x, 0}}.
    {jump, {f, 179}}.
  {label, 178}.
    {move, {y, 1}, {x, 0}}.
  {label, 179}.
    {deallocate, 4}.
    return.
% `s · h · h`: an overflow to ±Infinity (`h` = 1e300) or an underflow to ±0
% (`h` = 1e-300) as fdlibm writes them, with `h` a parameter so no target
% folds the product at compile time.

{function, timesHuge, 2, 61}.
  {label, 60}.
    {line, [{location, "std@math.erl", 37}]}.
    {func_info, {atom, std@math}, {atom, timesHuge}, 2}.
  {label, 61}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {y, 1}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {y, 1}], {x, 0}}.
    {deallocate, 2}.
    return.
% 2^k for a whole k in -1074..1023 — every step exact.

{function, twoTo, 1, 63}.
  {label, 62}.
    {line, [{location, "std@math.erl", 38}]}.
    {func_info, {atom, std@math}, {atom, twoTo}, 1}.
  {label, 63}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {float, 1.0}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {line, [{location, "std@math.erl", 39}]}.
  {label, 180}.
    {test, is_ge, {f, 181}, [{y, 2}, {float, 32.0}]}.
    {gc_bif, '*', {f, 0}, 0, [{y, 1}, {float, 4294967296.0}], {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 2}, {float, 32.0}], {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 180}}.
  {label, 181}.
    {line, [{location, "std@math.erl", 39}]}.
  {label, 182}.
    {test, is_ge, {f, 183}, [{y, 2}, {float, 1.0}]}.
    {gc_bif, '*', {f, 0}, 0, [{y, 1}, {float, 2.0}], {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 2}, {float, 1.0}], {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 182}}.
  {label, 183}.
    {line, [{location, "std@math.erl", 39}]}.
  {label, 184}.
    {test, is_ge, {f, 185}, [{float, -32.0}, {y, 2}]}.
    {gc_bif, '*', {f, 0}, 0, [{y, 1}, {float, 2.3283064365386963e-10}], {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {float, 32.0}], {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 184}}.
  {label, 185}.
    {line, [{location, "std@math.erl", 39}]}.
  {label, 186}.
    {test, is_ge, {f, 187}, [{float, -1.0}, {y, 2}]}.
    {gc_bif, '*', {f, 0}, 0, [{y, 1}, {float, 0.5}], {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {float, 1.0}], {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 186}}.
  {label, 187}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 3}.
    return.
% e with 2^e ≤ ax < 2^(e+1), for a positive finite ax.

{function, exponentOf, 1, 65}.
  {label, 64}.
    {line, [{location, "std@math.erl", 39}]}.
    {func_info, {atom, std@math}, {atom, exponentOf}, 1}.
  {label, 65}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {float, 0.0}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {line, [{location, "std@math.erl", 40}]}.
  {label, 188}.
    {test, is_ge, {f, 189}, [{y, 1}, {float, 4294967296.0}]}.
    {gc_bif, '*', {f, 0}, 0, [{y, 1}, {float, 2.3283064365386963e-10}], {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {float, 32.0}], {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 188}}.
  {label, 189}.
    {line, [{location, "std@math.erl", 40}]}.
  {label, 190}.
    {test, is_ge, {f, 191}, [{y, 1}, {float, 2.0}]}.
    {gc_bif, '*', {f, 0}, 0, [{y, 1}, {float, 0.5}], {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {float, 1.0}], {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 190}}.
  {label, 191}.
    {line, [{location, "std@math.erl", 40}]}.
  {label, 192}.
    {test, is_lt, {f, 193}, [{y, 1}, {float, 2.3283064365386963e-10}]}.
    {gc_bif, '*', {f, 0}, 0, [{y, 1}, {float, 4294967296.0}], {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 2}, {float, 32.0}], {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 192}}.
  {label, 193}.
    {line, [{location, "std@math.erl", 40}]}.
  {label, 194}.
    {test, is_lt, {f, 195}, [{y, 1}, {float, 1.0}]}.
    {gc_bif, '*', {f, 0}, 0, [{y, 1}, {float, 2.0}], {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 2}, {float, 1.0}], {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 194}}.
  {label, 195}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 3}.
    return.
% The 52-bit significand of a subnormal |x| as a whole number.

{function, subnormalBits, 1, 67}.
  {label, 66}.
    {line, [{location, "std@math.erl", 40}]}.
    {func_info, {atom, std@math}, {atom, subnormalBits}, 1}.
  {label, 67}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {float, 1000.0}, {x, 0}}.
    {call, 1, {f, 63}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {float, 74.0}, {x, 0}}.
    {call, 1, {f, 63}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 1}, {x, 0}], {x, 0}}.
    {deallocate, 5}.
    return.
% fdlibm's `hx & 0x7fffffff`: the high 32-bit word of |x| as a whole number.

{function, highWord, 1, 69}.
  {label, 68}.
    {line, [{location, "std@math.erl", 41}]}.
    {func_info, {atom, std@math}, {atom, highWord}, 1}.
  {label, 69}.
    {allocate, 10, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_ne_exact, {f, 196}, [{y, 0}, {y, 0}]}.
    {move, {float, 2146959360.0}, {x, 0}}.
    {deallocate, 10}.
    return.
  {label, 196}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, abs, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 79}}.
    {test, is_eq, {f, 197}, [{x, 0}, {atom, true}]}.
    {move, {float, 0.0}, {x, 0}}.
    {deallocate, 10}.
    return.
  {label, 197}.
    {test, is_lt, {f, 198}, [{float, 1.7976931348623157e308}, {y, 1}]}.
    {move, {float, 2146435072.0}, {x, 0}}.
    {deallocate, 10}.
    return.
  {label, 198}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 65}}.
    {move, {x, 0}, {y, 2}}.
    {test, is_lt, {f, 199}, [{y, 2}, {float, -1022.0}]}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 67}}.
    {gc_bif, '/', {f, 0}, 1, [{x, 0}, {float, 4294967296.0}], {x, 0}}.
    {call_ext_last, 1, {extfunc, math, floor, 1}, 10}.
  {label, 199}.
    {gc_bif, '-', {f, 0}, 0, [{float, 0.0}, {y, 2}], {x, 0}}.
    {call, 1, {f, 63}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 1}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {float, 1023.0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {float, 1048576.0}], {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 3}, {float, 1.0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {float, 1048576.0}], {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 4}, {x, 0}], {x, 0}}.
    {deallocate, 10}.
    return.
% fdlibm's low word: the low 32 bits of |x|'s significand.

{function, lowWord, 1, 71}.
  {label, 70}.
    {line, [{location, "std@math.erl", 42}]}.
    {func_info, {atom, std@math}, {atom, lowWord}, 1}.
  {label, 71}.
    {allocate, 12, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, abs, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_ne_exact, {f, 201}, [{y, 0}, {y, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 202}}.
  {label, 201}.
    {move, {atom, false}, {x, 0}}.
  {label, 202}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 203}, [{x, 1}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 79}}.
    {jump, {f, 204}}.
  {label, 203}.
    {move, {atom, true}, {x, 0}}.
  {label, 204}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 205}, [{x, 1}, {atom, true}]}.
    {test, is_lt, {f, 207}, [{float, 1.7976931348623157e308}, {y, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 208}}.
  {label, 207}.
    {move, {atom, false}, {x, 0}}.
  {label, 208}.
    {jump, {f, 206}}.
  {label, 205}.
    {move, {atom, true}, {x, 0}}.
  {label, 206}.
    {test, is_eq, {f, 200}, [{x, 0}, {atom, true}]}.
    {move, {float, 0.0}, {x, 0}}.
    {deallocate, 12}.
    return.
  {label, 200}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 65}}.
    {move, {x, 0}, {y, 2}}.
    {test, is_lt, {f, 209}, [{y, 2}, {float, -1022.0}]}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 67}}.
    {jump, {f, 210}}.
  {label, 209}.
    {gc_bif, '-', {f, 0}, 0, [{float, 0.0}, {y, 2}], {x, 0}}.
    {call, 1, {f, 63}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 1}, {x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {float, 1.0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {float, 4503599627370496.0}], {x, 0}}.
  {label, 210}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, '/', {f, 0}, 0, [{y, 3}, {float, 4294967296.0}], {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {float, 4294967296.0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 3}, {x, 0}], {x, 0}}.
    {deallocate, 12}.
    return.
% The positive double whose words are `hw` (below the sign) and `lw`.

{function, fromWords, 2, 73}.
  {label, 72}.
    {line, [{location, "std@math.erl", 43}]}.
    {func_info, {atom, std@math}, {atom, fromWords}, 2}.
  {label, 73}.
    {allocate, 10, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '/', {f, 0}, 0, [{y, 0}, {float, 1048576.0}], {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 2}, {float, 1048576.0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {float, 4294967296.0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 1}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call, 1, {f, 79}}.
    {test, is_eq, {f, 211}, [{x, 0}, {atom, true}]}.
    {move, {float, -1000.0}, {x, 0}}.
    {call, 1, {f, 63}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 3}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {float, -74.0}, {x, 0}}.
    {call, 1, {f, 63}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 4}, {x, 0}], {x, 0}}.
    {deallocate, 10}.
    return.
  {label, 211}.
    {gc_bif, '/', {f, 0}, 0, [{y, 3}, {float, 4503599627370496.0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, 1.0}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 2}, {float, 1023.0}], {x, 0}}.
    {call, 1, {f, 63}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 5}, {x, 0}], {x, 0}}.
    {deallocate, 10}.
    return.
% fdlibm's `SET_LOW_WORD(x, 0)`.

{function, withLowZero, 1, 75}.
  {label, 74}.
    {line, [{location, "std@math.erl", 44}]}.
    {func_info, {atom, std@math}, {atom, withLowZero}, 1}.
  {label, 75}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 69}}.
    {move, {float, 0.0}, {x, 1}}.
    {call, 2, {f, 73}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 77}}.
    {test, is_eq, {f, 212}, [{x, 0}, {atom, true}]}.
    {gc_bif, '*', {f, 0}, 0, [{float, -1.0}, {y, 1}], {x, 0}}.
    {jump, {f, 213}}.
  {label, 212}.
    {move, {y, 1}, {x, 0}}.
  {label, 213}.
    {deallocate, 2}.
    return.
% Whether `v` carries a minus sign — `-0.0` included (fdlibm's `hx < 0`).
% commonJS and wasm compare `-0.0` equal to `0.0` and tell the two apart by
% `1 / v`; erlang and beam compare them unequal (`=:=`) and have no `1 / 0`.

{function, signBit, 1, 77}.
  {label, 76}.
    {line, [{location, "std@math.erl", 45}]}.
    {func_info, {atom, std@math}, {atom, signBit}, 1}.
  {label, 77}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_lt, {f, 214}, [{y, 0}, {float, 0.0}]}.
    {move, {atom, true}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 214}.
    {test, is_lt, {f, 215}, [{float, 0.0}, {y, 0}]}.
    {move, {atom, false}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 215}.
    {test, is_eq_exact, {f, 217}, [{y, 0}, {float, 0.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 218}}.
  {label, 217}.
    {move, {atom, false}, {x, 0}}.
  {label, 218}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 219}, [{x, 1}, {atom, true}]}.
    {test, is_eq_exact, {f, 221}, [{y, 0}, {float, -0.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 222}}.
  {label, 221}.
    {move, {atom, false}, {x, 0}}.
  {label, 222}.
    {jump, {f, 220}}.
  {label, 219}.
    {move, {atom, false}, {x, 0}}.
  {label, 220}.
    {test, is_eq, {f, 216}, [{x, 0}, {atom, true}]}.
    {test, is_ne, {f, 223}, [{y, 0}, {integer, 0}]}.
    {jump, {f, 224}}.
  {label, 223}.
    {move, {literal, {panic, <<"division by zero: / on f64 at src/math.bp:293:43">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 224}.
    {gc_bif, '/', {f, 0}, 0, [{float, 1.0}, {y, 0}], {x, 0}}.
    {test, is_lt, {f, 225}, [{x, 0}, {float, 0.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 226}}.
  {label, 225}.
    {move, {atom, false}, {x, 0}}.
  {label, 226}.
    {deallocate, 1}.
    return.
  {label, 216}.
    {test, is_eq_exact, {f, 227}, [{y, 0}, {float, -0.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 228}}.
  {label, 227}.
    {move, {atom, false}, {x, 0}}.
  {label, 228}.
    {deallocate, 1}.
    return.
% Whether `v` is `0.0` or `-0.0` — on every target: `v == 0.0` is false for
% `-0.0` on erlang and beam (`=:=`).

{function, isZero, 1, 79}.
  {label, 78}.
    {line, [{location, "std@math.erl", 46}]}.
    {func_info, {atom, std@math}, {atom, isZero}, 1}.
  {label, 79}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_ge, {f, 229}, [{y, 0}, {float, 0.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 230}}.
  {label, 229}.
    {move, {atom, false}, {x, 0}}.
  {label, 230}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 231}, [{x, 1}, {atom, true}]}.
    {test, is_ge, {f, 233}, [{float, 0.0}, {y, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 234}}.
  {label, 233}.
    {move, {atom, false}, {x, 0}}.
  {label, 234}.
    {jump, {f, 232}}.
  {label, 231}.
    {move, {atom, false}, {x, 0}}.
  {label, 232}.
    {deallocate, 1}.
    return.
% The exponent field of x's high word (`(hx >> 20) & 0x7ff`).

{function, exponentField, 1, 81}.
  {label, 80}.
    {line, [{location, "std@math.erl", 47}]}.
    {func_info, {atom, std@math}, {atom, exponentField}, 1}.
  {label, 81}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 69}}.
    {gc_bif, '/', {f, 0}, 1, [{x, 0}, {float, 1048576.0}], {x, 0}}.
    {call_ext_last, 1, {extfunc, math, floor, 1}, 1}.
% ── exp, expm1 ───────────────────────────────────────────────────────────────

{function, expBody, 1, 83}.
  {label, 82}.
    {line, [{location, "std@math.erl", 48}]}.
    {func_info, {atom, std@math}, {atom, expBody}, 1}.
  {label, 83}.
    {allocate, 12, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 69}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 77}}.
    {move, {x, 0}, {y, 2}}.
    {test, is_ge, {f, 235}, [{y, 1}, {float, 1082535490.0}]}.
    {test, is_ge, {f, 236}, [{y, 1}, {float, 2146435072.0}]}.
    {test, is_ne_exact, {f, 237}, [{y, 0}, {y, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {y, 0}], {x, 0}}.
    {deallocate, 12}.
    return.
  {label, 237}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq, {f, 238}, [{x, 0}, {atom, true}]}.
    {move, {float, 0.0}, {x, 0}}.
    {jump, {f, 239}}.
  {label, 238}.
    {move, {y, 0}, {x, 0}}.
  {label, 239}.
    {deallocate, 12}.
    return.
  {label, 236}.
    {test, is_lt, {f, 240}, [{float, 7.09782712893383973096e+02}, {y, 0}]}.
    {move, {float, 1.0}, {x, 0}}.
    {move, {float, 1.0e300}, {x, 1}}.
    {call_last, 2, {f, 61}, 12}.
  {label, 240}.
    {test, is_lt, {f, 241}, [{y, 0}, {float, -7.45133219101941108420e+02}]}.
    {move, {float, 1.0}, {x, 0}}.
    {move, {float, 9.33263618503218878990e-302}, {x, 1}}.
    {call_last, 2, {f, 61}, 12}.
  {label, 241}.
    {jump, {f, 242}}.
  {label, 235}.
  {label, 242}.
    {move, {float, 0.0}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {float, 0.0}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {float, 0.0}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {test, is_lt, {f, 243}, [{float, 1071001154.0}, {y, 1}]}.
    {test, is_lt, {f, 244}, [{y, 1}, {float, 1072734898.0}]}.
    {test, is_eq_exact, {f, 245}, [{y, 0}, {float, 1.0}]}.
    {move, {float, 2.718281828459045}, {x, 0}}.
    {deallocate, 12}.
    return.
  {label, 245}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq, {f, 246}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {float, 6.93147180369123816490e-01}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {float, -1.90821492927058770002e-10}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {float, -1.0}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 247}}.
  {label, 246}.
    {gc_bif, '-', {f, 0}, 0, [{y, 0}, {float, 6.93147180369123816490e-01}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {float, 1.90821492927058770002e-10}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {float, 1.0}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
  {label, 247}.
    {jump, {f, 248}}.
  {label, 244}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq, {f, 249}, [{x, 0}, {atom, true}]}.
    {move, {float, -0.5}, {x, 0}}.
    {jump, {f, 250}}.
  {label, 249}.
    {move, {float, 0.5}, {x, 0}}.
  {label, 250}.
    {move, {x, 0}, {y, 7}}.
    {gc_bif, '*', {f, 0}, 0, [{float, 1.44269504088896338700e+00}, {y, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 7}], {x, 0}}.
    {call_ext, 1, {extfunc, erlang, trunc, 1}}.
    {move, {x, 0}, {y, 5}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 5}, {float, 6.93147180369123816490e-01}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 5}, {float, 1.90821492927058770002e-10}], {x, 0}}.
    {move, {x, 0}, {y, 4}}.
  {label, 248}.
    {gc_bif, '-', {f, 0}, 0, [{y, 3}, {y, 4}], {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {jump, {f, 251}}.
  {label, 243}.
    {test, is_lt, {f, 252}, [{y, 1}, {float, 1043333120.0}]}.
    {gc_bif, '+', {f, 0}, 0, [{float, 1.0}, {y, 0}], {x, 0}}.
    {deallocate, 12}.
    return.
  {label, 252}.
  {label, 251}.
    {gc_bif, '*', {f, 0}, 0, [{y, 6}, {y, 6}], {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {test, is_ge, {f, 253}, [{y, 5}, {float, -1021.0}]}.
    {move, {y, 5}, {x, 0}}.
    {call, 1, {f, 63}}.
    {jump, {f, 254}}.
  {label, 253}.
    {gc_bif, '+', {f, 0}, 0, [{y, 5}, {float, 1000.0}], {x, 0}}.
    {call, 1, {f, 63}}.
  {label, 254}.
    {move, {x, 0}, {y, 9}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 8}, {float, 4.13813679705723846039e-08}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, -1.65339022054652515390e-06}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 8}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, 6.61375632143793436117e-05}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 8}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, -2.77777777770155933842e-03}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 8}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, 1.66666666666666019037e-01}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 8}, {x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 6}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 5}, {x, 0}}.
    {call, 1, {f, 79}}.
    {test, is_eq, {f, 255}, [{x, 0}, {atom, true}]}.
    {gc_bif, '*', {f, 0}, 0, [{y, 6}, {y, 10}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '-', {f, 0}, 2, [{y, 10}, {float, 2.0}], {x, 0}}.
    {test, is_ne, {f, 256}, [{x, 0}, {integer, 0}]}.
    {jump, {f, 257}}.
  {label, 256}.
    {move, {literal, {panic, <<"division by zero: / on f64 at src/math.bp:358:42">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 257}.
    {gc_bif, '/', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {y, 6}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{float, 1.0}, {x, 0}], {x, 0}}.
    {deallocate, 12}.
    return.
  {label, 255}.
    {gc_bif, '*', {f, 0}, 0, [{y, 6}, {y, 10}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '-', {f, 0}, 2, [{float, 2.0}, {y, 10}], {x, 0}}.
    {test, is_ne, {f, 258}, [{x, 0}, {integer, 0}]}.
    {jump, {f, 259}}.
  {label, 258}.
    {move, {literal, {panic, <<"division by zero: / on f64 at src/math.bp:359:34">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 259}.
    {gc_bif, '/', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 4}, {x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {y, 3}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{float, 1.0}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {test, is_ge, {f, 260}, [{y, 5}, {float, -1021.0}]}.
    {test, is_eq_exact, {f, 261}, [{y, 5}, {float, 1024.0}]}.
    {gc_bif, '*', {f, 0}, 0, [{y, 11}, {float, 2.0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {float, 8.988465674311579539e307}], {x, 0}}.
    {deallocate, 12}.
    return.
  {label, 261}.
    {gc_bif, '*', {f, 0}, 0, [{y, 11}, {y, 9}], {x, 0}}.
    {deallocate, 12}.
    return.
  {label, 260}.
    {gc_bif, '*', {f, 0}, 0, [{y, 11}, {y, 9}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {float, 9.33263618503218878990e-302}], {x, 0}}.
    {deallocate, 12}.
    return.

{function, expm1Body, 1, 85}.
  {label, 84}.
    {line, [{location, "std@math.erl", 49}]}.
    {func_info, {atom, std@math}, {atom, expm1Body}, 1}.
  {label, 85}.
    {allocate, 45, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}, {y, 20}, {y, 21}, {y, 22}, {y, 23}, {y, 24}, {y, 25}, {y, 26}, {y, 27}, {y, 28}, {y, 29}, {y, 30}, {y, 31}, {y, 32}, {y, 33}, {y, 34}, {y, 35}, {y, 36}, {y, 37}, {y, 38}, {y, 39}, {y, 40}, {y, 41}, {y, 42}, {y, 43}, {y, 44}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 69}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 77}}.
    {move, {x, 0}, {y, 2}}.
    {test, is_ge, {f, 262}, [{y, 1}, {float, 1078159482.0}]}.
    {test, is_ge, {f, 263}, [{y, 1}, {float, 1082535490.0}]}.
    {test, is_ge, {f, 264}, [{y, 1}, {float, 2146435072.0}]}.
    {test, is_ne_exact, {f, 265}, [{y, 0}, {y, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {y, 0}], {x, 0}}.
    {deallocate, 45}.
    return.
  {label, 265}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq, {f, 266}, [{x, 0}, {atom, true}]}.
    {move, {float, -1.0}, {x, 0}}.
    {jump, {f, 267}}.
  {label, 266}.
    {move, {y, 0}, {x, 0}}.
  {label, 267}.
    {deallocate, 45}.
    return.
  {label, 264}.
    {test, is_lt, {f, 268}, [{float, 7.09782712893383973096e+02}, {y, 0}]}.
    {move, {float, 1.0}, {x, 0}}.
    {move, {float, 1.0e300}, {x, 1}}.
    {call_last, 2, {f, 61}, 45}.
  {label, 268}.
    {jump, {f, 269}}.
  {label, 263}.
  {label, 269}.
    {test, is_eq, {f, 271}, [{y, 2}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {float, 1.0e-300}], {x, 0}}.
    {test, is_lt, {f, 273}, [{x, 0}, {float, 0.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 274}}.
  {label, 273}.
    {move, {atom, false}, {x, 0}}.
  {label, 274}.
    {jump, {f, 272}}.
  {label, 271}.
    {move, {atom, false}, {x, 0}}.
  {label, 272}.
    {test, is_eq, {f, 270}, [{x, 0}, {atom, true}]}.
    {gc_bif, '-', {f, 0}, 0, [{float, 1.0e-300}, {float, 1.0}], {x, 0}}.
    {deallocate, 45}.
    return.
  {label, 270}.
    {jump, {f, 275}}.
  {label, 262}.
  {label, 275}.
    {move, {float, 0.0}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {float, 0.0}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {test, is_lt, {f, 276}, [{float, 1071001154.0}, {y, 1}]}.
    {move, {float, 0.0}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {float, 0.0}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {test, is_lt, {f, 277}, [{y, 1}, {float, 1072734898.0}]}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq, {f, 279}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 280}}.
  {label, 279}.
    {move, {atom, true}, {x, 0}}.
  {label, 280}.
    {test, is_eq, {f, 278}, [{x, 0}, {atom, true}]}.
    {gc_bif, '-', {f, 0}, 0, [{y, 0}, {float, 6.93147180369123816490e-01}], {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {float, 1.90821492927058770002e-10}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {float, 1.0}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 281}}.
  {label, 278}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {float, 6.93147180369123816490e-01}], {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {float, -1.90821492927058770002e-10}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {float, -1.0}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
  {label, 281}.
    {jump, {f, 282}}.
  {label, 277}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq, {f, 283}, [{x, 0}, {atom, true}]}.
    {move, {float, -0.5}, {x, 0}}.
    {jump, {f, 284}}.
  {label, 283}.
    {move, {float, 0.5}, {x, 0}}.
  {label, 284}.
    {move, {x, 0}, {y, 8}}.
    {gc_bif, '*', {f, 0}, 0, [{float, 1.44269504088896338700e+00}, {y, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 8}], {x, 0}}.
    {call_ext, 1, {extfunc, erlang, trunc, 1}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 3}, {float, 6.93147180369123816490e-01}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 3}, {float, 1.90821492927058770002e-10}], {x, 0}}.
    {move, {x, 0}, {y, 7}}.
  {label, 282}.
    {gc_bif, '-', {f, 0}, 0, [{y, 6}, {y, 7}], {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 6}, {y, 4}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {y, 7}], {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 285}}.
  {label, 276}.
    {test, is_lt, {f, 286}, [{y, 1}, {float, 1016070144.0}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 45}.
    return.
  {label, 286}.
  {label, 285}.
    {gc_bif, '*', {f, 0}, 0, [{float, 0.5}, {y, 4}], {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 4}, {y, 9}], {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 10}, {float, -2.01099218183624371326e-07}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, 4.00821782732936239552e-06}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 10}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, -7.93650757867487942473e-05}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 10}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, 1.58730158725481460165e-03}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 10}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, -3.33333333333331316428e-02}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 10}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, 1.0}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 11}, {y, 9}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{float, 3.0}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 12}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 11}, {y, 12}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '*', {f, 0}, 2, [{y, 4}, {y, 12}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 2, [{float, 6.0}, {x, 0}], {x, 0}}.
    {test, is_ne, {f, 287}, [{x, 0}, {integer, 0}]}.
    {jump, {f, 288}}.
  {label, 287}.
    {move, {literal, {panic, <<"division by zero: / on f64 at src/math.bp:418:29">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 288}.
    {gc_bif, '/', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 10}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 3}, {x, 0}}.
    {call, 1, {f, 79}}.
    {test, is_eq, {f, 289}, [{x, 0}, {atom, true}]}.
    {gc_bif, '*', {f, 0}, 0, [{y, 4}, {y, 13}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {y, 10}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 4}, {x, 0}], {x, 0}}.
    {deallocate, 45}.
    return.
  {label, 289}.
    {move, {y, 3}, {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 14}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 13}, {y, 5}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 4}, {x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {y, 5}], {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 13}, {y, 10}], {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {test, is_eq_exact, {f, 290}, [{y, 3}, {float, -1.0}]}.
    {gc_bif, '-', {f, 0}, 0, [{y, 4}, {y, 13}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{float, 0.5}, {x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {float, 0.5}], {x, 0}}.
    {deallocate, 45}.
    return.
  {label, 290}.
    {test, is_eq_exact, {f, 291}, [{y, 3}, {float, 1.0}]}.
    {test, is_lt, {f, 292}, [{y, 4}, {float, -0.25}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 4}, {float, 0.5}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 13}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{float, -2.0}, {x, 0}], {x, 0}}.
    {jump, {f, 293}}.
  {label, 292}.
    {gc_bif, '-', {f, 0}, 0, [{y, 4}, {y, 13}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{float, 2.0}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, 1.0}, {x, 0}], {x, 0}}.
  {label, 293}.
    {deallocate, 45}.
    return.
  {label, 291}.
    {test, is_ge, {f, 295}, [{float, -2.0}, {y, 3}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 296}}.
  {label, 295}.
    {move, {atom, false}, {x, 0}}.
  {label, 296}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 297}, [{x, 1}, {atom, true}]}.
    {test, is_lt, {f, 299}, [{float, 56.0}, {y, 3}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 300}}.
  {label, 299}.
    {move, {atom, false}, {x, 0}}.
  {label, 300}.
    {jump, {f, 298}}.
  {label, 297}.
    {move, {atom, true}, {x, 0}}.
  {label, 298}.
    {test, is_eq, {f, 294}, [{x, 0}, {atom, true}]}.
    {gc_bif, '-', {f, 0}, 0, [{y, 13}, {y, 4}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{float, 1.0}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 15}}.
    {test, is_eq_exact, {f, 301}, [{y, 3}, {float, 1024.0}]}.
    {gc_bif, '*', {f, 0}, 0, [{y, 15}, {float, 2.0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {float, 8.98846567431158e+307}], {x, 0}}.
    {jump, {f, 302}}.
  {label, 301}.
    {gc_bif, '*', {f, 0}, 0, [{y, 15}, {y, 14}], {x, 0}}.
  {label, 302}.
    {move, {x, 0}, {y, 16}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 16}, {float, 1.0}], {x, 0}}.
    {deallocate, 45}.
    return.
  {label, 294}.
    {test, is_lt, {f, 303}, [{y, 3}, {float, 20.0}]}.
    {gc_bif, '-', {f, 0}, 0, [{float, 21.0}, {y, 3}], {x, 0}}.
    {call, 1, {f, 63}}.
    {gc_bif, '-', {f, 0}, 1, [{float, 1072693248.0}, {x, 0}], {x, 0}}.
    {move, {float, 0.0}, {x, 1}}.
    {call, 2, {f, 73}}.
    {move, {x, 0}, {y, 17}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 13}, {y, 4}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 17}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {y, 14}], {x, 0}}.
    {deallocate, 45}.
    return.
  {label, 303}.
    {gc_bif, '-', {f, 0}, 0, [{float, 1023.0}, {y, 3}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {float, 1048576.0}], {x, 0}}.
    {move, {float, 0.0}, {x, 1}}.
    {call, 2, {f, 73}}.
    {move, {x, 0}, {y, 18}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 13}, {y, 18}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 4}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {float, 1.0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {y, 14}], {x, 0}}.
    {deallocate, 45}.
    return.
% ── logarithms ───────────────────────────────────────────────────────────────
% fdlibm's answer for what is not a positive finite number.

{function, logSpecial, 1, 87}.
  {label, 86}.
    {line, [{location, "std@math.erl", 50}]}.
    {func_info, {atom, std@math}, {atom, logSpecial}, 1}.
  {label, 87}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_ne_exact, {f, 305}, [{y, 0}, {y, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 306}}.
  {label, 305}.
    {move, {atom, false}, {x, 0}}.
  {label, 306}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 307}, [{x, 1}, {atom, true}]}.
    {test, is_lt, {f, 309}, [{float, 1.7976931348623157e308}, {y, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 310}}.
  {label, 309}.
    {move, {atom, false}, {x, 0}}.
  {label, 310}.
    {jump, {f, 308}}.
  {label, 307}.
    {move, {atom, true}, {x, 0}}.
  {label, 308}.
    {test, is_eq, {f, 304}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {y, 0}], {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 304}.
    {test, is_lt, {f, 311}, [{y, 0}, {float, 0.0}]}.
    {gc_bif, '-', {f, 0}, 0, [{y, 0}, {y, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '-', {f, 0}, 2, [{y, 0}, {y, 0}], {x, 0}}.
    {test, is_ne, {f, 312}, [{x, 0}, {integer, 0}]}.
    {jump, {f, 313}}.
  {label, 312}.
    {move, {literal, {panic, <<"division by zero: / on f64 at src/math.bp:447:33">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 313}.
    {gc_bif, '/', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 311}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {y, 0}], {x, 0}}.
    {test, is_ne, {f, 314}, [{x, 0}, {integer, 0}]}.
    {jump, {f, 315}}.
  {label, 314}.
    {move, {literal, {panic, <<"division by zero: / on f64 at src/math.bp:448:17">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 315}.
    {gc_bif, '/', {f, 0}, 1, [{float, -1.0}, {x, 0}], {x, 0}}.
    {deallocate, 1}.
    return.
% `x` with its exponent set to 0 (or -1, when the mantissa's high bits pass
% √2's — fdlibm's `(hx + 0x95f64) & 0x100000`), and how much the exponent
% moved: `logScaled(x, 0)` answers the scaled `x`, `logScaled(x, 1)` the `k`.

{function, logScaled, 2, 89}.
  {label, 88}.
    {line, [{location, "std@math.erl", 51}]}.
    {func_info, {atom, std@math}, {atom, logScaled}, 2}.
  {label, 89}.
    {allocate, 12, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {float, 0.0}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {test, is_lt, {f, 316}, [{y, 0}, {float, 2.2250738585072014e-308}]}.
    {move, {float, -54.0}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {float, 1.80143985094819840000e+16}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 317}}.
  {label, 316}.
  {label, 317}.
    {move, {y, 3}, {x, 0}}.
    {call, 1, {f, 69}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, '/', {f, 0}, 0, [{y, 4}, {float, 1048576.0}], {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
    {move, {x, 0}, {y, 5}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 5}, {float, 1048576.0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 4}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 6}, {float, 614244.0}], {x, 0}}.
    {test, is_ge, {f, 318}, [{x, 0}, {float, 1048576.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 319}}.
  {label, 318}.
    {move, {atom, false}, {x, 0}}.
  {label, 319}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq, {f, 320}, [{x, 0}, {atom, true}]}.
    {move, {float, 1.0}, {x, 0}}.
    {jump, {f, 321}}.
  {label, 320}.
    {move, {float, 0.0}, {x, 0}}.
  {label, 321}.
    {move, {x, 0}, {y, 8}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {y, 5}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {float, 1023.0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 8}], {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {test, is_lt, {f, 322}, [{float, 0.5}, {y, 1}]}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 12}.
    return.
  {label, 322}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq, {f, 323}, [{x, 0}, {atom, true}]}.
    {move, {float, 1071644672.0}, {x, 0}}.
    {jump, {f, 324}}.
  {label, 323}.
    {move, {float, 1072693248.0}, {x, 0}}.
  {label, 324}.
    {move, {x, 0}, {y, 9}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 9}, {y, 6}], {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 3}, {x, 0}}.
    {call, 1, {f, 71}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 10}, {x, 0}}.
    {call_last, 2, {f, 73}, 12}.
% The high mantissa bits (`hx & 0xfffff`) the scaled `x` came from.

{function, logMantissaBits, 1, 91}.
  {label, 90}.
    {line, [{location, "std@math.erl", 52}]}.
    {func_info, {atom, std@math}, {atom, logMantissaBits}, 1}.
  {label, 91}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_lt, {f, 325}, [{y, 0}, {float, 2.2250738585072014e-308}]}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {float, 1.80143985094819840000e+16}], {x, 0}}.
    {jump, {f, 326}}.
  {label, 325}.
    {move, {y, 0}, {x, 0}}.
  {label, 326}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 69}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, '/', {f, 0}, 0, [{y, 2}, {float, 1048576.0}], {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {float, 1048576.0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 2}, {x, 0}], {x, 0}}.
    {deallocate, 5}.
    return.

{function, lnBody, 1, 93}.
  {label, 92}.
    {line, [{location, "std@math.erl", 53}]}.
    {func_info, {atom, std@math}, {atom, lnBody}, 1}.
  {label, 93}.
    {allocate, 16, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_ne_exact, {f, 328}, [{y, 0}, {y, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 329}}.
  {label, 328}.
    {move, {atom, false}, {x, 0}}.
  {label, 329}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 330}, [{x, 1}, {atom, true}]}.
    {test, is_ge, {f, 332}, [{float, 0.0}, {y, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 333}}.
  {label, 332}.
    {move, {atom, false}, {x, 0}}.
  {label, 333}.
    {jump, {f, 331}}.
  {label, 330}.
    {move, {atom, true}, {x, 0}}.
  {label, 331}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 334}, [{x, 1}, {atom, true}]}.
    {test, is_lt, {f, 336}, [{float, 1.7976931348623157e308}, {y, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 337}}.
  {label, 336}.
    {move, {atom, false}, {x, 0}}.
  {label, 337}.
    {jump, {f, 335}}.
  {label, 334}.
    {move, {atom, true}, {x, 0}}.
  {label, 335}.
    {test, is_eq, {f, 327}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 87}, 16}.
  {label, 327}.
    {move, {y, 0}, {x, 0}}.
    {move, {float, 1.0}, {x, 1}}.
    {call, 2, {f, 89}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {float, 0.0}, {x, 1}}.
    {call, 2, {f, 89}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {float, 1.0}], {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 91}}.
    {move, {x, 0}, {y, 3}}.
    {move, {float, 6.93147180369123816490e-01}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {float, 1.90821492927058770002e-10}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {test, is_ge, {f, 339}, [{y, 3}, {float, 1048574.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 340}}.
  {label, 339}.
    {move, {atom, false}, {x, 0}}.
  {label, 340}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 341}, [{x, 1}, {atom, true}]}.
    {move, {y, 3}, {x, 0}}.
    {call, 1, {f, 79}}.
    {jump, {f, 342}}.
  {label, 341}.
    {move, {atom, true}, {x, 0}}.
  {label, 342}.
    {test, is_eq, {f, 338}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {x, 0}}.
    {call, 1, {f, 79}}.
    {test, is_eq, {f, 343}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 79}}.
    {test, is_eq, {f, 344}, [{x, 0}, {atom, true}]}.
    {move, {float, 0.0}, {x, 0}}.
    {jump, {f, 345}}.
  {label, 344}.
    {gc_bif, '*', {f, 0}, 0, [{y, 1}, {y, 4}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '*', {f, 0}, 2, [{y, 1}, {y, 5}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
  {label, 345}.
    {deallocate, 16}.
    return.
  {label, 343}.
    {gc_bif, '*', {f, 0}, 0, [{y, 2}, {y, 2}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '*', {f, 0}, 2, [{float, 0.33333333333333333}, {y, 2}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 2, [{float, 0.5}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 79}}.
    {test, is_eq, {f, 346}, [{x, 0}, {atom, true}]}.
    {gc_bif, '-', {f, 0}, 0, [{y, 2}, {y, 6}], {x, 0}}.
    {jump, {f, 347}}.
  {label, 346}.
    {gc_bif, '*', {f, 0}, 0, [{y, 1}, {y, 4}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '*', {f, 0}, 2, [{y, 1}, {y, 5}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 2, [{y, 6}, {x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 2, [{x, 0}, {y, 2}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
  {label, 347}.
    {deallocate, 16}.
    return.
  {label, 338}.
    {gc_bif, '+', {f, 0}, 0, [{float, 2.0}, {y, 2}], {x, 0}}.
    {test, is_ne, {f, 348}, [{x, 0}, {integer, 0}]}.
    {jump, {f, 349}}.
  {label, 348}.
    {move, {literal, {panic, <<"division by zero: / on f64 at src/math.bp:494:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 349}.
    {gc_bif, '/', {f, 0}, 1, [{y, 2}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 7}, {y, 7}], {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 8}, {y, 8}], {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 9}, {float, 1.531383769920937332e-01}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, 2.222219843214978396e-01}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 9}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, 3.999999999940941908e-01}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 9}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 9}, {float, 1.479819860511658591e-01}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, 1.818357216161805012e-01}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 9}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, 2.857142874366239149e-01}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 9}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, 6.666666666666735130e-01}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 8}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 11}, {y, 10}], {x, 0}}.
    {move, {x, 0}, {y, 12}}.
    {test, is_ge, {f, 351}, [{y, 3}, {float, 398458.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 352}}.
  {label, 351}.
    {move, {atom, false}, {x, 0}}.
  {label, 352}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 353}, [{x, 1}, {atom, true}]}.
    {test, is_ge, {f, 355}, [{float, 440401.0}, {y, 3}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 356}}.
  {label, 355}.
    {move, {atom, false}, {x, 0}}.
  {label, 356}.
    {jump, {f, 354}}.
  {label, 353}.
    {move, {atom, false}, {x, 0}}.
  {label, 354}.
    {test, is_eq, {f, 350}, [{x, 0}, {atom, true}]}.
    {gc_bif, '*', {f, 0}, 0, [{float, 0.5}, {y, 2}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {y, 2}], {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 79}}.
    {test, is_eq, {f, 357}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 13}, {y, 12}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 7}, {x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 13}, {x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 2}, {x, 0}], {x, 0}}.
    {jump, {f, 358}}.
  {label, 357}.
    {gc_bif, '*', {f, 0}, 0, [{y, 1}, {y, 4}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '+', {f, 0}, 2, [{y, 13}, {y, 12}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 2, [{y, 7}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {gc_bif, '*', {f, 0}, 3, [{y, 1}, {y, 5}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 3, [{x, 2}, {x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 2, [{y, 13}, {x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 2, [{x, 0}, {y, 2}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
  {label, 358}.
    {deallocate, 16}.
    return.
  {label, 350}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 79}}.
    {test, is_eq, {f, 359}, [{x, 0}, {atom, true}]}.
    {gc_bif, '-', {f, 0}, 0, [{y, 2}, {y, 12}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 7}, {x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 2}, {x, 0}], {x, 0}}.
    {jump, {f, 360}}.
  {label, 359}.
    {gc_bif, '*', {f, 0}, 0, [{y, 1}, {y, 4}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '-', {f, 0}, 2, [{y, 2}, {y, 12}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 2, [{y, 7}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {gc_bif, '*', {f, 0}, 3, [{y, 1}, {y, 5}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 3, [{x, 2}, {x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 2, [{x, 0}, {y, 2}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
  {label, 360}.
    {deallocate, 16}.
    return.
% fdlibm's `k_log1p(f)`.

{function, logOnePlusTail, 1, 95}.
  {label, 94}.
    {line, [{location, "std@math.erl", 54}]}.
    {func_info, {atom, std@math}, {atom, logOnePlusTail}, 1}.
  {label, 95}.
    {allocate, 7, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '+', {f, 0}, 0, [{float, 2.0}, {y, 0}], {x, 0}}.
    {test, is_ne, {f, 361}, [{x, 0}, {integer, 0}]}.
    {jump, {f, 362}}.
  {label, 361}.
    {move, {literal, {panic, <<"division by zero: / on f64 at src/math.bp:523:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 362}.
    {gc_bif, '/', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 1}, {y, 1}], {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 2}, {y, 2}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 3}, {float, 1.531383769920937332e-01}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, 2.222219843214978396e-01}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 3}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, 3.999999999940941908e-01}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 3}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 3}, {float, 1.479819860511658591e-01}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, 1.818357216161805012e-01}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 3}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, 2.857142874366239149e-01}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 3}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, 6.666666666666735130e-01}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 2}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {gc_bif, '*', {f, 0}, 0, [{float, 0.5}, {y, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {y, 0}], {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 5}, {y, 4}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 6}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 1}, {x, 0}], {x, 0}}.
    {deallocate, 7}.
    return.

{function, log2Body, 1, 97}.
  {label, 96}.
    {line, [{location, "std@math.erl", 55}]}.
    {func_info, {atom, std@math}, {atom, log2Body}, 1}.
  {label, 97}.
    {allocate, 10, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_ne_exact, {f, 364}, [{y, 0}, {y, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 365}}.
  {label, 364}.
    {move, {atom, false}, {x, 0}}.
  {label, 365}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 366}, [{x, 1}, {atom, true}]}.
    {test, is_ge, {f, 368}, [{float, 0.0}, {y, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 369}}.
  {label, 368}.
    {move, {atom, false}, {x, 0}}.
  {label, 369}.
    {jump, {f, 367}}.
  {label, 366}.
    {move, {atom, true}, {x, 0}}.
  {label, 367}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 370}, [{x, 1}, {atom, true}]}.
    {test, is_lt, {f, 372}, [{float, 1.7976931348623157e308}, {y, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 373}}.
  {label, 372}.
    {move, {atom, false}, {x, 0}}.
  {label, 373}.
    {jump, {f, 371}}.
  {label, 370}.
    {move, {atom, true}, {x, 0}}.
  {label, 371}.
    {test, is_eq, {f, 363}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 87}, 10}.
  {label, 363}.
    {test, is_eq_exact, {f, 374}, [{y, 0}, {float, 1.0}]}.
    {move, {float, 0.0}, {x, 0}}.
    {deallocate, 10}.
    return.
  {label, 374}.
    {move, {y, 0}, {x, 0}}.
    {move, {float, 1.0}, {x, 1}}.
    {call, 2, {f, 89}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {float, 0.0}, {x, 1}}.
    {call, 2, {f, 89}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {float, 1.0}], {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, '*', {f, 0}, 0, [{float, 0.5}, {y, 2}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {y, 2}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call, 1, {f, 95}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 2}, {y, 3}], {x, 0}}.
    {call, 1, {f, 75}}.
    {move, {x, 0}, {y, 5}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 2}, {y, 5}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {y, 3}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 4}], {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 5}, {float, 1.44269504072144627571e+00}], {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 6}, {y, 5}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {float, 1.67517131648865118353e-10}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '*', {f, 0}, 2, [{y, 6}, {float, 1.44269504072144627571e+00}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {y, 7}], {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 9}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 7}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 8}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 9}], {x, 0}}.
    {deallocate, 10}.
    return.

{function, log10Body, 1, 99}.
  {label, 98}.
    {line, [{location, "std@math.erl", 56}]}.
    {func_info, {atom, std@math}, {atom, log10Body}, 1}.
  {label, 99}.
    {allocate, 15, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_ne_exact, {f, 376}, [{y, 0}, {y, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 377}}.
  {label, 376}.
    {move, {atom, false}, {x, 0}}.
  {label, 377}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 378}, [{x, 1}, {atom, true}]}.
    {test, is_ge, {f, 380}, [{float, 0.0}, {y, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 381}}.
  {label, 380}.
    {move, {atom, false}, {x, 0}}.
  {label, 381}.
    {jump, {f, 379}}.
  {label, 378}.
    {move, {atom, true}, {x, 0}}.
  {label, 379}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 382}, [{x, 1}, {atom, true}]}.
    {test, is_lt, {f, 384}, [{float, 1.7976931348623157e308}, {y, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 385}}.
  {label, 384}.
    {move, {atom, false}, {x, 0}}.
  {label, 385}.
    {jump, {f, 383}}.
  {label, 382}.
    {move, {atom, true}, {x, 0}}.
  {label, 383}.
    {test, is_eq, {f, 375}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 87}, 15}.
  {label, 375}.
    {test, is_eq_exact, {f, 386}, [{y, 0}, {float, 1.0}]}.
    {move, {float, 0.0}, {x, 0}}.
    {deallocate, 15}.
    return.
  {label, 386}.
    {move, {float, 0.0}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {test, is_lt, {f, 387}, [{y, 0}, {float, 2.2250738585072014e-308}]}.
    {move, {float, -54.0}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {float, 1.80143985094819840000e+16}], {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 388}}.
  {label, 387}.
  {label, 388}.
    {move, {y, 2}, {x, 0}}.
    {call, 1, {f, 69}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, '/', {f, 0}, 0, [{y, 3}, {float, 1048576.0}], {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {y, 4}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {float, 1023.0}], {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_lt, {f, 389}, [{y, 1}, {float, 0.0}]}.
    {move, {float, 1.0}, {x, 0}}.
    {jump, {f, 390}}.
  {label, 389}.
    {move, {float, 0.0}, {x, 0}}.
  {label, 390}.
    {move, {x, 0}, {y, 5}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 4}, {float, 1048576.0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 3}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '-', {f, 0}, 2, [{float, 1023.0}, {y, 5}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 2, [{x, 0}, {float, 1048576.0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 2}, {x, 0}}.
    {call, 1, {f, 71}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 6}, {x, 0}}.
    {call, 2, {f, 73}}.
    {move, {x, 0}, {y, 7}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {y, 5}], {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 8}, {float, 3.69423907715893078616e-13}], {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 7}, {x, 0}}.
    {call, 1, {f, 93}}.
    {gc_bif, '*', {f, 0}, 1, [{float, 4.34294481903251816668e-01}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 9}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 8}, {float, 3.01029995663611771306e-01}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 10}, {x, 0}], {x, 0}}.
    {deallocate, 15}.
    return.
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

{function, sumError, 3, 101}.
  {label, 100}.
    {line, [{location, "std@math.erl", 57}]}.
    {func_info, {atom, std@math}, {atom, sumError}, 3}.
  {label, 101}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 2}, {y, 0}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 2}, {y, 3}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '-', {f, 0}, 2, [{y, 1}, {y, 3}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {deallocate, 4}.
    return.
% a·b − p exactly, for p the rounded product (Dekker's two-product).

{function, productError, 3, 103}.
  {label, 102}.
    {line, [{location, "std@math.erl", 58}]}.
    {func_info, {atom, std@math}, {atom, productError}, 3}.
  {label, 103}.
    {allocate, 9, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {gc_bif, '*', {f, 0}, 0, [{float, 134217729.0}, {y, 0}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 3}, {y, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 3}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 0}, {y, 4}], {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {gc_bif, '*', {f, 0}, 0, [{float, 134217729.0}, {y, 1}], {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 6}, {y, 1}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 6}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 7}], {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 4}, {y, 7}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {y, 2}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '*', {f, 0}, 2, [{y, 4}, {y, 8}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '*', {f, 0}, 2, [{y, 5}, {y, 7}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '*', {f, 0}, 2, [{y, 5}, {y, 8}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {deallocate, 9}.
    return.
% The power of two of s's leading bit, for a normal s ≠ 0 (Rump, Zimmermann,
% Boldo and Melquiond's `ufp`: φ = 2^52 + 1, ψ = 1 − 2^-53).

{function, unitInFirstPlace, 1, 105}.
  {label, 104}.
    {line, [{location, "std@math.erl", 59}]}.
    {func_info, {atom, std@math}, {atom, unitInFirstPlace}, 1}.
  {label, 105}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '*', {f, 0}, 0, [{float, 4503599627370497.0}, {y, 0}], {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, '*', {f, 0}, 0, [{float, 0.9999999999999999}, {y, 1}], {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 2}], {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, abs, 1}, 3}.
% a + b rounded to odd: the exact sum when it is a double, else the one of
% its two neighbours whose last significand bit is 1.

{function, sumRoundedToOdd, 2, 107}.
  {label, 106}.
    {line, [{location, "std@math.erl", 60}]}.
    {func_info, {atom, std@math}, {atom, sumRoundedToOdd}, 2}.
  {label, 107}.
    {allocate, 14, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {y, 1}], {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call, 3, {f, 101}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {call, 1, {f, 79}}.
    {test, is_eq, {f, 391}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 14}.
    return.
  {label, 391}.
    {move, {y, 2}, {x, 0}}.
    {call, 1, {f, 105}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 4}, {float, 2.220446049250313e-16}], {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, abs, 1}}.
    {move, {x, 0}, {y, 6}}.
    {test, is_ne, {f, 392}, [{y, 5}, {integer, 0}]}.
    {jump, {f, 393}}.
  {label, 392}.
    {move, {literal, {panic, <<"division by zero: / on f64 at src/math.bp:629:17">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 393}.
    {gc_bif, '/', {f, 0}, 0, [{y, 6}, {y, 5}], {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 7}, {float, 0.5}], {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
    {gc_bif, '*', {f, 0}, 1, [{float, 2.0}, {x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 7}, {x, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 394}, [{x, 0}, {float, 1.0}]}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 14}.
    return.
  {label, 394}.
    {test, is_lt, {f, 395}, [{float, 0.0}, {y, 3}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 396}}.
  {label, 395}.
    {move, {atom, false}, {x, 0}}.
  {label, 396}.
    {move, {x, 0}, {x, 1}}.
    {test, is_lt, {f, 397}, [{float, 0.0}, {y, 2}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 398}}.
  {label, 397}.
    {move, {atom, false}, {x, 0}}.
  {label, 398}.
    {test, is_eq_exact, {f, 399}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 400}}.
  {label, 399}.
    {move, {atom, false}, {x, 0}}.
  {label, 400}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq, {f, 401}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 6}, {y, 5}], {x, 0}}.
    {jump, {f, 402}}.
  {label, 401}.
    {test, is_eq_exact, {f, 403}, [{y, 6}, {y, 4}]}.
    {gc_bif, '*', {f, 0}, 0, [{y, 5}, {float, 0.5}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 6}, {x, 0}], {x, 0}}.
    {jump, {f, 404}}.
  {label, 403}.
    {gc_bif, '-', {f, 0}, 0, [{y, 6}, {y, 5}], {x, 0}}.
  {label, 404}.
  {label, 402}.
    {move, {x, 0}, {y, 9}}.
    {test, is_lt, {f, 405}, [{float, 0.0}, {y, 2}]}.
    {move, {y, 9}, {x, 0}}.
    {jump, {f, 406}}.
  {label, 405}.
    {gc_bif, '*', {f, 0}, 0, [{float, -1.0}, {y, 9}], {x, 0}}.
  {label, 406}.
    {deallocate, 14}.
    return.
% fma(a, b, c): a·b + c rounded once (Boldo and Melquiond's emulation — the
% exact product, a two-sum, one sum rounded to odd, one rounding to nearest).

{function, fusedMultiplyAdd, 3, 109}.
  {label, 108}.
    {line, [{location, "std@math.erl", 61}]}.
    {func_info, {atom, std@math}, {atom, fusedMultiplyAdd}, 3}.
  {label, 109}.
    {allocate, 9, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {y, 1}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call, 3, {f, 103}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {y, 3}], {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 5}, {x, 2}}.
    {move, {y, 3}, {x, 1}}.
    {call, 3, {f, 101}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call, 2, {f, 107}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 5}, {x, 0}], {x, 0}}.
    {deallocate, 9}.
    return.
% 0 when `y` is not a whole number, 1 when it is odd, 2 when it is even
% (glibc's `checkint`).

{function, wholeKind, 1, 111}.
  {label, 110}.
    {line, [{location, "std@math.erl", 62}]}.
    {func_info, {atom, std@math}, {atom, wholeKind}, 1}.
  {label, 111}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
    {test, is_ne_exact, {f, 407}, [{x, 0}, {y, 0}]}.
    {move, {float, 0.0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 407}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, abs, 1}}.
    {test, is_ge, {f, 408}, [{x, 0}, {float, 9007199254740992.0}]}.
    {move, {float, 2.0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 408}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {float, 0.5}], {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
    {test, is_eq_exact, {f, 409}, [{x, 0}, {y, 1}]}.
    {move, {float, 2.0}, {x, 0}}.
    {jump, {f, 410}}.
  {label, 409}.
    {move, {float, 1.0}, {x, 0}}.
  {label, 410}.
    {deallocate, 2}.
    return.

{function, powBody, 2, 113}.
  {label, 112}.
    {line, [{location, "std@math.erl", 63}]}.
    {func_info, {atom, std@math}, {atom, powBody}, 2}.
  {label, 113}.
    {allocate, 57, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}, {y, 20}, {y, 21}, {y, 22}, {y, 23}, {y, 24}, {y, 25}, {y, 26}, {y, 27}, {y, 28}, {y, 29}, {y, 30}, {y, 31}, {y, 32}, {y, 33}, {y, 34}, {y, 35}, {y, 36}, {y, 37}, {y, 38}, {y, 39}, {y, 40}, {y, 41}, {y, 42}, {y, 43}, {y, 44}, {y, 45}, {y, 46}, {y, 47}, {y, 48}, {y, 49}, {y, 50}, {y, 51}, {y, 52}, {y, 53}, {y, 54}, {y, 55}, {y, 56}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ne_exact, {f, 411}, [{y, 1}, {y, 1}]}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 57}.
    return.
  {label, 411}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, abs, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, abs, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {float, 1.7976931348623157e308}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {test, is_lt, {f, 413}, [{y, 4}, {y, 3}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 414}}.
  {label, 413}.
    {move, {atom, false}, {x, 0}}.
  {label, 414}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 415}, [{x, 1}, {atom, true}]}.
    {test, is_eq_exact, {f, 417}, [{y, 2}, {float, 1.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 418}}.
  {label, 417}.
    {move, {atom, false}, {x, 0}}.
  {label, 418}.
    {jump, {f, 416}}.
  {label, 415}.
    {move, {atom, false}, {x, 0}}.
  {label, 416}.
    {test, is_eq, {f, 412}, [{x, 0}, {atom, true}]}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 1}], {x, 0}}.
    {deallocate, 57}.
    return.
  {label, 412}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 79}}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 420}, [{x, 1}, {atom, true}]}.
    {test, is_eq_exact, {f, 422}, [{y, 0}, {float, 1.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 423}}.
  {label, 422}.
    {move, {atom, false}, {x, 0}}.
  {label, 423}.
    {jump, {f, 421}}.
  {label, 420}.
    {move, {atom, true}, {x, 0}}.
  {label, 421}.
    {test, is_eq, {f, 419}, [{x, 0}, {atom, true}]}.
    {move, {float, 1.0}, {x, 0}}.
    {deallocate, 57}.
    return.
  {label, 419}.
    {test, is_ne_exact, {f, 424}, [{y, 0}, {y, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {y, 1}], {x, 0}}.
    {deallocate, 57}.
    return.
  {label, 424}.
    {test, is_lt, {f, 425}, [{y, 4}, {y, 3}]}.
    {test, is_lt, {f, 427}, [{y, 2}, {float, 1.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 428}}.
  {label, 427}.
    {move, {atom, false}, {x, 0}}.
  {label, 428}.
    {move, {x, 0}, {x, 1}}.
    {test, is_lt, {f, 429}, [{float, 0.0}, {y, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 430}}.
  {label, 429}.
    {move, {atom, false}, {x, 0}}.
  {label, 430}.
    {test, is_eq_exact, {f, 426}, [{x, 1}, {x, 0}]}.
    {move, {float, 0.0}, {x, 0}}.
    {jump, {f, 431}}.
  {label, 426}.
    {move, {y, 3}, {x, 0}}.
  {label, 431}.
    {deallocate, 57}.
    return.
  {label, 425}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 111}}.
    {test, is_eq_exact, {f, 432}, [{x, 0}, {float, 1.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 433}}.
  {label, 432}.
    {move, {atom, false}, {x, 0}}.
  {label, 433}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 77}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 2}, {x, 0}}.
    {call, 1, {f, 79}}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 435}, [{x, 1}, {atom, true}]}.
    {test, is_lt, {f, 437}, [{y, 4}, {y, 2}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 438}}.
  {label, 437}.
    {move, {atom, false}, {x, 0}}.
  {label, 438}.
    {jump, {f, 436}}.
  {label, 435}.
    {move, {atom, true}, {x, 0}}.
  {label, 436}.
    {test, is_eq, {f, 434}, [{x, 0}, {atom, true}]}.
    {test, is_eq, {f, 440}, [{y, 6}, {atom, true}]}.
    {move, {y, 5}, {x, 0}}.
    {jump, {f, 441}}.
  {label, 440}.
    {move, {atom, false}, {x, 0}}.
  {label, 441}.
    {test, is_eq, {f, 439}, [{x, 0}, {atom, true}]}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {y, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{float, -1.0}, {x, 0}], {x, 0}}.
    {jump, {f, 442}}.
  {label, 439}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {y, 0}], {x, 0}}.
  {label, 442}.
    {move, {x, 0}, {y, 7}}.
    {test, is_lt, {f, 443}, [{y, 1}, {float, 0.0}]}.
    {test, is_ne, {f, 445}, [{y, 7}, {integer, 0}]}.
    {jump, {f, 446}}.
  {label, 445}.
    {move, {literal, {panic, <<"division by zero: / on f64 at src/math.bp:674:33">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 446}.
    {gc_bif, '/', {f, 0}, 0, [{float, 1.0}, {y, 7}], {x, 0}}.
    {jump, {f, 444}}.
  {label, 443}.
    {move, {y, 7}, {x, 0}}.
  {label, 444}.
    {deallocate, 57}.
    return.
  {label, 434}.
    {test, is_eq, {f, 448}, [{y, 6}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 111}}.
    {call, 1, {f, 79}}.
    {jump, {f, 449}}.
  {label, 448}.
    {move, {atom, false}, {x, 0}}.
  {label, 449}.
    {test, is_eq, {f, 447}, [{x, 0}, {atom, true}]}.
    {gc_bif, '-', {f, 0}, 0, [{y, 0}, {y, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '-', {f, 0}, 2, [{y, 0}, {y, 0}], {x, 0}}.
    {test, is_ne, {f, 450}, [{x, 0}, {integer, 0}]}.
    {jump, {f, 451}}.
  {label, 450}.
    {move, {literal, {panic, <<"division by zero: / on f64 at src/math.bp:676:52">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 451}.
    {gc_bif, '/', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {deallocate, 57}.
    return.
  {label, 447}.
    {test, is_lt, {f, 453}, [{y, 3}, {float, 2.710505431213761e-20}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 454}}.
  {label, 453}.
    {move, {atom, false}, {x, 0}}.
  {label, 454}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 455}, [{x, 1}, {atom, true}]}.
    {test, is_ge, {f, 457}, [{y, 3}, {float, 9.223372036854776e18}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 458}}.
  {label, 457}.
    {move, {atom, false}, {x, 0}}.
  {label, 458}.
    {jump, {f, 456}}.
  {label, 455}.
    {move, {atom, true}, {x, 0}}.
  {label, 456}.
    {test, is_eq, {f, 452}, [{x, 0}, {atom, true}]}.
    {test, is_eq_exact, {f, 459}, [{y, 2}, {float, 1.0}]}.
    {move, {float, 1.0}, {x, 0}}.
    {deallocate, 57}.
    return.
  {label, 459}.
    {test, is_lt, {f, 460}, [{y, 3}, {float, 2.710505431213761e-20}]}.
    {test, is_lt, {f, 461}, [{float, 1.0}, {y, 2}]}.
    {gc_bif, '+', {f, 0}, 0, [{float, 1.0}, {y, 1}], {x, 0}}.
    {jump, {f, 462}}.
  {label, 461}.
    {gc_bif, '-', {f, 0}, 0, [{float, 1.0}, {y, 1}], {x, 0}}.
  {label, 462}.
    {deallocate, 57}.
    return.
  {label, 460}.
    {test, is_lt, {f, 464}, [{float, 1.0}, {y, 2}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 465}}.
  {label, 464}.
    {move, {atom, false}, {x, 0}}.
  {label, 465}.
    {move, {x, 0}, {x, 1}}.
    {test, is_lt, {f, 466}, [{float, 0.0}, {y, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 467}}.
  {label, 466}.
    {move, {atom, false}, {x, 0}}.
  {label, 467}.
    {test, is_eq_exact, {f, 463}, [{x, 1}, {x, 0}]}.
    {move, {float, 1.0}, {x, 0}}.
    {move, {float, 1.0e300}, {x, 1}}.
    {call, 2, {f, 61}}.
    {jump, {f, 468}}.
  {label, 463}.
    {move, {float, 1.0}, {x, 0}}.
    {move, {float, 1.0e-300}, {x, 1}}.
    {call, 2, {f, 61}}.
  {label, 468}.
    {deallocate, 57}.
    return.
  {label, 452}.
    {test, is_lt, {f, 469}, [{y, 2}, {float, 2.2250738585072014e-308}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 470}}.
  {label, 469}.
    {move, {atom, false}, {x, 0}}.
  {label, 470}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq, {f, 471}, [{x, 0}, {atom, true}]}.
    {gc_bif, '*', {f, 0}, 0, [{y, 2}, {float, 4503599627370496.0}], {x, 0}}.
    {jump, {f, 472}}.
  {label, 471}.
    {move, {y, 2}, {x, 0}}.
  {label, 472}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call, 1, {f, 65}}.
    {move, {x, 0}, {y, 10}}.
    {gc_bif, '-', {f, 0}, 0, [{float, 0.0}, {y, 10}], {x, 0}}.
    {call, 1, {f, 63}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 9}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {test, is_ge, {f, 473}, [{y, 11}, {float, 1.4114580154418945}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 474}}.
  {label, 473}.
    {move, {atom, false}, {x, 0}}.
  {label, 474}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {x, 0}}.
    {test, is_eq, {f, 475}, [{x, 0}, {atom, true}]}.
    {gc_bif, '*', {f, 0}, 0, [{y, 11}, {float, 0.5}], {x, 0}}.
    {jump, {f, 476}}.
  {label, 475}.
    {move, {y, 11}, {x, 0}}.
  {label, 476}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 12}, {x, 0}}.
    {test, is_eq, {f, 477}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 10}, {float, 1.0}], {x, 0}}.
    {jump, {f, 478}}.
  {label, 477}.
    {move, {y, 10}, {x, 0}}.
  {label, 478}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq, {f, 479}, [{x, 0}, {atom, true}]}.
    {gc_bif, '-', {f, 0}, 0, [{y, 14}, {float, 52.0}], {x, 0}}.
    {jump, {f, 480}}.
  {label, 479}.
    {move, {y, 14}, {x, 0}}.
  {label, 480}.
    {move, {x, 0}, {y, 15}}.
    {test, is_lt, {f, 481}, [{y, 13}, {float, 1.0}]}.
    {gc_bif, '-', {f, 0}, 0, [{y, 13}, {float, 0.7057290077209473}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {float, 256.0}], {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
    {jump, {f, 482}}.
  {label, 481}.
    {gc_bif, '-', {f, 0}, 0, [{y, 13}, {float, 1.0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {float, 128.0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {float, 75.3333740234375}], {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
  {label, 482}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 16}, {x, 0}}.
    {call, 1, {f, 117}}.
    {move, {x, 0}, {y, 17}}.
    {move, {y, 16}, {x, 0}}.
    {call, 1, {f, 119}}.
    {move, {x, 0}, {y, 18}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 13}, {y, 17}], {x, 0}}.
    {move, {x, 0}, {y, 19}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 19}, {float, 1.0}], {x, 0}}.
    {move, {x, 0}, {y, 20}}.
    {move, {y, 13}, {x, 0}}.
    {move, {y, 19}, {x, 2}}.
    {move, {y, 17}, {x, 1}}.
    {call, 3, {f, 103}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 20}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 21}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 15}, {float, 0.6931471805598903}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 18}], {x, 0}}.
    {move, {x, 0}, {y, 22}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 22}, {y, 21}], {x, 0}}.
    {move, {x, 0}, {y, 23}}.
    {move, {y, 16}, {x, 0}}.
    {call, 1, {f, 121}}.
    {move, {float, 5.497923018708371e-14}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 15}, {x, 0}}.
    {call, 3, {f, 109}}.
    {move, {x, 0}, {y, 24}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 22}, {y, 23}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 21}], {x, 0}}.
    {move, {x, 0}, {y, 25}}.
    {gc_bif, '*', {f, 0}, 0, [{float, -0.5}, {y, 21}], {x, 0}}.
    {move, {x, 0}, {y, 26}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 21}, {y, 26}], {x, 0}}.
    {move, {x, 0}, {y, 27}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 21}, {y, 27}], {x, 0}}.
    {move, {x, 0}, {y, 28}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 23}, {y, 27}], {x, 0}}.
    {move, {x, 0}, {y, 29}}.
    {move, {y, 26}, {x, 0}}.
    {move, {y, 27}, {x, 2}}.
    {move, {y, 21}, {x, 1}}.
    {call, 3, {f, 103}}.
    {move, {x, 0}, {y, 30}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 23}, {y, 29}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 27}], {x, 0}}.
    {move, {x, 0}, {y, 31}}.
    {move, {y, 21}, {x, 0}}.
    {move, {float, -1.142909628459501}, {x, 2}}.
    {move, {float, 1.0000415263675542}, {x, 1}}.
    {call, 3, {f, 109}}.
    {move, {x, 0}, {y, 32}}.
    {move, {y, 21}, {x, 0}}.
    {move, {float, 0.7999999995323976}, {x, 2}}.
    {move, {float, -0.6666666663487739}, {x, 1}}.
    {call, 3, {f, 109}}.
    {move, {y, 32}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 27}, {x, 0}}.
    {call, 3, {f, 109}}.
    {move, {x, 0}, {y, 33}}.
    {move, {y, 21}, {x, 0}}.
    {move, {float, -0.6666666666666679}, {x, 2}}.
    {move, {float, 0.5000000000000007}, {x, 1}}.
    {call, 3, {f, 109}}.
    {move, {y, 33}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 27}, {x, 0}}.
    {call, 3, {f, 109}}.
    {move, {x, 0}, {y, 34}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 24}, {y, 25}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 30}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 31}], {x, 0}}.
    {move, {y, 34}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 28}, {x, 0}}.
    {call, 3, {f, 109}}.
    {move, {x, 0}, {y, 35}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 29}, {y, 35}], {x, 0}}.
    {move, {x, 0}, {y, 36}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 29}, {y, 36}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 35}], {x, 0}}.
    {move, {x, 0}, {y, 37}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 1}, {y, 36}], {x, 0}}.
    {move, {x, 0}, {y, 38}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 38}, {x, 2}}.
    {move, {y, 36}, {x, 1}}.
    {call, 3, {f, 103}}.
    {move, {y, 37}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call, 3, {f, 109}}.
    {move, {x, 0}, {y, 39}}.
    {test, is_eq, {f, 483}, [{y, 6}, {atom, true}]}.
    {move, {y, 5}, {x, 0}}.
    {jump, {f, 484}}.
  {label, 483}.
    {move, {atom, false}, {x, 0}}.
  {label, 484}.
    {move, {y, 39}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 38}, {x, 0}}.
    {call_last, 3, {f, 115}, 57}.
% glibc's `exp_inline`: ±e^(x + xtail), the sign minus when `neg`.

{function, powExp, 3, 115}.
  {label, 114}.
    {line, [{location, "std@math.erl", 64}]}.
    {func_info, {atom, std@math}, {atom, powExp}, 3}.
  {label, 115}.
    {allocate, 49, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}, {y, 20}, {y, 21}, {y, 22}, {y, 23}, {y, 24}, {y, 25}, {y, 26}, {y, 27}, {y, 28}, {y, 29}, {y, 30}, {y, 31}, {y, 32}, {y, 33}, {y, 34}, {y, 35}, {y, 36}, {y, 37}, {y, 38}, {y, 39}, {y, 40}, {y, 41}, {y, 42}, {y, 43}, {y, 44}, {y, 45}, {y, 46}, {y, 47}, {y, 48}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq, {f, 485}, [{x, 0}, {atom, true}]}.
    {move, {float, -1.0}, {x, 0}}.
    {jump, {f, 486}}.
  {label, 485}.
    {move, {float, 1.0}, {x, 0}}.
  {label, 486}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, abs, 1}}.
    {move, {x, 0}, {y, 4}}.
    {test, is_lt, {f, 487}, [{y, 4}, {float, 5.551115123125783e-17}]}.
    {gc_bif, '+', {f, 0}, 0, [{float, 1.0}, {y, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 3}, {x, 0}], {x, 0}}.
    {deallocate, 49}.
    return.
  {label, 487}.
    {test, is_ge, {f, 488}, [{y, 4}, {float, 1024.0}]}.
    {test, is_lt, {f, 489}, [{y, 0}, {float, 0.0}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {float, 1.0e-300}, {x, 1}}.
    {call, 2, {f, 61}}.
    {jump, {f, 490}}.
  {label, 489}.
    {move, {y, 3}, {x, 0}}.
    {move, {float, 1.0e300}, {x, 1}}.
    {call, 2, {f, 61}}.
  {label, 490}.
    {deallocate, 49}.
    return.
  {label, 488}.
    {move, {float, 184.6649652337873}, {x, 0}}.
    {move, {float, 6755399441055744.0}, {x, 2}}.
    {move, {y, 0}, {x, 1}}.
    {call, 3, {f, 109}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {float, 6755399441055744.0}], {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 0}, {x, 2}}.
    {move, {float, -0.005415212348111709}, {x, 1}}.
    {call, 3, {f, 109}}.
    {move, {float, -1.2864023111638346e-14}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 5}, {x, 0}}.
    {call, 3, {f, 109}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 1}], {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {gc_bif, '/', {f, 0}, 0, [{y, 5}, {float, 128.0}], {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
    {gc_bif, '*', {f, 0}, 1, [{float, 128.0}, {x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 5}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 6}, {y, 6}], {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 8}, {y, 8}], {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 6}, {x, 0}}.
    {move, {float, 0.0416666808410674}, {x, 2}}.
    {move, {float, 0.008333335853059549}, {x, 1}}.
    {call, 3, {f, 109}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 6}, {x, 0}}.
    {move, {float, 0.49999999999996786}, {x, 2}}.
    {move, {float, 0.16666666666665886}, {x, 1}}.
    {call, 3, {f, 109}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 7}, {x, 0}}.
    {call, 1, {f, 125}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 6}], {x, 0}}.
    {move, {y, 11}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 8}, {x, 0}}.
    {call, 3, {f, 109}}.
    {move, {y, 10}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 9}, {x, 0}}.
    {call, 3, {f, 109}}.
    {move, {x, 0}, {y, 12}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 5}, {y, 7}], {x, 0}}.
    {gc_bif, '/', {f, 0}, 1, [{x, 0}, {float, 128.0}], {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {test, is_lt, {f, 491}, [{y, 4}, {float, 512.0}]}.
    {move, {y, 7}, {x, 0}}.
    {call, 1, {f, 123}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 3}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 13}, {x, 0}}.
    {call, 1, {f, 63}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 14}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 15}}.
    {move, {y, 15}, {x, 0}}.
    {move, {y, 15}, {x, 2}}.
    {move, {y, 12}, {x, 1}}.
    {call_last, 3, {f, 109}, 49}.
  {label, 491}.
    {test, is_lt, {f, 492}, [{float, 0.0}, {y, 5}]}.
    {move, {y, 7}, {x, 0}}.
    {call, 1, {f, 123}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 3}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 16}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 13}, {float, 1009.0}], {x, 0}}.
    {call, 1, {f, 63}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 16}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 17}}.
    {move, {y, 17}, {x, 0}}.
    {move, {y, 17}, {x, 2}}.
    {move, {y, 12}, {x, 1}}.
    {call, 3, {f, 109}}.
    {gc_bif, '*', {f, 0}, 1, [{float, 5.486124068793689e303}, {x, 0}], {x, 0}}.
    {deallocate, 49}.
    return.
  {label, 492}.
    {move, {y, 7}, {x, 0}}.
    {call, 1, {f, 123}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 3}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 18}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 13}, {float, 1022.0}], {x, 0}}.
    {call, 1, {f, 63}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 18}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 19}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 19}, {y, 12}], {x, 0}}.
    {move, {x, 0}, {y, 20}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 19}, {y, 20}], {x, 0}}.
    {move, {x, 0}, {y, 21}}.
    {move, {y, 21}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, abs, 1}}.
    {test, is_ge, {f, 493}, [{x, 0}, {float, 1.0}]}.
    {gc_bif, '*', {f, 0}, 0, [{float, 2.2250738585072014e-308}, {y, 21}], {x, 0}}.
    {deallocate, 49}.
    return.
  {label, 493}.
    {test, is_lt, {f, 494}, [{y, 21}, {float, 0.0}]}.
    {move, {float, -1.0}, {x, 0}}.
    {jump, {f, 495}}.
  {label, 494}.
    {move, {float, 1.0}, {x, 0}}.
  {label, 495}.
    {move, {x, 0}, {y, 22}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 19}, {y, 21}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 20}], {x, 0}}.
    {move, {x, 0}, {y, 23}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 22}, {y, 21}], {x, 0}}.
    {move, {x, 0}, {y, 24}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 22}, {y, 24}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 21}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 23}], {x, 0}}.
    {move, {x, 0}, {y, 25}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 24}, {y, 25}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {y, 22}], {x, 0}}.
    {move, {x, 0}, {y, 26}}.
    {test, is_lt, {f, 497}, [{float, 0.0}, {y, 26}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 498}}.
  {label, 497}.
    {move, {atom, false}, {x, 0}}.
  {label, 498}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 499}, [{x, 1}, {atom, true}]}.
    {test, is_lt, {f, 501}, [{y, 26}, {float, 0.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 502}}.
  {label, 501}.
    {move, {atom, false}, {x, 0}}.
  {label, 502}.
    {jump, {f, 500}}.
  {label, 499}.
    {move, {atom, true}, {x, 0}}.
  {label, 500}.
    {test, is_eq, {f, 496}, [{x, 0}, {atom, true}]}.
    {move, {y, 26}, {x, 0}}.
    {jump, {f, 503}}.
  {label, 496}.
    {gc_bif, '*', {f, 0}, 0, [{y, 3}, {float, 0.0}], {x, 0}}.
  {label, 503}.
    {move, {x, 0}, {y, 27}}.
    {gc_bif, '*', {f, 0}, 0, [{float, 2.2250738585072014e-308}, {y, 27}], {x, 0}}.
    {deallocate, 49}.
    return.
% `__pow_log_data.tab[i].invc`: 1/c for the i-th of the 128 subintervals of
% [0x1.69555p-1, 0x1.69555p0) — a number of few bits, so z/c − 1 is exact.

{function, powInvc, 1, 117}.
  {label, 116}.
    {line, [{location, "std@math.erl", 65}]}.
    {func_info, {atom, std@math}, {atom, powInvc}, 1}.
  {label, 117}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_lt, {f, 504}, [{y, 0}, {float, 64.0}]}.
    {test, is_lt, {f, 506}, [{y, 0}, {float, 32.0}]}.
    {test, is_lt, {f, 508}, [{y, 0}, {float, 16.0}]}.
    {test, is_lt, {f, 510}, [{y, 0}, {float, 8.0}]}.
    {test, is_lt, {f, 512}, [{y, 0}, {float, 4.0}]}.
    {test, is_lt, {f, 514}, [{y, 0}, {float, 2.0}]}.
    {test, is_lt, {f, 516}, [{y, 0}, {float, 1.0}]}.
    {move, {float, 1.4140625}, {x, 0}}.
    {jump, {f, 517}}.
  {label, 516}.
    {move, {float, 1.40625}, {x, 0}}.
  {label, 517}.
    {jump, {f, 515}}.
  {label, 514}.
    {test, is_lt, {f, 518}, [{y, 0}, {float, 3.0}]}.
    {move, {float, 1.3984375}, {x, 0}}.
    {jump, {f, 519}}.
  {label, 518}.
    {move, {float, 1.390625}, {x, 0}}.
  {label, 519}.
  {label, 515}.
    {jump, {f, 513}}.
  {label, 512}.
    {test, is_lt, {f, 520}, [{y, 0}, {float, 6.0}]}.
    {test, is_lt, {f, 522}, [{y, 0}, {float, 5.0}]}.
    {move, {float, 1.3828125}, {x, 0}}.
    {jump, {f, 523}}.
  {label, 522}.
    {move, {float, 1.375}, {x, 0}}.
  {label, 523}.
    {jump, {f, 521}}.
  {label, 520}.
    {test, is_lt, {f, 524}, [{y, 0}, {float, 7.0}]}.
    {move, {float, 1.3671875}, {x, 0}}.
    {jump, {f, 525}}.
  {label, 524}.
    {move, {float, 1.359375}, {x, 0}}.
  {label, 525}.
  {label, 521}.
  {label, 513}.
    {jump, {f, 511}}.
  {label, 510}.
    {test, is_lt, {f, 526}, [{y, 0}, {float, 12.0}]}.
    {test, is_lt, {f, 528}, [{y, 0}, {float, 10.0}]}.
    {test, is_lt, {f, 530}, [{y, 0}, {float, 9.0}]}.
    {move, {float, 1.3515625}, {x, 0}}.
    {jump, {f, 531}}.
  {label, 530}.
    {move, {float, 1.34375}, {x, 0}}.
  {label, 531}.
    {jump, {f, 529}}.
  {label, 528}.
    {test, is_lt, {f, 532}, [{y, 0}, {float, 11.0}]}.
    {move, {float, 1.3359375}, {x, 0}}.
    {jump, {f, 533}}.
  {label, 532}.
    {move, {float, 1.3359375}, {x, 0}}.
  {label, 533}.
  {label, 529}.
    {jump, {f, 527}}.
  {label, 526}.
    {test, is_lt, {f, 534}, [{y, 0}, {float, 14.0}]}.
    {test, is_lt, {f, 536}, [{y, 0}, {float, 13.0}]}.
    {move, {float, 1.328125}, {x, 0}}.
    {jump, {f, 537}}.
  {label, 536}.
    {move, {float, 1.3203125}, {x, 0}}.
  {label, 537}.
    {jump, {f, 535}}.
  {label, 534}.
    {test, is_lt, {f, 538}, [{y, 0}, {float, 15.0}]}.
    {move, {float, 1.3125}, {x, 0}}.
    {jump, {f, 539}}.
  {label, 538}.
    {move, {float, 1.3046875}, {x, 0}}.
  {label, 539}.
  {label, 535}.
  {label, 527}.
  {label, 511}.
    {jump, {f, 509}}.
  {label, 508}.
    {test, is_lt, {f, 540}, [{y, 0}, {float, 24.0}]}.
    {test, is_lt, {f, 542}, [{y, 0}, {float, 20.0}]}.
    {test, is_lt, {f, 544}, [{y, 0}, {float, 18.0}]}.
    {test, is_lt, {f, 546}, [{y, 0}, {float, 17.0}]}.
    {move, {float, 1.296875}, {x, 0}}.
    {jump, {f, 547}}.
  {label, 546}.
    {move, {float, 1.2890625}, {x, 0}}.
  {label, 547}.
    {jump, {f, 545}}.
  {label, 544}.
    {test, is_lt, {f, 548}, [{y, 0}, {float, 19.0}]}.
    {move, {float, 1.2890625}, {x, 0}}.
    {jump, {f, 549}}.
  {label, 548}.
    {move, {float, 1.28125}, {x, 0}}.
  {label, 549}.
  {label, 545}.
    {jump, {f, 543}}.
  {label, 542}.
    {test, is_lt, {f, 550}, [{y, 0}, {float, 22.0}]}.
    {test, is_lt, {f, 552}, [{y, 0}, {float, 21.0}]}.
    {move, {float, 1.2734375}, {x, 0}}.
    {jump, {f, 553}}.
  {label, 552}.
    {move, {float, 1.265625}, {x, 0}}.
  {label, 553}.
    {jump, {f, 551}}.
  {label, 550}.
    {test, is_lt, {f, 554}, [{y, 0}, {float, 23.0}]}.
    {move, {float, 1.2578125}, {x, 0}}.
    {jump, {f, 555}}.
  {label, 554}.
    {move, {float, 1.25}, {x, 0}}.
  {label, 555}.
  {label, 551}.
  {label, 543}.
    {jump, {f, 541}}.
  {label, 540}.
    {test, is_lt, {f, 556}, [{y, 0}, {float, 28.0}]}.
    {test, is_lt, {f, 558}, [{y, 0}, {float, 26.0}]}.
    {test, is_lt, {f, 560}, [{y, 0}, {float, 25.0}]}.
    {move, {float, 1.25}, {x, 0}}.
    {jump, {f, 561}}.
  {label, 560}.
    {move, {float, 1.2421875}, {x, 0}}.
  {label, 561}.
    {jump, {f, 559}}.
  {label, 558}.
    {test, is_lt, {f, 562}, [{y, 0}, {float, 27.0}]}.
    {move, {float, 1.234375}, {x, 0}}.
    {jump, {f, 563}}.
  {label, 562}.
    {move, {float, 1.2265625}, {x, 0}}.
  {label, 563}.
  {label, 559}.
    {jump, {f, 557}}.
  {label, 556}.
    {test, is_lt, {f, 564}, [{y, 0}, {float, 30.0}]}.
    {test, is_lt, {f, 566}, [{y, 0}, {float, 29.0}]}.
    {move, {float, 1.2265625}, {x, 0}}.
    {jump, {f, 567}}.
  {label, 566}.
    {move, {float, 1.21875}, {x, 0}}.
  {label, 567}.
    {jump, {f, 565}}.
  {label, 564}.
    {test, is_lt, {f, 568}, [{y, 0}, {float, 31.0}]}.
    {move, {float, 1.2109375}, {x, 0}}.
    {jump, {f, 569}}.
  {label, 568}.
    {move, {float, 1.203125}, {x, 0}}.
  {label, 569}.
  {label, 565}.
  {label, 557}.
  {label, 541}.
  {label, 509}.
    {jump, {f, 507}}.
  {label, 506}.
    {test, is_lt, {f, 570}, [{y, 0}, {float, 48.0}]}.
    {test, is_lt, {f, 572}, [{y, 0}, {float, 40.0}]}.
    {test, is_lt, {f, 574}, [{y, 0}, {float, 36.0}]}.
    {test, is_lt, {f, 576}, [{y, 0}, {float, 34.0}]}.
    {test, is_lt, {f, 578}, [{y, 0}, {float, 33.0}]}.
    {move, {float, 1.203125}, {x, 0}}.
    {jump, {f, 579}}.
  {label, 578}.
    {move, {float, 1.1953125}, {x, 0}}.
  {label, 579}.
    {jump, {f, 577}}.
  {label, 576}.
    {test, is_lt, {f, 580}, [{y, 0}, {float, 35.0}]}.
    {move, {float, 1.1875}, {x, 0}}.
    {jump, {f, 581}}.
  {label, 580}.
    {move, {float, 1.1875}, {x, 0}}.
  {label, 581}.
  {label, 577}.
    {jump, {f, 575}}.
  {label, 574}.
    {test, is_lt, {f, 582}, [{y, 0}, {float, 38.0}]}.
    {test, is_lt, {f, 584}, [{y, 0}, {float, 37.0}]}.
    {move, {float, 1.1796875}, {x, 0}}.
    {jump, {f, 585}}.
  {label, 584}.
    {move, {float, 1.171875}, {x, 0}}.
  {label, 585}.
    {jump, {f, 583}}.
  {label, 582}.
    {test, is_lt, {f, 586}, [{y, 0}, {float, 39.0}]}.
    {move, {float, 1.171875}, {x, 0}}.
    {jump, {f, 587}}.
  {label, 586}.
    {move, {float, 1.1640625}, {x, 0}}.
  {label, 587}.
  {label, 583}.
  {label, 575}.
    {jump, {f, 573}}.
  {label, 572}.
    {test, is_lt, {f, 588}, [{y, 0}, {float, 44.0}]}.
    {test, is_lt, {f, 590}, [{y, 0}, {float, 42.0}]}.
    {test, is_lt, {f, 592}, [{y, 0}, {float, 41.0}]}.
    {move, {float, 1.15625}, {x, 0}}.
    {jump, {f, 593}}.
  {label, 592}.
    {move, {float, 1.1484375}, {x, 0}}.
  {label, 593}.
    {jump, {f, 591}}.
  {label, 590}.
    {test, is_lt, {f, 594}, [{y, 0}, {float, 43.0}]}.
    {move, {float, 1.1484375}, {x, 0}}.
    {jump, {f, 595}}.
  {label, 594}.
    {move, {float, 1.140625}, {x, 0}}.
  {label, 595}.
  {label, 591}.
    {jump, {f, 589}}.
  {label, 588}.
    {test, is_lt, {f, 596}, [{y, 0}, {float, 46.0}]}.
    {test, is_lt, {f, 598}, [{y, 0}, {float, 45.0}]}.
    {move, {float, 1.140625}, {x, 0}}.
    {jump, {f, 599}}.
  {label, 598}.
    {move, {float, 1.1328125}, {x, 0}}.
  {label, 599}.
    {jump, {f, 597}}.
  {label, 596}.
    {test, is_lt, {f, 600}, [{y, 0}, {float, 47.0}]}.
    {move, {float, 1.125}, {x, 0}}.
    {jump, {f, 601}}.
  {label, 600}.
    {move, {float, 1.125}, {x, 0}}.
  {label, 601}.
  {label, 597}.
  {label, 589}.
  {label, 573}.
    {jump, {f, 571}}.
  {label, 570}.
    {test, is_lt, {f, 602}, [{y, 0}, {float, 56.0}]}.
    {test, is_lt, {f, 604}, [{y, 0}, {float, 52.0}]}.
    {test, is_lt, {f, 606}, [{y, 0}, {float, 50.0}]}.
    {test, is_lt, {f, 608}, [{y, 0}, {float, 49.0}]}.
    {move, {float, 1.1171875}, {x, 0}}.
    {jump, {f, 609}}.
  {label, 608}.
    {move, {float, 1.109375}, {x, 0}}.
  {label, 609}.
    {jump, {f, 607}}.
  {label, 606}.
    {test, is_lt, {f, 610}, [{y, 0}, {float, 51.0}]}.
    {move, {float, 1.109375}, {x, 0}}.
    {jump, {f, 611}}.
  {label, 610}.
    {move, {float, 1.1015625}, {x, 0}}.
  {label, 611}.
  {label, 607}.
    {jump, {f, 605}}.
  {label, 604}.
    {test, is_lt, {f, 612}, [{y, 0}, {float, 54.0}]}.
    {test, is_lt, {f, 614}, [{y, 0}, {float, 53.0}]}.
    {move, {float, 1.1015625}, {x, 0}}.
    {jump, {f, 615}}.
  {label, 614}.
    {move, {float, 1.09375}, {x, 0}}.
  {label, 615}.
    {jump, {f, 613}}.
  {label, 612}.
    {test, is_lt, {f, 616}, [{y, 0}, {float, 55.0}]}.
    {move, {float, 1.0859375}, {x, 0}}.
    {jump, {f, 617}}.
  {label, 616}.
    {move, {float, 1.0859375}, {x, 0}}.
  {label, 617}.
  {label, 613}.
  {label, 605}.
    {jump, {f, 603}}.
  {label, 602}.
    {test, is_lt, {f, 618}, [{y, 0}, {float, 60.0}]}.
    {test, is_lt, {f, 620}, [{y, 0}, {float, 58.0}]}.
    {test, is_lt, {f, 622}, [{y, 0}, {float, 57.0}]}.
    {move, {float, 1.078125}, {x, 0}}.
    {jump, {f, 623}}.
  {label, 622}.
    {move, {float, 1.078125}, {x, 0}}.
  {label, 623}.
    {jump, {f, 621}}.
  {label, 620}.
    {test, is_lt, {f, 624}, [{y, 0}, {float, 59.0}]}.
    {move, {float, 1.0703125}, {x, 0}}.
    {jump, {f, 625}}.
  {label, 624}.
    {move, {float, 1.0625}, {x, 0}}.
  {label, 625}.
  {label, 621}.
    {jump, {f, 619}}.
  {label, 618}.
    {test, is_lt, {f, 626}, [{y, 0}, {float, 62.0}]}.
    {test, is_lt, {f, 628}, [{y, 0}, {float, 61.0}]}.
    {move, {float, 1.0625}, {x, 0}}.
    {jump, {f, 629}}.
  {label, 628}.
    {move, {float, 1.0546875}, {x, 0}}.
  {label, 629}.
    {jump, {f, 627}}.
  {label, 626}.
    {test, is_lt, {f, 630}, [{y, 0}, {float, 63.0}]}.
    {move, {float, 1.0546875}, {x, 0}}.
    {jump, {f, 631}}.
  {label, 630}.
    {move, {float, 1.046875}, {x, 0}}.
  {label, 631}.
  {label, 627}.
  {label, 619}.
  {label, 603}.
  {label, 571}.
  {label, 507}.
    {jump, {f, 505}}.
  {label, 504}.
    {test, is_lt, {f, 632}, [{y, 0}, {float, 96.0}]}.
    {test, is_lt, {f, 634}, [{y, 0}, {float, 80.0}]}.
    {test, is_lt, {f, 636}, [{y, 0}, {float, 72.0}]}.
    {test, is_lt, {f, 638}, [{y, 0}, {float, 68.0}]}.
    {test, is_lt, {f, 640}, [{y, 0}, {float, 66.0}]}.
    {test, is_lt, {f, 642}, [{y, 0}, {float, 65.0}]}.
    {move, {float, 1.046875}, {x, 0}}.
    {jump, {f, 643}}.
  {label, 642}.
    {move, {float, 1.0390625}, {x, 0}}.
  {label, 643}.
    {jump, {f, 641}}.
  {label, 640}.
    {test, is_lt, {f, 644}, [{y, 0}, {float, 67.0}]}.
    {move, {float, 1.0390625}, {x, 0}}.
    {jump, {f, 645}}.
  {label, 644}.
    {move, {float, 1.03125}, {x, 0}}.
  {label, 645}.
  {label, 641}.
    {jump, {f, 639}}.
  {label, 638}.
    {test, is_lt, {f, 646}, [{y, 0}, {float, 70.0}]}.
    {test, is_lt, {f, 648}, [{y, 0}, {float, 69.0}]}.
    {move, {float, 1.03125}, {x, 0}}.
    {jump, {f, 649}}.
  {label, 648}.
    {move, {float, 1.0234375}, {x, 0}}.
  {label, 649}.
    {jump, {f, 647}}.
  {label, 646}.
    {test, is_lt, {f, 650}, [{y, 0}, {float, 71.0}]}.
    {move, {float, 1.015625}, {x, 0}}.
    {jump, {f, 651}}.
  {label, 650}.
    {move, {float, 1.015625}, {x, 0}}.
  {label, 651}.
  {label, 647}.
  {label, 639}.
    {jump, {f, 637}}.
  {label, 636}.
    {test, is_lt, {f, 652}, [{y, 0}, {float, 76.0}]}.
    {test, is_lt, {f, 654}, [{y, 0}, {float, 74.0}]}.
    {test, is_lt, {f, 656}, [{y, 0}, {float, 73.0}]}.
    {move, {float, 1.0078125}, {x, 0}}.
    {jump, {f, 657}}.
  {label, 656}.
    {move, {float, 1.0078125}, {x, 0}}.
  {label, 657}.
    {jump, {f, 655}}.
  {label, 654}.
    {test, is_lt, {f, 658}, [{y, 0}, {float, 75.0}]}.
    {move, {float, 1.0}, {x, 0}}.
    {jump, {f, 659}}.
  {label, 658}.
    {move, {float, 1.0}, {x, 0}}.
  {label, 659}.
  {label, 655}.
    {jump, {f, 653}}.
  {label, 652}.
    {test, is_lt, {f, 660}, [{y, 0}, {float, 78.0}]}.
    {test, is_lt, {f, 662}, [{y, 0}, {float, 77.0}]}.
    {move, {float, 0.9921875}, {x, 0}}.
    {jump, {f, 663}}.
  {label, 662}.
    {move, {float, 0.984375}, {x, 0}}.
  {label, 663}.
    {jump, {f, 661}}.
  {label, 660}.
    {test, is_lt, {f, 664}, [{y, 0}, {float, 79.0}]}.
    {move, {float, 0.9765625}, {x, 0}}.
    {jump, {f, 665}}.
  {label, 664}.
    {move, {float, 0.96875}, {x, 0}}.
  {label, 665}.
  {label, 661}.
  {label, 653}.
  {label, 637}.
    {jump, {f, 635}}.
  {label, 634}.
    {test, is_lt, {f, 666}, [{y, 0}, {float, 88.0}]}.
    {test, is_lt, {f, 668}, [{y, 0}, {float, 84.0}]}.
    {test, is_lt, {f, 670}, [{y, 0}, {float, 82.0}]}.
    {test, is_lt, {f, 672}, [{y, 0}, {float, 81.0}]}.
    {move, {float, 0.9609375}, {x, 0}}.
    {jump, {f, 673}}.
  {label, 672}.
    {move, {float, 0.953125}, {x, 0}}.
  {label, 673}.
    {jump, {f, 671}}.
  {label, 670}.
    {test, is_lt, {f, 674}, [{y, 0}, {float, 83.0}]}.
    {move, {float, 0.9453125}, {x, 0}}.
    {jump, {f, 675}}.
  {label, 674}.
    {move, {float, 0.94140625}, {x, 0}}.
  {label, 675}.
  {label, 671}.
    {jump, {f, 669}}.
  {label, 668}.
    {test, is_lt, {f, 676}, [{y, 0}, {float, 86.0}]}.
    {test, is_lt, {f, 678}, [{y, 0}, {float, 85.0}]}.
    {move, {float, 0.93359375}, {x, 0}}.
    {jump, {f, 679}}.
  {label, 678}.
    {move, {float, 0.92578125}, {x, 0}}.
  {label, 679}.
    {jump, {f, 677}}.
  {label, 676}.
    {test, is_lt, {f, 680}, [{y, 0}, {float, 87.0}]}.
    {move, {float, 0.91796875}, {x, 0}}.
    {jump, {f, 681}}.
  {label, 680}.
    {move, {float, 0.9140625}, {x, 0}}.
  {label, 681}.
  {label, 677}.
  {label, 669}.
    {jump, {f, 667}}.
  {label, 666}.
    {test, is_lt, {f, 682}, [{y, 0}, {float, 92.0}]}.
    {test, is_lt, {f, 684}, [{y, 0}, {float, 90.0}]}.
    {test, is_lt, {f, 686}, [{y, 0}, {float, 89.0}]}.
    {move, {float, 0.90625}, {x, 0}}.
    {jump, {f, 687}}.
  {label, 686}.
    {move, {float, 0.8984375}, {x, 0}}.
  {label, 687}.
    {jump, {f, 685}}.
  {label, 684}.
    {test, is_lt, {f, 688}, [{y, 0}, {float, 91.0}]}.
    {move, {float, 0.89453125}, {x, 0}}.
    {jump, {f, 689}}.
  {label, 688}.
    {move, {float, 0.88671875}, {x, 0}}.
  {label, 689}.
  {label, 685}.
    {jump, {f, 683}}.
  {label, 682}.
    {test, is_lt, {f, 690}, [{y, 0}, {float, 94.0}]}.
    {test, is_lt, {f, 692}, [{y, 0}, {float, 93.0}]}.
    {move, {float, 0.8828125}, {x, 0}}.
    {jump, {f, 693}}.
  {label, 692}.
    {move, {float, 0.875}, {x, 0}}.
  {label, 693}.
    {jump, {f, 691}}.
  {label, 690}.
    {test, is_lt, {f, 694}, [{y, 0}, {float, 95.0}]}.
    {move, {float, 0.87109375}, {x, 0}}.
    {jump, {f, 695}}.
  {label, 694}.
    {move, {float, 0.86328125}, {x, 0}}.
  {label, 695}.
  {label, 691}.
  {label, 683}.
  {label, 667}.
  {label, 635}.
    {jump, {f, 633}}.
  {label, 632}.
    {test, is_lt, {f, 696}, [{y, 0}, {float, 112.0}]}.
    {test, is_lt, {f, 698}, [{y, 0}, {float, 104.0}]}.
    {test, is_lt, {f, 700}, [{y, 0}, {float, 100.0}]}.
    {test, is_lt, {f, 702}, [{y, 0}, {float, 98.0}]}.
    {test, is_lt, {f, 704}, [{y, 0}, {float, 97.0}]}.
    {move, {float, 0.859375}, {x, 0}}.
    {jump, {f, 705}}.
  {label, 704}.
    {move, {float, 0.8515625}, {x, 0}}.
  {label, 705}.
    {jump, {f, 703}}.
  {label, 702}.
    {test, is_lt, {f, 706}, [{y, 0}, {float, 99.0}]}.
    {move, {float, 0.84765625}, {x, 0}}.
    {jump, {f, 707}}.
  {label, 706}.
    {move, {float, 0.83984375}, {x, 0}}.
  {label, 707}.
  {label, 703}.
    {jump, {f, 701}}.
  {label, 700}.
    {test, is_lt, {f, 708}, [{y, 0}, {float, 102.0}]}.
    {test, is_lt, {f, 710}, [{y, 0}, {float, 101.0}]}.
    {move, {float, 0.8359375}, {x, 0}}.
    {jump, {f, 711}}.
  {label, 710}.
    {move, {float, 0.83203125}, {x, 0}}.
  {label, 711}.
    {jump, {f, 709}}.
  {label, 708}.
    {test, is_lt, {f, 712}, [{y, 0}, {float, 103.0}]}.
    {move, {float, 0.82421875}, {x, 0}}.
    {jump, {f, 713}}.
  {label, 712}.
    {move, {float, 0.8203125}, {x, 0}}.
  {label, 713}.
  {label, 709}.
  {label, 701}.
    {jump, {f, 699}}.
  {label, 698}.
    {test, is_lt, {f, 714}, [{y, 0}, {float, 108.0}]}.
    {test, is_lt, {f, 716}, [{y, 0}, {float, 106.0}]}.
    {test, is_lt, {f, 718}, [{y, 0}, {float, 105.0}]}.
    {move, {float, 0.8125}, {x, 0}}.
    {jump, {f, 719}}.
  {label, 718}.
    {move, {float, 0.80859375}, {x, 0}}.
  {label, 719}.
    {jump, {f, 717}}.
  {label, 716}.
    {test, is_lt, {f, 720}, [{y, 0}, {float, 107.0}]}.
    {move, {float, 0.8046875}, {x, 0}}.
    {jump, {f, 721}}.
  {label, 720}.
    {move, {float, 0.80078125}, {x, 0}}.
  {label, 721}.
  {label, 717}.
    {jump, {f, 715}}.
  {label, 714}.
    {test, is_lt, {f, 722}, [{y, 0}, {float, 110.0}]}.
    {test, is_lt, {f, 724}, [{y, 0}, {float, 109.0}]}.
    {move, {float, 0.79296875}, {x, 0}}.
    {jump, {f, 725}}.
  {label, 724}.
    {move, {float, 0.7890625}, {x, 0}}.
  {label, 725}.
    {jump, {f, 723}}.
  {label, 722}.
    {test, is_lt, {f, 726}, [{y, 0}, {float, 111.0}]}.
    {move, {float, 0.78515625}, {x, 0}}.
    {jump, {f, 727}}.
  {label, 726}.
    {move, {float, 0.78125}, {x, 0}}.
  {label, 727}.
  {label, 723}.
  {label, 715}.
  {label, 699}.
    {jump, {f, 697}}.
  {label, 696}.
    {test, is_lt, {f, 728}, [{y, 0}, {float, 120.0}]}.
    {test, is_lt, {f, 730}, [{y, 0}, {float, 116.0}]}.
    {test, is_lt, {f, 732}, [{y, 0}, {float, 114.0}]}.
    {test, is_lt, {f, 734}, [{y, 0}, {float, 113.0}]}.
    {move, {float, 0.7734375}, {x, 0}}.
    {jump, {f, 735}}.
  {label, 734}.
    {move, {float, 0.76953125}, {x, 0}}.
  {label, 735}.
    {jump, {f, 733}}.
  {label, 732}.
    {test, is_lt, {f, 736}, [{y, 0}, {float, 115.0}]}.
    {move, {float, 0.765625}, {x, 0}}.
    {jump, {f, 737}}.
  {label, 736}.
    {move, {float, 0.76171875}, {x, 0}}.
  {label, 737}.
  {label, 733}.
    {jump, {f, 731}}.
  {label, 730}.
    {test, is_lt, {f, 738}, [{y, 0}, {float, 118.0}]}.
    {test, is_lt, {f, 740}, [{y, 0}, {float, 117.0}]}.
    {move, {float, 0.7578125}, {x, 0}}.
    {jump, {f, 741}}.
  {label, 740}.
    {move, {float, 0.75390625}, {x, 0}}.
  {label, 741}.
    {jump, {f, 739}}.
  {label, 738}.
    {test, is_lt, {f, 742}, [{y, 0}, {float, 119.0}]}.
    {move, {float, 0.74609375}, {x, 0}}.
    {jump, {f, 743}}.
  {label, 742}.
    {move, {float, 0.7421875}, {x, 0}}.
  {label, 743}.
  {label, 739}.
  {label, 731}.
    {jump, {f, 729}}.
  {label, 728}.
    {test, is_lt, {f, 744}, [{y, 0}, {float, 124.0}]}.
    {test, is_lt, {f, 746}, [{y, 0}, {float, 122.0}]}.
    {test, is_lt, {f, 748}, [{y, 0}, {float, 121.0}]}.
    {move, {float, 0.73828125}, {x, 0}}.
    {jump, {f, 749}}.
  {label, 748}.
    {move, {float, 0.734375}, {x, 0}}.
  {label, 749}.
    {jump, {f, 747}}.
  {label, 746}.
    {test, is_lt, {f, 750}, [{y, 0}, {float, 123.0}]}.
    {move, {float, 0.73046875}, {x, 0}}.
    {jump, {f, 751}}.
  {label, 750}.
    {move, {float, 0.7265625}, {x, 0}}.
  {label, 751}.
  {label, 747}.
    {jump, {f, 745}}.
  {label, 744}.
    {test, is_lt, {f, 752}, [{y, 0}, {float, 126.0}]}.
    {test, is_lt, {f, 754}, [{y, 0}, {float, 125.0}]}.
    {move, {float, 0.72265625}, {x, 0}}.
    {jump, {f, 755}}.
  {label, 754}.
    {move, {float, 0.71875}, {x, 0}}.
  {label, 755}.
    {jump, {f, 753}}.
  {label, 752}.
    {test, is_lt, {f, 756}, [{y, 0}, {float, 127.0}]}.
    {move, {float, 0.71484375}, {x, 0}}.
    {jump, {f, 757}}.
  {label, 756}.
    {move, {float, 0.7109375}, {x, 0}}.
  {label, 757}.
  {label, 753}.
  {label, 745}.
  {label, 729}.
  {label, 697}.
  {label, 633}.
  {label, 505}.
    {deallocate, 1}.
    return.
% `__pow_log_data.tab[i].logc`: log c, its last bits rounded away so
% k·ln2hi + logc is exact.

{function, powLogc, 1, 119}.
  {label, 118}.
    {line, [{location, "std@math.erl", 66}]}.
    {func_info, {atom, std@math}, {atom, powLogc}, 1}.
  {label, 119}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_lt, {f, 758}, [{y, 0}, {float, 64.0}]}.
    {test, is_lt, {f, 760}, [{y, 0}, {float, 32.0}]}.
    {test, is_lt, {f, 762}, [{y, 0}, {float, 16.0}]}.
    {test, is_lt, {f, 764}, [{y, 0}, {float, 8.0}]}.
    {test, is_lt, {f, 766}, [{y, 0}, {float, 4.0}]}.
    {test, is_lt, {f, 768}, [{y, 0}, {float, 2.0}]}.
    {test, is_lt, {f, 770}, [{y, 0}, {float, 1.0}]}.
    {move, {float, -0.3464667673462145}, {x, 0}}.
    {jump, {f, 771}}.
  {label, 770}.
    {move, {float, -0.34092658697056777}, {x, 0}}.
  {label, 771}.
    {jump, {f, 769}}.
  {label, 768}.
    {test, is_lt, {f, 772}, [{y, 0}, {float, 3.0}]}.
    {move, {float, -0.3353555419211034}, {x, 0}}.
    {jump, {f, 773}}.
  {label, 772}.
    {move, {float, -0.3297532863724655}, {x, 0}}.
  {label, 773}.
  {label, 769}.
    {jump, {f, 767}}.
  {label, 766}.
    {test, is_lt, {f, 774}, [{y, 0}, {float, 6.0}]}.
    {test, is_lt, {f, 776}, [{y, 0}, {float, 5.0}]}.
    {move, {float, -0.32411946865420305}, {x, 0}}.
    {jump, {f, 777}}.
  {label, 776}.
    {move, {float, -0.31845373111855224}, {x, 0}}.
  {label, 777}.
    {jump, {f, 775}}.
  {label, 774}.
    {test, is_lt, {f, 778}, [{y, 0}, {float, 7.0}]}.
    {move, {float, -0.31275571000389846}, {x, 0}}.
    {jump, {f, 779}}.
  {label, 778}.
    {move, {float, -0.3070250352949415}, {x, 0}}.
  {label, 779}.
  {label, 775}.
  {label, 767}.
    {jump, {f, 765}}.
  {label, 764}.
    {test, is_lt, {f, 780}, [{y, 0}, {float, 12.0}]}.
    {test, is_lt, {f, 782}, [{y, 0}, {float, 10.0}]}.
    {test, is_lt, {f, 784}, [{y, 0}, {float, 9.0}]}.
    {move, {float, -0.3012613305781997}, {x, 0}}.
    {jump, {f, 785}}.
  {label, 784}.
    {move, {float, -0.2954642128938758}, {x, 0}}.
  {label, 785}.
    {jump, {f, 783}}.
  {label, 782}.
    {test, is_lt, {f, 786}, [{y, 0}, {float, 11.0}]}.
    {move, {float, -0.28963329258306203}, {x, 0}}.
    {jump, {f, 787}}.
  {label, 786}.
    {move, {float, -0.28963329258306203}, {x, 0}}.
  {label, 787}.
  {label, 783}.
    {jump, {f, 781}}.
  {label, 780}.
    {test, is_lt, {f, 788}, [{y, 0}, {float, 14.0}]}.
    {test, is_lt, {f, 790}, [{y, 0}, {float, 13.0}]}.
    {move, {float, -0.28376817313062475}, {x, 0}}.
    {jump, {f, 791}}.
  {label, 790}.
    {move, {float, -0.27786845100342816}, {x, 0}}.
  {label, 791}.
    {jump, {f, 789}}.
  {label, 788}.
    {test, is_lt, {f, 792}, [{y, 0}, {float, 15.0}]}.
    {move, {float, -0.2719337154836694}, {x, 0}}.
    {jump, {f, 793}}.
  {label, 792}.
    {move, {float, -0.2659635484970977}, {x, 0}}.
  {label, 793}.
  {label, 789}.
  {label, 781}.
  {label, 765}.
    {jump, {f, 763}}.
  {label, 762}.
    {test, is_lt, {f, 794}, [{y, 0}, {float, 24.0}]}.
    {test, is_lt, {f, 796}, [{y, 0}, {float, 20.0}]}.
    {test, is_lt, {f, 798}, [{y, 0}, {float, 18.0}]}.
    {test, is_lt, {f, 800}, [{y, 0}, {float, 17.0}]}.
    {move, {float, -0.25995752443691345}, {x, 0}}.
    {jump, {f, 801}}.
  {label, 800}.
    {move, {float, -0.25391520998095984}, {x, 0}}.
  {label, 801}.
    {jump, {f, 799}}.
  {label, 798}.
    {test, is_lt, {f, 802}, [{y, 0}, {float, 19.0}]}.
    {move, {float, -0.25391520998095984}, {x, 0}}.
    {jump, {f, 803}}.
  {label, 802}.
    {move, {float, -0.2478361639045943}, {x, 0}}.
  {label, 803}.
  {label, 799}.
    {jump, {f, 797}}.
  {label, 796}.
    {test, is_lt, {f, 804}, [{y, 0}, {float, 22.0}]}.
    {test, is_lt, {f, 806}, [{y, 0}, {float, 21.0}]}.
    {move, {float, -0.2417199368871934}, {x, 0}}.
    {jump, {f, 807}}.
  {label, 806}.
    {move, {float, -0.23556607131274632}, {x, 0}}.
  {label, 807}.
    {jump, {f, 805}}.
  {label, 804}.
    {test, is_lt, {f, 808}, [{y, 0}, {float, 23.0}]}.
    {move, {float, -0.22937410106487732}, {x, 0}}.
    {jump, {f, 809}}.
  {label, 808}.
    {move, {float, -0.22314355131425145}, {x, 0}}.
  {label, 809}.
  {label, 805}.
  {label, 797}.
    {jump, {f, 795}}.
  {label, 794}.
    {test, is_lt, {f, 810}, [{y, 0}, {float, 28.0}]}.
    {test, is_lt, {f, 812}, [{y, 0}, {float, 26.0}]}.
    {test, is_lt, {f, 814}, [{y, 0}, {float, 25.0}]}.
    {move, {float, -0.22314355131425145}, {x, 0}}.
    {jump, {f, 815}}.
  {label, 814}.
    {move, {float, -0.21687393830063684}, {x, 0}}.
  {label, 815}.
    {jump, {f, 813}}.
  {label, 812}.
    {test, is_lt, {f, 816}, [{y, 0}, {float, 27.0}]}.
    {move, {float, -0.21056476910735}, {x, 0}}.
    {jump, {f, 817}}.
  {label, 816}.
    {move, {float, -0.2042155414286526}, {x, 0}}.
  {label, 817}.
  {label, 813}.
    {jump, {f, 811}}.
  {label, 810}.
    {test, is_lt, {f, 818}, [{y, 0}, {float, 30.0}]}.
    {test, is_lt, {f, 820}, [{y, 0}, {float, 29.0}]}.
    {move, {float, -0.2042155414286526}, {x, 0}}.
    {jump, {f, 821}}.
  {label, 820}.
    {move, {float, -0.19782574332987224}, {x, 0}}.
  {label, 821}.
    {jump, {f, 819}}.
  {label, 818}.
    {test, is_lt, {f, 822}, [{y, 0}, {float, 31.0}]}.
    {move, {float, -0.19139485299967873}, {x, 0}}.
    {jump, {f, 823}}.
  {label, 822}.
    {move, {float, -0.18492233849406148}, {x, 0}}.
  {label, 823}.
  {label, 819}.
  {label, 811}.
  {label, 795}.
  {label, 763}.
    {jump, {f, 761}}.
  {label, 760}.
    {test, is_lt, {f, 824}, [{y, 0}, {float, 48.0}]}.
    {test, is_lt, {f, 826}, [{y, 0}, {float, 40.0}]}.
    {test, is_lt, {f, 828}, [{y, 0}, {float, 36.0}]}.
    {test, is_lt, {f, 830}, [{y, 0}, {float, 34.0}]}.
    {test, is_lt, {f, 832}, [{y, 0}, {float, 33.0}]}.
    {move, {float, -0.18492233849406148}, {x, 0}}.
    {jump, {f, 833}}.
  {label, 832}.
    {move, {float, -0.1784076574728033}, {x, 0}}.
  {label, 833}.
    {jump, {f, 831}}.
  {label, 830}.
    {test, is_lt, {f, 834}, [{y, 0}, {float, 35.0}]}.
    {move, {float, -0.17185025692663203}, {x, 0}}.
    {jump, {f, 835}}.
  {label, 834}.
    {move, {float, -0.17185025692663203}, {x, 0}}.
  {label, 835}.
  {label, 831}.
    {jump, {f, 829}}.
  {label, 828}.
    {test, is_lt, {f, 836}, [{y, 0}, {float, 38.0}]}.
    {test, is_lt, {f, 838}, [{y, 0}, {float, 37.0}]}.
    {move, {float, -0.1652495728952772}, {x, 0}}.
    {jump, {f, 839}}.
  {label, 838}.
    {move, {float, -0.15860503017665906}, {x, 0}}.
  {label, 839}.
    {jump, {f, 837}}.
  {label, 836}.
    {test, is_lt, {f, 840}, [{y, 0}, {float, 39.0}]}.
    {move, {float, -0.15860503017665906}, {x, 0}}.
    {jump, {f, 841}}.
  {label, 840}.
    {move, {float, -0.15191604202584585}, {x, 0}}.
  {label, 841}.
  {label, 837}.
  {label, 829}.
    {jump, {f, 827}}.
  {label, 826}.
    {test, is_lt, {f, 842}, [{y, 0}, {float, 44.0}]}.
    {test, is_lt, {f, 844}, [{y, 0}, {float, 42.0}]}.
    {test, is_lt, {f, 846}, [{y, 0}, {float, 41.0}]}.
    {move, {float, -0.1451820098444614}, {x, 0}}.
    {jump, {f, 847}}.
  {label, 846}.
    {move, {float, -0.13840232285906495}, {x, 0}}.
  {label, 847}.
    {jump, {f, 845}}.
  {label, 844}.
    {test, is_lt, {f, 848}, [{y, 0}, {float, 43.0}]}.
    {move, {float, -0.13840232285906495}, {x, 0}}.
    {jump, {f, 849}}.
  {label, 848}.
    {move, {float, -0.131576357788731}, {x, 0}}.
  {label, 849}.
  {label, 845}.
    {jump, {f, 843}}.
  {label, 842}.
    {test, is_lt, {f, 850}, [{y, 0}, {float, 46.0}]}.
    {test, is_lt, {f, 852}, [{y, 0}, {float, 45.0}]}.
    {move, {float, -0.131576357788731}, {x, 0}}.
    {jump, {f, 853}}.
  {label, 852}.
    {move, {float, -0.12470347850091912}, {x, 0}}.
  {label, 853}.
    {jump, {f, 851}}.
  {label, 850}.
    {test, is_lt, {f, 854}, [{y, 0}, {float, 47.0}]}.
    {move, {float, -0.11778303565643}, {x, 0}}.
    {jump, {f, 855}}.
  {label, 854}.
    {move, {float, -0.11778303565643}, {x, 0}}.
  {label, 855}.
  {label, 851}.
  {label, 843}.
  {label, 827}.
    {jump, {f, 825}}.
  {label, 824}.
    {test, is_lt, {f, 856}, [{y, 0}, {float, 56.0}]}.
    {test, is_lt, {f, 858}, [{y, 0}, {float, 52.0}]}.
    {test, is_lt, {f, 860}, [{y, 0}, {float, 50.0}]}.
    {test, is_lt, {f, 862}, [{y, 0}, {float, 49.0}]}.
    {move, {float, -0.11081436634026431}, {x, 0}}.
    {jump, {f, 863}}.
  {label, 862}.
    {move, {float, -0.10379679368168127}, {x, 0}}.
  {label, 863}.
    {jump, {f, 861}}.
  {label, 860}.
    {test, is_lt, {f, 864}, [{y, 0}, {float, 51.0}]}.
    {move, {float, -0.10379679368168127}, {x, 0}}.
    {jump, {f, 865}}.
  {label, 864}.
    {move, {float, -0.09672962645856842}, {x, 0}}.
  {label, 865}.
  {label, 861}.
    {jump, {f, 859}}.
  {label, 858}.
    {test, is_lt, {f, 866}, [{y, 0}, {float, 54.0}]}.
    {test, is_lt, {f, 868}, [{y, 0}, {float, 53.0}]}.
    {move, {float, -0.09672962645856842}, {x, 0}}.
    {jump, {f, 869}}.
  {label, 868}.
    {move, {float, -0.089612158689647}, {x, 0}}.
  {label, 869}.
    {jump, {f, 867}}.
  {label, 866}.
    {test, is_lt, {f, 870}, [{y, 0}, {float, 55.0}]}.
    {move, {float, -0.08244366921110213}, {x, 0}}.
    {jump, {f, 871}}.
  {label, 870}.
    {move, {float, -0.08244366921110213}, {x, 0}}.
  {label, 871}.
  {label, 867}.
  {label, 859}.
    {jump, {f, 857}}.
  {label, 856}.
    {test, is_lt, {f, 872}, [{y, 0}, {float, 60.0}]}.
    {test, is_lt, {f, 874}, [{y, 0}, {float, 58.0}]}.
    {test, is_lt, {f, 876}, [{y, 0}, {float, 57.0}]}.
    {move, {float, -0.07522342123763792}, {x, 0}}.
    {jump, {f, 877}}.
  {label, 876}.
    {move, {float, -0.07522342123763792}, {x, 0}}.
  {label, 877}.
    {jump, {f, 875}}.
  {label, 874}.
    {test, is_lt, {f, 878}, [{y, 0}, {float, 59.0}]}.
    {move, {float, -0.06795066190852594}, {x, 0}}.
    {jump, {f, 879}}.
  {label, 878}.
    {move, {float, -0.06062462181648698}, {x, 0}}.
  {label, 879}.
  {label, 875}.
    {jump, {f, 873}}.
  {label, 872}.
    {test, is_lt, {f, 880}, [{y, 0}, {float, 62.0}]}.
    {test, is_lt, {f, 882}, [{y, 0}, {float, 61.0}]}.
    {move, {float, -0.06062462181648698}, {x, 0}}.
    {jump, {f, 883}}.
  {label, 882}.
    {move, {float, -0.053244514518837605}, {x, 0}}.
  {label, 883}.
    {jump, {f, 881}}.
  {label, 880}.
    {test, is_lt, {f, 884}, [{y, 0}, {float, 63.0}]}.
    {move, {float, -0.053244514518837605}, {x, 0}}.
    {jump, {f, 885}}.
  {label, 884}.
    {move, {float, -0.045809536031242715}, {x, 0}}.
  {label, 885}.
  {label, 881}.
  {label, 873}.
  {label, 857}.
  {label, 825}.
  {label, 761}.
    {jump, {f, 759}}.
  {label, 758}.
    {test, is_lt, {f, 886}, [{y, 0}, {float, 96.0}]}.
    {test, is_lt, {f, 888}, [{y, 0}, {float, 80.0}]}.
    {test, is_lt, {f, 890}, [{y, 0}, {float, 72.0}]}.
    {test, is_lt, {f, 892}, [{y, 0}, {float, 68.0}]}.
    {test, is_lt, {f, 894}, [{y, 0}, {float, 66.0}]}.
    {test, is_lt, {f, 896}, [{y, 0}, {float, 65.0}]}.
    {move, {float, -0.045809536031242715}, {x, 0}}.
    {jump, {f, 897}}.
  {label, 896}.
    {move, {float, -0.038318864302141264}, {x, 0}}.
  {label, 897}.
    {jump, {f, 895}}.
  {label, 894}.
    {test, is_lt, {f, 898}, [{y, 0}, {float, 67.0}]}.
    {move, {float, -0.038318864302141264}, {x, 0}}.
    {jump, {f, 899}}.
  {label, 898}.
    {move, {float, -0.03077165866670839}, {x, 0}}.
  {label, 899}.
  {label, 895}.
    {jump, {f, 893}}.
  {label, 892}.
    {test, is_lt, {f, 900}, [{y, 0}, {float, 70.0}]}.
    {test, is_lt, {f, 902}, [{y, 0}, {float, 69.0}]}.
    {move, {float, -0.03077165866670839}, {x, 0}}.
    {jump, {f, 903}}.
  {label, 902}.
    {move, {float, -0.023167059281490765}, {x, 0}}.
  {label, 903}.
    {jump, {f, 901}}.
  {label, 900}.
    {test, is_lt, {f, 904}, [{y, 0}, {float, 71.0}]}.
    {move, {float, -0.015504186535963527}, {x, 0}}.
    {jump, {f, 905}}.
  {label, 904}.
    {move, {float, -0.015504186535963527}, {x, 0}}.
  {label, 905}.
  {label, 901}.
  {label, 893}.
    {jump, {f, 891}}.
  {label, 890}.
    {test, is_lt, {f, 906}, [{y, 0}, {float, 76.0}]}.
    {test, is_lt, {f, 908}, [{y, 0}, {float, 74.0}]}.
    {test, is_lt, {f, 910}, [{y, 0}, {float, 73.0}]}.
    {move, {float, -0.0077821404420319595}, {x, 0}}.
    {jump, {f, 911}}.
  {label, 910}.
    {move, {float, -0.0077821404420319595}, {x, 0}}.
  {label, 911}.
    {jump, {f, 909}}.
  {label, 908}.
    {test, is_lt, {f, 912}, [{y, 0}, {float, 75.0}]}.
    {move, {float, 0.0}, {x, 0}}.
    {jump, {f, 913}}.
  {label, 912}.
    {move, {float, 0.0}, {x, 0}}.
  {label, 913}.
  {label, 909}.
    {jump, {f, 907}}.
  {label, 906}.
    {test, is_lt, {f, 914}, [{y, 0}, {float, 78.0}]}.
    {test, is_lt, {f, 916}, [{y, 0}, {float, 77.0}]}.
    {move, {float, 0.007843177461040796}, {x, 0}}.
    {jump, {f, 917}}.
  {label, 916}.
    {move, {float, 0.01574835696817445}, {x, 0}}.
  {label, 917}.
    {jump, {f, 915}}.
  {label, 914}.
    {test, is_lt, {f, 918}, [{y, 0}, {float, 79.0}]}.
    {move, {float, 0.023716526617363343}, {x, 0}}.
    {jump, {f, 919}}.
  {label, 918}.
    {move, {float, 0.03174869831457272}, {x, 0}}.
  {label, 919}.
  {label, 915}.
  {label, 907}.
  {label, 891}.
    {jump, {f, 889}}.
  {label, 888}.
    {test, is_lt, {f, 920}, [{y, 0}, {float, 88.0}]}.
    {test, is_lt, {f, 922}, [{y, 0}, {float, 84.0}]}.
    {test, is_lt, {f, 924}, [{y, 0}, {float, 82.0}]}.
    {test, is_lt, {f, 926}, [{y, 0}, {float, 81.0}]}.
    {move, {float, 0.039845908547249564}, {x, 0}}.
    {jump, {f, 927}}.
  {label, 926}.
    {move, {float, 0.048009219186383234}, {x, 0}}.
  {label, 927}.
    {jump, {f, 925}}.
  {label, 924}.
    {test, is_lt, {f, 928}, [{y, 0}, {float, 83.0}]}.
    {move, {float, 0.056239718322899535}, {x, 0}}.
    {jump, {f, 929}}.
  {label, 928}.
    {move, {float, 0.06038051098892083}, {x, 0}}.
  {label, 929}.
  {label, 925}.
    {jump, {f, 923}}.
  {label, 922}.
    {test, is_lt, {f, 930}, [{y, 0}, {float, 86.0}]}.
    {test, is_lt, {f, 932}, [{y, 0}, {float, 85.0}]}.
    {move, {float, 0.06871389254808946}, {x, 0}}.
    {jump, {f, 933}}.
  {label, 932}.
    {move, {float, 0.07711730334438016}, {x, 0}}.
  {label, 933}.
    {jump, {f, 931}}.
  {label, 930}.
    {test, is_lt, {f, 934}, [{y, 0}, {float, 87.0}]}.
    {move, {float, 0.08559193033545398}, {x, 0}}.
    {jump, {f, 935}}.
  {label, 934}.
    {move, {float, 0.08985632912185793}, {x, 0}}.
  {label, 935}.
  {label, 931}.
  {label, 923}.
    {jump, {f, 921}}.
  {label, 920}.
    {test, is_lt, {f, 936}, [{y, 0}, {float, 92.0}]}.
    {test, is_lt, {f, 938}, [{y, 0}, {float, 90.0}]}.
    {test, is_lt, {f, 940}, [{y, 0}, {float, 89.0}]}.
    {move, {float, 0.09844007281321865}, {x, 0}}.
    {jump, {f, 941}}.
  {label, 940}.
    {move, {float, 0.10709813555638448}, {x, 0}}.
  {label, 941}.
    {jump, {f, 939}}.
  {label, 938}.
    {test, is_lt, {f, 942}, [{y, 0}, {float, 91.0}]}.
    {move, {float, 0.11145544092528326}, {x, 0}}.
    {jump, {f, 943}}.
  {label, 942}.
    {move, {float, 0.12022742699821265}, {x, 0}}.
  {label, 943}.
  {label, 939}.
    {jump, {f, 937}}.
  {label, 936}.
    {test, is_lt, {f, 944}, [{y, 0}, {float, 94.0}]}.
    {test, is_lt, {f, 946}, [{y, 0}, {float, 93.0}]}.
    {move, {float, 0.12464244520731427}, {x, 0}}.
    {jump, {f, 947}}.
  {label, 946}.
    {move, {float, 0.13353139262449076}, {x, 0}}.
  {label, 947}.
    {jump, {f, 945}}.
  {label, 944}.
    {test, is_lt, {f, 948}, [{y, 0}, {float, 95.0}]}.
    {move, {float, 0.13800567301939282}, {x, 0}}.
    {jump, {f, 949}}.
  {label, 948}.
    {move, {float, 0.14701474296180095}, {x, 0}}.
  {label, 949}.
  {label, 945}.
  {label, 937}.
  {label, 921}.
  {label, 889}.
    {jump, {f, 887}}.
  {label, 886}.
    {test, is_lt, {f, 950}, [{y, 0}, {float, 112.0}]}.
    {test, is_lt, {f, 952}, [{y, 0}, {float, 104.0}]}.
    {test, is_lt, {f, 954}, [{y, 0}, {float, 100.0}]}.
    {test, is_lt, {f, 956}, [{y, 0}, {float, 98.0}]}.
    {test, is_lt, {f, 958}, [{y, 0}, {float, 97.0}]}.
    {move, {float, 0.15154989812720032}, {x, 0}}.
    {jump, {f, 959}}.
  {label, 958}.
    {move, {float, 0.16068238169043525}, {x, 0}}.
  {label, 959}.
    {jump, {f, 957}}.
  {label, 956}.
    {test, is_lt, {f, 960}, [{y, 0}, {float, 99.0}]}.
    {move, {float, 0.16528009093906348}, {x, 0}}.
    {jump, {f, 961}}.
  {label, 960}.
    {move, {float, 0.17453941635187675}, {x, 0}}.
  {label, 961}.
  {label, 957}.
    {jump, {f, 955}}.
  {label, 954}.
    {test, is_lt, {f, 962}, [{y, 0}, {float, 102.0}]}.
    {test, is_lt, {f, 964}, [{y, 0}, {float, 101.0}]}.
    {move, {float, 0.17920142945774842}, {x, 0}}.
    {jump, {f, 965}}.
  {label, 964}.
    {move, {float, 0.18388527877016259}, {x, 0}}.
  {label, 965}.
    {jump, {f, 963}}.
  {label, 962}.
    {test, is_lt, {f, 966}, [{y, 0}, {float, 103.0}]}.
    {move, {float, 0.1933193110035063}, {x, 0}}.
    {jump, {f, 967}}.
  {label, 966}.
    {move, {float, 0.19806991376208316}, {x, 0}}.
  {label, 967}.
  {label, 963}.
  {label, 955}.
    {jump, {f, 953}}.
  {label, 952}.
    {test, is_lt, {f, 968}, [{y, 0}, {float, 108.0}]}.
    {test, is_lt, {f, 970}, [{y, 0}, {float, 106.0}]}.
    {test, is_lt, {f, 972}, [{y, 0}, {float, 105.0}]}.
    {move, {float, 0.20763936477828793}, {x, 0}}.
    {jump, {f, 973}}.
  {label, 972}.
    {move, {float, 0.21245865121420593}, {x, 0}}.
  {label, 973}.
    {jump, {f, 971}}.
  {label, 970}.
    {test, is_lt, {f, 974}, [{y, 0}, {float, 107.0}]}.
    {move, {float, 0.21730127569003344}, {x, 0}}.
    {jump, {f, 975}}.
  {label, 974}.
    {move, {float, 0.22216746534115828}, {x, 0}}.
  {label, 975}.
  {label, 971}.
    {jump, {f, 969}}.
  {label, 968}.
    {test, is_lt, {f, 976}, [{y, 0}, {float, 110.0}]}.
    {test, is_lt, {f, 978}, [{y, 0}, {float, 109.0}]}.
    {move, {float, 0.2319714654378231}, {x, 0}}.
    {jump, {f, 979}}.
  {label, 978}.
    {move, {float, 0.2369097470783572}, {x, 0}}.
  {label, 979}.
    {jump, {f, 977}}.
  {label, 976}.
    {test, is_lt, {f, 980}, [{y, 0}, {float, 111.0}]}.
    {move, {float, 0.24187253642048745}, {x, 0}}.
    {jump, {f, 981}}.
  {label, 980}.
    {move, {float, 0.2468600779315011}, {x, 0}}.
  {label, 981}.
  {label, 977}.
  {label, 969}.
  {label, 953}.
    {jump, {f, 951}}.
  {label, 950}.
    {test, is_lt, {f, 982}, [{y, 0}, {float, 120.0}]}.
    {test, is_lt, {f, 984}, [{y, 0}, {float, 116.0}]}.
    {test, is_lt, {f, 986}, [{y, 0}, {float, 114.0}]}.
    {test, is_lt, {f, 988}, [{y, 0}, {float, 113.0}]}.
    {move, {float, 0.2569104137850218}, {x, 0}}.
    {jump, {f, 989}}.
  {label, 988}.
    {move, {float, 0.26197371574153294}, {x, 0}}.
  {label, 989}.
    {jump, {f, 987}}.
  {label, 986}.
    {test, is_lt, {f, 990}, [{y, 0}, {float, 115.0}]}.
    {move, {float, 0.2670627852490952}, {x, 0}}.
    {jump, {f, 991}}.
  {label, 990}.
    {move, {float, 0.27217788591576664}, {x, 0}}.
  {label, 991}.
  {label, 987}.
    {jump, {f, 985}}.
  {label, 984}.
    {test, is_lt, {f, 992}, [{y, 0}, {float, 118.0}]}.
    {test, is_lt, {f, 994}, [{y, 0}, {float, 117.0}]}.
    {move, {float, 0.27731928541618345}, {x, 0}}.
    {jump, {f, 995}}.
  {label, 994}.
    {move, {float, 0.28248725557466514}, {x, 0}}.
  {label, 995}.
    {jump, {f, 993}}.
  {label, 992}.
    {test, is_lt, {f, 996}, [{y, 0}, {float, 119.0}]}.
    {move, {float, 0.29290401643288533}, {x, 0}}.
    {jump, {f, 997}}.
  {label, 996}.
    {move, {float, 0.29815337231912054}, {x, 0}}.
  {label, 997}.
  {label, 993}.
  {label, 985}.
    {jump, {f, 983}}.
  {label, 982}.
    {test, is_lt, {f, 998}, [{y, 0}, {float, 124.0}]}.
    {test, is_lt, {f, 1000}, [{y, 0}, {float, 122.0}]}.
    {test, is_lt, {f, 1002}, [{y, 0}, {float, 121.0}]}.
    {move, {float, 0.3034304294199046}, {x, 0}}.
    {jump, {f, 1003}}.
  {label, 1002}.
    {move, {float, 0.30873548164959175}, {x, 0}}.
  {label, 1003}.
    {jump, {f, 1001}}.
  {label, 1000}.
    {test, is_lt, {f, 1004}, [{y, 0}, {float, 123.0}]}.
    {move, {float, 0.3140688276249648}, {x, 0}}.
    {jump, {f, 1005}}.
  {label, 1004}.
    {move, {float, 0.31943077076641657}, {x, 0}}.
  {label, 1005}.
  {label, 1001}.
    {jump, {f, 999}}.
  {label, 998}.
    {test, is_lt, {f, 1006}, [{y, 0}, {float, 126.0}]}.
    {test, is_lt, {f, 1008}, [{y, 0}, {float, 125.0}]}.
    {move, {float, 0.3248216194012912}, {x, 0}}.
    {jump, {f, 1009}}.
  {label, 1008}.
    {move, {float, 0.33024168687052224}, {x, 0}}.
  {label, 1009}.
    {jump, {f, 1007}}.
  {label, 1006}.
    {test, is_lt, {f, 1010}, [{y, 0}, {float, 127.0}]}.
    {move, {float, 0.3356912916381134}, {x, 0}}.
    {jump, {f, 1011}}.
  {label, 1010}.
    {move, {float, 0.3411707574027787}, {x, 0}}.
  {label, 1011}.
  {label, 1007}.
  {label, 999}.
  {label, 983}.
  {label, 951}.
  {label, 887}.
  {label, 759}.
    {deallocate, 1}.
    return.
% `__pow_log_data.tab[i].logctail`: log c − logc.

{function, powLogctail, 1, 121}.
  {label, 120}.
    {line, [{location, "std@math.erl", 67}]}.
    {func_info, {atom, std@math}, {atom, powLogctail}, 1}.
  {label, 121}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_lt, {f, 1012}, [{y, 0}, {float, 64.0}]}.
    {test, is_lt, {f, 1014}, [{y, 0}, {float, 32.0}]}.
    {test, is_lt, {f, 1016}, [{y, 0}, {float, 16.0}]}.
    {test, is_lt, {f, 1018}, [{y, 0}, {float, 8.0}]}.
    {test, is_lt, {f, 1020}, [{y, 0}, {float, 4.0}]}.
    {test, is_lt, {f, 1022}, [{y, 0}, {float, 2.0}]}.
    {test, is_lt, {f, 1024}, [{y, 0}, {float, 1.0}]}.
    {move, {float, 5.929407345889625e-15}, {x, 0}}.
    {jump, {f, 1025}}.
  {label, 1024}.
    {move, {float, -2.544157440035963e-14}, {x, 0}}.
  {label, 1025}.
    {jump, {f, 1023}}.
  {label, 1022}.
    {test, is_lt, {f, 1026}, [{y, 0}, {float, 3.0}]}.
    {move, {float, -3.443525940775045e-14}, {x, 0}}.
    {jump, {f, 1027}}.
  {label, 1026}.
    {move, {float, -2.500123826022799e-15}, {x, 0}}.
  {label, 1027}.
  {label, 1023}.
    {jump, {f, 1021}}.
  {label, 1020}.
    {test, is_lt, {f, 1028}, [{y, 0}, {float, 6.0}]}.
    {test, is_lt, {f, 1030}, [{y, 0}, {float, 5.0}]}.
    {move, {float, -8.929337133850617e-15}, {x, 0}}.
    {jump, {f, 1031}}.
  {label, 1030}.
    {move, {float, 1.7625431312172662e-14}, {x, 0}}.
  {label, 1031}.
    {jump, {f, 1029}}.
  {label, 1028}.
    {test, is_lt, {f, 1032}, [{y, 0}, {float, 7.0}]}.
    {move, {float, 1.5688303180062087e-15}, {x, 0}}.
    {jump, {f, 1033}}.
  {label, 1032}.
    {move, {float, 2.9655274673691784e-14}, {x, 0}}.
  {label, 1033}.
  {label, 1029}.
  {label, 1021}.
    {jump, {f, 1019}}.
  {label, 1018}.
    {test, is_lt, {f, 1034}, [{y, 0}, {float, 12.0}]}.
    {test, is_lt, {f, 1036}, [{y, 0}, {float, 10.0}]}.
    {test, is_lt, {f, 1038}, [{y, 0}, {float, 9.0}]}.
    {move, {float, 3.7923164802093147e-14}, {x, 0}}.
    {jump, {f, 1039}}.
  {label, 1038}.
    {move, {float, 3.993416384387844e-14}, {x, 0}}.
  {label, 1039}.
    {jump, {f, 1037}}.
  {label, 1036}.
    {test, is_lt, {f, 1040}, [{y, 0}, {float, 11.0}]}.
    {move, {float, 1.9352855826489123e-14}, {x, 0}}.
    {jump, {f, 1041}}.
  {label, 1040}.
    {move, {float, 1.9352855826489123e-14}, {x, 0}}.
  {label, 1041}.
  {label, 1037}.
    {jump, {f, 1035}}.
  {label, 1034}.
    {test, is_lt, {f, 1042}, [{y, 0}, {float, 14.0}]}.
    {test, is_lt, {f, 1044}, [{y, 0}, {float, 13.0}]}.
    {move, {float, -1.9852665484979036e-14}, {x, 0}}.
    {jump, {f, 1045}}.
  {label, 1044}.
    {move, {float, -2.814323765595281e-14}, {x, 0}}.
  {label, 1045}.
    {jump, {f, 1043}}.
  {label, 1042}.
    {test, is_lt, {f, 1046}, [{y, 0}, {float, 15.0}]}.
    {move, {float, 2.7643769993528702e-14}, {x, 0}}.
    {jump, {f, 1047}}.
  {label, 1046}.
    {move, {float, -4.025092402293806e-14}, {x, 0}}.
  {label, 1047}.
  {label, 1043}.
  {label, 1035}.
  {label, 1019}.
    {jump, {f, 1017}}.
  {label, 1016}.
    {test, is_lt, {f, 1048}, [{y, 0}, {float, 24.0}]}.
    {test, is_lt, {f, 1050}, [{y, 0}, {float, 20.0}]}.
    {test, is_lt, {f, 1052}, [{y, 0}, {float, 18.0}]}.
    {test, is_lt, {f, 1054}, [{y, 0}, {float, 17.0}]}.
    {move, {float, -1.2621729398885316e-14}, {x, 0}}.
    {jump, {f, 1055}}.
  {label, 1054}.
    {move, {float, -3.600176732637335e-15}, {x, 0}}.
  {label, 1055}.
    {jump, {f, 1053}}.
  {label, 1052}.
    {test, is_lt, {f, 1056}, [{y, 0}, {float, 19.0}]}.
    {move, {float, -3.600176732637335e-15}, {x, 0}}.
    {jump, {f, 1057}}.
  {label, 1056}.
    {move, {float, 1.3029797173308663e-14}, {x, 0}}.
  {label, 1057}.
  {label, 1053}.
    {jump, {f, 1051}}.
  {label, 1050}.
    {test, is_lt, {f, 1058}, [{y, 0}, {float, 22.0}]}.
    {test, is_lt, {f, 1060}, [{y, 0}, {float, 21.0}]}.
    {move, {float, 4.8230289429940886e-14}, {x, 0}}.
    {jump, {f, 1061}}.
  {label, 1060}.
    {move, {float, -2.0592242769647135e-14}, {x, 0}}.
  {label, 1061}.
    {jump, {f, 1059}}.
  {label, 1058}.
    {test, is_lt, {f, 1062}, [{y, 0}, {float, 23.0}]}.
    {move, {float, 3.149265065191484e-14}, {x, 0}}.
    {jump, {f, 1063}}.
  {label, 1062}.
    {move, {float, 4.169796584527195e-14}, {x, 0}}.
  {label, 1063}.
  {label, 1059}.
  {label, 1051}.
    {jump, {f, 1049}}.
  {label, 1048}.
    {test, is_lt, {f, 1064}, [{y, 0}, {float, 28.0}]}.
    {test, is_lt, {f, 1066}, [{y, 0}, {float, 26.0}]}.
    {test, is_lt, {f, 1068}, [{y, 0}, {float, 25.0}]}.
    {move, {float, 4.169796584527195e-14}, {x, 0}}.
    {jump, {f, 1069}}.
  {label, 1068}.
    {move, {float, 2.2477465222466186e-14}, {x, 0}}.
  {label, 1069}.
    {jump, {f, 1067}}.
  {label, 1066}.
    {test, is_lt, {f, 1070}, [{y, 0}, {float, 27.0}]}.
    {move, {float, 3.6507188831790577e-16}, {x, 0}}.
    {jump, {f, 1071}}.
  {label, 1070}.
    {move, {float, -3.827767260205414e-14}, {x, 0}}.
  {label, 1071}.
  {label, 1067}.
    {jump, {f, 1065}}.
  {label, 1064}.
    {test, is_lt, {f, 1072}, [{y, 0}, {float, 30.0}]}.
    {test, is_lt, {f, 1074}, [{y, 0}, {float, 29.0}]}.
    {move, {float, -3.827767260205414e-14}, {x, 0}}.
    {jump, {f, 1075}}.
  {label, 1074}.
    {move, {float, -4.7641388950792196e-14}, {x, 0}}.
  {label, 1075}.
    {jump, {f, 1073}}.
  {label, 1072}.
    {test, is_lt, {f, 1076}, [{y, 0}, {float, 31.0}]}.
    {move, {float, 4.9278276214647115e-14}, {x, 0}}.
    {jump, {f, 1077}}.
  {label, 1076}.
    {move, {float, 4.9485167661250996e-14}, {x, 0}}.
  {label, 1077}.
  {label, 1073}.
  {label, 1065}.
  {label, 1049}.
  {label, 1017}.
    {jump, {f, 1015}}.
  {label, 1014}.
    {test, is_lt, {f, 1078}, [{y, 0}, {float, 48.0}]}.
    {test, is_lt, {f, 1080}, [{y, 0}, {float, 40.0}]}.
    {test, is_lt, {f, 1082}, [{y, 0}, {float, 36.0}]}.
    {test, is_lt, {f, 1084}, [{y, 0}, {float, 34.0}]}.
    {test, is_lt, {f, 1086}, [{y, 0}, {float, 33.0}]}.
    {move, {float, 4.9485167661250996e-14}, {x, 0}}.
    {jump, {f, 1087}}.
  {label, 1086}.
    {move, {float, -1.5003333854266542e-14}, {x, 0}}.
  {label, 1087}.
    {jump, {f, 1085}}.
  {label, 1084}.
    {test, is_lt, {f, 1088}, [{y, 0}, {float, 35.0}]}.
    {move, {float, -2.7194441649495324e-14}, {x, 0}}.
    {jump, {f, 1089}}.
  {label, 1088}.
    {move, {float, -2.7194441649495324e-14}, {x, 0}}.
  {label, 1089}.
  {label, 1085}.
    {jump, {f, 1083}}.
  {label, 1082}.
    {test, is_lt, {f, 1090}, [{y, 0}, {float, 38.0}]}.
    {test, is_lt, {f, 1092}, [{y, 0}, {float, 37.0}]}.
    {move, {float, -2.99659267292569e-14}, {x, 0}}.
    {jump, {f, 1093}}.
  {label, 1092}.
    {move, {float, 2.0472357800461955e-14}, {x, 0}}.
  {label, 1093}.
    {jump, {f, 1091}}.
  {label, 1090}.
    {test, is_lt, {f, 1094}, [{y, 0}, {float, 39.0}]}.
    {move, {float, 2.0472357800461955e-14}, {x, 0}}.
    {jump, {f, 1095}}.
  {label, 1094}.
    {move, {float, 3.879296723063646e-15}, {x, 0}}.
  {label, 1095}.
  {label, 1091}.
  {label, 1083}.
    {jump, {f, 1081}}.
  {label, 1080}.
    {test, is_lt, {f, 1096}, [{y, 0}, {float, 44.0}]}.
    {test, is_lt, {f, 1098}, [{y, 0}, {float, 42.0}]}.
    {test, is_lt, {f, 1100}, [{y, 0}, {float, 41.0}]}.
    {move, {float, -3.6506824353335045e-14}, {x, 0}}.
    {jump, {f, 1101}}.
  {label, 1100}.
    {move, {float, -5.4183331379008994e-14}, {x, 0}}.
  {label, 1101}.
    {jump, {f, 1099}}.
  {label, 1098}.
    {test, is_lt, {f, 1102}, [{y, 0}, {float, 43.0}]}.
    {move, {float, -5.4183331379008994e-14}, {x, 0}}.
    {jump, {f, 1103}}.
  {label, 1102}.
    {move, {float, 1.1729485484531301e-14}, {x, 0}}.
  {label, 1103}.
  {label, 1099}.
    {jump, {f, 1097}}.
  {label, 1096}.
    {test, is_lt, {f, 1104}, [{y, 0}, {float, 46.0}]}.
    {test, is_lt, {f, 1106}, [{y, 0}, {float, 45.0}]}.
    {move, {float, 1.1729485484531301e-14}, {x, 0}}.
    {jump, {f, 1107}}.
  {label, 1106}.
    {move, {float, -3.811763084710266e-14}, {x, 0}}.
  {label, 1107}.
    {jump, {f, 1105}}.
  {label, 1104}.
    {test, is_lt, {f, 1108}, [{y, 0}, {float, 47.0}]}.
    {move, {float, 4.654729747598445e-14}, {x, 0}}.
    {jump, {f, 1109}}.
  {label, 1108}.
    {move, {float, 4.654729747598445e-14}, {x, 0}}.
  {label, 1109}.
  {label, 1105}.
  {label, 1097}.
  {label, 1081}.
    {jump, {f, 1079}}.
  {label, 1078}.
    {test, is_lt, {f, 1110}, [{y, 0}, {float, 56.0}]}.
    {test, is_lt, {f, 1112}, [{y, 0}, {float, 52.0}]}.
    {test, is_lt, {f, 1114}, [{y, 0}, {float, 50.0}]}.
    {test, is_lt, {f, 1116}, [{y, 0}, {float, 49.0}]}.
    {move, {float, -2.5799991283069902e-14}, {x, 0}}.
    {jump, {f, 1117}}.
  {label, 1116}.
    {move, {float, 3.7700471749674615e-14}, {x, 0}}.
  {label, 1117}.
    {jump, {f, 1115}}.
  {label, 1114}.
    {test, is_lt, {f, 1118}, [{y, 0}, {float, 51.0}]}.
    {move, {float, 3.7700471749674615e-14}, {x, 0}}.
    {jump, {f, 1119}}.
  {label, 1118}.
    {move, {float, 1.7306161136093256e-14}, {x, 0}}.
  {label, 1119}.
  {label, 1115}.
    {jump, {f, 1113}}.
  {label, 1112}.
    {test, is_lt, {f, 1120}, [{y, 0}, {float, 54.0}]}.
    {test, is_lt, {f, 1122}, [{y, 0}, {float, 53.0}]}.
    {move, {float, 1.7306161136093256e-14}, {x, 0}}.
    {jump, {f, 1123}}.
  {label, 1122}.
    {move, {float, -4.012913552726574e-14}, {x, 0}}.
  {label, 1123}.
    {jump, {f, 1121}}.
  {label, 1120}.
    {test, is_lt, {f, 1124}, [{y, 0}, {float, 55.0}]}.
    {move, {float, 2.7541708360737882e-14}, {x, 0}}.
    {jump, {f, 1125}}.
  {label, 1124}.
    {move, {float, 2.7541708360737882e-14}, {x, 0}}.
  {label, 1125}.
  {label, 1121}.
  {label, 1113}.
    {jump, {f, 1111}}.
  {label, 1110}.
    {test, is_lt, {f, 1126}, [{y, 0}, {float, 60.0}]}.
    {test, is_lt, {f, 1128}, [{y, 0}, {float, 58.0}]}.
    {test, is_lt, {f, 1130}, [{y, 0}, {float, 57.0}]}.
    {move, {float, 5.0396178134370583e-14}, {x, 0}}.
    {jump, {f, 1131}}.
  {label, 1130}.
    {move, {float, 5.0396178134370583e-14}, {x, 0}}.
  {label, 1131}.
    {jump, {f, 1129}}.
  {label, 1128}.
    {test, is_lt, {f, 1132}, [{y, 0}, {float, 59.0}]}.
    {move, {float, 1.8195060030168815e-14}, {x, 0}}.
    {jump, {f, 1133}}.
  {label, 1132}.
    {move, {float, 5.213620639136504e-14}, {x, 0}}.
  {label, 1133}.
  {label, 1129}.
    {jump, {f, 1127}}.
  {label, 1126}.
    {test, is_lt, {f, 1134}, [{y, 0}, {float, 62.0}]}.
    {test, is_lt, {f, 1136}, [{y, 0}, {float, 61.0}]}.
    {move, {float, 5.213620639136504e-14}, {x, 0}}.
    {jump, {f, 1137}}.
  {label, 1136}.
    {move, {float, 2.532168943117445e-14}, {x, 0}}.
  {label, 1137}.
    {jump, {f, 1135}}.
  {label, 1134}.
    {test, is_lt, {f, 1138}, [{y, 0}, {float, 63.0}]}.
    {move, {float, 2.532168943117445e-14}, {x, 0}}.
    {jump, {f, 1139}}.
  {label, 1138}.
    {move, {float, -5.148849572685811e-14}, {x, 0}}.
  {label, 1139}.
  {label, 1135}.
  {label, 1127}.
  {label, 1111}.
  {label, 1079}.
  {label, 1015}.
    {jump, {f, 1013}}.
  {label, 1012}.
    {test, is_lt, {f, 1140}, [{y, 0}, {float, 96.0}]}.
    {test, is_lt, {f, 1142}, [{y, 0}, {float, 80.0}]}.
    {test, is_lt, {f, 1144}, [{y, 0}, {float, 72.0}]}.
    {test, is_lt, {f, 1146}, [{y, 0}, {float, 68.0}]}.
    {test, is_lt, {f, 1148}, [{y, 0}, {float, 66.0}]}.
    {test, is_lt, {f, 1150}, [{y, 0}, {float, 65.0}]}.
    {move, {float, -5.148849572685811e-14}, {x, 0}}.
    {jump, {f, 1151}}.
  {label, 1150}.
    {move, {float, 4.6652946995830086e-15}, {x, 0}}.
  {label, 1151}.
    {jump, {f, 1149}}.
  {label, 1148}.
    {test, is_lt, {f, 1152}, [{y, 0}, {float, 67.0}]}.
    {move, {float, 4.6652946995830086e-15}, {x, 0}}.
    {jump, {f, 1153}}.
  {label, 1152}.
    {move, {float, -4.529814257790929e-14}, {x, 0}}.
  {label, 1153}.
  {label, 1149}.
    {jump, {f, 1147}}.
  {label, 1146}.
    {test, is_lt, {f, 1154}, [{y, 0}, {float, 70.0}]}.
    {test, is_lt, {f, 1156}, [{y, 0}, {float, 69.0}]}.
    {move, {float, -4.529814257790929e-14}, {x, 0}}.
    {jump, {f, 1157}}.
  {label, 1156}.
    {move, {float, -4.361324067851568e-14}, {x, 0}}.
  {label, 1157}.
    {jump, {f, 1155}}.
  {label, 1154}.
    {test, is_lt, {f, 1158}, [{y, 0}, {float, 71.0}]}.
    {move, {float, -1.7274567499706107e-15}, {x, 0}}.
    {jump, {f, 1159}}.
  {label, 1158}.
    {move, {float, -1.7274567499706107e-15}, {x, 0}}.
  {label, 1159}.
  {label, 1155}.
  {label, 1147}.
    {jump, {f, 1145}}.
  {label, 1144}.
    {test, is_lt, {f, 1160}, [{y, 0}, {float, 76.0}]}.
    {test, is_lt, {f, 1162}, [{y, 0}, {float, 74.0}]}.
    {test, is_lt, {f, 1164}, [{y, 0}, {float, 73.0}]}.
    {move, {float, -2.298941004620351e-14}, {x, 0}}.
    {jump, {f, 1165}}.
  {label, 1164}.
    {move, {float, -2.298941004620351e-14}, {x, 0}}.
  {label, 1165}.
    {jump, {f, 1163}}.
  {label, 1162}.
    {test, is_lt, {f, 1166}, [{y, 0}, {float, 75.0}]}.
    {move, {float, 0.0}, {x, 0}}.
    {jump, {f, 1167}}.
  {label, 1166}.
    {move, {float, 0.0}, {x, 0}}.
  {label, 1167}.
  {label, 1163}.
    {jump, {f, 1161}}.
  {label, 1160}.
    {test, is_lt, {f, 1168}, [{y, 0}, {float, 78.0}]}.
    {test, is_lt, {f, 1170}, [{y, 0}, {float, 77.0}]}.
    {move, {float, -1.4902732911301337e-14}, {x, 0}}.
    {jump, {f, 1171}}.
  {label, 1170}.
    {move, {float, -3.527980389655325e-14}, {x, 0}}.
  {label, 1171}.
    {jump, {f, 1169}}.
  {label, 1168}.
    {test, is_lt, {f, 1172}, [{y, 0}, {float, 79.0}]}.
    {move, {float, -4.730054772033249e-14}, {x, 0}}.
    {jump, {f, 1173}}.
  {label, 1172}.
    {move, {float, 7.580310369375161e-15}, {x, 0}}.
  {label, 1173}.
  {label, 1169}.
  {label, 1161}.
  {label, 1145}.
    {jump, {f, 1143}}.
  {label, 1142}.
    {test, is_lt, {f, 1174}, [{y, 0}, {float, 88.0}]}.
    {test, is_lt, {f, 1176}, [{y, 0}, {float, 84.0}]}.
    {test, is_lt, {f, 1178}, [{y, 0}, {float, 82.0}]}.
    {test, is_lt, {f, 1180}, [{y, 0}, {float, 81.0}]}.
    {move, {float, -4.9893776716773285e-14}, {x, 0}}.
    {jump, {f, 1181}}.
  {label, 1180}.
    {move, {float, -2.262629393030674e-14}, {x, 0}}.
  {label, 1181}.
    {jump, {f, 1179}}.
  {label, 1178}.
    {test, is_lt, {f, 1182}, [{y, 0}, {float, 83.0}]}.
    {move, {float, -2.345674491018699e-14}, {x, 0}}.
    {jump, {f, 1183}}.
  {label, 1182}.
    {move, {float, -1.3352588834854848e-14}, {x, 0}}.
  {label, 1183}.
  {label, 1179}.
    {jump, {f, 1177}}.
  {label, 1176}.
    {test, is_lt, {f, 1184}, [{y, 0}, {float, 86.0}]}.
    {test, is_lt, {f, 1186}, [{y, 0}, {float, 85.0}]}.
    {move, {float, -3.765296820388875e-14}, {x, 0}}.
    {jump, {f, 1187}}.
  {label, 1186}.
    {move, {float, 5.1128335719851986e-14}, {x, 0}}.
  {label, 1187}.
    {jump, {f, 1185}}.
  {label, 1184}.
    {test, is_lt, {f, 1188}, [{y, 0}, {float, 87.0}]}.
    {move, {float, -5.046674438470119e-14}, {x, 0}}.
    {jump, {f, 1189}}.
  {label, 1188}.
    {move, {float, 3.1218748807418837e-15}, {x, 0}}.
  {label, 1189}.
  {label, 1185}.
  {label, 1177}.
    {jump, {f, 1175}}.
  {label, 1174}.
    {test, is_lt, {f, 1190}, [{y, 0}, {float, 92.0}]}.
    {test, is_lt, {f, 1192}, [{y, 0}, {float, 90.0}]}.
    {test, is_lt, {f, 1194}, [{y, 0}, {float, 89.0}]}.
    {move, {float, 3.3871241029241416e-14}, {x, 0}}.
    {jump, {f, 1195}}.
  {label, 1194}.
    {move, {float, -1.7376727386423858e-14}, {x, 0}}.
  {label, 1195}.
    {jump, {f, 1193}}.
  {label, 1192}.
    {test, is_lt, {f, 1196}, [{y, 0}, {float, 91.0}]}.
    {move, {float, 3.957125899799804e-14}, {x, 0}}.
    {jump, {f, 1197}}.
  {label, 1196}.
    {move, {float, -5.2849453521890294e-14}, {x, 0}}.
  {label, 1197}.
  {label, 1193}.
    {jump, {f, 1191}}.
  {label, 1190}.
    {test, is_lt, {f, 1198}, [{y, 0}, {float, 94.0}]}.
    {test, is_lt, {f, 1200}, [{y, 0}, {float, 93.0}]}.
    {move, {float, -3.767012502308738e-14}, {x, 0}}.
    {jump, {f, 1201}}.
  {label, 1200}.
    {move, {float, 3.1859736349078334e-14}, {x, 0}}.
  {label, 1201}.
    {jump, {f, 1199}}.
  {label, 1198}.
    {test, is_lt, {f, 1202}, [{y, 0}, {float, 95.0}]}.
    {move, {float, 5.0900642926060466e-14}, {x, 0}}.
    {jump, {f, 1203}}.
  {label, 1202}.
    {move, {float, 8.710783796122478e-15}, {x, 0}}.
  {label, 1203}.
  {label, 1199}.
  {label, 1191}.
  {label, 1175}.
  {label, 1143}.
    {jump, {f, 1141}}.
  {label, 1140}.
    {test, is_lt, {f, 1204}, [{y, 0}, {float, 112.0}]}.
    {test, is_lt, {f, 1206}, [{y, 0}, {float, 104.0}]}.
    {test, is_lt, {f, 1208}, [{y, 0}, {float, 100.0}]}.
    {test, is_lt, {f, 1210}, [{y, 0}, {float, 98.0}]}.
    {test, is_lt, {f, 1212}, [{y, 0}, {float, 97.0}]}.
    {move, {float, 6.157896229122976e-16}, {x, 0}}.
    {jump, {f, 1213}}.
  {label, 1212}.
    {move, {float, 3.821577743916796e-14}, {x, 0}}.
  {label, 1213}.
    {jump, {f, 1211}}.
  {label, 1210}.
    {test, is_lt, {f, 1214}, [{y, 0}, {float, 99.0}]}.
    {move, {float, 3.9440046718453496e-14}, {x, 0}}.
    {jump, {f, 1215}}.
  {label, 1214}.
    {move, {float, 2.2924522154618074e-14}, {x, 0}}.
  {label, 1215}.
  {label, 1211}.
    {jump, {f, 1209}}.
  {label, 1208}.
    {test, is_lt, {f, 1216}, [{y, 0}, {float, 102.0}]}.
    {test, is_lt, {f, 1218}, [{y, 0}, {float, 101.0}]}.
    {move, {float, -3.742530094732263e-14}, {x, 0}}.
    {jump, {f, 1219}}.
  {label, 1218}.
    {move, {float, -2.5223102140407338e-14}, {x, 0}}.
  {label, 1219}.
    {jump, {f, 1217}}.
  {label, 1216}.
    {test, is_lt, {f, 1220}, [{y, 0}, {float, 103.0}]}.
    {move, {float, -1.0320443688698849e-14}, {x, 0}}.
    {jump, {f, 1221}}.
  {label, 1220}.
    {move, {float, 1.0634128304268335e-14}, {x, 0}}.
  {label, 1221}.
  {label, 1217}.
  {label, 1209}.
    {jump, {f, 1207}}.
  {label, 1206}.
    {test, is_lt, {f, 1222}, [{y, 0}, {float, 108.0}]}.
    {test, is_lt, {f, 1224}, [{y, 0}, {float, 106.0}]}.
    {test, is_lt, {f, 1226}, [{y, 0}, {float, 105.0}]}.
    {move, {float, -4.3425422595242564e-14}, {x, 0}}.
    {jump, {f, 1227}}.
  {label, 1226}.
    {move, {float, -1.2527395755711364e-14}, {x, 0}}.
  {label, 1227}.
    {jump, {f, 1225}}.
  {label, 1224}.
    {test, is_lt, {f, 1228}, [{y, 0}, {float, 107.0}]}.
    {move, {float, -5.204008743405884e-14}, {x, 0}}.
    {jump, {f, 1229}}.
  {label, 1228}.
    {move, {float, -3.979844515951702e-15}, {x, 0}}.
  {label, 1229}.
  {label, 1225}.
    {jump, {f, 1223}}.
  {label, 1222}.
    {test, is_lt, {f, 1230}, [{y, 0}, {float, 110.0}]}.
    {test, is_lt, {f, 1232}, [{y, 0}, {float, 109.0}]}.
    {move, {float, -4.7955860343296286e-14}, {x, 0}}.
    {jump, {f, 1233}}.
  {label, 1232}.
    {move, {float, 5.015686013791602e-16}, {x, 0}}.
  {label, 1233}.
    {jump, {f, 1231}}.
  {label, 1230}.
    {test, is_lt, {f, 1234}, [{y, 0}, {float, 111.0}]}.
    {move, {float, -7.252318953240293e-16}, {x, 0}}.
    {jump, {f, 1235}}.
  {label, 1234}.
    {move, {float, 2.4688324156011588e-14}, {x, 0}}.
  {label, 1235}.
  {label, 1231}.
  {label, 1223}.
  {label, 1207}.
    {jump, {f, 1205}}.
  {label, 1204}.
    {test, is_lt, {f, 1236}, [{y, 0}, {float, 120.0}]}.
    {test, is_lt, {f, 1238}, [{y, 0}, {float, 116.0}]}.
    {test, is_lt, {f, 1240}, [{y, 0}, {float, 114.0}]}.
    {test, is_lt, {f, 1242}, [{y, 0}, {float, 113.0}]}.
    {move, {float, 5.465121253624792e-15}, {x, 0}}.
    {jump, {f, 1243}}.
  {label, 1242}.
    {move, {float, 4.102651071698446e-14}, {x, 0}}.
  {label, 1243}.
    {jump, {f, 1241}}.
  {label, 1240}.
    {test, is_lt, {f, 1244}, [{y, 0}, {float, 115.0}]}.
    {move, {float, -4.996736502345936e-14}, {x, 0}}.
    {jump, {f, 1245}}.
  {label, 1244}.
    {move, {float, 4.903580708156347e-14}, {x, 0}}.
  {label, 1245}.
  {label, 1241}.
    {jump, {f, 1239}}.
  {label, 1238}.
    {test, is_lt, {f, 1246}, [{y, 0}, {float, 118.0}]}.
    {test, is_lt, {f, 1248}, [{y, 0}, {float, 117.0}]}.
    {move, {float, 5.089628039500759e-14}, {x, 0}}.
    {jump, {f, 1249}}.
  {label, 1248}.
    {move, {float, 1.1782016386565151e-14}, {x, 0}}.
  {label, 1249}.
    {jump, {f, 1247}}.
  {label, 1246}.
    {test, is_lt, {f, 1250}, [{y, 0}, {float, 119.0}]}.
    {move, {float, 4.727452940514406e-14}, {x, 0}}.
    {jump, {f, 1251}}.
  {label, 1250}.
    {move, {float, -4.4204083338755686e-14}, {x, 0}}.
  {label, 1251}.
  {label, 1247}.
  {label, 1239}.
    {jump, {f, 1237}}.
  {label, 1236}.
    {test, is_lt, {f, 1252}, [{y, 0}, {float, 124.0}]}.
    {test, is_lt, {f, 1254}, [{y, 0}, {float, 122.0}]}.
    {test, is_lt, {f, 1256}, [{y, 0}, {float, 121.0}]}.
    {move, {float, 1.548345993498083e-14}, {x, 0}}.
    {jump, {f, 1257}}.
  {label, 1256}.
    {move, {float, 2.1522127491642888e-14}, {x, 0}}.
  {label, 1257}.
    {jump, {f, 1255}}.
  {label, 1254}.
    {test, is_lt, {f, 1258}, [{y, 0}, {float, 123.0}]}.
    {move, {float, 1.1054030169005386e-14}, {x, 0}}.
    {jump, {f, 1259}}.
  {label, 1258}.
    {move, {float, -5.534326352070679e-14}, {x, 0}}.
  {label, 1259}.
  {label, 1255}.
    {jump, {f, 1253}}.
  {label, 1252}.
    {test, is_lt, {f, 1260}, [{y, 0}, {float, 126.0}]}.
    {test, is_lt, {f, 1262}, [{y, 0}, {float, 125.0}]}.
    {move, {float, -5.351646604259541e-14}, {x, 0}}.
    {jump, {f, 1263}}.
  {label, 1262}.
    {move, {float, 5.4612144489920215e-14}, {x, 0}}.
  {label, 1263}.
    {jump, {f, 1261}}.
  {label, 1260}.
    {test, is_lt, {f, 1264}, [{y, 0}, {float, 127.0}]}.
    {move, {float, 2.8136969901227338e-14}, {x, 0}}.
    {jump, {f, 1265}}.
  {label, 1264}.
    {move, {float, -1.156568624616423e-14}, {x, 0}}.
  {label, 1265}.
  {label, 1261}.
  {label, 1253}.
  {label, 1237}.
  {label, 1205}.
  {label, 1141}.
  {label, 1013}.
    {deallocate, 1}.
    return.
% 2^(j/128) rounded to the nearest double (`__exp_data.tab[2j + 1]` with
% its exponent bits restored).

{function, expHead, 1, 123}.
  {label, 122}.
    {line, [{location, "std@math.erl", 68}]}.
    {func_info, {atom, std@math}, {atom, expHead}, 1}.
  {label, 123}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_lt, {f, 1266}, [{y, 0}, {float, 64.0}]}.
    {test, is_lt, {f, 1268}, [{y, 0}, {float, 32.0}]}.
    {test, is_lt, {f, 1270}, [{y, 0}, {float, 16.0}]}.
    {test, is_lt, {f, 1272}, [{y, 0}, {float, 8.0}]}.
    {test, is_lt, {f, 1274}, [{y, 0}, {float, 4.0}]}.
    {test, is_lt, {f, 1276}, [{y, 0}, {float, 2.0}]}.
    {test, is_lt, {f, 1278}, [{y, 0}, {float, 1.0}]}.
    {move, {float, 1.0}, {x, 0}}.
    {jump, {f, 1279}}.
  {label, 1278}.
    {move, {float, 1.0054299011128027}, {x, 0}}.
  {label, 1279}.
    {jump, {f, 1277}}.
  {label, 1276}.
    {test, is_lt, {f, 1280}, [{y, 0}, {float, 3.0}]}.
    {move, {float, 1.0108892860517005}, {x, 0}}.
    {jump, {f, 1281}}.
  {label, 1280}.
    {move, {float, 1.016378314910953}, {x, 0}}.
  {label, 1281}.
  {label, 1277}.
    {jump, {f, 1275}}.
  {label, 1274}.
    {test, is_lt, {f, 1282}, [{y, 0}, {float, 6.0}]}.
    {test, is_lt, {f, 1284}, [{y, 0}, {float, 5.0}]}.
    {move, {float, 1.0218971486541166}, {x, 0}}.
    {jump, {f, 1285}}.
  {label, 1284}.
    {move, {float, 1.0274459491187637}, {x, 0}}.
  {label, 1285}.
    {jump, {f, 1283}}.
  {label, 1282}.
    {test, is_lt, {f, 1286}, [{y, 0}, {float, 7.0}]}.
    {move, {float, 1.0330248790212284}, {x, 0}}.
    {jump, {f, 1287}}.
  {label, 1286}.
    {move, {float, 1.0386341019613787}, {x, 0}}.
  {label, 1287}.
  {label, 1283}.
  {label, 1275}.
    {jump, {f, 1273}}.
  {label, 1272}.
    {test, is_lt, {f, 1288}, [{y, 0}, {float, 12.0}]}.
    {test, is_lt, {f, 1290}, [{y, 0}, {float, 10.0}]}.
    {test, is_lt, {f, 1292}, [{y, 0}, {float, 9.0}]}.
    {move, {float, 1.0442737824274138}, {x, 0}}.
    {jump, {f, 1293}}.
  {label, 1292}.
    {move, {float, 1.0499440858006872}, {x, 0}}.
  {label, 1293}.
    {jump, {f, 1291}}.
  {label, 1290}.
    {test, is_lt, {f, 1294}, [{y, 0}, {float, 11.0}]}.
    {move, {float, 1.0556451783605572}, {x, 0}}.
    {jump, {f, 1295}}.
  {label, 1294}.
    {move, {float, 1.061377227289262}, {x, 0}}.
  {label, 1295}.
  {label, 1291}.
    {jump, {f, 1289}}.
  {label, 1288}.
    {test, is_lt, {f, 1296}, [{y, 0}, {float, 14.0}]}.
    {test, is_lt, {f, 1298}, [{y, 0}, {float, 13.0}]}.
    {move, {float, 1.0671404006768237}, {x, 0}}.
    {jump, {f, 1299}}.
  {label, 1298}.
    {move, {float, 1.0729348675259756}, {x, 0}}.
  {label, 1299}.
    {jump, {f, 1297}}.
  {label, 1296}.
    {test, is_lt, {f, 1300}, [{y, 0}, {float, 15.0}]}.
    {move, {float, 1.0787607977571199}, {x, 0}}.
    {jump, {f, 1301}}.
  {label, 1300}.
    {move, {float, 1.0846183622133092}, {x, 0}}.
  {label, 1301}.
  {label, 1297}.
  {label, 1289}.
  {label, 1273}.
    {jump, {f, 1271}}.
  {label, 1270}.
    {test, is_lt, {f, 1302}, [{y, 0}, {float, 24.0}]}.
    {test, is_lt, {f, 1304}, [{y, 0}, {float, 20.0}]}.
    {test, is_lt, {f, 1306}, [{y, 0}, {float, 18.0}]}.
    {test, is_lt, {f, 1308}, [{y, 0}, {float, 17.0}]}.
    {move, {float, 1.0905077326652577}, {x, 0}}.
    {jump, {f, 1309}}.
  {label, 1308}.
    {move, {float, 1.0964290818163769}, {x, 0}}.
  {label, 1309}.
    {jump, {f, 1307}}.
  {label, 1306}.
    {test, is_lt, {f, 1310}, [{y, 0}, {float, 19.0}]}.
    {move, {float, 1.102382583307841}, {x, 0}}.
    {jump, {f, 1311}}.
  {label, 1310}.
    {move, {float, 1.1083684117236787}, {x, 0}}.
  {label, 1311}.
  {label, 1307}.
    {jump, {f, 1305}}.
  {label, 1304}.
    {test, is_lt, {f, 1312}, [{y, 0}, {float, 22.0}]}.
    {test, is_lt, {f, 1314}, [{y, 0}, {float, 21.0}]}.
    {move, {float, 1.1143867425958924}, {x, 0}}.
    {jump, {f, 1315}}.
  {label, 1314}.
    {move, {float, 1.1204377524096067}, {x, 0}}.
  {label, 1315}.
    {jump, {f, 1313}}.
  {label, 1312}.
    {test, is_lt, {f, 1316}, [{y, 0}, {float, 23.0}]}.
    {move, {float, 1.1265216186082418}, {x, 0}}.
    {jump, {f, 1317}}.
  {label, 1316}.
    {move, {float, 1.1326385195987192}, {x, 0}}.
  {label, 1317}.
  {label, 1313}.
  {label, 1305}.
    {jump, {f, 1303}}.
  {label, 1302}.
    {test, is_lt, {f, 1318}, [{y, 0}, {float, 28.0}]}.
    {test, is_lt, {f, 1320}, [{y, 0}, {float, 26.0}]}.
    {test, is_lt, {f, 1322}, [{y, 0}, {float, 25.0}]}.
    {move, {float, 1.1387886347566916}, {x, 0}}.
    {jump, {f, 1323}}.
  {label, 1322}.
    {move, {float, 1.1449721444318042}, {x, 0}}.
  {label, 1323}.
    {jump, {f, 1321}}.
  {label, 1320}.
    {test, is_lt, {f, 1324}, [{y, 0}, {float, 27.0}]}.
    {move, {float, 1.1511892299529827}, {x, 0}}.
    {jump, {f, 1325}}.
  {label, 1324}.
    {move, {float, 1.1574400736337511}, {x, 0}}.
  {label, 1325}.
  {label, 1321}.
    {jump, {f, 1319}}.
  {label, 1318}.
    {test, is_lt, {f, 1326}, [{y, 0}, {float, 30.0}]}.
    {test, is_lt, {f, 1328}, [{y, 0}, {float, 29.0}]}.
    {move, {float, 1.1637248587775775}, {x, 0}}.
    {jump, {f, 1329}}.
  {label, 1328}.
    {move, {float, 1.1700437696832502}, {x, 0}}.
  {label, 1329}.
    {jump, {f, 1327}}.
  {label, 1326}.
    {test, is_lt, {f, 1330}, [{y, 0}, {float, 31.0}]}.
    {move, {float, 1.1763969916502812}, {x, 0}}.
    {jump, {f, 1331}}.
  {label, 1330}.
    {move, {float, 1.182784710984341}, {x, 0}}.
  {label, 1331}.
  {label, 1327}.
  {label, 1319}.
  {label, 1303}.
  {label, 1271}.
    {jump, {f, 1269}}.
  {label, 1268}.
    {test, is_lt, {f, 1332}, [{y, 0}, {float, 48.0}]}.
    {test, is_lt, {f, 1334}, [{y, 0}, {float, 40.0}]}.
    {test, is_lt, {f, 1336}, [{y, 0}, {float, 36.0}]}.
    {test, is_lt, {f, 1338}, [{y, 0}, {float, 34.0}]}.
    {test, is_lt, {f, 1340}, [{y, 0}, {float, 33.0}]}.
    {move, {float, 1.189207115002721}, {x, 0}}.
    {jump, {f, 1341}}.
  {label, 1340}.
    {move, {float, 1.1956643920398273}, {x, 0}}.
  {label, 1341}.
    {jump, {f, 1339}}.
  {label, 1338}.
    {test, is_lt, {f, 1342}, [{y, 0}, {float, 35.0}]}.
    {move, {float, 1.202156731452703}, {x, 0}}.
    {jump, {f, 1343}}.
  {label, 1342}.
    {move, {float, 1.2086843236265816}, {x, 0}}.
  {label, 1343}.
  {label, 1339}.
    {jump, {f, 1337}}.
  {label, 1336}.
    {test, is_lt, {f, 1344}, [{y, 0}, {float, 38.0}]}.
    {test, is_lt, {f, 1346}, [{y, 0}, {float, 37.0}]}.
    {move, {float, 1.215247359980469}, {x, 0}}.
    {jump, {f, 1347}}.
  {label, 1346}.
    {move, {float, 1.2218460329727576}, {x, 0}}.
  {label, 1347}.
    {jump, {f, 1345}}.
  {label, 1344}.
    {test, is_lt, {f, 1348}, [{y, 0}, {float, 39.0}]}.
    {move, {float, 1.22848053610687}, {x, 0}}.
    {jump, {f, 1349}}.
  {label, 1348}.
    {move, {float, 1.2351510639369334}, {x, 0}}.
  {label, 1349}.
  {label, 1345}.
  {label, 1337}.
    {jump, {f, 1335}}.
  {label, 1334}.
    {test, is_lt, {f, 1350}, [{y, 0}, {float, 44.0}]}.
    {test, is_lt, {f, 1352}, [{y, 0}, {float, 42.0}]}.
    {test, is_lt, {f, 1354}, [{y, 0}, {float, 41.0}]}.
    {move, {float, 1.241857812073484}, {x, 0}}.
    {jump, {f, 1355}}.
  {label, 1354}.
    {move, {float, 1.2486009771892048}, {x, 0}}.
  {label, 1355}.
    {jump, {f, 1353}}.
  {label, 1352}.
    {test, is_lt, {f, 1356}, [{y, 0}, {float, 43.0}]}.
    {move, {float, 1.255380757024691}, {x, 0}}.
    {jump, {f, 1357}}.
  {label, 1356}.
    {move, {float, 1.2621973503942507}, {x, 0}}.
  {label, 1357}.
  {label, 1353}.
    {jump, {f, 1351}}.
  {label, 1350}.
    {test, is_lt, {f, 1358}, [{y, 0}, {float, 46.0}]}.
    {test, is_lt, {f, 1360}, [{y, 0}, {float, 45.0}]}.
    {move, {float, 1.2690509571917332}, {x, 0}}.
    {jump, {f, 1361}}.
  {label, 1360}.
    {move, {float, 1.275941778396392}, {x, 0}}.
  {label, 1361}.
    {jump, {f, 1359}}.
  {label, 1358}.
    {test, is_lt, {f, 1362}, [{y, 0}, {float, 47.0}]}.
    {move, {float, 1.2828700160787783}, {x, 0}}.
    {jump, {f, 1363}}.
  {label, 1362}.
    {move, {float, 1.2898358734066657}, {x, 0}}.
  {label, 1363}.
  {label, 1359}.
  {label, 1351}.
  {label, 1335}.
    {jump, {f, 1333}}.
  {label, 1332}.
    {test, is_lt, {f, 1364}, [{y, 0}, {float, 56.0}]}.
    {test, is_lt, {f, 1366}, [{y, 0}, {float, 52.0}]}.
    {test, is_lt, {f, 1368}, [{y, 0}, {float, 50.0}]}.
    {test, is_lt, {f, 1370}, [{y, 0}, {float, 49.0}]}.
    {move, {float, 1.2968395546510096}, {x, 0}}.
    {jump, {f, 1371}}.
  {label, 1370}.
    {move, {float, 1.3038812651919358}, {x, 0}}.
  {label, 1371}.
    {jump, {f, 1369}}.
  {label, 1368}.
    {test, is_lt, {f, 1372}, [{y, 0}, {float, 51.0}]}.
    {move, {float, 1.3109612115247644}, {x, 0}}.
    {jump, {f, 1373}}.
  {label, 1372}.
    {move, {float, 1.318079601266064}, {x, 0}}.
  {label, 1373}.
  {label, 1369}.
    {jump, {f, 1367}}.
  {label, 1366}.
    {test, is_lt, {f, 1374}, [{y, 0}, {float, 54.0}]}.
    {test, is_lt, {f, 1376}, [{y, 0}, {float, 53.0}]}.
    {move, {float, 1.3252366431597413}, {x, 0}}.
    {jump, {f, 1377}}.
  {label, 1376}.
    {move, {float, 1.3324325470831615}, {x, 0}}.
  {label, 1377}.
    {jump, {f, 1375}}.
  {label, 1374}.
    {test, is_lt, {f, 1378}, [{y, 0}, {float, 55.0}]}.
    {move, {float, 1.339667524053303}, {x, 0}}.
    {jump, {f, 1379}}.
  {label, 1378}.
    {move, {float, 1.3469417862329458}, {x, 0}}.
  {label, 1379}.
  {label, 1375}.
  {label, 1367}.
    {jump, {f, 1365}}.
  {label, 1364}.
    {test, is_lt, {f, 1380}, [{y, 0}, {float, 60.0}]}.
    {test, is_lt, {f, 1382}, [{y, 0}, {float, 58.0}]}.
    {test, is_lt, {f, 1384}, [{y, 0}, {float, 57.0}]}.
    {move, {float, 1.3542555469368927}, {x, 0}}.
    {jump, {f, 1385}}.
  {label, 1384}.
    {move, {float, 1.3616090206382248}, {x, 0}}.
  {label, 1385}.
    {jump, {f, 1383}}.
  {label, 1382}.
    {test, is_lt, {f, 1386}, [{y, 0}, {float, 59.0}]}.
    {move, {float, 1.3690024229745905}, {x, 0}}.
    {jump, {f, 1387}}.
  {label, 1386}.
    {move, {float, 1.3764359707545302}, {x, 0}}.
  {label, 1387}.
  {label, 1383}.
    {jump, {f, 1381}}.
  {label, 1380}.
    {test, is_lt, {f, 1388}, [{y, 0}, {float, 62.0}]}.
    {test, is_lt, {f, 1390}, [{y, 0}, {float, 61.0}]}.
    {move, {float, 1.383909881963832}, {x, 0}}.
    {jump, {f, 1391}}.
  {label, 1390}.
    {move, {float, 1.3914243757719262}, {x, 0}}.
  {label, 1391}.
    {jump, {f, 1389}}.
  {label, 1388}.
    {test, is_lt, {f, 1392}, [{y, 0}, {float, 63.0}]}.
    {move, {float, 1.3989796725383112}, {x, 0}}.
    {jump, {f, 1393}}.
  {label, 1392}.
    {move, {float, 1.4065759938190154}, {x, 0}}.
  {label, 1393}.
  {label, 1389}.
  {label, 1381}.
  {label, 1365}.
  {label, 1333}.
  {label, 1269}.
    {jump, {f, 1267}}.
  {label, 1266}.
    {test, is_lt, {f, 1394}, [{y, 0}, {float, 96.0}]}.
    {test, is_lt, {f, 1396}, [{y, 0}, {float, 80.0}]}.
    {test, is_lt, {f, 1398}, [{y, 0}, {float, 72.0}]}.
    {test, is_lt, {f, 1400}, [{y, 0}, {float, 68.0}]}.
    {test, is_lt, {f, 1402}, [{y, 0}, {float, 66.0}]}.
    {test, is_lt, {f, 1404}, [{y, 0}, {float, 65.0}]}.
    {move, {float, 1.4142135623730951}, {x, 0}}.
    {jump, {f, 1405}}.
  {label, 1404}.
    {move, {float, 1.4218926021691656}, {x, 0}}.
  {label, 1405}.
    {jump, {f, 1403}}.
  {label, 1402}.
    {test, is_lt, {f, 1406}, [{y, 0}, {float, 67.0}]}.
    {move, {float, 1.42961333839197}, {x, 0}}.
    {jump, {f, 1407}}.
  {label, 1406}.
    {move, {float, 1.4373759974489824}, {x, 0}}.
  {label, 1407}.
  {label, 1403}.
    {jump, {f, 1401}}.
  {label, 1400}.
    {test, is_lt, {f, 1408}, [{y, 0}, {float, 70.0}]}.
    {test, is_lt, {f, 1410}, [{y, 0}, {float, 69.0}]}.
    {move, {float, 1.4451808069770467}, {x, 0}}.
    {jump, {f, 1411}}.
  {label, 1410}.
    {move, {float, 1.4530279958490526}, {x, 0}}.
  {label, 1411}.
    {jump, {f, 1409}}.
  {label, 1408}.
    {test, is_lt, {f, 1412}, [{y, 0}, {float, 71.0}]}.
    {move, {float, 1.460917794180647}, {x, 0}}.
    {jump, {f, 1413}}.
  {label, 1412}.
    {move, {float, 1.4688504333369818}, {x, 0}}.
  {label, 1413}.
  {label, 1409}.
  {label, 1401}.
    {jump, {f, 1399}}.
  {label, 1398}.
    {test, is_lt, {f, 1414}, [{y, 0}, {float, 76.0}]}.
    {test, is_lt, {f, 1416}, [{y, 0}, {float, 74.0}]}.
    {test, is_lt, {f, 1418}, [{y, 0}, {float, 73.0}]}.
    {move, {float, 1.4768261459394993}, {x, 0}}.
    {jump, {f, 1419}}.
  {label, 1418}.
    {move, {float, 1.4848451658727524}, {x, 0}}.
  {label, 1419}.
    {jump, {f, 1417}}.
  {label, 1416}.
    {test, is_lt, {f, 1420}, [{y, 0}, {float, 75.0}]}.
    {move, {float, 1.4929077282912648}, {x, 0}}.
    {jump, {f, 1421}}.
  {label, 1420}.
    {move, {float, 1.5010140696264256}, {x, 0}}.
  {label, 1421}.
  {label, 1417}.
    {jump, {f, 1415}}.
  {label, 1414}.
    {test, is_lt, {f, 1422}, [{y, 0}, {float, 78.0}]}.
    {test, is_lt, {f, 1424}, [{y, 0}, {float, 77.0}]}.
    {move, {float, 1.5091644275934228}, {x, 0}}.
    {jump, {f, 1425}}.
  {label, 1424}.
    {move, {float, 1.5173590411982147}, {x, 0}}.
  {label, 1425}.
    {jump, {f, 1423}}.
  {label, 1422}.
    {test, is_lt, {f, 1426}, [{y, 0}, {float, 79.0}]}.
    {move, {float, 1.5255981507445384}, {x, 0}}.
    {jump, {f, 1427}}.
  {label, 1426}.
    {move, {float, 1.533881997840956}, {x, 0}}.
  {label, 1427}.
  {label, 1423}.
  {label, 1415}.
  {label, 1399}.
    {jump, {f, 1397}}.
  {label, 1396}.
    {test, is_lt, {f, 1428}, [{y, 0}, {float, 88.0}]}.
    {test, is_lt, {f, 1430}, [{y, 0}, {float, 84.0}]}.
    {test, is_lt, {f, 1432}, [{y, 0}, {float, 82.0}]}.
    {test, is_lt, {f, 1434}, [{y, 0}, {float, 81.0}]}.
    {move, {float, 1.5422108254079407}, {x, 0}}.
    {jump, {f, 1435}}.
  {label, 1434}.
    {move, {float, 1.550584877685}, {x, 0}}.
  {label, 1435}.
    {jump, {f, 1433}}.
  {label, 1432}.
    {test, is_lt, {f, 1436}, [{y, 0}, {float, 83.0}]}.
    {move, {float, 1.559004400237837}, {x, 0}}.
    {jump, {f, 1437}}.
  {label, 1436}.
    {move, {float, 1.567469639965553}, {x, 0}}.
  {label, 1437}.
  {label, 1433}.
    {jump, {f, 1431}}.
  {label, 1430}.
    {test, is_lt, {f, 1438}, [{y, 0}, {float, 86.0}]}.
    {test, is_lt, {f, 1440}, [{y, 0}, {float, 85.0}]}.
    {move, {float, 1.5759808451078865}, {x, 0}}.
    {jump, {f, 1441}}.
  {label, 1440}.
    {move, {float, 1.5845382652524937}, {x, 0}}.
  {label, 1441}.
    {jump, {f, 1439}}.
  {label, 1438}.
    {test, is_lt, {f, 1442}, [{y, 0}, {float, 87.0}]}.
    {move, {float, 1.593142151342267}, {x, 0}}.
    {jump, {f, 1443}}.
  {label, 1442}.
    {move, {float, 1.6017927556826934}, {x, 0}}.
  {label, 1443}.
  {label, 1439}.
  {label, 1431}.
    {jump, {f, 1429}}.
  {label, 1428}.
    {test, is_lt, {f, 1444}, [{y, 0}, {float, 92.0}]}.
    {test, is_lt, {f, 1446}, [{y, 0}, {float, 90.0}]}.
    {test, is_lt, {f, 1448}, [{y, 0}, {float, 89.0}]}.
    {move, {float, 1.6104903319492543}, {x, 0}}.
    {jump, {f, 1449}}.
  {label, 1448}.
    {move, {float, 1.6192351351948637}, {x, 0}}.
  {label, 1449}.
    {jump, {f, 1447}}.
  {label, 1446}.
    {test, is_lt, {f, 1450}, [{y, 0}, {float, 91.0}]}.
    {move, {float, 1.6280274218573478}, {x, 0}}.
    {jump, {f, 1451}}.
  {label, 1450}.
    {move, {float, 1.6368674497669644}, {x, 0}}.
  {label, 1451}.
  {label, 1447}.
    {jump, {f, 1445}}.
  {label, 1444}.
    {test, is_lt, {f, 1452}, [{y, 0}, {float, 94.0}]}.
    {test, is_lt, {f, 1454}, [{y, 0}, {float, 93.0}]}.
    {move, {float, 1.645755478153965}, {x, 0}}.
    {jump, {f, 1455}}.
  {label, 1454}.
    {move, {float, 1.6546917676561943}, {x, 0}}.
  {label, 1455}.
    {jump, {f, 1453}}.
  {label, 1452}.
    {test, is_lt, {f, 1456}, [{y, 0}, {float, 95.0}]}.
    {move, {float, 1.6636765803267364}, {x, 0}}.
    {jump, {f, 1457}}.
  {label, 1456}.
    {move, {float, 1.6727101796415966}, {x, 0}}.
  {label, 1457}.
  {label, 1453}.
  {label, 1445}.
  {label, 1429}.
  {label, 1397}.
    {jump, {f, 1395}}.
  {label, 1394}.
    {test, is_lt, {f, 1458}, [{y, 0}, {float, 112.0}]}.
    {test, is_lt, {f, 1460}, [{y, 0}, {float, 104.0}]}.
    {test, is_lt, {f, 1462}, [{y, 0}, {float, 100.0}]}.
    {test, is_lt, {f, 1464}, [{y, 0}, {float, 98.0}]}.
    {test, is_lt, {f, 1466}, [{y, 0}, {float, 97.0}]}.
    {move, {float, 1.681792830507429}, {x, 0}}.
    {jump, {f, 1467}}.
  {label, 1466}.
    {move, {float, 1.6909247992693053}, {x, 0}}.
  {label, 1467}.
    {jump, {f, 1465}}.
  {label, 1464}.
    {test, is_lt, {f, 1468}, [{y, 0}, {float, 99.0}]}.
    {move, {float, 1.7001063537185235}, {x, 0}}.
    {jump, {f, 1469}}.
  {label, 1468}.
    {move, {float, 1.709337763100463}, {x, 0}}.
  {label, 1469}.
  {label, 1465}.
    {jump, {f, 1463}}.
  {label, 1462}.
    {test, is_lt, {f, 1470}, [{y, 0}, {float, 102.0}]}.
    {test, is_lt, {f, 1472}, [{y, 0}, {float, 101.0}]}.
    {move, {float, 1.718619298122478}, {x, 0}}.
    {jump, {f, 1473}}.
  {label, 1472}.
    {move, {float, 1.7279512309618377}, {x, 0}}.
  {label, 1473}.
    {jump, {f, 1471}}.
  {label, 1470}.
    {test, is_lt, {f, 1474}, [{y, 0}, {float, 103.0}]}.
    {move, {float, 1.7373338352737062}, {x, 0}}.
    {jump, {f, 1475}}.
  {label, 1474}.
    {move, {float, 1.746767386199169}, {x, 0}}.
  {label, 1475}.
  {label, 1471}.
  {label, 1463}.
    {jump, {f, 1461}}.
  {label, 1460}.
    {test, is_lt, {f, 1476}, [{y, 0}, {float, 108.0}]}.
    {test, is_lt, {f, 1478}, [{y, 0}, {float, 106.0}]}.
    {test, is_lt, {f, 1480}, [{y, 0}, {float, 105.0}]}.
    {move, {float, 1.7562521603732995}, {x, 0}}.
    {jump, {f, 1481}}.
  {label, 1480}.
    {move, {float, 1.7657884359332727}, {x, 0}}.
  {label, 1481}.
    {jump, {f, 1479}}.
  {label, 1478}.
    {test, is_lt, {f, 1482}, [{y, 0}, {float, 107.0}]}.
    {move, {float, 1.7753764925265212}, {x, 0}}.
    {jump, {f, 1483}}.
  {label, 1482}.
    {move, {float, 1.785016611318935}, {x, 0}}.
  {label, 1483}.
  {label, 1479}.
    {jump, {f, 1477}}.
  {label, 1476}.
    {test, is_lt, {f, 1484}, [{y, 0}, {float, 110.0}]}.
    {test, is_lt, {f, 1486}, [{y, 0}, {float, 109.0}]}.
    {move, {float, 1.7947090750031072}, {x, 0}}.
    {jump, {f, 1487}}.
  {label, 1486}.
    {move, {float, 1.804454167806624}, {x, 0}}.
  {label, 1487}.
    {jump, {f, 1485}}.
  {label, 1484}.
    {test, is_lt, {f, 1488}, [{y, 0}, {float, 111.0}]}.
    {move, {float, 1.8142521755003989}, {x, 0}}.
    {jump, {f, 1489}}.
  {label, 1488}.
    {move, {float, 1.8241033854070534}, {x, 0}}.
  {label, 1489}.
  {label, 1485}.
  {label, 1477}.
  {label, 1461}.
    {jump, {f, 1459}}.
  {label, 1458}.
    {test, is_lt, {f, 1490}, [{y, 0}, {float, 120.0}]}.
    {test, is_lt, {f, 1492}, [{y, 0}, {float, 116.0}]}.
    {test, is_lt, {f, 1494}, [{y, 0}, {float, 114.0}]}.
    {test, is_lt, {f, 1496}, [{y, 0}, {float, 113.0}]}.
    {move, {float, 1.8340080864093424}, {x, 0}}.
    {jump, {f, 1497}}.
  {label, 1496}.
    {move, {float, 1.843966568958626}, {x, 0}}.
  {label, 1497}.
    {jump, {f, 1495}}.
  {label, 1494}.
    {test, is_lt, {f, 1498}, [{y, 0}, {float, 115.0}]}.
    {move, {float, 1.8539791250833855}, {x, 0}}.
    {jump, {f, 1499}}.
  {label, 1498}.
    {move, {float, 1.864046048397789}, {x, 0}}.
  {label, 1499}.
  {label, 1495}.
    {jump, {f, 1493}}.
  {label, 1492}.
    {test, is_lt, {f, 1500}, [{y, 0}, {float, 118.0}]}.
    {test, is_lt, {f, 1502}, [{y, 0}, {float, 117.0}]}.
    {move, {float, 1.8741676341103}, {x, 0}}.
    {jump, {f, 1503}}.
  {label, 1502}.
    {move, {float, 1.8843441790323345}, {x, 0}}.
  {label, 1503}.
    {jump, {f, 1501}}.
  {label, 1500}.
    {test, is_lt, {f, 1504}, [{y, 0}, {float, 119.0}]}.
    {move, {float, 1.8945759815869656}, {x, 0}}.
    {jump, {f, 1505}}.
  {label, 1504}.
    {move, {float, 1.9048633418176741}, {x, 0}}.
  {label, 1505}.
  {label, 1501}.
  {label, 1493}.
    {jump, {f, 1491}}.
  {label, 1490}.
    {test, is_lt, {f, 1506}, [{y, 0}, {float, 124.0}]}.
    {test, is_lt, {f, 1508}, [{y, 0}, {float, 122.0}]}.
    {test, is_lt, {f, 1510}, [{y, 0}, {float, 121.0}]}.
    {move, {float, 1.9152065613971474}, {x, 0}}.
    {jump, {f, 1511}}.
  {label, 1510}.
    {move, {float, 1.925605943636125}, {x, 0}}.
  {label, 1511}.
    {jump, {f, 1509}}.
  {label, 1508}.
    {test, is_lt, {f, 1512}, [{y, 0}, {float, 123.0}]}.
    {move, {float, 1.9360617934922943}, {x, 0}}.
    {jump, {f, 1513}}.
  {label, 1512}.
    {move, {float, 1.9465744175792332}, {x, 0}}.
  {label, 1513}.
  {label, 1509}.
    {jump, {f, 1507}}.
  {label, 1506}.
    {test, is_lt, {f, 1514}, [{y, 0}, {float, 126.0}]}.
    {test, is_lt, {f, 1516}, [{y, 0}, {float, 125.0}]}.
    {move, {float, 1.9571441241754002}, {x, 0}}.
    {jump, {f, 1517}}.
  {label, 1516}.
    {move, {float, 1.9677712232331759}, {x, 0}}.
  {label, 1517}.
    {jump, {f, 1515}}.
  {label, 1514}.
    {test, is_lt, {f, 1518}, [{y, 0}, {float, 127.0}]}.
    {move, {float, 1.978456026387951}, {x, 0}}.
    {jump, {f, 1519}}.
  {label, 1518}.
    {move, {float, 1.9891988469672663}, {x, 0}}.
  {label, 1519}.
  {label, 1515}.
  {label, 1507}.
  {label, 1491}.
  {label, 1459}.
  {label, 1395}.
  {label, 1267}.
    {deallocate, 1}.
    return.
% `__exp_data.tab[2j]`: 2^(j/128) / expHead(j) − 1.

{function, expTail, 1, 125}.
  {label, 124}.
    {line, [{location, "std@math.erl", 69}]}.
    {func_info, {atom, std@math}, {atom, expTail}, 1}.
  {label, 125}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_lt, {f, 1520}, [{y, 0}, {float, 64.0}]}.
    {test, is_lt, {f, 1522}, [{y, 0}, {float, 32.0}]}.
    {test, is_lt, {f, 1524}, [{y, 0}, {float, 16.0}]}.
    {test, is_lt, {f, 1526}, [{y, 0}, {float, 8.0}]}.
    {test, is_lt, {f, 1528}, [{y, 0}, {float, 4.0}]}.
    {test, is_lt, {f, 1530}, [{y, 0}, {float, 2.0}]}.
    {test, is_lt, {f, 1532}, [{y, 0}, {float, 1.0}]}.
    {move, {float, 0.0}, {x, 0}}.
    {jump, {f, 1533}}.
  {label, 1532}.
    {move, {float, 9.447885451727066e-17}, {x, 0}}.
  {label, 1533}.
    {jump, {f, 1531}}.
  {label, 1530}.
    {test, is_lt, {f, 1534}, [{y, 0}, {float, 3.0}]}.
    {move, {float, -1.507066976926039e-17}, {x, 0}}.
    {jump, {f, 1535}}.
  {label, 1534}.
    {move, {float, -5.679155082825012e-17}, {x, 0}}.
  {label, 1535}.
  {label, 1531}.
    {jump, {f, 1529}}.
  {label, 1528}.
    {test, is_lt, {f, 1536}, [{y, 0}, {float, 6.0}]}.
    {test, is_lt, {f, 1538}, [{y, 0}, {float, 5.0}]}.
    {move, {float, 4.9997448722726326e-17}, {x, 0}}.
    {jump, {f, 1539}}.
  {label, 1538}.
    {move, {float, -4.823683599994895e-17}, {x, 0}}.
  {label, 1539}.
    {jump, {f, 1537}}.
  {label, 1536}.
    {test, is_lt, {f, 1540}, [{y, 0}, {float, 7.0}]}.
    {move, {float, 7.357846871247418e-18}, {x, 0}}.
    {jump, {f, 1541}}.
  {label, 1540}.
    {move, {float, 5.773230223741951e-17}, {x, 0}}.
  {label, 1541}.
  {label, 1537}.
  {label, 1529}.
    {jump, {f, 1527}}.
  {label, 1526}.
    {test, is_lt, {f, 1542}, [{y, 0}, {float, 12.0}]}.
    {test, is_lt, {f, 1544}, [{y, 0}, {float, 10.0}]}.
    {test, is_lt, {f, 1546}, [{y, 0}, {float, 9.0}]}.
    {move, {float, 8.189317638195515e-17}, {x, 0}}.
    {jump, {f, 1547}}.
  {label, 1546}.
    {move, {float, 5.326891139980878e-17}, {x, 0}}.
  {label, 1547}.
    {jump, {f, 1545}}.
  {label, 1544}.
    {test, is_lt, {f, 1548}, [{y, 0}, {float, 11.0}]}.
    {move, {float, 1.6665881442326747e-18}, {x, 0}}.
    {jump, {f, 1549}}.
  {label, 1548}.
    {move, {float, -1.128113245461828e-17}, {x, 0}}.
  {label, 1549}.
  {label, 1545}.
    {jump, {f, 1543}}.
  {label, 1542}.
    {test, is_lt, {f, 1550}, [{y, 0}, {float, 14.0}]}.
    {test, is_lt, {f, 1552}, [{y, 0}, {float, 13.0}]}.
    {move, {float, -7.402825309426177e-17}, {x, 0}}.
    {jump, {f, 1553}}.
  {label, 1552}.
    {move, {float, -3.578659767309563e-18}, {x, 0}}.
  {label, 1553}.
    {jump, {f, 1551}}.
  {label, 1550}.
    {test, is_lt, {f, 1554}, [{y, 0}, {float, 15.0}]}.
    {move, {float, -6.170654745608695e-17}, {x, 0}}.
    {jump, {f, 1555}}.
  {label, 1554}.
    {move, {float, 2.919139999949279e-17}, {x, 0}}.
  {label, 1555}.
  {label, 1551}.
  {label, 1543}.
  {label, 1527}.
    {jump, {f, 1525}}.
  {label, 1524}.
    {test, is_lt, {f, 1556}, [{y, 0}, {float, 24.0}]}.
    {test, is_lt, {f, 1558}, [{y, 0}, {float, 20.0}]}.
    {test, is_lt, {f, 1560}, [{y, 0}, {float, 18.0}]}.
    {test, is_lt, {f, 1562}, [{y, 0}, {float, 17.0}]}.
    {move, {float, -2.7939114859515733e-17}, {x, 0}}.
    {jump, {f, 1563}}.
  {label, 1562}.
    {move, {float, -5.399285355184285e-17}, {x, 0}}.
  {label, 1563}.
    {jump, {f, 1561}}.
  {label, 1560}.
    {test, is_lt, {f, 1564}, [{y, 0}, {float, 19.0}]}.
    {move, {float, 4.776959425256223e-17}, {x, 0}}.
    {jump, {f, 1565}}.
  {label, 1564}.
    {move, {float, -7.927701432338473e-17}, {x, 0}}.
  {label, 1565}.
  {label, 1561}.
    {jump, {f, 1559}}.
  {label, 1558}.
    {test, is_lt, {f, 1566}, [{y, 0}, {float, 22.0}]}.
    {test, is_lt, {f, 1568}, [{y, 0}, {float, 21.0}]}.
    {move, {float, 9.341710609905046e-17}, {x, 0}}.
    {jump, {f, 1569}}.
  {label, 1568}.
    {move, {float, -5.534520675707472e-17}, {x, 0}}.
  {label, 1569}.
    {jump, {f, 1567}}.
  {label, 1566}.
    {test, is_lt, {f, 1570}, [{y, 0}, {float, 23.0}]}.
    {move, {float, 4.585670326662351e-17}, {x, 0}}.
    {jump, {f, 1571}}.
  {label, 1570}.
    {move, {float, 2.8582430411116143e-17}, {x, 0}}.
  {label, 1571}.
  {label, 1567}.
  {label, 1559}.
    {jump, {f, 1557}}.
  {label, 1556}.
    {test, is_lt, {f, 1572}, [{y, 0}, {float, 28.0}]}.
    {test, is_lt, {f, 1574}, [{y, 0}, {float, 26.0}]}.
    {test, is_lt, {f, 1576}, [{y, 0}, {float, 25.0}]}.
    {move, {float, 7.826573258636076e-17}, {x, 0}}.
    {jump, {f, 1577}}.
  {label, 1576}.
    {move, {float, 4.053626906769216e-17}, {x, 0}}.
  {label, 1577}.
    {jump, {f, 1575}}.
  {label, 1574}.
    {test, is_lt, {f, 1578}, [{y, 0}, {float, 27.0}]}.
    {move, {float, 2.823784425951061e-17}, {x, 0}}.
    {jump, {f, 1579}}.
  {label, 1578}.
    {move, {float, -7.882802262487991e-17}, {x, 0}}.
  {label, 1579}.
  {label, 1575}.
    {jump, {f, 1573}}.
  {label, 1572}.
    {test, is_lt, {f, 1580}, [{y, 0}, {float, 30.0}]}.
    {test, is_lt, {f, 1582}, [{y, 0}, {float, 29.0}]}.
    {move, {float, 3.2904726646008416e-17}, {x, 0}}.
    {jump, {f, 1583}}.
  {label, 1582}.
    {move, {float, -1.5792094703347882e-18}, {x, 0}}.
  {label, 1583}.
    {jump, {f, 1581}}.
  {label, 1580}.
    {test, is_lt, {f, 1584}, [{y, 0}, {float, 31.0}]}.
    {move, {float, 4.721368121170128e-17}, {x, 0}}.
    {jump, {f, 1585}}.
  {label, 1584}.
    {move, {float, 1.3045277096919659e-17}, {x, 0}}.
  {label, 1585}.
  {label, 1581}.
  {label, 1573}.
  {label, 1557}.
  {label, 1525}.
    {jump, {f, 1523}}.
  {label, 1522}.
    {test, is_lt, {f, 1586}, [{y, 0}, {float, 48.0}]}.
    {test, is_lt, {f, 1588}, [{y, 0}, {float, 40.0}]}.
    {test, is_lt, {f, 1590}, [{y, 0}, {float, 36.0}]}.
    {test, is_lt, {f, 1592}, [{y, 0}, {float, 34.0}]}.
    {test, is_lt, {f, 1594}, [{y, 0}, {float, 33.0}]}.
    {move, {float, 3.3484623336251524e-17}, {x, 0}}.
    {jump, {f, 1595}}.
  {label, 1594}.
    {move, {float, 3.8611199774925664e-17}, {x, 0}}.
  {label, 1595}.
    {jump, {f, 1593}}.
  {label, 1592}.
    {test, is_lt, {f, 1596}, [{y, 0}, {float, 35.0}]}.
    {move, {float, 5.527550048505249e-17}, {x, 0}}.
    {jump, {f, 1597}}.
  {label, 1596}.
    {move, {float, -3.927184172445234e-17}, {x, 0}}.
  {label, 1597}.
  {label, 1593}.
    {jump, {f, 1591}}.
  {label, 1590}.
    {test, is_lt, {f, 1598}, [{y, 0}, {float, 38.0}]}.
    {test, is_lt, {f, 1600}, [{y, 0}, {float, 37.0}]}.
    {move, {float, -6.346552106729483e-17}, {x, 0}}.
    {jump, {f, 1601}}.
  {label, 1600}.
    {move, {float, -8.684417614865944e-17}, {x, 0}}.
  {label, 1601}.
    {jump, {f, 1599}}.
  {label, 1598}.
    {test, is_lt, {f, 1602}, [{y, 0}, {float, 39.0}]}.
    {move, {float, -1.5456342819397733e-17}, {x, 0}}.
    {jump, {f, 1603}}.
  {label, 1602}.
    {move, {float, -8.70763476495455e-17}, {x, 0}}.
  {label, 1603}.
  {label, 1599}.
  {label, 1591}.
    {jump, {f, 1589}}.
  {label, 1588}.
    {test, is_lt, {f, 1604}, [{y, 0}, {float, 44.0}]}.
    {test, is_lt, {f, 1606}, [{y, 0}, {float, 42.0}]}.
    {test, is_lt, {f, 1608}, [{y, 0}, {float, 41.0}]}.
    {move, {float, 3.750854201303127e-17}, {x, 0}}.
    {jump, {f, 1609}}.
  {label, 1608}.
    {move, {float, -6.616854503526488e-17}, {x, 0}}.
  {label, 1609}.
    {jump, {f, 1607}}.
  {label, 1606}.
    {test, is_lt, {f, 1610}, [{y, 0}, {float, 43.0}]}.
    {move, {float, -5.346099009198751e-18}, {x, 0}}.
    {jump, {f, 1611}}.
  {label, 1610}.
    {move, {float, -2.443726321015018e-17}, {x, 0}}.
  {label, 1611}.
  {label, 1607}.
    {jump, {f, 1605}}.
  {label, 1604}.
    {test, is_lt, {f, 1612}, [{y, 0}, {float, 46.0}]}.
    {test, is_lt, {f, 1614}, [{y, 0}, {float, 45.0}]}.
    {move, {float, 2.1023049675215714e-18}, {x, 0}}.
    {jump, {f, 1615}}.
  {label, 1614}.
    {move, {float, 7.771067937501065e-17}, {x, 0}}.
  {label, 1615}.
    {jump, {f, 1613}}.
  {label, 1612}.
    {test, is_lt, {f, 1616}, [{y, 0}, {float, 47.0}]}.
    {move, {float, 1.3357510088834541e-17}, {x, 0}}.
    {jump, {f, 1617}}.
  {label, 1616}.
    {move, {float, 6.938291696959204e-17}, {x, 0}}.
  {label, 1617}.
  {label, 1613}.
  {label, 1605}.
  {label, 1589}.
    {jump, {f, 1587}}.
  {label, 1586}.
    {test, is_lt, {f, 1618}, [{y, 0}, {float, 56.0}]}.
    {test, is_lt, {f, 1620}, [{y, 0}, {float, 52.0}]}.
    {test, is_lt, {f, 1622}, [{y, 0}, {float, 50.0}]}.
    {test, is_lt, {f, 1624}, [{y, 0}, {float, 49.0}]}.
    {move, {float, 1.9572585293112036e-17}, {x, 0}}.
    {jump, {f, 1625}}.
  {label, 1624}.
    {move, {float, 6.632256961675804e-17}, {x, 0}}.
  {label, 1625}.
    {jump, {f, 1623}}.
  {label, 1622}.
    {test, is_lt, {f, 1626}, [{y, 0}, {float, 51.0}]}.
    {move, {float, -5.478069123926778e-17}, {x, 0}}.
    {jump, {f, 1627}}.
  {label, 1626}.
    {move, {float, -4.140839310392624e-17}, {x, 0}}.
  {label, 1627}.
  {label, 1623}.
    {jump, {f, 1621}}.
  {label, 1620}.
    {test, is_lt, {f, 1628}, [{y, 0}, {float, 54.0}]}.
    {test, is_lt, {f, 1630}, [{y, 0}, {float, 53.0}]}.
    {move, {float, -2.1571477251208752e-17}, {x, 0}}.
    {jump, {f, 1631}}.
  {label, 1630}.
    {move, {float, -3.8287766552120535e-17}, {x, 0}}.
  {label, 1631}.
    {jump, {f, 1629}}.
  {label, 1628}.
    {test, is_lt, {f, 1632}, [{y, 0}, {float, 55.0}]}.
    {move, {float, 6.663804589232195e-17}, {x, 0}}.
    {jump, {f, 1633}}.
  {label, 1632}.
    {move, {float, 2.3936187400285282e-17}, {x, 0}}.
  {label, 1633}.
  {label, 1629}.
  {label, 1621}.
    {jump, {f, 1619}}.
  {label, 1618}.
    {test, is_lt, {f, 1634}, [{y, 0}, {float, 60.0}]}.
    {test, is_lt, {f, 1636}, [{y, 0}, {float, 58.0}]}.
    {test, is_lt, {f, 1638}, [{y, 0}, {float, 57.0}]}.
    {move, {float, 5.68648095791174e-17}, {x, 0}}.
    {jump, {f, 1639}}.
  {label, 1638}.
    {move, {float, 1.1264523354521684e-18}, {x, 0}}.
  {label, 1639}.
    {jump, {f, 1637}}.
  {label, 1636}.
    {test, is_lt, {f, 1640}, [{y, 0}, {float, 59.0}]}.
    {move, {float, 7.007875046906994e-17}, {x, 0}}.
    {jump, {f, 1641}}.
  {label, 1640}.
    {move, {float, -5.0119214278381254e-17}, {x, 0}}.
  {label, 1641}.
  {label, 1637}.
    {jump, {f, 1635}}.
  {label, 1634}.
    {test, is_lt, {f, 1642}, [{y, 0}, {float, 62.0}]}.
    {test, is_lt, {f, 1644}, [{y, 0}, {float, 61.0}]}.
    {move, {float, -4.8923067513522756e-17}, {x, 0}}.
    {jump, {f, 1645}}.
  {label, 1644}.
    {move, {float, -3.5260089953269434e-17}, {x, 0}}.
  {label, 1645}.
    {jump, {f, 1643}}.
  {label, 1642}.
    {test, is_lt, {f, 1646}, [{y, 0}, {float, 63.0}]}.
    {move, {float, -6.872303720902018e-17}, {x, 0}}.
    {jump, {f, 1647}}.
  {label, 1646}.
    {move, {float, 5.001446664133532e-18}, {x, 0}}.
  {label, 1647}.
  {label, 1643}.
  {label, 1635}.
  {label, 1619}.
  {label, 1587}.
  {label, 1523}.
    {jump, {f, 1521}}.
  {label, 1520}.
    {test, is_lt, {f, 1648}, [{y, 0}, {float, 96.0}]}.
    {test, is_lt, {f, 1650}, [{y, 0}, {float, 80.0}]}.
    {test, is_lt, {f, 1652}, [{y, 0}, {float, 72.0}]}.
    {test, is_lt, {f, 1654}, [{y, 0}, {float, 68.0}]}.
    {test, is_lt, {f, 1656}, [{y, 0}, {float, 66.0}]}.
    {test, is_lt, {f, 1658}, [{y, 0}, {float, 65.0}]}.
    {move, {float, -6.835808657661922e-17}, {x, 0}}.
    {jump, {f, 1659}}.
  {label, 1658}.
    {move, {float, -1.1307344092910212e-17}, {x, 0}}.
  {label, 1659}.
    {jump, {f, 1657}}.
  {label, 1656}.
    {test, is_lt, {f, 1660}, [{y, 0}, {float, 67.0}]}.
    {move, {float, -8.416011634717156e-18}, {x, 0}}.
    {jump, {f, 1661}}.
  {label, 1660}.
    {move, {float, -2.9247977035436566e-17}, {x, 0}}.
  {label, 1661}.
  {label, 1657}.
    {jump, {f, 1655}}.
  {label, 1654}.
    {test, is_lt, {f, 1662}, [{y, 0}, {float, 70.0}]}.
    {test, is_lt, {f, 1664}, [{y, 0}, {float, 69.0}]}.
    {move, {float, -2.092304381843353e-17}, {x, 0}}.
    {jump, {f, 1665}}.
  {label, 1664}.
    {move, {float, -3.9778645875427124e-17}, {x, 0}}.
  {label, 1665}.
    {jump, {f, 1663}}.
  {label, 1662}.
    {test, is_lt, {f, 1666}, [{y, 0}, {float, 71.0}]}.
    {move, {float, -3.833464968654295e-17}, {x, 0}}.
    {jump, {f, 1667}}.
  {label, 1666}.
    {move, {float, 5.763611164480894e-17}, {x, 0}}.
  {label, 1667}.
  {label, 1663}.
  {label, 1655}.
    {jump, {f, 1653}}.
  {label, 1652}.
    {test, is_lt, {f, 1668}, [{y, 0}, {float, 76.0}]}.
    {test, is_lt, {f, 1670}, [{y, 0}, {float, 74.0}]}.
    {test, is_lt, {f, 1672}, [{y, 0}, {float, 73.0}]}.
    {move, {float, -2.3591094770850053e-17}, {x, 0}}.
    {jump, {f, 1673}}.
  {label, 1672}.
    {move, {float, 7.260074661098575e-17}, {x, 0}}.
  {label, 1673}.
    {jump, {f, 1671}}.
  {label, 1670}.
    {test, is_lt, {f, 1674}, [{y, 0}, {float, 75.0}]}.
    {move, {float, 9.50689710108796e-18}, {x, 0}}.
    {jump, {f, 1675}}.
  {label, 1674}.
    {move, {float, -4.272956133839906e-17}, {x, 0}}.
  {label, 1675}.
  {label, 1671}.
    {jump, {f, 1669}}.
  {label, 1668}.
    {test, is_lt, {f, 1676}, [{y, 0}, {float, 78.0}]}.
    {test, is_lt, {f, 1678}, [{y, 0}, {float, 77.0}]}.
    {move, {float, -6.735219232374683e-17}, {x, 0}}.
    {jump, {f, 1679}}.
  {label, 1678}.
    {move, {float, -2.8396044410430936e-17}, {x, 0}}.
  {label, 1679}.
    {jump, {f, 1677}}.
  {label, 1676}.
    {test, is_lt, {f, 1680}, [{y, 0}, {float, 79.0}]}.
    {move, {float, -7.226635472101257e-17}, {x, 0}}.
    {jump, {f, 1681}}.
  {label, 1680}.
    {move, {float, 5.786121003395918e-17}, {x, 0}}.
  {label, 1681}.
  {label, 1677}.
  {label, 1669}.
  {label, 1653}.
    {jump, {f, 1651}}.
  {label, 1650}.
    {test, is_lt, {f, 1682}, [{y, 0}, {float, 88.0}]}.
    {test, is_lt, {f, 1684}, [{y, 0}, {float, 84.0}]}.
    {test, is_lt, {f, 1686}, [{y, 0}, {float, 82.0}]}.
    {test, is_lt, {f, 1688}, [{y, 0}, {float, 81.0}]}.
    {move, {float, 5.1548301170786783e-17}, {x, 0}}.
    {jump, {f, 1689}}.
  {label, 1688}.
    {move, {float, -9.416257568878152e-18}, {x, 0}}.
  {label, 1689}.
    {jump, {f, 1687}}.
  {label, 1686}.
    {test, is_lt, {f, 1690}, [{y, 0}, {float, 83.0}]}.
    {move, {float, 2.4253985766689806e-17}, {x, 0}}.
    {jump, {f, 1691}}.
  {label, 1690}.
    {move, {float, -6.604314051707707e-17}, {x, 0}}.
  {label, 1691}.
  {label, 1687}.
    {jump, {f, 1685}}.
  {label, 1684}.
    {test, is_lt, {f, 1692}, [{y, 0}, {float, 86.0}]}.
    {test, is_lt, {f, 1694}, [{y, 0}, {float, 85.0}]}.
    {move, {float, -6.432131775424189e-18}, {x, 0}}.
    {jump, {f, 1695}}.
  {label, 1694}.
    {move, {float, -1.2204007601863921e-17}, {x, 0}}.
  {label, 1695}.
    {jump, {f, 1693}}.
  {label, 1692}.
    {test, is_lt, {f, 1696}, [{y, 0}, {float, 87.0}]}.
    {move, {float, -6.336161863401293e-17}, {x, 0}}.
    {jump, {f, 1697}}.
  {label, 1696}.
    {move, {float, -3.7800879246373815e-17}, {x, 0}}.
  {label, 1697}.
  {label, 1693}.
  {label, 1685}.
    {jump, {f, 1683}}.
  {label, 1682}.
    {test, is_lt, {f, 1698}, [{y, 0}, {float, 92.0}]}.
    {test, is_lt, {f, 1700}, [{y, 0}, {float, 90.0}]}.
    {test, is_lt, {f, 1702}, [{y, 0}, {float, 89.0}]}.
    {move, {float, 1.5341410053603723e-17}, {x, 0}}.
    {jump, {f, 1703}}.
  {label, 1702}.
    {move, {float, 1.2932855580427452e-17}, {x, 0}}.
  {label, 1703}.
    {jump, {f, 1701}}.
  {label, 1700}.
    {test, is_lt, {f, 1704}, [{y, 0}, {float, 91.0}]}.
    {move, {float, -4.123367330661149e-17}, {x, 0}}.
    {jump, {f, 1705}}.
  {label, 1704}.
    {move, {float, 4.703083974463456e-17}, {x, 0}}.
  {label, 1705}.
  {label, 1701}.
    {jump, {f, 1699}}.
  {label, 1698}.
    {test, is_lt, {f, 1706}, [{y, 0}, {float, 94.0}]}.
    {test, is_lt, {f, 1708}, [{y, 0}, {float, 93.0}]}.
    {move, {float, -6.152602891550265e-17}, {x, 0}}.
    {jump, {f, 1709}}.
  {label, 1708}.
    {move, {float, 5.827849326195279e-17}, {x, 0}}.
  {label, 1709}.
    {jump, {f, 1707}}.
  {label, 1706}.
    {test, is_lt, {f, 1710}, [{y, 0}, {float, 95.0}]}.
    {move, {float, 3.540948262646183e-17}, {x, 0}}.
    {jump, {f, 1711}}.
  {label, 1710}.
    {move, {float, -3.2741571320938764e-17}, {x, 0}}.
  {label, 1711}.
  {label, 1707}.
  {label, 1699}.
  {label, 1683}.
  {label, 1651}.
    {jump, {f, 1649}}.
  {label, 1648}.
    {test, is_lt, {f, 1712}, [{y, 0}, {float, 112.0}]}.
    {test, is_lt, {f, 1714}, [{y, 0}, {float, 104.0}]}.
    {test, is_lt, {f, 1716}, [{y, 0}, {float, 100.0}]}.
    {test, is_lt, {f, 1718}, [{y, 0}, {float, 98.0}]}.
    {test, is_lt, {f, 1720}, [{y, 0}, {float, 97.0}]}.
    {move, {float, 4.875160526227062e-17}, {x, 0}}.
    {jump, {f, 1721}}.
  {label, 1720}.
    {move, {float, -5.718569790077838e-17}, {x, 0}}.
  {label, 1721}.
    {jump, {f, 1719}}.
  {label, 1718}.
    {test, is_lt, {f, 1722}, [{y, 0}, {float, 99.0}]}.
    {move, {float, -4.719539664590972e-18}, {x, 0}}.
    {jump, {f, 1723}}.
  {label, 1722}.
    {move, {float, -5.773451958805706e-17}, {x, 0}}.
  {label, 1723}.
  {label, 1719}.
    {jump, {f, 1717}}.
  {label, 1716}.
    {test, is_lt, {f, 1724}, [{y, 0}, {float, 102.0}]}.
    {test, is_lt, {f, 1726}, [{y, 0}, {float, 101.0}]}.
    {move, {float, -1.0772487078934056e-17}, {x, 0}}.
    {jump, {f, 1727}}.
  {label, 1726}.
    {move, {float, -6.221808618533911e-17}, {x, 0}}.
  {label, 1727}.
    {jump, {f, 1725}}.
  {label, 1724}.
    {test, is_lt, {f, 1728}, [{y, 0}, {float, 103.0}]}.
    {move, {float, 1.821405440362259e-17}, {x, 0}}.
    {jump, {f, 1729}}.
  {label, 1728}.
    {move, {float, -6.155536546227639e-17}, {x, 0}}.
  {label, 1729}.
  {label, 1725}.
  {label, 1717}.
    {jump, {f, 1715}}.
  {label, 1714}.
    {test, is_lt, {f, 1730}, [{y, 0}, {float, 108.0}]}.
    {test, is_lt, {f, 1732}, [{y, 0}, {float, 106.0}]}.
    {test, is_lt, {f, 1734}, [{y, 0}, {float, 105.0}]}.
    {move, {float, 1.685487290628973e-17}, {x, 0}}.
    {jump, {f, 1735}}.
  {label, 1734}.
    {move, {float, 5.3581249177694816e-17}, {x, 0}}.
  {label, 1735}.
    {jump, {f, 1733}}.
  {label, 1732}.
    {test, is_lt, {f, 1736}, [{y, 0}, {float, 107.0}]}.
    {move, {float, 3.621615935336894e-17}, {x, 0}}.
    {jump, {f, 1737}}.
  {label, 1736}.
    {move, {float, 8.588379527574144e-18}, {x, 0}}.
  {label, 1737}.
  {label, 1733}.
    {jump, {f, 1731}}.
  {label, 1730}.
    {test, is_lt, {f, 1738}, [{y, 0}, {float, 110.0}]}.
    {test, is_lt, {f, 1740}, [{y, 0}, {float, 109.0}]}.
    {move, {float, 1.01562190116415e-17}, {x, 0}}.
    {jump, {f, 1741}}.
  {label, 1740}.
    {move, {float, -2.869134889187244e-17}, {x, 0}}.
  {label, 1741}.
    {jump, {f, 1739}}.
  {label, 1738}.
    {test, is_lt, {f, 1742}, [{y, 0}, {float, 111.0}]}.
    {move, {float, -5.495118966122005e-17}, {x, 0}}.
    {jump, {f, 1743}}.
  {label, 1742}.
    {move, {float, -5.56965572431627e-17}, {x, 0}}.
  {label, 1743}.
  {label, 1739}.
  {label, 1731}.
  {label, 1715}.
    {jump, {f, 1713}}.
  {label, 1712}.
    {test, is_lt, {f, 1744}, [{y, 0}, {float, 120.0}]}.
    {test, is_lt, {f, 1746}, [{y, 0}, {float, 116.0}]}.
    {test, is_lt, {f, 1748}, [{y, 0}, {float, 114.0}]}.
    {test, is_lt, {f, 1750}, [{y, 0}, {float, 113.0}]}.
    {move, {float, 1.790126907604513e-17}, {x, 0}}.
    {jump, {f, 1751}}.
  {label, 1750}.
    {move, {float, -3.2211766346200164e-17}, {x, 0}}.
  {label, 1751}.
    {jump, {f, 1749}}.
  {label, 1748}.
    {test, is_lt, {f, 1752}, [{y, 0}, {float, 115.0}]}.
    {move, {float, 5.265370768556274e-17}, {x, 0}}.
    {jump, {f, 1753}}.
  {label, 1752}.
    {move, {float, 3.5089866402403033e-17}, {x, 0}}.
  {label, 1753}.
  {label, 1749}.
    {jump, {f, 1747}}.
  {label, 1746}.
    {test, is_lt, {f, 1754}, [{y, 0}, {float, 118.0}]}.
    {test, is_lt, {f, 1756}, [{y, 0}, {float, 117.0}]}.
    {move, {float, -3.266924100901318e-17}, {x, 0}}.
    {jump, {f, 1757}}.
  {label, 1756}.
    {move, {float, -4.3657593008079375e-17}, {x, 0}}.
  {label, 1757}.
    {jump, {f, 1755}}.
  {label, 1754}.
    {test, is_lt, {f, 1758}, [{y, 0}, {float, 119.0}]}.
    {move, {float, 1.7963932659833022e-17}, {x, 0}}.
    {jump, {f, 1759}}.
  {label, 1758}.
    {move, {float, 3.4300925275214166e-17}, {x, 0}}.
  {label, 1759}.
  {label, 1755}.
  {label, 1747}.
    {jump, {f, 1745}}.
  {label, 1744}.
    {test, is_lt, {f, 1760}, [{y, 0}, {float, 124.0}]}.
    {test, is_lt, {f, 1762}, [{y, 0}, {float, 122.0}]}.
    {test, is_lt, {f, 1764}, [{y, 0}, {float, 121.0}]}.
    {move, {float, -5.545065618639427e-17}, {x, 0}}.
    {jump, {f, 1765}}.
  {label, 1764}.
    {move, {float, -5.149009745457733e-17}, {x, 0}}.
  {label, 1765}.
    {jump, {f, 1763}}.
  {label, 1762}.
    {test, is_lt, {f, 1766}, [{y, 0}, {float, 123.0}]}.
    {move, {float, 5.336805878514151e-17}, {x, 0}}.
    {jump, {f, 1767}}.
  {label, 1766}.
    {move, {float, 3.498978661192973e-17}, {x, 0}}.
  {label, 1767}.
  {label, 1763}.
    {jump, {f, 1761}}.
  {label, 1760}.
    {test, is_lt, {f, 1768}, [{y, 0}, {float, 126.0}]}.
    {test, is_lt, {f, 1770}, [{y, 0}, {float, 125.0}]}.
    {move, {float, 4.5784915277060095e-17}, {x, 0}}.
    {jump, {f, 1771}}.
  {label, 1770}.
    {move, {float, -5.241934575393899e-17}, {x, 0}}.
  {label, 1771}.
    {jump, {f, 1769}}.
  {label, 1768}.
    {test, is_lt, {f, 1772}, [{y, 0}, {float, 127.0}]}.
    {move, {float, 2.0414278897578303e-17}, {x, 0}}.
    {jump, {f, 1773}}.
  {label, 1772}.
    {move, {float, 4.124842848606488e-18}, {x, 0}}.
  {label, 1773}.
  {label, 1769}.
  {label, 1761}.
  {label, 1745}.
  {label, 1713}.
  {label, 1649}.
  {label, 1521}.
    {deallocate, 1}.
    return.
% ── trigonometry ─────────────────────────────────────────────────────────────
% fdlibm's `__ieee754_rem_pio2` for |x| up to 2^19·π/2: `which` 0 answers the
% quadrant n, 1 and 2 the remainder's head and tail. A larger |x| needs
% `__kernel_rem_pio2`, which is not ported — refused by a panic.

{function, remPio2, 2, 127}.
  {label, 126}.
    {line, [{location, "std@math.erl", 70}]}.
    {func_info, {atom, std@math}, {atom, remPio2}, 2}.
  {label, 127}.
    {allocate, 22, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}, {y, 20}, {y, 21}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 77}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 69}}.
    {move, {x, 0}, {y, 3}}.
    {move, {float, 0.0}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {float, 0.0}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {test, is_ge, {f, 1774}, [{float, 1072243195.0}, {y, 3}]}.
    {move, {float, 0.0}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {jump, {f, 1775}}.
  {label, 1774}.
    {test, is_lt, {f, 1776}, [{y, 3}, {float, 1073928572.0}]}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq, {f, 1777}, [{x, 0}, {atom, true}]}.
    {move, {float, -1.0}, {x, 0}}.
    {jump, {f, 1778}}.
  {label, 1777}.
    {move, {float, 1.0}, {x, 0}}.
  {label, 1778}.
    {move, {x, 0}, {y, 7}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 7}, {float, 1.57079632673412561417e+00}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {test, is_ne_exact, {f, 1779}, [{y, 3}, {float, 1073291771.0}]}.
    {gc_bif, '*', {f, 0}, 0, [{y, 7}, {float, 6.07710050650619224932e-11}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 8}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 8}, {y, 5}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '*', {f, 0}, 2, [{y, 7}, {float, 6.07710050650619224932e-11}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {jump, {f, 1780}}.
  {label, 1779}.
    {gc_bif, '*', {f, 0}, 0, [{y, 7}, {float, 6.07710050630396597660e-11}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 8}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 7}, {float, 2.02226624879595063154e-21}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 8}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 8}, {y, 5}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '*', {f, 0}, 2, [{y, 7}, {float, 2.02226624879595063154e-21}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 6}}.
  {label, 1780}.
    {move, {y, 7}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {jump, {f, 1781}}.
  {label, 1776}.
    {test, is_ge, {f, 1782}, [{float, 1094263291.0}, {y, 3}]}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, abs, 1}}.
    {move, {x, 0}, {y, 9}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 9}, {float, 6.36619772367581382433e-01}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {float, 0.5}], {x, 0}}.
    {call_ext, 1, {extfunc, erlang, trunc, 1}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 4}, {float, 1.57079632673412561417e+00}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 9}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 4}, {float, 6.07710050650619224932e-11}], {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {test, is_lt, {f, 1784}, [{y, 4}, {float, 32.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1785}}.
  {label, 1784}.
    {move, {atom, false}, {x, 0}}.
  {label, 1785}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 1786}, [{x, 1}, {atom, true}]}.
    {gc_bif, '*', {f, 0}, 0, [{y, 4}, {float, 1.5707963267948966}], {x, 0}}.
    {call, 1, {f, 69}}.
    {test, is_ne_exact, {f, 1788}, [{y, 3}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1789}}.
  {label, 1788}.
    {move, {atom, false}, {x, 0}}.
  {label, 1789}.
    {jump, {f, 1787}}.
  {label, 1786}.
    {move, {atom, false}, {x, 0}}.
  {label, 1787}.
    {test, is_eq, {f, 1783}, [{x, 0}, {atom, true}]}.
    {gc_bif, '-', {f, 0}, 0, [{y, 10}, {y, 11}], {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 1790}}.
  {label, 1783}.
    {gc_bif, '/', {f, 0}, 0, [{y, 3}, {float, 1048576.0}], {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
    {move, {x, 0}, {y, 12}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 10}, {y, 11}], {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {call, 1, {f, 81}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 12}, {x, 0}], {x, 0}}.
    {test, is_lt, {f, 1791}, [{float, 16.0}, {x, 0}]}.
    {move, {y, 10}, {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 4}, {float, 6.07710050630396597660e-11}], {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 13}, {y, 11}], {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 4}, {float, 2.02226624879595063154e-21}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '-', {f, 0}, 2, [{y, 13}, {y, 10}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 2, [{x, 0}, {y, 11}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 10}, {y, 11}], {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {call, 1, {f, 81}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 12}, {x, 0}], {x, 0}}.
    {test, is_lt, {f, 1792}, [{float, 49.0}, {x, 0}]}.
    {move, {y, 10}, {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 4}, {float, 2.02226624871116645580e-21}], {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 13}, {y, 11}], {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 4}, {float, 8.47842766036889956997e-32}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '-', {f, 0}, 2, [{y, 13}, {y, 10}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 2, [{x, 0}, {y, 11}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 10}, {y, 11}], {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 1793}}.
  {label, 1792}.
  {label, 1793}.
    {jump, {f, 1794}}.
  {label, 1791}.
  {label, 1794}.
  {label, 1790}.
    {gc_bif, '-', {f, 0}, 0, [{y, 10}, {y, 5}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {y, 11}], {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq, {f, 1795}, [{x, 0}, {atom, true}]}.
    {gc_bif, '*', {f, 0}, 0, [{float, -1.0}, {y, 5}], {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {gc_bif, '*', {f, 0}, 0, [{float, -1.0}, {y, 6}], {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {gc_bif, '*', {f, 0}, 0, [{float, -1.0}, {y, 4}], {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {jump, {f, 1796}}.
  {label, 1795}.
  {label, 1796}.
    {jump, {f, 1797}}.
  {label, 1782}.
    {test, is_ge, {f, 1798}, [{y, 3}, {float, 2146435072.0}]}.
    {gc_bif, '-', {f, 0}, 0, [{y, 0}, {y, 0}], {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {jump, {f, 1799}}.
  {label, 1798}.
    {move, {literal, <<"math: a trigonometric argument beyond 2^19 \x{C2}\x{B7} \x{CF}\x{80}/2 is not reduced on wasm">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, panic}, {x, 0}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1799}.
  {label, 1797}.
  {label, 1781}.
  {label, 1775}.
    {test, is_lt, {f, 1800}, [{y, 1}, {float, 0.5}]}.
    {move, {y, 4}, {x, 0}}.
    {jump, {f, 1801}}.
  {label, 1800}.
    {test, is_lt, {f, 1802}, [{y, 1}, {float, 1.5}]}.
    {move, {y, 5}, {x, 0}}.
    {jump, {f, 1803}}.
  {label, 1802}.
    {move, {y, 6}, {x, 0}}.
  {label, 1803}.
  {label, 1801}.
    {deallocate, 22}.
    return.

{function, kernelCos, 2, 129}.
  {label, 128}.
    {line, [{location, "std@math.erl", 71}]}.
    {func_info, {atom, std@math}, {atom, kernelCos}, 2}.
  {label, 129}.
    {allocate, 8, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 69}}.
    {move, {x, 0}, {y, 2}}.
    {test, is_lt, {f, 1804}, [{y, 2}, {float, 1044381696.0}]}.
    {move, {float, 1.0}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 1804}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {y, 0}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 3}, {float, -1.13596475577881948265e-11}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, 2.08757232129817482790e-09}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 3}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, -2.75573143513906633035e-07}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 3}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, 2.48015872894767294178e-05}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 3}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, -1.38888888888741095749e-03}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 3}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, 4.16666666666666019037e-02}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 3}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {test, is_lt, {f, 1805}, [{y, 2}, {float, 1070805811.0}]}.
    {gc_bif, '*', {f, 0}, 0, [{float, 0.5}, {y, 3}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '*', {f, 0}, 2, [{y, 3}, {y, 4}], {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {gc_bif, '*', {f, 0}, 3, [{y, 0}, {y, 1}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 3, [{x, 2}, {x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{float, 1.0}, {x, 0}], {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 1805}.
    {test, is_lt, {f, 1806}, [{float, 1072234496.0}, {y, 2}]}.
    {move, {float, 0.28125}, {x, 0}}.
    {jump, {f, 1807}}.
  {label, 1806}.
    {gc_bif, '-', {f, 0}, 0, [{y, 2}, {float, 2097152.0}], {x, 0}}.
    {move, {float, 0.0}, {x, 1}}.
    {call, 2, {f, 73}}.
  {label, 1807}.
    {move, {x, 0}, {y, 5}}.
    {gc_bif, '*', {f, 0}, 0, [{float, 0.5}, {y, 3}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {y, 5}], {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {gc_bif, '-', {f, 0}, 0, [{float, 1.0}, {y, 5}], {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 3}, {y, 4}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '*', {f, 0}, 2, [{y, 0}, {y, 1}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 6}, {x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 7}, {x, 0}], {x, 0}}.
    {deallocate, 8}.
    return.

{function, kernelSin, 3, 131}.
  {label, 130}.
    {line, [{location, "std@math.erl", 72}]}.
    {func_info, {atom, std@math}, {atom, kernelSin}, 3}.
  {label, 131}.
    {allocate, 6, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 69}}.
    {test, is_lt, {f, 1808}, [{x, 0}, {float, 1044381696.0}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 1808}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {y, 0}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 3}, {y, 0}], {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 3}, {float, 1.58969099521155010221e-10}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, -2.50507602534068634195e-08}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 3}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, 2.75573137070700676789e-06}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 3}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, -1.98412698298579493134e-04}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 3}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, 8.33333333332248946124e-03}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 2}, {x, 0}}.
    {call, 1, {f, 79}}.
    {test, is_eq, {f, 1809}, [{x, 0}, {atom, true}]}.
    {gc_bif, '*', {f, 0}, 0, [{y, 3}, {y, 5}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, -1.66666666666666324348e-01}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 4}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 1809}.
    {gc_bif, '*', {f, 0}, 0, [{float, 0.5}, {y, 1}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '*', {f, 0}, 2, [{y, 4}, {y, 5}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 3}, {x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {y, 1}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '*', {f, 0}, 2, [{y, 4}, {float, -1.66666666666666324348e-01}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {deallocate, 6}.
    return.
% fdlibm's `__kernel_tan`: tan(x + y) for `iy` 1, -1/tan(x + y) for -1.

{function, kernelTan, 3, 133}.
  {label, 132}.
    {line, [{location, "std@math.erl", 73}]}.
    {func_info, {atom, std@math}, {atom, kernelTan}, 3}.
  {label, 133}.
    {allocate, 32, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}, {y, 20}, {y, 21}, {y, 22}, {y, 23}, {y, 24}, {y, 25}, {y, 26}, {y, 27}, {y, 28}, {y, 29}, {y, 30}, {y, 31}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 77}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 69}}.
    {move, {x, 0}, {y, 4}}.
    {test, is_lt, {f, 1810}, [{y, 4}, {float, 1043333120.0}]}.
    {move, {y, 4}, {x, 0}}.
    {call, 1, {f, 79}}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 1812}, [{x, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 71}}.
    {call, 1, {f, 79}}.
    {jump, {f, 1813}}.
  {label, 1812}.
    {move, {atom, false}, {x, 0}}.
  {label, 1813}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 1814}, [{x, 1}, {atom, true}]}.
    {test, is_eq_exact, {f, 1816}, [{y, 2}, {float, -1.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1817}}.
  {label, 1816}.
    {move, {atom, false}, {x, 0}}.
  {label, 1817}.
    {jump, {f, 1815}}.
  {label, 1814}.
    {move, {atom, false}, {x, 0}}.
  {label, 1815}.
    {test, is_eq, {f, 1811}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, abs, 1}}.
    {test, is_ne, {f, 1818}, [{x, 0}, {integer, 0}]}.
    {jump, {f, 1819}}.
  {label, 1818}.
    {move, {literal, {panic, <<"division by zero: / on f64 at src/math.bp:1960:24">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1819}.
    {gc_bif, '/', {f, 0}, 1, [{float, 1.0}, {x, 0}], {x, 0}}.
    {deallocate, 32}.
    return.
  {label, 1811}.
    {test, is_eq_exact, {f, 1820}, [{y, 2}, {float, 1.0}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 32}.
    return.
  {label, 1820}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {y, 1}], {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {call, 1, {f, 75}}.
    {move, {x, 0}, {y, 6}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 6}, {y, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 1}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {test, is_ne, {f, 1821}, [{y, 5}, {integer, 0}]}.
    {jump, {f, 1822}}.
  {label, 1821}.
    {move, {literal, {panic, <<"division by zero: / on f64 at src/math.bp:1965:23">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1822}.
    {gc_bif, '/', {f, 0}, 0, [{float, -1.0}, {y, 5}], {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call, 1, {f, 75}}.
    {move, {x, 0}, {y, 9}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 9}, {y, 6}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, 1.0}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 9}, {y, 7}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 10}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 8}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 9}, {x, 0}], {x, 0}}.
    {deallocate, 32}.
    return.
  {label, 1810}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {y, 12}}.
    {test, is_ge, {f, 1823}, [{y, 4}, {float, 1072010280.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1824}}.
  {label, 1823}.
    {move, {atom, false}, {x, 0}}.
  {label, 1824}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {x, 0}}.
    {test, is_eq, {f, 1825}, [{x, 0}, {atom, true}]}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq, {f, 1826}, [{x, 0}, {atom, true}]}.
    {gc_bif, '*', {f, 0}, 0, [{float, -1.0}, {y, 11}], {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {gc_bif, '*', {f, 0}, 0, [{float, -1.0}, {y, 12}], {x, 0}}.
    {move, {x, 0}, {y, 12}}.
    {jump, {f, 1827}}.
  {label, 1826}.
  {label, 1827}.
    {gc_bif, '-', {f, 0}, 0, [{float, 7.85398163397448278999e-01}, {y, 11}], {x, 0}}.
    {move, {x, 0}, {y, 14}}.
    {gc_bif, '-', {f, 0}, 0, [{float, 3.06161699786838301793e-17}, {y, 12}], {x, 0}}.
    {move, {x, 0}, {y, 15}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 14}, {y, 15}], {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {float, 0.0}, {x, 0}}.
    {move, {x, 0}, {y, 12}}.
    {jump, {f, 1828}}.
  {label, 1825}.
  {label, 1828}.
    {gc_bif, '*', {f, 0}, 0, [{y, 11}, {y, 11}], {x, 0}}.
    {move, {x, 0}, {y, 16}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 16}, {y, 16}], {x, 0}}.
    {move, {x, 0}, {y, 17}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 17}, {float, -1.85586374855275456654e-05}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, 7.81794442939557092300e-05}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 17}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, 5.88041240820264096874e-04}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 17}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, 3.59207910759131235356e-03}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 17}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, 2.18694882948595424599e-02}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 17}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, 1.33333333333201242699e-01}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 18}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 17}, {float, 2.59073051863633712884e-05}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, 7.14072491382608190305e-05}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 17}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, 2.46463134818469906812e-04}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 17}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, 1.45620945432529025516e-03}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 17}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, 8.86323982359930005737e-03}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 17}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, 5.39682539762260521377e-02}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 16}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 19}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 16}, {y, 11}], {x, 0}}.
    {move, {x, 0}, {y, 20}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 18}, {y, 19}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 20}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 12}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 16}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 12}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 18}}.
    {gc_bif, '*', {f, 0}, 0, [{float, 3.33333333333334091986e-01}, {y, 20}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 18}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 18}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 11}, {y, 18}], {x, 0}}.
    {move, {x, 0}, {y, 21}}.
    {move, {y, 13}, {x, 0}}.
    {test, is_eq, {f, 1829}, [{x, 0}, {atom, true}]}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq, {f, 1830}, [{x, 0}, {atom, true}]}.
    {move, {float, -1.0}, {x, 0}}.
    {jump, {f, 1831}}.
  {label, 1830}.
    {move, {float, 1.0}, {x, 0}}.
  {label, 1831}.
    {move, {x, 0}, {y, 22}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 21}, {y, 21}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '+', {f, 0}, 2, [{y, 21}, {y, 2}], {x, 0}}.
    {test, is_ne, {f, 1832}, [{x, 0}, {integer, 0}]}.
    {jump, {f, 1833}}.
  {label, 1832}.
    {move, {literal, {panic, <<"division by zero: / on f64 at src/math.bp:2013:49">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1833}.
    {gc_bif, '/', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {y, 18}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 11}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{float, 2.0}, {x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 2}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 22}, {x, 0}], {x, 0}}.
    {deallocate, 32}.
    return.
  {label, 1829}.
    {test, is_eq_exact, {f, 1834}, [{y, 2}, {float, 1.0}]}.
    {move, {y, 21}, {x, 0}}.
    {deallocate, 32}.
    return.
  {label, 1834}.
    {move, {y, 21}, {x, 0}}.
    {call, 1, {f, 75}}.
    {move, {x, 0}, {y, 23}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 23}, {y, 11}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 18}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 24}}.
    {test, is_ne, {f, 1835}, [{y, 21}, {integer, 0}]}.
    {jump, {f, 1836}}.
  {label, 1835}.
    {move, {literal, {panic, <<"division by zero: / on f64 at src/math.bp:2018:18">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1836}.
    {gc_bif, '/', {f, 0}, 0, [{float, -1.0}, {y, 21}], {x, 0}}.
    {move, {x, 0}, {y, 25}}.
    {move, {y, 25}, {x, 0}}.
    {call, 1, {f, 75}}.
    {move, {x, 0}, {y, 26}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 26}, {y, 23}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, 1.0}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 27}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 26}, {y, 24}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 27}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 25}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 26}, {x, 0}], {x, 0}}.
    {deallocate, 32}.
    return.
% n mod 4 in 0..3 (fdlibm's `n & 3`).

{function, quadrantOf, 1, 135}.
  {label, 134}.
    {line, [{location, "std@math.erl", 74}]}.
    {func_info, {atom, std@math}, {atom, quadrantOf}, 1}.
  {label, 135}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {float, 0.25}], {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
    {gc_bif, '*', {f, 0}, 1, [{float, 4.0}, {x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {deallocate, 5}.
    return.

{function, sinBody, 1, 137}.
  {label, 136}.
    {line, [{location, "std@math.erl", 75}]}.
    {func_info, {atom, std@math}, {atom, sinBody}, 1}.
  {label, 137}.
    {allocate, 9, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 69}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_ge, {f, 1837}, [{float, 1072243195.0}, {y, 1}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {float, 0.0}, {x, 2}}.
    {move, {float, 0.0}, {x, 1}}.
    {call_last, 3, {f, 131}, 9}.
  {label, 1837}.
    {test, is_ge, {f, 1838}, [{y, 1}, {float, 2146435072.0}]}.
    {gc_bif, '-', {f, 0}, 0, [{y, 0}, {y, 0}], {x, 0}}.
    {deallocate, 9}.
    return.
  {label, 1838}.
    {move, {y, 0}, {x, 0}}.
    {move, {float, 0.0}, {x, 1}}.
    {call, 2, {f, 127}}.
    {call, 1, {f, 135}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {float, 1.0}, {x, 1}}.
    {call, 2, {f, 127}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {float, 2.0}, {x, 1}}.
    {call, 2, {f, 127}}.
    {move, {x, 0}, {y, 4}}.
    {test, is_lt, {f, 1839}, [{y, 2}, {float, 0.5}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {float, 1.0}, {x, 2}}.
    {move, {y, 4}, {x, 1}}.
    {call, 3, {f, 131}}.
    {jump, {f, 1840}}.
  {label, 1839}.
    {test, is_lt, {f, 1841}, [{y, 2}, {float, 1.5}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call, 2, {f, 129}}.
    {jump, {f, 1842}}.
  {label, 1841}.
    {test, is_lt, {f, 1843}, [{y, 2}, {float, 2.5}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {float, 1.0}, {x, 2}}.
    {move, {y, 4}, {x, 1}}.
    {call, 3, {f, 131}}.
    {gc_bif, '*', {f, 0}, 1, [{float, -1.0}, {x, 0}], {x, 0}}.
    {jump, {f, 1844}}.
  {label, 1843}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call, 2, {f, 129}}.
    {gc_bif, '*', {f, 0}, 1, [{float, -1.0}, {x, 0}], {x, 0}}.
  {label, 1844}.
  {label, 1842}.
  {label, 1840}.
    {deallocate, 9}.
    return.

{function, cosBody, 1, 139}.
  {label, 138}.
    {line, [{location, "std@math.erl", 76}]}.
    {func_info, {atom, std@math}, {atom, cosBody}, 1}.
  {label, 139}.
    {allocate, 9, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 69}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_ge, {f, 1845}, [{float, 1072243195.0}, {y, 1}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {float, 0.0}, {x, 1}}.
    {call_last, 2, {f, 129}, 9}.
  {label, 1845}.
    {test, is_ge, {f, 1846}, [{y, 1}, {float, 2146435072.0}]}.
    {gc_bif, '-', {f, 0}, 0, [{y, 0}, {y, 0}], {x, 0}}.
    {deallocate, 9}.
    return.
  {label, 1846}.
    {move, {y, 0}, {x, 0}}.
    {move, {float, 0.0}, {x, 1}}.
    {call, 2, {f, 127}}.
    {call, 1, {f, 135}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {float, 1.0}, {x, 1}}.
    {call, 2, {f, 127}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {float, 2.0}, {x, 1}}.
    {call, 2, {f, 127}}.
    {move, {x, 0}, {y, 4}}.
    {test, is_lt, {f, 1847}, [{y, 2}, {float, 0.5}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call, 2, {f, 129}}.
    {jump, {f, 1848}}.
  {label, 1847}.
    {test, is_lt, {f, 1849}, [{y, 2}, {float, 1.5}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {float, 1.0}, {x, 2}}.
    {move, {y, 4}, {x, 1}}.
    {call, 3, {f, 131}}.
    {gc_bif, '*', {f, 0}, 1, [{float, -1.0}, {x, 0}], {x, 0}}.
    {jump, {f, 1850}}.
  {label, 1849}.
    {test, is_lt, {f, 1851}, [{y, 2}, {float, 2.5}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call, 2, {f, 129}}.
    {gc_bif, '*', {f, 0}, 1, [{float, -1.0}, {x, 0}], {x, 0}}.
    {jump, {f, 1852}}.
  {label, 1851}.
    {move, {y, 3}, {x, 0}}.
    {move, {float, 1.0}, {x, 2}}.
    {move, {y, 4}, {x, 1}}.
    {call, 3, {f, 131}}.
  {label, 1852}.
  {label, 1850}.
  {label, 1848}.
    {deallocate, 9}.
    return.

{function, tanBody, 1, 141}.
  {label, 140}.
    {line, [{location, "std@math.erl", 77}]}.
    {func_info, {atom, std@math}, {atom, tanBody}, 1}.
  {label, 141}.
    {allocate, 10, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 69}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_ge, {f, 1853}, [{float, 1072243195.0}, {y, 1}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {float, 1.0}, {x, 2}}.
    {move, {float, 0.0}, {x, 1}}.
    {call_last, 3, {f, 133}, 10}.
  {label, 1853}.
    {test, is_ge, {f, 1854}, [{y, 1}, {float, 2146435072.0}]}.
    {gc_bif, '-', {f, 0}, 0, [{y, 0}, {y, 0}], {x, 0}}.
    {deallocate, 10}.
    return.
  {label, 1854}.
    {move, {y, 0}, {x, 0}}.
    {move, {float, 0.0}, {x, 1}}.
    {call, 2, {f, 127}}.
    {call, 1, {f, 135}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {float, 0.0}, {x, 1}}.
    {call, 2, {f, 127}}.
    {call, 1, {f, 135}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {float, 0.5}], {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
    {gc_bif, '*', {f, 0}, 1, [{float, 2.0}, {x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 2}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {float, 1.0}, {x, 1}}.
    {call, 2, {f, 127}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {move, {float, 2.0}, {x, 1}}.
    {call, 2, {f, 127}}.
    {move, {x, 0}, {y, 5}}.
    {gc_bif, '*', {f, 0}, 0, [{float, 2.0}, {y, 3}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{float, 1.0}, {x, 0}], {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 4}, {x, 0}}.
    {call_last, 3, {f, 133}, 10}.

{function, asinPoly, 1, 143}.
  {label, 142}.
    {line, [{location, "std@math.erl", 78}]}.
    {func_info, {atom, std@math}, {atom, asinPoly}, 1}.
  {label, 143}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {float, 3.47933107596021167570e-05}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, 7.91534994289814532176e-04}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, -4.00555345006794114027e-02}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, 2.01212532134862925881e-01}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, -3.25565818622400915405e-01}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, 1.66666666666666657415e-01}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {float, 7.70381505559019352791e-02}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, -6.88283971605453293030e-01}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, 2.02094576023350569471e+00}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, -2.40339491173441421878e+00}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, 1.0}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {test, is_ne, {f, 1855}, [{y, 2}, {integer, 0}]}.
    {jump, {f, 1856}}.
  {label, 1855}.
    {move, {literal, {panic, <<"division by zero: / on f64 at src/math.bp:2093:14">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1856}.
    {gc_bif, '/', {f, 0}, 0, [{y, 1}, {y, 2}], {x, 0}}.
    {deallocate, 3}.
    return.

{function, asinBody, 1, 145}.
  {label, 144}.
    {line, [{location, "std@math.erl", 79}]}.
    {func_info, {atom, std@math}, {atom, asinBody}, 1}.
  {label, 145}.
    {allocate, 28, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}, {y, 20}, {y, 21}, {y, 22}, {y, 23}, {y, 24}, {y, 25}, {y, 26}, {y, 27}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 69}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_ge, {f, 1857}, [{y, 1}, {float, 1072693248.0}]}.
    {test, is_eq_exact, {f, 1859}, [{y, 1}, {float, 1072693248.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1860}}.
  {label, 1859}.
    {move, {atom, false}, {x, 0}}.
  {label, 1860}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 1861}, [{x, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 71}}.
    {call, 1, {f, 79}}.
    {jump, {f, 1862}}.
  {label, 1861}.
    {move, {atom, false}, {x, 0}}.
  {label, 1862}.
    {test, is_eq, {f, 1858}, [{x, 0}, {atom, true}]}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {float, 1.57079632679489655800e+00}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '*', {f, 0}, 2, [{y, 0}, {float, 6.12323399573676603587e-17}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {deallocate, 28}.
    return.
  {label, 1858}.
    {gc_bif, '-', {f, 0}, 0, [{y, 0}, {y, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '-', {f, 0}, 2, [{y, 0}, {y, 0}], {x, 0}}.
    {test, is_ne, {f, 1863}, [{x, 0}, {integer, 0}]}.
    {jump, {f, 1864}}.
  {label, 1863}.
    {move, {literal, {panic, <<"division by zero: / on f64 at src/math.bp:2102:24">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1864}.
    {gc_bif, '/', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {deallocate, 28}.
    return.
  {label, 1857}.
    {test, is_lt, {f, 1865}, [{y, 1}, {float, 1071644672.0}]}.
    {test, is_lt, {f, 1866}, [{y, 1}, {float, 1044381696.0}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 28}.
    return.
  {label, 1866}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {y, 0}], {x, 0}}.
    {call, 1, {f, 143}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {deallocate, 28}.
    return.
  {label, 1865}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, abs, 1}}.
    {gc_bif, '-', {f, 0}, 1, [{float, 1.0}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 2}, {float, 0.5}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, math, sqrt, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {float, 0.0}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {test, is_ge, {f, 1867}, [{y, 1}, {float, 1072640819.0}]}.
    {move, {y, 3}, {x, 0}}.
    {call, 1, {f, 143}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 4}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 4}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{float, 2.0}, {x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {float, 6.12323399573676603587e-17}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{float, 1.57079632679489655800e+00}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 1868}}.
  {label, 1867}.
    {move, {y, 4}, {x, 0}}.
    {call, 1, {f, 75}}.
    {move, {x, 0}, {y, 6}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 6}, {y, 6}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 3}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '+', {f, 0}, 2, [{y, 4}, {y, 6}], {x, 0}}.
    {test, is_ne, {f, 1869}, [{x, 0}, {integer, 0}]}.
    {jump, {f, 1870}}.
  {label, 1869}.
    {move, {literal, {panic, <<"division by zero: / on f64 at src/math.bp:2117:31">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1870}.
    {gc_bif, '/', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {gc_bif, '*', {f, 0}, 0, [{float, 2.0}, {y, 4}], {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 3}, {x, 0}}.
    {call, 1, {f, 143}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 8}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '*', {f, 0}, 2, [{float, 2.0}, {y, 7}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 2, [{float, 6.12323399573676603587e-17}, {x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {gc_bif, '*', {f, 0}, 0, [{float, 2.0}, {y, 6}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{float, 7.85398163397448278999e-01}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 9}, {y, 10}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{float, 7.85398163397448278999e-01}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 5}}.
  {label, 1868}.
    {test, is_lt, {f, 1871}, [{float, 0.0}, {y, 0}]}.
    {move, {y, 5}, {x, 0}}.
    {jump, {f, 1872}}.
  {label, 1871}.
    {gc_bif, '*', {f, 0}, 0, [{float, -1.0}, {y, 5}], {x, 0}}.
  {label, 1872}.
    {deallocate, 28}.
    return.

{function, acosBody, 1, 147}.
  {label, 146}.
    {line, [{location, "std@math.erl", 80}]}.
    {func_info, {atom, std@math}, {atom, acosBody}, 1}.
  {label, 147}.
    {allocate, 22, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}, {y, 20}, {y, 21}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 69}}.
    {move, {x, 0}, {y, 1}}.
    {move, {float, 1.57079632679489655800e+00}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {float, 6.12323399573676603587e-17}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {test, is_ge, {f, 1873}, [{y, 1}, {float, 1072693248.0}]}.
    {test, is_eq_exact, {f, 1875}, [{y, 1}, {float, 1072693248.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1876}}.
  {label, 1875}.
    {move, {atom, false}, {x, 0}}.
  {label, 1876}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 1877}, [{x, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 71}}.
    {call, 1, {f, 79}}.
    {jump, {f, 1878}}.
  {label, 1877}.
    {move, {atom, false}, {x, 0}}.
  {label, 1878}.
    {test, is_eq, {f, 1874}, [{x, 0}, {atom, true}]}.
    {test, is_lt, {f, 1879}, [{float, 0.0}, {y, 0}]}.
    {move, {float, 0.0}, {x, 0}}.
    {jump, {f, 1880}}.
  {label, 1879}.
    {gc_bif, '*', {f, 0}, 0, [{float, 2.0}, {y, 3}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, 3.14159265358979311600e+00}, {x, 0}], {x, 0}}.
  {label, 1880}.
    {deallocate, 22}.
    return.
  {label, 1874}.
    {gc_bif, '-', {f, 0}, 0, [{y, 0}, {y, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '-', {f, 0}, 2, [{y, 0}, {y, 0}], {x, 0}}.
    {test, is_ne, {f, 1881}, [{x, 0}, {integer, 0}]}.
    {jump, {f, 1882}}.
  {label, 1881}.
    {move, {literal, {panic, <<"division by zero: / on f64 at src/math.bp:2135:24">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1882}.
    {gc_bif, '/', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {deallocate, 22}.
    return.
  {label, 1873}.
    {test, is_lt, {f, 1883}, [{y, 1}, {float, 1071644672.0}]}.
    {test, is_ge, {f, 1884}, [{float, 1012924416.0}, {y, 1}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {y, 3}], {x, 0}}.
    {deallocate, 22}.
    return.
  {label, 1884}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {y, 0}], {x, 0}}.
    {call, 1, {f, 143}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 3}, {x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 2}, {x, 0}], {x, 0}}.
    {deallocate, 22}.
    return.
  {label, 1883}.
    {test, is_lt, {f, 1885}, [{y, 0}, {float, 0.0}]}.
    {gc_bif, '+', {f, 0}, 0, [{float, 1.0}, {y, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {float, 0.5}], {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext, 1, {extfunc, math, sqrt, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {call, 1, {f, 143}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {y, 5}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {y, 3}], {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 5}, {y, 6}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{float, 2.0}, {x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{float, 3.14159265358979311600e+00}, {x, 0}], {x, 0}}.
    {deallocate, 22}.
    return.
  {label, 1885}.
    {gc_bif, '-', {f, 0}, 0, [{float, 1.0}, {y, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {float, 0.5}], {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {call_ext, 1, {extfunc, math, sqrt, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call, 1, {f, 75}}.
    {move, {x, 0}, {y, 9}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 9}, {y, 9}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 7}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '+', {f, 0}, 2, [{y, 8}, {y, 9}], {x, 0}}.
    {test, is_ne, {f, 1886}, [{x, 0}, {integer, 0}]}.
    {jump, {f, 1887}}.
  {label, 1886}.
    {move, {literal, {panic, <<"division by zero: / on f64 at src/math.bp:2150:27">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1887}.
    {gc_bif, '/', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 7}, {x, 0}}.
    {call, 1, {f, 143}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {y, 8}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 10}], {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 9}, {y, 11}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{float, 2.0}, {x, 0}], {x, 0}}.
    {deallocate, 22}.
    return.

{function, atanBody, 1, 149}.
  {label, 148}.
    {line, [{location, "std@math.erl", 81}]}.
    {func_info, {atom, std@math}, {atom, atanBody}, 1}.
  {label, 149}.
    {allocate, 13, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 69}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 77}}.
    {move, {x, 0}, {y, 2}}.
    {test, is_ge, {f, 1888}, [{y, 1}, {float, 1141899264.0}]}.
    {test, is_ne_exact, {f, 1889}, [{y, 0}, {y, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {y, 0}], {x, 0}}.
    {deallocate, 13}.
    return.
  {label, 1889}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq, {f, 1890}, [{x, 0}, {atom, true}]}.
    {gc_bif, '-', {f, 0}, 0, [{float, -1.57079632679489655800e+00}, {float, 6.12323399573676603587e-17}], {x, 0}}.
    {jump, {f, 1891}}.
  {label, 1890}.
    {gc_bif, '+', {f, 0}, 0, [{float, 1.57079632679489655800e+00}, {float, 6.12323399573676603587e-17}], {x, 0}}.
  {label, 1891}.
    {deallocate, 13}.
    return.
  {label, 1888}.
    {move, {float, -1.0}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {test, is_lt, {f, 1892}, [{y, 1}, {float, 1071382528.0}]}.
    {test, is_lt, {f, 1893}, [{y, 1}, {float, 1044381696.0}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 13}.
    return.
  {label, 1893}.
    {jump, {f, 1894}}.
  {label, 1892}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, abs, 1}}.
    {move, {x, 0}, {y, 5}}.
    {test, is_lt, {f, 1895}, [{y, 1}, {float, 1072889856.0}]}.
    {test, is_lt, {f, 1896}, [{y, 1}, {float, 1072037888.0}]}.
    {move, {float, 0.0}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, '*', {f, 0}, 0, [{float, 2.0}, {y, 5}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {float, 1.0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '+', {f, 0}, 2, [{float, 2.0}, {y, 5}], {x, 0}}.
    {test, is_ne, {f, 1897}, [{x, 0}, {integer, 0}]}.
    {jump, {f, 1898}}.
  {label, 1897}.
    {move, {literal, {panic, <<"division by zero: / on f64 at src/math.bp:2174:38">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1898}.
    {gc_bif, '/', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {jump, {f, 1899}}.
  {label, 1896}.
    {move, {float, 1.0}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 5}, {float, 1.0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '+', {f, 0}, 2, [{y, 5}, {float, 1.0}], {x, 0}}.
    {test, is_ne, {f, 1900}, [{x, 0}, {integer, 0}]}.
    {jump, {f, 1901}}.
  {label, 1900}.
    {move, {literal, {panic, <<"division by zero: / on f64 at src/math.bp:2177:32">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1901}.
    {gc_bif, '/', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 4}}.
  {label, 1899}.
    {jump, {f, 1902}}.
  {label, 1895}.
    {test, is_lt, {f, 1903}, [{y, 1}, {float, 1073971200.0}]}.
    {move, {float, 2.0}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 5}, {float, 1.5}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '*', {f, 0}, 2, [{float, 1.5}, {y, 5}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 2, [{float, 1.0}, {x, 0}], {x, 0}}.
    {test, is_ne, {f, 1904}, [{x, 0}, {integer, 0}]}.
    {jump, {f, 1905}}.
  {label, 1904}.
    {move, {literal, {panic, <<"division by zero: / on f64 at src/math.bp:2181:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1905}.
    {gc_bif, '/', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {jump, {f, 1906}}.
  {label, 1903}.
    {move, {float, 3.0}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {test, is_ne, {f, 1907}, [{y, 5}, {integer, 0}]}.
    {jump, {f, 1908}}.
  {label, 1907}.
    {move, {literal, {panic, <<"division by zero: / on f64 at src/math.bp:2184:22">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1908}.
    {gc_bif, '/', {f, 0}, 0, [{float, -1.0}, {y, 5}], {x, 0}}.
    {move, {x, 0}, {y, 4}}.
  {label, 1906}.
  {label, 1902}.
  {label, 1894}.
    {gc_bif, '*', {f, 0}, 0, [{y, 4}, {y, 4}], {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 6}, {y, 6}], {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 7}, {float, 1.62858201153657823623e-02}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, 4.97687799461593236017e-02}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 7}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, 6.66107313738753120669e-02}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 7}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, 9.09088713343650656196e-02}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 7}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, 1.42857142725034663711e-01}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 7}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, 3.33333333333329318027e-01}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 6}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 7}, {float, -3.65315727442169155270e-02}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, -5.83357013379057348645e-02}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 7}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, -7.69187620504482999495e-02}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 7}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, -1.11111104054623557880e-01}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 7}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, -1.99999999998764832476e-01}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 7}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {test, is_lt, {f, 1909}, [{y, 3}, {float, 0.0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 8}, {y, 9}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 4}, {x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 4}, {x, 0}], {x, 0}}.
    {deallocate, 13}.
    return.
  {label, 1909}.
    {test, is_lt, {f, 1910}, [{y, 3}, {float, 0.5}]}.
    {move, {float, 4.63647609000806093515e-01}, {x, 0}}.
    {jump, {f, 1911}}.
  {label, 1910}.
    {test, is_lt, {f, 1912}, [{y, 3}, {float, 1.5}]}.
    {move, {float, 7.85398163397448278999e-01}, {x, 0}}.
    {jump, {f, 1913}}.
  {label, 1912}.
    {test, is_lt, {f, 1914}, [{y, 3}, {float, 2.5}]}.
    {move, {float, 9.82793723247329054082e-01}, {x, 0}}.
    {jump, {f, 1915}}.
  {label, 1914}.
    {move, {float, 1.57079632679489655800e+00}, {x, 0}}.
  {label, 1915}.
  {label, 1913}.
  {label, 1911}.
    {move, {x, 0}, {y, 10}}.
    {test, is_lt, {f, 1916}, [{y, 3}, {float, 0.5}]}.
    {move, {float, 2.26987774529616870924e-17}, {x, 0}}.
    {jump, {f, 1917}}.
  {label, 1916}.
    {test, is_lt, {f, 1918}, [{y, 3}, {float, 1.5}]}.
    {move, {float, 3.06161699786838301793e-17}, {x, 0}}.
    {jump, {f, 1919}}.
  {label, 1918}.
    {test, is_lt, {f, 1920}, [{y, 3}, {float, 2.5}]}.
    {move, {float, 1.39033110312309984516e-17}, {x, 0}}.
    {jump, {f, 1921}}.
  {label, 1920}.
    {move, {float, 6.12323399573676603587e-17}, {x, 0}}.
  {label, 1921}.
  {label, 1919}.
  {label, 1917}.
    {move, {x, 0}, {y, 11}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 8}, {y, 9}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 4}, {x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {y, 11}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {y, 4}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 10}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq, {f, 1922}, [{x, 0}, {atom, true}]}.
    {gc_bif, '*', {f, 0}, 0, [{float, -1.0}, {y, 12}], {x, 0}}.
    {jump, {f, 1923}}.
  {label, 1922}.
    {move, {y, 12}, {x, 0}}.
  {label, 1923}.
    {deallocate, 13}.
    return.

{function, atan2Body, 2, 151}.
  {label, 150}.
    {line, [{location, "std@math.erl", 82}]}.
    {func_info, {atom, std@math}, {atom, atan2Body}, 2}.
  {label, 151}.
    {allocate, 20, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ne_exact, {f, 1925}, [{y, 1}, {y, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1926}}.
  {label, 1925}.
    {move, {atom, false}, {x, 0}}.
  {label, 1926}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 1927}, [{x, 1}, {atom, true}]}.
    {test, is_ne_exact, {f, 1929}, [{y, 0}, {y, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1930}}.
  {label, 1929}.
    {move, {atom, false}, {x, 0}}.
  {label, 1930}.
    {jump, {f, 1928}}.
  {label, 1927}.
    {move, {atom, true}, {x, 0}}.
  {label, 1928}.
    {test, is_eq, {f, 1924}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {deallocate, 20}.
    return.
  {label, 1924}.
    {test, is_eq_exact, {f, 1931}, [{y, 1}, {float, 1.0}]}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 149}, 20}.
  {label, 1931}.
    {move, {float, 3.1415926535897931160E+00}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {float, 1.2246467991473531772E-16}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {float, 1.5707963267948965580E+00}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {float, 7.8539816339744827900E-01}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 77}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 77}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq, {f, 1932}, [{x, 0}, {atom, true}]}.
    {move, {float, 1.0}, {x, 0}}.
    {jump, {f, 1933}}.
  {label, 1932}.
    {move, {float, 0.0}, {x, 0}}.
  {label, 1933}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq, {f, 1934}, [{x, 0}, {atom, true}]}.
    {move, {float, 2.0}, {x, 0}}.
    {jump, {f, 1935}}.
  {label, 1934}.
    {move, {float, 0.0}, {x, 0}}.
  {label, 1935}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call, 2, {f, 1937}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 79}}.
    {test, is_eq, {f, 1939}, [{x, 0}, {atom, true}]}.
    {test, is_lt, {f, 1940}, [{y, 10}, {float, 1.5}]}.
    {move, {y, 0}, {x, 0}}.
    {jump, {f, 1941}}.
  {label, 1940}.
    {test, is_lt, {f, 1942}, [{y, 10}, {float, 2.5}]}.
    {move, {y, 2}, {x, 0}}.
    {jump, {f, 1943}}.
  {label, 1942}.
    {gc_bif, '*', {f, 0}, 0, [{float, -1.0}, {y, 2}], {x, 0}}.
  {label, 1943}.
  {label, 1941}.
    {deallocate, 20}.
    return.
  {label, 1939}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 79}}.
    {test, is_eq, {f, 1944}, [{x, 0}, {atom, true}]}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq, {f, 1945}, [{x, 0}, {atom, true}]}.
    {gc_bif, '*', {f, 0}, 0, [{float, -1.0}, {y, 4}], {x, 0}}.
    {jump, {f, 1946}}.
  {label, 1945}.
    {move, {y, 4}, {x, 0}}.
  {label, 1946}.
    {deallocate, 20}.
    return.
  {label, 1944}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 69}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 69}}.
    {move, {x, 0}, {y, 12}}.
    {test, is_eq_exact, {f, 1947}, [{y, 11}, {float, 2146435072.0}]}.
    {test, is_eq_exact, {f, 1948}, [{y, 12}, {float, 2146435072.0}]}.
    {test, is_lt, {f, 1949}, [{y, 10}, {float, 0.5}]}.
    {move, {y, 5}, {x, 0}}.
    {jump, {f, 1950}}.
  {label, 1949}.
    {test, is_lt, {f, 1951}, [{y, 10}, {float, 1.5}]}.
    {gc_bif, '*', {f, 0}, 0, [{float, -1.0}, {y, 5}], {x, 0}}.
    {jump, {f, 1952}}.
  {label, 1951}.
    {test, is_lt, {f, 1953}, [{y, 10}, {float, 2.5}]}.
    {gc_bif, '*', {f, 0}, 0, [{float, 3.0}, {y, 5}], {x, 0}}.
    {jump, {f, 1954}}.
  {label, 1953}.
    {gc_bif, '*', {f, 0}, 0, [{float, -3.0}, {y, 5}], {x, 0}}.
  {label, 1954}.
  {label, 1952}.
  {label, 1950}.
    {deallocate, 20}.
    return.
  {label, 1948}.
    {test, is_lt, {f, 1955}, [{y, 10}, {float, 0.5}]}.
    {move, {float, 0.0}, {x, 0}}.
    {jump, {f, 1956}}.
  {label, 1955}.
    {test, is_lt, {f, 1957}, [{y, 10}, {float, 1.5}]}.
    {gc_bif, '*', {f, 0}, 0, [{float, -1.0}, {float, 0.0}], {x, 0}}.
    {jump, {f, 1958}}.
  {label, 1957}.
    {test, is_lt, {f, 1959}, [{y, 10}, {float, 2.5}]}.
    {move, {y, 2}, {x, 0}}.
    {jump, {f, 1960}}.
  {label, 1959}.
    {gc_bif, '*', {f, 0}, 0, [{float, -1.0}, {y, 2}], {x, 0}}.
  {label, 1960}.
  {label, 1958}.
  {label, 1956}.
    {deallocate, 20}.
    return.
  {label, 1947}.
    {test, is_eq_exact, {f, 1961}, [{y, 12}, {float, 2146435072.0}]}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq, {f, 1962}, [{x, 0}, {atom, true}]}.
    {gc_bif, '*', {f, 0}, 0, [{float, -1.0}, {y, 4}], {x, 0}}.
    {jump, {f, 1963}}.
  {label, 1962}.
    {move, {y, 4}, {x, 0}}.
  {label, 1963}.
    {deallocate, 20}.
    return.
  {label, 1961}.
    {gc_bif, '-', {f, 0}, 0, [{y, 12}, {y, 11}], {x, 0}}.
    {gc_bif, '/', {f, 0}, 1, [{x, 0}, {float, 1048576.0}], {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 10}, {x, 0}}.
    {move, {x, 0}, {y, 14}}.
    {move, {float, 0.0}, {x, 0}}.
    {move, {x, 0}, {y, 15}}.
    {test, is_lt, {f, 1964}, [{float, 60.0}, {y, 13}]}.
    {gc_bif, '*', {f, 0}, 0, [{float, 0.5}, {y, 3}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 4}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 15}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 10}, {float, 0.5}], {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
    {gc_bif, '*', {f, 0}, 1, [{float, 2.0}, {x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 10}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 14}}.
    {jump, {f, 1965}}.
  {label, 1964}.
    {test, is_eq, {f, 1967}, [{y, 7}, {atom, true}]}.
    {test, is_lt, {f, 1969}, [{y, 13}, {float, -60.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1970}}.
  {label, 1969}.
    {move, {atom, false}, {x, 0}}.
  {label, 1970}.
    {jump, {f, 1968}}.
  {label, 1967}.
    {move, {atom, false}, {x, 0}}.
  {label, 1968}.
    {test, is_eq, {f, 1966}, [{x, 0}, {atom, true}]}.
    {move, {float, 0.0}, {x, 0}}.
    {move, {x, 0}, {y, 15}}.
    {jump, {f, 1971}}.
  {label, 1966}.
    {test, is_ne, {f, 1972}, [{y, 1}, {integer, 0}]}.
    {jump, {f, 1973}}.
  {label, 1972}.
    {move, {literal, {panic, <<"division by zero: / on f64 at src/math.bp:2273:65">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1973}.
    {gc_bif, '/', {f, 0}, 0, [{y, 0}, {y, 1}], {x, 0}}.
    {call_ext, 1, {extfunc, erlang, abs, 1}}.
    {call, 1, {f, 149}}.
    {move, {x, 0}, {y, 15}}.
  {label, 1971}.
  {label, 1965}.
    {test, is_lt, {f, 1974}, [{y, 14}, {float, 0.5}]}.
    {move, {y, 15}, {x, 0}}.
    {jump, {f, 1975}}.
  {label, 1974}.
    {test, is_lt, {f, 1976}, [{y, 14}, {float, 1.5}]}.
    {gc_bif, '*', {f, 0}, 0, [{float, -1.0}, {y, 15}], {x, 0}}.
    {jump, {f, 1977}}.
  {label, 1976}.
    {test, is_lt, {f, 1978}, [{y, 14}, {float, 2.5}]}.
    {gc_bif, '-', {f, 0}, 0, [{y, 15}, {y, 3}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 2}, {x, 0}], {x, 0}}.
    {jump, {f, 1979}}.
  {label, 1978}.
    {gc_bif, '-', {f, 0}, 0, [{y, 15}, {y, 3}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {y, 2}], {x, 0}}.
  {label, 1979}.
  {label, 1977}.
  {label, 1975}.
    {deallocate, 20}.
    return.
% ── hyperbolic functions ─────────────────────────────────────────────────────

{function, sinhBody, 1, 153}.
  {label, 152}.
    {line, [{location, "std@math.erl", 83}]}.
    {func_info, {atom, std@math}, {atom, sinhBody}, 1}.
  {label, 153}.
    {allocate, 8, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_lt, {f, 1980}, [{y, 0}, {float, 0.0}]}.
    {move, {float, -0.5}, {x, 0}}.
    {jump, {f, 1981}}.
  {label, 1980}.
    {move, {float, 0.5}, {x, 0}}.
  {label, 1981}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, abs, 1}}.
    {move, {x, 0}, {y, 2}}.
    {test, is_lt, {f, 1982}, [{y, 2}, {float, 22.0}]}.
    {test, is_lt, {f, 1983}, [{y, 2}, {float, 3.725290298461914e-9}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 1983}.
    {move, {y, 2}, {x, 0}}.
    {call, 1, {f, 85}}.
    {move, {x, 0}, {y, 3}}.
    {test, is_lt, {f, 1984}, [{y, 2}, {float, 1.0}]}.
    {gc_bif, '*', {f, 0}, 0, [{float, 2.0}, {y, 3}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '*', {f, 0}, 2, [{y, 3}, {y, 3}], {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {gc_bif, '+', {f, 0}, 3, [{y, 3}, {float, 1.0}], {x, 0}}.
    {test, is_ne, {f, 1985}, [{x, 0}, {integer, 0}]}.
    {jump, {f, 1986}}.
  {label, 1985}.
    {move, {literal, {panic, <<"division by zero: / on f64 at src/math.bp:2292:51">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1986}.
    {gc_bif, '/', {f, 0}, 3, [{x, 2}, {x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 1}, {x, 0}], {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 1984}.
    {gc_bif, '+', {f, 0}, 0, [{y, 3}, {float, 1.0}], {x, 0}}.
    {test, is_ne, {f, 1987}, [{x, 0}, {integer, 0}]}.
    {jump, {f, 1988}}.
  {label, 1987}.
    {move, {literal, {panic, <<"division by zero: / on f64 at src/math.bp:2293:27">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1988}.
    {gc_bif, '/', {f, 0}, 1, [{y, 3}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 3}, {x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 1}, {x, 0}], {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 1982}.
    {test, is_lt, {f, 1989}, [{y, 2}, {float, 709.7822265625}]}.
    {move, {y, 2}, {x, 0}}.
    {call, 1, {f, 83}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 1}, {x, 0}], {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 1989}.
    {test, is_ge, {f, 1990}, [{float, 710.4758600739439}, {y, 2}]}.
    {gc_bif, '*', {f, 0}, 0, [{float, 0.5}, {y, 2}], {x, 0}}.
    {call, 1, {f, 83}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 1}, {y, 4}], {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 5}, {y, 4}], {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 1990}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {float, 1.0e307}], {x, 0}}.
    {deallocate, 8}.
    return.

{function, coshBody, 1, 155}.
  {label, 154}.
    {line, [{location, "std@math.erl", 84}]}.
    {func_info, {atom, std@math}, {atom, coshBody}, 1}.
  {label, 155}.
    {allocate, 11, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 69}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_lt, {f, 1991}, [{y, 1}, {float, 1071001155.0}]}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, abs, 1}}.
    {call, 1, {f, 85}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, '+', {f, 0}, 0, [{float, 1.0}, {y, 2}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {test, is_lt, {f, 1992}, [{y, 1}, {float, 1015021568.0}]}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 11}.
    return.
  {label, 1992}.
    {gc_bif, '*', {f, 0}, 0, [{y, 2}, {y, 2}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '+', {f, 0}, 2, [{y, 3}, {y, 3}], {x, 0}}.
    {test, is_ne, {f, 1993}, [{x, 0}, {integer, 0}]}.
    {jump, {f, 1994}}.
  {label, 1993}.
    {move, {literal, {panic, <<"division by zero: / on f64 at src/math.bp:2310:30">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1994}.
    {gc_bif, '/', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{float, 1.0}, {x, 0}], {x, 0}}.
    {deallocate, 11}.
    return.
  {label, 1991}.
    {test, is_lt, {f, 1995}, [{y, 1}, {float, 1077280768.0}]}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, abs, 1}}.
    {call, 1, {f, 83}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, '*', {f, 0}, 0, [{float, 0.5}, {y, 4}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne, {f, 1996}, [{y, 4}, {integer, 0}]}.
    {jump, {f, 1997}}.
  {label, 1996}.
    {move, {literal, {panic, <<"division by zero: / on f64 at src/math.bp:2314:30">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1997}.
    {gc_bif, '/', {f, 0}, 2, [{float, 0.5}, {y, 4}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {deallocate, 11}.
    return.
  {label, 1995}.
    {test, is_lt, {f, 1998}, [{y, 1}, {float, 1082535490.0}]}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, abs, 1}}.
    {call, 1, {f, 83}}.
    {gc_bif, '*', {f, 0}, 1, [{float, 0.5}, {x, 0}], {x, 0}}.
    {deallocate, 11}.
    return.
  {label, 1998}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, abs, 1}}.
    {test, is_ge, {f, 1999}, [{float, 710.4758600739439}, {x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, abs, 1}}.
    {gc_bif, '*', {f, 0}, 1, [{float, 0.5}, {x, 0}], {x, 0}}.
    {call, 1, {f, 83}}.
    {move, {x, 0}, {y, 5}}.
    {gc_bif, '*', {f, 0}, 0, [{float, 0.5}, {y, 5}], {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 6}, {y, 5}], {x, 0}}.
    {deallocate, 11}.
    return.
  {label, 1999}.
    {test, is_ge, {f, 2000}, [{y, 1}, {float, 2146435072.0}]}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {y, 0}], {x, 0}}.
    {deallocate, 11}.
    return.
  {label, 2000}.
    {move, {float, 1.0}, {x, 0}}.
    {move, {float, 1.0e300}, {x, 1}}.
    {call_last, 2, {f, 61}, 11}.

{function, tanhBody, 1, 157}.
  {label, 156}.
    {line, [{location, "std@math.erl", 85}]}.
    {func_info, {atom, std@math}, {atom, tanhBody}, 1}.
  {label, 157}.
    {allocate, 10, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 69}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 77}}.
    {move, {x, 0}, {y, 2}}.
    {test, is_ge, {f, 2001}, [{y, 1}, {float, 2146435072.0}]}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq, {f, 2003}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 2004}}.
  {label, 2003}.
    {move, {atom, true}, {x, 0}}.
  {label, 2004}.
    {test, is_eq, {f, 2002}, [{x, 0}, {atom, true}]}.
    {test, is_ne, {f, 2006}, [{y, 0}, {integer, 0}]}.
    {jump, {f, 2007}}.
  {label, 2006}.
    {move, {literal, {panic, <<"division by zero: / on f64 at src/math.bp:2329:50">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 2007}.
    {gc_bif, '/', {f, 0}, 0, [{float, 1.0}, {y, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {float, 1.0}], {x, 0}}.
    {jump, {f, 2005}}.
  {label, 2002}.
    {test, is_ne, {f, 2008}, [{y, 0}, {integer, 0}]}.
    {jump, {f, 2009}}.
  {label, 2008}.
    {move, {literal, {panic, <<"division by zero: / on f64 at src/math.bp:2329:69">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 2009}.
    {gc_bif, '/', {f, 0}, 0, [{float, 1.0}, {y, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {float, 1.0}], {x, 0}}.
  {label, 2005}.
    {deallocate, 10}.
    return.
  {label, 2001}.
    {move, {float, 0.0}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {test, is_lt, {f, 2010}, [{y, 1}, {float, 1077280768.0}]}.
    {test, is_lt, {f, 2011}, [{y, 1}, {float, 1043333120.0}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 10}.
    return.
  {label, 2011}.
    {test, is_ge, {f, 2012}, [{y, 1}, {float, 1072693248.0}]}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, abs, 1}}.
    {gc_bif, '*', {f, 0}, 1, [{float, 2.0}, {x, 0}], {x, 0}}.
    {call, 1, {f, 85}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 4}, {float, 2.0}], {x, 0}}.
    {test, is_ne, {f, 2013}, [{x, 0}, {integer, 0}]}.
    {jump, {f, 2014}}.
  {label, 2013}.
    {move, {literal, {panic, <<"division by zero: / on f64 at src/math.bp:2335:27">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 2014}.
    {gc_bif, '/', {f, 0}, 1, [{float, 2.0}, {x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{float, 1.0}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 2015}}.
  {label, 2012}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, abs, 1}}.
    {gc_bif, '*', {f, 0}, 1, [{float, -2.0}, {x, 0}], {x, 0}}.
    {call, 1, {f, 85}}.
    {move, {x, 0}, {y, 5}}.
    {gc_bif, '*', {f, 0}, 0, [{float, -1.0}, {y, 5}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '+', {f, 0}, 2, [{y, 5}, {float, 2.0}], {x, 0}}.
    {test, is_ne, {f, 2016}, [{x, 0}, {integer, 0}]}.
    {jump, {f, 2017}}.
  {label, 2016}.
    {move, {literal, {panic, <<"division by zero: / on f64 at src/math.bp:2338:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 2017}.
    {gc_bif, '/', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
  {label, 2015}.
    {jump, {f, 2018}}.
  {label, 2010}.
    {gc_bif, '-', {f, 0}, 0, [{float, 1.0}, {float, 1.0e-300}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
  {label, 2018}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq, {f, 2020}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 2021}}.
  {label, 2020}.
    {move, {atom, true}, {x, 0}}.
  {label, 2021}.
    {test, is_eq, {f, 2019}, [{x, 0}, {atom, true}]}.
    {move, {y, 3}, {x, 0}}.
    {jump, {f, 2022}}.
  {label, 2019}.
    {gc_bif, '*', {f, 0}, 0, [{float, -1.0}, {y, 3}], {x, 0}}.
  {label, 2022}.
    {deallocate, 10}.
    return.
% ── tests ────────────────────────────────────────────────────────────────────

{function, '__bp_priv__acosBody', 1, 2024}.
  {label, 2023}.
    {line, [{location, "std@math.erl", 86}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__acosBody'}, 1}.
  {label, 2024}.
    {call_only, 1, {f, 147}}.

{function, '__bp_priv__asinBody', 1, 2026}.
  {label, 2025}.
    {line, [{location, "std@math.erl", 87}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__asinBody'}, 1}.
  {label, 2026}.
    {call_only, 1, {f, 145}}.

{function, '__bp_priv__asinPoly', 1, 2028}.
  {label, 2027}.
    {line, [{location, "std@math.erl", 88}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__asinPoly'}, 1}.
  {label, 2028}.
    {call_only, 1, {f, 143}}.

{function, '__bp_priv__atan2Body', 2, 2030}.
  {label, 2029}.
    {line, [{location, "std@math.erl", 89}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__atan2Body'}, 2}.
  {label, 2030}.
    {call_only, 2, {f, 151}}.

{function, '__bp_priv__atanBody', 1, 2032}.
  {label, 2031}.
    {line, [{location, "std@math.erl", 90}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__atanBody'}, 1}.
  {label, 2032}.
    {call_only, 1, {f, 149}}.

{function, '__bp_priv__cosBody', 1, 2034}.
  {label, 2033}.
    {line, [{location, "std@math.erl", 91}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__cosBody'}, 1}.
  {label, 2034}.
    {call_only, 1, {f, 139}}.

{function, '__bp_priv__coshBody', 1, 2036}.
  {label, 2035}.
    {line, [{location, "std@math.erl", 92}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__coshBody'}, 1}.
  {label, 2036}.
    {call_only, 1, {f, 155}}.

{function, '__bp_priv__expBody', 1, 2038}.
  {label, 2037}.
    {line, [{location, "std@math.erl", 93}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__expBody'}, 1}.
  {label, 2038}.
    {call_only, 1, {f, 83}}.

{function, '__bp_priv__expHead', 1, 2040}.
  {label, 2039}.
    {line, [{location, "std@math.erl", 94}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__expHead'}, 1}.
  {label, 2040}.
    {call_only, 1, {f, 123}}.

{function, '__bp_priv__expTail', 1, 2042}.
  {label, 2041}.
    {line, [{location, "std@math.erl", 95}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__expTail'}, 1}.
  {label, 2042}.
    {call_only, 1, {f, 125}}.

{function, '__bp_priv__expm1Body', 1, 2044}.
  {label, 2043}.
    {line, [{location, "std@math.erl", 96}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__expm1Body'}, 1}.
  {label, 2044}.
    {call_only, 1, {f, 85}}.

{function, '__bp_priv__exponentField', 1, 2046}.
  {label, 2045}.
    {line, [{location, "std@math.erl", 97}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__exponentField'}, 1}.
  {label, 2046}.
    {call_only, 1, {f, 81}}.

{function, '__bp_priv__exponentOf', 1, 2048}.
  {label, 2047}.
    {line, [{location, "std@math.erl", 98}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__exponentOf'}, 1}.
  {label, 2048}.
    {call_only, 1, {f, 65}}.

{function, '__bp_priv__fromWords', 2, 2050}.
  {label, 2049}.
    {line, [{location, "std@math.erl", 99}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__fromWords'}, 2}.
  {label, 2050}.
    {call_only, 2, {f, 73}}.

{function, '__bp_priv__fusedMultiplyAdd', 3, 2052}.
  {label, 2051}.
    {line, [{location, "std@math.erl", 100}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__fusedMultiplyAdd'}, 3}.
  {label, 2052}.
    {call_only, 3, {f, 109}}.

{function, '__bp_priv__highWord', 1, 2054}.
  {label, 2053}.
    {line, [{location, "std@math.erl", 101}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__highWord'}, 1}.
  {label, 2054}.
    {call_only, 1, {f, 69}}.

{function, '__bp_priv__isZero', 1, 2056}.
  {label, 2055}.
    {line, [{location, "std@math.erl", 102}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__isZero'}, 1}.
  {label, 2056}.
    {call_only, 1, {f, 79}}.

{function, '__bp_priv__kernelCos', 2, 2058}.
  {label, 2057}.
    {line, [{location, "std@math.erl", 103}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__kernelCos'}, 2}.
  {label, 2058}.
    {call_only, 2, {f, 129}}.

{function, '__bp_priv__kernelSin', 3, 2060}.
  {label, 2059}.
    {line, [{location, "std@math.erl", 104}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__kernelSin'}, 3}.
  {label, 2060}.
    {call_only, 3, {f, 131}}.

{function, '__bp_priv__kernelTan', 3, 2062}.
  {label, 2061}.
    {line, [{location, "std@math.erl", 105}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__kernelTan'}, 3}.
  {label, 2062}.
    {call_only, 3, {f, 133}}.

{function, '__bp_priv__lnBody', 1, 2064}.
  {label, 2063}.
    {line, [{location, "std@math.erl", 106}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__lnBody'}, 1}.
  {label, 2064}.
    {call_only, 1, {f, 93}}.

{function, '__bp_priv__log10Body', 1, 2066}.
  {label, 2065}.
    {line, [{location, "std@math.erl", 107}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__log10Body'}, 1}.
  {label, 2066}.
    {call_only, 1, {f, 99}}.

{function, '__bp_priv__log2Body', 1, 2068}.
  {label, 2067}.
    {line, [{location, "std@math.erl", 108}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__log2Body'}, 1}.
  {label, 2068}.
    {call_only, 1, {f, 97}}.

{function, '__bp_priv__logMantissaBits', 1, 2070}.
  {label, 2069}.
    {line, [{location, "std@math.erl", 109}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__logMantissaBits'}, 1}.
  {label, 2070}.
    {call_only, 1, {f, 91}}.

{function, '__bp_priv__logOnePlusTail', 1, 2072}.
  {label, 2071}.
    {line, [{location, "std@math.erl", 110}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__logOnePlusTail'}, 1}.
  {label, 2072}.
    {call_only, 1, {f, 95}}.

{function, '__bp_priv__logScaled', 2, 2074}.
  {label, 2073}.
    {line, [{location, "std@math.erl", 111}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__logScaled'}, 2}.
  {label, 2074}.
    {call_only, 2, {f, 89}}.

{function, '__bp_priv__logSpecial', 1, 2076}.
  {label, 2075}.
    {line, [{location, "std@math.erl", 112}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__logSpecial'}, 1}.
  {label, 2076}.
    {call_only, 1, {f, 87}}.

{function, '__bp_priv__lowWord', 1, 2078}.
  {label, 2077}.
    {line, [{location, "std@math.erl", 113}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__lowWord'}, 1}.
  {label, 2078}.
    {call_only, 1, {f, 71}}.

{function, '__bp_priv__powBody', 2, 2080}.
  {label, 2079}.
    {line, [{location, "std@math.erl", 114}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__powBody'}, 2}.
  {label, 2080}.
    {call_only, 2, {f, 113}}.

{function, '__bp_priv__powExp', 3, 2082}.
  {label, 2081}.
    {line, [{location, "std@math.erl", 115}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__powExp'}, 3}.
  {label, 2082}.
    {call_only, 3, {f, 115}}.

{function, '__bp_priv__powInvc', 1, 2084}.
  {label, 2083}.
    {line, [{location, "std@math.erl", 116}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__powInvc'}, 1}.
  {label, 2084}.
    {call_only, 1, {f, 117}}.

{function, '__bp_priv__powLogc', 1, 2086}.
  {label, 2085}.
    {line, [{location, "std@math.erl", 117}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__powLogc'}, 1}.
  {label, 2086}.
    {call_only, 1, {f, 119}}.

{function, '__bp_priv__powLogctail', 1, 2088}.
  {label, 2087}.
    {line, [{location, "std@math.erl", 118}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__powLogctail'}, 1}.
  {label, 2088}.
    {call_only, 1, {f, 121}}.

{function, '__bp_priv__productError', 3, 2090}.
  {label, 2089}.
    {line, [{location, "std@math.erl", 119}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__productError'}, 3}.
  {label, 2090}.
    {call_only, 3, {f, 103}}.

{function, '__bp_priv__quadrantOf', 1, 2092}.
  {label, 2091}.
    {line, [{location, "std@math.erl", 120}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__quadrantOf'}, 1}.
  {label, 2092}.
    {call_only, 1, {f, 135}}.

{function, '__bp_priv__remPio2', 2, 2094}.
  {label, 2093}.
    {line, [{location, "std@math.erl", 121}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__remPio2'}, 2}.
  {label, 2094}.
    {call_only, 2, {f, 127}}.

{function, '__bp_priv__roundHalfUp', 1, 2096}.
  {label, 2095}.
    {line, [{location, "std@math.erl", 122}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__roundHalfUp'}, 1}.
  {label, 2096}.
    {call_only, 1, {f, 59}}.

{function, '__bp_priv__signBit', 1, 2098}.
  {label, 2097}.
    {line, [{location, "std@math.erl", 123}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__signBit'}, 1}.
  {label, 2098}.
    {call_only, 1, {f, 77}}.

{function, '__bp_priv__sinBody', 1, 2100}.
  {label, 2099}.
    {line, [{location, "std@math.erl", 124}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__sinBody'}, 1}.
  {label, 2100}.
    {call_only, 1, {f, 137}}.

{function, '__bp_priv__sinhBody', 1, 2102}.
  {label, 2101}.
    {line, [{location, "std@math.erl", 125}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__sinhBody'}, 1}.
  {label, 2102}.
    {call_only, 1, {f, 153}}.

{function, '__bp_priv__subnormalBits', 1, 2104}.
  {label, 2103}.
    {line, [{location, "std@math.erl", 126}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__subnormalBits'}, 1}.
  {label, 2104}.
    {call_only, 1, {f, 67}}.

{function, '__bp_priv__sumError', 3, 2106}.
  {label, 2105}.
    {line, [{location, "std@math.erl", 127}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__sumError'}, 3}.
  {label, 2106}.
    {call_only, 3, {f, 101}}.

{function, '__bp_priv__sumRoundedToOdd', 2, 2108}.
  {label, 2107}.
    {line, [{location, "std@math.erl", 128}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__sumRoundedToOdd'}, 2}.
  {label, 2108}.
    {call_only, 2, {f, 107}}.

{function, '__bp_priv__tanBody', 1, 2110}.
  {label, 2109}.
    {line, [{location, "std@math.erl", 129}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__tanBody'}, 1}.
  {label, 2110}.
    {call_only, 1, {f, 141}}.

{function, '__bp_priv__tanhBody', 1, 2112}.
  {label, 2111}.
    {line, [{location, "std@math.erl", 130}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__tanhBody'}, 1}.
  {label, 2112}.
    {call_only, 1, {f, 157}}.

{function, '__bp_priv__timesHuge', 2, 2114}.
  {label, 2113}.
    {line, [{location, "std@math.erl", 131}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__timesHuge'}, 2}.
  {label, 2114}.
    {call_only, 2, {f, 61}}.

{function, '__bp_priv__twoTo', 1, 2116}.
  {label, 2115}.
    {line, [{location, "std@math.erl", 132}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__twoTo'}, 1}.
  {label, 2116}.
    {call_only, 1, {f, 63}}.

{function, '__bp_priv__unitInFirstPlace', 1, 2118}.
  {label, 2117}.
    {line, [{location, "std@math.erl", 133}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__unitInFirstPlace'}, 1}.
  {label, 2118}.
    {call_only, 1, {f, 105}}.

{function, '__bp_priv__wholeKind', 1, 2120}.
  {label, 2119}.
    {line, [{location, "std@math.erl", 134}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__wholeKind'}, 1}.
  {label, 2120}.
    {call_only, 1, {f, 111}}.

{function, '__bp_priv__withLowZero', 1, 2122}.
  {label, 2121}.
    {line, [{location, "std@math.erl", 135}]}.
    {func_info, {atom, std@math}, {atom, '__bp_priv__withLowZero'}, 1}.
  {label, 2122}.
    {call_only, 1, {f, 75}}.

{function, '__bp_add', 2, 1937}.
  {label, 1936}.
    {line, [{location, "std@math.erl", 83}]}.
    {func_info, {atom, std@math}, {atom, '__bp_add'}, 2}.
  {label, 1937}.
    {test, is_binary, {f, 1938}, [{x, 0}]}.
    {test, is_binary, {f, 1938}, [{x, 1}]}.
    {test_heap, 4, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call_ext_only, 1, {extfunc, erlang, iolist_to_binary, 1}}.
  {label, 1938}.
    {gc_bif, '+', {f, 0}, 2, [{x, 0}, {x, 1}], {x, 0}}.
    return.
