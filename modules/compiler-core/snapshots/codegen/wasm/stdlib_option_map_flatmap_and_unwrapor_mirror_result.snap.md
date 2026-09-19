----- SOURCE CODE -- main.bp
```botopink
type Person(name: string)
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
    call $__i32_to_str
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
    i32.load ;; optional payload
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
  (func $__alloc (param $n i32) (result i32)
    (local $p i32)
    global.get $__heap_ptr
    local.set $p
    global.get $__heap_ptr
    local.get $n
    i32.add
    i32.const 3
    i32.add
    i32.const -4
    i32.and
    global.set $__heap_ptr
    local.get $p
  )
  (func $__i32_to_str (param $n i32) (result i32)
    (local $u i64) (local $pos i32) (local $len i32) (local $p i32) (local $neg i32)
    i32.const 160
    local.set $pos
    local.get $n
    i32.const 0
    i32.lt_s
    local.set $neg
    local.get $n
    i64.extend_i32_s
    local.set $u
    local.get $neg
    (if
      (then
        i64.const 0
        local.get $u
        i64.sub
        local.set $u
      )
    )
    (block $brk
      (loop $cont
        local.get $pos
        i32.const 1
        i32.sub
        local.set $pos
        local.get $pos
        local.get $u
        i64.const 10
        i64.rem_u
        i32.wrap_i64
        i32.const 48
        i32.add
        i32.store8
        local.get $u
        i64.const 10
        i64.div_u
        local.set $u
        local.get $u
        i64.eqz
        br_if $brk
        br $cont
      )
    )
    local.get $neg
    (if
      (then
        local.get $pos
        i32.const 1
        i32.sub
        local.set $pos
        local.get $pos
        i32.const 45
        i32.store8
      )
    )
    i32.const 160
    local.get $pos
    i32.sub
    local.set $len
    local.get $len
    i32.const 4
    i32.add
    call $__alloc
    local.set $p
    local.get $p
    local.get $len
    i32.store
    local.get $p
    i32.const 4
    i32.add
    local.get $pos
    local.get $len
    memory.copy
    local.get $p
  )
)
```

----- RUN LOG -----
```logs
```
