-module(std@unicode@@NormalizationForm).
-export(['__bp_format'/1]).

'__bp_format'(std@unicode@@NormalizationForm__v__nfc) -> {variant, "NormalizationForm.NFC", []};
'__bp_format'(std@unicode@@NormalizationForm__v__nfd) -> {variant, "NormalizationForm.NFD", []};
'__bp_format'(std@unicode@@NormalizationForm__v__nfkc) -> {variant, "NormalizationForm.NFKC", []};
'__bp_format'(std@unicode@@NormalizationForm__v__nfkd) -> {variant, "NormalizationForm.NFKD", []}.
