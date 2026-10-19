----- SOURCE CODE -- std/functions.bp
```botopink
//// std/functions — combinators over function values (decision 738).
////
//// Plain functions of a std module, imported by path:
//// `import {functions.compose} from "std";`. A function's type is
//// `fn(A) -> B`; no `Function` contract names it. Pure botopink, no host
//// backing, so the module runs on every target.
////
//// No import (decision 106: a root module).

/// The argument, unchanged.
pub fn identity<A>(x: A) -> A {
    return x;
}

/// `f`, then `g`: `compose(f, g)(a)` is `g(f(a))`.
pub fn compose<A, B, C>(f: fn(a: A) -> B, g: fn(b: B) -> C) -> fn(A) -> C {
    return { a -> g(f(a)) };
}

/// `f` with its two arguments swapped: `flip(f)(b, a)` is `f(a, b)`.
pub fn flip<A, B, C>(f: fn(a: A, b: B) -> C) -> fn(B, A) -> C {
    return { b, a -> f(a, b) };
}

/// A function answering `x` whatever it is given. The argument is typed
/// `unknown` (decision 668: no parameter would bind a type for it), so one
/// binding takes any argument.
pub fn constant<A>(x: A) -> fn(unknown) -> A {
    return { ignored -> x };
}

test "functions.identity" {
    assert identity(42) == 42;
    assert identity("hi") == "hi";
    assert identity(true);
}

test "functions.compose runs left to right" {
    val double: fn(i32) -> i32 = { n -> n * 2 };
    val addOne: fn(i32) -> i32 = { n -> n + 1 };
    val f = compose(double, addOne);
    assert f(3) == 7;
    assert f(0) == 1;
}

test "functions.compose with a string transform" {
    val shout: fn(string) -> string = { s -> s + "!" };
    val greet: fn(string) -> string = { s -> "Hello, " + s };
    val greetAndShout = compose(greet, shout);
    assert greetAndShout("world") == "Hello, world!";
}

test "functions.flip reverses the argument order" {
    val sub: fn(i32, i32) -> i32 = { a, b -> a - b };
    val rsub = flip(sub);
    assert rsub(3, 10) == 7;
}

test "functions.constant ignores its argument" {
    val always42 = constant(42);
    assert always42("anything") == 42;
    assert always42(0) == 42;
}

```

----- JAVASCRIPT -- std/functions.js
```javascript
//// std/functions — combinators over function values (decision 738).

//// 

//// Plain functions of a std module, imported by path:

//// `import {functions.compose} from "std";`. A function's type is

//// `fn(A) -> B`; no `Function` contract names it. Pure botopink, no host

//// backing, so the module runs on every target.

//// 

//// No import (decision 106: a root module).

/** The argument, unchanged. */

function identity(x) {
    return x;
}
exports.identity = identity;

/** `f`, then `g`: `compose(f, g)(a)` is `g(f(a))`. */

function compose(f, g) {
    return (a) => {
    return g(f(a));
};
}
exports.compose = compose;

/** `f` with its two arguments swapped: `flip(f)(b, a)` is `f(a, b)`. */

function flip(f) {
    return (b, a) => {
    return f(a, b);
};
}
exports.flip = flip;

/** A function answering `x` whatever it is given. The argument is typed */

/** `unknown` (decision 668: no parameter would bind a type for it), so one */

/** binding takes any argument. */

function constant(x) {
    return (ignored) => {
    return x;
};
}
exports.constant = constant;

Object.defineProperty(exports, "__bp_priv__", { value: { identity, compose, flip, constant } });
```

----- TYPESCRIPT TYPEDEF -- std/functions.d.ts
```typescript
export declare function identity<A>(x: A): A;


export declare function compose<A, B, C>(f: (a: A) => B, g: (b: B) => C): (p0: A) => C;


export declare function flip<A, B, C>(f: (a: A, b: B) => C): (p0: B, p1: A) => C;


export declare function constant<A>(x: A): (p0: unknown) => A;

```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
fn parse(s: string) -> Result<Array<#(string, string)>, string> {
    if (s == "") throw "empty";
    return [#(s, s.toUpper())];
}

fn pairsOf(r: Result<Array<#(string, string)>, string>) -> string {
    val none: Array<#(string, string)> = [];
    return r.unwrapOr(none).map({ p -> [p._0, "=>", p._1].join("") }).join("|");
}

pub fn main() -> void {
    print(pairsOf(parse("a")));
    print(pairsOf(parse("")).length);
    val double: fn(i32) -> i32 = { n -> n * 2 };
    val addOne: fn(i32) -> i32 = { n -> n + 1 };
    print(functions.compose(double, addOne)(3));
    val shout: fn(string) -> string = { s -> s + "!" };
    print(functions.compose(shout, shout)("hi"));
    val sub: fn(i32, i32) -> i32 = { a, b -> a - b };
    print(functions.flip(sub)(3, 10));
    print(functions.constant(42)("x"));
}

import {io.terminal.print} from "std";
import {functions} from "std";
```

----- JAVASCRIPT -- main.js
```javascript
const __bp_surrogate = /[\uD800-\uDFFF]/;
const __bp_surrogate_k = new Array(64).fill("");
const __bp_surrogate_v = new Array(64).fill(false);
const __bp_surrogate_k2 = new Array(64).fill("");
const __bp_surrogate_v2 = new Array(64).fill(false);
function __bp_has_surrogate(s) {
    const h = s.length & 63;
    if (__bp_surrogate_k[h] === s) { return __bp_surrogate_v[h]; }
    if (__bp_surrogate_k2[h] === s) { return __bp_surrogate_v2[h]; }
    const p = __bp_surrogate.test(s);
    __bp_surrogate_k2[h] = __bp_surrogate_k[h];
    __bp_surrogate_v2[h] = __bp_surrogate_v[h];
    __bp_surrogate_k[h] = s;
    __bp_surrogate_v[h] = p;
    return p;
}

function __bp_str_length(s) {
    if (!__bp_has_surrogate(s)) { return s.length; }
    let n = 0;
    for (const c of s) { n += 1; }
    return n;
}

function __bp_f64(v) {
    if (Number.isNaN(v)) { return "NaN"; }
    if (!Number.isFinite(v)) { return (v < 0) ? "-Infinity" : "Infinity"; }
    if (v === 0) { return Object.is(v, -0) ? "-0.0" : "0.0"; }
    const t = Math.abs(v).toExponential();
    const i = t.indexOf("e");
    const d = t.slice(0, i).replace(".", "");
    const e = Number(t.slice(i + 1));
    const g = (v < 0) ? "-" : "";
    const x = g + d[0] + "." + ((d.length > 1) ? d.slice(1) : "0") + "e" + e;
    const p = e + 1;
    const f = g + ((p <= 0) ? "0." + "0".repeat(-p) + d : (p >= d.length) ? d + "0".repeat(p - d.length) + ".0" : d.slice(0, p) + "." + d.slice(p));
    return ((f.length <= x.length) && (Math.abs(v) < 9007199254740992)) ? f : x;
}

function __bp_case_map(t) {
    const m = new Map();
    for (const e of t.split(" ")) {
        const p = e.replace("!", "").split(",").map((x) => parseInt(x, 36));
        if (e[0] === "!") { m.set(p[0], String.fromCodePoint(...p.slice(1))); continue; }
        for (let i = 0; i < p[1]; i += 1) m.set(p[0] + i * p[2], String.fromCodePoint(p[0] + i * p[2] + p[3]));
    }
    return m;
}

function __bp_case(s, m) {
    let o = "";
    for (const c of s) {
        const r = m.get(c.codePointAt(0));
        o += (r === undefined) ? c : r;
    }
    return o;
}

function __bp_upper(s) {
    return __bp_case(s, __bp_upper.m ??= __bp_case_map("2p,q,1,-w 51,1,2,kn 68,n,1,-w 6w,7,1,-w 73,1,2,3d 75,o,2,-1 8h,1,2,-6g 8j,3,2,-1 8q,8,2,-1 97,n,2,-1 ai,3,2,-1 an,1,2,-8c ao,1,2,5f ar,2,2,-1 aw,1,2,-1 b0,1,2,-1 b6,1,2,-1 b9,1,2,2p bd,1,2,-1 be,1,2,4j bf,1,2,wu9 bi,1,2,3m bl,3,2,-1 bs,1,2,-1 bx,1,2,-1 c0,1,2,-1 c4,2,2,-1 c9,1,2,-1 cd,1,2,-1 cf,1,2,1k cl,1,2,-1 cm,1,2,-2 co,1,2,-1 cp,1,2,-2 cr,1,2,-1 cs,1,2,-2 cu,8,2,-1 d9,1,2,-27 db,9,2,-1 du,1,2,-1 dv,1,2,-2 dx,1,2,-1 e1,k,2,-1 f7,9,2,-1 fw,1,2,-1 fz,2,1,8cf g2,1,2,-1 g7,5,2,-1 gg,1,2,8bj gh,1,2,8bg gi,1,2,8bi gj,1,2,-5u gk,1,2,-5q gm,2,1,-5p gp,1,2,-5m gr,1,2,-5n gs,1,2,wnj gw,1,2,-5p gx,1,2,wnf gz,1,2,-5r h0,1,2,wo7 h1,1,2,wmg h2,1,2,wn8 h4,1,2,-5t h5,1,2,-5v h6,1,2,wn8 h7,1,2,8af h8,1,2,wn5 hb,1,2,-5v hd,1,2,8al he,1,2,-5x hh,1,2,-5y hp,1,2,89z hs,1,2,-62 hu,1,2,wn7 hv,1,2,-62 hz,1,2,wmi i0,1,2,-62 i1,1,2,-1x i2,2,1,-61 i4,1,2,-1z ia,1,2,-63 il,1,2,wlx im,1,2,wlu n9,1,2,2c oh,2,2,-1 on,1,2,-1 or,3,1,3m q4,1,2,-12 q5,3,1,-11 q9,h,1,-w qq,1,2,-v qr,9,1,-w r0,1,2,-1s r1,2,1,-1r r4,1,2,-1q r5,1,2,-1l r9,1,2,-1b ra,1,2,-1i rb,1,2,-8 rd,c,2,-1 s0,1,2,-2e s1,1,2,-28 s2,1,2,7 s3,1,2,-38 s5,1,2,-2o s8,1,2,-1 sb,1,2,-1 ts,w,1,-w uo,g,1,-28 v5,h,2,-1 wb,r,2,-1 xu,7,2,-1 y7,1,2,-f y9,1c,2,-1 129,12,1,-1c 3bk,17,1,2bk 3ct,3,1,2bk 3y0,6,1,-8 5mo,1,2,-4tq 5mp,1,2,-4tp 5mq,1,2,-4tg 5mr,2,1,-4te 5mt,1,2,-4tf 5mu,1,2,-4t8 5mv,1,2,-4rp 5mw,1,2,r7m 5my,1,2,-1 5tl,1,2,r9g 5tp,1,2,2xy 5u6,1,2,raw 5xd,23,2,-1 61n,1,2,-1n 61t,1c,2,-1 64g,8,1,8 64w,6,1,8 65c,8,1,8 65s,8,1,8 668,6,1,8 66p,4,2,8 674,8,1,8 67k,2,1,22 67m,4,1,2e 67q,2,1,2s 67s,2,1,3k 67u,2,1,34 67w,2,1,3i 69c,2,1,8 69q,1,2,-5k5 6a8,2,1,8 6ao,2,1,8 6at,1,2,7 6ku,1,2,-s 6ls,g,1,-g 6mc,1,2,-1 79s,q,1,-q 8q8,1c,1,-1c 8rl,1,2,-1 8rp,1,2,-8bv 8rq,1,2,-8bs 8rs,3,2,-1 8s3,1,2,-1 8s6,1,2,-1 8sh,1e,2,-1 8vg,2,2,-1 8vn,1,2,-1 8w0,12,1,-5ls 8x3,1,2,-5ls 8x9,1,2,-5ls wu9,n,2,-1 ww1,e,2,-1 x0j,7,2,-1 x0z,v,2,-1 x2y,2,2,-1 x33,5,2,-1 x3g,1,2,-1 x3l,2,2,-1 x3o,1,2,1c x3r,a,2,-1 x4l,8,2,-1 x54,2,2,-1 x59,8,2,-1 x6e,1,2,-1 xub,1,2,-ps xv4,28,1,-tzk 1ef5,q,1,-w 1fe0,14,1,-14 1fiw,10,1,-14 1fo7,b,1,-13 1foj,f,1,-13 1foz,7,1,-13 1fp7,2,1,-13 1h34,1f,1,-1s 1h80,m,1,-w 1jgg,w,1,-w 20dc,w,1,-w 20fv,p,1,-r 2oma,y,1,-y !67,2b,2b !95,jg,26 !ds,22,lo !pc,pl,lk,ld !q8,px,lk,ld !13b,111,11u !61i,20,mp !61j,2c,lk !61k,2f,lm !61l,2h,lm !61m,1t,ji !66o,px,lv !66q,px,lv,lc !66s,px,lv,ld !66u,px,lv,n6 !680,64o,pl !681,64p,pl !682,64q,pl !683,64r,pl !684,64s,pl !685,64t,pl !686,64u,pl !687,64v,pl !688,64o,pl !689,64p,pl !68a,64q,pl !68b,64r,pl !68c,64s,pl !68d,64t,pl !68e,64u,pl !68f,64v,pl !68g,65k,pl !68h,65l,pl !68i,65m,pl !68j,65n,pl !68k,65o,pl !68l,65p,pl !68m,65q,pl !68n,65r,pl !68o,65k,pl !68p,65l,pl !68q,65m,pl !68r,65n,pl !68s,65o,pl !68t,65p,pl !68u,65q,pl !68v,65r,pl !68w,67c,pl !68x,67d,pl !68y,67e,pl !68z,67f,pl !690,67g,pl !691,67h,pl !692,67i,pl !693,67j,pl !694,67c,pl !695,67d,pl !696,67e,pl !697,67f,pl !698,67g,pl !699,67h,pl !69a,67i,pl !69b,67j,pl !69e,69m,pl !69f,pd,pl !69g,p2,pl !69i,pd,n6 !69j,pd,n6,pl !69o,pd,pl !69u,6a2,pl !69v,pj,pl !69w,p5,pl !69y,pj,n6 !69z,pj,n6,pl !6a4,pj,pl !6aa,pl,lk,lc !6ab,pl,lk,ld !6ae,pl,n6 !6af,pl,lk,n6 !6aq,px,lk,lc !6ar,px,lk,ld !6as,pt,lv !6au,px,n6 !6av,px,lk,n6 !6b6,6be,pl !6b7,q1,pl !6b8,pb,pl !6ba,q1,n6 !6bb,q1,n6,pl !6bg,q1,pl !1dkw,1y,1y !1dkx,1y,21 !1dky,1y,24 !1dkz,1y,1y,21 !1dl0,1y,1y,24 !1dl1,2b,2c !1dl2,2b,2c !1dlf,11g,11i !1dlg,11g,111 !1dlh,11g,117 !1dli,11q,11i !1dlj,11g,119"));
}

function __bp_show(v, s, top, a) {
    if ((typeof v === "string")) {
        a.push(top ? v : (("\"" + Array.from(v, (c) => ((c === "\"") || (c === "\\")) ? ("\\" + c) : (c === "\n") ? "\\n" : (c === "\r") ? "\\r" : (c === "\t") ? "\\t" : c).join("")) + "\""));
        return "%s";
    }
    if ((typeof v === "bigint")) {
        a.push(String(v));
        return "%s";
    }
    if (((typeof v === "number") && (s === "f"))) {
        a.push(__bp_f64(v));
        return "%s";
    }
    if (Array.isArray(v)) {
        const t = ((s != null) && (s[0] === "#"));
        return (((t ? "#(" : "[") + v.map((e, i) => __bp_show(e, (s == null) ? null : t ? s[i + 1] : s[1], false, a)).join(", ")) + (t ? ")" : "]"));
    }
    if ((((typeof v === "object") && (v != null)) && (typeof v.__bp !== "string"))) {
        const k = Object.keys(v);
        if (((k.length === 1) && ((k[0] === "ok") || (k[0] === "error")))) {
            return ((((k[0] === "ok") ? "Ok(" : "Error(") + __bp_show(v[k[0]], null, false, a)) + ")");
        }
    }
    if (((v != null) && (typeof v.__bp === "string"))) {
        if ((typeof v.display === "function")) {
            a.push(v.display());
            return "%s";
        }
        const k = Object.keys(v);
        return (((typeof Object.getPrototypeOf(v).tag === "string") ? ((v.__bp + ".") + Object.getPrototypeOf(v).tag) : v.__bp) + ((k.length === 0) ? "" : (("(" + k.map((n) => ((n + ": ") + __bp_show(v[n], v.__bp_s?.[n], false, a))).join(", ")) + ")")));
    }
    if ((v === undefined)) return "null";
    a.push(v);
    return "%O";
}

function __bp_print() {
    const a = [];
    const f = Array.from(arguments, (v, i) => __bp_show(v, null, true, a)).join(" ");
    console.log.apply(console, [f, ...a]);
}

function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw Object.defineProperty(new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what), "__bp_panic", { value: true }); }

function parse(s) {
    if ((s === "")) { return ({ error: "empty" }); }
    return ({ ok: [[s, __bp_upper(s)]] });
}

function pairsOf(r) {
    const none = [];
    return ((_r) => "error" in _r ? (none) : _r.ok)(r).map((p) => {
    return [p[0], "=>", p[1]].join("");
}).join("|");
}

function main() {
    __bp_print(pairsOf(parse("a")));
    __bp_print(__bp_str_length(pairsOf(parse(""))));
    const double = (n) => {
    return __bp_int((n * 2), -2147483648, 2147483647, "* on i32 at main.bp:14:43");
};
    const addOne = (n) => {
    return __bp_int((n + 1), -2147483648, 2147483647, "+ on i32 at main.bp:15:43");
};
    __bp_print(functions.compose(double, addOne)(3));
    const shout = (s) => {
    return (s + "!");
};
    __bp_print(functions.compose(shout, shout)("hi"));
    const sub = (a, b) => {
    return __bp_int((a - b), -2147483648, 2147483647, "- on i32 at main.bp:19:48");
};
    __bp_print(functions.flip(sub)(3, 10));
    __bp_print(functions.constant(42)("x"));
}
exports.main = main;

const functions = require("./std/functions.js");

function _botopink_main() {
    main();
}
if (require.main === module) _botopink_main();

Object.defineProperty(exports, "__bp_priv__", { value: { parse, pairsOf, main, functions } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript




export declare function main(): void;

```

----- RUN LOG -----
```logs
a=>A
0
7
hi!!
7
42
```
