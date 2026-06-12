----- SOURCE CODE -- main.bp
```botopink
pub fn compute(x: i32) -> i32 {
    val doubled = x + x;
    @print(doubled);
    return doubled;
}
val result = compute(21);
@print(result);
```

