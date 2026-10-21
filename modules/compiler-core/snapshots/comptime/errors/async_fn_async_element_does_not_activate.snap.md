----- SOURCE CODE
val Element = type()
val Request = type(path: string)
component fn request() -> Component<Request> {
    return Request(path: "/");
}
fn Page() -> Async<Element> {
    val r = use request();
    return Element();
}

----- ERROR
error: use-without-component: `use` needs a body marked `component`
  ┌─ main.bp:7:13
  │
7 │     val r = use request();
  │             ^

  fn 'Page' returns 'Async<Element>' and carries no `component` marker,
  and only a `component fn` body activates a hook: write `component fn` (decisions 553, 573)
