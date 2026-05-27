----- SOURCE CODE -- main.bp
```botopink
val Option = enum <T> {
    Some(value: T),
    None,
};
val map = fn(opt: Option<i32>, f: fn(i32) -> i32) -> Option<i32> {
    case opt {
        Some(v) -> Some(value: f(v));
        None -> None;
    };
};
```

