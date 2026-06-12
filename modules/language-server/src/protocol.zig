/// LSP protocol types — structs for JSON serialization/deserialization.
///
/// Only the types required for Phase 1-3 features are defined here.
/// All optional fields use `?T` so they are omitted by `std.json`
/// when `.emit_null_optional_fields = false`.
const std = @import("std");

// ── Position and Range ────────────────────────────────────────────────────────

/// Position in a text document (0-based line, 0-based character/UTF-16 offset).
pub const Position = struct {
    line: u32,
    character: u32,
};

pub const Range = struct {
    start: Position,
    end: Position,
};

pub const Location = struct {
    uri: []const u8,
    range: Range,
};

// ── Diagnostics ───────────────────────────────────────────────────────────────

pub const DiagnosticSeverity = struct {
    pub const Error: u32 = 1;
    pub const Warning: u32 = 2;
    pub const Information: u32 = 3;
    pub const Hint: u32 = 4;
};

pub const Diagnostic = struct {
    range: Range,
    severity: ?u32 = null,
    message: []const u8,
    source: ?[]const u8 = null,
};

pub const PublishDiagnosticsParams = struct {
    uri: []const u8,
    diagnostics: []const Diagnostic,
};

// ── TextEdits ─────────────────────────────────────────────────────────────────

pub const TextEdit = struct {
    range: Range,
    newText: []const u8,
};

// ── Hover ─────────────────────────────────────────────────────────────────────

pub const MarkupKind = struct {
    pub const PlainText = "plaintext";
    pub const Markdown = "markdown";
};

pub const MarkupContent = struct {
    kind: []const u8,
    value: []const u8,
};

pub const Hover = struct {
    contents: MarkupContent,
    range: ?Range = null,
};

// ── Document Symbols ──────────────────────────────────────────────────────────

pub const SymbolKind = struct {
    pub const File: u32 = 1;
    pub const Module: u32 = 2;
    pub const Namespace: u32 = 3;
    pub const Method: u32 = 6;
    pub const Function: u32 = 12;
    pub const Variable: u32 = 13;
    pub const Constant: u32 = 14;
    pub const Struct: u32 = 23;
    pub const Enum: u32 = 10;
    pub const Interface: u32 = 11;
    pub const EnumMember: u32 = 22;
};

pub const DocumentSymbol = struct {
    name: []const u8,
    kind: u32,
    range: Range,
    selectionRange: Range,
    children: ?[]const DocumentSymbol = null,
};

// ── Completion ────────────────────────────────────────────────────────────────

pub const CompletionItemKind = struct {
    pub const Text: u32 = 1;
    pub const Method: u32 = 2;
    pub const Function: u32 = 3;
    pub const Constructor: u32 = 4;
    pub const Field: u32 = 5;
    pub const Variable: u32 = 6;
    pub const Class: u32 = 7;
    pub const Interface: u32 = 8;
    pub const Module: u32 = 9;
    pub const Property: u32 = 10;
    pub const Enum: u32 = 13;
    pub const Keyword: u32 = 14;
    pub const EnumMember: u32 = 20;
    pub const Struct: u32 = 22;
};

pub const CompletionItem = struct {
    label: []const u8,
    kind: ?u32 = null,
    detail: ?[]const u8 = null,
    documentation: ?MarkupContent = null,
    insertText: ?[]const u8 = null,
    sortText: ?[]const u8 = null,
};

pub const CompletionList = struct {
    isIncomplete: bool = false,
    items: []const CompletionItem,
};

// ── Rename ────────────────────────────────────────────────────────────────────

/// Maps file URI → list of edits to apply in that file.
pub const WorkspaceEdit = struct {
    changes: ?std.json.Value = null,
};

// ── Initialize ────────────────────────────────────────────────────────────────

pub const TextDocumentSyncKind = struct {
    pub const None: u32 = 0;
    pub const Full: u32 = 1;
    pub const Incremental: u32 = 2;
};

pub const TextDocumentSyncOptions = struct {
    openClose: bool = true,
    change: u32 = TextDocumentSyncKind.Full,
    save: bool = true,
};

pub const ServerCapabilities = struct {
    textDocumentSync: TextDocumentSyncOptions = .{},
    hoverProvider: bool = false,
    definitionProvider: bool = false,
    typeDefinitionProvider: bool = false,
    documentFormattingProvider: bool = false,
    documentSymbolProvider: bool = false,
    completionProvider: ?CompletionOptions = null,
    referencesProvider: bool = false,
    renameProvider: ?RenameOptions = null,
    diagnosticProvider: ?DiagnosticOptions = null,
    signatureHelpProvider: ?SignatureHelpOptions = null,
    inlayHintProvider: bool = false,
    codeActionProvider: bool = false,
    foldingRangeProvider: bool = false,
    semanticTokensProvider: ?SemanticTokensOptions = null,
};

pub const CompletionOptions = struct {
    triggerCharacters: ?[]const []const u8 = null,
    resolveProvider: bool = false,
};

pub const DiagnosticOptions = struct {
    interFileDependencies: bool = true,
    workspaceDiagnostics: bool = false,
};

pub const ServerInfo = struct {
    name: []const u8,
    version: []const u8,
};

pub const InitializeResult = struct {
    capabilities: ServerCapabilities,
    serverInfo: ServerInfo,
};

// ── Signature Help ────────────────────────────────────────────────────────────

pub const SignatureHelpOptions = struct {
    triggerCharacters: ?[]const []const u8 = null,
    retriggerCharacters: ?[]const []const u8 = null,
};

pub const ParameterInformation = struct {
    label: []const u8,
};

pub const SignatureInformation = struct {
    label: []const u8,
    documentation: ?MarkupContent = null,
    parameters: ?[]const ParameterInformation = null,
    activeParameter: ?u32 = null,
};

pub const SignatureHelp = struct {
    signatures: []const SignatureInformation,
    activeSignature: ?u32 = null,
    activeParameter: ?u32 = null,
};

// ── Inlay Hints ───────────────────────────────────────────────────────────────

pub const InlayHintKind = struct {
    pub const Type: u32 = 1;
    pub const Parameter: u32 = 2;
};

pub const InlayHint = struct {
    position: Position,
    label: []const u8,
    kind: ?u32 = null,
    paddingLeft: ?bool = null,
    paddingRight: ?bool = null,
};

// ── Semantic Tokens ───────────────────────────────────────────────────────────

/// Token-type indices. The order **defines** the legend advertised to the
/// client — never reorder without bumping the legend below in lockstep.
pub const SemanticTokenTypes = struct {
    pub const type_: u32 = 0;
    pub const interface: u32 = 1;
    pub const @"enum": u32 = 2;
    pub const enumMember: u32 = 3;
    pub const function: u32 = 4;
    pub const method: u32 = 5;
    pub const parameter: u32 = 6;
    pub const variable: u32 = 7;
    pub const property: u32 = 8;
    pub const keyword: u32 = 9;
    pub const comment: u32 = 10;
    // Indices 11–13 carry sub-language (`@ExprCustom`) `CustomNode.label`s that
    // have no first-class botopink token — `string`/`number`/`operator` content
    // inside an embedded query/markup literal (sublanguage-lsp). Appended after
    // `comment` so the existing indices above never shift.
    pub const string: u32 = 11;
    pub const number: u32 = 12;
    pub const operator: u32 = 13;

    /// Legend, in index order — advertised in `SemanticTokensLegend.tokenTypes`.
    pub const legend = [_][]const u8{
        "type",      "interface", "enum",     "enumMember", "function", "method",
        "parameter", "variable",  "property", "keyword",    "comment",  "string",
        "number",    "operator",
    };
};

/// Token-modifier bit flags. Combined into a bitmask per token.
pub const SemanticTokenModifiers = struct {
    pub const declaration: u32 = 1 << 0;
    pub const readonly: u32 = 1 << 1;
    pub const defaultLibrary: u32 = 1 << 2;

    pub const legend = [_][]const u8{ "declaration", "readonly", "defaultLibrary" };
};

pub const SemanticTokensLegend = struct {
    tokenTypes: []const []const u8,
    tokenModifiers: []const []const u8,
};

pub const SemanticTokensOptions = struct {
    legend: SemanticTokensLegend,
    range: bool = true,
    full: bool = true,
};

/// Response payload for `textDocument/semanticTokens/full` (+ `/range`):
/// `data` is the LSP delta-encoded array (5 ints per token).
pub const SemanticTokens = struct {
    data: []const u32,
};

// ── textDocument/didChange ────────────────────────────────────────────────────

pub const TextDocumentContentChangeEvent = struct {
    range: ?Range = null,
    text: []const u8,
};

// ── Rename (with prepare) ────────────────────────────────────────────────────

pub const RenameOptions = struct {
    prepareProvider: bool = false,
};

pub const PrepareRenameResult = struct {
    range: Range,
    placeholder: []const u8,
};

// ── Code Actions ─────────────────────────────────────────────────────────────

pub const CodeActionKind = struct {
    pub const QuickFix = "quickfix";
    pub const Refactor = "refactor";
    pub const Source = "source";
};

pub const CodeAction = struct {
    title: []const u8,
    kind: ?[]const u8 = null,
    diagnostics: ?[]const Diagnostic = null,
    edit: ?WorkspaceEditSimple = null,
};

pub const WorkspaceEditSimple = struct {
    documentChanges: ?[]const TextDocumentEdit = null,
};

pub const TextDocumentEdit = struct {
    textDocument: VersionedTextDocumentIdentifier,
    edits: []const TextEdit,
};

pub const VersionedTextDocumentIdentifier = struct {
    uri: []const u8,
    version: ?i64 = null,
};

// ── Folding Ranges ───────────────────────────────────────────────────────────

pub const FoldingRangeKind = struct {
    pub const Comment = "comment";
    pub const Imports = "imports";
    pub const Region = "region";
};

pub const FoldingRange = struct {
    startLine: u32,
    startCharacter: ?u32 = null,
    endLine: u32,
    endCharacter: ?u32 = null,
    kind: ?[]const u8 = null,
};

// ── JSON-RPC envelope ─────────────────────────────────────────────────────────

pub const JsonRpcResponse = struct {
    jsonrpc: []const u8 = "2.0",
    id: std.json.Value,
    result: std.json.Value,
};

pub const JsonRpcErrorResponse = struct {
    jsonrpc: []const u8 = "2.0",
    id: std.json.Value,
    @"error": RpcError,
};

pub const RpcError = struct {
    code: i32,
    message: []const u8,
};

pub const JsonRpcNotification = struct {
    jsonrpc: []const u8 = "2.0",
    method: []const u8,
    params: std.json.Value,
};
