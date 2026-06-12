/// Target module source emitted by the code generator.
pub const TargetSource = enum {
    commonJS,
    erlang,
    /// BEAM Assembly (`.S`) — the textual form produced by `erlc +to_asm`.
    beam,
    /// WebAssembly Text format (`.wat`) — target name is `wasm`.
    wasm,
    // esm,
    // iife,
};

/// Language used for generated type definitions.
pub const TypeDefLang = enum {
    typescript,
};

/// Top-level codegen configuration.
///
/// Note: pre-v0.beta.21 this struct carried a `comptimeRuntime` field selecting
/// one of four backends (node/erlang/wasm/beam). The four-runtime architecture
/// was retired by the `wasm3-unified-runtime` spec; every comptime val
/// expression now runs through the embedded wasm3 interpreter, so the field
/// became dead weight and was removed.
pub const Config = struct {
    /// Module source of the generated code.
    targetSource: TargetSource = .commonJS,

    /// Language for type definitions. If null, no types are generated.
    typeDefLanguage: ?TypeDefLang = null,

    /// Build root path for comptime scripts (e.g. `.botopinkbuild/<test_name>`).
    /// If null, defaults to `.botopinkbuild/<module_name>`.
    build_root: ?[]const u8 = null,

    /// Compile in test mode (`botopink test`): top-level `test { … }` blocks
    /// are emitted as functions plus a registry + runner entry, `assert`
    /// lowers to a throwing helper, and `fn main/0` is not auto-invoked.
    test_mode: bool = false,
};
