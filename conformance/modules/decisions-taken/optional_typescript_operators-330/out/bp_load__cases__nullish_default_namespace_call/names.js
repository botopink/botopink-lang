function fallback() {
    return "anon";
}
exports.fallback = fallback;

Object.defineProperty(exports, "__bp_priv__", { value: { fallback } });
