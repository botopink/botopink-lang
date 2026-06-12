----- SOURCE
```botopink
import { Response, created } from "rakun";
fn make(r: Response) -> Response {
    return Response.created(r, "hi");
                     ↑
}
```

----- DEFINITION at (line 2, char 21)
uri: file:///libs/rakun/http.bp
range: (1,7) → (1,14)
  fn make(r: Response) -> Response {
         ^^^^^^^
