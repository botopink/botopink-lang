const std = @import("std");
const unitCache = @import("./unit_cache.zig");
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

    /// Which package owns each module (decision 109): the root package's
    /// `botopink.json` `name` and the dependencies loaded beside it. The
    /// erlang and BEAM module atoms start with it. The default is a
    /// compilation with no manifest, whose modules are `bp`'s.
    packages: @import("crossModule.zig").Packages = .{},

    /// Decision 334 — the runtime a wasm build binds to (`botopink.json`'s
    /// `"wasm": { "host": … }`, read by the CLI): `wasi` (wasmtime, WASI
    /// preview 2), the default, or `browser` (JS imports, JSPI). It picks which
    /// `#[@External.Wasm(…, host: …)]` binding a `declare fn` lowers to.
    /// Read on the wasm target only.
    wasm_host: @import("../ast.zig").WasmHost = .wasi,

    /// Emit the wasm build's artifact rather than the bare module: on the
    /// `wasi` host the module wrapped as a WASI preview 2 component
    /// (`wat_emitter.renderComponent`, decision 334). Set by the CLI's build
    /// (`botopink build` / `run`); the snapshot harness records the module
    /// the backend lowers, so it leaves it off.
    wasm_artifact: bool = false,
    /// Decision 1008 (3) — wasm emits only this module, the program's entry:
    /// its component links every body it reaches, so no other module's
    /// component is ever run. Set by `build` and `run` on wasm (decision
    /// 1017 (5)); null (a package with no such module, other targets) emits every unit.
    wasm_entry_only: ?[]const u8 = null,

    /// The code cache's level B (144 B-60): where the comptime pass reads a
    /// dependency's analysis from and hands the entries it analysed to — the
    /// CLI's analysis store. Null analyses everything and stores nothing.
    analysis_store: ?*@import("../comptime/level_b.zig").Store = null,
    /// The unit cache (decision 1008 (2), `unit_cache.zig`): an emitter takes
    /// a dependency module's unit from it (`cachedUnit`) instead of emitting
    /// the module. Set by the CLI under every command that emits; null emits
    /// every module.
    unit_cache: ?*unitCache.UnitCache = null,

    /// The unit of module `name` read back from the unit cache, owned by
    /// `alloc`, or null: emit it. An emitter asks right where it would emit
    /// the module, after the program's own refusals (an atom fault, an
    /// ambiguous import) — those are the program's, never the cache's.
    pub fn cachedUnit(self: Config, alloc: std.mem.Allocator, name: []const u8) !?@import("moduleOutput.zig").GenerateResult {
        const cache = self.unit_cache orelse return null;
        return cache.take(alloc, name, self.codeEmit());
    }

    pub fn codeEmit(self: Config) unitCache.Emit {
        return .{ .wasm_artifact = self.wasm_artifact, .typedef = self.typeDefLanguage != null };
    }
};
