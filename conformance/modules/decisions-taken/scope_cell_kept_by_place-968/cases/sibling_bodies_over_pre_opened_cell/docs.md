> Decisions 966 (5), 968 (2)/(3), 812 (1): each body opens its own cell, a child of the cell it is handed, and takes
> that cell's contexts anew. A `use provide` writes the body's own cell, so it reaches that body's subtree alone.
> `Provider` and `Reader` are resolved one after the other over one cell opened outside any body
> (`root.childAt(…)`), so they are siblings. `Reader` reads the declared default (`light`), never `Provider`'s `dark`.
