-module(std@io@fs@@FsError).
-export([message/1, '__bp_format'/1]).

message(Self) ->
    case Self of
        {std@io@fs@@FsError__v__notfound, Path} ->
            <<"not found: ", ('__bp_text'(Path))/binary>>;
        {std@io@fs@@FsError__v__permissiondenied, Path@1} ->
            <<"permission denied: ", ('__bp_text'(Path@1))/binary>>;
        {std@io@fs@@FsError__v__isdirectory, Path@2} ->
            <<"is a directory: ", ('__bp_text'(Path@2))/binary>>;
        {std@io@fs@@FsError__v__notdirectory, Path@3} ->
            <<"not a directory: ", ('__bp_text'(Path@3))/binary>>;
        {std@io@fs@@FsError__v__alreadyexists, Path@4} ->
            <<"already exists: ", ('__bp_text'(Path@4))/binary>>;
        {std@io@fs@@FsError__v__invalidutf8, Path@5, Offset} ->
            <<"not UTF-8: ", ('__bp_text'(Path@5))/binary, " at byte ", ('__bp_text'(erlang:integer_to_binary(Offset)))/binary>>;
        {std@io@fs@@FsError__v__other, Path@6, Message} ->
            <<('__bp_text'(Path@6))/binary, ": ", ('__bp_text'(Message))/binary>>
    end.

'__bp_format'({std@io@fs@@FsError__v__notfound, F0}) -> {variant, "FsError.NotFound", [{"path", F0}]};
'__bp_format'({std@io@fs@@FsError__v__permissiondenied, F0}) -> {variant, "FsError.PermissionDenied", [{"path", F0}]};
'__bp_format'({std@io@fs@@FsError__v__isdirectory, F0}) -> {variant, "FsError.IsDirectory", [{"path", F0}]};
'__bp_format'({std@io@fs@@FsError__v__notdirectory, F0}) -> {variant, "FsError.NotDirectory", [{"path", F0}]};
'__bp_format'({std@io@fs@@FsError__v__alreadyexists, F0}) -> {variant, "FsError.AlreadyExists", [{"path", F0}]};
'__bp_format'({std@io@fs@@FsError__v__invalidutf8, F0, F1}) -> {variant, "FsError.InvalidUtf8", [{"path", F0}, {"offset", F1}]};
'__bp_format'({std@io@fs@@FsError__v__other, F0, F1}) -> {variant, "FsError.Other", [{"path", F0}, {"message", F1}]}.

'__bp_text'(Value) when erlang:is_binary(Value) -> Value;
'__bp_text'(Value) -> unicode:characters_to_binary('__bp_show'(Value, true)).

'__bp_show'(V, true) when erlang:is_binary(V) -> V;
'__bp_show'(V, _) when erlang:is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when erlang:is_list(V) -> [$[, lists:join(", ", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'({ok, P}, _) -> ["Ok(", '__bp_show'(P, false), $)];
'__bp_show'({error, P}, _) -> ["Error(", '__bp_show'(P, false), $)];
'__bp_show'(V, _) when erlang:is_tuple(V), erlang:tuple_size(V) > 0, erlang:is_atom(erlang:element(1, V)), erlang:element(1, V) =/= true, erlang:element(1, V) =/= false, erlang:element(1, V) =/= undefined -> '__bp_tagged'(erlang:element(1, V), V);
'__bp_show'(V, _) when erlang:is_tuple(V) -> ["#(", lists:join(", ", ['__bp_show'(E, false) || E <- erlang:tuple_to_list(V)]), $)];
'__bp_show'(undefined, _) -> "null";
'__bp_show'(V, _) when erlang:is_atom(V), V =/= true, V =/= false, V =/= undefined -> '__bp_tagged'(V, V);
'__bp_show'(V, _) -> io_lib:format("~p", [V]).

'__bp_tagged'(A, V) ->
    M = case string:split(erlang:atom_to_list(A), "__v__") of [P, _] -> erlang:list_to_atom(P); _ -> A end,
    case code:ensure_loaded(M) =:= {module, M} andalso erlang:function_exported(M, '__bp_format', 1) of true -> '__bp_render'(erlang:apply(M, '__bp_format', [V])); false -> io_lib:format("~p", [V]) end.

'__bp_render'({text, T}) -> T;
'__bp_render'({variant, N, []}) -> N;
'__bp_render'({_, N, Fs}) -> [N, $(, lists:join(", ", [[K, ": ", '__bp_show'(Val, false)] || {K, Val} <- Fs]), $)].
