----- SOURCE CODE -- main.bp
```botopink
val HttpMethod = type {
    Get,
    Post,
    Put,
    Delete,
    fn name(m: Self) -> string {
        val label = case m {
            Get -> "GET";
            Post -> "POST";
            Put -> "PUT";
            _ -> "DELETE";
        };
        return label;
    }
}
```

----- JAVASCRIPT -- main.js
```javascript
class HttpMethod {
    static name(m) {
        const label = (() => {
            const _s = m;
            if (_s instanceof HttpMethod$Get) return "GET";
            if (_s instanceof HttpMethod$Post) return "POST";
            if (_s instanceof HttpMethod$Put) return "PUT";
            return "DELETE";
        })();
        return label;
    }
}
HttpMethod.prototype.__bp = "HttpMethod";
class HttpMethod$Get extends HttpMethod {
}
HttpMethod$Get.prototype.tag = "Get";
class HttpMethod$Post extends HttpMethod {
}
HttpMethod$Post.prototype.tag = "Post";
class HttpMethod$Put extends HttpMethod {
}
HttpMethod$Put.prototype.tag = "Put";
class HttpMethod$Delete extends HttpMethod {
}
HttpMethod$Delete.prototype.tag = "Delete";
HttpMethod.Get = new HttpMethod$Get();
HttpMethod.Post = new HttpMethod$Post();
HttpMethod.Put = new HttpMethod$Put();
HttpMethod.Delete = new HttpMethod$Delete();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
