----- SOURCE CODE -- main.bp
```botopink
fn first3() -> string {
    val s = "hello";
    return s.slice(0, 3);
}
```

----- JAVASCRIPT -- main.js
```javascript
// interface String
//   fn length(...)
//   fn split(...)
//   fn toUpper(...)
//   fn toLower(...)
//   fn contains(...)
//   fn startsWith(...)
//   fn endsWith(...)
//   fn trim(...)
//   fn trimStart(...)
//   fn trimEnd(...)
//   fn replace(...)
//   default fn slice(...)
//   fn charAt(...)
//   fn indexOf(...)
//   default fn toString(...)
//   fn padStart(...)
//   fn padEnd(...)
//   fn repeat(...)
//   fn replaceAll(...)
//   fn chars(...)
//   fn lines(...)
//   fn words(...)
//   fn charCodeAt(...)
//   fn lastIndexOf(...)
String.prototype.slice = function(start, end) {
    const self = this.valueOf();
     if (end) { return require("./gleam_stdlib.mjs").string_slice(self, start, end); } else { return require("./gleam_stdlib.mjs").string_slice(self, start); };
};
String.prototype.chars = function() { return (Array.from(this.valueOf())); };
String.prototype.lines = function() { return this.valueOf().split(/\\r?\\n/); };
String.prototype.words = function() { return this.valueOf().split(/\\s+/).filter(__w => __w.length > 0); };
String.prototype.charCodeAt = function(index) { return ((this.valueOf().charCodeAt(index) ?? -1) | 0); };

function first3() {
    const s = "hello";
    return s.slice(0, 3);
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
