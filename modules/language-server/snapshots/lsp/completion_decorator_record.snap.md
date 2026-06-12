----- SOURCE
```botopink
fn service(comptime decl: @Decl) {
    @emit("val __wired = unresolvedRuntimeSymbol();");
}

#[service]
record PostService { name: string, count: i32 }

val usePost = PostService;
              ↑
```

----- COMPLETION at (line 7, char 14)
service  [Function]  detail: fn(Decl) -> void
PostService  [Struct]  detail: record { name: string, count: i32 }
