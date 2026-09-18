----- SOURCE CODE -- main.bp
```botopink
type Status { Ok, Fail }
#[@result]
fn check(s: Status) -> @Result<i32, string> {
    return case s {
        Ok -> 1;
        Fail -> throw "failed";
    };
}
fn main() {
    @print(check(Status.Ok).isOk());
    @print(check(Status.Fail).isOk());
}
```

----- JAVASCRIPT -- main.js
```javascript
function __bp_show(v, s, top, a) {
    if ((typeof v === "string")) {
        a.push(top ? v : (("\"" + Array.from(v, (c) => ((c === "\"") || (c === "\\")) ? ("\\" + c) : (c === "\n") ? "\\n" : (c === "\r") ? "\\r" : (c === "\t") ? "\\t" : c).join("")) + "\""));
        return "%s";
    }
    if (Array.isArray(v)) {
        const t = ((s != null) && (s[0] === "#"));
        return (((t ? "#(" : "[") + v.map((e, i) => __bp_show(e, (s == null) ? null : t ? s[i + 1] : s[1], false, a)).join(",")) + (t ? ")" : "]"));
    }
    a.push(v);
    return "%O";
}

function __bp_print() {
    const a = [];
    const f = Array.from(arguments, (v, i) => __bp_show(v, null, true, a)).join(" ");
    console.log.apply(console, [f, ...a]);
}

class Status {
}
Status.prototype.__bp = "Status";
class Status$Ok extends Status {
}
Status$Ok.prototype.tag = "Ok";
class Status$Fail extends Status {
}
Status$Fail.prototype.tag = "Fail";
Status.Ok = new Status$Ok();
Status.Fail = new Status$Fail();

function check(s) {
    {
        const _s = s;
        if (_s instanceof Status$Ok) return ({ ok: 1 });
        if (_s instanceof Status$Fail) return ({ error: "failed" });
    }
}

function main() {
    __bp_print(((_r) => !("error" in _r))(check(Status.Ok)));
    __bp_print(((_r) => !("error" in _r))(check(Status.Fail)));
}

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript





```

----- RUN LOG -----
```logs
true
false
```
