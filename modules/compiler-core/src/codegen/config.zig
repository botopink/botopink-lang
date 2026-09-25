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

/// The VM a compilation's decorator and template bodies run on (front 18,
/// `comptime/runtime/runtime.zig`): the BEAM (`persistent_erl.zig`) or wasm3
/// (`persistent_wat.zig`).
pub const ComptimeRuntime = enum { beam, wat };

/// Top-level codegen configuration.
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

    /// Which runtime evaluates this generation's decorators and templates.
    /// Null — every driver — is decision 84: the target's VM (erlang/beam →
    /// beam, commonJS/wasm → wat). Set only where one process generates the
    /// same program under both runtimes (the codegen snapshot harness's
    /// doubled tree); there is no flag or build option that reaches it.
    comptime_runtime: ?ComptimeRuntime = null,
};
