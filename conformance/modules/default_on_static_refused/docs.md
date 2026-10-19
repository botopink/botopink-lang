# default_on_static_refused

Decision 628: `default` is the mark of an instance member with an overridable body, its first parameter `self`. On a
behavior member without `self` — a static — it is refused at the modifier, `default-on-static` (`a member without self is
a static: write fn`); the static is written `fn unit() -> i32 { … }` (`behavior_static_written_fn`). It used to be the
only spelling of a behavior's static with a body.
