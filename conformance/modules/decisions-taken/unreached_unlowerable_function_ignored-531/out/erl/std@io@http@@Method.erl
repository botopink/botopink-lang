-module(std@io@http@@Method).
-export([verb/1, '__bp_format'/1]).

verb(Self) ->
    case Self of
        std@io@http@@Method__v__get ->
            <<"GET">>;
        std@io@http@@Method__v__post ->
            <<"POST">>;
        std@io@http@@Method__v__put ->
            <<"PUT">>;
        std@io@http@@Method__v__delete ->
            <<"DELETE">>;
        std@io@http@@Method__v__patch ->
            <<"PATCH">>;
        std@io@http@@Method__v__head ->
            <<"HEAD">>;
        std@io@http@@Method__v__options ->
            <<"OPTIONS">>
    end.

'__bp_format'(std@io@http@@Method__v__get) -> {variant, "Method.Get", []};
'__bp_format'(std@io@http@@Method__v__post) -> {variant, "Method.Post", []};
'__bp_format'(std@io@http@@Method__v__put) -> {variant, "Method.Put", []};
'__bp_format'(std@io@http@@Method__v__delete) -> {variant, "Method.Delete", []};
'__bp_format'(std@io@http@@Method__v__patch) -> {variant, "Method.Patch", []};
'__bp_format'(std@io@http@@Method__v__head) -> {variant, "Method.Head", []};
'__bp_format'(std@io@http@@Method__v__options) -> {variant, "Method.Options", []}.
