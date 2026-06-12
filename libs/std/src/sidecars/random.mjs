// std/random — Node sidecar (std-tail F2 + P12).
//
// Userland Mulberry32 PRNG so `random.seed(s)` produces reproducible
// `seededFloat()` draws across the same Node process. `random.float()`
// stays on `Math.random` by default — seeding flips a module-local
// switch that subsequent `seededFloat()` reads from. This separation
// matches the spec: existing callers never see a behaviour change;
// only callers that explicitly `seed` then `seededFloat` get the
// reproducible stream.

let state = 0;
let seeded = false;

export function seed(s) {
    // `s` arrives as a bp `i64`; coerce to a 32-bit unsigned base.
    state = (Number(s) | 0) >>> 0;
    seeded = true;
}

// Mulberry32 step → returns `[0, 1)` float. Stable across versions of
// Node — the constants `0x6D2B79F5`, `0x85EBCA6B` are Mulberry32's
// canonical mixer. ~32 bits of entropy per draw; cycle ≥ 2^32.
export function seededFloat() {
    if (!seeded) return Math.random();
    let t = (state = (state + 0x6D2B79F5) | 0);
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return (((t ^ (t >>> 14)) >>> 0) / 4294967296);
}

export function isSeeded() {
    return seeded;
}
