function __bp_array_at(xs, i) { return xs.at(i) ?? null; }

function __bp_eq(a, b, d) {
    if (Object.is(a, b)) {
        return true;
    }
    if ((((((d > 32) || (a === null)) || (b === null)) || (typeof a !== "object")) || (a.constructor !== b.constructor))) {
        return false;
    }
    if (Array.isArray(a)) {
        return ((a.length === b.length) && a.every((e, i) => __bp_eq(e, b[i], (d + 1))));
    }
    const k = Object.keys(a);
    return ((k.length === Object.keys(b).length) && k.every((n) => __bp_eq(a[n], b[n], (d + 1))));
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

function __bp_text(v, s) {
    const a = [];
    let i = 0;
    return __bp_show(v, s == null ? null : s, true, a).replace(/%[sO]/g, () => String(a[i++]));
}

function __bp_print() {
    const a = [];
    const f = Array.from(arguments, (v, i) => __bp_show(v, null, true, a)).join(" ");
    console.log.apply(console, [f, ...a]);
}

function __bp_eq_Person(a, b) {
    if (a === b) return true;
    return a.name === b.name && a.age === b.age;
}

function __bp_eq_Team(a, b) {
    if (a === b) return true;
    return __bp_eq_Person(a.lead, b.lead) && a.size === b.size;
}

function __bp_eq_Tuple2_i32_string(a, b) {
    if (a === b) return true;
    return a[0] === b[0] && a[1] === b[1];
}

function __bp_eq_Array_Person(a, b) {
    if (a === b) return true;
    return a.length === b.length && a.every((e, i) => __bp_eq_Person(e, b[i]));
}

function __bp_eq_Shape(a, b) {
    if (a === b) return true;
    if (a.tag !== b.tag) return false;
    if (a.tag === "Circle") return a.r === b.r;
    if (a.tag === "Rect") return a.w === b.w && a.h === b.h;
    return true;
}

function __bp_eq_Loose(a, b) {
    if (a === b) return true;
    return a.n === b.n;
}

//// Decision 210 — `==` compares by value on every target. Two records of the

//// same type with equal fields are equal, recursively through a nested

//// record, a tuple, an `Array` and an enum variant's payload; two values of

//// different types are never equal, however alike their fields (decision 21:

//// a value carries its declaring type); `!=` is the negation. erlang and beam

//// compare one term (`=:=`); commonJS and wasm answered `false` for two equal

//// records — a reference and a pointer — and now call an equality generated

//// per compared type. A generic body (`same<T>`) answers by value too.

//// Decision 211: `==` is always field by field — a method named `equals`

//// has no special role and `==` never calls user code.

class Person {
    constructor(name, age) {
        this.name = name;
        this.age = age;
    }
}
Person.prototype.__bp = "Person";

class Vec {
    constructor(name, age) {
        this.name = name;
        this.age = age;
    }
}
Vec.prototype.__bp = "Vec";

class Team {
    constructor(lead, size) {
        this.lead = lead;
        this.size = size;
    }
}
Team.prototype.__bp = "Team";

class Loose {
    constructor(n) {
        this.n = n;
    }

    equals(other) {
        return true;
    }
}
Loose.prototype.__bp = "Loose";

class Shape {
    static Circle(r) {
        return new Shape$Circle(r);
    }

    static Rect(w, h) {
        return new Shape$Rect(w, h);
    }

    toString() {
        return __bp_text(this);
    }
}
Shape.prototype.__bp = "Shape";
class Shape$Circle extends Shape {
    constructor(r) {
        super();
        this.r = r;
    }

    get $0() {
        return this.r;
    }
}
Shape$Circle.prototype.tag = "Circle";
class Shape$Rect extends Shape {
    constructor(w, h) {
        super();
        this.w = w;
        this.h = h;
    }

    get $0() {
        return this.w;
    }

    get $1() {
        return this.h;
    }
}
Shape$Rect.prototype.tag = "Rect";
class Shape$Dot extends Shape {
}
Shape$Dot.prototype.tag = "Dot";
Shape.Dot = new Shape$Dot();

function same(a, b) {
    return __bp_eq(a, b, 0);
}

function main() {
    const built = (() => { const __bp_nullish = __bp_array_at("Ana,x".split(","), 0); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })();
    __bp_print(__bp_eq_Person(new Person("Ana", 30), new Person("Ana", 30)));
    __bp_print(__bp_eq_Person(new Person(built, 30), new Person("Ana", 30)));
    __bp_print(__bp_eq_Person(new Person("Ana", 30), new Person("Ana", 31)));
    __bp_print(__bp_eq_Person(new Person("Ana", 30), new Person("Bia", 30)));
    __bp_print((!__bp_eq_Person(new Person("Ana", 30), new Person("Ana", 30))));
    __bp_print((!__bp_eq_Person(new Person("Ana", 30), new Person("Ana", 31))));
    const p = new Person("Ana", 30);
    __bp_print(__bp_eq_Person(p, p));
    __bp_print(__bp_eq_Team(new Team(new Person("Ana", 30), 3), new Team(new Person(built, 30), 3)));
    __bp_print(__bp_eq_Team(new Team(new Person("Ana", 30), 3), new Team(new Person("Ana", 29), 3)));
    const t1 = [1, "a"];
    const a = (() => { const __bp_nullish = __bp_array_at("a;y".split(";"), 0); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })();
    const t2 = [1, a];
    const t3 = [1, "b"];
    const t4 = [2, "a"];
    __bp_print(__bp_eq(t1, t2, 0));
    __bp_print(__bp_eq_Tuple2_i32_string(t1, t3));
    __bp_print((!__bp_eq_Tuple2_i32_string(t1, t4)));
    const xs = [new Person("Ana", 30), new Person("Bia", 25)];
    const ys = [new Person(built, 30), new Person("Bia", 25)];
    const zs = [new Person("Ana", 30)];
    __bp_print(__bp_eq_Array_Person(xs, ys));
    __bp_print(__bp_eq_Array_Person(xs, zs));
    __bp_print((!__bp_eq_Array_Person(xs, zs)));
    __bp_print(__bp_eq_Shape(Shape.Circle(2), Shape.Circle(2)));
    __bp_print(__bp_eq_Shape(Shape.Circle(2), Shape.Circle(3)));
    __bp_print(__bp_eq_Shape(Shape.Rect(1, 2), Shape.Rect(1, 2)));
    __bp_print(__bp_eq_Shape(Shape.Rect(1, 2), Shape.Circle(1)));
    __bp_print(__bp_eq_Shape(Shape.Dot, Shape.Dot));
    __bp_print((!__bp_eq_Shape(Shape.Dot, Shape.Circle(0))));
    __bp_print(__bp_eq(new Person("Ana", 30), new Vec("Ana", 30), 0));
    __bp_print((!__bp_eq(new Person("Ana", 30), new Vec("Ana", 30), 0)));
    __bp_print(same(new Person(built, 30), new Person("Ana", 30)));
    __bp_print(same(new Person("Ana", 30), new Person("Ana", 1)));
    __bp_print(same(t1, t2));
    __bp_print(same([1, 2], [1, 2]));
    __bp_print(same(Shape.Rect(1, 2), Shape.Rect(1, 2)));
    __bp_print(__bp_eq_Loose(new Loose(1), new Loose(2)));
}
exports.main = main;

function __bp_loaded_main() {
    main();
    return ({ ok: null });
}
exports.__bp_loaded_main = __bp_loaded_main;

function __bp_loaded_main_off() {
    return ({ error: "" });
}
exports.__bp_loaded_main_off = __bp_loaded_main_off;

function __bp_loaded_info() {
    return "cases/record_structural_equality|*";
}
exports.__bp_loaded_info = __bp_loaded_info;

function _botopink_main() {
    main();
}
if (require.main === module) {
    const __bp_abort = (e) => { const k = (e != null && e.__bp_panic != null) ? ["panic", (typeof e.__bp_panic === "string") ? e.__bp_panic : e.message] : (e != null && typeof e.__bp_assert_loc === "string") ? ["panic", e.message] : [(e != null && e.__bp_host === true) ? "host" : "crash", (e instanceof Error) ? e.message : String(e)]; globalThis.process.stderr.write(k[0] + ": " + k[1] + "\n", () => globalThis.process.exit(1)); };
    globalThis.process.on("uncaughtException", __bp_abort);
    globalThis.process.on("unhandledRejection", __bp_abort);
    _botopink_main();
}

Object.defineProperty(exports, "__bp_priv__", { value: { Person, Vec, Team, Loose, Shape, Shape$Circle, Shape$Rect, Shape$Dot, same, main, __bp_loaded_main, __bp_loaded_main_off, __bp_loaded_info } });
