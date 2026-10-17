----- SOURCE
```botopink
pub type User(id: i32, name: string);
fn fetchUser(id: i32) -> @Task<@Result<User, string>> {
   ↑
    if (id < 0) { throw "negative"; };
    return User(id: id, name: "ana");
}
```

----- HOVER at (line 1, char 3)
kind: markdown

```botopink
fn fetchUser(id: i32) -> @Task<@Result<User, string>>
```

---

`await` value type: `@Result<User, string>`
