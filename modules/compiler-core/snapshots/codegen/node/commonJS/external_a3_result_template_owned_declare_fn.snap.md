----- SOURCE CODE -- main.bp
```botopink
#[@result]
#[@External.Erlang( """(fun(__S) -> try {ok, binary_to_integer(__S)} catch _:_ -> {error, <<"not a number">>} end end)($0)"""),
  @External.Node("""(() => { const __n = Number($0); return Number.isFinite(__n) ? { ok: __n } : { error: "not a number" } })()""")]
pub declare fn parseInt(s: string) -> @Result<i32, string>;

fn main() {
    val r = parseInt("42");
    @print(r.unwrapOr(-1));
}
```

----- JAVASCRIPT -- main.js
```javascript
// parseInt: per-call template (see annotation)

function main() {
    const r = (() => { const __n = Number("42"); return Number.isFinite(__n) ? { ok: __n } : { error: "not a number" } })();
    console.log(((_r) => "error" in _r ? ((-1)) : _r.ok)(r));
}

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript
export declare function parseInt(s: ): { tag: "Ok"; result: i32 } | { tag: "Error"; error: string };



```

----- RUN LOG -----
```logs
42
```
