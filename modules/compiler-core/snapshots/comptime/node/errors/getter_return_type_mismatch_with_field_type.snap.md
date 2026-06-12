----- SOURCE CODE
val Account = struct {
    balance: i32 = 0,
    get balance(self: Self) -> string {
        return "nope";
    }
};

----- ERROR
error: type mismatch

  expected: i32
  found:    string
