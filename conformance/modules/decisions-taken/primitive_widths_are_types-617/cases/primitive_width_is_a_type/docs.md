# primitive_width_is_a_type

Decision 617 (1): the primitive widths are types. Std's prelude declares `pub type i32 implement Signed`, `i64`
likewise, `u32` and `u64` `implement Integer`, `f32` and `f64` `implement Float`; the six empty behaviors (`I32`, …) are
gone. A method on a width is found through its `implement` clause and the contracts' `extends` (`Signed extends Integer
extends Number`, `Float extends Number`), read from the text by the checker and by every backend. `i64` and `u32` stand in type positions (an array's element, a parameter); `abs` answers on `i32` (`Signed`), `isEven`,
`isOdd` and `toString` on `i32` (`Integer`, through `Signed extends Integer`), `floor` on `f64` (`Float`), `min` and
`clamp` on `i32` and `f64` alike (`Number`). The answers are the ones the behaviors gave: only where the chain is written changed. A module declaring a
width is refused (`primitive_width_redeclared_refused`).
