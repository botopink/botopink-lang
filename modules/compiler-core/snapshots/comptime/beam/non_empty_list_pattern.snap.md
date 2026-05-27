----- SOURCE CODE -- main.bp
```botopink
val first_or_default = fn(list: i32[], default: i32) -> i32 {
    case list {
        [first, ..] -> first;
        [] -> default;
    }
};
```

