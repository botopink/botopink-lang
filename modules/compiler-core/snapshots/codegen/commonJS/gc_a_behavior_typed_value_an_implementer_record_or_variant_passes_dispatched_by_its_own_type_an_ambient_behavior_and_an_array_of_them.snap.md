----- SOURCE CODE -- main.bp
```botopink
import {io.terminal.print} from "std";

behavior Greeter {
    fn greet(self: Self, punct: string) -> string;
}

type Bob(name: string) implement Greeter {
    fn greet(self: Self, punct: string) -> string {
        return "hi " + self.name + punct;
    }
}

type Ann(age: i32) implement Greeter {
    fn greet(self: Self, punct: string) -> string {
        return "ann " + self.age.toString() + punct;
    }
}

type Pet implement Greeter {
    Dog(name: string),
    Cat(lives: i32),

    fn greet(self: Self, punct: string) -> string {
        return case self {
            Dog(name) -> "woof " + name + punct;
            Cat(lives) -> "meow " + lives.toString() + punct;
        };
    }
}

type Door(name: string) implement Closeable {
    fn close(self: Self) -> void {
        print("closed " + self.name);
    }
}

type Registry(names: string[]) implement Index<string, i32> {
    pub fn at(self: Self, key: string) -> ?i32 {
        val found = self.names.indexOf(key);
        if (found < 0) return null;
        return found;
    }
}

fn welcome(g: Greeter) -> string {
    return g.greet("!");
}

fn make(old: bool) -> Greeter {
    if (old) return Ann(age: 70);
    return Bob(name: "b");
}

fn shut(c: Closeable) -> void {
    c.close();
}

fn lookup(m: Index<string, i32>, key: string) -> i32 {
    return m.at(key) ?? -1;
}

pub fn main() -> void {
    print(welcome(Bob(name: "bob")));
    print(welcome(make(true)));
    print(welcome(make(false)));
    print(welcome(Pet.Dog(name: "rex")));
    print(welcome(Pet.Cat(lives: 9)));
    val all: Greeter[] = [Bob(name: "x"), Ann(age: 3), Pet.Cat(lives: 1)];
    for (all) { g ->
        print(g.greet("?"));
    }
    shut(Door(name: "front"));
    val r = Registry(names: ["ana", "bo"]);
    print(lookup(r, "bo"));
    print(lookup(r, "zz"));
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

// behavior Greeter
//   fn greet(...)

class Bob {
    constructor(name) {
        this.name = name;
    }

    greet(punct) {
        return (("hi " + this.name) + punct);
    }
}
Bob.prototype.__bp = "Bob";
Bob.prototype["__bp_b_test@main@@Greeter"] = true;

class Ann {
    constructor(age) {
        this.age = age;
    }

    greet(punct) {
        return (("ann " + this.age.toString()) + punct);
    }
}
Ann.prototype.__bp = "Ann";
Ann.prototype["__bp_b_test@main@@Greeter"] = true;

class Pet {
    static Dog(name) {
        return new Pet$Dog(name);
    }

    static Cat(lives) {
        return new Pet$Cat(lives);
    }

    static greet(self, punct) {
        return (() => {
            const _s = self;
            if (_s.tag === "Dog") {
                const { name } = _s;
                return (("woof " + name) + punct);
            }
            if (_s.tag === "Cat") {
                const { lives } = _s;
                return (("meow " + lives.toString()) + punct);
            }
            throw new Error("case_clause");
        })();
    }

    greet(punct) {
        return Pet.greet(this, punct);
    }

    toString() {
        return __bp_text(this);
    }
}
Pet.prototype.__bp = "Pet";
Pet.prototype["__bp_b_test@main@@Greeter"] = true;
class Pet$Dog extends Pet {
    constructor(name) {
        super();
        this.name = name;
    }
}
Pet$Dog.prototype.tag = "Dog";
class Pet$Cat extends Pet {
    constructor(lives) {
        super();
        this.lives = lives;
    }
}
Pet$Cat.prototype.tag = "Cat";

class Door {
    constructor(name) {
        this.name = name;
    }

    close() {
        __bp_print(("closed " + this.name));
    }
}
Door.prototype.__bp = "Door";
Door.prototype["__bp_b_std@primitives@@Closeable"] = true;

class Registry {
    constructor(names) {
        this.names = names;
    }

    at(key) {
        const found = this.names.indexOf(key);
        if ((found < 0)) { return null; }
        return found;
    }
}
Registry.prototype.__bp = "Registry";
Registry.prototype["__bp_b_std@primitives@@Index"] = true;

function welcome(g) {
    return g.greet("!");
}

function make(old) {
    if (old) { return new Ann(70); }
    return new Bob("b");
}

function shut(c) {
    c.close();
}

function lookup(m, key) {
    return (() => { const __bp_nullish = m.at(key); if (__bp_nullish != null) { return __bp_nullish; } else { return (-1); } })();
}

function main() {
    __bp_print(welcome(new Bob("bob")));
    __bp_print(welcome(make(true)));
    __bp_print(welcome(make(false)));
    __bp_print(welcome(Pet.Dog("rex")));
    __bp_print(welcome(Pet.Cat(9)));
    const all = [new Bob("x"), new Ann(3), Pet.Cat(1)];
    for (const g of all) {
    __bp_print(g.greet("?"));
}
    shut(new Door("front"));
    const r = new Registry(["ana", "bo"]);
    __bp_print(lookup(r, "bo"));
    __bp_print(lookup(r, "zz"));
}
exports.main = main;

function _botopink_main() {
    main();
}
if (require.main === module) {
    const __bp_abort = (e) => { const k = (e != null && e.__bp_panic != null) ? ["panic", (typeof e.__bp_panic === "string") ? e.__bp_panic : e.message] : (e != null && typeof e.__bp_assert_loc === "string") ? ["panic", e.message] : [(e != null && e.__bp_host === true) ? "host" : "crash", (e instanceof Error) ? e.message : String(e)]; globalThis.process.stderr.write(k[0] + ": " + k[1] + "\n", () => globalThis.process.exit(1)); };
    globalThis.process.on("uncaughtException", __bp_abort);
    globalThis.process.on("unhandledRejection", __bp_abort);
    _botopink_main();
}

Object.defineProperty(exports, "__bp_priv__", { value: { Bob, Ann, Pet, Pet$Dog, Pet$Cat, Door, Registry, welcome, make, shut, lookup, main } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript




















export declare function main(): void;

```

----- RUN LOG -----
```logs
hi bob!
ann 70!
hi b!
woof rex!
meow 9!
hi x?
ann 3?
meow 1?
closed front
1
-1
```
