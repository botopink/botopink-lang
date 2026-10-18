----- SOURCE
```botopink
fn service(syntax decl: unknown) {
    @emit("val __wired = unresolvedRuntimeSymbol();");
}

#[service]
type PostService(name: string, count: i32)

val other = 1;
val usePost = PostService;
              ↑
```

----- COMPLETION at (line 8, char 14)
service  [Function]  detail: fn(__Decl) -> void
PostService  [Struct]  detail: type PostService(name: string, count: i32)
other  [Variable]  detail: i32
