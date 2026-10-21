;; std-wasm's `io/random` leaves (front 164 s3 P2-e, decision 585 (i), (j)): the
;; seeded stream and the host's entropy. Each function is a `std:` cell's
;; (`#[@External.Wasm(std: "random.<function>")]` in `libs/std/src/io/random.bp`)
;; and the program calls it as `$__std_random_<function>`.
;;
;; The stream's state is `$__random_state`, a mutable `i64` global the codegen
;; declares in `wat_prelude` (a leaf names it, as it names a type: 549, 585 (i)):
;; the Mulberry32 word held in the low 32 bits, `-1` before any `seed`. The
;; host's entropy is `$__wasi_random_f64`, the prelude's own function, named
;; without being declared (585 (j)).

;; `random.float` — an unseeded draw in `[0.0, 1.0)`: the host's entropy.
(func $random.float (result f64)
  call $__wasi_random_f64)

;; `random.seed` — the stream restarts from the bits of `s`.
(func $random.seed (param $s i32)
  local.get $s
  i64.extend_i32_u
  global.set $__random_state)

;; `random.seededFloat` — the stream's next draw in `[0.0, 1.0)`, or the host's
;; before any `seed`. Mulberry32, as the commonJS sidecar draws it: the state
;; steps by 0x6D2B79F5 and its bits are mixed to a word, read unsigned and
;; scaled by 2^-32 — the same `seed` gives the same draws on every target that
;; has the stream.
(func $random.seededFloat (result f64)
  (local $s i32)
  (local $t i32)
  global.get $__random_state
  i64.const 0
  i64.lt_s
  (if
    (then
      call $__wasi_random_f64
      return
    )
  )
  ;; s = state + 0x6D2B79F5, kept as the new state
  global.get $__random_state
  i32.wrap_i64
  i32.const 0x6D2B79F5
  i32.add
  local.tee $s
  i64.extend_i32_u
  global.set $__random_state
  ;; t = (s ^ (s >> 15)) * (s | 1)
  local.get $s
  local.get $s
  i32.const 15
  i32.shr_u
  i32.xor
  local.get $s
  i32.const 1
  i32.or
  i32.mul
  local.set $t
  ;; t = t ^ (t + (t ^ (t >> 7)) * (t | 61))
  local.get $t
  local.get $t
  local.get $t
  i32.const 7
  i32.shr_u
  i32.xor
  local.get $t
  i32.const 61
  i32.or
  i32.mul
  i32.add
  local.get $t
  i32.xor
  local.set $t
  ;; (t ^ (t >> 14)) / 2^32
  local.get $t
  local.get $t
  i32.const 14
  i32.shr_u
  i32.xor
  f64.convert_i32_u
  f64.const 4294967296.0
  f64.div)
