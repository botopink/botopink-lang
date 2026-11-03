> Decisions 908, 812 (1): a child is resolved inside the body whose cell holds its contexts, and a child run outside
> that cell is not the model's child. `Parent` provides `dark` and returns `Tree(child: Reader())`. A plain function,
> outside `Parent`'s body, resolves that child over the scope `Parent` was handed. `Parent`'s provide wrote `Parent`'s
> own cell, never the one it was handed, so `Reader` reads the declared default (`light`).
