----- SOURCE CODE -- std/order.bp
```botopink
//// Gleam-style `order` module, inspired by `gleam/order`. A sum type — the
//// `type Order` (type-exported to importers) plus companion functions.
//// Construct via the module fns (`order.lt()`); `toInt`/`reverse` operate on
//// an `Order`. Enums are concrete types, not interfaces.

pub type Order {
    Lt,
    Eq,
    Gt,
}

pub fn lt() -> Order {
    return Order.Lt;
}

pub fn eq() -> Order {
    return Order.Eq;
}

pub fn gt() -> Order {
    return Order.Gt;
}

pub fn toInt(o: Order) -> i32 {
    val n = case o {
        Lt -> -1;
        Eq -> 0;
        _ -> 1;
    };
    return n;
}

pub fn reverse(o: Order) -> Order {
    val r = case o {
        Lt -> Order.Gt;
        Gt -> Order.Lt;
        _ -> Order.Eq;
    };
    return r;
}

test "order toInt" {
    assert toInt(lt()) == -1;
    assert toInt(eq()) == 0;
    assert toInt(gt()) == 1;
}

test "order reverse" {
    assert toInt(reverse(lt())) == 1;
    assert toInt(reverse(gt())) == -1;
    assert toInt(reverse(eq())) == 0;
}

test "order case over Order" {
    val o = reverse(lt());
    val s = case o {
        Lt -> "less";
        Gt -> "greater";
        _ -> "equal";
    };
    assert s == "greater";
}

```

----- JAVASCRIPT -- std/order.js
```javascript
//// Gleam-style `order` module, inspired by `gleam/order`. A sum type — the

//// `type Order` (type-exported to importers) plus companion functions.

//// Construct via the module fns (`order.lt()`); `toInt`/`reverse` operate on

//// an `Order`. Enums are concrete types, not interfaces.

class Order {
}
Order.prototype.__bp = "Order";
class Order$Lt extends Order {
}
Order$Lt.prototype.tag = "Lt";
class Order$Eq extends Order {
}
Order$Eq.prototype.tag = "Eq";
class Order$Gt extends Order {
}
Order$Gt.prototype.tag = "Gt";
Order.Lt = new Order$Lt();
Order.Eq = new Order$Eq();
Order.Gt = new Order$Gt();
exports.Order = Order;

function lt() {
    return Order.Lt;
}
exports.lt = lt;

function eq() {
    return Order.Eq;
}
exports.eq = eq;

function gt() {
    return Order.Gt;
}
exports.gt = gt;

function toInt(o) {
    const n = (() => {
        const _s = o;
        if (_s instanceof Order$Lt) return (-1);
        if (_s instanceof Order$Eq) return 0;
        return 1;
    })();
    return n;
}
exports.toInt = toInt;

function reverse(o) {
    const r = (() => {
        const _s = o;
        if (_s instanceof Order$Lt) return Order.Gt;
        if (_s instanceof Order$Gt) return Order.Lt;
        return Order.Eq;
    })();
    return r;
}
exports.reverse = reverse;
```

----- TYPESCRIPT TYPEDEF -- std/order.d.ts
```typescript
export declare class Order {
    readonly tag: "Lt" | "Eq" | "Gt";
    static readonly Lt: Order;
    static readonly Eq: Order;
    static readonly Gt: Order;
}


export declare function lt(): Order;


export declare function eq(): Order;


export declare function gt(): Order;


export declare function toInt(o: Order): number;


export declare function reverse(o: Order): Order;

```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {order} from "std";

fn describe(o: Order) -> string {
    val s = case o {
        Lt -> "less";
        Gt -> "greater";
        _ -> "equal";
    };
    return s;
}

fn main() {
    @print(order.toInt(order.lt()));
    @print(describe(order.reverse(order.lt())));
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

const order = require("./std/order.js");

function describe(o) {
    const s = (() => {
        const _s = o;
        if (_s.tag === "Lt") return "less";
        if (_s.tag === "Gt") return "greater";
        return "equal";
    })();
    return s;
}

function main() {
    __bp_print(order.toInt(order.lt()));
    __bp_print(describe(order.reverse(order.lt())));
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
-1
greater
```
