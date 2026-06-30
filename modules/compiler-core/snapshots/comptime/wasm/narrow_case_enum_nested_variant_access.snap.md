----- SOURCE CODE -- main.bp
```botopink
enum Result_ { OkData(val: record { code: i32, msg: string }), Fail }
fn describe(r: Result_) -> string {
    return case r {
        OkData(d) -> d.msg;
        Fail -> "failed";
    };
}
```

