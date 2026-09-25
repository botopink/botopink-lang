----- SOURCE CODE
val Element = type implement @Context<Element> { }
val Request = type(path: string)
#[@use]
fn request() -> @Use<Element, Request> {
    Request(path: "/");
}
#[@future]
fn Page() -> @Future<Element> {
    val r = use request();
    return Element();
}

----- ERROR
error: use-without-context-effect: `use` needs `#[@use]` on the enclosing fn
  ┌─ :9:13
  │
9 │     val r = use request();
  │             ^

  fn 'Page' returns '@Future<Element>',
  but only a `#[@use]` body activates a hook (decision 104)
