const __bp_surrogate = /[\uD800-\uDFFF]/;
const __bp_surrogate_k = new Array(64).fill("");
const __bp_surrogate_v = new Array(64).fill(false);
const __bp_surrogate_k2 = new Array(64).fill("");
const __bp_surrogate_v2 = new Array(64).fill(false);
function __bp_has_surrogate(s) {
    const h = s.length & 63;
    if (__bp_surrogate_k[h] === s) { return __bp_surrogate_v[h]; }
    if (__bp_surrogate_k2[h] === s) { return __bp_surrogate_v2[h]; }
    const p = __bp_surrogate.test(s);
    __bp_surrogate_k2[h] = __bp_surrogate_k[h];
    __bp_surrogate_v2[h] = __bp_surrogate_v[h];
    __bp_surrogate_k[h] = s;
    __bp_surrogate_v[h] = p;
    return p;
}

function __bp_str_length(s) {
    if (!__bp_has_surrogate(s)) { return s.length; }
    let n = 0;
    for (const c of s) { n += 1; }
    return n;
}

function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what); }

class Props {
    constructor(title) {
        this.title = title;
    }
}
Props.prototype.__bp = "Props";
exports.Props = Props;

function twice(x) {
    return __bp_int((x * 2), -2147483648, 2147483647, "* on i32 at src/components/Card.bpp:4:14");
}
exports.twice = twice;

function default_(props) {
    const size = __bp_str_length(props.title);
    const label = (() => { if ((size > 1)) { return "long"; } else { return "short"; } })();
    return 23;
}
exports.default = default_;



Object.defineProperty(exports, "__bp_priv__", { value: { Props, twice, default_ } });
