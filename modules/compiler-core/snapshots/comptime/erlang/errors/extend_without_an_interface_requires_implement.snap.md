----- SOURCE CODE
record Pato { id: i32 }
val PatoVoa = extend Pato {
    fn fly(self: Self) {
        return self.id;
    }
}

----- ERROR
error: extend requires an interface

  `extend Pato` adds methods without a contract
  hint: use `implement <Interface> for Pato` so the methods satisfy an interface
