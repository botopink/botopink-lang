# Examples — `.bp` source side-by-side with emitted target

> Sibling (AGENTS): [`./AGENTS.md`](AGENTS.md) · Docs: [`./docs.md`](docs.md)

Pairs of `.bp` source and the code each backend emits. Useful for
understanding the shape of output you get after `botopink build`.

## Simple `val` and arithmetic

`.bp`:

```text
val pi  = 3.14;
val tau = pi * 2.0;
```

CommonJS:

```js
const pi  = 3.14;
const tau = pi * 2.0;
```

Erlang:

```erlang
Pi  = 3.14,
Tau = Pi * 2.0.
```

## `fn` declaration

`.bp`:

```text
fn add(a: i32, b: i32) i32 = a + b;
```

CommonJS:

```js
function add(a, b) {
    return a + b;
}
```

Erlang:

```erlang
add(A, B) -> A + B.
```

## `fn main()` entry point wrapper

`.bp`:

```text
fn main() {
    println("hello");
}
```

CommonJS — emitter appends `_botopink_main` + trailing call:

```js
function main() {
    println("hello");
}

function _botopink_main() {
    main();
}
_botopink_main();
```

Erlang — emitter quotes the leading-underscore atom and exposes
`main/1`:

```erlang
main() ->
    println(<<"hello">>).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

`_botopink_main` is quoted because plain Erlang atoms may not start with
`_` — `_botopink_main` alone would be parsed as an unbound variable.

## Records

`.bp`:

```text
record Point { x: f32, y: f32 }

val p = Point { x: 1.0, y: 2.0 };
val px = p.x;
```

CommonJS — records lower to plain object literals:

```js
const p  = { x: 1.0, y: 2.0 };
const px = p.x;
```

Erlang — maps with atom keys:

```erlang
P = #{ x => 1.0, y => 2.0 },
Px = maps:get(x, P).
```

## Pipelines

`.bp`:

```text
val r = [1, 2, 3]
    |> map(fn(x) { x * 2 })
    |> sum();
```

CommonJS:

```js
const r = sum(map([1, 2, 3], (x) => x * 2));
```

Erlang:

```erlang
R = sum(map([1, 2, 3], fun(X) -> X * 2 end)).
```

## Comptime val (inlined before emission)

`.bp`:

```text
val tau: f32 = comptime 2.0 * 3.14159265;
```

After the transform pass the AST has a plain literal, so codegen emits:

CommonJS:

```js
const tau = 6.2831853;
```

Erlang:

```erlang
Tau = 6.2831853.
```

## Comptime specialisation

`.bp`:

```text
fn scale(comptime f: f32, x: f32) f32 = x * f;
val a = scale(2.0, 3.0);
val b = scale(0.5, 9.0);
```

The transform pass specialises and mangles before codegen runs. CommonJS:

```js
function scale_$0(x) { return x * 2.0; }
function scale_$1(x) { return x * 0.5; }

const a = scale_$0(3.0);
const b = scale_$1(9.0);
```

Erlang:

```erlang
'scale_$0'(X) -> X * 2.0.
'scale_$1'(X) -> X * 0.5.

A = 'scale_$0'(3.0),
B = 'scale_$1'(9.0).
```

The original `scale` is dropped because every call was specialised.

## BEAM Assembly (`.S`, Fase 1 subset)

`.bp`:

```text
pub fn max(a: i32, b: i32) -> i32 {
    if (a < b) {
        return b;
    } else {
        return a;
    }
}
```

BEAM Assembly — the textual form `erlc +to_asm` produces (and which
`erlc +from_asm` re-assembles to a `.beam`):

```erlang
{module, main}.
{exports, [{max, 2}]}.
{attributes, []}.
{labels, 5}.

{function, max, 2, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, max}, 2}.
  {label, 3}.
    {test, is_lt, {f, 4}, [{x, 0}, {x, 1}]}.
    {move, {x, 1}, {x, 0}}.
    return.
  {label, 4}.
    return.
```

`is_lt` continues if `{x,0} < {x,1}` is true; otherwise it jumps to label
4 — the inverse of the symbolic `if_less` form you may see in BEAM
introductions. Arithmetic uses `{gc_bif, '+'/'-'/'*'/'div'/'rem', ...}`;
comparisons go through `{test, is_lt|is_gt|is_le|is_ge|is_eq|is_ne_exact, ...}`.

## BEAM Assembly — strings and field access

`.bp`:

```text
val Vec2 = record {
    x: f64,
    y: f64,
    fn scale(self: Self, factor: f64) -> f64 {
        return self.x * factor;
    }
}
```

BEAM Assembly — `self.x` lowers to `{get_map_elements, ...}`:

```erlang
{function, 'Vec2_scale', 2, 5}.
  {label, 4}.
    {func_info, {atom, main}, {atom, 'Vec2_scale'}, 2}.
  {label, 5}.
    {get_map_elements, {f, 6}, {x, 0}, {list, [{atom, x}, {x, 0}]}}.
  {label, 6}.
    {move, {x, 0}, {x, 2}}.
    {gc_bif, '*', {f, 0}, 3, [{x, 2}, {x, 1}], {x, 0}}.
    return.
```

String literals use `{literal, <<"...">>}` and `@print` calls `io:format/2`:

```erlang
{move, {literal, <<"Hello">>}, {x, 0}}.
{move, {x, 0}, {x, 1}}.
{move, {literal, <<"~p~n">>}, {x, 0}}.
{put_list, {x, 1}, nil, {x, 1}}.
{call_ext, 2, {extfunc, io, format, 2}}.
```

## WASM Text (`.wat`, Fase 1 subset)

`.bp`:

```text
pub fn max(a: i32, b: i32) -> i32 {
    if (a < b) {
        return b;
    } else {
        return a;
    }
}
```

WAT — an S-expression module that `wat2wasm` or `wasmtime` can consume
directly:

```wasm
(module
  (func $max (export "max") (param $a i32) (param $b i32) (result i32)
    local.get $a
    local.get $b
    i32.lt_s
    (if (result i32)
      (then
    local.get $b
    return
      )
      (else
    local.get $a
    return
      )
    )
  )
)
```

Operands are pushed onto the stack then consumed by the operation.
Arithmetic uses `i32.add`/`i32.sub`/`i32.mul`/`i32.div_s`/`i32.rem_s`
(or `f32.add`/`f32.div` etc. for floats). Comparisons become
`i32.lt_s`/`i32.gt_s`/`i32.eq`/`i32.ne` etc. Top-level `val` literals
lower to `(global $name i32 (i32.const N))`.

## WASM Text — locals and calls

`.bp`:

```text
fn increment() {
    var count = 0;
    count += 1;
}
```

WAT — local variables use `(local $name T)` + `local.set`/`local.get`:

```wasm
(module
  (func $increment
    (local $count i32)
    i32.const 0
    local.set $count
    local.get $count
    i32.const 1
    i32.add
    local.set $count
  )
)
```

Function calls emit `(call $fn ...)` with arguments pushed onto the
stack first. `@todo`/`@panic` emit `unreachable`. `!x` emits `i32.eqz`.

## TypeScript typedef (when configured)

`.bp`:

```text
record Point { x: f32, y: f32 }
fn add(a: Point, b: Point) Point = Point { x: a.x + b.x, y: a.y + b.y };
```

`main.d.ts`:

```ts
export interface Point { x: number; y: number; }
export function add(a: Point, b: Point): Point;
```

## See also

- Codegen design (why emitters are blind) → [`./docs.md`](docs.md).
- Where comptime work happens before codegen → [`../comptime/docs.md`](../comptime/docs.md).
- Full language reference → [`../../../../docs.md`](../../../../docs.md).
