----- SOURCE CODE -- main.bp
```botopink
record User { name: string }
fn greet(maybeUser: ?User) -> string {
    if (maybeUser) { u ->
        return "hello " + u.name;
    };
    return "no user";
}
@print(greet(User(name: "alice")));
```

