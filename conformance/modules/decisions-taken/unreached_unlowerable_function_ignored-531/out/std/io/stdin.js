//// std/io/stdin — the process's standard input, cross-backend (decision 506 (1)).

//// 

//// Reference:

////   Node.js  — https://nodejs.org/api/process.html#processstdin

////   Erlang   — https://www.erlang.org/doc/apps/stdlib/io.html#get_line/2

//// 

//// `readLine()` is the next line of input without its terminator (`\n` or `\r\n`), a last

//// line with no terminator included, and `null` at the end of input — the same on commonJS,

//// erlang and beam. It is a `Async` so that a program waiting on a terminal is not blocked

//// as a whole on Node: the line arrives through the stream's own events, so a signal handler

//// (`io.process.onSignal`) still runs while a prompt waits. Erlang is eager and blocks the

//// calling process in `io:get_line/2`.

//// 

//// `readChunk()` is the byte-level companion (what `io.terminal.keys` reads): the input

//// that has arrived, however long, `null` at the end of input. A program mixes the two

//// freely; what `readLine` has not taken is what `readChunk` answers.

//// 

//// There is no wasm binding: a call is refused at the call (`std-unsupported-on-target`,

//// decision 518 (4)).

// Does standard input read from a terminal? `false` for a pipe, a file or `/dev/null`.

// Node: `tty.isatty(0)`. Erlang: `prim_tty:isatty(stdin)`.

// isTTY: per-call template (see annotation)
function isTTY() { return require('tty').isatty(0); }
exports.isTTY = isTTY;

// Node's shared reader: the buffer, the queue of readers and the pump that answers them in

// order, created on first use and kept on `globalThis` (the stream is the process's, so is the

// buffer). The stream is paused whenever nobody waits, so a process whose reads are done can

// exit. Erlang keeps no state: `io:get_line/2` and `io:get_chars/3` are the buffer.

// reader: per-call template (see annotation)

// readLineHost: per-call template (see annotation)

// The next line of input without its line terminator, `null` at the end of input.

async function readLine() {
    return await new Promise((__r) => { (globalThis.__bpStdin ??= (() => { const __s = { buf: '', eof: false, q: [], dec: new (require('string_decoder').StringDecoder)('utf8') }; __s.pump = () => { while (__s.q.length) { const __r = __s.q[0][0]; const __k = __s.q[0][1]; if (__k === 'chunk') { if (__s.buf.length) { __s.q.shift(); const __c = __s.buf; __s.buf = ''; __r(__c); continue; } if (__s.eof) { __s.q.shift(); __r(null); continue; } break; } const __i = __s.buf.indexOf(String.fromCharCode(10)); if (__i >= 0) { __s.q.shift(); const __l = __s.buf.slice(0, __i); __s.buf = __s.buf.slice(__i + 1); __r(__l.endsWith(String.fromCharCode(13)) ? __l.slice(0, -1) : __l); continue; } if (__s.eof) { __s.q.shift(); if (__s.buf.length) { const __l = __s.buf; __s.buf = ''; __r(__l); } else { __r(null); } continue; } break; } if (__s.q.length && !__s.eof) { process.stdin.resume(); } else { process.stdin.pause(); } }; process.stdin.on('data', (__d) => { __s.buf += __s.dec.write(__d); __s.pump(); }); process.stdin.on('end', () => { __s.buf += __s.dec.end(); __s.eof = true; __s.pump(); }); process.stdin.on('error', () => { __s.eof = true; __s.pump(); }); process.stdin.pause(); return __s; })()).q.push([__r, 'line']); (globalThis.__bpStdin ??= (() => { const __s = { buf: '', eof: false, q: [], dec: new (require('string_decoder').StringDecoder)('utf8') }; __s.pump = () => { while (__s.q.length) { const __r = __s.q[0][0]; const __k = __s.q[0][1]; if (__k === 'chunk') { if (__s.buf.length) { __s.q.shift(); const __c = __s.buf; __s.buf = ''; __r(__c); continue; } if (__s.eof) { __s.q.shift(); __r(null); continue; } break; } const __i = __s.buf.indexOf(String.fromCharCode(10)); if (__i >= 0) { __s.q.shift(); const __l = __s.buf.slice(0, __i); __s.buf = __s.buf.slice(__i + 1); __r(__l.endsWith(String.fromCharCode(13)) ? __l.slice(0, -1) : __l); continue; } if (__s.eof) { __s.q.shift(); if (__s.buf.length) { const __l = __s.buf; __s.buf = ''; __r(__l); } else { __r(null); } continue; } break; } if (__s.q.length && !__s.eof) { process.stdin.resume(); } else { process.stdin.pause(); } }; process.stdin.on('data', (__d) => { __s.buf += __s.dec.write(__d); __s.pump(); }); process.stdin.on('end', () => { __s.buf += __s.dec.end(); __s.eof = true; __s.pump(); }); process.stdin.on('error', () => { __s.eof = true; __s.pump(); }); process.stdin.pause(); return __s; })()).pump(); });
}
exports.readLine = readLine;

// readChunkHost: per-call template (see annotation)

// What has arrived on standard input — one piece, never empty — or `null` at the end of input.

// On a terminal in raw mode (`io.terminal.setRaw`) that is the key just pressed, an escape

// sequence whole. Erlang reads a character at a time: after an Escape it waits 50 ms for the rest

// of the sequence, so a lone Escape key is told from the start of an arrow key there as well.

async function readChunk() {
    return await new Promise((__r) => { (globalThis.__bpStdin ??= (() => { const __s = { buf: '', eof: false, q: [], dec: new (require('string_decoder').StringDecoder)('utf8') }; __s.pump = () => { while (__s.q.length) { const __r = __s.q[0][0]; const __k = __s.q[0][1]; if (__k === 'chunk') { if (__s.buf.length) { __s.q.shift(); const __c = __s.buf; __s.buf = ''; __r(__c); continue; } if (__s.eof) { __s.q.shift(); __r(null); continue; } break; } const __i = __s.buf.indexOf(String.fromCharCode(10)); if (__i >= 0) { __s.q.shift(); const __l = __s.buf.slice(0, __i); __s.buf = __s.buf.slice(__i + 1); __r(__l.endsWith(String.fromCharCode(13)) ? __l.slice(0, -1) : __l); continue; } if (__s.eof) { __s.q.shift(); if (__s.buf.length) { const __l = __s.buf; __s.buf = ''; __r(__l); } else { __r(null); } continue; } break; } if (__s.q.length && !__s.eof) { process.stdin.resume(); } else { process.stdin.pause(); } }; process.stdin.on('data', (__d) => { __s.buf += __s.dec.write(__d); __s.pump(); }); process.stdin.on('end', () => { __s.buf += __s.dec.end(); __s.eof = true; __s.pump(); }); process.stdin.on('error', () => { __s.eof = true; __s.pump(); }); process.stdin.pause(); return __s; })()).q.push([__r, 'chunk']); (globalThis.__bpStdin ??= (() => { const __s = { buf: '', eof: false, q: [], dec: new (require('string_decoder').StringDecoder)('utf8') }; __s.pump = () => { while (__s.q.length) { const __r = __s.q[0][0]; const __k = __s.q[0][1]; if (__k === 'chunk') { if (__s.buf.length) { __s.q.shift(); const __c = __s.buf; __s.buf = ''; __r(__c); continue; } if (__s.eof) { __s.q.shift(); __r(null); continue; } break; } const __i = __s.buf.indexOf(String.fromCharCode(10)); if (__i >= 0) { __s.q.shift(); const __l = __s.buf.slice(0, __i); __s.buf = __s.buf.slice(__i + 1); __r(__l.endsWith(String.fromCharCode(13)) ? __l.slice(0, -1) : __l); continue; } if (__s.eof) { __s.q.shift(); if (__s.buf.length) { const __l = __s.buf; __s.buf = ''; __r(__l); } else { __r(null); } continue; } break; } if (__s.q.length && !__s.eof) { process.stdin.resume(); } else { process.stdin.pause(); } }; process.stdin.on('data', (__d) => { __s.buf += __s.dec.write(__d); __s.pump(); }); process.stdin.on('end', () => { __s.buf += __s.dec.end(); __s.eof = true; __s.pump(); }); process.stdin.on('error', () => { __s.eof = true; __s.pump(); }); process.stdin.pause(); return __s; })()).pump(); });
}
exports.readChunk = readChunk;

// ── tests ────────────────────────────────────────────────────────────────────

// A test cannot give itself an input: `readLine` / `readChunk` answer the end of input in the

// conformance cell `std_io_stdin_eof`.

Object.defineProperty(exports, "__bp_priv__", { value: { isTTY, readLine, readChunk } });
