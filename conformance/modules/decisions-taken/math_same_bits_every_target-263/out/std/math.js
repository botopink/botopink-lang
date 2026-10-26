//// std/math — math functions and constants (cross-backend).

//// 

//// Reference:

////   Node.js  — https://nodejs.org/api/  (the `Math` global)

////   Erlang   — https://www.erlang.org/doc/apps/stdlib/math.html

//// 

//// Surface mirrors the intersection of `Math.*` (JS) and `math:*` (Erlang).

//// `floor`/`ceil`/`trunc`/`round` return `f64` (both Node and Erlang return

//// floating-point on the host, and staying in `f64` keeps mixed arithmetic

//// from running into i32/i64 unification issues in pure-botopink

//// derivations). Constants live as `pub val`; every host-bound fn carries

//// `#[compiler.external(.<Target>(…))]` per backend, and `#[compiler.stage(.Any)]`: a pure

//// primitive runs at build as when the program runs (decision 376 (4)).

// ── constants ────────────────────────────────────────────────────────────────

const pi = 3.141592653589793;

exports.pi = pi;

const e = 2.718281828459045;

exports.e = e;

const tau = 6.283185307179586;

exports.tau = tau;

const sqrt2 = 1.4142135623730951;

exports.sqrt2 = sqrt2;

const ln2 = 0.6931471805599453;

exports.ln2 = ln2;

const ln10 = 2.302585092994046;

exports.ln10 = ln10;

const log2e = 1.4426950408889634;

exports.log2e = log2e;

const log10e = 0.4342944819032518;

exports.log10e = log10e;

// ── arithmetic + rounding ────────────────────────────────────────────────────

// `abs` works on `f64`. Integer abs lives on the numeric tower

// (`primitives.bp` Signed). `minF`/`maxF` are the float variants — the

// generic ones live on `Number`.

// abs: per-call template (see annotation)
function abs(x) { return Math.abs(x); }
exports.abs = abs;

// floor: per-call template (see annotation)
function floor(x) { return Math.floor(x); }
exports.floor = floor;

// round: per-call template (see annotation)
function round(x) { return Math.round(x); }
exports.round = round;

// trunc: per-call template (see annotation)
function trunc(x) { return Math.trunc(x); }
exports.trunc = trunc;

// `ceil(x) = -floor(-x)` — a pure-botopink derivation that avoids the

// erlang inline-arithmetic template (no `math:ceil/1` BIF exists pre-OTP-26).

function ceil(x) {
    return (0.0 - Math.floor((0.0 - x)));
}
exports.ceil = ceil;

// `sign` returns -1.0, 0.0, or 1.0 depending on the input's sign.

// Pure-botopink; sidesteps the inline-case template the spec describes.

function sign(x) {
    return (() => { if ((x > 0.0)) { return 1.0; } else { return (() => { if ((x < 0.0)) { return (0.0 - 1.0); } else { return 0.0; } })(); } })();
}
exports.sign = sign;

// minF: per-call template (see annotation)
function minF(a, b) { return Math.min(a, b); }
exports.minF = minF;

// maxF: per-call template (see annotation)
function maxF(a, b) { return Math.max(a, b); }
exports.maxF = maxF;

function clamp(x, lo, hi) {
    return Math.max(lo, Math.min(hi, x));
}
exports.clamp = clamp;

// ── powers + roots + exp/log ─────────────────────────────────────────────────

// sqrt: per-call template (see annotation)
function sqrt(x) { return Math.sqrt(x); }
exports.sqrt = sqrt;

// Every target runs std's body (decision 610: a function whose every target

// runs botopink is a bodied `fn`).

function pow(x, y) {
    return powBody(x, y);
}
exports.pow = pow;

// `cbrt(x)` via `pow(x, 1/3)`, honouring sign for negatives. Pure-botopink;

// node has `Math.cbrt` but the erlang side has no BIF — composition is uniform.

function cbrt(x) {
    return (() => { if ((x >= 0.0)) { return pow(x, 0.3333333333333333); } else { return (0.0 - pow((0.0 - x), 0.3333333333333333)); } })();
}
exports.cbrt = cbrt;

// exp: per-call template (see annotation)
function exp(x) { return Math.exp(x); }
exports.exp = exp;

// ln: per-call template (see annotation)
function ln(x) { return Math.log(x); }
exports.ln = ln;

// log2: per-call template (see annotation)
function log2(x) { return Math.log2(x); }
exports.log2 = log2;

// log10: per-call template (see annotation)
function log10(x) { return Math.log10(x); }
exports.log10 = log10;

// `hypot(x, y) = sqrt(x*x + y*y)` — pure-botopink composition.

function hypot(x, y) {
    return Math.sqrt(((x * x) + (y * y)));
}
exports.hypot = hypot;

// ── trigonometry ─────────────────────────────────────────────────────────────

// sin: per-call template (see annotation)
function sin(x) { return Math.sin(x); }
exports.sin = sin;

// cos: per-call template (see annotation)
function cos(x) { return Math.cos(x); }
exports.cos = cos;

// tan: per-call template (see annotation)
function tan(x) { return Math.tan(x); }
exports.tan = tan;

// asin: per-call template (see annotation)
function asin(x) { return Math.asin(x); }
exports.asin = asin;

// acos: per-call template (see annotation)
function acos(x) { return Math.acos(x); }
exports.acos = acos;

// atan: per-call template (see annotation)
function atan(x) { return Math.atan(x); }
exports.atan = atan;

// atan2: per-call template (see annotation)
function atan2(y, x) { return Math.atan2(y, x); }
exports.atan2 = atan2;

// sinh: per-call template (see annotation)
function sinh(x) { return Math.sinh(x); }
exports.sinh = sinh;

// cosh: per-call template (see annotation)
function cosh(x) { return Math.cosh(x); }
exports.cosh = cosh;

// tanh: per-call template (see annotation)
function tanh(x) { return Math.tanh(x); }
exports.tanh = tanh;

// ── the bodies (decisions 238, 263) ────────────────────────────────────────

// Each transcendental's `fn:` binding names one of these private bodies:

// erlang, beam and wasm run them, so a transcendental answers the same bits

// on every target and every OS — not the platform libm OTP's `math:*` calls,

// which differs by an ulp between glibc and Apple's (`tan(1.0)`, `asin(0.5)`).

// commonJS keeps `Math.*`, because they are a port of the fdlibm code (Sun

// Microsystems, 1993) Node's V8 answers `Math.*` with

// (`deps/v8/src/base/ieee754.cc`): the same operations in the same order, so

// every target's answer is the commonJS answer bit for bit. `pow` is the one

// commonJS runs too (below). fdlibm reads and writes the two 32-bit words of

// a double; botopink has no bit operation, so the words are read and written

// with arithmetic that is exact (`highWord`, `lowWord`, `fromWords`,

// `withLowZero`). One part is not ported: the reduction of a trigonometric

// argument beyond 2^19·π/2 (`__kernel_rem_pio2`), which panics rather than

// answer a wrong value. wasm has an instruction for `abs`, `floor`, `trunc`,

// `sqrt`, `minF` and `maxF` (`op:`), which every target leaves to its host:

// IEEE 754 makes them exact.

// `Math.round`: V8's `Float64RoundUp(x)`, less one when that is more than a

// half above `x` — a half rounds UP (`round(2.5)` is 3, `round(-2.5)` is -2)

// and `-0.4` answers `-0`. `f64.nearest` rounds a half to even, which is why

// this is not an `op:`.

function roundHalfUp(x) {
    const up = ((-1.0) * Math.floor(((-1.0) * x)));
    return (() => { if (((up - 0.5) > x)) { return (up - 1.0); } else { return up; } })();
}

// `s · h · h`: an overflow to ±Infinity (`h` = 1e300) or an underflow to ±0

// (`h` = 1e-300) as fdlibm writes them, with `h` a parameter so no target

// folds the product at compile time.

function timesHuge(s, h) {
    return ((s * h) * h);
}

// 2^k for a whole k in -1074..1023 — every step exact.

function twoTo(k) {
    let r = 1.0;
    let n = k;
    while ((n >= 32.0)) {
    r = (r * 4294967296.0);
    n = (n - 32.0);
}
    while ((n >= 1.0)) {
    r = (r * 2.0);
    n = (n - 1.0);
}
    while ((n <= (-32.0))) {
    r = (r * 2.3283064365386963e-10);
    n = (n + 32.0);
}
    while ((n <= (-1.0))) {
    r = (r * 0.5);
    n = (n + 1.0);
}
    return r;
}

// e with 2^e ≤ ax < 2^(e+1), for a positive finite ax.

function exponentOf(ax) {
    let v = ax;
    let e = 0.0;
    while ((v >= 4294967296.0)) {
    v = (v * 2.3283064365386963e-10);
    e = (e + 32.0);
}
    while ((v >= 2.0)) {
    v = (v * 0.5);
    e = (e + 1.0);
}
    while ((v < 2.3283064365386963e-10)) {
    v = (v * 4294967296.0);
    e = (e - 32.0);
}
    while ((v < 1.0)) {
    v = (v * 2.0);
    e = (e - 1.0);
}
    return e;
}

// The 52-bit significand of a subnormal |x| as a whole number.

function subnormalBits(ax) {
    return (((ax * twoTo(1000.0))) * twoTo(74.0));
}

// fdlibm's `hx & 0x7fffffff`: the high 32-bit word of |x| as a whole number.

function highWord(x) {
    if ((!Object.is(x, x))) { return 2146959360.0; }
    const ax = Math.abs(x);
    if (isZero(ax)) { return 0.0; }
    if ((ax > 1.7976931348623157e308)) { return 2146435072.0; }
    const e = exponentOf(ax);
    if ((e < (-1022.0))) { return Math.floor((subnormalBits(ax) / 4294967296.0)); }
    const m = (ax * twoTo((0.0 - e)));
    return ((((e + 1023.0)) * 1048576.0) + Math.floor((((m - 1.0)) * 1048576.0)));
}

// fdlibm's low word: the low 32 bits of |x|'s significand.

function lowWord(x) {
    const ax = Math.abs(x);
    if ((((!Object.is(x, x)) || isZero(ax)) || (ax > 1.7976931348623157e308))) { return 0.0; }
    const e = exponentOf(ax);
    const bits = (() => { if ((e < (-1022.0))) { return subnormalBits(ax); } else { return ((((ax * twoTo((0.0 - e))) - 1.0)) * 4503599627370496.0); } })();
    return (bits - (Math.floor((bits / 4294967296.0)) * 4294967296.0));
}

// The positive double whose words are `hw` (below the sign) and `lw`.

function fromWords(hw, lw) {
    const ef = Math.floor((hw / 1048576.0));
    const frac = ((((hw - (ef * 1048576.0))) * 4294967296.0) + lw);
    if (isZero(ef)) { return (((frac * twoTo((-1000.0)))) * twoTo((-74.0))); }
    return (((1.0 + (frac / 4503599627370496.0))) * twoTo((ef - 1023.0)));
}

// fdlibm's `SET_LOW_WORD(x, 0)`.

function withLowZero(x) {
    const v = fromWords(highWord(x), 0.0);
    return (() => { if (signBit(x)) { return ((-1.0) * v); } else { return v; } })();
}

// Whether `v` carries a minus sign — `-0.0` included (fdlibm's `hx < 0`).

// commonJS and wasm compare `-0.0` equal to `0.0` and tell the two apart by

// `1 / v`; erlang and beam compare them unequal (`=:=`) and have no `1 / 0`.

function signBit(v) {
    if ((v < 0.0)) { return true; }
    if ((v > 0.0)) { return false; }
    if ((Object.is(v, 0.0) && Object.is(v, (-0.0)))) { return ((1.0 / v) < 0.0); }
    return Object.is(v, (-0.0));
}

// Whether `v` is `0.0` or `-0.0` — on every target: `v == 0.0` is false for

// `-0.0` on erlang and beam (`=:=`).

function isZero(v) {
    return ((v >= 0.0) && (v <= 0.0));
}

// The exponent field of x's high word (`(hx >> 20) & 0x7ff`).

function exponentField(x) {
    return Math.floor((highWord(x) / 1048576.0));
}

// ── exp, expm1 ───────────────────────────────────────────────────────────────

function expBody(x) {
    const hx = highWord(x);
    const neg = signBit(x);
    if ((hx >= 1082535490.0)) { if ((hx >= 2146435072.0)) { if ((!Object.is(x, x))) { return (x + x); } return (() => { if (neg) { return 0.0; } else { return x; } })(); } if ((x > 7.09782712893383973096e+02)) { return timesHuge(1.0, 1.0e300); } if ((x < (-7.45133219101941108420e+02))) { return timesHuge(1.0, 9.33263618503218878990e-302); } }
    let hi = 0.0;
    let lo = 0.0;
    let k = 0.0;
    let r = x;
    if ((hx > 1071001154.0)) { if ((hx < 1072734898.0)) { if (Object.is(x, 1.0)) { return 2.718281828459045; } (() => { if (neg) { hi = (x + 6.93147180369123816490e-01); lo = (-1.90821492927058770002e-10); return k = (-1.0); } else { hi = (x - 6.93147180369123816490e-01); lo = 1.90821492927058770002e-10; return k = 1.0; } })(); } else { const half = (() => { if (neg) { return (-0.5); } else { return 0.5; } })(); k = Math.trunc(((1.44269504088896338700e+00 * x) + half)); hi = (x - (k * 6.93147180369123816490e-01)); lo = (k * 1.90821492927058770002e-10); } r = (hi - lo); } else { if ((hx < 1043333120.0)) { return (1.0 + x); } }
    const t = (r * r);
    const twopk = (() => { if ((k >= (-1021.0))) { return twoTo(k); } else { return twoTo((k + 1000.0)); } })();
    const c = (r - (t * ((1.66666666666666019037e-01 + (t * (((-2.77777777770155933842e-03) + (t * ((6.61375632143793436117e-05 + (t * (((-1.65339022054652515390e-06) + (t * 4.13813679705723846039e-08))))))))))))));
    if (isZero(k)) { return (1.0 - (((((r * c)) / ((c - 2.0))) - r))); }
    const y = (1.0 - ((((lo - (((r * c)) / ((2.0 - c))))) - hi)));
    if ((k >= (-1021.0))) { if (Object.is(k, 1024.0)) { return ((y * 2.0) * 8.988465674311579539e307); } return (y * twopk); }
    return ((y * twopk) * 9.33263618503218878990e-302);
}

function expm1Body(x) {
    const hx = highWord(x);
    const neg = signBit(x);
    if ((hx >= 1078159482.0)) { if ((hx >= 1082535490.0)) { if ((hx >= 2146435072.0)) { if ((!Object.is(x, x))) { return (x + x); } return (() => { if (neg) { return (-1.0); } else { return x; } })(); } if ((x > 7.09782712893383973096e+02)) { return timesHuge(1.0, 1.0e300); } } if ((neg && ((x + 1.0e-300) < 0.0))) { return (1.0e-300 - 1.0); } }
    let k = 0.0;
    let r = x;
    let c = 0.0;
    if ((hx > 1071001154.0)) { let hi = 0.0; let lo = 0.0; (() => { if ((hx < 1072734898.0)) { return (() => { if ((!neg)) { hi = (x - 6.93147180369123816490e-01); lo = 1.90821492927058770002e-10; return k = 1.0; } else { hi = (x + 6.93147180369123816490e-01); lo = (-1.90821492927058770002e-10); return k = (-1.0); } })(); } else { const half = (() => { if (neg) { return (-0.5); } else { return 0.5; } })(); k = Math.trunc(((1.44269504088896338700e+00 * x) + half)); hi = (x - (k * 6.93147180369123816490e-01)); return lo = (k * 1.90821492927058770002e-10); } })(); r = (hi - lo); c = (((hi - r)) - lo); } else { if ((hx < 1016070144.0)) { return x; } }
    const hfx = (0.5 * r);
    const hxs = (r * hfx);
    const r1 = (1.0 + (hxs * (((-3.33333333333331316428e-02) + (hxs * ((1.58730158725481460165e-03 + (hxs * (((-7.93650757867487942473e-05) + (hxs * ((4.00821782732936239552e-06 + (hxs * (-2.01099218183624371326e-07)))))))))))))));
    const t = (3.0 - (r1 * hfx));
    let e = (hxs * ((((r1 - t)) / ((6.0 - (r * t))))));
    if (isZero(k)) { return (r - (((r * e) - hxs))); }
    const twopk = twoTo(k);
    e = ((r * ((e - c))) - c);
    e = (e - hxs);
    if (Object.is(k, (-1.0))) { return ((0.5 * ((r - e))) - 0.5); }
    if (Object.is(k, 1.0)) { return (() => { if ((r < (-0.25))) { return ((-2.0) * ((e - ((r + 0.5))))); } else { return (1.0 + (2.0 * ((r - e)))); } })(); }
    if (((k <= (-2.0)) || (k > 56.0))) { const y = (1.0 - ((e - r))); const scaled = (() => { if (Object.is(k, 1024.0)) { return ((y * 2.0) * 8.98846567431158e+307); } else { return (y * twopk); } })(); return (scaled - 1.0); }
    if ((k < 20.0)) { const t2 = fromWords((1072693248.0 - twoTo((21.0 - k))), 0.0); return (((t2 - ((e - r)))) * twopk); }
    const t3 = fromWords((((1023.0 - k)) * 1048576.0), 0.0);
    return (((((r - ((e + t3)))) + 1.0)) * twopk);
}

// ── logarithms ───────────────────────────────────────────────────────────────

// fdlibm's answer for what is not a positive finite number.

function logSpecial(x) {
    if (((!Object.is(x, x)) || (x > 1.7976931348623157e308))) { return (x + x); }
    if ((x < 0.0)) { return (((x - x)) / ((x - x))); }
    return ((-1.0) / ((x * x)));
}

// `x` with its exponent set to 0 (or -1, when the mantissa's high bits pass

// √2's — fdlibm's `(hx + 0x95f64) & 0x100000`), and how much the exponent

// moved: `logScaled(x, 0)` answers the scaled `x`, `logScaled(x, 1)` the `k`.

function logScaled(x, which) {
    let k = 0.0;
    let v = x;
    (() => { if ((x < 2.2250738585072014e-308)) { k = (-54.0); return v = (x * 1.80143985094819840000e+16); } })();
    const hw = highWord(v);
    const ef = Math.floor((hw / 1048576.0));
    const m20 = (hw - (ef * 1048576.0));
    const up = ((m20 + 614244.0) >= 1048576.0);
    const carry = (() => { if (up) { return 1.0; } else { return 0.0; } })();
    k = (((k + ef) - 1023.0) + carry);
    if ((which > 0.5)) { return k; }
    const field = (() => { if (up) { return 1071644672.0; } else { return 1072693248.0; } })();
    return fromWords((field + m20), lowWord(v));
}

// The high mantissa bits (`hx & 0xfffff`) the scaled `x` came from.

function logMantissaBits(x) {
    const v = (() => { if ((x < 2.2250738585072014e-308)) { return (x * 1.80143985094819840000e+16); } else { return x; } })();
    const hw = highWord(v);
    return (hw - (Math.floor((hw / 1048576.0)) * 1048576.0));
}

function lnBody(x) {
    if ((((!Object.is(x, x)) || (x <= 0.0)) || (x > 1.7976931348623157e308))) { return logSpecial(x); }
    const k = logScaled(x, 1.0);
    const f = (logScaled(x, 0.0) - 1.0);
    const m20 = logMantissaBits(x);
    const ln2Hi = 6.93147180369123816490e-01;
    const ln2Lo = 1.90821492927058770002e-10;
    if (((m20 >= 1048574.0) || isZero(m20))) { if (isZero(f)) { return (() => { if (isZero(k)) { return 0.0; } else { return ((k * ln2Hi) + (k * ln2Lo)); } })(); } const rr = ((f * f) * ((0.5 - (0.33333333333333333 * f)))); return (() => { if (isZero(k)) { return (f - rr); } else { return ((k * ln2Hi) - ((((rr - (k * ln2Lo))) - f))); } })(); }
    const s = (f / ((2.0 + f)));
    const z = (s * s);
    const w = (z * z);
    const t1 = (w * ((3.999999999940941908e-01 + (w * ((2.222219843214978396e-01 + (w * 1.531383769920937332e-01)))))));
    const t2 = (z * ((6.666666666666735130e-01 + (w * ((2.857142874366239149e-01 + (w * ((1.818357216161805012e-01 + (w * 1.479819860511658591e-01))))))))));
    const rr = (t2 + t1);
    if (((m20 >= 398458.0) && (m20 <= 440401.0))) { const hfsq = ((0.5 * f) * f); return (() => { if (isZero(k)) { return (f - ((hfsq - (s * ((hfsq + rr)))))); } else { return ((k * ln2Hi) - ((((hfsq - (((s * ((hfsq + rr))) + (k * ln2Lo))))) - f))); } })(); }
    return (() => { if (isZero(k)) { return (f - (s * ((f - rr)))); } else { return ((k * ln2Hi) - (((((s * ((f - rr))) - (k * ln2Lo))) - f))); } })();
}

// fdlibm's `k_log1p(f)`.

function logOnePlusTail(f) {
    const s = (f / ((2.0 + f)));
    const z = (s * s);
    const w = (z * z);
    const t1 = (w * ((3.999999999940941908e-01 + (w * ((2.222219843214978396e-01 + (w * 1.531383769920937332e-01)))))));
    const t2 = (z * ((6.666666666666735130e-01 + (w * ((2.857142874366239149e-01 + (w * ((1.818357216161805012e-01 + (w * 1.479819860511658591e-01))))))))));
    const hfsq = ((0.5 * f) * f);
    return (s * ((hfsq + ((t2 + t1)))));
}

function log2Body(x) {
    if ((((!Object.is(x, x)) || (x <= 0.0)) || (x > 1.7976931348623157e308))) { return logSpecial(x); }
    if (Object.is(x, 1.0)) { return 0.0; }
    const y = logScaled(x, 1.0);
    const f = (logScaled(x, 0.0) - 1.0);
    const hfsq = ((0.5 * f) * f);
    const r = logOnePlusTail(f);
    const hi = withLowZero((f - hfsq));
    const lo = ((((f - hi)) - hfsq) + r);
    const valHi = (hi * 1.44269504072144627571e+00);
    const valLo = ((((lo + hi)) * 1.67517131648865118353e-10) + (lo * 1.44269504072144627571e+00));
    const w = (y + valHi);
    return (((valLo + ((((y - w)) + valHi)))) + w);
}

function log10Body(x) {
    if ((((!Object.is(x, x)) || (x <= 0.0)) || (x > 1.7976931348623157e308))) { return logSpecial(x); }
    if (Object.is(x, 1.0)) { return 0.0; }
    let k = 0.0;
    let v = x;
    (() => { if ((x < 2.2250738585072014e-308)) { k = (-54.0); return v = (x * 1.80143985094819840000e+16); } })();
    const hw = highWord(v);
    const ef = Math.floor((hw / 1048576.0));
    k = ((k + ef) - 1023.0);
    const i = (() => { if ((k < 0.0)) { return 1.0; } else { return 0.0; } })();
    const scaled = fromWords(((hw - (ef * 1048576.0)) + (((1023.0 - i)) * 1048576.0)), lowWord(v));
    const y = (k + i);
    const z = ((y * 3.69423907715893078616e-13) + (4.34294481903251816668e-01 * lnBody(scaled)));
    return (z + (y * 3.01029995663611771306e-01));
}

// ── pow ──────────────────────────────────────────────────────────────────────

// glibc's `pow` (`sysdeps/ieee754/dbl-64/e_pow.c`, the algorithm since glibc

// 2.28, from Arm's optimized-routines) as x86-64 glibc runs it: the

// `__ieee754_pow_fma` build, whose compiler fused each `a * b + c` it could

// into one rounding. Every target runs this body (decision 259), so a pow is

// the same bits everywhere and Linux's `Math.pow` and `math:pow` bit for bit:

// `pow(158.42161580281933, 2.853827476501465)` is `1896229.4525711867`.

// log|x| is carried in double-double from a 128-entry table (`powInvc`,

// `powLogc`, `powLogctail` — glibc's `__pow_log_data`), e^(y·log|x|) from the

// 128 values of 2^(j/128) (`expHead`, `expTail` — `__exp_data`); the tables

// are glibc 2.44's, read from its libm. glibc's word operations are exact

// arithmetic here and each fused multiply-add is computed exactly

// (`fusedMultiplyAdd`). The special values are glibc's, after ECMA-262's two

// (`pow(x, NaN)` and `pow(±1, ±Infinity)` are NaN, where C answers 1), so

// commonJS answers what `Math.pow` answered.

// a + b − s exactly, for s the rounded sum (Knuth's two-sum).

function sumError(a, b, s) {
    const bb = (s - a);
    return (((a - ((s - bb)))) + ((b - bb)));
}

// a·b − p exactly, for p the rounded product (Dekker's two-product).

function productError(a, b, p) {
    const ca = (134217729.0 * a);
    const ah = (ca - ((ca - a)));
    const al = (a - ah);
    const cb = (134217729.0 * b);
    const bh = (cb - ((cb - b)));
    const bl = (b - bh);
    return (((((((ah * bh) - p)) + (ah * bl)) + (al * bh))) + (al * bl));
}

// The power of two of s's leading bit, for a normal s ≠ 0 (Rump, Zimmermann,

// Boldo and Melquiond's `ufp`: φ = 2^52 + 1, ψ = 1 − 2^-53).

function unitInFirstPlace(s) {
    const q = (4503599627370497.0 * s);
    const r = (0.9999999999999999 * q);
    return Math.abs((q - r));
}

// a + b rounded to odd: the exact sum when it is a double, else the one of

// its two neighbours whose last significand bit is 1.

function sumRoundedToOdd(a, b) {
    const s = (a + b);
    const err = sumError(a, b, s);
    if (isZero(err)) { return s; }
    const f = unitInFirstPlace(s);
    const ulp = (f * 2.220446049250313e-16);
    const mag = Math.abs(s);
    const m = (mag / ulp);
    if (Object.is((m - (2.0 * Math.floor((m * 0.5)))), 1.0)) { return s; }
    const away = (((err > 0.0)) === ((s > 0.0)));
    const stepped = (() => { if (away) { return (mag + ulp); } else { return (() => { if (Object.is(mag, f)) { return (mag - (ulp * 0.5)); } else { return (mag - ulp); } })(); } })();
    return (() => { if ((s > 0.0)) { return stepped; } else { return ((-1.0) * stepped); } })();
}

// fma(a, b, c): a·b + c rounded once (Boldo and Melquiond's emulation — the

// exact product, a two-sum, one sum rounded to odd, one rounding to nearest).

function fusedMultiplyAdd(a, b, c) {
    const uh = (a * b);
    const ul = productError(a, b, uh);
    const th = (c + uh);
    const tl = sumError(c, uh, th);
    return (th + sumRoundedToOdd(tl, ul));
}

// 0 when `y` is not a whole number, 1 when it is odd, 2 when it is even

// (glibc's `checkint`).

function wholeKind(y) {
    if ((!Object.is(Math.floor(y), y))) { return 0.0; }
    if ((Math.abs(y) >= 9007199254740992.0)) { return 2.0; }
    const half = (y * 0.5);
    return (() => { if (Object.is(Math.floor(half), half)) { return 2.0; } else { return 1.0; } })();
}

function powBody(x, y) {
    if ((!Object.is(y, y))) { return y; }
    const ax = Math.abs(x);
    const ay = Math.abs(y);
    const inf = 1.7976931348623157e308;
    if (((ay > inf) && Object.is(ax, 1.0))) { return (y - y); }
    if ((isZero(y) || Object.is(x, 1.0))) { return 1.0; }
    if ((!Object.is(x, x))) { return (x + y); }
    if ((ay > inf)) { return (() => { if ((((ax < 1.0)) === ((y > 0.0)))) { return 0.0; } else { return ay; } })(); }
    const odd = Object.is(wholeKind(y), 1.0);
    const nx = signBit(x);
    if ((isZero(ax) || (ax > inf))) { /* ±0 and ±Infinity: x², negated for an odd power of a negative x */ const x2 = (() => { if ((nx && odd)) { return ((-1.0) * ((x * x))); } else { return (x * x); } })(); return (() => { if ((y < 0.0)) { return (1.0 / x2); } else { return x2; } })(); }
    if ((nx && isZero(wholeKind(y)))) { return (((x - x)) / ((x - x))); }
    if (((ay < 2.710505431213761e-20) || (ay >= 9.223372036854776e18))) { if (Object.is(ax, 1.0)) { return 1.0; } if ((ay < 2.710505431213761e-20)) { return (() => { if ((ax > 1.0)) { return (1.0 + y); } else { return (1.0 - y); } })(); } return (() => { if ((((ax > 1.0)) === ((y > 0.0)))) { return timesHuge(1.0, 1.0e300); } else { return timesHuge(1.0, 1.0e-300); } })(); }
    // log|x| = k·ln2 + log c + log1p(z/c − 1), |x| = 2^k·z with z in;
    // [0x1.69555p-1, 0x1.69555p0) and c near the middle of z's subinterval;
    const sub = (ax < 2.2250738585072014e-308);
    const xs = (() => { if (sub) { return (ax * 4503599627370496.0); } else { return ax; } })();
    const e = exponentOf(xs);
    const m = (xs * twoTo((0.0 - e)));
    const big = (m >= 1.4114580154418945);
    const z = (() => { if (big) { return (m * 0.5); } else { return m; } })();
    const kz = (() => { if (big) { return (e + 1.0); } else { return e; } })();
    const k = (() => { if (sub) { return (kz - 52.0); } else { return kz; } })();
    const i = (() => { if ((z < 1.0)) { return Math.floor((((z - 0.7057290077209473)) * 256.0)); } else { return Math.floor(((((z - 1.0)) * 128.0) + 75.3333740234375)); } })();
    const invc = powInvc(i);
    const logc = powLogc(i);
    const zc = (z * invc);
    const r = (((zc - 1.0)) + productError(z, invc, zc));
    const t1 = ((k * 0.6931471805598903) + logc);
    const t2 = (t1 + r);
    const lo1 = fusedMultiplyAdd(k, 5.497923018708371e-14, powLogctail(i));
    const lo2 = ((t1 - t2) + r);
    const ar = ((-0.5) * r);
    const ar2 = (r * ar);
    const ar3 = (r * ar2);
    const lhi = (t2 + ar2);
    const lo3 = productError(ar, r, ar2);
    const lo4 = ((t2 - lhi) + ar2);
    const q = fusedMultiplyAdd(ar2, fusedMultiplyAdd(ar2, fusedMultiplyAdd(r, 1.0000415263675542, (-1.142909628459501)), fusedMultiplyAdd(r, (-0.6666666663487739), 0.7999999995323976)), fusedMultiplyAdd(r, 0.5000000000000007, (-0.6666666666666679)));
    const llo = fusedMultiplyAdd(ar3, q, (((lo1 + lo2) + lo3) + lo4));
    const l = (lhi + llo);
    const ltail = ((lhi - l) + llo);
    // e^(y·log|x|), y·log|x| carried as ehi + elo;
    const ehi = (y * l);
    const elo = fusedMultiplyAdd(y, ltail, productError(y, l, ehi));
    return powExp(ehi, elo, (nx && odd));
}

// glibc's `exp_inline`: ±e^(x + xtail), the sign minus when `neg`.

function powExp(x, xtail, neg) {
    const s = (() => { if (neg) { return (-1.0); } else { return 1.0; } })();
    const ax = Math.abs(x);
    if ((ax < 5.551115123125783e-17)) { return (s * ((1.0 + x))); }
    if ((ax >= 1024.0)) { return (() => { if ((x < 0.0)) { return timesHuge(s, 1.0e-300); } else { return timesHuge(s, 1.0e300); } })(); }
    // x = k·ln2/128 + r, e^x = 2^(k/128)·e^r, j = k mod 128;
    const kd = (fusedMultiplyAdd(184.6649652337873, x, 6755399441055744.0) - 6755399441055744.0);
    const r = (fusedMultiplyAdd(kd, (-1.2864023111638346e-14), fusedMultiplyAdd(kd, (-0.005415212348111709), x)) + xtail);
    const j = (kd - (128.0 * Math.floor((kd / 128.0))));
    const r2 = (r * r);
    const tmp = fusedMultiplyAdd((r2 * r2), fusedMultiplyAdd(r, 0.008333335853059549, 0.0416666808410674), fusedMultiplyAdd(r2, fusedMultiplyAdd(r, 0.16666666666665886, 0.49999999999996786), (expTail(j) + r)));
    const n = (((kd - j)) / 128.0);
    if ((ax < 512.0)) { const scale = ((s * expHead(j)) * twoTo(n)); return fusedMultiplyAdd(scale, tmp, scale); }
    // glibc's `specialcase`: the scale's exponent kept in range, then the;
    // result scaled — rounded once more in the subnormal range;
    if ((kd > 0.0)) { const big = ((s * expHead(j)) * twoTo((n - 1009.0))); return (5.486124068793689e303 * fusedMultiplyAdd(big, tmp, big)); }
    const scale = ((s * expHead(j)) * twoTo((n + 1022.0)));
    const st = (scale * tmp);
    const v = (scale + st);
    if ((Math.abs(v) >= 1.0)) { return (2.2250738585072014e-308 * v); }
    const one = (() => { if ((v < 0.0)) { return (-1.0); } else { return 1.0; } })();
    const lo0 = ((scale - v) + st);
    const hi = (one + v);
    const lo = (((one - hi) + v) + lo0);
    const w = (((hi + lo)) - one);
    const wz = (() => { if (((w > 0.0) || (w < 0.0))) { return w; } else { return (s * 0.0); } })();
    return (2.2250738585072014e-308 * wz);
}

// `__pow_log_data.tab[i].invc`: 1/c for the i-th of the 128 subintervals of

// [0x1.69555p-1, 0x1.69555p0) — a number of few bits, so z/c − 1 is exact.

function powInvc(i) {
    return (() => { if ((i < 64.0)) { return (() => { if ((i < 32.0)) { return (() => { if ((i < 16.0)) { return (() => { if ((i < 8.0)) { return (() => { if ((i < 4.0)) { return (() => { if ((i < 2.0)) { return (() => { if ((i < 1.0)) { return 1.4140625; } else { return 1.40625; } })(); } else { return (() => { if ((i < 3.0)) { return 1.3984375; } else { return 1.390625; } })(); } })(); } else { return (() => { if ((i < 6.0)) { return (() => { if ((i < 5.0)) { return 1.3828125; } else { return 1.375; } })(); } else { return (() => { if ((i < 7.0)) { return 1.3671875; } else { return 1.359375; } })(); } })(); } })(); } else { return (() => { if ((i < 12.0)) { return (() => { if ((i < 10.0)) { return (() => { if ((i < 9.0)) { return 1.3515625; } else { return 1.34375; } })(); } else { return (() => { if ((i < 11.0)) { return 1.3359375; } else { return 1.3359375; } })(); } })(); } else { return (() => { if ((i < 14.0)) { return (() => { if ((i < 13.0)) { return 1.328125; } else { return 1.3203125; } })(); } else { return (() => { if ((i < 15.0)) { return 1.3125; } else { return 1.3046875; } })(); } })(); } })(); } })(); } else { return (() => { if ((i < 24.0)) { return (() => { if ((i < 20.0)) { return (() => { if ((i < 18.0)) { return (() => { if ((i < 17.0)) { return 1.296875; } else { return 1.2890625; } })(); } else { return (() => { if ((i < 19.0)) { return 1.2890625; } else { return 1.28125; } })(); } })(); } else { return (() => { if ((i < 22.0)) { return (() => { if ((i < 21.0)) { return 1.2734375; } else { return 1.265625; } })(); } else { return (() => { if ((i < 23.0)) { return 1.2578125; } else { return 1.25; } })(); } })(); } })(); } else { return (() => { if ((i < 28.0)) { return (() => { if ((i < 26.0)) { return (() => { if ((i < 25.0)) { return 1.25; } else { return 1.2421875; } })(); } else { return (() => { if ((i < 27.0)) { return 1.234375; } else { return 1.2265625; } })(); } })(); } else { return (() => { if ((i < 30.0)) { return (() => { if ((i < 29.0)) { return 1.2265625; } else { return 1.21875; } })(); } else { return (() => { if ((i < 31.0)) { return 1.2109375; } else { return 1.203125; } })(); } })(); } })(); } })(); } })(); } else { return (() => { if ((i < 48.0)) { return (() => { if ((i < 40.0)) { return (() => { if ((i < 36.0)) { return (() => { if ((i < 34.0)) { return (() => { if ((i < 33.0)) { return 1.203125; } else { return 1.1953125; } })(); } else { return (() => { if ((i < 35.0)) { return 1.1875; } else { return 1.1875; } })(); } })(); } else { return (() => { if ((i < 38.0)) { return (() => { if ((i < 37.0)) { return 1.1796875; } else { return 1.171875; } })(); } else { return (() => { if ((i < 39.0)) { return 1.171875; } else { return 1.1640625; } })(); } })(); } })(); } else { return (() => { if ((i < 44.0)) { return (() => { if ((i < 42.0)) { return (() => { if ((i < 41.0)) { return 1.15625; } else { return 1.1484375; } })(); } else { return (() => { if ((i < 43.0)) { return 1.1484375; } else { return 1.140625; } })(); } })(); } else { return (() => { if ((i < 46.0)) { return (() => { if ((i < 45.0)) { return 1.140625; } else { return 1.1328125; } })(); } else { return (() => { if ((i < 47.0)) { return 1.125; } else { return 1.125; } })(); } })(); } })(); } })(); } else { return (() => { if ((i < 56.0)) { return (() => { if ((i < 52.0)) { return (() => { if ((i < 50.0)) { return (() => { if ((i < 49.0)) { return 1.1171875; } else { return 1.109375; } })(); } else { return (() => { if ((i < 51.0)) { return 1.109375; } else { return 1.1015625; } })(); } })(); } else { return (() => { if ((i < 54.0)) { return (() => { if ((i < 53.0)) { return 1.1015625; } else { return 1.09375; } })(); } else { return (() => { if ((i < 55.0)) { return 1.0859375; } else { return 1.0859375; } })(); } })(); } })(); } else { return (() => { if ((i < 60.0)) { return (() => { if ((i < 58.0)) { return (() => { if ((i < 57.0)) { return 1.078125; } else { return 1.078125; } })(); } else { return (() => { if ((i < 59.0)) { return 1.0703125; } else { return 1.0625; } })(); } })(); } else { return (() => { if ((i < 62.0)) { return (() => { if ((i < 61.0)) { return 1.0625; } else { return 1.0546875; } })(); } else { return (() => { if ((i < 63.0)) { return 1.0546875; } else { return 1.046875; } })(); } })(); } })(); } })(); } })(); } })(); } else { return (() => { if ((i < 96.0)) { return (() => { if ((i < 80.0)) { return (() => { if ((i < 72.0)) { return (() => { if ((i < 68.0)) { return (() => { if ((i < 66.0)) { return (() => { if ((i < 65.0)) { return 1.046875; } else { return 1.0390625; } })(); } else { return (() => { if ((i < 67.0)) { return 1.0390625; } else { return 1.03125; } })(); } })(); } else { return (() => { if ((i < 70.0)) { return (() => { if ((i < 69.0)) { return 1.03125; } else { return 1.0234375; } })(); } else { return (() => { if ((i < 71.0)) { return 1.015625; } else { return 1.015625; } })(); } })(); } })(); } else { return (() => { if ((i < 76.0)) { return (() => { if ((i < 74.0)) { return (() => { if ((i < 73.0)) { return 1.0078125; } else { return 1.0078125; } })(); } else { return (() => { if ((i < 75.0)) { return 1.0; } else { return 1.0; } })(); } })(); } else { return (() => { if ((i < 78.0)) { return (() => { if ((i < 77.0)) { return 0.9921875; } else { return 0.984375; } })(); } else { return (() => { if ((i < 79.0)) { return 0.9765625; } else { return 0.96875; } })(); } })(); } })(); } })(); } else { return (() => { if ((i < 88.0)) { return (() => { if ((i < 84.0)) { return (() => { if ((i < 82.0)) { return (() => { if ((i < 81.0)) { return 0.9609375; } else { return 0.953125; } })(); } else { return (() => { if ((i < 83.0)) { return 0.9453125; } else { return 0.94140625; } })(); } })(); } else { return (() => { if ((i < 86.0)) { return (() => { if ((i < 85.0)) { return 0.93359375; } else { return 0.92578125; } })(); } else { return (() => { if ((i < 87.0)) { return 0.91796875; } else { return 0.9140625; } })(); } })(); } })(); } else { return (() => { if ((i < 92.0)) { return (() => { if ((i < 90.0)) { return (() => { if ((i < 89.0)) { return 0.90625; } else { return 0.8984375; } })(); } else { return (() => { if ((i < 91.0)) { return 0.89453125; } else { return 0.88671875; } })(); } })(); } else { return (() => { if ((i < 94.0)) { return (() => { if ((i < 93.0)) { return 0.8828125; } else { return 0.875; } })(); } else { return (() => { if ((i < 95.0)) { return 0.87109375; } else { return 0.86328125; } })(); } })(); } })(); } })(); } })(); } else { return (() => { if ((i < 112.0)) { return (() => { if ((i < 104.0)) { return (() => { if ((i < 100.0)) { return (() => { if ((i < 98.0)) { return (() => { if ((i < 97.0)) { return 0.859375; } else { return 0.8515625; } })(); } else { return (() => { if ((i < 99.0)) { return 0.84765625; } else { return 0.83984375; } })(); } })(); } else { return (() => { if ((i < 102.0)) { return (() => { if ((i < 101.0)) { return 0.8359375; } else { return 0.83203125; } })(); } else { return (() => { if ((i < 103.0)) { return 0.82421875; } else { return 0.8203125; } })(); } })(); } })(); } else { return (() => { if ((i < 108.0)) { return (() => { if ((i < 106.0)) { return (() => { if ((i < 105.0)) { return 0.8125; } else { return 0.80859375; } })(); } else { return (() => { if ((i < 107.0)) { return 0.8046875; } else { return 0.80078125; } })(); } })(); } else { return (() => { if ((i < 110.0)) { return (() => { if ((i < 109.0)) { return 0.79296875; } else { return 0.7890625; } })(); } else { return (() => { if ((i < 111.0)) { return 0.78515625; } else { return 0.78125; } })(); } })(); } })(); } })(); } else { return (() => { if ((i < 120.0)) { return (() => { if ((i < 116.0)) { return (() => { if ((i < 114.0)) { return (() => { if ((i < 113.0)) { return 0.7734375; } else { return 0.76953125; } })(); } else { return (() => { if ((i < 115.0)) { return 0.765625; } else { return 0.76171875; } })(); } })(); } else { return (() => { if ((i < 118.0)) { return (() => { if ((i < 117.0)) { return 0.7578125; } else { return 0.75390625; } })(); } else { return (() => { if ((i < 119.0)) { return 0.74609375; } else { return 0.7421875; } })(); } })(); } })(); } else { return (() => { if ((i < 124.0)) { return (() => { if ((i < 122.0)) { return (() => { if ((i < 121.0)) { return 0.73828125; } else { return 0.734375; } })(); } else { return (() => { if ((i < 123.0)) { return 0.73046875; } else { return 0.7265625; } })(); } })(); } else { return (() => { if ((i < 126.0)) { return (() => { if ((i < 125.0)) { return 0.72265625; } else { return 0.71875; } })(); } else { return (() => { if ((i < 127.0)) { return 0.71484375; } else { return 0.7109375; } })(); } })(); } })(); } })(); } })(); } })(); } })();
}

// `__pow_log_data.tab[i].logc`: log c, its last bits rounded away so

// k·ln2hi + logc is exact.

function powLogc(i) {
    return (() => { if ((i < 64.0)) { return (() => { if ((i < 32.0)) { return (() => { if ((i < 16.0)) { return (() => { if ((i < 8.0)) { return (() => { if ((i < 4.0)) { return (() => { if ((i < 2.0)) { return (() => { if ((i < 1.0)) { return (-0.3464667673462145); } else { return (-0.34092658697056777); } })(); } else { return (() => { if ((i < 3.0)) { return (-0.3353555419211034); } else { return (-0.3297532863724655); } })(); } })(); } else { return (() => { if ((i < 6.0)) { return (() => { if ((i < 5.0)) { return (-0.32411946865420305); } else { return (-0.31845373111855224); } })(); } else { return (() => { if ((i < 7.0)) { return (-0.31275571000389846); } else { return (-0.3070250352949415); } })(); } })(); } })(); } else { return (() => { if ((i < 12.0)) { return (() => { if ((i < 10.0)) { return (() => { if ((i < 9.0)) { return (-0.3012613305781997); } else { return (-0.2954642128938758); } })(); } else { return (() => { if ((i < 11.0)) { return (-0.28963329258306203); } else { return (-0.28963329258306203); } })(); } })(); } else { return (() => { if ((i < 14.0)) { return (() => { if ((i < 13.0)) { return (-0.28376817313062475); } else { return (-0.27786845100342816); } })(); } else { return (() => { if ((i < 15.0)) { return (-0.2719337154836694); } else { return (-0.2659635484970977); } })(); } })(); } })(); } })(); } else { return (() => { if ((i < 24.0)) { return (() => { if ((i < 20.0)) { return (() => { if ((i < 18.0)) { return (() => { if ((i < 17.0)) { return (-0.25995752443691345); } else { return (-0.25391520998095984); } })(); } else { return (() => { if ((i < 19.0)) { return (-0.25391520998095984); } else { return (-0.2478361639045943); } })(); } })(); } else { return (() => { if ((i < 22.0)) { return (() => { if ((i < 21.0)) { return (-0.2417199368871934); } else { return (-0.23556607131274632); } })(); } else { return (() => { if ((i < 23.0)) { return (-0.22937410106487732); } else { return (-0.22314355131425145); } })(); } })(); } })(); } else { return (() => { if ((i < 28.0)) { return (() => { if ((i < 26.0)) { return (() => { if ((i < 25.0)) { return (-0.22314355131425145); } else { return (-0.21687393830063684); } })(); } else { return (() => { if ((i < 27.0)) { return (-0.21056476910735); } else { return (-0.2042155414286526); } })(); } })(); } else { return (() => { if ((i < 30.0)) { return (() => { if ((i < 29.0)) { return (-0.2042155414286526); } else { return (-0.19782574332987224); } })(); } else { return (() => { if ((i < 31.0)) { return (-0.19139485299967873); } else { return (-0.18492233849406148); } })(); } })(); } })(); } })(); } })(); } else { return (() => { if ((i < 48.0)) { return (() => { if ((i < 40.0)) { return (() => { if ((i < 36.0)) { return (() => { if ((i < 34.0)) { return (() => { if ((i < 33.0)) { return (-0.18492233849406148); } else { return (-0.1784076574728033); } })(); } else { return (() => { if ((i < 35.0)) { return (-0.17185025692663203); } else { return (-0.17185025692663203); } })(); } })(); } else { return (() => { if ((i < 38.0)) { return (() => { if ((i < 37.0)) { return (-0.1652495728952772); } else { return (-0.15860503017665906); } })(); } else { return (() => { if ((i < 39.0)) { return (-0.15860503017665906); } else { return (-0.15191604202584585); } })(); } })(); } })(); } else { return (() => { if ((i < 44.0)) { return (() => { if ((i < 42.0)) { return (() => { if ((i < 41.0)) { return (-0.1451820098444614); } else { return (-0.13840232285906495); } })(); } else { return (() => { if ((i < 43.0)) { return (-0.13840232285906495); } else { return (-0.131576357788731); } })(); } })(); } else { return (() => { if ((i < 46.0)) { return (() => { if ((i < 45.0)) { return (-0.131576357788731); } else { return (-0.12470347850091912); } })(); } else { return (() => { if ((i < 47.0)) { return (-0.11778303565643); } else { return (-0.11778303565643); } })(); } })(); } })(); } })(); } else { return (() => { if ((i < 56.0)) { return (() => { if ((i < 52.0)) { return (() => { if ((i < 50.0)) { return (() => { if ((i < 49.0)) { return (-0.11081436634026431); } else { return (-0.10379679368168127); } })(); } else { return (() => { if ((i < 51.0)) { return (-0.10379679368168127); } else { return (-0.09672962645856842); } })(); } })(); } else { return (() => { if ((i < 54.0)) { return (() => { if ((i < 53.0)) { return (-0.09672962645856842); } else { return (-0.089612158689647); } })(); } else { return (() => { if ((i < 55.0)) { return (-0.08244366921110213); } else { return (-0.08244366921110213); } })(); } })(); } })(); } else { return (() => { if ((i < 60.0)) { return (() => { if ((i < 58.0)) { return (() => { if ((i < 57.0)) { return (-0.07522342123763792); } else { return (-0.07522342123763792); } })(); } else { return (() => { if ((i < 59.0)) { return (-0.06795066190852594); } else { return (-0.06062462181648698); } })(); } })(); } else { return (() => { if ((i < 62.0)) { return (() => { if ((i < 61.0)) { return (-0.06062462181648698); } else { return (-0.053244514518837605); } })(); } else { return (() => { if ((i < 63.0)) { return (-0.053244514518837605); } else { return (-0.045809536031242715); } })(); } })(); } })(); } })(); } })(); } })(); } else { return (() => { if ((i < 96.0)) { return (() => { if ((i < 80.0)) { return (() => { if ((i < 72.0)) { return (() => { if ((i < 68.0)) { return (() => { if ((i < 66.0)) { return (() => { if ((i < 65.0)) { return (-0.045809536031242715); } else { return (-0.038318864302141264); } })(); } else { return (() => { if ((i < 67.0)) { return (-0.038318864302141264); } else { return (-0.03077165866670839); } })(); } })(); } else { return (() => { if ((i < 70.0)) { return (() => { if ((i < 69.0)) { return (-0.03077165866670839); } else { return (-0.023167059281490765); } })(); } else { return (() => { if ((i < 71.0)) { return (-0.015504186535963527); } else { return (-0.015504186535963527); } })(); } })(); } })(); } else { return (() => { if ((i < 76.0)) { return (() => { if ((i < 74.0)) { return (() => { if ((i < 73.0)) { return (-0.0077821404420319595); } else { return (-0.0077821404420319595); } })(); } else { return (() => { if ((i < 75.0)) { return 0.0; } else { return 0.0; } })(); } })(); } else { return (() => { if ((i < 78.0)) { return (() => { if ((i < 77.0)) { return 0.007843177461040796; } else { return 0.01574835696817445; } })(); } else { return (() => { if ((i < 79.0)) { return 0.023716526617363343; } else { return 0.03174869831457272; } })(); } })(); } })(); } })(); } else { return (() => { if ((i < 88.0)) { return (() => { if ((i < 84.0)) { return (() => { if ((i < 82.0)) { return (() => { if ((i < 81.0)) { return 0.039845908547249564; } else { return 0.048009219186383234; } })(); } else { return (() => { if ((i < 83.0)) { return 0.056239718322899535; } else { return 0.06038051098892083; } })(); } })(); } else { return (() => { if ((i < 86.0)) { return (() => { if ((i < 85.0)) { return 0.06871389254808946; } else { return 0.07711730334438016; } })(); } else { return (() => { if ((i < 87.0)) { return 0.08559193033545398; } else { return 0.08985632912185793; } })(); } })(); } })(); } else { return (() => { if ((i < 92.0)) { return (() => { if ((i < 90.0)) { return (() => { if ((i < 89.0)) { return 0.09844007281321865; } else { return 0.10709813555638448; } })(); } else { return (() => { if ((i < 91.0)) { return 0.11145544092528326; } else { return 0.12022742699821265; } })(); } })(); } else { return (() => { if ((i < 94.0)) { return (() => { if ((i < 93.0)) { return 0.12464244520731427; } else { return 0.13353139262449076; } })(); } else { return (() => { if ((i < 95.0)) { return 0.13800567301939282; } else { return 0.14701474296180095; } })(); } })(); } })(); } })(); } })(); } else { return (() => { if ((i < 112.0)) { return (() => { if ((i < 104.0)) { return (() => { if ((i < 100.0)) { return (() => { if ((i < 98.0)) { return (() => { if ((i < 97.0)) { return 0.15154989812720032; } else { return 0.16068238169043525; } })(); } else { return (() => { if ((i < 99.0)) { return 0.16528009093906348; } else { return 0.17453941635187675; } })(); } })(); } else { return (() => { if ((i < 102.0)) { return (() => { if ((i < 101.0)) { return 0.17920142945774842; } else { return 0.18388527877016259; } })(); } else { return (() => { if ((i < 103.0)) { return 0.1933193110035063; } else { return 0.19806991376208316; } })(); } })(); } })(); } else { return (() => { if ((i < 108.0)) { return (() => { if ((i < 106.0)) { return (() => { if ((i < 105.0)) { return 0.20763936477828793; } else { return 0.21245865121420593; } })(); } else { return (() => { if ((i < 107.0)) { return 0.21730127569003344; } else { return 0.22216746534115828; } })(); } })(); } else { return (() => { if ((i < 110.0)) { return (() => { if ((i < 109.0)) { return 0.2319714654378231; } else { return 0.2369097470783572; } })(); } else { return (() => { if ((i < 111.0)) { return 0.24187253642048745; } else { return 0.2468600779315011; } })(); } })(); } })(); } })(); } else { return (() => { if ((i < 120.0)) { return (() => { if ((i < 116.0)) { return (() => { if ((i < 114.0)) { return (() => { if ((i < 113.0)) { return 0.2569104137850218; } else { return 0.26197371574153294; } })(); } else { return (() => { if ((i < 115.0)) { return 0.2670627852490952; } else { return 0.27217788591576664; } })(); } })(); } else { return (() => { if ((i < 118.0)) { return (() => { if ((i < 117.0)) { return 0.27731928541618345; } else { return 0.28248725557466514; } })(); } else { return (() => { if ((i < 119.0)) { return 0.29290401643288533; } else { return 0.29815337231912054; } })(); } })(); } })(); } else { return (() => { if ((i < 124.0)) { return (() => { if ((i < 122.0)) { return (() => { if ((i < 121.0)) { return 0.3034304294199046; } else { return 0.30873548164959175; } })(); } else { return (() => { if ((i < 123.0)) { return 0.3140688276249648; } else { return 0.31943077076641657; } })(); } })(); } else { return (() => { if ((i < 126.0)) { return (() => { if ((i < 125.0)) { return 0.3248216194012912; } else { return 0.33024168687052224; } })(); } else { return (() => { if ((i < 127.0)) { return 0.3356912916381134; } else { return 0.3411707574027787; } })(); } })(); } })(); } })(); } })(); } })(); } })();
}

// `__pow_log_data.tab[i].logctail`: log c − logc.

function powLogctail(i) {
    return (() => { if ((i < 64.0)) { return (() => { if ((i < 32.0)) { return (() => { if ((i < 16.0)) { return (() => { if ((i < 8.0)) { return (() => { if ((i < 4.0)) { return (() => { if ((i < 2.0)) { return (() => { if ((i < 1.0)) { return 5.929407345889625e-15; } else { return (-2.544157440035963e-14); } })(); } else { return (() => { if ((i < 3.0)) { return (-3.443525940775045e-14); } else { return (-2.500123826022799e-15); } })(); } })(); } else { return (() => { if ((i < 6.0)) { return (() => { if ((i < 5.0)) { return (-8.929337133850617e-15); } else { return 1.7625431312172662e-14; } })(); } else { return (() => { if ((i < 7.0)) { return 1.5688303180062087e-15; } else { return 2.9655274673691784e-14; } })(); } })(); } })(); } else { return (() => { if ((i < 12.0)) { return (() => { if ((i < 10.0)) { return (() => { if ((i < 9.0)) { return 3.7923164802093147e-14; } else { return 3.993416384387844e-14; } })(); } else { return (() => { if ((i < 11.0)) { return 1.9352855826489123e-14; } else { return 1.9352855826489123e-14; } })(); } })(); } else { return (() => { if ((i < 14.0)) { return (() => { if ((i < 13.0)) { return (-1.9852665484979036e-14); } else { return (-2.814323765595281e-14); } })(); } else { return (() => { if ((i < 15.0)) { return 2.7643769993528702e-14; } else { return (-4.025092402293806e-14); } })(); } })(); } })(); } })(); } else { return (() => { if ((i < 24.0)) { return (() => { if ((i < 20.0)) { return (() => { if ((i < 18.0)) { return (() => { if ((i < 17.0)) { return (-1.2621729398885316e-14); } else { return (-3.600176732637335e-15); } })(); } else { return (() => { if ((i < 19.0)) { return (-3.600176732637335e-15); } else { return 1.3029797173308663e-14; } })(); } })(); } else { return (() => { if ((i < 22.0)) { return (() => { if ((i < 21.0)) { return 4.8230289429940886e-14; } else { return (-2.0592242769647135e-14); } })(); } else { return (() => { if ((i < 23.0)) { return 3.149265065191484e-14; } else { return 4.169796584527195e-14; } })(); } })(); } })(); } else { return (() => { if ((i < 28.0)) { return (() => { if ((i < 26.0)) { return (() => { if ((i < 25.0)) { return 4.169796584527195e-14; } else { return 2.2477465222466186e-14; } })(); } else { return (() => { if ((i < 27.0)) { return 3.6507188831790577e-16; } else { return (-3.827767260205414e-14); } })(); } })(); } else { return (() => { if ((i < 30.0)) { return (() => { if ((i < 29.0)) { return (-3.827767260205414e-14); } else { return (-4.7641388950792196e-14); } })(); } else { return (() => { if ((i < 31.0)) { return 4.9278276214647115e-14; } else { return 4.9485167661250996e-14; } })(); } })(); } })(); } })(); } })(); } else { return (() => { if ((i < 48.0)) { return (() => { if ((i < 40.0)) { return (() => { if ((i < 36.0)) { return (() => { if ((i < 34.0)) { return (() => { if ((i < 33.0)) { return 4.9485167661250996e-14; } else { return (-1.5003333854266542e-14); } })(); } else { return (() => { if ((i < 35.0)) { return (-2.7194441649495324e-14); } else { return (-2.7194441649495324e-14); } })(); } })(); } else { return (() => { if ((i < 38.0)) { return (() => { if ((i < 37.0)) { return (-2.99659267292569e-14); } else { return 2.0472357800461955e-14; } })(); } else { return (() => { if ((i < 39.0)) { return 2.0472357800461955e-14; } else { return 3.879296723063646e-15; } })(); } })(); } })(); } else { return (() => { if ((i < 44.0)) { return (() => { if ((i < 42.0)) { return (() => { if ((i < 41.0)) { return (-3.6506824353335045e-14); } else { return (-5.4183331379008994e-14); } })(); } else { return (() => { if ((i < 43.0)) { return (-5.4183331379008994e-14); } else { return 1.1729485484531301e-14; } })(); } })(); } else { return (() => { if ((i < 46.0)) { return (() => { if ((i < 45.0)) { return 1.1729485484531301e-14; } else { return (-3.811763084710266e-14); } })(); } else { return (() => { if ((i < 47.0)) { return 4.654729747598445e-14; } else { return 4.654729747598445e-14; } })(); } })(); } })(); } })(); } else { return (() => { if ((i < 56.0)) { return (() => { if ((i < 52.0)) { return (() => { if ((i < 50.0)) { return (() => { if ((i < 49.0)) { return (-2.5799991283069902e-14); } else { return 3.7700471749674615e-14; } })(); } else { return (() => { if ((i < 51.0)) { return 3.7700471749674615e-14; } else { return 1.7306161136093256e-14; } })(); } })(); } else { return (() => { if ((i < 54.0)) { return (() => { if ((i < 53.0)) { return 1.7306161136093256e-14; } else { return (-4.012913552726574e-14); } })(); } else { return (() => { if ((i < 55.0)) { return 2.7541708360737882e-14; } else { return 2.7541708360737882e-14; } })(); } })(); } })(); } else { return (() => { if ((i < 60.0)) { return (() => { if ((i < 58.0)) { return (() => { if ((i < 57.0)) { return 5.0396178134370583e-14; } else { return 5.0396178134370583e-14; } })(); } else { return (() => { if ((i < 59.0)) { return 1.8195060030168815e-14; } else { return 5.213620639136504e-14; } })(); } })(); } else { return (() => { if ((i < 62.0)) { return (() => { if ((i < 61.0)) { return 5.213620639136504e-14; } else { return 2.532168943117445e-14; } })(); } else { return (() => { if ((i < 63.0)) { return 2.532168943117445e-14; } else { return (-5.148849572685811e-14); } })(); } })(); } })(); } })(); } })(); } })(); } else { return (() => { if ((i < 96.0)) { return (() => { if ((i < 80.0)) { return (() => { if ((i < 72.0)) { return (() => { if ((i < 68.0)) { return (() => { if ((i < 66.0)) { return (() => { if ((i < 65.0)) { return (-5.148849572685811e-14); } else { return 4.6652946995830086e-15; } })(); } else { return (() => { if ((i < 67.0)) { return 4.6652946995830086e-15; } else { return (-4.529814257790929e-14); } })(); } })(); } else { return (() => { if ((i < 70.0)) { return (() => { if ((i < 69.0)) { return (-4.529814257790929e-14); } else { return (-4.361324067851568e-14); } })(); } else { return (() => { if ((i < 71.0)) { return (-1.7274567499706107e-15); } else { return (-1.7274567499706107e-15); } })(); } })(); } })(); } else { return (() => { if ((i < 76.0)) { return (() => { if ((i < 74.0)) { return (() => { if ((i < 73.0)) { return (-2.298941004620351e-14); } else { return (-2.298941004620351e-14); } })(); } else { return (() => { if ((i < 75.0)) { return 0.0; } else { return 0.0; } })(); } })(); } else { return (() => { if ((i < 78.0)) { return (() => { if ((i < 77.0)) { return (-1.4902732911301337e-14); } else { return (-3.527980389655325e-14); } })(); } else { return (() => { if ((i < 79.0)) { return (-4.730054772033249e-14); } else { return 7.580310369375161e-15; } })(); } })(); } })(); } })(); } else { return (() => { if ((i < 88.0)) { return (() => { if ((i < 84.0)) { return (() => { if ((i < 82.0)) { return (() => { if ((i < 81.0)) { return (-4.9893776716773285e-14); } else { return (-2.262629393030674e-14); } })(); } else { return (() => { if ((i < 83.0)) { return (-2.345674491018699e-14); } else { return (-1.3352588834854848e-14); } })(); } })(); } else { return (() => { if ((i < 86.0)) { return (() => { if ((i < 85.0)) { return (-3.765296820388875e-14); } else { return 5.1128335719851986e-14; } })(); } else { return (() => { if ((i < 87.0)) { return (-5.046674438470119e-14); } else { return 3.1218748807418837e-15; } })(); } })(); } })(); } else { return (() => { if ((i < 92.0)) { return (() => { if ((i < 90.0)) { return (() => { if ((i < 89.0)) { return 3.3871241029241416e-14; } else { return (-1.7376727386423858e-14); } })(); } else { return (() => { if ((i < 91.0)) { return 3.957125899799804e-14; } else { return (-5.2849453521890294e-14); } })(); } })(); } else { return (() => { if ((i < 94.0)) { return (() => { if ((i < 93.0)) { return (-3.767012502308738e-14); } else { return 3.1859736349078334e-14; } })(); } else { return (() => { if ((i < 95.0)) { return 5.0900642926060466e-14; } else { return 8.710783796122478e-15; } })(); } })(); } })(); } })(); } })(); } else { return (() => { if ((i < 112.0)) { return (() => { if ((i < 104.0)) { return (() => { if ((i < 100.0)) { return (() => { if ((i < 98.0)) { return (() => { if ((i < 97.0)) { return 6.157896229122976e-16; } else { return 3.821577743916796e-14; } })(); } else { return (() => { if ((i < 99.0)) { return 3.9440046718453496e-14; } else { return 2.2924522154618074e-14; } })(); } })(); } else { return (() => { if ((i < 102.0)) { return (() => { if ((i < 101.0)) { return (-3.742530094732263e-14); } else { return (-2.5223102140407338e-14); } })(); } else { return (() => { if ((i < 103.0)) { return (-1.0320443688698849e-14); } else { return 1.0634128304268335e-14; } })(); } })(); } })(); } else { return (() => { if ((i < 108.0)) { return (() => { if ((i < 106.0)) { return (() => { if ((i < 105.0)) { return (-4.3425422595242564e-14); } else { return (-1.2527395755711364e-14); } })(); } else { return (() => { if ((i < 107.0)) { return (-5.204008743405884e-14); } else { return (-3.979844515951702e-15); } })(); } })(); } else { return (() => { if ((i < 110.0)) { return (() => { if ((i < 109.0)) { return (-4.7955860343296286e-14); } else { return 5.015686013791602e-16; } })(); } else { return (() => { if ((i < 111.0)) { return (-7.252318953240293e-16); } else { return 2.4688324156011588e-14; } })(); } })(); } })(); } })(); } else { return (() => { if ((i < 120.0)) { return (() => { if ((i < 116.0)) { return (() => { if ((i < 114.0)) { return (() => { if ((i < 113.0)) { return 5.465121253624792e-15; } else { return 4.102651071698446e-14; } })(); } else { return (() => { if ((i < 115.0)) { return (-4.996736502345936e-14); } else { return 4.903580708156347e-14; } })(); } })(); } else { return (() => { if ((i < 118.0)) { return (() => { if ((i < 117.0)) { return 5.089628039500759e-14; } else { return 1.1782016386565151e-14; } })(); } else { return (() => { if ((i < 119.0)) { return 4.727452940514406e-14; } else { return (-4.4204083338755686e-14); } })(); } })(); } })(); } else { return (() => { if ((i < 124.0)) { return (() => { if ((i < 122.0)) { return (() => { if ((i < 121.0)) { return 1.548345993498083e-14; } else { return 2.1522127491642888e-14; } })(); } else { return (() => { if ((i < 123.0)) { return 1.1054030169005386e-14; } else { return (-5.534326352070679e-14); } })(); } })(); } else { return (() => { if ((i < 126.0)) { return (() => { if ((i < 125.0)) { return (-5.351646604259541e-14); } else { return 5.4612144489920215e-14; } })(); } else { return (() => { if ((i < 127.0)) { return 2.8136969901227338e-14; } else { return (-1.156568624616423e-14); } })(); } })(); } })(); } })(); } })(); } })(); } })();
}

// 2^(j/128) rounded to the nearest double (`__exp_data.tab[2j + 1]` with

// its exponent bits restored).

function expHead(j) {
    return (() => { if ((j < 64.0)) { return (() => { if ((j < 32.0)) { return (() => { if ((j < 16.0)) { return (() => { if ((j < 8.0)) { return (() => { if ((j < 4.0)) { return (() => { if ((j < 2.0)) { return (() => { if ((j < 1.0)) { return 1.0; } else { return 1.0054299011128027; } })(); } else { return (() => { if ((j < 3.0)) { return 1.0108892860517005; } else { return 1.016378314910953; } })(); } })(); } else { return (() => { if ((j < 6.0)) { return (() => { if ((j < 5.0)) { return 1.0218971486541166; } else { return 1.0274459491187637; } })(); } else { return (() => { if ((j < 7.0)) { return 1.0330248790212284; } else { return 1.0386341019613787; } })(); } })(); } })(); } else { return (() => { if ((j < 12.0)) { return (() => { if ((j < 10.0)) { return (() => { if ((j < 9.0)) { return 1.0442737824274138; } else { return 1.0499440858006872; } })(); } else { return (() => { if ((j < 11.0)) { return 1.0556451783605572; } else { return 1.061377227289262; } })(); } })(); } else { return (() => { if ((j < 14.0)) { return (() => { if ((j < 13.0)) { return 1.0671404006768237; } else { return 1.0729348675259756; } })(); } else { return (() => { if ((j < 15.0)) { return 1.0787607977571199; } else { return 1.0846183622133092; } })(); } })(); } })(); } })(); } else { return (() => { if ((j < 24.0)) { return (() => { if ((j < 20.0)) { return (() => { if ((j < 18.0)) { return (() => { if ((j < 17.0)) { return 1.0905077326652577; } else { return 1.0964290818163769; } })(); } else { return (() => { if ((j < 19.0)) { return 1.102382583307841; } else { return 1.1083684117236787; } })(); } })(); } else { return (() => { if ((j < 22.0)) { return (() => { if ((j < 21.0)) { return 1.1143867425958924; } else { return 1.1204377524096067; } })(); } else { return (() => { if ((j < 23.0)) { return 1.1265216186082418; } else { return 1.1326385195987192; } })(); } })(); } })(); } else { return (() => { if ((j < 28.0)) { return (() => { if ((j < 26.0)) { return (() => { if ((j < 25.0)) { return 1.1387886347566916; } else { return 1.1449721444318042; } })(); } else { return (() => { if ((j < 27.0)) { return 1.1511892299529827; } else { return 1.1574400736337511; } })(); } })(); } else { return (() => { if ((j < 30.0)) { return (() => { if ((j < 29.0)) { return 1.1637248587775775; } else { return 1.1700437696832502; } })(); } else { return (() => { if ((j < 31.0)) { return 1.1763969916502812; } else { return 1.182784710984341; } })(); } })(); } })(); } })(); } })(); } else { return (() => { if ((j < 48.0)) { return (() => { if ((j < 40.0)) { return (() => { if ((j < 36.0)) { return (() => { if ((j < 34.0)) { return (() => { if ((j < 33.0)) { return 1.189207115002721; } else { return 1.1956643920398273; } })(); } else { return (() => { if ((j < 35.0)) { return 1.202156731452703; } else { return 1.2086843236265816; } })(); } })(); } else { return (() => { if ((j < 38.0)) { return (() => { if ((j < 37.0)) { return 1.215247359980469; } else { return 1.2218460329727576; } })(); } else { return (() => { if ((j < 39.0)) { return 1.22848053610687; } else { return 1.2351510639369334; } })(); } })(); } })(); } else { return (() => { if ((j < 44.0)) { return (() => { if ((j < 42.0)) { return (() => { if ((j < 41.0)) { return 1.241857812073484; } else { return 1.2486009771892048; } })(); } else { return (() => { if ((j < 43.0)) { return 1.255380757024691; } else { return 1.2621973503942507; } })(); } })(); } else { return (() => { if ((j < 46.0)) { return (() => { if ((j < 45.0)) { return 1.2690509571917332; } else { return 1.275941778396392; } })(); } else { return (() => { if ((j < 47.0)) { return 1.2828700160787783; } else { return 1.2898358734066657; } })(); } })(); } })(); } })(); } else { return (() => { if ((j < 56.0)) { return (() => { if ((j < 52.0)) { return (() => { if ((j < 50.0)) { return (() => { if ((j < 49.0)) { return 1.2968395546510096; } else { return 1.3038812651919358; } })(); } else { return (() => { if ((j < 51.0)) { return 1.3109612115247644; } else { return 1.318079601266064; } })(); } })(); } else { return (() => { if ((j < 54.0)) { return (() => { if ((j < 53.0)) { return 1.3252366431597413; } else { return 1.3324325470831615; } })(); } else { return (() => { if ((j < 55.0)) { return 1.339667524053303; } else { return 1.3469417862329458; } })(); } })(); } })(); } else { return (() => { if ((j < 60.0)) { return (() => { if ((j < 58.0)) { return (() => { if ((j < 57.0)) { return 1.3542555469368927; } else { return 1.3616090206382248; } })(); } else { return (() => { if ((j < 59.0)) { return 1.3690024229745905; } else { return 1.3764359707545302; } })(); } })(); } else { return (() => { if ((j < 62.0)) { return (() => { if ((j < 61.0)) { return 1.383909881963832; } else { return 1.3914243757719262; } })(); } else { return (() => { if ((j < 63.0)) { return 1.3989796725383112; } else { return 1.4065759938190154; } })(); } })(); } })(); } })(); } })(); } })(); } else { return (() => { if ((j < 96.0)) { return (() => { if ((j < 80.0)) { return (() => { if ((j < 72.0)) { return (() => { if ((j < 68.0)) { return (() => { if ((j < 66.0)) { return (() => { if ((j < 65.0)) { return 1.4142135623730951; } else { return 1.4218926021691656; } })(); } else { return (() => { if ((j < 67.0)) { return 1.42961333839197; } else { return 1.4373759974489824; } })(); } })(); } else { return (() => { if ((j < 70.0)) { return (() => { if ((j < 69.0)) { return 1.4451808069770467; } else { return 1.4530279958490526; } })(); } else { return (() => { if ((j < 71.0)) { return 1.460917794180647; } else { return 1.4688504333369818; } })(); } })(); } })(); } else { return (() => { if ((j < 76.0)) { return (() => { if ((j < 74.0)) { return (() => { if ((j < 73.0)) { return 1.4768261459394993; } else { return 1.4848451658727524; } })(); } else { return (() => { if ((j < 75.0)) { return 1.4929077282912648; } else { return 1.5010140696264256; } })(); } })(); } else { return (() => { if ((j < 78.0)) { return (() => { if ((j < 77.0)) { return 1.5091644275934228; } else { return 1.5173590411982147; } })(); } else { return (() => { if ((j < 79.0)) { return 1.5255981507445384; } else { return 1.533881997840956; } })(); } })(); } })(); } })(); } else { return (() => { if ((j < 88.0)) { return (() => { if ((j < 84.0)) { return (() => { if ((j < 82.0)) { return (() => { if ((j < 81.0)) { return 1.5422108254079407; } else { return 1.550584877685; } })(); } else { return (() => { if ((j < 83.0)) { return 1.559004400237837; } else { return 1.567469639965553; } })(); } })(); } else { return (() => { if ((j < 86.0)) { return (() => { if ((j < 85.0)) { return 1.5759808451078865; } else { return 1.5845382652524937; } })(); } else { return (() => { if ((j < 87.0)) { return 1.593142151342267; } else { return 1.6017927556826934; } })(); } })(); } })(); } else { return (() => { if ((j < 92.0)) { return (() => { if ((j < 90.0)) { return (() => { if ((j < 89.0)) { return 1.6104903319492543; } else { return 1.6192351351948637; } })(); } else { return (() => { if ((j < 91.0)) { return 1.6280274218573478; } else { return 1.6368674497669644; } })(); } })(); } else { return (() => { if ((j < 94.0)) { return (() => { if ((j < 93.0)) { return 1.645755478153965; } else { return 1.6546917676561943; } })(); } else { return (() => { if ((j < 95.0)) { return 1.6636765803267364; } else { return 1.6727101796415966; } })(); } })(); } })(); } })(); } })(); } else { return (() => { if ((j < 112.0)) { return (() => { if ((j < 104.0)) { return (() => { if ((j < 100.0)) { return (() => { if ((j < 98.0)) { return (() => { if ((j < 97.0)) { return 1.681792830507429; } else { return 1.6909247992693053; } })(); } else { return (() => { if ((j < 99.0)) { return 1.7001063537185235; } else { return 1.709337763100463; } })(); } })(); } else { return (() => { if ((j < 102.0)) { return (() => { if ((j < 101.0)) { return 1.718619298122478; } else { return 1.7279512309618377; } })(); } else { return (() => { if ((j < 103.0)) { return 1.7373338352737062; } else { return 1.746767386199169; } })(); } })(); } })(); } else { return (() => { if ((j < 108.0)) { return (() => { if ((j < 106.0)) { return (() => { if ((j < 105.0)) { return 1.7562521603732995; } else { return 1.7657884359332727; } })(); } else { return (() => { if ((j < 107.0)) { return 1.7753764925265212; } else { return 1.785016611318935; } })(); } })(); } else { return (() => { if ((j < 110.0)) { return (() => { if ((j < 109.0)) { return 1.7947090750031072; } else { return 1.804454167806624; } })(); } else { return (() => { if ((j < 111.0)) { return 1.8142521755003989; } else { return 1.8241033854070534; } })(); } })(); } })(); } })(); } else { return (() => { if ((j < 120.0)) { return (() => { if ((j < 116.0)) { return (() => { if ((j < 114.0)) { return (() => { if ((j < 113.0)) { return 1.8340080864093424; } else { return 1.843966568958626; } })(); } else { return (() => { if ((j < 115.0)) { return 1.8539791250833855; } else { return 1.864046048397789; } })(); } })(); } else { return (() => { if ((j < 118.0)) { return (() => { if ((j < 117.0)) { return 1.8741676341103; } else { return 1.8843441790323345; } })(); } else { return (() => { if ((j < 119.0)) { return 1.8945759815869656; } else { return 1.9048633418176741; } })(); } })(); } })(); } else { return (() => { if ((j < 124.0)) { return (() => { if ((j < 122.0)) { return (() => { if ((j < 121.0)) { return 1.9152065613971474; } else { return 1.925605943636125; } })(); } else { return (() => { if ((j < 123.0)) { return 1.9360617934922943; } else { return 1.9465744175792332; } })(); } })(); } else { return (() => { if ((j < 126.0)) { return (() => { if ((j < 125.0)) { return 1.9571441241754002; } else { return 1.9677712232331759; } })(); } else { return (() => { if ((j < 127.0)) { return 1.978456026387951; } else { return 1.9891988469672663; } })(); } })(); } })(); } })(); } })(); } })(); } })();
}

// `__exp_data.tab[2j]`: 2^(j/128) / expHead(j) − 1.

function expTail(j) {
    return (() => { if ((j < 64.0)) { return (() => { if ((j < 32.0)) { return (() => { if ((j < 16.0)) { return (() => { if ((j < 8.0)) { return (() => { if ((j < 4.0)) { return (() => { if ((j < 2.0)) { return (() => { if ((j < 1.0)) { return 0.0; } else { return 9.447885451727066e-17; } })(); } else { return (() => { if ((j < 3.0)) { return (-1.507066976926039e-17); } else { return (-5.679155082825012e-17); } })(); } })(); } else { return (() => { if ((j < 6.0)) { return (() => { if ((j < 5.0)) { return 4.9997448722726326e-17; } else { return (-4.823683599994895e-17); } })(); } else { return (() => { if ((j < 7.0)) { return 7.357846871247418e-18; } else { return 5.773230223741951e-17; } })(); } })(); } })(); } else { return (() => { if ((j < 12.0)) { return (() => { if ((j < 10.0)) { return (() => { if ((j < 9.0)) { return 8.189317638195515e-17; } else { return 5.326891139980878e-17; } })(); } else { return (() => { if ((j < 11.0)) { return 1.6665881442326747e-18; } else { return (-1.128113245461828e-17); } })(); } })(); } else { return (() => { if ((j < 14.0)) { return (() => { if ((j < 13.0)) { return (-7.402825309426177e-17); } else { return (-3.578659767309563e-18); } })(); } else { return (() => { if ((j < 15.0)) { return (-6.170654745608695e-17); } else { return 2.919139999949279e-17; } })(); } })(); } })(); } })(); } else { return (() => { if ((j < 24.0)) { return (() => { if ((j < 20.0)) { return (() => { if ((j < 18.0)) { return (() => { if ((j < 17.0)) { return (-2.7939114859515733e-17); } else { return (-5.399285355184285e-17); } })(); } else { return (() => { if ((j < 19.0)) { return 4.776959425256223e-17; } else { return (-7.927701432338473e-17); } })(); } })(); } else { return (() => { if ((j < 22.0)) { return (() => { if ((j < 21.0)) { return 9.341710609905046e-17; } else { return (-5.534520675707472e-17); } })(); } else { return (() => { if ((j < 23.0)) { return 4.585670326662351e-17; } else { return 2.8582430411116143e-17; } })(); } })(); } })(); } else { return (() => { if ((j < 28.0)) { return (() => { if ((j < 26.0)) { return (() => { if ((j < 25.0)) { return 7.826573258636076e-17; } else { return 4.053626906769216e-17; } })(); } else { return (() => { if ((j < 27.0)) { return 2.823784425951061e-17; } else { return (-7.882802262487991e-17); } })(); } })(); } else { return (() => { if ((j < 30.0)) { return (() => { if ((j < 29.0)) { return 3.2904726646008416e-17; } else { return (-1.5792094703347882e-18); } })(); } else { return (() => { if ((j < 31.0)) { return 4.721368121170128e-17; } else { return 1.3045277096919659e-17; } })(); } })(); } })(); } })(); } })(); } else { return (() => { if ((j < 48.0)) { return (() => { if ((j < 40.0)) { return (() => { if ((j < 36.0)) { return (() => { if ((j < 34.0)) { return (() => { if ((j < 33.0)) { return 3.3484623336251524e-17; } else { return 3.8611199774925664e-17; } })(); } else { return (() => { if ((j < 35.0)) { return 5.527550048505249e-17; } else { return (-3.927184172445234e-17); } })(); } })(); } else { return (() => { if ((j < 38.0)) { return (() => { if ((j < 37.0)) { return (-6.346552106729483e-17); } else { return (-8.684417614865944e-17); } })(); } else { return (() => { if ((j < 39.0)) { return (-1.5456342819397733e-17); } else { return (-8.70763476495455e-17); } })(); } })(); } })(); } else { return (() => { if ((j < 44.0)) { return (() => { if ((j < 42.0)) { return (() => { if ((j < 41.0)) { return 3.750854201303127e-17; } else { return (-6.616854503526488e-17); } })(); } else { return (() => { if ((j < 43.0)) { return (-5.346099009198751e-18); } else { return (-2.443726321015018e-17); } })(); } })(); } else { return (() => { if ((j < 46.0)) { return (() => { if ((j < 45.0)) { return 2.1023049675215714e-18; } else { return 7.771067937501065e-17; } })(); } else { return (() => { if ((j < 47.0)) { return 1.3357510088834541e-17; } else { return 6.938291696959204e-17; } })(); } })(); } })(); } })(); } else { return (() => { if ((j < 56.0)) { return (() => { if ((j < 52.0)) { return (() => { if ((j < 50.0)) { return (() => { if ((j < 49.0)) { return 1.9572585293112036e-17; } else { return 6.632256961675804e-17; } })(); } else { return (() => { if ((j < 51.0)) { return (-5.478069123926778e-17); } else { return (-4.140839310392624e-17); } })(); } })(); } else { return (() => { if ((j < 54.0)) { return (() => { if ((j < 53.0)) { return (-2.1571477251208752e-17); } else { return (-3.8287766552120535e-17); } })(); } else { return (() => { if ((j < 55.0)) { return 6.663804589232195e-17; } else { return 2.3936187400285282e-17; } })(); } })(); } })(); } else { return (() => { if ((j < 60.0)) { return (() => { if ((j < 58.0)) { return (() => { if ((j < 57.0)) { return 5.68648095791174e-17; } else { return 1.1264523354521684e-18; } })(); } else { return (() => { if ((j < 59.0)) { return 7.007875046906994e-17; } else { return (-5.0119214278381254e-17); } })(); } })(); } else { return (() => { if ((j < 62.0)) { return (() => { if ((j < 61.0)) { return (-4.8923067513522756e-17); } else { return (-3.5260089953269434e-17); } })(); } else { return (() => { if ((j < 63.0)) { return (-6.872303720902018e-17); } else { return 5.001446664133532e-18; } })(); } })(); } })(); } })(); } })(); } })(); } else { return (() => { if ((j < 96.0)) { return (() => { if ((j < 80.0)) { return (() => { if ((j < 72.0)) { return (() => { if ((j < 68.0)) { return (() => { if ((j < 66.0)) { return (() => { if ((j < 65.0)) { return (-6.835808657661922e-17); } else { return (-1.1307344092910212e-17); } })(); } else { return (() => { if ((j < 67.0)) { return (-8.416011634717156e-18); } else { return (-2.9247977035436566e-17); } })(); } })(); } else { return (() => { if ((j < 70.0)) { return (() => { if ((j < 69.0)) { return (-2.092304381843353e-17); } else { return (-3.9778645875427124e-17); } })(); } else { return (() => { if ((j < 71.0)) { return (-3.833464968654295e-17); } else { return 5.763611164480894e-17; } })(); } })(); } })(); } else { return (() => { if ((j < 76.0)) { return (() => { if ((j < 74.0)) { return (() => { if ((j < 73.0)) { return (-2.3591094770850053e-17); } else { return 7.260074661098575e-17; } })(); } else { return (() => { if ((j < 75.0)) { return 9.50689710108796e-18; } else { return (-4.272956133839906e-17); } })(); } })(); } else { return (() => { if ((j < 78.0)) { return (() => { if ((j < 77.0)) { return (-6.735219232374683e-17); } else { return (-2.8396044410430936e-17); } })(); } else { return (() => { if ((j < 79.0)) { return (-7.226635472101257e-17); } else { return 5.786121003395918e-17; } })(); } })(); } })(); } })(); } else { return (() => { if ((j < 88.0)) { return (() => { if ((j < 84.0)) { return (() => { if ((j < 82.0)) { return (() => { if ((j < 81.0)) { return 5.1548301170786783e-17; } else { return (-9.416257568878152e-18); } })(); } else { return (() => { if ((j < 83.0)) { return 2.4253985766689806e-17; } else { return (-6.604314051707707e-17); } })(); } })(); } else { return (() => { if ((j < 86.0)) { return (() => { if ((j < 85.0)) { return (-6.432131775424189e-18); } else { return (-1.2204007601863921e-17); } })(); } else { return (() => { if ((j < 87.0)) { return (-6.336161863401293e-17); } else { return (-3.7800879246373815e-17); } })(); } })(); } })(); } else { return (() => { if ((j < 92.0)) { return (() => { if ((j < 90.0)) { return (() => { if ((j < 89.0)) { return 1.5341410053603723e-17; } else { return 1.2932855580427452e-17; } })(); } else { return (() => { if ((j < 91.0)) { return (-4.123367330661149e-17); } else { return 4.703083974463456e-17; } })(); } })(); } else { return (() => { if ((j < 94.0)) { return (() => { if ((j < 93.0)) { return (-6.152602891550265e-17); } else { return 5.827849326195279e-17; } })(); } else { return (() => { if ((j < 95.0)) { return 3.540948262646183e-17; } else { return (-3.2741571320938764e-17); } })(); } })(); } })(); } })(); } })(); } else { return (() => { if ((j < 112.0)) { return (() => { if ((j < 104.0)) { return (() => { if ((j < 100.0)) { return (() => { if ((j < 98.0)) { return (() => { if ((j < 97.0)) { return 4.875160526227062e-17; } else { return (-5.718569790077838e-17); } })(); } else { return (() => { if ((j < 99.0)) { return (-4.719539664590972e-18); } else { return (-5.773451958805706e-17); } })(); } })(); } else { return (() => { if ((j < 102.0)) { return (() => { if ((j < 101.0)) { return (-1.0772487078934056e-17); } else { return (-6.221808618533911e-17); } })(); } else { return (() => { if ((j < 103.0)) { return 1.821405440362259e-17; } else { return (-6.155536546227639e-17); } })(); } })(); } })(); } else { return (() => { if ((j < 108.0)) { return (() => { if ((j < 106.0)) { return (() => { if ((j < 105.0)) { return 1.685487290628973e-17; } else { return 5.3581249177694816e-17; } })(); } else { return (() => { if ((j < 107.0)) { return 3.621615935336894e-17; } else { return 8.588379527574144e-18; } })(); } })(); } else { return (() => { if ((j < 110.0)) { return (() => { if ((j < 109.0)) { return 1.01562190116415e-17; } else { return (-2.869134889187244e-17); } })(); } else { return (() => { if ((j < 111.0)) { return (-5.495118966122005e-17); } else { return (-5.56965572431627e-17); } })(); } })(); } })(); } })(); } else { return (() => { if ((j < 120.0)) { return (() => { if ((j < 116.0)) { return (() => { if ((j < 114.0)) { return (() => { if ((j < 113.0)) { return 1.790126907604513e-17; } else { return (-3.2211766346200164e-17); } })(); } else { return (() => { if ((j < 115.0)) { return 5.265370768556274e-17; } else { return 3.5089866402403033e-17; } })(); } })(); } else { return (() => { if ((j < 118.0)) { return (() => { if ((j < 117.0)) { return (-3.266924100901318e-17); } else { return (-4.3657593008079375e-17); } })(); } else { return (() => { if ((j < 119.0)) { return 1.7963932659833022e-17; } else { return 3.4300925275214166e-17; } })(); } })(); } })(); } else { return (() => { if ((j < 124.0)) { return (() => { if ((j < 122.0)) { return (() => { if ((j < 121.0)) { return (-5.545065618639427e-17); } else { return (-5.149009745457733e-17); } })(); } else { return (() => { if ((j < 123.0)) { return 5.336805878514151e-17; } else { return 3.498978661192973e-17; } })(); } })(); } else { return (() => { if ((j < 126.0)) { return (() => { if ((j < 125.0)) { return 4.5784915277060095e-17; } else { return (-5.241934575393899e-17); } })(); } else { return (() => { if ((j < 127.0)) { return 2.0414278897578303e-17; } else { return 4.124842848606488e-18; } })(); } })(); } })(); } })(); } })(); } })(); } })();
}

// ── trigonometry ─────────────────────────────────────────────────────────────

// fdlibm's `__ieee754_rem_pio2` for |x| up to 2^19·π/2: `which` 0 answers the

// quadrant n, 1 and 2 the remainder's head and tail. A larger |x| needs

// `__kernel_rem_pio2`, which is not ported — refused by a panic.

function remPio2(x, which) {
    const neg = signBit(x);
    const ix = highWord(x);
    let n = 0.0;
    let y0 = x;
    let y1 = 0.0;
    (() => { if ((ix <= 1072243195.0)) { return n = 0.0; } else { return (() => { if ((ix < 1073928572.0)) { const sgn = (() => { if (neg) { return (-1.0); } else { return 1.0; } })(); let z = (x - (sgn * 1.57079632673412561417e+00)); (() => { if ((!Object.is(ix, 1073291771.0))) { y0 = (z - (sgn * 6.07710050650619224932e-11)); return y1 = (((z - y0)) - (sgn * 6.07710050650619224932e-11)); } else { z = (z - (sgn * 6.07710050630396597660e-11)); y0 = (z - (sgn * 2.02226624879595063154e-21)); return y1 = (((z - y0)) - (sgn * 2.02226624879595063154e-21)); } })(); return n = sgn; } else { return (() => { if ((ix <= 1094263291.0)) { const t = Math.abs(x); n = Math.trunc(((t * 6.36619772367581382433e-01) + 0.5)); let r = (t - (n * 1.57079632673412561417e+00)); let w = (n * 6.07710050650619224932e-11); (() => { if (((n < 32.0) && (!Object.is(ix, highWord((n * 1.5707963267948966)))))) { return y0 = (r - w); } else { const j = Math.floor((ix / 1048576.0)); y0 = (r - w); return (() => { if (((j - exponentField(y0)) > 16.0)) { let tt = r; w = (n * 6.07710050630396597660e-11); r = (tt - w); w = ((n * 2.02226624879595063154e-21) - ((((tt - r)) - w))); y0 = (r - w); return (() => { if (((j - exponentField(y0)) > 49.0)) { tt = r; w = (n * 2.02226624871116645580e-21); r = (tt - w); w = ((n * 8.47842766036889956997e-32) - ((((tt - r)) - w))); return y0 = (r - w); } })(); } })(); } })(); y1 = (((r - y0)) - w); return (() => { if (neg) { y0 = ((-1.0) * y0); y1 = ((-1.0) * y1); return n = ((-1.0) * n); } })(); } else { return (() => { if ((ix >= 2146435072.0)) { y0 = (x - x); return y1 = y0; } else { return (() => { throw Object.defineProperty(new Error("math: a trigonometric argument beyond 2^19 · π/2 is not reduced on wasm"), '__bp_panic', { value: true }) })(); } })(); } })(); } })(); } })();
    return (() => { if ((which < 0.5)) { return n; } else { return (() => { if ((which < 1.5)) { return y0; } else { return y1; } })(); } })();
}

function kernelCos(x, y) {
    const ix = highWord(x);
    if ((ix < 1044381696.0)) { return 1.0; }
    const z = (x * x);
    const r = (z * ((4.16666666666666019037e-02 + (z * (((-1.38888888888741095749e-03) + (z * ((2.48015872894767294178e-05 + (z * (((-2.75573143513906633035e-07) + (z * ((2.08757232129817482790e-09 + (z * (-1.13596475577881948265e-11)))))))))))))))));
    if ((ix < 1070805811.0)) { return (1.0 - (((0.5 * z) - (((z * r) - (x * y)))))); }
    const qx = (() => { if ((ix > 1072234496.0)) { return 0.28125; } else { return fromWords((ix - 2097152.0), 0.0); } })();
    const iz = ((0.5 * z) - qx);
    const a = (1.0 - qx);
    return (a - ((iz - (((z * r) - (x * y))))));
}

function kernelSin(x, y, iy) {
    if ((highWord(x) < 1044381696.0)) { return x; }
    const z = (x * x);
    const v = (z * x);
    const r = (8.33333333332248946124e-03 + (z * (((-1.98412698298579493134e-04) + (z * ((2.75573137070700676789e-06 + (z * (((-2.50507602534068634195e-08) + (z * 1.58969099521155010221e-10)))))))))));
    if (isZero(iy)) { return (x + (v * (((-1.66666666666666324348e-01) + (z * r))))); }
    return (x - (((((z * (((0.5 * y) - (v * r)))) - y)) - (v * (-1.66666666666666324348e-01)))));
}

// fdlibm's `__kernel_tan`: tan(x + y) for `iy` 1, -1/tan(x + y) for -1.

function kernelTan(x0, y0, iy) {
    const neg = signBit(x0);
    const ix = highWord(x0);
    if ((ix < 1043333120.0)) { if (((isZero(ix) && isZero(lowWord(x0))) && Object.is(iy, (-1.0)))) { return (1.0 / Math.abs(x0)); } if (Object.is(iy, 1.0)) { return x0; } const w0 = (x0 + y0); const z0 = withLowZero(w0); const v0 = (y0 - ((z0 - x0))); const a0 = ((-1.0) / w0); const t0 = withLowZero(a0); const s0 = (1.0 + (t0 * z0)); return (t0 + (a0 * ((s0 + (t0 * v0))))); }
    let x = x0;
    let y = y0;
    const big = (ix >= 1072010280.0);
    (() => { if (big) { (() => { if (neg) { x = ((-1.0) * x); return y = ((-1.0) * y); } })(); const zb = (7.85398163397448278999e-01 - x); const wb = (3.06161699786838301793e-17 - y); x = (zb + wb); return y = 0.0; } })();
    const z = (x * x);
    const w = (z * z);
    let r = (1.33333333333201242699e-01 + (w * ((2.18694882948595424599e-02 + (w * ((3.59207910759131235356e-03 + (w * ((5.88041240820264096874e-04 + (w * ((7.81794442939557092300e-05 + (w * (-1.85586374855275456654e-05)))))))))))))));
    const v = (z * ((5.39682539762260521377e-02 + (w * ((8.86323982359930005737e-03 + (w * ((1.45620945432529025516e-03 + (w * ((2.46463134818469906812e-04 + (w * ((7.14072491382608190305e-05 + (w * 2.59073051863633712884e-05))))))))))))))));
    const s = (z * x);
    r = (y + (z * (((s * ((r + v))) + y))));
    r = (r + (3.33333333333334091986e-01 * s));
    const ww = (x + r);
    if (big) { const sign = (() => { if (neg) { return (-1.0); } else { return 1.0; } })(); return (sign * ((iy - (2.0 * ((x - ((((ww * ww) / ((ww + iy))) - r)))))))); }
    if (Object.is(iy, 1.0)) { return ww; }
    const z2 = withLowZero(ww);
    const v2 = (r - ((z2 - x)));
    const a = ((-1.0) / ww);
    const t = withLowZero(a);
    const s2 = (1.0 + (t * z2));
    return (t + (a * ((s2 + (t * v2)))));
}

// n mod 4 in 0..3 (fdlibm's `n & 3`).

function quadrantOf(n) {
    return (n - (4.0 * Math.floor((n * 0.25))));
}

function sinBody(x) {
    const ix = highWord(x);
    if ((ix <= 1072243195.0)) { return kernelSin(x, 0.0, 0.0); }
    if ((ix >= 2146435072.0)) { return (x - x); }
    const q = quadrantOf(remPio2(x, 0.0));
    const y0 = remPio2(x, 1.0);
    const y1 = remPio2(x, 2.0);
    return (() => { if ((q < 0.5)) { return kernelSin(y0, y1, 1.0); } else { return (() => { if ((q < 1.5)) { return kernelCos(y0, y1); } else { return (() => { if ((q < 2.5)) { return ((-1.0) * kernelSin(y0, y1, 1.0)); } else { return ((-1.0) * kernelCos(y0, y1)); } })(); } })(); } })();
}

function cosBody(x) {
    const ix = highWord(x);
    if ((ix <= 1072243195.0)) { return kernelCos(x, 0.0); }
    if ((ix >= 2146435072.0)) { return (x - x); }
    const q = quadrantOf(remPio2(x, 0.0));
    const y0 = remPio2(x, 1.0);
    const y1 = remPio2(x, 2.0);
    return (() => { if ((q < 0.5)) { return kernelCos(y0, y1); } else { return (() => { if ((q < 1.5)) { return ((-1.0) * kernelSin(y0, y1, 1.0)); } else { return (() => { if ((q < 2.5)) { return ((-1.0) * kernelCos(y0, y1)); } else { return kernelSin(y0, y1, 1.0); } })(); } })(); } })();
}

function tanBody(x) {
    const ix = highWord(x);
    if ((ix <= 1072243195.0)) { return kernelTan(x, 0.0, 1.0); }
    if ((ix >= 2146435072.0)) { return (x - x); }
    const odd = (quadrantOf(remPio2(x, 0.0)) - (2.0 * Math.floor((quadrantOf(remPio2(x, 0.0)) * 0.5))));
    return kernelTan(remPio2(x, 1.0), remPio2(x, 2.0), (1.0 - (2.0 * odd)));
}

function asinPoly(t) {
    const p = (t * ((1.66666666666666657415e-01 + (t * (((-3.25565818622400915405e-01) + (t * ((2.01212532134862925881e-01 + (t * (((-4.00555345006794114027e-02) + (t * ((7.91534994289814532176e-04 + (t * 3.47933107596021167570e-05))))))))))))))));
    const q = (1.0 + (t * (((-2.40339491173441421878e+00) + (t * ((2.02094576023350569471e+00 + (t * (((-6.88283971605453293030e-01) + (t * 7.70381505559019352791e-02)))))))))));
    return (p / q);
}

function asinBody(x) {
    const ix = highWord(x);
    if ((ix >= 1072693248.0)) { if ((Object.is(ix, 1072693248.0) && isZero(lowWord(x)))) { return ((x * 1.57079632679489655800e+00) + (x * 6.12323399573676603587e-17)); } return (((x - x)) / ((x - x))); }
    if ((ix < 1071644672.0)) { if ((ix < 1044381696.0)) { return x; } return (x + (x * asinPoly((x * x)))); }
    const w = (1.0 - Math.abs(x));
    const t = (w * 0.5);
    const s = Math.sqrt(t);
    let res = 0.0;
    (() => { if ((ix >= 1072640819.0)) { return res = (1.57079632679489655800e+00 - (((2.0 * ((s + (s * asinPoly(t))))) - 6.12323399573676603587e-17))); } else { const ws = withLowZero(s); const c = (((t - (ws * ws))) / ((s + ws))); const p = (((2.0 * s) * asinPoly(t)) - ((6.12323399573676603587e-17 - (2.0 * c)))); const q = (7.85398163397448278999e-01 - (2.0 * ws)); return res = (7.85398163397448278999e-01 - ((p - q))); } })();
    return (() => { if ((x > 0.0)) { return res; } else { return ((-1.0) * res); } })();
}

function acosBody(x) {
    const ix = highWord(x);
    const pio2Hi = 1.57079632679489655800e+00;
    const pio2Lo = 6.12323399573676603587e-17;
    if ((ix >= 1072693248.0)) { if ((Object.is(ix, 1072693248.0) && isZero(lowWord(x)))) { return (() => { if ((x > 0.0)) { return 0.0; } else { return (3.14159265358979311600e+00 + (2.0 * pio2Lo)); } })(); } return (((x - x)) / ((x - x))); }
    if ((ix < 1071644672.0)) { if ((ix <= 1012924416.0)) { return (pio2Hi + pio2Lo); } return (pio2Hi - ((x - ((pio2Lo - (x * asinPoly((x * x)))))))); }
    if ((x < 0.0)) { const z = (((1.0 + x)) * 0.5); const s = Math.sqrt(z); const w = ((asinPoly(z) * s) - pio2Lo); return (3.14159265358979311600e+00 - (2.0 * ((s + w)))); }
    const z = (((1.0 - x)) * 0.5);
    const s = Math.sqrt(z);
    const df = withLowZero(s);
    const c = (((z - (df * df))) / ((s + df)));
    const w = ((asinPoly(z) * s) + c);
    return (2.0 * ((df + w)));
}

function atanBody(x) {
    const ix = highWord(x);
    const neg = signBit(x);
    if ((ix >= 1141899264.0)) { if ((!Object.is(x, x))) { return (x + x); } return (() => { if (neg) { return ((-1.57079632679489655800e+00) - 6.12323399573676603587e-17); } else { return (1.57079632679489655800e+00 + 6.12323399573676603587e-17); } })(); }
    let id = (-1.0);
    let t = x;
    if ((ix < 1071382528.0)) { if ((ix < 1044381696.0)) { return x; } } else { const ax = Math.abs(x); (() => { if ((ix < 1072889856.0)) { return (() => { if ((ix < 1072037888.0)) { id = 0.0; return t = ((((2.0 * ax) - 1.0)) / ((2.0 + ax))); } else { id = 1.0; return t = (((ax - 1.0)) / ((ax + 1.0))); } })(); } else { return (() => { if ((ix < 1073971200.0)) { id = 2.0; return t = (((ax - 1.5)) / ((1.0 + (1.5 * ax)))); } else { id = 3.0; return t = ((-1.0) / ax); } })(); } })(); }
    const z = (t * t);
    const w = (z * z);
    const s1 = (z * ((3.33333333333329318027e-01 + (w * ((1.42857142725034663711e-01 + (w * ((9.09088713343650656196e-02 + (w * ((6.66107313738753120669e-02 + (w * ((4.97687799461593236017e-02 + (w * 1.62858201153657823623e-02))))))))))))))));
    const s2 = (w * (((-1.99999999998764832476e-01) + (w * (((-1.11111104054623557880e-01) + (w * (((-7.69187620504482999495e-02) + (w * (((-5.83357013379057348645e-02) + (w * (-3.65315727442169155270e-02))))))))))))));
    if ((id < 0.0)) { return (t - (t * ((s1 + s2)))); }
    const hi = (() => { if ((id < 0.5)) { return 4.63647609000806093515e-01; } else { return (() => { if ((id < 1.5)) { return 7.85398163397448278999e-01; } else { return (() => { if ((id < 2.5)) { return 9.82793723247329054082e-01; } else { return 1.57079632679489655800e+00; } })(); } })(); } })();
    const lo = (() => { if ((id < 0.5)) { return 2.26987774529616870924e-17; } else { return (() => { if ((id < 1.5)) { return 3.06161699786838301793e-17; } else { return (() => { if ((id < 2.5)) { return 1.39033110312309984516e-17; } else { return 6.12323399573676603587e-17; } })(); } })(); } })();
    const zz = (hi - (((((t * ((s1 + s2))) - lo)) - t)));
    return (() => { if (neg) { return ((-1.0) * zz); } else { return zz; } })();
}

function atan2Body(y, x) {
    if (((!Object.is(x, x)) || (!Object.is(y, y)))) { return (x + y); }
    if (Object.is(x, 1.0)) { return atanBody(y); }
    const piV = 3.1415926535897931160E+00;
    const piLo = 1.2246467991473531772E-16;
    const halfPi = 1.5707963267948965580E+00;
    const quarterPi = 7.8539816339744827900E-01;
    const ny = signBit(y);
    const nx = signBit(x);
    const my = (() => { if (ny) { return 1.0; } else { return 0.0; } })();
    const mx = (() => { if (nx) { return 2.0; } else { return 0.0; } })();
    const m = (my + mx);
    if (isZero(y)) { return (() => { if ((m < 1.5)) { return y; } else { return (() => { if ((m < 2.5)) { return piV; } else { return ((-1.0) * piV); } })(); } })(); }
    if (isZero(x)) { return (() => { if (ny) { return ((-1.0) * halfPi); } else { return halfPi; } })(); }
    const ix = highWord(x);
    const iy = highWord(y);
    if (Object.is(ix, 2146435072.0)) { if (Object.is(iy, 2146435072.0)) { return (() => { if ((m < 0.5)) { return quarterPi; } else { return (() => { if ((m < 1.5)) { return ((-1.0) * quarterPi); } else { return (() => { if ((m < 2.5)) { return (3.0 * quarterPi); } else { return ((-3.0) * quarterPi); } })(); } })(); } })(); } return (() => { if ((m < 0.5)) { return 0.0; } else { return (() => { if ((m < 1.5)) { return ((-1.0) * 0.0); } else { return (() => { if ((m < 2.5)) { return piV; } else { return ((-1.0) * piV); } })(); } })(); } })(); }
    if (Object.is(iy, 2146435072.0)) { return (() => { if (ny) { return ((-1.0) * halfPi); } else { return halfPi; } })(); }
    const k = Math.floor((((iy - ix)) / 1048576.0));
    let mm = m;
    let z = 0.0;
    (() => { if ((k > 60.0)) { z = (halfPi + (0.5 * piLo)); return mm = (m - (2.0 * Math.floor((m * 0.5)))); } else { return (() => { if ((nx && (k < (-60.0)))) { return z = 0.0; } else { return z = atanBody(Math.abs((y / x))); } })(); } })();
    return (() => { if ((mm < 0.5)) { return z; } else { return (() => { if ((mm < 1.5)) { return ((-1.0) * z); } else { return (() => { if ((mm < 2.5)) { return (piV - ((z - piLo))); } else { return (((z - piLo)) - piV); } })(); } })(); } })();
}

// ── hyperbolic functions ─────────────────────────────────────────────────────

function sinhBody(x) {
    const h = (() => { if ((x < 0.0)) { return (-0.5); } else { return 0.5; } })();
    const ax = Math.abs(x);
    if ((ax < 22.0)) { if ((ax < 3.725290298461914e-9)) { return x; } const t = expm1Body(ax); if ((ax < 1.0)) { return (h * (((2.0 * t) - ((t * t) / ((t + 1.0)))))); } return (h * ((t + (t / ((t + 1.0)))))); }
    if ((ax < 709.7822265625)) { return (h * expBody(ax)); }
    if ((ax <= 710.4758600739439)) { const w = expBody((0.5 * ax)); const t = (h * w); return (t * w); }
    return (x * 1.0e307);
}

function coshBody(x) {
    const ix = highWord(x);
    if ((ix < 1071001155.0)) { const t = expm1Body(Math.abs(x)); const w = (1.0 + t); if ((ix < 1015021568.0)) { return w; } return (1.0 + (((t * t)) / ((w + w)))); }
    if ((ix < 1077280768.0)) { const t = expBody(Math.abs(x)); return ((0.5 * t) + (0.5 / t)); }
    if ((ix < 1082535490.0)) { return (0.5 * expBody(Math.abs(x))); }
    if ((Math.abs(x) <= 710.4758600739439)) { const w = expBody((0.5 * Math.abs(x))); const t = (0.5 * w); return (t * w); }
    if ((ix >= 2146435072.0)) { return (x * x); }
    return timesHuge(1.0, 1.0e300);
}

function tanhBody(x) {
    const ix = highWord(x);
    const neg = signBit(x);
    if ((ix >= 2146435072.0)) { return (() => { if ((!neg)) { return ((1.0 / x) + 1.0); } else { return ((1.0 / x) - 1.0); } })(); }
    let z = 0.0;
    if ((ix < 1077280768.0)) { if ((ix < 1043333120.0)) { return x; } (() => { if ((ix >= 1072693248.0)) { const t = expm1Body((2.0 * Math.abs(x))); return z = (1.0 - (2.0 / ((t + 2.0)))); } else { const t = expm1Body(((-2.0) * Math.abs(x))); return z = ((((-1.0) * t)) / ((t + 2.0))); } })(); } else { z = (1.0 - 1.0e-300); }
    return (() => { if ((!neg)) { return z; } else { return ((-1.0) * z); } })();
}

// ── tests ────────────────────────────────────────────────────────────────────

Object.defineProperty(exports, "__bp_priv__", { value: { pi, e, tau, sqrt2, ln2, ln10, log2e, log10e, abs, floor, round, trunc, ceil, sign, minF, maxF, clamp, sqrt, pow, cbrt, exp, ln, log2, log10, hypot, sin, cos, tan, asin, acos, atan, atan2, sinh, cosh, tanh, roundHalfUp, timesHuge, twoTo, exponentOf, subnormalBits, highWord, lowWord, fromWords, withLowZero, signBit, isZero, exponentField, expBody, expm1Body, logSpecial, logScaled, logMantissaBits, lnBody, logOnePlusTail, log2Body, log10Body, sumError, productError, unitInFirstPlace, sumRoundedToOdd, fusedMultiplyAdd, wholeKind, powBody, powExp, powInvc, powLogc, powLogctail, expHead, expTail, remPio2, kernelCos, kernelSin, kernelTan, quadrantOf, sinBody, cosBody, tanBody, asinPoly, asinBody, acosBody, atanBody, atan2Body, sinhBody, coshBody, tanhBody } });
