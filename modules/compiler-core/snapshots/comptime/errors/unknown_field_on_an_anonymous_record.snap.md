----- SOURCE CODE
val port = 8080;
val cfg = #(port);
val x = cfg.prot;

----- ERROR
error: this tuple has no element labeled `prot`
  ┌─ main.bp:3:13
  │
3 │ val x = cfg.prot;
  │             ^

  hint: labels come from the tuple's written type or from the variables it was built from; use the position instead: `._0`, `._1`, …
