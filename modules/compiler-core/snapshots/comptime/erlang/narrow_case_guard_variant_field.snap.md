----- SOURCE CODE -- main.bp
```botopink
enum Response {
    Data(code: i32, body: string),
    Error(code: i32),
}
fn handle(r: Response) -> string {
    return case r {
        Data(code, body) if (code == 200) -> body;
        Data(code, body) if (code == 404) -> "not found";
        Error(code) -> "error " + code;
    };
}
```

