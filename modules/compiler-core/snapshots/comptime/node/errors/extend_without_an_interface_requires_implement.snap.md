----- SOURCE CODE
type Pato(id: i32)
val PatoVoa = extend Pato {
    fn fly(self: Self) {
        return self.id;
    }
}

----- ERROR
error: extend requires a behavior

  `extend Pato` adds methods without a contract
  hint: use `implement <Behavior> for Pato` so the methods satisfy a behavior
