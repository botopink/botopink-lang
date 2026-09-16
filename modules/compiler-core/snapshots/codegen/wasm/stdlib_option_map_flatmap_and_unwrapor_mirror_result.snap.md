----- SOURCE CODE -- main.bp
```botopink
record Person { name: string }
fn firstName(p: Person) -> ?string { @todo(); }
fn shout(s: string) -> ?string { @todo(); }
fn greet(p: Person) -> string {
    return firstName(p)
        .map({ n -> "Hello " + n })
        .flatMap({ n -> shout(n) })
        .unwrapOr("Hello stranger");
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\06\00\00\00Hello ")
  (data (i32.const 268) "\0e\00\00\00Hello stranger")
  (global $__heap_ptr (mut i32) (i32.const 288))
  (func $firstName (param $p i32) (result i32)
    unreachable
    i32.const 0
  )
  (func $shout (param $s i32) (result i32)
    unreachable
    i32.const 0
  )
  (func $greet (param $p i32) (result i32)
    (local $_res0 i32)
    (local $_res1 i32)
    (local $_res2 i32)
    (local $n i32)
    local.get $p
    call $firstName
    local.set $_res2
    local.get $_res2 ;; Option (0 = None, else Some payload)
    (if (result i32)
      (then
    local.get $_res2
    local.set $n
    i32.const 256
    local.get $n
    call $__str_concat
      )
      (else
    i32.const 0 ;; None — propagate absence
      )
    )
    local.set $_res1
    local.get $_res1 ;; Option (0 = None, else Some payload)
    (if (result i32)
      (then
    local.get $_res1
    local.set $n
    local.get $n
    call $shout
      )
      (else
    i32.const 0 ;; None — propagate absence
      )
    )
    local.set $_res0
    local.get $_res0 ;; Option (0 = None, else Some payload)
    (if (result i32)
      (then
    local.get $_res0 ;; Some — present value
      )
      (else
    i32.const 268
      )
    )
    return
  )
  (func $__str_concat (param $a i32) (param $b i32) (result i32)
    (local $base i32) (local $alen i32) (local $blen i32)
    local.get $a
    i32.load
    local.set $alen
    local.get $b
    i32.load
    local.set $blen
    global.get $__heap_ptr
    local.set $base
    ;; bump heap by 4 (length prefix) + alen + blen
    global.get $__heap_ptr
    i32.const 4
    local.get $alen
    i32.add
    local.get $blen
    i32.add
    i32.add
    global.set $__heap_ptr
    ;; store combined length prefix
    local.get $base
    local.get $alen
    local.get $blen
    i32.add
    i32.store
    ;; copy a's bytes: base+4 <- a+4
    local.get $base
    i32.const 4
    i32.add
    local.get $a
    i32.const 4
    i32.add
    local.get $alen
    memory.copy
    ;; copy b's bytes: base+4+alen <- b+4
    local.get $base
    i32.const 4
    i32.add
    local.get $alen
    i32.add
    local.get $b
    i32.const 4
    i32.add
    local.get $blen
    memory.copy
    local.get $base
  )
)
```

----- RUN LOG -----
```logs
```
