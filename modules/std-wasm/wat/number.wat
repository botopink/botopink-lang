;; std-wasm's number leaves (front 164 s3): an integer's decimal text as the
;; codegen's `$str`, `(array (mut i8))` (decision 549: named, never declared).
;; Each is a `std:` cell's and the program's
;; (`#[@External.Wasm(std: "number.<function>")]`, called as
;; `$__std_number_<function>`); a print helper of a GC module writes the text
;; through `$__print_str_raw`.

;; `number.decimal` — the digits of `mag` read as an unsigned 64-bit value,
;; behind a `-` when `neg` is 1: the one body of the three leaves below. A
;; signed value's magnitude is taken by the caller as `0 - v`, which wraps
;; `i64::MIN` to 2^63, the right unsigned magnitude.
(func $number.decimal (param $mag i64) (param $neg i32) (result (ref null $str))
  (local $n i32)
  (local $i i32)
  (local $t i64)
  (local $out (ref null $str))
  ;; n = the digit count (at least one)
  local.get $mag
  local.set $t
  (block $counted
    (loop $count
      local.get $n
      i32.const 1
      i32.add
      local.set $n
      local.get $t
      i64.const 10
      i64.div_u
      local.tee $t
      i64.eqz
      br_if $counted
      br $count
    )
  )
  local.get $n
  local.get $neg
  i32.add
  local.tee $i
  array.new_default $str
  local.set $out
  ;; the digits, filled from the end
  local.get $mag
  local.set $t
  (block $filled
    (loop $fill
      local.get $i
      i32.const 1
      i32.sub
      local.set $i
      local.get $out
      local.get $i
      local.get $t
      i64.const 10
      i64.rem_u
      i32.wrap_i64
      i32.const 48
      i32.add
      array.set $str
      local.get $t
      i64.const 10
      i64.div_u
      local.tee $t
      i64.eqz
      br_if $filled
      br $fill
    )
  )
  local.get $neg
  (if
    (then
      local.get $out
      i32.const 0
      i32.const 45
      array.set $str
    )
  )
  local.get $out)

;; `number.i64ToString` — an `i64`'s decimal text.
(func $number.i64ToString (param $v i64) (result (ref null $str))
  local.get $v
  i64.const 0
  i64.lt_s
  (if (result (ref null $str))
    (then
      i64.const 0
      local.get $v
      i64.sub
      i32.const 1
      call $number.decimal
    )
    (else
      local.get $v
      i32.const 0
      call $number.decimal
    )
  ))

;; `number.i32ToString` — an `i32`'s decimal text.
(func $number.i32ToString (param $v i32) (result (ref null $str))
  local.get $v
  i64.extend_i32_s
  call $number.i64ToString)

;; `number.u64ToString` — the carrier's 64 bits read unsigned (decision 319).
(func $number.u64ToString (param $v i64) (result (ref null $str))
  local.get $v
  i32.const 0
  call $number.decimal)
