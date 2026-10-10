----- SOURCE CODE
fn parse(s: string) -> @Result<i32, string> {
    return 1;
}
fn run() -> @Task<void> {
    val t = async {
        val n = try parse("7");
        return n + 1;
    };
    val v: i32 = await t;
}

----- ERROR
error: type mismatch
  ┌─ main.bp:9:18
  │
9 │     val v: i32 = await t;
  │                  ^

  expected: i32
  found:    Result<i32,string>
  hint: `await` answers the `@Result` the Task holds: write `try await t` to propagate its error, or handle it with `case` / `catch`; it is a `@Result` because of the `try` at 6:17 in its own block
