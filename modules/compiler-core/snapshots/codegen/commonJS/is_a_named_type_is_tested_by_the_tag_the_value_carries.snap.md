----- SOURCE CODE -- main.bp
```botopink
type Person(name: string, age: i32)
type Vec(name: string, age: i32)
type Shape { Dot, Circle(radius: i32) }

fn nameOf(v: Person | Vec) -> string {
    return case v {
        Person { "person" }
        Vec { "vec" }
    };
}

fn main() {
    val u: unknown = Vec(name: "Ana", age: 30);
    @print(u is Vec);
    @print(u is Person);
    val s: unknown = Shape.Circle(radius: 4);
    @print(s is Shape);
    val d: unknown = Shape.Dot;
    @print(d is Shape);
    @print(nameOf(Person(name: "Ana", age: 30)));
    @print(nameOf(Vec(name: "Ana", age: 30)));
}
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

function __bp_text(v) {
    const a = [];
    let i = 0;
    return __bp_show(v, null, true, a).replace(/%[sO]/g, () => String(a[i++]));
}

function __bp_print() {
    const a = [];
    const f = Array.from(arguments, (v, i) => __bp_show(v, null, true, a)).join(" ");
    console.log.apply(console, [f, ...a]);
}

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

class Shape {
    static Circle(radius) {
        return new Shape$Circle(radius);
    }

    toString() {
        return __bp_text(this);
    }
}
Shape.prototype.__bp = "Shape";
class Shape$Dot extends Shape {
}
Shape$Dot.prototype.tag = "Dot";
class Shape$Circle extends Shape {
    constructor(radius) {
        super();
        this.radius = radius;
    }
}
Shape$Circle.prototype.tag = "Circle";
Shape.Dot = new Shape$Dot();

function nameOf(v) {
    return (() => {
        const _s = v;
        if (_s instanceof Person) {
            return "person";
        }
        if (_s instanceof Vec) {
            return "vec";
        }
    })();
}

function main() {
    const u = new Vec("Ana", 30);
    __bp_print(u instanceof Vec);
    __bp_print(u instanceof Person);
    const s = Shape.Circle(4);
    __bp_print(s instanceof Shape);
    const d = Shape.Dot;
    __bp_print(d instanceof Shape);
    __bp_print(nameOf(new Person("Ana", 30)));
    __bp_print(nameOf(new Vec("Ana", 30)));
}

function _botopink_main() {
    main();
}
if (require.main === module) _botopink_main();

Object.defineProperty(exports, "__bp_priv__", { value: { Person, Vec, Shape, Shape$Dot, Shape$Circle, nameOf, main } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript









```

----- RUN LOG -----
```logs
true
false
true
true
person
vec
```
