-module(std@encoding@@EncodingError).
-export(['__bp_format'/1]).

'__bp_format'(std@encoding@@EncodingError__v__notbase64) -> {variant, "EncodingError.NotBase64", []};
'__bp_format'(std@encoding@@EncodingError__v__nothex) -> {variant, "EncodingError.NotHex", []};
'__bp_format'(std@encoding@@EncodingError__v__notpercentencoded) -> {variant, "EncodingError.NotPercentEncoded", []}.
