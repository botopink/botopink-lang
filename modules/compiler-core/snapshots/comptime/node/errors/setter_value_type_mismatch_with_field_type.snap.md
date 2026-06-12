----- SOURCE CODE
val Account = struct {
    balance: i32 = 0,
    set balance(self: Self, value: string) {
        self.balance = value;
    }
};

----- ERROR
error: type mismatch

  expected: i32
  found:    string
