----- SOURCE CODE
val Element = type() implement @Context<Element>
val Request = type(path: string)
fn request() -> @Component<Element, Request> {
    Request(path: "/");
}
fn Page() -> @Task<Element> {
    val r = use request();
    return Element();
}

----- ERROR
error: use-without-context-effect: `use` needs a `-> @Component<C, T>` return on the enclosing fn
  ┌─ main.bp:7:13
  │
7 │     val r = use request();
  │             ^

  fn 'Page' returns '@Task<Element>',
  but only a `-> @Component<C, T>` body activates a hook (decisions 104, 118)
