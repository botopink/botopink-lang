----- SOURCE CODE -- main.bp
```botopink
pub fn shout(comptime q: @Expr<string>) -> @Expr<string> {
    val t = q.text().trim();
    val words = t.split(" ").map({ w -> w.toUpper() });
    val lead = t.slice(0, 5);
    val rest = t.slice(6, t.length);
    val all = words.append(["END"]).reverse();
    val at = if (words.at(1) == "BIG") { "at"; } else { "-"; };
    val big = if (t.contains("big")) { "contains"; } else { "-"; };
    val greet = if (lead.startsWith("hel")) { "startsWith"; } else { "-"; };
    val where = if (words.indexOf("WORLD") == 2) { "indexOf"; } else { "-"; };
    return q.build("\"" + all.join(",") + "|" + lead + "|" + rest + "|" + at + "|" + big + "|" + greet + "|" + where + "\"");
}

val s = shout " hello big world ";

fn main() {
    @print(s);
}
```

----- COMPTIME ERLANG -- template shout
```erlang
shout(Q) ->
    T = '__bp_prim_trim'(text(Q)),
    Words = '__bp_prim_map'('__bp_prim_split'(T, <<" ">>), fun(W) ->
        '__bp_prim_toUpper'(W)
    end),
    Lead = '__bp_prim_slice'(T, 0, 5),
    Rest = '__bp_prim_slice'(T, 6, '__bp_len'(T, length)),
    All = '__bp_prim_reverse'('__bp_prim_append'(Words, [<<"END">>])),
    At = case ('__bp_prim_at'(Words, 1) =:= <<"BIG">>) of
        true ->
            <<"at">>;
        false ->
            <<"-">>
    end,
    Big = case '__bp_prim_contains'(T, <<"big">>) of
        true ->
            <<"contains">>;
        false ->
            <<"-">>
    end,
    Greet = case '__bp_prim_startsWith'(Lead, <<"hel">>) of
        true ->
            <<"startsWith">>;
        false ->
            <<"-">>
    end,
    Where = case ('__bp_prim_indexOf'(Words, <<"WORLD">>) =:= 2) of
        true ->
            <<"indexOf">>;
        false ->
            <<"-">>
    end,
    build(Q, '__bp_add'('__bp_add'('__bp_add'('__bp_add'('__bp_add'('__bp_add'('__bp_add'('__bp_add'('__bp_add'('__bp_add'('__bp_add'('__bp_add'('__bp_add'('__bp_add'(<<"\"">>, '__bp_prim_join'(All, <<",">>)), <<"|">>), Lead), <<"|">>), Rest), <<"|">>), At), <<"|">>), Big), <<"|">>), Greet), <<"|">>), Where), <<"\"">>)).

main({Arg0}) ->
    try
        json:encode('__bp_reply'(shout(Arg0)))
    catch
        throw:{'__bp_template_fail', Message, Param, Span} ->
            json:encode(#{kind => <<"fail">>, message => '__bp_text'(Message), param => Param, span => '__bp_json'(Span)});
        Class:Reason ->
            json:encode(#{kind => <<"error">>, message => '__bp_text'({Class, Reason})})
    end.

%% main/1 argument — an external term, not part of the module:
%% Arg0 = #{
%%     '__bp_capture' => <<"q">>,
%%     text => <<" hello big world ">>,
%%     parts => [
%%         #{
%%             kind => <<"Text">>,
%%             text => <<" hello big world ">>,
%%             span => #{start => 0, 'end' => 17, line => 1}
%%         }
%%     ],
%%     source => #{file => <<"">>, line => 14, col => 15},
%%     context => #{
%%         source => #{file => <<"">>, line => 14, col => 15},
%%         text => <<" hello big world ">>,
%%         multiline => false
%%     },
%%     bindings => [
%%         #{name => <<"shout">>, kind => 'Fn'},
%%         #{name => <<"s">>, kind => 'Val'},
%%         #{name => <<"main">>, kind => 'Fn'}
%%     ]
%% }
```

----- COMPTIME REPLY -- template shout
```json
{
  "source": "\"END,WORLD,BIG,HELLO|hello|big world|at|contains|startsWith|indexOf\"",
  "kind": "code"
}
```

----- JAVASCRIPT -- main.js
```javascript
function __bp_show(v, s, top, a) {
    if ((typeof v === "string")) {
        a.push(top ? v : (("\"" + Array.from(v, (c) => ((c === "\"") || (c === "\\")) ? ("\\" + c) : (c === "\n") ? "\\n" : (c === "\r") ? "\\r" : (c === "\t") ? "\\t" : c).join("")) + "\""));
        return "%s";
    }
    if (((typeof v === "number") && (s === "f"))) {
        a.push(Number.isInteger(v) ? v.toFixed(1) : String(v));
        return "%s";
    }
    if (Array.isArray(v)) {
        const t = ((s != null) && (s[0] === "#"));
        return (((t ? "#(" : "[") + v.map((e, i) => __bp_show(e, (s == null) ? null : t ? s[i + 1] : s[1], false, a)).join(", ")) + (t ? ")" : "]"));
    }
    if (((v != null) && (typeof v.__bp === "string"))) {
        if ((typeof v.display === "function")) {
            a.push(v.display());
            return "%s";
        }
        const k = Object.keys(v);
        return (((typeof v.tag === "string") ? ((v.__bp + ".") + v.tag) : v.__bp) + ((k.length === 0) ? "" : (("(" + k.map((n) => ((n + ": ") + __bp_show(v[n], null, false, a))).join(", ")) + ")")));
    }
    a.push(v);
    return "%O";
}

function __bp_print() {
    const a = [];
    const f = Array.from(arguments, (v, i) => __bp_show(v, null, true, a)).join(" ");
    console.log.apply(console, [f, ...a]);
}

// behavior String
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
//   fn at(...)
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
    if ((end != null)) { return ((__s, __a, __e) => { const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); const __f = __e < 0 ? Math.max(__n + __e, 0) : Math.min(__e, __n); return __s.substring(__b, Math.max(__b, __f)); })(self, start, end); } else { return ((__s, __a) => { const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); return __s.substring(__b); })(self, start); }
};
String.prototype.chars = function() { return (Array.from(this.valueOf())); };
String.prototype.lines = function() { return this.valueOf().split(/\r?\n/); };
String.prototype.words = function() { return this.valueOf().split(/[ \t\n\r]+/).filter(__w => __w.length > 0); };
String.prototype.charCodeAt = function(index) { return ((this.valueOf().charCodeAt(index) ?? -1) | 0); };

// behavior Array
//   length: i32
//   fn at(...)
//   fn push(...)
//   fn pop(...)
//   default fn slice(...)
//   fn join(...)
//   fn reverse(...)
//   fn indexOf(...)
//   fn forEach(...)
//   fn map(...)
//   fn filter(...)
//   fn zip(...)
//   default fn range(...)
//   default fn repeat(...)
//   default fn isEmpty(...)
//   default fn contains(...)
//   default fn first(...)
//   default fn rest(...)
//   default fn take(...)
//   default fn drop(...)
//   default fn fold(...)
//   default fn find(...)
//   default fn count(...)
//   default fn all(...)
//   default fn any(...)
//   default fn append(...)
//   default fn prepend(...)
//   default fn flatten(...)
//   default fn flatMap(...)
//   default fn toList(...)
//   default fn some(...)
//   default fn every(...)
//   default fn flat(...)
//   default fn findIndex(...)
//   default fn fill(...)
//   default fn chunked(...)
//   default fn sliding(...)
//   default fn unique(...)
Array.range = function(start, stop) {
    return (() => { if ((start >= stop)) { return []; } else { const head = start; return [head, ...(Array.range((start + 1), stop))]; } })();
};
Array.repeat = function(value, times) {
    return (() => { if ((times <= 0)) { return []; } else { const head = value; return [head, ...(Array.repeat(value, (times - 1)))]; } })();
};
Array.prototype.slice = function(start, end) {
    if ((end != null)) { return ((__xs, __a, __e) => { const __n = __xs.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); const __f = __e < 0 ? Math.max(__n + __e, 0) : Math.min(__e, __n); return Array.from({ length: Math.max(__f - __b, 0) }, (_, __i) => __xs[__b + __i]); })(this, start, end); } else { return ((__xs, __a) => { const __n = __xs.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); return Array.from({ length: __n - __b }, (_, __i) => __xs[__b + __i]); })(this, start); }
};
Array.prototype.zip = function(other) { return this.map((__x, __i) => [__x, (other)[__i]]).slice(0, Math.min(this.length, (other).length)); };
Array.prototype.isEmpty = function() {
    return (this.length === 0);
};
Array.prototype.contains = function(x) {
    return (this.indexOf(x) !== (-1));
};
Array.prototype.first = function() {
    return this.at(0);
};
Array.prototype.rest = function() {
    return this.slice(1, this.length);
};
Array.prototype.take = function(n) {
    return this.slice(0, n);
};
Array.prototype.drop = function(n) {
    return this.slice(n, this.length);
};
Array.prototype.fold = function(initial, f) {
    let acc = initial;
    this.forEach((x) => {
    acc = f(acc, x);
});
    return acc;
};
Array.prototype.count = function(pred) {
    return this.filter(pred).length;
};
Array.prototype.all = function(pred) {
    return (this.filter(pred).length === this.length);
};
Array.prototype.any = function(pred) {
    return (this.filter(pred).length !== 0);
};
Array.prototype.prepend = function(item) {
    let out = [item];
    this.forEach((x) => {
    return out.push(x);
});
    return out;
};
Array.prototype.flatten = function() {
    let out = [];
    this.forEach((inner) => {
    out = out.concat(inner);
});
    return out;
};
Array.prototype.toList = function() {
    return this;
};
Array.prototype.some = function(pred) {
    return this.any(pred);
};
Array.prototype.every = function(pred) {
    return this.all(pred);
};
Array.prototype.flat = function() {
    return this.flatten();
};
Array.prototype.findIndex = function(pred) {
    let out = (-1);
    let i = 0;
    this.forEach((x) => {
    (() => { if ((out === (-1))) { return (() => { if (pred(x)) { return out = i; } })(); } })();
    i = (i + 1);
});
    return out;
};
Array.prototype.fill = function(value) {
    return Array.repeat(value, this.length);
};
Array.prototype.chunked = function(n) {
    let out = [];
    if ((n <= 0)) { return out; }
    const len = this.length;
    for (const k of Array.from({length: Math.max(0, (len) - (0))}, (_, __i) => (0) + __i)) {
    (() => { if (((k % n) === 0)) { return out = out.concat([this.slice(k, (k + n))]); } })();
}
    return out;
};
Array.prototype.sliding = function(n) {
    let out = [];
    if ((n <= 0)) { return out; }
    const windows = ((this.length - n) + 1);
    if ((windows <= 0)) { return out; }
    for (const k of Array.from({length: Math.max(0, (windows) - (0))}, (_, __i) => (0) + __i)) {
    out = out.concat([this.slice(k, (k + n))]);
}
    return out;
};
Array.prototype.unique = function() {
    let out = [];
    let seenLast = false;
    let prev = this.at(0);
    this.forEach((x) => {
    (() => { if (seenLast) { return (() => { if ((prev.unwrapOr(x) !== x)) { out = out.concat([x]); return prev = this.at(out.length); } })(); } else { out = out.concat([x]); seenLast = true; return prev = this.at(0); } })();
});
    return out;
};

const s = "END,WORLD,BIG,HELLO|hello|big world|at|contains|startsWith|indexOf";

function main() {
    __bp_print(s);
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
END,WORLD,BIG,HELLO|hello|big world|at|contains|startsWith|indexOf
```
