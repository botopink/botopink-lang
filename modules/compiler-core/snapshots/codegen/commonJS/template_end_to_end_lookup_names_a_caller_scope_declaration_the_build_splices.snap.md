----- SOURCE CODE -- main.bp
```botopink
val greeting = "ola mundo";
pub fn refer(comptime q: @Expr<string>) -> @Expr<string> {
    val hit = q.lookup("greeting");
    if (hit) { b ->
        return q.build(b.name);
    } else {
        return q.fail("greeting not found in caller scope");
    };
}
val s = refer "greeting";
fn main() {
    @print(s);
}
```

----- COMPTIME WAT -- template refer
```wat
(func $refer/1 (param $a0 i32) (result i32)
  (local $V_Q i32) (local $s1 i32) (local $s2 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_Q
  local.get $V_Q
  global.get $__lit
  i32.const 288
  i32.add
  i32.const 8
  call $rt_bin
  call $bp_comptime_template:lookup/2
  call $rt_pending
  br_if $raise
  local.set $s1
  (block $L4
  (block $L3
  local.get $s1
  local.set $s2
  br $L4
  )
  local.get $s1
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s1
  drop
  local.get $s2
  local.set $s1
  (block $L5 (result i32)
  (block $L6
  local.get $s1
  global.get $__lit
  i32.const 112
  i32.add
  i32.const 9
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L6
  local.get $V_Q
  global.get $__lit
  i32.const 296
  i32.add
  i32.const 34
  call $rt_bin
  call $bp_comptime_template:fail/2
  call $rt_pending
  br_if $raise
  br $L5
  )
  (block $L7
  local.get $s1
  local.set $s2
  local.get $V_Q
  global.get $__lit
  i32.const 336
  i32.add
  i32.const 4
  call $rt_atom
  local.get $s2
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  call $bp_comptime_template:build/2
  call $rt_pending
  br_if $raise
  br $L5
  )
  local.get $s1
  call $rt_case_clause
  drop
  br $raise
  )
  br $L1
  )
  call $rt_function_clause
  drop
  br $raise
  )
  return
  )
  i32.const 0
)

;; main/1 argument — an external term, not part of the module:
;; Arg0 = #{
;;     '__bp_capture' => <<"q">>,
;;     text => <<"greeting">>,
;;     parts => [
;;         #{
;;             kind => <<"Text">>,
;;             text => <<"greeting">>,
;;             span => #{start => 0, 'end' => 8, line => 1}
;;         }
;;     ],
;;     source => #{file => <<"">>, line => 10, col => 15},
;;     context => #{
;;         source => #{file => <<"">>, line => 10, col => 15},
;;         text => <<"greeting">>,
;;         multiline => false
;;     },
;;     bindings => [
;;         #{
;;             kind => 'Val',
;;             name => <<"greeting">>,
;;             fields => [],
;;             variants => [],
;;             methods => [],
;;             returnType => <<"">>,
;;             annotations => [],
;;             hooks => [],
;;             params => [],
;;             component => undefined,
;;             module => <<"">>,
;;             owner => undefined,
;;             meta => [],
;;             identity => <<"main@@greeting">>,
;;             local => <<"greeting">>
;;         }
;;     ],
;;     words => [<<"greeting">>]
;; }
```

----- COMPTIME REPLY -- template refer
```json
{
  "kind": "code",
  "source": "greeting"
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

function __bp_print() {
    const a = [];
    const f = Array.from(arguments, (v, i) => __bp_show(v, null, true, a)).join(" ");
    console.log.apply(console, [f, ...a]);
}

const greeting = "ola mundo";

exports.greeting = greeting;

const s = greeting;

exports.s = s;

function main() {
    __bp_print(s);
}
exports.main = main;

function _botopink_main() {
    main();
}
if (require.main === module) _botopink_main();

Object.defineProperty(exports, "__bp_priv__", { value: { greeting, s, main } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript







```

----- RUN LOG -----
```logs
ola mundo
```
