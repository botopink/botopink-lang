----- SOURCE
```botopink
val Status = type { Active, Inactive, fn label(self: Self) -> string { return "s"; } };
val s = Status.Active;
val n = s.label();
          ↑
```

----- COMPLETION at (line 2, char 10)
label  [Method]  detail: fn label(self: Self) -> string
