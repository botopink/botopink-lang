----- SOURCE CODE
pub fn bad(expr q: string) -> i32 {
    return "not an int";
}
val d = bad @`x`;

----- ERROR
error: template-build-outside-bound: `bad` built code of type `string`, outside its answer `i32`
  ┌─ main.bp:4:9
  │
4 │ val d = bad @`x`;
  │         ^

  hint: A template's answer is a bound its built code fits (decision 426 (2)): build code of that type, or widen the answer.
