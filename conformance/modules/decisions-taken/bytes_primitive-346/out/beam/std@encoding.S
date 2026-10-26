{module, std@encoding}.
{exports, [{base64Encode, 1}, {base64Decode, 1}, {base64UrlEncode, 1}, {base64UrlDecode, 1}, {hexEncode, 1}, {hexDecode, 1}, {base64EncodeBytes, 1}, {base64DecodeBytes, 1}, {hexEncodeBytes, 1}, {hexDecodeBytes, 1}, {percentEncode, 1}, {percentDecode, 1}, {formStringify, 1}, {formParse, 1}, {'__bp_priv__array_flatten', 1}, {'__bp_priv__array_range', 2}, {'__bp_priv__array_repeat', 2}, {'__bp_priv__string_slice', 3}, {'__bp_priv__base64DecodeBody', 1}, {'__bp_priv__base64EncodeBody', 1}, {'__bp_priv__base64Text', 1}, {'__bp_priv__base64Value', 1}, {'__bp_priv__escapedByte', 2}, {'__bp_priv__formDecode', 1}, {'__bp_priv__formField', 1}, {'__bp_priv__hexDecodeBody', 1}, {'__bp_priv__hexDigit', 1}, {'__bp_priv__hexEncodeBody', 1}, {'__bp_priv__hexValue', 1}, {'__bp_priv__isUnreserved', 1}, {'__bp_priv__padToMultipleOfFour', 1}, {'__bp_priv__percentDecodeBody', 1}, {'__bp_priv__percentEncodeBody', 1}, {'__bp_priv__refused', 1}, {'__bp_priv__textOfUtf8', 1}, {'__bp_priv__upperHexDigit', 1}, {'__bp_priv__utf8Bytes', 1}, {'__bp_priv__utf8Of', 1}]}.
{attributes, []}.
{labels, 902}.

{function, 'array_range', 2, 3}.
  {label, 2}.
    {line, [{location, "std@encoding.erl", 1}]}.
    {func_info, {atom, std@encoding}, {atom, 'array_range'}, 2}.
  {label, 3}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_ge, {f, 76}, [{integer, 0}, {x, 0}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 77}}.
  {label, 76}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 78}, [{x, 0}, {integer, 1}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {jump, {f, 79}}.
  {label, 78}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call, 2, {f, 81}}.
  {label, 79}.
  {label, 77}.
    {deallocate, 6}.
    return.

{function, 'array_repeat', 2, 5}.
  {label, 4}.
    {line, [{location, "std@encoding.erl", 2}]}.
    {func_info, {atom, std@encoding}, {atom, 'array_repeat'}, 2}.
  {label, 5}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ge, {f, 82}, [{integer, 0}, {y, 1}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 83}}.
  {label, 82}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {test, is_eq_exact, {f, 84}, [{x, 0}, {integer, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 81}}.
    {jump, {f, 85}}.
  {label, 84}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 81}}.
    {move, {x, 0}, {x, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 2}}.
    {test_heap, 2, 3}.
    {put_list, {x, 0}, {x, 2}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 81}}.
  {label, 85}.
  {label, 83}.
    {deallocate, 6}.
    return.
%%% std/encoding — the wire formats: base64, base64url, hex, percent
%%% encoding and the percent-aware form codec, cross-backend.
%%% 
%%% Reference:
%%%   Node.js  — https://nodejs.org/api/buffer.html (`Buffer.from(s, 'utf8').toString('base64' | 'base64url' | 'hex')`)
%%%              https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/encodeURIComponent
%%%   Erlang   — https://www.erlang.org/doc/apps/stdlib/base64.html
%%%              https://www.erlang.org/doc/apps/stdlib/binary.html (`encode_hex/1`, `decode_hex/1`)
%%%              https://www.erlang.org/doc/apps/stdlib/uri_string.html (`quote/1`, `unquote/1`)
%%%   RFC 4648 (base64, base64url), RFC 3986 §2.1 (percent-encoding)
%%% 
%%% One import for the whole wire-format surface. Every encoder answers a
%%% string; every decoder that can meet malformed input answers
%%% `Result<…, EncodingError>` (decision 486): the host cell writes
%%% `result: true` (decisions 431, 490) and answers `Result<…, HostError>`,
%%% and the public function maps it — nothing here returns a sentinel. The text
%%% codecs read and write the UTF-8 bytes of a `string`: `base64Decode` and
%%% `hexDecode` answer the bytes read back as UTF-8 (a non-UTF-8 payload is
%%% lossy). Bytes cross losslessly through the `Bytes` bridges
%%% (decision 346): `base64EncodeBytes` / `base64DecodeBytes` and
%%% `hexEncodeBytes` / `hexDecodeBytes`.
%%% 
%%% Was also `base64` (decision 106): its `encode`/`decode`/`encodeUrlSafe`/
%%% `decodeUrlSafe` are `base64Encode`/`base64Decode`/`base64UrlEncode`/
%%% `base64UrlDecode` here, and its four tests sit at the foot of this file.
% What a decoder refuses (decision 486): the text is not in the codec's form.
% Standard base64 (RFC 4648 §4) of the UTF-8 bytes of `s`, with `=` padding.

{function, base64Encode, 1, 65}.
  {label, 64}.
    {line, [{location, "std@encoding.erl", 3}]}.
    {func_info, {atom, std@encoding}, {atom, base64Encode}, 1}.
  {label, 65}.
    {call_ext_only, 1, {extfunc, base64, encode, 1}}.
% The inverse of `base64Encode`. Malformed input is an `Error`: Node's
% `Buffer.from(_, 'base64')` silently drops what it cannot read, so the
% template re-encodes and compares to detect it; Erlang's `base64:decode/1`
% raises, and the template catches.

{function, base64Decode, 1, 7}.
  {label, 6}.
    {line, [{location, "std@encoding.erl", 4}]}.
    {func_info, {atom, std@encoding}, {atom, base64Decode}, 1}.
  {label, 7}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 87}}.
    {test, is_tagged_tuple, {f, 103}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 2}.
    return.
    {jump, {f, 102}}.
  {label, 103}.
    {test, is_tagged_tuple, {f, 104}, [{x, 0}, 2, {atom, error}]}.
    {move, {atom, std@encoding@@EncodingError__v__notbase64}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 2}.
    return.
    {jump, {f, 102}}.
  {label, 104}.
    {case_end, {x, 0}}.
  {label, 102}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 2}.
    return.
% base64url (RFC 4648 §5): the `-_` alphabet, no `=` padding — the form
% JWS/JWT (RFC 7515) and `random.secureToken` use. Pure over `base64Encode`,
% with `replaceAll` (not `replace`, which stops at the first occurrence).

{function, base64UrlEncode, 1, 9}.
  {label, 8}.
    {line, [{location, "std@encoding.erl", 5}]}.
    {func_info, {atom, std@encoding}, {atom, base64UrlEncode}, 1}.
  {label, 9}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, base64, encode, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"+">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"-">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call, 3, {f, 106}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"/">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"_">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call, 3, {f, 106}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"=">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 3}, {x, 0}}.
    {call_last, 3, {f, 106}, 4}.
% The inverse of `base64UrlEncode`: restore the `+/` alphabet, re-pad to a
% multiple of four, decode.

{function, base64UrlDecode, 1, 11}.
  {label, 10}.
    {line, [{location, "std@encoding.erl", 6}]}.
    {func_info, {atom, std@encoding}, {atom, base64UrlDecode}, 1}.
  {label, 11}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"-">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"+">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 106}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"_">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"/">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call, 3, {f, 106}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call, 1, {f, 13}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {call_last, 1, {f, 7}, 4}.
% Internal: append `=` until the length is a multiple of four. Tail-recursive;
% at most three steps.

{function, padToMultipleOfFour, 1, 13}.
  {label, 12}.
    {line, [{location, "std@encoding.erl", 7}]}.
    {func_info, {atom, std@encoding}, {atom, padToMultipleOfFour}, 1}.
  {label, 13}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {gc_bif, 'rem', {f, 0}, 1, [{x, 0}, {integer, 4}], {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 111}, [{y, 1}, {integer, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {jump, {f, 112}}.
  {label, 111}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"=">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 114}}.
    {call, 1, {f, 13}}.
  {label, 112}.
    {deallocate, 3}.
    return.
% Lowercase hex of the UTF-8 bytes of `s`: `"hi"` → `6869`.

{function, hexEncode, 1, 69}.
  {label, 68}.
    {line, [{location, "std@encoding.erl", 8}]}.
    {func_info, {atom, std@encoding}, {atom, hexEncode}, 1}.
  {label, 69}.
    {call_only, 1, {f, 67}}.
% The inverse of `hexEncode`, either case. An odd length or a non-hex digit
% is an `Error` (Node's `Buffer.from(_, 'hex')` truncates silently at the
% first bad digit, so the template validates first; Erlang's
% `binary:decode_hex/1` raises `badarg`, caught).

{function, hexDecode, 1, 15}.
  {label, 14}.
    {line, [{location, "std@encoding.erl", 9}]}.
    {func_info, {atom, std@encoding}, {atom, hexDecode}, 1}.
  {label, 15}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 148}}.
    {test, is_tagged_tuple, {f, 164}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 2}.
    return.
    {jump, {f, 163}}.
  {label, 164}.
    {test, is_tagged_tuple, {f, 165}, [{x, 0}, 2, {atom, error}]}.
    {move, {atom, std@encoding@@EncodingError__v__nothex}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 2}.
    return.
    {jump, {f, 163}}.
  {label, 165}.
    {case_end, {x, 0}}.
  {label, 163}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 2}.
    return.
% ── the `bytes` bridges (decision 346) ───────────────────────────────────────
% The codecs above over `bytes`, lossless: an encoder answers the text of the
% bytes as they are, a decoder the bytes the text spells — with the text
% codecs' rules (the Node cell's base64: trailing `=` optional, no length of
% the form 4k + 1, zero bits after the last whole byte; hex either case, an
% even length) and their `Error` texts. On wasm and at comptime std-wasm
% answers (`encoding.zig`); a decoder's cell answers `?bytes`, absent for text
% that is not one, and the public function makes it the `Error`.
% Standard base64 (RFC 4648 §4) of `b`, with `=` padding.

{function, base64EncodeBytes, 1, 71}.
  {label, 70}.
    {line, [{location, "std@encoding.erl", 10}]}.
    {func_info, {atom, std@encoding}, {atom, base64EncodeBytes}, 1}.
  {label, 71}.
    {call_ext_only, 1, {extfunc, base64, encode, 1}}.
% The bytes the base64 text `s` spells; anything `base64Decode` refuses is
% the same `Error`.

{function, base64DecodeBytes, 1, 17}.
  {label, 16}.
    {line, [{location, "std@encoding.erl", 11}]}.
    {func_info, {atom, std@encoding}, {atom, base64DecodeBytes}, 1}.
  {label, 17}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 167}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 218}, [{y, 1}, {atom, undefined}]}.
    {move, {atom, std@encoding@@EncodingError__v__notbase64}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 218}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 2}.
    return.
% Lowercase hex of `b`: the bytes `0x68 0x69` are `6869`.

{function, hexEncodeBytes, 1, 73}.
  {label, 72}.
    {line, [{location, "std@encoding.erl", 12}]}.
    {func_info, {atom, std@encoding}, {atom, hexEncodeBytes}, 1}.
  {label, 73}.
    {call_only, 1, {f, 67}}.
% The bytes the hex text `s` spells, either case; an odd length or a non-hex
% digit is `hexDecode`'s `Error`.

{function, hexDecodeBytes, 1, 19}.
  {label, 18}.
    {line, [{location, "std@encoding.erl", 13}]}.
    {func_info, {atom, std@encoding}, {atom, hexDecodeBytes}, 1}.
  {label, 19}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 220}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 252}, [{y, 1}, {atom, undefined}]}.
    {move, {atom, std@encoding@@EncodingError__v__nothex}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 252}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 2}.
    return.
% RFC 3986 percent-encoding of a component: every byte of the UTF-8 form
% outside the unreserved set `A-Z a-z 0-9 - . _ ~` becomes `%XX`, uppercase.
% `uri_string:quote/1` is exactly that; `encodeURIComponent` leaves
% `! ' ( ) *` unencoded (RFC 2396's mark set), so the Node template encodes
% those five too — the two targets answer the same bytes for the same input.

{function, percentEncode, 1, 75}.
  {label, 74}.
    {line, [{location, "std@encoding.erl", 14}]}.
    {func_info, {atom, std@encoding}, {atom, percentEncode}, 1}.
  {label, 75}.
    {call_ext_only, 1, {extfunc, uri_string, quote, 1}}.
% The inverse of `percentEncode`. A `%` not followed by two hex digits, or a
% sequence that is not UTF-8, is an `Error`. `+` is left as `+` — the form
% codec below is what reads `+` as a space.

{function, percentDecode, 1, 21}.
  {label, 20}.
    {line, [{location, "std@encoding.erl", 15}]}.
    {func_info, {atom, std@encoding}, {atom, percentDecode}, 1}.
  {label, 21}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 254}}.
    {test, is_tagged_tuple, {f, 278}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 2}.
    return.
    {jump, {f, 277}}.
  {label, 278}.
    {test, is_tagged_tuple, {f, 279}, [{x, 0}, 2, {atom, error}]}.
    {move, {atom, std@encoding@@EncodingError__v__notpercentencoded}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 2}.
    return.
    {jump, {f, 277}}.
  {label, 279}.
    {case_end, {x, 0}}.
  {label, 277}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 2}.
    return.
% `application/x-www-form-urlencoded`, the escaping form: each pair is
% `percentEncode(name)=percentEncode(value)`, joined with `&`.
% `querystring.stringify` writes the same text and refuses a control
% character, which this does not.

{function, formStringify, 1, 23}.
  {label, 22}.
    {line, [{location, "std@encoding.erl", 16}]}.
    {func_info, {atom, std@encoding}, {atom, formStringify}, 1}.
  {label, 23}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 281}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"&">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 114}, 3}.
% The inverse of `formStringify`, percent-aware: split on `&`, each field on
% its FIRST `=` (a field with no `=` is a name with an empty value), `+` read
% as a space (the form encoding's rule), then percent-decoded. A field that
% does not decode keeps its raw text — a parse over user input must not
% throw, and a malformed pair is still a pair. Empty fields (`a=1&&b=2`)
% are dropped. `querystring.parseForm` is the refusing reader: a malformed
% escape or a control character is its `Error`, not a raw field.

{function, formParse, 1, 25}.
  {label, 24}.
    {line, [{location, "std@encoding.erl", 17}]}.
    {func_info, {atom, std@encoding}, {atom, formParse}, 1}.
  {label, 25}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"&">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 283}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 300}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, filter, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 304}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, map, 2}, 4}.
% Internal: one `name=value` field into its decoded pair.

{function, formField, 1, 27}.
  {label, 26}.
    {line, [{location, "std@encoding.erl", 18}]}.
    {func_info, {atom, std@encoding}, {atom, formField}, 1}.
  {label, 27}.
    {allocate, 9, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"=">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 306}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_lt, {f, 319}, [{y, 1}, {integer, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {jump, {f, 320}}.
  {label, 319}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 2}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 3, {f, 322}}.
  {label, 320}.
    {move, {x, 0}, {y, 2}}.
    {test, is_lt, {f, 323}, [{y, 1}, {integer, 0}]}.
    {move, {literal, <<"">>}, {x, 0}}.
    {jump, {f, 324}}.
  {label, 323}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 325}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 325}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 326}}.
  {label, 325}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/encoding.bp:224:51">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 326}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 322}}.
  {label, 324}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 2}, {x, 0}}.
    {call, 1, {f, 29}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {call, 1, {f, 29}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{y, 5}, {x, 0}]}}.
    {deallocate, 9}.
    return.
% Internal: `+` to space, then percent-decode, falling back to the raw text.

{function, formDecode, 1, 29}.
  {label, 28}.
    {line, [{location, "std@encoding.erl", 19}]}.
    {func_info, {atom, std@encoding}, {atom, formDecode}, 1}.
  {label, 29}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"+">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 106}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 21}}.
    {test, is_tagged_tuple, {f, 327}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 328}}.
  {label, 327}.
    {move, {y, 1}, {x, 0}}.
  {label, 328}.
    {deallocate, 2}.
    return.
% ── the wasm bodies (decision 238) ───────────────────────────────────────────
% wasm has no host to encode with, so each cell above names one of these
% private bodies with `#[compiler.external(.Wasm(fn: …))]`. They run only on wasm and
% answer what the Node cell answers: a string's bytes are its UTF-8, a decoded
% byte string is read back as Node's `toString('utf8')` reads it (WHATWG UTF-8:
% each maximal ill-formed subsequence one U+FFFD), and the text is built from
% code points with `string.fromCodepoint` (decision 262).

{function, base64EncodeBody, 1, 31}.
  {label, 30}.
    {line, [{location, "std@encoding.erl", 20}]}.
    {func_info, {atom, std@encoding}, {atom, base64EncodeBody}, 1}.
  {label, 31}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 49}}.
    {call_last, 1, {f, 55}, 1}.
% What the wasm bodies refuse with: the `HostError` a host's raise would be.

{function, refused, 1, 33}.
  {label, 32}.
    {line, [{location, "std@encoding.erl", 21}]}.
    {func_info, {atom, std@encoding}, {atom, refused}, 1}.
  {label, 33}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"host">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {x, 0}}.
    {test_heap, 6, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 0}, {x, 1}, {x, 0}, {atom, undefined}]}}.
    {deallocate, 1}.
    return.
% The Node cell's rule: strip trailing `=`, decode, and accept only what
% re-encodes to the same text — the `+/` alphabet only, no length of the form
% 4k + 1, zero bits after the last whole byte.

{function, base64DecodeBody, 1, 35}.
  {label, 34}.
    {line, [{location, "std@encoding.erl", 22}]}.
    {func_info, {atom, std@encoding}, {atom, base64DecodeBody}, 1}.
  {label, 35}.
    {allocate, 22, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}, {y, 20}, {y, 21}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 330}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {line, [{location, "std@encoding.erl", 23}]}.
  {label, 339}.
    {test, is_lt, {f, 341}, [{integer, 0}, {y, 2}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 342}}.
  {label, 341}.
    {move, {atom, false}, {x, 0}}.
  {label, 342}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 343}, [{x, 1}, {atom, true}]}.
    {gc_bif, '-', {f, 0}, 0, [{y, 2}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 346}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 346}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 347}}.
  {label, 346}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/encoding.bp:262:30">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 347}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 349}}.
    {test, is_ne_exact, {f, 345}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {jump, {f, 352}}.
  {label, 345}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 352}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"=">>}, {x, 0}}.
    {test, is_eq_exact, {f, 353}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 354}}.
  {label, 353}.
    {move, {atom, false}, {x, 0}}.
  {label, 354}.
    {jump, {f, 344}}.
  {label, 343}.
    {move, {atom, false}, {x, 0}}.
  {label, 344}.
    {test, is_eq_exact, {f, 340}, [{x, 0}, {atom, true}]}.
    {gc_bif, '-', {f, 0}, 0, [{y, 2}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 355}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 355}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 356}}.
  {label, 355}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/encoding.bp:263:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 356}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 339}}.
  {label, 340}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 2}, {integer, 4}], {x, 0}}.
    {test, is_eq_exact, {f, 357}, [{x, 0}, {integer, 1}]}.
    {move, {literal, <<"not base64">>}, {x, 0}}.
    {call, 1, {f, 33}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 22}.
    return.
  {label, 357}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {line, [{location, "std@encoding.erl", 23}]}.
  {label, 358}.
    {test, is_lt, {f, 359}, [{y, 5}, {y, 2}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call, 2, {f, 349}}.
    {test, is_ne_exact, {f, 360}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {jump, {f, 361}}.
  {label, 360}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 361}.
    {call, 1, {f, 57}}.
    {move, {x, 0}, {y, 7}}.
    {test, is_lt, {f, 362}, [{y, 7}, {integer, 0}]}.
    {move, {literal, <<"not base64">>}, {x, 0}}.
    {call, 1, {f, 33}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 22}.
    return.
  {label, 362}.
    {test_heap, 2, 0}.
    {put_list, {y, 7}, nil, {x, 1}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 5}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 363}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 363}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 364}}.
  {label, 363}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/encoding.bp:272:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 364}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 358}}.
  {label, 359}.
    {gc_bif, '-', {f, 0}, 0, [{y, 2}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 366}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 366}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 367}}.
  {label, 366}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/encoding.bp:274:29">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 367}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 4}, {x, 0}}.
    {call, 2, {f, 349}}.
    {test, is_ne_exact, {f, 365}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {jump, {f, 368}}.
  {label, 365}.
    {move, {integer, 0}, {x, 0}}.
  {label, 368}.
    {move, {x, 0}, {y, 9}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 2}, {integer, 4}], {x, 0}}.
    {test, is_eq_exact, {f, 370}, [{x, 0}, {integer, 2}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 371}}.
  {label, 370}.
    {move, {atom, false}, {x, 0}}.
  {label, 371}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 372}, [{x, 1}, {atom, true}]}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 9}, {integer, 16}], {x, 0}}.
    {test, is_ne_exact, {f, 374}, [{x, 0}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 375}}.
  {label, 374}.
    {move, {atom, false}, {x, 0}}.
  {label, 375}.
    {jump, {f, 373}}.
  {label, 372}.
    {move, {atom, false}, {x, 0}}.
  {label, 373}.
    {test, is_eq, {f, 369}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"not base64">>}, {x, 0}}.
    {call, 1, {f, 33}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 22}.
    return.
  {label, 369}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 2}, {integer, 4}], {x, 0}}.
    {test, is_eq_exact, {f, 377}, [{x, 0}, {integer, 3}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 378}}.
  {label, 377}.
    {move, {atom, false}, {x, 0}}.
  {label, 378}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 379}, [{x, 1}, {atom, true}]}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 9}, {integer, 4}], {x, 0}}.
    {test, is_ne_exact, {f, 381}, [{x, 0}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 382}}.
  {label, 381}.
    {move, {atom, false}, {x, 0}}.
  {label, 382}.
    {jump, {f, 380}}.
  {label, 379}.
    {move, {atom, false}, {x, 0}}.
  {label, 380}.
    {test, is_eq, {f, 376}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"not base64">>}, {x, 0}}.
    {call, 1, {f, 33}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 22}.
    return.
  {label, 376}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {line, [{location, "std@encoding.erl", 23}]}.
  {label, 383}.
    {test, is_lt, {f, 384}, [{y, 11}, {y, 2}]}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 11}, {x, 1}}.
    {call, 2, {f, 349}}.
    {test, is_ne_exact, {f, 385}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {x, 0}}.
    {jump, {f, 386}}.
  {label, 385}.
    {move, {integer, 0}, {x, 0}}.
  {label, 386}.
    {move, {x, 0}, {y, 13}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 11}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 388}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 388}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 389}}.
  {label, 388}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/encoding.bp:281:31">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 389}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 4}, {x, 0}}.
    {call, 2, {f, 349}}.
    {test, is_ne_exact, {f, 387}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 14}, {x, 0}}.
    {jump, {f, 390}}.
  {label, 387}.
    {move, {integer, 0}, {x, 0}}.
  {label, 390}.
    {move, {x, 0}, {y, 15}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 11}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 392}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 392}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 393}}.
  {label, 392}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/encoding.bp:282:31">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 393}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 4}, {x, 0}}.
    {call, 2, {f, 349}}.
    {test, is_ne_exact, {f, 391}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 16}, {x, 0}}.
    {jump, {f, 394}}.
  {label, 391}.
    {move, {integer, 0}, {x, 0}}.
  {label, 394}.
    {move, {x, 0}, {y, 17}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 11}, {integer, 3}], {x, 0}}.
    {test, is_ge, {f, 396}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 396}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 397}}.
  {label, 396}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/encoding.bp:283:31">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 397}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 4}, {x, 0}}.
    {call, 2, {f, 349}}.
    {test, is_ne_exact, {f, 395}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 18}}.
    {move, {y, 18}, {x, 0}}.
    {jump, {f, 398}}.
  {label, 395}.
    {move, {integer, 0}, {x, 0}}.
  {label, 398}.
    {move, {x, 0}, {y, 19}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 13}, {integer, 4}], {x, 0}}.
    {test, is_ge, {f, 399}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 399}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 400}}.
  {label, 399}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/encoding.bp:284:23">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 400}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, 'div', {f, 0}, 2, [{y, 15}, {integer, 16}], {x, 0}}.
    {test, is_ge, {f, 401}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 401}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 402}}.
  {label, 401}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/encoding.bp:284:32">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 402}.
    {gc_bif, '+', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 403}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 403}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 404}}.
  {label, 403}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/encoding.bp:284:27">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 404}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 10}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 11}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 406}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 406}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 407}}.
  {label, 406}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/encoding.bp:285:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 407}.
    {test, is_lt, {f, 405}, [{x, 0}, {y, 2}]}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 15}, {integer, 16}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {integer, 16}], {x, 0}}.
    {test, is_ge, {f, 408}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 408}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 409}}.
  {label, 408}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/encoding.bp:285:45">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 409}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, 'div', {f, 0}, 2, [{y, 17}, {integer, 4}], {x, 0}}.
    {test, is_ge, {f, 410}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 410}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 411}}.
  {label, 410}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/encoding.bp:285:55">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 411}.
    {gc_bif, '+', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 412}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 412}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 413}}.
  {label, 412}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/encoding.bp:285:50">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 413}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 10}}.
    {jump, {f, 414}}.
  {label, 405}.
  {label, 414}.
    {gc_bif, '+', {f, 0}, 0, [{y, 11}, {integer, 3}], {x, 0}}.
    {test, is_ge, {f, 416}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 416}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 417}}.
  {label, 416}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/encoding.bp:286:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 417}.
    {test, is_lt, {f, 415}, [{x, 0}, {y, 2}]}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 17}, {integer, 4}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {integer, 64}], {x, 0}}.
    {test, is_ge, {f, 418}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 418}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 419}}.
  {label, 418}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/encoding.bp:286:44">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 419}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 19}], {x, 0}}.
    {test, is_ge, {f, 420}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 420}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 421}}.
  {label, 420}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/encoding.bp:286:49">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 421}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 10}}.
    {jump, {f, 422}}.
  {label, 415}.
  {label, 422}.
    {gc_bif, '+', {f, 0}, 0, [{y, 11}, {integer, 4}], {x, 0}}.
    {test, is_ge, {f, 423}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 423}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 424}}.
  {label, 423}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/encoding.bp:287:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 424}.
    {move, {x, 0}, {y, 11}}.
    {jump, {f, 383}}.
  {label, 384}.
    {move, {y, 10}, {x, 0}}.
    {call, 1, {f, 53}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 22}.
    return.

{function, hexEncodeBody, 1, 37}.
  {label, 36}.
    {line, [{location, "std@encoding.erl", 23}]}.
    {func_info, {atom, std@encoding}, {atom, hexEncodeBody}, 1}.
  {label, 37}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 49}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 426}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 114}, 5}.

{function, hexDecodeBody, 1, 39}.
  {label, 38}.
    {line, [{location, "std@encoding.erl", 24}]}.
    {func_info, {atom, std@encoding}, {atom, hexDecodeBody}, 1}.
  {label, 39}.
    {allocate, 8, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 330}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {gc_bif, 'rem', {f, 0}, 1, [{x, 0}, {integer, 2}], {x, 0}}.
    {test, is_ne_exact, {f, 429}, [{x, 0}, {integer, 0}]}.
    {move, {literal, <<"not hex">>}, {x, 0}}.
    {call, 1, {f, 33}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 8}.
    return.
  {label, 429}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {line, [{location, "std@encoding.erl", 25}]}.
  {label, 430}.
    {move, {y, 1}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 431}, [{y, 3}, {x, 0}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call, 2, {f, 349}}.
    {test, is_ne_exact, {f, 432}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {jump, {f, 433}}.
  {label, 432}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 433}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 5}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 3}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 435}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 435}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 436}}.
  {label, 435}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/encoding.bp:303:35">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 436}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 349}}.
    {test, is_ne_exact, {f, 434}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {jump, {f, 437}}.
  {label, 434}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 437}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 7}}.
    {test, is_lt, {f, 439}, [{y, 5}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 440}}.
  {label, 439}.
    {move, {atom, false}, {x, 0}}.
  {label, 440}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 441}, [{x, 1}, {atom, true}]}.
    {test, is_lt, {f, 443}, [{y, 7}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 444}}.
  {label, 443}.
    {move, {atom, false}, {x, 0}}.
  {label, 444}.
    {jump, {f, 442}}.
  {label, 441}.
    {move, {atom, true}, {x, 0}}.
  {label, 442}.
    {test, is_eq, {f, 438}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"not hex">>}, {x, 0}}.
    {call, 1, {f, 33}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 8}.
    return.
  {label, 438}.
    {gc_bif, '*', {f, 0}, 0, [{y, 5}, {integer, 16}], {x, 0}}.
    {test, is_ge, {f, 445}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 445}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 446}}.
  {label, 445}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/encoding.bp:305:23">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 446}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 7}], {x, 0}}.
    {test, is_ge, {f, 447}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 447}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 448}}.
  {label, 447}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/encoding.bp:305:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 448}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 449}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 449}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 450}}.
  {label, 449}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/encoding.bp:306:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 450}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 430}}.
  {label, 431}.
    {move, {y, 2}, {x, 0}}.
    {call, 1, {f, 53}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 8}.
    return.
% `encodeURIComponent` plus the five marks the Node cell escapes too: every
% UTF-8 byte outside `A-Z a-z 0-9 - . _ ~` as `%XX`, uppercase.

{function, percentEncodeBody, 1, 41}.
  {label, 40}.
    {line, [{location, "std@encoding.erl", 25}]}.
    {func_info, {atom, std@encoding}, {atom, percentEncodeBody}, 1}.
  {label, 41}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 330}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 452}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 114}, 5}.
% `decodeURIComponent`: a `%` reads two hex digits; a byte below 0x80 is its
% character, a lead byte takes the continuation escapes its length says, and
% the sequence must be well-formed UTF-8 (no overlong form, no surrogate,
% nothing past U+10FFFF) — anything else is the `Error`. Other text passes.

{function, percentDecodeBody, 1, 43}.
  {label, 42}.
    {line, [{location, "std@encoding.erl", 26}]}.
    {func_info, {atom, std@encoding}, {atom, percentDecodeBody}, 1}.
  {label, 43}.
    {allocate, 16, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 330}}.
    {move, {x, 0}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {line, [{location, "std@encoding.erl", 27}]}.
  {label, 470}.
    {move, {y, 1}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 471}, [{y, 3}, {x, 0}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call, 2, {f, 349}}.
    {test, is_ne_exact, {f, 472}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {jump, {f, 473}}.
  {label, 472}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 473}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, <<"%">>}, {x, 0}}.
    {test, is_ne_exact, {f, 474}, [{y, 5}, {x, 0}]}.
    {test_heap, 2, 0}.
    {put_list, {y, 5}, nil, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 3}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 475}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 475}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 476}}.
  {label, 475}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/encoding.bp:341:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 476}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 477}}.
  {label, 474}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call, 2, {f, 45}}.
    {move, {x, 0}, {y, 6}}.
    {test, is_lt, {f, 478}, [{y, 6}, {integer, 0}]}.
    {move, {literal, <<"not percent-encoded">>}, {x, 0}}.
    {call, 1, {f, 33}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 16}.
    return.
  {label, 478}.
    {test, is_lt, {f, 479}, [{y, 6}, {integer, 128}]}.
    {move, {y, 6}, {x, 0}}.
    {call, 1, {f, 481}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 3}, {integer, 3}], {x, 0}}.
    {test, is_ge, {f, 486}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 486}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 487}}.
  {label, 486}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/encoding.bp:347:23">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 487}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 488}}.
  {label, 479}.
    {test, is_ge, {f, 490}, [{y, 6}, {integer, 192}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 491}}.
  {label, 490}.
    {move, {atom, false}, {x, 0}}.
  {label, 491}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 492}, [{x, 1}, {atom, true}]}.
    {test, is_lt, {f, 494}, [{y, 6}, {integer, 224}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 495}}.
  {label, 494}.
    {move, {atom, false}, {x, 0}}.
  {label, 495}.
    {jump, {f, 493}}.
  {label, 492}.
    {move, {atom, false}, {x, 0}}.
  {label, 493}.
    {test, is_eq, {f, 489}, [{x, 0}, {atom, true}]}.
    {move, {integer, 2}, {x, 0}}.
    {jump, {f, 496}}.
  {label, 489}.
    {test, is_ge, {f, 498}, [{y, 6}, {integer, 224}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 499}}.
  {label, 498}.
    {move, {atom, false}, {x, 0}}.
  {label, 499}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 500}, [{x, 1}, {atom, true}]}.
    {test, is_lt, {f, 502}, [{y, 6}, {integer, 240}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 503}}.
  {label, 502}.
    {move, {atom, false}, {x, 0}}.
  {label, 503}.
    {jump, {f, 501}}.
  {label, 500}.
    {move, {atom, false}, {x, 0}}.
  {label, 501}.
    {test, is_eq, {f, 497}, [{x, 0}, {atom, true}]}.
    {move, {integer, 3}, {x, 0}}.
    {jump, {f, 504}}.
  {label, 497}.
    {test, is_ge, {f, 506}, [{y, 6}, {integer, 240}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 507}}.
  {label, 506}.
    {move, {atom, false}, {x, 0}}.
  {label, 507}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 508}, [{x, 1}, {atom, true}]}.
    {test, is_lt, {f, 510}, [{y, 6}, {integer, 248}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 511}}.
  {label, 510}.
    {move, {atom, false}, {x, 0}}.
  {label, 511}.
    {jump, {f, 509}}.
  {label, 508}.
    {move, {atom, false}, {x, 0}}.
  {label, 509}.
    {test, is_eq, {f, 505}, [{x, 0}, {atom, true}]}.
    {move, {integer, 4}, {x, 0}}.
    {jump, {f, 512}}.
  {label, 505}.
    {move, {integer, 0}, {x, 0}}.
  {label, 512}.
  {label, 504}.
  {label, 496}.
    {move, {x, 0}, {y, 7}}.
    {test, is_eq_exact, {f, 513}, [{y, 7}, {integer, 0}]}.
    {move, {literal, <<"not percent-encoded">>}, {x, 0}}.
    {call, 1, {f, 33}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 16}.
    return.
  {label, 513}.
    {test, is_eq_exact, {f, 514}, [{y, 7}, {integer, 2}]}.
    {gc_bif, '-', {f, 0}, 0, [{y, 6}, {integer, 192}], {x, 0}}.
    {test, is_ge, {f, 516}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 516}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 517}}.
  {label, 516}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/encoding.bp:359:23">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 517}.
    {jump, {f, 515}}.
  {label, 514}.
    {test, is_eq_exact, {f, 518}, [{y, 7}, {integer, 3}]}.
    {gc_bif, '-', {f, 0}, 0, [{y, 6}, {integer, 224}], {x, 0}}.
    {test, is_ge, {f, 520}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 520}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 521}}.
  {label, 520}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/encoding.bp:361:23">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 521}.
    {jump, {f, 519}}.
  {label, 518}.
    {gc_bif, '-', {f, 0}, 0, [{y, 6}, {integer, 240}], {x, 0}}.
    {test, is_ge, {f, 522}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 522}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 523}}.
  {label, 522}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/encoding.bp:363:23">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 523}.
  {label, 519}.
  {label, 515}.
    {move, {x, 0}, {y, 8}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {line, [{location, "std@encoding.erl", 27}]}.
  {label, 524}.
    {test, is_lt, {f, 525}, [{y, 9}, {y, 7}]}.
    {gc_bif, '*', {f, 0}, 0, [{integer, 3}, {y, 9}], {x, 0}}.
    {test, is_ge, {f, 526}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 526}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 527}}.
  {label, 526}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/encoding.bp:366:52">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 527}.
    {gc_bif, '+', {f, 0}, 1, [{y, 3}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 528}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 528}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 529}}.
  {label, 528}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/encoding.bp:366:48">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 529}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 45}}.
    {move, {x, 0}, {y, 10}}.
    {test, is_lt, {f, 531}, [{y, 10}, {integer, 128}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 532}}.
  {label, 531}.
    {move, {atom, false}, {x, 0}}.
  {label, 532}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 533}, [{x, 1}, {atom, true}]}.
    {test, is_ge, {f, 535}, [{y, 10}, {integer, 192}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 536}}.
  {label, 535}.
    {move, {atom, false}, {x, 0}}.
  {label, 536}.
    {jump, {f, 534}}.
  {label, 533}.
    {move, {atom, true}, {x, 0}}.
  {label, 534}.
    {test, is_eq, {f, 530}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"not percent-encoded">>}, {x, 0}}.
    {call, 1, {f, 33}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 16}.
    return.
  {label, 530}.
    {gc_bif, '*', {f, 0}, 0, [{y, 8}, {integer, 64}], {x, 0}}.
    {test, is_ge, {f, 537}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 537}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 538}}.
  {label, 537}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/encoding.bp:369:29">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 538}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '-', {f, 0}, 2, [{y, 10}, {integer, 128}], {x, 0}}.
    {test, is_ge, {f, 539}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 539}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 540}}.
  {label, 539}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/encoding.bp:369:40">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 540}.
    {gc_bif, '+', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 541}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 541}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 542}}.
  {label, 541}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/encoding.bp:369:34">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 542}.
    {move, {x, 0}, {y, 8}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 9}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 543}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 543}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 544}}.
  {label, 543}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/encoding.bp:370:27">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 544}.
    {move, {x, 0}, {y, 9}}.
    {jump, {f, 524}}.
  {label, 525}.
    {test, is_eq_exact, {f, 545}, [{y, 7}, {integer, 2}]}.
    {move, {integer, 128}, {x, 0}}.
    {jump, {f, 546}}.
  {label, 545}.
    {test, is_eq_exact, {f, 547}, [{y, 7}, {integer, 3}]}.
    {move, {integer, 2048}, {x, 0}}.
    {jump, {f, 548}}.
  {label, 547}.
    {move, {integer, 65536}, {x, 0}}.
  {label, 548}.
  {label, 546}.
    {move, {x, 0}, {y, 11}}.
    {test, is_lt, {f, 550}, [{y, 8}, {y, 11}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 551}}.
  {label, 550}.
    {move, {atom, false}, {x, 0}}.
  {label, 551}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 552}, [{x, 1}, {atom, true}]}.
    {test, is_lt, {f, 554}, [{integer, 1114111}, {y, 8}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 555}}.
  {label, 554}.
    {move, {atom, false}, {x, 0}}.
  {label, 555}.
    {jump, {f, 553}}.
  {label, 552}.
    {move, {atom, true}, {x, 0}}.
  {label, 553}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 556}, [{x, 1}, {atom, true}]}.
    {test, is_ge, {f, 558}, [{y, 8}, {integer, 55296}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 559}}.
  {label, 558}.
    {move, {atom, false}, {x, 0}}.
  {label, 559}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 560}, [{x, 1}, {atom, true}]}.
    {test, is_ge, {f, 562}, [{integer, 57343}, {y, 8}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 563}}.
  {label, 562}.
    {move, {atom, false}, {x, 0}}.
  {label, 563}.
    {jump, {f, 561}}.
  {label, 560}.
    {move, {atom, false}, {x, 0}}.
  {label, 561}.
    {jump, {f, 557}}.
  {label, 556}.
    {move, {atom, true}, {x, 0}}.
  {label, 557}.
    {test, is_eq, {f, 549}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"not percent-encoded">>}, {x, 0}}.
    {call, 1, {f, 33}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 16}.
    return.
  {label, 549}.
    {move, {y, 8}, {x, 0}}.
    {call, 1, {f, 481}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, '*', {f, 0}, 0, [{integer, 3}, {y, 7}], {x, 0}}.
    {test, is_ge, {f, 564}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 564}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 565}}.
  {label, 564}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/encoding.bp:381:27">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 565}.
    {gc_bif, '+', {f, 0}, 1, [{y, 3}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 566}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 566}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 567}}.
  {label, 566}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/encoding.bp:381:23">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 567}.
    {move, {x, 0}, {y, 3}}.
  {label, 488}.
  {label, 477}.
    {jump, {f, 470}}.
  {label, 471}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call, 2, {f, 114}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 16}.
    return.
% The byte `%XX` at index `i` spells, or -1 when `i` holds no `%` followed by
% two hex digits.

{function, escapedByte, 2, 45}.
  {label, 44}.
    {line, [{location, "std@encoding.erl", 27}]}.
    {func_info, {atom, std@encoding}, {atom, escapedByte}, 2}.
  {label, 45}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 349}}.
    {test, is_ne_exact, {f, 569}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {jump, {f, 570}}.
  {label, 569}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 570}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"%">>}, {x, 0}}.
    {test, is_ne_exact, {f, 568}, [{x, 1}, {x, 0}]}.
    {move, {integer, -1}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 568}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 572}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 572}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 573}}.
  {label, 572}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/encoding.bp:392:31">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 573}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 349}}.
    {test, is_ne_exact, {f, 571}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {jump, {f, 574}}.
  {label, 571}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 574}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 576}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 576}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 577}}.
  {label, 576}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/encoding.bp:393:31">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 577}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 349}}.
    {test, is_ne_exact, {f, 575}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {jump, {f, 578}}.
  {label, 575}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 578}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 6}}.
    {test, is_lt, {f, 580}, [{y, 4}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 581}}.
  {label, 580}.
    {move, {atom, false}, {x, 0}}.
  {label, 581}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 582}, [{x, 1}, {atom, true}]}.
    {test, is_lt, {f, 584}, [{y, 6}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 585}}.
  {label, 584}.
    {move, {atom, false}, {x, 0}}.
  {label, 585}.
    {jump, {f, 583}}.
  {label, 582}.
    {move, {atom, true}, {x, 0}}.
  {label, 583}.
    {test, is_eq, {f, 579}, [{x, 0}, {atom, true}]}.
    {move, {integer, -1}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 579}.
    {gc_bif, '*', {f, 0}, 0, [{y, 4}, {integer, 16}], {x, 0}}.
    {test, is_ge, {f, 586}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 586}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 587}}.
  {label, 586}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/encoding.bp:395:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 587}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 6}], {x, 0}}.
    {test, is_ge, {f, 588}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 588}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 589}}.
  {label, 588}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/encoding.bp:395:20">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 589}.
    {deallocate, 7}.
    return.

{function, isUnreserved, 1, 47}.
  {label, 46}.
    {line, [{location, "std@encoding.erl", 28}]}.
    {func_info, {atom, std@encoding}, {atom, isUnreserved}, 1}.
  {label, 47}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_ge, {f, 590}, [{y, 0}, {integer, 65}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 591}}.
  {label, 590}.
    {move, {atom, false}, {x, 0}}.
  {label, 591}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 592}, [{x, 1}, {atom, true}]}.
    {test, is_ge, {f, 594}, [{integer, 90}, {y, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 595}}.
  {label, 594}.
    {move, {atom, false}, {x, 0}}.
  {label, 595}.
    {jump, {f, 593}}.
  {label, 592}.
    {move, {atom, false}, {x, 0}}.
  {label, 593}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 596}, [{x, 1}, {atom, true}]}.
    {test, is_ge, {f, 598}, [{y, 0}, {integer, 97}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 599}}.
  {label, 598}.
    {move, {atom, false}, {x, 0}}.
  {label, 599}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 600}, [{x, 1}, {atom, true}]}.
    {test, is_ge, {f, 602}, [{integer, 122}, {y, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 603}}.
  {label, 602}.
    {move, {atom, false}, {x, 0}}.
  {label, 603}.
    {jump, {f, 601}}.
  {label, 600}.
    {move, {atom, false}, {x, 0}}.
  {label, 601}.
    {jump, {f, 597}}.
  {label, 596}.
    {move, {atom, true}, {x, 0}}.
  {label, 597}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 604}, [{x, 1}, {atom, true}]}.
    {test, is_ge, {f, 606}, [{y, 0}, {integer, 48}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 607}}.
  {label, 606}.
    {move, {atom, false}, {x, 0}}.
  {label, 607}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 608}, [{x, 1}, {atom, true}]}.
    {test, is_ge, {f, 610}, [{integer, 57}, {y, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 611}}.
  {label, 610}.
    {move, {atom, false}, {x, 0}}.
  {label, 611}.
    {jump, {f, 609}}.
  {label, 608}.
    {move, {atom, false}, {x, 0}}.
  {label, 609}.
    {jump, {f, 605}}.
  {label, 604}.
    {move, {atom, true}, {x, 0}}.
  {label, 605}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 612}, [{x, 1}, {atom, true}]}.
    {test, is_eq_exact, {f, 614}, [{y, 0}, {integer, 45}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 615}}.
  {label, 614}.
    {move, {atom, false}, {x, 0}}.
  {label, 615}.
    {jump, {f, 613}}.
  {label, 612}.
    {move, {atom, true}, {x, 0}}.
  {label, 613}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 616}, [{x, 1}, {atom, true}]}.
    {test, is_eq_exact, {f, 618}, [{y, 0}, {integer, 46}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 619}}.
  {label, 618}.
    {move, {atom, false}, {x, 0}}.
  {label, 619}.
    {jump, {f, 617}}.
  {label, 616}.
    {move, {atom, true}, {x, 0}}.
  {label, 617}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 620}, [{x, 1}, {atom, true}]}.
    {test, is_eq_exact, {f, 622}, [{y, 0}, {integer, 95}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 623}}.
  {label, 622}.
    {move, {atom, false}, {x, 0}}.
  {label, 623}.
    {jump, {f, 621}}.
  {label, 620}.
    {move, {atom, true}, {x, 0}}.
  {label, 621}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 624}, [{x, 1}, {atom, true}]}.
    {test, is_eq_exact, {f, 626}, [{y, 0}, {integer, 126}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 627}}.
  {label, 626}.
    {move, {atom, false}, {x, 0}}.
  {label, 627}.
    {jump, {f, 625}}.
  {label, 624}.
    {move, {atom, true}, {x, 0}}.
  {label, 625}.
    {deallocate, 1}.
    return.
% ── bytes and text ──

{function, utf8Of, 1, 49}.
  {label, 48}.
    {line, [{location, "std@encoding.erl", 29}]}.
    {func_info, {atom, std@encoding}, {atom, utf8Of}, 1}.
  {label, 49}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 330}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 629}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_last, 1, {f, 631}, 4}.

{function, utf8Bytes, 1, 51}.
  {label, 50}.
    {line, [{location, "std@encoding.erl", 30}]}.
    {func_info, {atom, std@encoding}, {atom, utf8Bytes}, 1}.
  {label, 51}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_lt, {f, 632}, [{y, 0}, {integer, 128}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 632}.
    {test, is_lt, {f, 633}, [{y, 0}, {integer, 2048}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 0}, {integer, 64}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{integer, 128}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 634}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 634}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 635}}.
  {label, 634}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/encoding.bp:421:47">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 635}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 0}, {integer, 64}], {x, 0}}.
    {test, is_ge, {f, 636}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 636}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 637}}.
  {label, 636}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/encoding.bp:421:37">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 637}.
    {gc_bif, '+', {f, 0}, 1, [{integer, 192}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 638}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 638}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 639}}.
  {label, 638}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/encoding.bp:421:32">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 639}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 633}.
    {test, is_lt, {f, 640}, [{y, 0}, {integer, 65536}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 0}, {integer, 64}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{integer, 128}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 641}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 641}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 642}}.
  {label, 641}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/encoding.bp:423:60">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 642}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 0}, {integer, 64}], {x, 0}}.
    {test, is_ge, {f, 643}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 643}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 644}}.
  {label, 643}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/encoding.bp:423:44">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 644}.
    {gc_bif, 'rem', {f, 0}, 1, [{x, 0}, {integer, 64}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{integer, 128}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 645}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 645}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 646}}.
  {label, 645}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/encoding.bp:423:38">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 646}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 0}, {integer, 4096}], {x, 0}}.
    {test, is_ge, {f, 647}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 647}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 648}}.
  {label, 647}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/encoding.bp:423:26">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 648}.
    {gc_bif, '+', {f, 0}, 1, [{integer, 224}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 649}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 649}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 650}}.
  {label, 649}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/encoding.bp:423:21">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 650}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 640}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 0}, {integer, 64}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{integer, 128}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 651}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 651}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 652}}.
  {label, 651}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/encoding.bp:428:13">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 652}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 0}, {integer, 64}], {x, 0}}.
    {test, is_ge, {f, 653}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 653}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 654}}.
  {label, 653}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/encoding.bp:427:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 654}.
    {gc_bif, 'rem', {f, 0}, 1, [{x, 0}, {integer, 64}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{integer, 128}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 655}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 655}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 656}}.
  {label, 655}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/encoding.bp:427:13">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 656}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 0}, {integer, 4096}], {x, 0}}.
    {test, is_ge, {f, 657}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 657}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 658}}.
  {label, 657}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/encoding.bp:426:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 658}.
    {gc_bif, 'rem', {f, 0}, 1, [{x, 0}, {integer, 64}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{integer, 128}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 659}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 659}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 660}}.
  {label, 659}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/encoding.bp:426:13">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 660}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 0}, {integer, 262144}], {x, 0}}.
    {test, is_ge, {f, 661}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 661}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 662}}.
  {label, 661}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/encoding.bp:425:18">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 662}.
    {gc_bif, '+', {f, 0}, 1, [{integer, 240}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 663}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 663}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 664}}.
  {label, 663}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/encoding.bp:425:13">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 664}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 5}.
    return.
% `bytes` read as UTF-8 the way the WHATWG decoder (and so Node's
% `toString('utf8')`) reads them: a byte that cannot start a sequence, a
% sequence cut short, an overlong or surrogate form, and a sequence past
% U+10FFFF each answer U+FFFD for their maximal ill-formed subsequence.

{function, textOfUtf8, 1, 53}.
  {label, 52}.
    {line, [{location, "std@encoding.erl", 31}]}.
    {func_info, {atom, std@encoding}, {atom, textOfUtf8}, 1}.
  {label, 53}.
    {allocate, 20, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {integer, 128}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {integer, 191}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {line, [{location, "std@encoding.erl", 32}]}.
  {label, 665}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 666}, [{y, 7}, {x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {call, 2, {f, 349}}.
    {test, is_ne_exact, {f, 667}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {jump, {f, 668}}.
  {label, 667}.
    {move, {integer, 0}, {x, 0}}.
  {label, 668}.
    {move, {x, 0}, {y, 9}}.
    {test, is_eq_exact, {f, 669}, [{y, 2}, {integer, 0}]}.
    {test, is_lt, {f, 670}, [{y, 9}, {integer, 128}]}.
    {move, {y, 9}, {x, 0}}.
    {call, 1, {f, 481}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 1}}.
    {jump, {f, 671}}.
  {label, 670}.
    {test, is_ge, {f, 673}, [{y, 9}, {integer, 194}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 674}}.
  {label, 673}.
    {move, {atom, false}, {x, 0}}.
  {label, 674}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 675}, [{x, 1}, {atom, true}]}.
    {test, is_ge, {f, 677}, [{integer, 223}, {y, 9}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 678}}.
  {label, 677}.
    {move, {atom, false}, {x, 0}}.
  {label, 678}.
    {jump, {f, 676}}.
  {label, 675}.
    {move, {atom, false}, {x, 0}}.
  {label, 676}.
    {test, is_eq, {f, 672}, [{x, 0}, {atom, true}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 9}, {integer, 192}], {x, 0}}.
    {test, is_ge, {f, 679}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 679}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 680}}.
  {label, 679}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/encoding.bp:450:24">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 680}.
    {move, {x, 0}, {y, 4}}.
    {jump, {f, 681}}.
  {label, 672}.
    {test, is_ge, {f, 683}, [{y, 9}, {integer, 224}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 684}}.
  {label, 683}.
    {move, {atom, false}, {x, 0}}.
  {label, 684}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 685}, [{x, 1}, {atom, true}]}.
    {test, is_ge, {f, 687}, [{integer, 239}, {y, 9}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 688}}.
  {label, 687}.
    {move, {atom, false}, {x, 0}}.
  {label, 688}.
    {jump, {f, 686}}.
  {label, 685}.
    {move, {atom, false}, {x, 0}}.
  {label, 686}.
    {test, is_eq, {f, 682}, [{x, 0}, {atom, true}]}.
    {test, is_eq_exact, {f, 689}, [{y, 9}, {integer, 224}]}.
    {move, {integer, 160}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 690}}.
  {label, 689}.
  {label, 690}.
    {test, is_eq_exact, {f, 691}, [{y, 9}, {integer, 237}]}.
    {move, {integer, 159}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {jump, {f, 692}}.
  {label, 691}.
  {label, 692}.
    {move, {integer, 2}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 9}, {integer, 224}], {x, 0}}.
    {test, is_ge, {f, 693}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 693}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 694}}.
  {label, 693}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/encoding.bp:455:24">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 694}.
    {move, {x, 0}, {y, 4}}.
    {jump, {f, 695}}.
  {label, 682}.
    {test, is_ge, {f, 697}, [{y, 9}, {integer, 240}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 698}}.
  {label, 697}.
    {move, {atom, false}, {x, 0}}.
  {label, 698}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 699}, [{x, 1}, {atom, true}]}.
    {test, is_ge, {f, 701}, [{integer, 244}, {y, 9}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 702}}.
  {label, 701}.
    {move, {atom, false}, {x, 0}}.
  {label, 702}.
    {jump, {f, 700}}.
  {label, 699}.
    {move, {atom, false}, {x, 0}}.
  {label, 700}.
    {test, is_eq, {f, 696}, [{x, 0}, {atom, true}]}.
    {test, is_eq_exact, {f, 703}, [{y, 9}, {integer, 240}]}.
    {move, {integer, 144}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 704}}.
  {label, 703}.
  {label, 704}.
    {test, is_eq_exact, {f, 705}, [{y, 9}, {integer, 244}]}.
    {move, {integer, 143}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {jump, {f, 706}}.
  {label, 705}.
  {label, 706}.
    {move, {integer, 3}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 9}, {integer, 240}], {x, 0}}.
    {test, is_ge, {f, 707}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 707}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 708}}.
  {label, 707}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/encoding.bp:460:24">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 708}.
    {move, {x, 0}, {y, 4}}.
    {jump, {f, 709}}.
  {label, 696}.
    {move, {integer, 65533}, {x, 0}}.
    {call, 1, {f, 481}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 1}}.
  {label, 709}.
  {label, 695}.
  {label, 681}.
  {label, 671}.
    {gc_bif, '+', {f, 0}, 0, [{y, 7}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 710}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 710}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 711}}.
  {label, 710}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/encoding.bp:462:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 711}.
    {move, {x, 0}, {y, 7}}.
    {jump, {f, 712}}.
  {label, 669}.
    {test, is_lt, {f, 714}, [{y, 9}, {y, 5}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 715}}.
  {label, 714}.
    {move, {atom, false}, {x, 0}}.
  {label, 715}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 716}, [{x, 1}, {atom, true}]}.
    {test, is_lt, {f, 718}, [{y, 6}, {y, 9}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 719}}.
  {label, 718}.
    {move, {atom, false}, {x, 0}}.
  {label, 719}.
    {jump, {f, 717}}.
  {label, 716}.
    {move, {atom, true}, {x, 0}}.
  {label, 717}.
    {test, is_eq, {f, 713}, [{x, 0}, {atom, true}]}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {integer, 128}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {integer, 191}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {integer, 65533}, {x, 0}}.
    {call, 1, {f, 481}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 1}}.
    {jump, {f, 720}}.
  {label, 713}.
    {move, {integer, 128}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {integer, 191}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 4}, {integer, 64}], {x, 0}}.
    {test, is_ge, {f, 721}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 721}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 722}}.
  {label, 721}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/encoding.bp:473:21">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 722}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '-', {f, 0}, 2, [{y, 9}, {integer, 128}], {x, 0}}.
    {test, is_ge, {f, 723}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 723}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 724}}.
  {label, 723}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/encoding.bp:473:31">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 724}.
    {gc_bif, '+', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 725}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 725}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 726}}.
  {label, 725}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/encoding.bp:473:26">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 726}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 3}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 727}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 727}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 728}}.
  {label, 727}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/encoding.bp:474:25">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 728}.
    {move, {x, 0}, {y, 3}}.
    {test, is_eq_exact, {f, 729}, [{y, 3}, {y, 2}]}.
    {move, {y, 4}, {x, 0}}.
    {call, 1, {f, 481}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {jump, {f, 730}}.
  {label, 729}.
  {label, 730}.
    {gc_bif, '+', {f, 0}, 0, [{y, 7}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 731}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 731}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 732}}.
  {label, 731}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/encoding.bp:481:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 732}.
    {move, {x, 0}, {y, 7}}.
  {label, 720}.
  {label, 712}.
    {jump, {f, 665}}.
  {label, 666}.
    {test, is_ne_exact, {f, 733}, [{y, 2}, {integer, 0}]}.
    {move, {integer, 65533}, {x, 0}}.
    {call, 1, {f, 481}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 1}}.
    {jump, {f, 734}}.
  {label, 733}.
  {label, 734}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_last, 2, {f, 114}, 20}.

{function, base64Text, 1, 55}.
  {label, 54}.
    {line, [{location, "std@encoding.erl", 32}]}.
    {func_info, {atom, std@encoding}, {atom, base64Text}, 1}.
  {label, 55}.
    {allocate, 23, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}, {y, 20}, {y, 21}, {y, 22}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/">>}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {line, [{location, "std@encoding.erl", 33}]}.
  {label, 735}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 736}, [{y, 3}, {x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {y, 3}], {x, 0}}.
    {test, is_ge, {f, 737}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 737}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 738}}.
  {label, 737}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/encoding.bp:493:30">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 738}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call, 2, {f, 349}}.
    {test, is_ne_exact, {f, 739}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {jump, {f, 740}}.
  {label, 739}.
    {move, {integer, 0}, {x, 0}}.
  {label, 740}.
    {move, {x, 0}, {y, 6}}.
    {test, is_lt, {f, 741}, [{integer, 1}, {y, 4}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 3}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 744}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 744}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 745}}.
  {label, 744}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/encoding.bp:496:24">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 745}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 349}}.
    {test, is_ne_exact, {f, 743}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {jump, {f, 746}}.
  {label, 743}.
    {move, {integer, 0}, {x, 0}}.
  {label, 746}.
    {jump, {f, 742}}.
  {label, 741}.
    {move, {integer, 0}, {x, 0}}.
  {label, 742}.
    {move, {x, 0}, {y, 8}}.
    {test, is_lt, {f, 747}, [{integer, 2}, {y, 4}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 750}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 750}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 751}}.
  {label, 750}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/encoding.bp:499:24">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 751}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 349}}.
    {test, is_ne_exact, {f, 749}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {jump, {f, 752}}.
  {label, 749}.
    {move, {integer, 0}, {x, 0}}.
  {label, 752}.
    {jump, {f, 748}}.
  {label, 747}.
    {move, {integer, 0}, {x, 0}}.
  {label, 748}.
    {move, {x, 0}, {y, 10}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 6}, {integer, 4}], {x, 0}}.
    {test, is_ge, {f, 777}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 777}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 778}}.
  {label, 777}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/encoding.bp:501:33">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 778}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 755}}.
    {test, is_ne_exact, {f, 753}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {jump, {f, 779}}.
  {label, 753}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 779}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 6}, {integer, 4}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {integer, 16}], {x, 0}}.
    {test, is_ge, {f, 781}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 781}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 782}}.
  {label, 781}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/encoding.bp:502:39">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 782}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, 'div', {f, 0}, 2, [{y, 8}, {integer, 16}], {x, 0}}.
    {test, is_ge, {f, 783}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 783}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 784}}.
  {label, 783}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/encoding.bp:502:49">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 784}.
    {gc_bif, '+', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 785}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 785}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 786}}.
  {label, 785}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/encoding.bp:502:44">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 786}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 755}}.
    {test, is_ne_exact, {f, 780}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {x, 0}}.
    {jump, {f, 787}}.
  {label, 780}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 787}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 2}}.
    {test, is_lt, {f, 788}, [{integer, 1}, {y, 4}]}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 8}, {integer, 16}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {integer, 4}], {x, 0}}.
    {test, is_ge, {f, 791}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 791}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 792}}.
  {label, 791}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/encoding.bp:505:39">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 792}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, 'div', {f, 0}, 2, [{y, 10}, {integer, 64}], {x, 0}}.
    {test, is_ge, {f, 793}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 793}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 794}}.
  {label, 793}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/encoding.bp:505:48">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 794}.
    {gc_bif, '+', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 795}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 795}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 796}}.
  {label, 795}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/encoding.bp:505:43">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 796}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 755}}.
    {test, is_ne_exact, {f, 790}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {x, 0}}.
    {jump, {f, 797}}.
  {label, 790}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 797}.
    {jump, {f, 789}}.
  {label, 788}.
    {move, {literal, <<"=">>}, {x, 0}}.
  {label, 789}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 2}}.
    {test, is_lt, {f, 798}, [{integer, 2}, {y, 4}]}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 10}, {integer, 64}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 755}}.
    {test, is_ne_exact, {f, 800}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 14}, {x, 0}}.
    {jump, {f, 801}}.
  {label, 800}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 801}.
    {jump, {f, 799}}.
  {label, 798}.
    {move, {literal, <<"=">>}, {x, 0}}.
  {label, 799}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 3}, {integer, 3}], {x, 0}}.
    {test, is_ge, {f, 802}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 802}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 803}}.
  {label, 802}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/encoding.bp:513:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 803}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 735}}.
  {label, 736}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call_last, 2, {f, 114}, 23}.
% The value of one character of the `+/` alphabet, or -1.

{function, base64Value, 1, 57}.
  {label, 56}.
    {line, [{location, "std@encoding.erl", 33}]}.
    {func_info, {atom, std@encoding}, {atom, base64Value}, 1}.
  {label, 57}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 804}, [{y, 0}, {x, 0}]}.
    {move, {integer, -1}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 804}.
    {move, {literal, <<"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 306}, 1}.

{function, hexDigit, 1, 59}.
  {label, 58}.
    {line, [{location, "std@encoding.erl", 34}]}.
    {func_info, {atom, std@encoding}, {atom, hexDigit}, 1}.
  {label, 59}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"0123456789abcdef">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call, 2, {f, 755}}.
    {test, is_ne_exact, {f, 805}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {jump, {f, 806}}.
  {label, 805}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 806}.
    {deallocate, 2}.
    return.

{function, upperHexDigit, 1, 61}.
  {label, 60}.
    {line, [{location, "std@encoding.erl", 35}]}.
    {func_info, {atom, std@encoding}, {atom, upperHexDigit}, 1}.
  {label, 61}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"0123456789ABCDEF">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call, 2, {f, 755}}.
    {test, is_ne_exact, {f, 807}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {jump, {f, 808}}.
  {label, 807}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 808}.
    {deallocate, 2}.
    return.
% The value of one hex digit, either case, or -1.

{function, hexValue, 1, 63}.
  {label, 62}.
    {line, [{location, "std@encoding.erl", 36}]}.
    {func_info, {atom, std@encoding}, {atom, hexValue}, 1}.
  {label, 63}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 809}, [{y, 0}, {x, 0}]}.
    {move, {integer, -1}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 809}.
    {move, {literal, <<"0123456789abcdef">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call, 2, {f, 306}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_ge, {f, 810}, [{y, 1}, {integer, 0}]}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 810}.
    {move, {literal, <<"0123456789ABCDEF">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 306}, 2}.
% ── tests ────────────────────────────────────────────────────────────────────
% ── the tests of the retired `base64` module, over the names that replaced it ──

{function, 'string_slice', 3, 322}.
  {label, 321}.
    {line, [{location, "std@encoding.erl", 37}]}.
    {func_info, {atom, std@encoding}, {atom, 'string_slice'}, 3}.
  {label, 322}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test, is_ne_exact, {f, 811}, [{y, 2}, {atom, undefined}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 3, {f, 813}, 3}.
  {label, 811}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 2, {f, 835}, 3}.

{function, 'array_flatten', 1, 631}.
  {label, 630}.
    {line, [{location, "std@encoding.erl", 38}]}.
    {func_info, {atom, std@encoding}, {atom, 'array_flatten'}, 1}.
  {label, 631}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 852}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_priv__array_flatten', 1, 855}.
  {label, 854}.
    {line, [{location, "std@encoding.erl", 40}]}.
    {func_info, {atom, std@encoding}, {atom, '__bp_priv__array_flatten'}, 1}.
  {label, 855}.
    {call_only, 1, {f, 631}}.

{function, '__bp_priv__array_range', 2, 857}.
  {label, 856}.
    {line, [{location, "std@encoding.erl", 41}]}.
    {func_info, {atom, std@encoding}, {atom, '__bp_priv__array_range'}, 2}.
  {label, 857}.
    {call_only, 2, {f, 3}}.

{function, '__bp_priv__array_repeat', 2, 859}.
  {label, 858}.
    {line, [{location, "std@encoding.erl", 42}]}.
    {func_info, {atom, std@encoding}, {atom, '__bp_priv__array_repeat'}, 2}.
  {label, 859}.
    {call_only, 2, {f, 5}}.

{function, '__bp_priv__string_slice', 3, 861}.
  {label, 860}.
    {line, [{location, "std@encoding.erl", 43}]}.
    {func_info, {atom, std@encoding}, {atom, '__bp_priv__string_slice'}, 3}.
  {label, 861}.
    {call_only, 3, {f, 322}}.

{function, '__bp_priv__base64DecodeBody', 1, 863}.
  {label, 862}.
    {line, [{location, "std@encoding.erl", 44}]}.
    {func_info, {atom, std@encoding}, {atom, '__bp_priv__base64DecodeBody'}, 1}.
  {label, 863}.
    {call_only, 1, {f, 35}}.

{function, '__bp_priv__base64EncodeBody', 1, 865}.
  {label, 864}.
    {line, [{location, "std@encoding.erl", 45}]}.
    {func_info, {atom, std@encoding}, {atom, '__bp_priv__base64EncodeBody'}, 1}.
  {label, 865}.
    {call_only, 1, {f, 31}}.

{function, '__bp_priv__base64Text', 1, 867}.
  {label, 866}.
    {line, [{location, "std@encoding.erl", 46}]}.
    {func_info, {atom, std@encoding}, {atom, '__bp_priv__base64Text'}, 1}.
  {label, 867}.
    {call_only, 1, {f, 55}}.

{function, '__bp_priv__base64Value', 1, 869}.
  {label, 868}.
    {line, [{location, "std@encoding.erl", 47}]}.
    {func_info, {atom, std@encoding}, {atom, '__bp_priv__base64Value'}, 1}.
  {label, 869}.
    {call_only, 1, {f, 57}}.

{function, '__bp_priv__escapedByte', 2, 871}.
  {label, 870}.
    {line, [{location, "std@encoding.erl", 48}]}.
    {func_info, {atom, std@encoding}, {atom, '__bp_priv__escapedByte'}, 2}.
  {label, 871}.
    {call_only, 2, {f, 45}}.

{function, '__bp_priv__formDecode', 1, 873}.
  {label, 872}.
    {line, [{location, "std@encoding.erl", 49}]}.
    {func_info, {atom, std@encoding}, {atom, '__bp_priv__formDecode'}, 1}.
  {label, 873}.
    {call_only, 1, {f, 29}}.

{function, '__bp_priv__formField', 1, 875}.
  {label, 874}.
    {line, [{location, "std@encoding.erl", 50}]}.
    {func_info, {atom, std@encoding}, {atom, '__bp_priv__formField'}, 1}.
  {label, 875}.
    {call_only, 1, {f, 27}}.

{function, '__bp_priv__hexDecodeBody', 1, 877}.
  {label, 876}.
    {line, [{location, "std@encoding.erl", 51}]}.
    {func_info, {atom, std@encoding}, {atom, '__bp_priv__hexDecodeBody'}, 1}.
  {label, 877}.
    {call_only, 1, {f, 39}}.

{function, '__bp_priv__hexDigit', 1, 879}.
  {label, 878}.
    {line, [{location, "std@encoding.erl", 52}]}.
    {func_info, {atom, std@encoding}, {atom, '__bp_priv__hexDigit'}, 1}.
  {label, 879}.
    {call_only, 1, {f, 59}}.

{function, '__bp_priv__hexEncodeBody', 1, 881}.
  {label, 880}.
    {line, [{location, "std@encoding.erl", 53}]}.
    {func_info, {atom, std@encoding}, {atom, '__bp_priv__hexEncodeBody'}, 1}.
  {label, 881}.
    {call_only, 1, {f, 37}}.

{function, '__bp_priv__hexValue', 1, 883}.
  {label, 882}.
    {line, [{location, "std@encoding.erl", 54}]}.
    {func_info, {atom, std@encoding}, {atom, '__bp_priv__hexValue'}, 1}.
  {label, 883}.
    {call_only, 1, {f, 63}}.

{function, '__bp_priv__isUnreserved', 1, 885}.
  {label, 884}.
    {line, [{location, "std@encoding.erl", 55}]}.
    {func_info, {atom, std@encoding}, {atom, '__bp_priv__isUnreserved'}, 1}.
  {label, 885}.
    {call_only, 1, {f, 47}}.

{function, '__bp_priv__padToMultipleOfFour', 1, 887}.
  {label, 886}.
    {line, [{location, "std@encoding.erl", 56}]}.
    {func_info, {atom, std@encoding}, {atom, '__bp_priv__padToMultipleOfFour'}, 1}.
  {label, 887}.
    {call_only, 1, {f, 13}}.

{function, '__bp_priv__percentDecodeBody', 1, 889}.
  {label, 888}.
    {line, [{location, "std@encoding.erl", 57}]}.
    {func_info, {atom, std@encoding}, {atom, '__bp_priv__percentDecodeBody'}, 1}.
  {label, 889}.
    {call_only, 1, {f, 43}}.

{function, '__bp_priv__percentEncodeBody', 1, 891}.
  {label, 890}.
    {line, [{location, "std@encoding.erl", 58}]}.
    {func_info, {atom, std@encoding}, {atom, '__bp_priv__percentEncodeBody'}, 1}.
  {label, 891}.
    {call_only, 1, {f, 41}}.

{function, '__bp_priv__refused', 1, 893}.
  {label, 892}.
    {line, [{location, "std@encoding.erl", 59}]}.
    {func_info, {atom, std@encoding}, {atom, '__bp_priv__refused'}, 1}.
  {label, 893}.
    {call_only, 1, {f, 33}}.

{function, '__bp_priv__textOfUtf8', 1, 895}.
  {label, 894}.
    {line, [{location, "std@encoding.erl", 60}]}.
    {func_info, {atom, std@encoding}, {atom, '__bp_priv__textOfUtf8'}, 1}.
  {label, 895}.
    {call_only, 1, {f, 53}}.

{function, '__bp_priv__upperHexDigit', 1, 897}.
  {label, 896}.
    {line, [{location, "std@encoding.erl", 61}]}.
    {func_info, {atom, std@encoding}, {atom, '__bp_priv__upperHexDigit'}, 1}.
  {label, 897}.
    {call_only, 1, {f, 61}}.

{function, '__bp_priv__utf8Bytes', 1, 899}.
  {label, 898}.
    {line, [{location, "std@encoding.erl", 62}]}.
    {func_info, {atom, std@encoding}, {atom, '__bp_priv__utf8Bytes'}, 1}.
  {label, 899}.
    {call_only, 1, {f, 51}}.

{function, '__bp_priv__utf8Of', 1, 901}.
  {label, 900}.
    {line, [{location, "std@encoding.erl", 63}]}.
    {func_info, {atom, std@encoding}, {atom, '__bp_priv__utf8Of'}, 1}.
  {label, 901}.
    {call_only, 1, {f, 49}}.

{function, '__bp_tpl_0', 1, 67}.
  {label, 66}.
    {func_info, {atom, std@encoding}, {atom, '__bp_tpl_0'}, 1}.
  {label, 67}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, binary, encode_hex, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, string, lowercase, 1}, 2}.

{function, '__bp_tpl_1', 1, 87}.
  {label, 86}.
    {func_info, {atom, std@encoding}, {atom, '__bp_tpl_1'}, 1}.
  {label, 87}.
    {allocate, 12, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 3}}.
    {'try', {y, 11}, {f, 90}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, base64, decode, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 6}}.
    {try_end, {y, 11}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 93}, [{x, 0}]}.
    {test, test_arity, {f, 93}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 93}, [{x, 0}, {atom, ok}]}.
    {move, {y, 8}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 92}}.
  {label, 93}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 94}, [{x, 0}]}.
    {test, test_arity, {f, 94}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 94}, [{x, 0}, {atom, error}]}.
    {move, {y, 8}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 9}, {literal, <<"host">>}, {atom, std@failure@@HostErrorName__v__error}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 92}}.
  {label, 94}.
    {move, {y, 6}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 4}}.
    {jump, {f, 92}}.
  {label, 92}.
    {jump, {f, 91}}.
  {label, 90}.
    {try_case, {y, 11}}.
    {move, {x, 0}, {y, 5}}.
    {move, {x, 1}, {y, 6}}.
    {move, {x, 2}, {y, 7}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 7}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 99}, [{x, 0}, {atom, error}]}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {y, 9}}.
    {jump, {f, 98}}.
  {label, 99}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 100}, [{x, 0}, {atom, throw}]}.
    {move, {atom, std@failure@@HostErrorName__v__throw}, {y, 9}}.
    {jump, {f, 98}}.
  {label, 100}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 101}, [{x, 0}, {atom, exit}]}.
    {move, {atom, std@failure@@HostErrorName__v__exit}, {y, 9}}.
    {jump, {f, 98}}.
  {label, 101}.
    {move, {y, 0}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 98}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 8}, {literal, <<"host">>}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 8}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 4}}.
    {jump, {f, 96}}.
  {label, 96}.
  {label, 91}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_tpl_2-t/3-fun-0-', 3, 110}.
  {label, 109}.
    {func_info, {atom, std@encoding}, {atom, '__bp_tpl_2-t/3-fun-0-'}, 3}.
  {label, 110}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {literal, [global]}, {x, 3}}.
    {call_ext_last, 4, {extfunc, binary, replace, 4}, 3}.

{function, '__bp_tpl_2', 3, 106}.
  {label, 105}.
    {func_info, {atom, std@encoding}, {atom, '__bp_tpl_2'}, 3}.
  {label, 106}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 110}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 3}, {x, 3}}.
    {call_fun, 3}.
    {deallocate, 4}.
    return.

{function, '__bp_print', 1, 116}.
  {label, 115}.
    {line, [{location, "std@encoding.erl", 8}]}.
    {func_info, {atom, std@encoding}, {atom, '__bp_print'}, 1}.
  {label, 116}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 120}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 120}.
  {label, 119}.
    {line, [{location, "std@encoding.erl", 8}]}.
    {func_info, {atom, std@encoding}, {atom, '-bp_show_top-'}, 1}.
  {label, 120}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 118}}.

{function, '-bp_show_elem-', 1, 122}.
  {label, 121}.
    {line, [{location, "std@encoding.erl", 8}]}.
    {func_info, {atom, std@encoding}, {atom, '-bp_show_elem-'}, 1}.
  {label, 122}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 118}}.

{function, '__bp_show', 2, 118}.
  {label, 117}.
    {line, [{location, "std@encoding.erl", 8}]}.
    {func_info, {atom, std@encoding}, {atom, '__bp_show'}, 2}.
  {label, 118}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 130}, [{x, 0}]}.
    {test, is_eq, {f, 129}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 129}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 130}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 131}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 122}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 93}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 91}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 131}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 133}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 132}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 132}, [{x, 0}]}.
    {test, is_ne_exact, {f, 132}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 132}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 132}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 137}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 138}}.
  {label, 137}.
    {test, is_eq_exact, {f, 134}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 138}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 118}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 132}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 122}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 40}, {x, 0}, {x, 0}}.
    {put_list, {integer, 35}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 133}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 135}, [{x, 0}]}.
    {test, is_ne_exact, {f, 135}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 135}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 136}, [{x, 0}, {atom, undefined}]}.
  {label, 134}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 124}, 2}.
  {label, 135}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 136}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 124}.
  {label, 123}.
    {line, [{location, "std@encoding.erl", 8}]}.
    {func_info, {atom, std@encoding}, {atom, '__bp_tagged'}, 2}.
  {label, 124}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 139}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 139}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 139}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 140}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 126}, 3}.
  {label, 140}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 126}.
  {label, 125}.
    {line, [{location, "std@encoding.erl", 8}]}.
    {func_info, {atom, std@encoding}, {atom, '__bp_render'}, 1}.
  {label, 126}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 141}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 141}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 142}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 142}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 128}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {y, 1}, {x, 1}, {x, 1}}.
    {put_list, {integer, 40}, {x, 1}, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-bp_render_pair-', 1, 128}.
  {label, 127}.
    {line, [{location, "std@encoding.erl", 8}]}.
    {func_info, {atom, std@encoding}, {atom, '-bp_render_pair-'}, 1}.
  {label, 128}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 118}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 6, 1}.
    {put_list, {y, 1}, nil, {x, 1}}.
    {put_list, {literal, <<": ">>}, {x, 1}, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-bp_stringify-', 1, 144}.
  {label, 143}.
    {line, [{location, "std@encoding.erl", 8}]}.
    {func_info, {atom, std@encoding}, {atom, '-bp_stringify-'}, 1}.
  {label, 144}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 145}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 145}.
    {test, is_integer, {f, 146}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 146}.
    {call, 1, {f, 120}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.

{function, '-bp_join-', 2, 114}.
  {label, 113}.
    {line, [{location, "std@encoding.erl", 8}]}.
    {func_info, {atom, std@encoding}, {atom, '-bp_join-'}, 2}.
  {label, 114}.
    {allocate, 1, 2}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 144}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {call_ext_last, 1, {extfunc, erlang, iolist_to_binary, 1}, 1}.

{function, '__bp_tpl_3', 1, 148}.
  {label, 147}.
    {func_info, {atom, std@encoding}, {atom, '__bp_tpl_3'}, 1}.
  {label, 148}.
    {allocate, 12, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 3}}.
    {'try', {y, 11}, {f, 151}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, binary, decode_hex, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 6}}.
    {try_end, {y, 11}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 154}, [{x, 0}]}.
    {test, test_arity, {f, 154}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 154}, [{x, 0}, {atom, ok}]}.
    {move, {y, 8}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 153}}.
  {label, 154}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 155}, [{x, 0}]}.
    {test, test_arity, {f, 155}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 155}, [{x, 0}, {atom, error}]}.
    {move, {y, 8}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 9}, {literal, <<"host">>}, {atom, std@failure@@HostErrorName__v__error}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 153}}.
  {label, 155}.
    {move, {y, 6}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 4}}.
    {jump, {f, 153}}.
  {label, 153}.
    {jump, {f, 152}}.
  {label, 151}.
    {try_case, {y, 11}}.
    {move, {x, 0}, {y, 5}}.
    {move, {x, 1}, {y, 6}}.
    {move, {x, 2}, {y, 7}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 7}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 160}, [{x, 0}, {atom, error}]}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {y, 9}}.
    {jump, {f, 159}}.
  {label, 160}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 161}, [{x, 0}, {atom, throw}]}.
    {move, {atom, std@failure@@HostErrorName__v__throw}, {y, 9}}.
    {jump, {f, 159}}.
  {label, 161}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 162}, [{x, 0}, {atom, exit}]}.
    {move, {atom, std@failure@@HostErrorName__v__exit}, {y, 9}}.
    {jump, {f, 159}}.
  {label, 162}.
    {move, {y, 0}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 159}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 8}, {literal, <<"host">>}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 8}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 4}}.
    {jump, {f, 157}}.
  {label, 157}.
  {label, 152}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_tpl_4--t/1-fun-0--fun-1-', 1, 182}.
  {label, 181}.
    {func_info, {atom, std@encoding}, {atom, '__bp_tpl_4--t/1-fun-0--fun-1-'}, 1}.
  {label, 182}.
    {allocate, 10, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 65}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '>=', 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 185}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 90}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=<', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 2}}.
    {jump, {f, 187}}.
  {label, 185}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 186}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 2}}.
    {jump, {f, 187}}.
  {label, 186}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 3}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 187}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 188}, [{x, 0}, {atom, false}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 97}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '>=', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 191}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 122}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 4}}.
    {jump, {f, 193}}.
  {label, 191}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 192}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 4}}.
    {jump, {f, 193}}.
  {label, 192}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 5}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 193}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 194}, [{x, 0}, {atom, false}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 48}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '>=', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 197}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 57}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=<', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 6}}.
    {jump, {f, 199}}.
  {label, 197}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 198}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 6}}.
    {jump, {f, 199}}.
  {label, 198}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 7}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 199}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 200}, [{x, 0}, {atom, false}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 43}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 203}, [{x, 0}, {atom, false}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 47}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 7}}.
    {jump, {f, 205}}.
  {label, 203}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 204}, [{x, 0}, {atom, true}]}.
    {move, {atom, true}, {y, 7}}.
    {jump, {f, 205}}.
  {label, 204}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 8}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 205}.
    {move, {y, 7}, {y, 5}}.
    {jump, {f, 202}}.
  {label, 200}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 201}, [{x, 0}, {atom, true}]}.
    {move, {atom, true}, {y, 5}}.
    {jump, {f, 202}}.
  {label, 201}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 6}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 202}.
    {move, {y, 5}, {y, 3}}.
    {jump, {f, 196}}.
  {label, 194}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 195}, [{x, 0}, {atom, true}]}.
    {move, {atom, true}, {y, 3}}.
    {jump, {f, 196}}.
  {label, 195}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 4}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 196}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 190}}.
  {label, 188}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 189}, [{x, 0}, {atom, true}]}.
    {move, {atom, true}, {y, 1}}.
    {jump, {f, 190}}.
  {label, 189}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 2}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 190}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 10}.
    return.

{function, '__bp_tpl_4-t/1-fun-0-', 1, 171}.
  {label, 170}.
    {func_info, {atom, std@encoding}, {atom, '__bp_tpl_4-t/1-fun-0-'}, 1}.
  {label, 171}.
    {allocate, 7, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {atom, trailing}, {x, 1}}.
    {move, {literal, [61]}, {x, 2}}.
    {call_ext, 3, {extfunc, string, trim, 3}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 175}}.
  {label, 175}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, byte_size, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 177}}.
  {label, 177}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, 'rem', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 178}, [{x, 0}, {atom, true}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 182}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, binary_to_list, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, all, 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 3}}.
    {jump, {f, 180}}.
  {label, 178}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 179}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 3}}.
    {jump, {f, 180}}.
  {label, 179}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 4}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 180}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 207}, [{x, 0}, {atom, false}]}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 207}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 208}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 209}, [{x, 0}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, 'rem', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {integer, 4}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, 'rem', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"=">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, binary, copy, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_binary, {f, 209}, [{x, 0}]}.
    {test_heap, 4, 0}.
    {put_list, {y, 4}, nil, {x, 0}}.
    {put_list, {y, 0}, {x, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 210}}.
  {label, 209}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 210}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {jump, {f, 212}}.
  {label, 212}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, base64, decode, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 1}}.
    {jump, {f, 214}}.
  {label, 214}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, base64, encode, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 216}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 216}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 217}, [{x, 0}, {atom, false}]}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 217}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 208}.
    {move, {y, 3}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_4', 1, 167}.
  {label, 166}.
    {func_info, {atom, std@encoding}, {atom, '__bp_tpl_4'}, 1}.
  {label, 167}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 171}, 1, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_5--t/1-fun-0--fun-1-', 1, 231}.
  {label, 230}.
    {func_info, {atom, std@encoding}, {atom, '__bp_tpl_5--t/1-fun-0--fun-1-'}, 1}.
  {label, 231}.
    {allocate, 8, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 48}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '>=', 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 234}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 57}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=<', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 2}}.
    {jump, {f, 236}}.
  {label, 234}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 235}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 2}}.
    {jump, {f, 236}}.
  {label, 235}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 3}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 236}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 237}, [{x, 0}, {atom, false}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 65}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '>=', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 240}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 70}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 4}}.
    {jump, {f, 242}}.
  {label, 240}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 241}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 4}}.
    {jump, {f, 242}}.
  {label, 241}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 5}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 242}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 243}, [{x, 0}, {atom, false}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 97}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '>=', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 246}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 102}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=<', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 5}}.
    {jump, {f, 248}}.
  {label, 246}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 247}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 5}}.
    {jump, {f, 248}}.
  {label, 247}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 6}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 248}.
    {move, {y, 5}, {y, 3}}.
    {jump, {f, 245}}.
  {label, 243}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 244}, [{x, 0}, {atom, true}]}.
    {move, {atom, true}, {y, 3}}.
    {jump, {f, 245}}.
  {label, 244}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 4}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 245}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 239}}.
  {label, 237}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 238}, [{x, 0}, {atom, true}]}.
    {move, {atom, true}, {y, 1}}.
    {jump, {f, 239}}.
  {label, 238}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 2}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 239}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 8}.
    return.

{function, '__bp_tpl_5-t/1-fun-0-', 1, 224}.
  {label, 223}.
    {func_info, {atom, std@encoding}, {atom, '__bp_tpl_5-t/1-fun-0-'}, 1}.
  {label, 224}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, byte_size, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, 'rem', 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 227}, [{x, 0}, {atom, true}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 231}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, binary_to_list, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, all, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 229}}.
  {label, 227}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 228}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 1}}.
    {jump, {f, 229}}.
  {label, 228}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 2}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 229}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq_exact, {f, 250}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, binary, decode_hex, 1}, 5}.
  {label, 250}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq_exact, {f, 251}, [{x, 0}, {atom, false}]}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 251}.
    {move, {y, 1}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_5', 1, 220}.
  {label, 219}.
    {func_info, {atom, std@encoding}, {atom, '__bp_tpl_5'}, 1}.
  {label, 220}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 224}, 1, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_6-t/1-fun-0-', 1, 260}.
  {label, 259}.
    {func_info, {atom, std@encoding}, {atom, '__bp_tpl_6-t/1-fun-0-'}, 1}.
  {label, 260}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, uri_string, unquote, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 264}, [{x, 0}]}.
    {jump, {f, 265}}.
  {label, 265}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 264}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 3}.

{function, '__bp_tpl_6', 1, 254}.
  {label, 253}.
    {func_info, {atom, std@encoding}, {atom, '__bp_tpl_6'}, 1}.
  {label, 254}.
    {allocate, 12, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 3}}.
    {'try', {y, 11}, {f, 257}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 260}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 6}}.
    {try_end, {y, 11}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 268}, [{x, 0}]}.
    {test, test_arity, {f, 268}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 268}, [{x, 0}, {atom, ok}]}.
    {move, {y, 8}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 267}}.
  {label, 268}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 269}, [{x, 0}]}.
    {test, test_arity, {f, 269}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 269}, [{x, 0}, {atom, error}]}.
    {move, {y, 8}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 9}, {literal, <<"host">>}, {atom, std@failure@@HostErrorName__v__error}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 267}}.
  {label, 269}.
    {move, {y, 6}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 4}}.
    {jump, {f, 267}}.
  {label, 267}.
    {jump, {f, 258}}.
  {label, 257}.
    {try_case, {y, 11}}.
    {move, {x, 0}, {y, 5}}.
    {move, {x, 1}, {y, 6}}.
    {move, {x, 2}, {y, 7}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 7}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 274}, [{x, 0}, {atom, error}]}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {y, 9}}.
    {jump, {f, 273}}.
  {label, 274}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 275}, [{x, 0}, {atom, throw}]}.
    {move, {atom, std@failure@@HostErrorName__v__throw}, {y, 9}}.
    {jump, {f, 273}}.
  {label, 275}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 276}, [{x, 0}, {atom, exit}]}.
    {move, {atom, std@failure@@HostErrorName__v__exit}, {y, 9}}.
    {jump, {f, 273}}.
  {label, 276}.
    {move, {y, 0}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 273}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 8}, {literal, <<"host">>}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 8}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 4}}.
    {jump, {f, 271}}.
  {label, 271}.
  {label, 258}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '-formStringify/1-fun-0-', 1, 281}.
  {label, 280}.
    {line, [{location, "std@encoding.erl", 17}]}.
    {func_info, {atom, std@encoding}, {atom, '-formStringify/1-fun-0-'}, 1}.
  {label, 281}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {call_ext, 1, {extfunc, uri_string, quote, 1}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"=">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {call_ext, 1, {extfunc, uri_string, quote, 1}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 114}}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_7-t/2-fun-0-', 2, 287}.
  {label, 286}.
    {func_info, {atom, std@encoding}, {atom, '__bp_tpl_7-t/2-fun-0-'}, 2}.
  {label, 287}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 289}, [{x, 0}, {literal, <<"">>}]}.
    {move, nil, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {test, is_list, {f, 291}, [{x, 0}]}.
    {jump, {f, 292}}.
  {label, 291}.
    {test, is_tuple, {f, 293}, [{x, 0}]}.
    {test, test_arity, {f, 293}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 292}}.
  {label, 293}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 1}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 292}.
    {move, {x, 0}, {y, 4}}.
  {label, 294}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nonempty_list, {f, 295}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 5}, {y, 4}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_integer, {f, 297}, [{x, 0}]}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {test, is_binary, {f, 297}, [{x, 0}]}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 298}}.
  {label, 297}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 298}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, {y, 3}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 294}}.
  {label, 295}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nil, {f, 296}, [{x, 0}]}.
    {jump, {f, 290}}.
  {label, 296}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 4}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 290}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 289}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {move, {atom, all}, {x, 2}}.
    {call_ext_last, 3, {extfunc, string, split, 3}, 7}.

{function, '__bp_tpl_7', 2, 283}.
  {label, 282}.
    {func_info, {atom, std@encoding}, {atom, '__bp_tpl_7'}, 2}.
  {label, 283}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 287}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '-formParse/1-fun-1-', 1, 300}.
  {label, 299}.
    {line, [{location, "std@encoding.erl", 18}]}.
    {func_info, {atom, std@encoding}, {atom, '-formParse/1-fun-1-'}, 1}.
  {label, 300}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 301}, [{y, 0}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 302}}.
  {label, 301}.
    {move, {atom, false}, {x, 0}}.
  {label, 302}.
    {deallocate, 1}.
    return.

{function, '-formParse/1-fun-2-', 1, 304}.
  {label, 303}.
    {line, [{location, "std@encoding.erl", 18}]}.
    {func_info, {atom, std@encoding}, {atom, '-formParse/1-fun-2-'}, 1}.
  {label, 304}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 27}}.
    {deallocate, 1}.
    return.

{function, '__bp_tpl_8-t/2-fun-0-', 2, 310}.
  {label, 309}.
    {func_info, {atom, std@encoding}, {atom, '__bp_tpl_8-t/2-fun-0-'}, 2}.
  {label, 310}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 314}, [{x, 0}, {literal, <<"">>}]}.
    {move, {integer, 0}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 314}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, binary, match, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 317}, [{x, 0}, {atom, nomatch}]}.
    {move, {integer, -1}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 317}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 318}, [{x, 0}]}.
    {test, test_arity, {f, 318}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {move, {y, 0}, {x, 2}}.
    {call_ext, 3, {extfunc, binary, part, 3}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, length, 1}, 6}.
  {label, 318}.
    {move, {y, 3}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_8', 2, 306}.
  {label, 305}.
    {func_info, {atom, std@encoding}, {atom, '__bp_tpl_8'}, 2}.
  {label, 306}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 310}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_9', 1, 330}.
  {label, 329}.
    {func_info, {atom, std@encoding}, {atom, '__bp_tpl_9'}, 1}.
  {label, 330}.
    {allocate, 7, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, nil, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, utf8}, {x, 1}}.
    {call_ext, 2, {extfunc, unicode, characters_to_list, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 3}}.
  {label, 334}.
    {move, {y, 3}, {x, 0}}.
    {test, is_nonempty_list, {f, 335}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 5}, {y, 3}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_integer, {f, 337}, [{x, 0}]}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {test, is_binary, {f, 337}, [{x, 0}]}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 338}}.
  {label, 337}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 338}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, {y, 2}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 334}}.
  {label, 335}.
    {move, {y, 3}, {x, 0}}.
    {test, is_nil, {f, 336}, [{x, 0}]}.
    {jump, {f, 333}}.
  {label, 336}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 3}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 333}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 7}.
    return.

{function, '-bp_at-', 2, 349}.
  {label, 348}.
    {line, [{location, "std@encoding.erl", 23}]}.
    {func_info, {atom, std@encoding}, {atom, '-bp_at-'}, 2}.
  {label, 349}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 0}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {test, is_ge, {f, 351}, [{y, 0}, {integer, 0}]}.
    {test, is_lt, {f, 350}, [{y, 0}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 351}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 350}, [{x, 0}, {integer, 0}]}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 350}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-hexEncodeBody/1-fun-3-', 1, 426}.
  {label, 425}.
    {line, [{location, "std@encoding.erl", 24}]}.
    {func_info, {atom, std@encoding}, {atom, '-hexEncodeBody/1-fun-3-'}, 1}.
  {label, 426}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 0}, {integer, 16}], {x, 0}}.
    {call, 1, {f, 59}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 0}, {integer, 16}], {x, 0}}.
    {test, is_ge, {f, 427}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 427}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 428}}.
  {label, 427}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/encoding.bp:293:44">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 428}.
    {call, 1, {f, 59}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 144}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_10-t/2-fun-0-', 2, 459}.
  {label, 458}.
    {func_info, {atom, std@encoding}, {atom, '__bp_tpl_10-t/2-fun-0-'}, 2}.
  {label, 459}.
    {allocate, 5, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, utf8}, {x, 1}}.
    {call_ext, 2, {extfunc, unicode, characters_to_list, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 463}, 1, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test, is_lt, {f, 463}, [{x, 0}, {x, 1}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {test, is_ge, {f, 463}, [{x, 0}, {x, 1}]}.
    {jump, {f, 464}}.
  {label, 464}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 5}.
  {label, 463}.
    {move, {integer, -1}, {x, 0}}.
    {deallocate, 5}.
    return.

{function, '__bp_tpl_10', 2, 455}.
  {label, 454}.
    {func_info, {atom, std@encoding}, {atom, '__bp_tpl_10'}, 2}.
  {label, 455}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 459}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '-percentEncodeBody/1-fun-5-', 1, 467}.
  {label, 466}.
    {line, [{location, "std@encoding.erl", 26}]}.
    {func_info, {atom, std@encoding}, {atom, '-percentEncodeBody/1-fun-5-'}, 1}.
  {label, 467}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 0}, {integer, 16}], {x, 0}}.
    {call, 1, {f, 61}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 0}, {integer, 16}], {x, 0}}.
    {test, is_ge, {f, 468}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 468}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 469}}.
  {label, 468}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/encoding.bp:322:54">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 469}.
    {call, 1, {f, 61}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"%">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 144}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 2}.
    return.

{function, '-percentEncodeBody/1-fun-4-', 1, 452}.
  {label, 451}.
    {line, [{location, "std@encoding.erl", 26}]}.
    {func_info, {atom, std@encoding}, {atom, '-percentEncodeBody/1-fun-4-'}, 1}.
  {label, 452}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 455}}.
    {call, 1, {f, 47}}.
    {test, is_eq, {f, 453}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {jump, {f, 465}}.
  {label, 453}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 455}}.
    {call, 1, {f, 51}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 467}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 114}}.
  {label, 465}.
    {deallocate, 5}.
    return.

{function, '__bp_tpl_11', 1, 481}.
  {label, 480}.
    {func_info, {atom, std@encoding}, {atom, '__bp_tpl_11'}, 1}.
  {label, 481}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_integer, {f, 484}, [{x, 0}]}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {test, is_binary, {f, 484}, [{x, 0}]}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 485}}.
  {label, 484}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 485}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-utf8Of/1-fun-6-', 1, 629}.
  {label, 628}.
    {line, [{location, "std@encoding.erl", 30}]}.
    {func_info, {atom, std@encoding}, {atom, '-utf8Of/1-fun-6-'}, 1}.
  {label, 629}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 455}}.
    {call, 1, {f, 51}}.
    {deallocate, 1}.
    return.

{function, '__bp_tpl_12-t/2-fun-0-', 2, 759}.
  {label, 758}.
    {func_info, {atom, std@encoding}, {atom, '__bp_tpl_12-t/2-fun-0-'}, 2}.
  {label, 759}.
    {allocate, 8, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 0}}.
    {jump, {f, 763}}.
  {label, 763}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 1}}.
    {jump, {f, 765}}.
  {label, 765}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 767}, [{x, 0}, {atom, true}]}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 6}}.
    {jump, {f, 766}}.
  {label, 767}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 768}, [{x, 0}, {atom, false}]}.
    {move, {y, 4}, {y, 6}}.
    {jump, {f, 766}}.
  {label, 768}.
    {move, {y, 5}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 766}.
    {move, {y, 6}, {y, 2}}.
    {jump, {f, 770}}.
  {label, 770}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '>=', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 771}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 5}}.
    {jump, {f, 773}}.
  {label, 771}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 772}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 5}}.
    {jump, {f, 773}}.
  {label, 772}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 6}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 773}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 775}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nth, 2}}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, nil, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 8}.
  {label, 775}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 776}, [{x, 0}, {atom, false}]}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 776}.
    {move, {y, 5}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_12', 2, 755}.
  {label, 754}.
    {func_info, {atom, std@encoding}, {atom, '__bp_tpl_12'}, 2}.
  {label, 755}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 759}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_13-t/3-fun-0-', 3, 817}.
  {label, 816}.
    {func_info, {atom, std@encoding}, {atom, '__bp_tpl_13-t/3-fun-0-'}, 3}.
  {label, 817}.
    {allocate, 9, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {move, {x, 2}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 0}}.
    {jump, {f, 821}}.
  {label, 821}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 1}}.
    {jump, {f, 823}}.
  {label, 823}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 825}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 824}}.
  {label, 825}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 826}, [{x, 0}, {atom, false}]}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 824}}.
  {label, 826}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 824}.
    {move, {y, 7}, {y, 2}}.
    {jump, {f, 828}}.
  {label, 828}.
    {move, {y, 5}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 830}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 829}}.
  {label, 830}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 831}, [{x, 0}, {atom, false}]}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 829}}.
  {label, 831}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 829}.
    {move, {y, 7}, {y, 1}}.
    {jump, {f, 833}}.
  {label, 833}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {move, {y, 7}, {x, 2}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 9}.

{function, '__bp_tpl_13', 3, 813}.
  {label, 812}.
    {func_info, {atom, std@encoding}, {atom, '__bp_tpl_13'}, 3}.
  {label, 813}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 817}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 3}, {x, 3}}.
    {call_fun, 3}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_14-t/2-fun-0-', 2, 839}.
  {label, 838}.
    {func_info, {atom, std@encoding}, {atom, '__bp_tpl_14-t/2-fun-0-'}, 2}.
  {label, 839}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {jump, {f, 843}}.
  {label, 843}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 1}}.
    {jump, {f, 845}}.
  {label, 845}.
    {move, {y, 3}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 847}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 846}}.
  {label, 847}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 848}, [{x, 0}, {atom, false}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 846}}.
  {label, 848}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 846}.
    {move, {y, 5}, {y, 1}}.
    {jump, {f, 850}}.
  {label, 850}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 7}.

{function, '__bp_tpl_14', 2, 835}.
  {label, 834}.
    {func_info, {atom, std@encoding}, {atom, '__bp_tpl_14'}, 2}.
  {label, 835}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 839}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '-flatten/1-fun-7-', 2, 852}.
  {label, 851}.
    {line, [{location, "std@encoding.erl", 39}]}.
    {func_info, {atom, std@encoding}, {atom, '-flatten/1-fun-7-'}, 2}.
  {label, 852}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call, 2, {f, 81}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_prim_append', 2, 81}.
  {label, 80}.
    {line, [{location, "std@encoding.erl", 39}]}.
    {func_info, {atom, std@encoding}, {atom, '__bp_prim_append'}, 2}.
  {label, 81}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 853}, [{x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, append, 2}, 2}.
  {label, 853}.
    %% unresolved_method: append/2
    {move, {literal, {unresolved_method, append, 2}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {deallocate, 2}.
    return.
