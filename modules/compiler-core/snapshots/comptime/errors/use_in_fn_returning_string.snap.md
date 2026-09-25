----- SOURCE CODE
val Element = type implement @Context<Element> { }
#[@use]
fn state(initial: i32) -> @Component<Element, i32> {
    initial;
}
fn bad() -> string {
    val x = use state(0);
    "hi";
}

----- ERROR
error: use-without-context-effect: `use` needs `#[@use]` on the enclosing fn
  ┌─ :7:13
  │
7 │     val x = use state(0);
  │             ^

  fn 'bad' returns 'string',
  but only a `#[@use]` body activates a hook (decision 104)
