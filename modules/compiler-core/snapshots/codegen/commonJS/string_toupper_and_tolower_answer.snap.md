----- SOURCE CODE -- main.bp
```botopink
fn main() -> void {
    print("aB".toUpper());
    print("aB".toLower());
}

import {io.terminal.print} from "std";
```

----- JAVASCRIPT -- main.js
```javascript
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

function __bp_lower(s) {
    return __bp_case(s, __bp_lower.m ??= __bp_case_map("1t,q,1,w 5c,n,1,w 60,7,1,w 74,o,2,1 8i,3,2,1 8p,8,2,1 96,n,2,1 ag,1,2,-3d ah,3,2,1 ap,1,2,5u aq,2,2,1 au,1,2,5q av,1,2,1 ax,2,1,5p az,1,2,1 b2,1,2,27 b3,1,2,5m b4,1,2,5n b5,1,2,1 b7,1,2,5p b8,1,2,5r ba,1,2,5v bb,1,2,5t bc,1,2,1 bg,1,2,5v bh,1,2,5x bj,1,2,5y bk,3,2,1 bq,1,2,62 br,1,2,1 bt,1,2,62 bw,1,2,1 by,1,2,62 bz,1,2,1 c1,2,1,61 c3,2,2,1 c7,1,2,63 c8,1,2,1 cc,1,2,1 ck,1,2,2 cl,1,2,1 cn,1,2,2 co,1,2,1 cq,1,2,2 cr,9,2,1 da,9,2,1 dt,1,2,2 du,2,2,1 dy,1,2,-2p dz,1,2,-1k e0,k,2,1 f4,1,2,-3m f6,9,2,1 fu,1,2,8bv fv,1,2,1 fx,1,2,-4j fy,1,2,8bs g1,1,2,1 g3,1,2,-5f g4,1,2,1x g5,1,2,1z g6,5,2,1 og,2,2,1 om,1,2,1 ov,1,2,38 p2,1,2,12 p4,3,1,11 p8,1,2,1s pa,2,1,1r pd,h,1,w pv,9,1,w r3,1,2,8 rc,c,2,1 s4,1,2,-1o s7,1,2,1 s9,1,2,-7 sa,1,2,1 sd,3,1,-3m sg,g,1,28 sw,w,1,w v4,h,2,1 wa,r,2,1 xs,1,2,f xt,7,2,1 y8,1c,2,1 10x,12,1,1c 3a8,12,1,5ls 3bb,1,2,5ls 3bh,1,2,5ls 3vk,28,1,tzk 3xs,6,1,8 5mx,1,2,1 5n4,17,1,-2bk 5od,3,1,-2bk 5xc,23,2,1 61q,1,2,-5vj 61s,1c,2,1 64o,8,1,-8 654,6,1,-8 65k,8,1,-8 660,8,1,-8 66g,6,1,-8 66x,4,2,-8 67c,8,1,-8 688,8,1,-8 68o,8,1,-8 694,8,1,-8 69k,2,1,-8 69m,2,1,-22 69o,1,2,-9 6a0,4,1,-2e 6a4,1,2,-9 6ag,2,1,-8 6ai,2,1,-2s 6aw,2,1,-8 6ay,2,1,-34 6b0,1,2,-7 6bc,2,1,-3k 6be,2,1,-3i 6bg,1,2,-9 6jq,1,2,-5st 6ju,1,2,-6gv 6jv,1,2,-6di 6k2,1,2,s 6lc,g,1,g 6mb,1,2,1 792,q,1,q 8ow,1c,1,1c 8rk,1,2,1 8rm,1,2,-8af 8rn,1,2,-2xy 8ro,1,2,-89z 8rr,3,2,1 8rx,1,2,-8bg 8ry,1,2,-8al 8rz,1,2,-8bj 8s0,1,2,-8bi 8s2,1,2,1 8s5,1,2,1 8se,2,1,-8cf 8sg,1e,2,1 8vf,2,2,1 8vm,1,2,1 wu8,n,2,1 ww0,e,2,1 x0i,7,2,1 x0y,v,2,1 x2x,2,2,1 x31,1,2,-r9g x32,5,2,1 x3f,1,2,1 x3h,1,2,-wmg x3k,2,2,1 x3q,a,2,1 x4a,1,2,-wn8 x4b,1,2,-wnj x4c,1,2,-wnf x4d,1,2,-wn5 x4e,1,2,-wn8 x4g,1,2,-wlu x4h,1,2,-wmi x4i,1,2,-wlx x4j,1,2,ps x4k,8,2,1 x50,1,2,-1c x51,1,2,-wn7 x52,1,2,-raw x53,2,2,1 x57,1,2,-wo7 x58,8,2,1 x5o,1,2,-wu9 x6d,1,2,1 1ee9,q,1,w 1fcw,14,1,14 1fhs,10,1,14 1fn4,b,1,13 1fng,f,1,13 1fnw,7,1,13 1fo4,2,1,13 1h1c,1f,1,1s 1h74,m,1,w 1jfk,w,1,w 20cg,w,1,w 20f4,p,1,r 2olc,y,1,y !8g,2x,lj"));
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

function main() {
    __bp_print(__bp_upper("aB"));
    __bp_print(__bp_lower("aB"));
}

function _botopink_main() {
    main();
}
if (require.main === module) _botopink_main();

Object.defineProperty(exports, "__bp_priv__", { value: { main } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
AB
ab
```
