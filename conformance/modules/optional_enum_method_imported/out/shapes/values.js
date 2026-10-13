function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what); }

class Val {
    static Num(n) {
        return new Val$Num(n);
    }

    static Text(s) {
        return new Val$Text(s);
    }

    static str(self) {
        return (() => {
            const _s = self;
            if (_s.tag === "Text") {
                const { s: t } = _s;
                return t;
            }
            return "";
        })();
    }

    static plus(self, k) {
        return (() => {
            const _s = self;
            if (_s.tag === "Num") {
                const { n: v } = _s;
                return __bp_int((v + k), -2147483648, 2147483647, "+ on i32 at src/values.bp:14:28");
            }
            return k;
        })();
    }
}
Val.prototype.__bp = "Val";
class Val$Num extends Val {
    constructor(n) {
        super();
        this.n = n;
    }
}
Val$Num.prototype.tag = "Num";
class Val$Text extends Val {
    constructor(s) {
        super();
        this.s = s;
    }
}
Val$Text.prototype.tag = "Text";
exports.Val = Val;

function find(kind) {
    if ((kind === 1)) { return Val.Text("a"); }
    if ((kind === 2)) { return Val.Num(40); }
    return null;
}
exports.find = find;

Object.defineProperty(exports, "__bp_priv__", { value: { Val, Val$Num, Val$Text, find } });
