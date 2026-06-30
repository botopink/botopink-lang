----- SOURCE CODE -- main.bp
```botopink
record User { name: string }
enum AppError { NotFound, Timeout(msg: string) }
#[@result]
fn fetchUser(id: i32) -> @Result<User, AppError> {
    if (id == 0) { throw AppError.NotFound; };
    return User(name: "alice");
}
fn main() {
    val r = fetchUser(1);
    case r {
        Ok(u) -> @print(u.name);
        Err(NotFound) -> @print("404");
        Err(Timeout(msg)) -> @print("timeout: " + msg);
    };
}
```

