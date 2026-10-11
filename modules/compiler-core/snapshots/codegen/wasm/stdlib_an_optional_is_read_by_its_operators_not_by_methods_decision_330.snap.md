----- SOURCE CODE -- main.bp
```botopink
type Person(name: string)
fn find(p: Person) -> ?Person { @todo(); }
fn greet(p: Person) -> string {
    return find(p)?.name ?? "Hello stranger";
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\0e\00\00\00Hello stranger")
  (global $__heap_ptr (mut i32) (i32.const 276))
  (func $find (param $p i32) (result i32)
    unreachable
    i32.const 0
  )
  (func $greet (param $p i32) (result i32)
    (local $__mem0 i32)
    (local $__bp_nullish i32)
    (local $__opt0 i32)
    local.get $p
    call $find
    local.tee $__mem0
    i32.eqz
    (if (result i32)
      (then
        i32.const 0 ;; ?.name on null
      )
      (else
        local.get $__mem0
        i32.load ;; ?.name
      )
    )
    local.tee $__opt0
    (if (result i32)
      (then
    local.get $__opt0
    local.set $__bp_nullish
    local.get $__bp_nullish
      )
      (else
    i32.const 256
      )
    )
    return
  )
)
```

----- RUN LOG -----
```logs
```
