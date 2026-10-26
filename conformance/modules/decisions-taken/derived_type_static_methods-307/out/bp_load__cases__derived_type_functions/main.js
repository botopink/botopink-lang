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

function __bp_print() {
    const a = [];
    const f = Array.from(arguments, (v, i) => __bp_show(v, null, true, a)).join(" ");
    console.log.apply(console, [f, ...a]);
}

//// Decision 307 — std's `Type` answers a NEW record type at build, bound by a

//// module-level `val` and named after it: `pick`, `omit`, `partial`,

//// `required` and `merge`, nested and chained, each usable in every type

//// position, constructed by its fields, read, printed and matched by name, on

//// all four targets.

const { Type } = require("../std/types.js");

class Recipe {
    constructor(title, description, servings) {
        this.title = title;
        this.description = description;
        this.servings = servings;
    }
}
Recipe.prototype.__bp = "Recipe";

class Dog {
    constructor(name, age) {
        this.name = name;
        this.age = age;
    }
}
Dog.prototype.__bp = "Dog";

class Breed {
    constructor(breed) {
        this.breed = breed;
    }
}
Breed.prototype.__bp = "Breed";

class Note {
    constructor(text) {
        this.text = text;
    }
}
Note.prototype.__bp = "Note";

class RecipeTitle {
    constructor(title) {
        this.title = title;
    }
}
RecipeTitle.prototype.__bp = "RecipeTitle";

class RecipeBrief {
    constructor(title, servings) {
        this.title = title;
        this.servings = servings;
    }
}
RecipeBrief.prototype.__bp = "RecipeBrief";

class RecipePatch {
    constructor(title, description, servings) {
        this.title = title;
        this.description = description;
        this.servings = servings;
    }
}
RecipePatch.prototype.__bp = "RecipePatch";

class RecipeFull {
    constructor(title, description, servings) {
        this.title = title;
        this.description = description;
        this.servings = servings;
    }
}
RecipeFull.prototype.__bp = "RecipeFull";

class DogWithBreed {
    constructor(name, age, breed) {
        this.name = name;
        this.age = age;
        this.breed = breed;
    }
}
DogWithBreed.prototype.__bp = "DogWithBreed";

// A derivation of a derivation, and a nested call as the source.

class NotedDog {
    constructor(name, age, breed, text) {
        this.name = name;
        this.age = age;
        this.breed = breed;
        this.text = text;
    }
}
NotedDog.prototype.__bp = "NotedDog";

class TitleOnly {
    constructor(title) {
        this.title = title;
    }
}
TitleOnly.prototype.__bp = "TitleOnly";

function titleOf(t) {
    return t.title;
}

function patched(r, p) {
    return new Recipe((() => { const __bp_nullish = p.title; if (__bp_nullish != null) { return __bp_nullish; } else { return r.title; } })(), (() => { const __bp_nullish = p.description; if (__bp_nullish != null) { return __bp_nullish; } else { return r.description; } })(), (() => { const __bp_nullish = p.servings; if (__bp_nullish != null) { return __bp_nullish; } else { return r.servings; } })());
}

// Matched by name: a derived type is its own type, not its source's.

function kind(v) {
    if (v instanceof DogWithBreed) { return "DogWithBreed"; }
    if (v instanceof Dog) { return "Dog"; }
    return "other";
}

function main() {
    __bp_print(titleOf(new RecipeTitle("Feijoada")));
    const brief = new RecipeBrief("Moqueca", 2);
    __bp_print(brief.servings);
    const before = new Recipe("Feijoada", null, 2);
    const after = patched(before, new RecipePatch(null, "black beans", 6));
    __bp_print(after.title);
    __bp_print((() => { const __bp_nullish = after.description; if (__bp_nullish != null) { return __bp_nullish; } else { return "-"; } })());
    __bp_print(after.servings);
    const full = new RecipeFull("Acarajé", "fried", 4);
    __bp_print(full.description);
    const rex = new DogWithBreed("Rex", null, "mutt");
    const bia = new Dog("Bia", 3);
    __bp_print(kind(rex));
    __bp_print(kind(bia));
    const mixed = new DogWithBreed("Lua", 3, "beagle");
    __bp_print((((("" + mixed.name) + " (") + mixed.breed) + ")"));
    const noted = new NotedDog("Lua", 1, "poodle", "calm");
    __bp_print(noted.text);
    __bp_print(new TitleOnly("Vatapá").title);
    __bp_print(new RecipeTitle("Bobó"));
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
    return "cases/derived_type_functions|*";
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

Object.defineProperty(exports, "__bp_priv__", { value: { Type, Recipe, Dog, Breed, Note, RecipeTitle, RecipeBrief, RecipePatch, RecipeFull, DogWithBreed, NotedDog, TitleOnly, titleOf, patched, kind, main, __bp_loaded_main, __bp_loaded_main_off, __bp_loaded_info } });
