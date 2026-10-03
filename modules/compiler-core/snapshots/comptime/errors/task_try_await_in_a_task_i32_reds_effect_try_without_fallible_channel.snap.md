----- SOURCE CODE
fn fetchUser() -> @Task<@Result<i32, string>> {
    return 1;
}
fn count() -> @Task<i32> {
    val n = try await fetchUser();
    return n;
}

----- ERROR
error: effect-try-without-fallible-channel: `try` needs a `@Result` in some layer of the return — this fn returns `@Task<…>` with no `@Result` in it
  ┌─ main.bp:5:13
  │
5 │     val n = try await fetchUser();
  │             ^

  hint: Use `try <expr> catch <fallback>`, which handles the error here and needs no channel, or put a `@Result` in the return.
