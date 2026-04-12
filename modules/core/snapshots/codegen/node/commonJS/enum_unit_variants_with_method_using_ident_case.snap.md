----- SOURCE CODE -- main.bp
```botopink
val HttpMethod = enum {
    Get,
    Post,
    Put,
    Delete,
    fn name(m: Self) -> string {
        val label = case m {
            Get -> "GET";
            Post -> "POST";
            Put -> "PUT";
            else -> "DELETE";
        };
        return label;
    }
}
```

----- JAVASCRIPT -- main.js
```javascript
const HttpMethod = Object.freeze({
    Get: "Get",
    Post: "Post",
    Put: "Put",
    Delete: "Delete",
    name: function(m) {
        const label = (() => {
            const _s = m;
            if (_s === "Get") return "GET";
            if (_s === "Post") return "POST";
            if (_s === "Put") return "PUT";
            return "DELETE";
        })();
        return label;
    },
});
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
