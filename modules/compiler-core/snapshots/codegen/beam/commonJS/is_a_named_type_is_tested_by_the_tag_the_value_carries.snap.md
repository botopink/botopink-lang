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
function __bp_show(v, s, top, a) {
    if ((typeof v === "string")) {
        a.push(top ? v : (("\"" + Array.from(v, (c) => ((c === "\"") || (c === "\\")) ? ("\\" + c) : (c === "\n") ? "\\n" : (c === "\r") ? "\\r" : (c === "\t") ? "\\t" : c).join("")) + "\""));
        return "%s";
    }
    if (((typeof v === "number") && (s === "f"))) {
        a.push(Number.isInteger(v) ? v.toFixed(1) : String(v));
        return "%s";
    }
    if (Array.isArray(v)) {
        const t = ((s != null) && (s[0] === "#"));
        return (((t ? "#(" : "[") + v.map((e, i) => __bp_show(e, (s == null) ? null : t ? s[i + 1] : s[1], false, a)).join(", ")) + (t ? ")" : "]"));
    }
    if (((v != null) && (typeof v.__bp === "string"))) {
        if ((typeof v.display === "function")) {
            a.push(v.display());
            return "%s";
        }
        const k = Object.keys(v);
        return (((typeof v.tag === "string") ? ((v.__bp + ".") + v.tag) : v.__bp) + ((k.length === 0) ? "" : (("(" + k.map((n) => ((n + ": ") + __bp_show(v[n], null, false, a))).join(", ")) + ")")));
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
_botopink_main();
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
