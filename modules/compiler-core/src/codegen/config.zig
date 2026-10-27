const std = @import("std");
const levelB = @import("../comptime/level_b.zig");
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
    /// component is ever run. Set by `run` over a `.bpr`; `build` (null)
    /// emits every unit.
    wasm_entry_only: ?[]const u8 = null,

    /// The code cache's level B (144 B-60): where the comptime pass reads a
    /// dependency's analysis from and hands the entries it analysed to — the
    /// CLI's analysis store. Null analyses everything and stores nothing.
    analysis_store: ?*@import("../comptime/level_b.zig").Store = null,
    /// The CODE of the compile's level B entries (144 B-60 S4), set by
    /// `codegen.generateWith` under every command that emits, `test_mode`
    /// too (decision 513: a dependency's unit is the same bytes under
    /// `botopink test`, and a test unit is never cached): an emitter takes a dependency
    /// module's unit from it (`cachedUnit`) instead of emitting the module,
    /// and gives a module whose entry lacks CODE everything CODE holds
    /// (`recordsCode`). Null: emit every module.
    level_b_code: ?*levelB.Code = null,

    /// The unit of module `name` read back from its entry's CODE, owned by
    /// `alloc`, or null: emit it. An emitter asks right where it would emit
    /// the module, after the program's own refusals (an atom fault, an
    /// ambiguous import) — those are the program's, never the entry's.
    pub fn cachedUnit(self: Config, alloc: std.mem.Allocator, name: []const u8) !?@import("moduleOutput.zig").GenerateResult {
        const code = self.level_b_code orelse return null;
        return code.take(alloc, name, self.codeEmit());
    }

    /// Whether module `name`'s unit is to be written into its entry's CODE.
    pub fn recordsCode(self: Config, name: []const u8) bool {
        const code = self.level_b_code orelse return false;
        return code.records(name);
    }

    pub fn codeEmit(self: Config) levelB.Code.Emit {
        return .{ .wasm_artifact = self.wasm_artifact, .typedef = self.typeDefLanguage != null };
    }
};
