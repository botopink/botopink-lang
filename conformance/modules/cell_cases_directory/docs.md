> Decision 765 — a module may hold several cells: `<module>/cases/<case>/` is
> a full cell (its own `botopink.json`, `src/main.bp`, `snapshot/` and
> `docs.md`), and the module holds `docs.md` beside `cases/` and no `src/`.
> `botopink cell check` over the module checks every case; this module holds a
> printing case and a refused one.

[cases/prints/src/main.bp](cases/prints/src/main.bp)
[cases/refused/src/main.bp](cases/refused/src/main.bp)
