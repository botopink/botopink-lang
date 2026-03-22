const std = @import("std");
const token = @import("./lexer/token.zig");
const ast = @import("ast.zig");
const lexer = @import("lexer.zig");

pub const Token = token.Token;
pub const TokenKind = token.TokenKind;

pub const UseDecl = ast.UseDecl;
pub const Source = ast.Source;
pub const InterfaceDecl = ast.InterfaceDecl;
pub const InterfaceField = ast.InterfaceField;
pub const InterfaceMethod = ast.InterfaceMethod;
pub const StructDecl = ast.StructDecl;
pub const StructMember = ast.StructMember;
pub const StructField = ast.StructField;
pub const StructGetter = ast.StructGetter;
pub const StructSetter = ast.StructSetter;
pub const Param = ast.Param;
pub const Stmt = ast.Stmt;
pub const Expr = ast.Expr;
pub const RecordDecl = ast.RecordDecl;
pub const RecordField = ast.RecordField;
pub const ImplementDecl = ast.ImplementDecl;
pub const ImplementMethod = ast.ImplementMethod;
pub const DeclKind = ast.DeclKind;
pub const Program = ast.Program;
pub const GenericParam = ast.GenericParam;
pub const ParamModifier = ast.ParamModifier;

// ── Parser error types ────────────────────────────────────────────────────────

pub const ParseErrorType = enum {
    /// Generic unexpected token
    UnexpectedToken,
    /// Reserved word used as an identifier (e.g. auto = 1)
    ReservedWord,
    /// Assignment without 'val'/'var' (e.g. x = 4 instead of val x = 4)
    NoValBinding,
    /// Binary operator with no value on its right-hand side (e.g. 1 ++ val a = 5)
    OpNakedRight,
    /// List spread without a tail (e.g. [1, 2, ..])
    ListSpreadWithoutTail,
    /// Elements after a spread in a list (e.g. [..xs, 1, 2])
    ListSpreadNotLast,
    /// Useless spread with no elements to its left (e.g. [..wibble])
    UselessSpread,
};

pub const ParseErrorInfo = struct {
    kind: ParseErrorType,
    /// Byte offset of the start of the problematic token in the original source
    start: usize,
    /// Byte offset of the end (exclusive)
    end: usize,
    /// Lexeme of the problematic token
    lexeme: []const u8,
    /// Line number (1-based) — used when source is not available
    line: usize = 1,
    /// Column (1-based) — used when source is not available
    col: usize = 1,
    /// Extra context (e.g. the reserved word name)
    detail: ?[]const u8 = null,
};

pub const ParseError = error{ UnexpectedToken, OutOfMemory };

// ── Parser ────────────────────────────────────────────────────────────────────

pub const Parser = struct {
    tokens: []const Token,
    current: usize,
    /// Populated when parse() returns ParseError.UnexpectedToken
    parse_error: ?ParseErrorInfo,
    /// Original source text (for span calculation, when available)
    source: ?[]const u8,

    pub fn init(tokens: []const Token) Parser {
        return .{
            .tokens = tokens,
            .current = 0,
            .parse_error = null,
            .source = null,
        };
    }

    /// Initializes with the original source for richer error messages.
    pub fn initWithSource(tokens: []const Token, source: []const u8) Parser {
        return .{
            .tokens = tokens,
            .current = 0,
            .parse_error = null,
            .source = source,
        };
    }

    pub fn parse(self: *Parser, allocator: std.mem.Allocator) ParseError!Program {
        var decls: std.ArrayList(DeclKind) = .empty;
        errdefer {
            for (decls.items) |*d| d.deinit(allocator);
            decls.deinit(allocator);
        }
        while (!self.check(.EndOfFile)) {
            if (self.check(.KwUse)) {
                const u = try self.parseUseDecl(allocator);
                try decls.append(allocator, .{ .Use = u });
            } else if (self.check(.KwVal)) {
                const saved = self.current;
                _ = self.advance(); // consume `val`
                _ = self.advance(); // consume Name (Identifier)
                _ = self.advance(); // consume `=`
                const is_struct = self.check(.KwStruct);
                const is_record = self.check(.KwRecord);
                const is_implement = self.check(.KwImplement);
                self.current = saved;

                if (is_struct) {
                    const s = try self.parseStructDecl(allocator);
                    try decls.append(allocator, .{ .Struct = s });
                } else if (is_record) {
                    const r = try self.parseRecordDecl(allocator);
                    try decls.append(allocator, .{ .Record = r });
                } else if (is_implement) {
                    const i = try self.parseImplementDecl(allocator);
                    try decls.append(allocator, .{ .Implement = i });
                } else {
                    const t = try self.parseInterfaceDecl(allocator);
                    try decls.append(allocator, .{ .Interface = t });
                }
            } else {
                // Detect reserved word at top level
                if (isReservedWord(self.peek().kind)) {
                    const tok = self.peek();
                    self.parse_error = .{
                        .kind = .ReservedWord,
                        .start = tok.col - 1,
                        .end = tok.col - 1 + tok.lexeme.len,
                        .lexeme = tok.lexeme,
                        .line = tok.line,
                        .col = tok.col,
                        .detail = tok.lexeme,
                    };
                } else {
                    // Generic error: parse_error stays null, caller receives UnexpectedToken
                }
                return ParseError.UnexpectedToken;
            }
        }
        return Program{ .decls = try decls.toOwnedSlice(allocator) };
    }

    // ── use decl ─────────────────────────────────────────────────────────────

    fn parseUseDecl(self: *Parser, allocator: std.mem.Allocator) ParseError!UseDecl {
        _ = try self.consume(.KwUse);
        _ = try self.consume(.LBrace);
        const imports = try self.parseImportList(allocator);
        errdefer allocator.free(imports);
        _ = try self.consume(.RBrace);
        _ = try self.consume(.KwFrom);
        return UseDecl{ .imports = imports, .source = try self.parseSource() };
    }

    fn parseImportList(self: *Parser, allocator: std.mem.Allocator) ParseError![]const []const u8 {
        var names: std.ArrayList([]const u8) = .empty;
        errdefer names.deinit(allocator);
        if (!self.check(.Identifier)) return names.toOwnedSlice(allocator);
        try names.append(allocator, (try self.consume(.Identifier)).lexeme);
        while (self.match(.Comma)) {
            if (self.check(.RBrace)) break;
            try names.append(allocator, (try self.consume(.Identifier)).lexeme);
        }
        return names.toOwnedSlice(allocator);
    }

    fn parseSource(self: *Parser) ParseError!Source {
        if (self.check(.StringLiteral)) {
            const tok = try self.consume(.StringLiteral);
            return Source{ .StringPath = tok.lexeme[1 .. tok.lexeme.len - 1] };
        }
        if (self.check(.Identifier)) {
            const tok = try self.consume(.Identifier);
            _ = try self.consume(.LParen);
            _ = try self.consume(.RParen);
            return Source{ .FunctionCall = tok.lexeme };
        }
        return ParseError.UnexpectedToken;
    }

    // ── interface decl ───────────────────────────────────────────────────────────

    fn parseInterfaceDecl(self: *Parser, allocator: std.mem.Allocator) ParseError!InterfaceDecl {
        _ = try self.consume(.KwVal);
        const name = (try self.consume(.Identifier)).lexeme;
        const generic_params = try self.parseGenericParams(allocator);
        errdefer allocator.free(generic_params);
        _ = try self.consume(.Equal);
        _ = try self.consume(.KwInterface);
        _ = try self.consume(.LBrace);

        var fields: std.ArrayList(InterfaceField) = .empty;
        errdefer fields.deinit(allocator);

        var methods: std.ArrayList(InterfaceMethod) = .empty;
        errdefer {
            for (methods.items) |*m| m.deinit(allocator);
            methods.deinit(allocator);
        }

        while (!self.check(.RBrace) and !self.check(.EndOfFile)) {
            if (self.check(.KwVal)) {
                _ = try self.consume(.KwVal);
                const field_name = (try self.consume(.Identifier)).lexeme;
                _ = try self.consume(.Colon);
                const type_name = (try self.consume(.Identifier)).lexeme;
                try fields.append(allocator, .{ .name = field_name, .type_name = type_name });
            } else if (self.check(.KwFn)) {
                const method = try self.parseInterfaceMethod(allocator);
                try methods.append(allocator, method);
            } else {
                return ParseError.UnexpectedToken;
            }
        }

        _ = try self.consume(.RBrace);

        return InterfaceDecl{
            .name = name,
            .generic_params = generic_params,
            .fields = try fields.toOwnedSlice(allocator),
            .methods = try methods.toOwnedSlice(allocator),
        };
    }

    fn parseInterfaceMethod(self: *Parser, allocator: std.mem.Allocator) ParseError!InterfaceMethod {
        _ = try self.consume(.KwFn);
        const name = (try self.consume(.Identifier)).lexeme;

        // optional generic params: `<T, R>`
        const generic_params = try self.parseGenericParams(allocator);
        errdefer allocator.free(generic_params);

        _ = try self.consume(.LParen);
        var params: std.ArrayList(Param) = .empty;
        errdefer params.deinit(allocator);

        while (!self.check(.RParen) and !self.check(.EndOfFile)) {
            const p = try self.parseParam(allocator);
            try params.append(allocator, p);
            if (!self.match(.Comma)) break;
        }
        _ = try self.consume(.RParen);

        if (self.match(.RArrow)) {
            _ = try self.consumeTypeName();
        }

        if (!self.check(.LBrace)) {
            return InterfaceMethod{
                .name = name,
                .generic_params = generic_params,
                .params = try params.toOwnedSlice(allocator),
                .body = null,
            };
        }

        _ = try self.consume(.LBrace);
        var stmts: std.ArrayList(Stmt) = .empty;
        errdefer {
            for (stmts.items) |*s| s.deinit(allocator);
            stmts.deinit(allocator);
        }

        while (!self.check(.RBrace) and !self.check(.EndOfFile)) {
            const expr = try self.parseExpr(allocator);
            try stmts.append(allocator, .{ .expr = expr });
        }

        _ = try self.consume(.RBrace);

        return InterfaceMethod{
            .name = name,
            .generic_params = generic_params,
            .params = try params.toOwnedSlice(allocator),
            .body = try stmts.toOwnedSlice(allocator),
        };
    }

    // ── struct decl ───────────────────────────────────────────────────────────

    fn parseStructDecl(self: *Parser, allocator: std.mem.Allocator) ParseError!StructDecl {
        _ = try self.consume(.KwVal);
        const name = (try self.consume(.Identifier)).lexeme;
        const generic_params = try self.parseGenericParams(allocator);
        errdefer allocator.free(generic_params);
        _ = try self.consume(.Equal);
        _ = try self.consume(.KwStruct);
        _ = try self.consume(.LBrace);

        var members: std.ArrayList(StructMember) = .empty;
        errdefer {
            for (members.items) |*m| m.deinit(allocator);
            members.deinit(allocator);
        }

        while (!self.check(.RBrace) and !self.check(.EndOfFile)) {
            if (self.check(.KwPrivate)) {
                _ = self.advance();
                _ = try self.consume(.KwVal);
                const field_name = (try self.consume(.Identifier)).lexeme;
                _ = try self.consume(.Colon);
                const type_name = (try self.consumeTypeName()).lexeme;
                _ = try self.consume(.Equal);
                const init_expr = try self.parseExpr(allocator);
                try members.append(allocator, .{ .Field = .{
                    .is_private = true,
                    .name = field_name,
                    .type_name = type_name,
                    .init = init_expr,
                } });
            } else if (self.check(.KwVal)) {
                _ = self.advance();
                const field_name = (try self.consume(.Identifier)).lexeme;
                _ = try self.consume(.Colon);
                const type_name = (try self.consumeTypeName()).lexeme;
                _ = try self.consume(.Equal);
                const init_expr = try self.parseExpr(allocator);
                try members.append(allocator, .{ .Field = .{
                    .is_private = false,
                    .name = field_name,
                    .type_name = type_name,
                    .init = init_expr,
                } });
            } else if (self.check(.KwGet)) {
                const getter = try self.parseStructGetter(allocator);
                try members.append(allocator, .{ .Getter = getter });
            } else if (self.check(.KwSet)) {
                const setter = try self.parseStructSetter(allocator);
                try members.append(allocator, .{ .Setter = setter });
            } else if (self.check(.KwFn)) {
                const method = try self.parseInterfaceMethod(allocator);
                try members.append(allocator, .{ .Method = method });
            } else {
                return ParseError.UnexpectedToken;
            }
        }

        _ = try self.consume(.RBrace);

        return StructDecl{
            .name = name,
            .generic_params = generic_params,
            .members = try members.toOwnedSlice(allocator),
        };
    }

    fn parseStructGetter(self: *Parser, allocator: std.mem.Allocator) ParseError!StructGetter {
        _ = try self.consume(.KwGet);
        const name = (try self.consume(.Identifier)).lexeme;
        _ = try self.consume(.LParen);
        const self_param_name = (try self.consumeParamName()).lexeme;
        _ = try self.consume(.Colon);
        const self_param_type = (try self.consumeTypeName()).lexeme;
        _ = try self.consume(.RParen);
        _ = try self.consume(.RArrow);
        const return_type = (try self.consumeTypeName()).lexeme;

        _ = try self.consume(.LBrace);
        var stmts: std.ArrayList(Stmt) = .empty;
        errdefer {
            for (stmts.items) |*s| s.deinit(allocator);
            stmts.deinit(allocator);
        }
        while (!self.check(.RBrace) and !self.check(.EndOfFile)) {
            const expr = try self.parseExpr(allocator);
            try stmts.append(allocator, .{ .expr = expr });
        }
        _ = try self.consume(.RBrace);

        return StructGetter{
            .name = name,
            .self_param = .{ .name = self_param_name, .type_name = self_param_type },
            .return_type = return_type,
            .body = try stmts.toOwnedSlice(allocator),
        };
    }

    fn parseStructSetter(self: *Parser, allocator: std.mem.Allocator) ParseError!StructSetter {
        _ = try self.consume(.KwSet);
        const name = (try self.consume(.Identifier)).lexeme;
        _ = try self.consume(.LParen);

        var params: std.ArrayList(Param) = .empty;
        errdefer params.deinit(allocator);
        while (!self.check(.RParen) and !self.check(.EndOfFile)) {
            const p = try self.parseParam(allocator);
            try params.append(allocator, p);
            if (!self.match(.Comma)) break;
        }
        _ = try self.consume(.RParen);

        _ = try self.consume(.LBrace);
        var stmts: std.ArrayList(Stmt) = .empty;
        errdefer {
            for (stmts.items) |*s| s.deinit(allocator);
            stmts.deinit(allocator);
        }
        while (!self.check(.RBrace) and !self.check(.EndOfFile)) {
            const expr = try self.parseExpr(allocator);
            try stmts.append(allocator, .{ .expr = expr });
        }
        _ = try self.consume(.RBrace);

        return StructSetter{
            .name = name,
            .params = try params.toOwnedSlice(allocator),
            .body = try stmts.toOwnedSlice(allocator),
        };
    }

    // ── record decl ──────────────────────────────────────────────────────────

    fn parseRecordDecl(self: *Parser, allocator: std.mem.Allocator) ParseError!RecordDecl {
        _ = try self.consume(.KwVal);
        const name = (try self.consume(.Identifier)).lexeme;
        const generic_params = try self.parseGenericParams(allocator);
        errdefer allocator.free(generic_params);
        _ = try self.consume(.Equal);
        _ = try self.consume(.KwRecord);
        _ = try self.consume(.LParen);

        var fields: std.ArrayList(RecordField) = .empty;
        errdefer fields.deinit(allocator);
        while (!self.check(.RParen) and !self.check(.EndOfFile)) {
            _ = try self.consume(.KwVal);
            const field_name = (try self.consume(.Identifier)).lexeme;
            _ = try self.consume(.Colon);
            const field_type = (try self.consumeTypeName()).lexeme;
            try fields.append(allocator, .{ .name = field_name, .type_name = field_type });
            if (!self.match(.Comma)) break;
        }
        _ = try self.consume(.RParen);

        _ = try self.consume(.LBrace);
        var methods: std.ArrayList(InterfaceMethod) = .empty;
        errdefer {
            for (methods.items) |*m| m.deinit(allocator);
            methods.deinit(allocator);
        }

        while (!self.check(.RBrace) and !self.check(.EndOfFile)) {
            if (self.check(.KwFn)) {
                const method = try self.parseInterfaceMethod(allocator);
                try methods.append(allocator, method);
            } else {
                return ParseError.UnexpectedToken;
            }
        }
        _ = try self.consume(.RBrace);

        return RecordDecl{
            .name = name,
            .generic_params = generic_params,
            .fields = try fields.toOwnedSlice(allocator),
            .methods = try methods.toOwnedSlice(allocator),
        };
    }

    // ── implement decl ────────────────────────────────────────────────────────────

    fn parseImplementDecl(self: *Parser, allocator: std.mem.Allocator) ParseError!ImplementDecl {
        _ = try self.consume(.KwVal);
        const name = (try self.consume(.Identifier)).lexeme;
        const generic_params = try self.parseGenericParams(allocator);
        errdefer allocator.free(generic_params);
        _ = try self.consume(.Equal);
        _ = try self.consume(.KwImplement);

        var interfaces: std.ArrayList([]const u8) = .empty;
        errdefer interfaces.deinit(allocator);

        const first_interface = (try self.consume(.Identifier)).lexeme;
        try interfaces.append(allocator, first_interface);
        while (self.match(.Comma)) {
            if (self.check(.KwFor)) break;
            try interfaces.append(allocator, (try self.consume(.Identifier)).lexeme);
        }

        _ = try self.consume(.KwFor);
        const target = (try self.consume(.Identifier)).lexeme;

        _ = try self.consume(.LBrace);
        var methods: std.ArrayList(ImplementMethod) = .empty;
        errdefer {
            for (methods.items) |*m| m.deinit(allocator);
            methods.deinit(allocator);
        }

        while (!self.check(.RBrace) and !self.check(.EndOfFile)) {
            if (self.check(.KwFn)) {
                const method = try self.parseImplementMethod(allocator);
                try methods.append(allocator, method);
            } else {
                return ParseError.UnexpectedToken;
            }
        }
        _ = try self.consume(.RBrace);

        return ImplementDecl{
            .name = name,
            .generic_params = generic_params,
            .interfaces = try interfaces.toOwnedSlice(allocator),
            .target = target,
            .methods = try methods.toOwnedSlice(allocator),
        };
    }

    fn parseImplementMethod(self: *Parser, allocator: std.mem.Allocator) ParseError!ImplementMethod {
        _ = try self.consume(.KwFn);

        const first = (try self.consume(.Identifier)).lexeme;
        var qualifier: ?[]const u8 = null;
        var method_name: []const u8 = first;

        if (self.match(.Dot)) {
            qualifier = first;
            method_name = (try self.consume(.Identifier)).lexeme;
        }

        // optional generic params: `<T, R>`
        const generic_params = try self.parseGenericParams(allocator);
        errdefer allocator.free(generic_params);

        _ = try self.consume(.LParen);
        var params: std.ArrayList(Param) = .empty;
        errdefer params.deinit(allocator);

        while (!self.check(.RParen) and !self.check(.EndOfFile)) {
            const p = try self.parseParam(allocator);
            try params.append(allocator, p);
            if (!self.match(.Comma)) break;
        }
        _ = try self.consume(.RParen);

        if (self.match(.RArrow)) {
            _ = try self.consumeTypeName();
        }

        _ = try self.consume(.LBrace);
        var stmts: std.ArrayList(Stmt) = .empty;
        errdefer {
            for (stmts.items) |*s| s.deinit(allocator);
            stmts.deinit(allocator);
        }
        while (!self.check(.RBrace) and !self.check(.EndOfFile)) {
            const expr = try self.parseExpr(allocator);
            try stmts.append(allocator, .{ .expr = expr });
        }
        _ = try self.consume(.RBrace);

        return ImplementMethod{
            .qualifier = qualifier,
            .name = method_name,
            .params = try params.toOwnedSlice(allocator),
            .body = try stmts.toOwnedSlice(allocator),
        };
    }

    // ── param / type name helpers ─────────────────────────────────────────────

    fn consumeParamName(self: *Parser) ParseError!Token {
        if (self.check(.Identifier)) return self.advance();
        return ParseError.UnexpectedToken;
    }

    /// Parses a plain type name token: `Self` or any `Identifier`.
    fn consumeTypeName(self: *Parser) ParseError!Token {
        if (self.check(.KwSelfType)) return self.advance();
        if (self.check(.Identifier)) return self.advance();
        return ParseError.UnexpectedToken;
    }

    /// Parses an optional generic parameter list `<T, R, ...>`.
    /// Returns an empty slice if there is no `<` at the current position.
    fn parseGenericParams(self: *Parser, allocator: std.mem.Allocator) ParseError![]GenericParam {
        var list: std.ArrayList(GenericParam) = .empty;
        errdefer list.deinit(allocator);

        if (!self.match(.Less)) return list.toOwnedSlice(allocator);

        while (!self.check(.Greater) and !self.check(.EndOfFile)) {
            const name = (try self.consume(.Identifier)).lexeme;
            try list.append(allocator, .{ .name = name });
            if (!self.match(.Comma)) break;
        }
        _ = try self.consume(.Greater);
        return list.toOwnedSlice(allocator);
    }

    /// Parses a single function/method parameter with optional modifier.
    ///
    /// Grammar:
    ///   param        ::= param_name ':' modifier? type_name
    ///   modifier     ::= 'comptime' | 'syntax' | 'typeinfo'
    ///   type_name    ::= Identifier | 'Self'
    ///
    /// For `typeinfo` the optional constraint list follows:
    ///   typeinfo_param ::= param_name ':' 'typeinfo' type_name ('|' type_name)*
    fn parseParam(self: *Parser, allocator: std.mem.Allocator) ParseError!Param {
        const name = (try self.consumeParamName()).lexeme;
        _ = try self.consume(.Colon);

        // ── detect modifier ──────────────────────────────────────────────────
        const modifier: ParamModifier = blk: {
            if (self.match(.KwComptime)) break :blk .Comptime;
            if (self.match(.KwSyntax)) break :blk .Syntax;
            if (self.match(.KwTypeinfo)) break :blk .Typeinfo;
            break :blk .None;
        };

        const type_tok = try self.consumeTypeName();

        // ── typeinfo constraint list:  `typeinfo T | U | V` ──────────────────
        if (modifier == .Typeinfo) {
            var constraints: std.ArrayList([]const u8) = .empty;
            errdefer constraints.deinit(allocator);
            try constraints.append(allocator, type_tok.lexeme);
            while (self.match(.Vbar)) {
                try constraints.append(allocator, (try self.consumeTypeName()).lexeme);
            }
            return Param{
                .name = name,
                .type_name = type_tok.lexeme,
                .modifier = .Typeinfo,
                .typeinfo_constraints = try constraints.toOwnedSlice(allocator),
            };
        }

        return Param{ .name = name, .type_name = type_tok.lexeme, .modifier = modifier };
    }

    // ── expression parser ──────────────────────────────────────────────────────

    fn parseExpr(self: *Parser, allocator: std.mem.Allocator) ParseError!Expr {
        // ── Detect: identifier = expr (missing val/var) ──────────────────────
        if (self.check(.Identifier)) {
            const saved = self.current;
            const ident_tok = self.advance();
            if (self.check(.Equal) or self.check(.Colon)) {
                // Could be "x = 4" or "x:Int = 4" without val — NoValBinding error
                self.parse_error = .{
                    .kind = .NoValBinding,
                    .start = ident_tok.col - 1,
                    .end = ident_tok.col - 1 + ident_tok.lexeme.len,
                    .lexeme = ident_tok.lexeme,
                    .line = ident_tok.line,
                    .col = ident_tok.col,
                    .detail = ident_tok.lexeme,
                };
                return ParseError.UnexpectedToken;
            }
            self.current = saved;
        }

        // throw new Error("msg")
        if (self.check(.KwThrow)) {
            _ = self.advance();
            _ = try self.consume(.KwNew);
            const error_type = (try self.consume(.Identifier)).lexeme;
            _ = try self.consume(.LParen);
            const msg_expr = try self.parseConcatExpr(allocator);
            _ = try self.consume(.RParen);
            const msg_ptr = try allocator.create(Expr);
            msg_ptr.* = msg_expr;
            return Expr{ .ThrowNew = .{ .error_type = error_type, .message = msg_ptr } };
        }

        // return expr
        if (self.check(.KwReturn)) {
            _ = self.advance();
            const inner = try self.parseLtExpr(allocator);
            const inner_ptr = try allocator.create(Expr);
            inner_ptr.* = inner;
            return Expr{ .Return = inner_ptr };
        }

        // self._field = expr   ou   self._field += expr
        if (self.check(.Identifier)) {
            const saved = self.current;
            const first = self.advance();

            if (std.mem.eql(u8, first.lexeme, "self") and self.check(.Dot)) {
                _ = self.advance();
                const field_tok = try self.consume(.Identifier);

                if (self.match(.Equal)) {
                    const val_expr = try self.parseLtExpr(allocator);
                    const val_ptr = try allocator.create(Expr);
                    val_ptr.* = val_expr;
                    return Expr{ .SelfFieldAssign = .{ .field = field_tok.lexeme, .value = val_ptr } };
                }

                if (self.match(.PlusEq)) {
                    const val_expr = try self.parseLtExpr(allocator);
                    const val_ptr = try allocator.create(Expr);
                    val_ptr.* = val_expr;
                    return Expr{ .SelfFieldPlusEq = .{ .field = field_tok.lexeme, .value = val_ptr } };
                }

                self.current = saved;
            } else {
                self.current = saved;
            }
        }

        // Receiver.Method(arg) — static call
        if (self.check(.Identifier)) {
            const saved = self.current;
            const receiver_tok = self.advance();

            if (self.match(.Dot)) {
                const method_tok = try self.consume(.Identifier);
                _ = try self.consume(.LParen);
                const arg_expr = try self.parseConcatExpr(allocator);
                _ = try self.consume(.RParen);

                const arg_ptr = try allocator.create(Expr);
                arg_ptr.* = arg_expr;

                return Expr{ .StaticCall = .{
                    .receiver = receiver_tok.lexeme,
                    .method = method_tok.lexeme,
                    .arg = arg_ptr,
                } };
            }

            self.current = saved;
        }

        return self.parseLtExpr(allocator);
    }

    fn parseLtExpr(self: *Parser, allocator: std.mem.Allocator) ParseError!Expr {
        var lhs = try self.parseConcatExpr(allocator);

        if (self.match(.Less)) {
            // Detect: operator with no right-hand value (e.g. 1 < val a = 5)
            if (self.check(.KwVal) or self.check(.EndOfFile)) {
                const op_tok = self.tokens[self.current - 1];
                self.parse_error = .{
                    .kind = .OpNakedRight,
                    .start = op_tok.col - 1,
                    .end = op_tok.col - 1 + op_tok.lexeme.len,
                    .lexeme = op_tok.lexeme,
                    .line = op_tok.line,
                    .col = op_tok.col,
                };
                return ParseError.UnexpectedToken;
            }
            const rhs = try self.parseConcatExpr(allocator);
            const lhs_ptr = try allocator.create(Expr);
            lhs_ptr.* = lhs;
            const rhs_ptr = try allocator.create(Expr);
            rhs_ptr.* = rhs;
            lhs = Expr{ .Lt = .{ .lhs = lhs_ptr, .rhs = rhs_ptr } };
        }

        return lhs;
    }

    fn parseConcatExpr(self: *Parser, allocator: std.mem.Allocator) ParseError!Expr {
        var lhs = try self.parsePrimary(allocator);

        while (self.match(.Concatenate)) {
            // Detect: binary operator with no right-hand value (e.g. "a" ++ val x = ...)
            if (self.check(.KwVal) or self.check(.EndOfFile)) {
                const op_tok = self.tokens[self.current - 1];
                self.parse_error = .{
                    .kind = .OpNakedRight,
                    .start = op_tok.col - 1,
                    .end = op_tok.col - 1 + op_tok.lexeme.len,
                    .lexeme = op_tok.lexeme,
                    .line = op_tok.line,
                    .col = op_tok.col,
                };
                return ParseError.UnexpectedToken;
            }

            const rhs = try self.parsePrimary(allocator);

            const lhs_ptr = try allocator.create(Expr);
            lhs_ptr.* = lhs;
            const rhs_ptr = try allocator.create(Expr);
            rhs_ptr.* = rhs;

            lhs = Expr{ .Concat = .{ .lhs = lhs_ptr, .rhs = rhs_ptr } };
        }

        return lhs;
    }

    fn parsePrimary(self: *Parser, allocator: std.mem.Allocator) ParseError!Expr {
        _ = allocator;

        if (self.check(.StringLiteral)) {
            const tok = self.advance();
            return Expr{ .StringLit = tok.lexeme[1 .. tok.lexeme.len - 1] };
        }

        if (self.check(.NumberLiteral)) {
            const tok = self.advance();
            return Expr{ .NumberLit = tok.lexeme };
        }

        if (self.check(.KwSelfType)) {
            _ = self.advance();
            return Expr{ .Ident = "Self" };
        }

        // Detect reserved word used as expression
        if (isReservedWord(self.peek().kind)) {
            const tok = self.peek();
            self.parse_error = .{
                .kind = .ReservedWord,
                .start = tok.col - 1,
                .end = tok.col - 1 + tok.lexeme.len,
                .lexeme = tok.lexeme,
                .line = tok.line,
                .col = tok.col,
                .detail = tok.lexeme,
            };
            return ParseError.UnexpectedToken;
        }

        if (self.check(.Identifier)) {
            const tok = self.advance();
            if (std.mem.eql(u8, tok.lexeme, "self") and self.check(.Dot)) {
                _ = self.advance();
                const field = (try self.consume(.Identifier)).lexeme;
                return Expr{ .SelfField = field };
            }
            return Expr{ .Ident = tok.lexeme };
        }
        return ParseError.UnexpectedToken;
    }

    // ── primitives ────────────────────────────────────────────────────────────

    fn consume(self: *Parser, kind: TokenKind) ParseError!Token {
        if (self.check(kind)) return self.advance();
        // parse_error may not be set here; the top-level caller must populate
        // it before propagating if rich error context is needed.
        return ParseError.UnexpectedToken;
    }

    fn match(self: *Parser, kind: TokenKind) bool {
        if (!self.check(kind)) return false;
        _ = self.advance();
        return true;
    }

    fn check(self: *Parser, kind: TokenKind) bool {
        return self.peek().kind == kind;
    }

    fn advance(self: *Parser) Token {
        const t = self.tokens[self.current];
        if (t.kind != .EndOfFile) self.current += 1;
        return t;
    }

    fn peek(self: *Parser) Token {
        return self.tokens[self.current];
    }

    // ── reserved word detection helpers ──────────────────────────────────────

    fn isReservedWord(kind: TokenKind) bool {
        return lexer.isReservedWord(kind);
    }
};

// ── List spread validation — public helpers ───────────────────────────────────

pub const ListSpreadError = enum {
    /// Spread without explicit tail: [1, 2, ..]
    NoTail,
    /// Elements after spread: [..xs, 1, 2]
    ElementsAfterSpread,
    /// Useless spread (sole element, no prepend): [..wibble]
    UselessSpread,
};

/// Validates a list element sequence for spread errors.
/// Returns null if valid, or the error kind found.
pub fn validateListSpread(has_spread: bool, spread_is_last: bool, elements_before_spread: usize) ?ListSpreadError {
    if (has_spread) {
        if (!spread_is_last) return .ElementsAfterSpread;
        if (elements_before_spread == 0) return .UselessSpread;
    }
    return null;
}

/// Error messages for invalid list spreads.
pub fn listSpreadErrorMessage(err: ListSpreadError) struct { message: []const u8, hint: []const u8 } {
    return switch (err) {
        .NoTail => .{
            .message = "I was expecting a value after this spread",
            .hint = "If a list expression has a spread then a tail must also be given. Example: [1, 2, ..rest]",
        },
        .ElementsAfterSpread => .{
            .message = "I wasn't expecting elements after this",
            .hint = "Lists are immutable and singly-linked. Prepend items to the list and then reverse it once you are done.",
        },
        .UselessSpread => .{
            .message = "This spread does nothing",
            .hint = "Try prepending some elements [1, 2, ..list].",
        },
    };
}

/// Prints a list spread error to stderr — convenient for CLIs.
/// For tests or custom output destinations, use `print.zig` directly.
pub fn printListSpreadError(err: ListSpreadError, path: []const u8, line: usize, col: usize, span: []const u8) void {
    const msgs = listSpreadErrorMessage(err);
    const stderr = std.io.getStdErr().writer();
    const line_w = blk: {
        var w: usize = 1;
        var n = line;
        while (n >= 10) : (n /= 10) w += 1;
        break :blk w;
    };
    stderr.print("error: syntax error\n", .{}) catch return;
    for (0..line_w + 1) |_| stderr.writeByte(' ') catch return;
    stderr.print("┌─ {s}:{d}:{d}\n", .{ path, line, col }) catch return;
    for (0..line_w + 1) |_| stderr.writeByte(' ') catch return;
    stderr.print("│\n", .{}) catch return;
    stderr.print("{d} │ {s}\n", .{ line, span }) catch return;
    for (0..line_w + 1) |_| stderr.writeByte(' ') catch return;
    stderr.print("│ ", .{}) catch return;
    for (0..col - 1) |_| stderr.writeByte(' ') catch return;
    for (0..span.len) |_| stderr.writeByte('^') catch return;
    stderr.print(" {s}\n\n", .{msgs.message}) catch return;
    for (0..line_w + 1) |_| stderr.writeByte(' ') catch return;
    stderr.print("hint: {s}\n\n", .{msgs.hint}) catch return;
}
