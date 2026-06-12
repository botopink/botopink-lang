----- SOURCE CODE
record Box<A, B> { first: A, second: B }

fn main() {
    val b = Box(first: 1, second: "one");
    val bad: i32 = b.second;
}

----- ERROR
error: type mismatch
  ┌─ :5:22
  │
5 │     val bad: i32 = b.second;
  │                      ^

  expected: i32
  found:    string
