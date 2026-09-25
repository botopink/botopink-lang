----- SOURCE CODE
fn parse(n: i32) -> @Result<i32, string> {
    val r = Result.Ok(result: n);
    return n;
}

----- ERROR
error: result-manual-construction-forbidden: in a body whose return carries a `@Result`, the variants are constructed by `return` / `throw` alone.
  ┌─ :2:20
  │
2 │     val r = Result.Ok(result: n);
  │                    ^

  hint: Replace the manual `Result.Ok(...)` / `Result.Error(...)` with the implicit form (`return <r>;` / `throw <e>;`), or move the construction outside this body.
