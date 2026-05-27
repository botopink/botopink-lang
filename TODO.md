# TODO — Botopink Compiler

## Design — `@Context<ContextBase, Return>` + `@Future<Return>`

### Regra central

O **tipo de retorno** da função define quais capacidades o body pode usar:

| Retorno impl        | `use` | `await` |
|----------------------|-------|---------|
| `@Context<B, R>`    | ✓     | ✗       |
| `@Future<R>`        | ✗     | ✓       |
| `@Context + @Future`| ✓     | ✓       |
| nenhum               | ✗     | ✗       |

- `use` exige `@Context<ContextBase, _>` no retorno
- `await` exige `@Future<_>` no retorno
- Todos os `use` numa mesma função devem ter o **mesmo ContextBase**
- Misturou ContextBase = compile error

### Interface

```bp
interface @Context<ContextBase, Return> { }
```

- `ContextBase` = phantom type (erased em runtime, zero custo)
- `Return` = shape do que `use` destructura
- Sem método `resolve()` — é contrato de tipos, codegen é target-specific

### Módulo

Um arquivo `.bp` é implicitamente `fn*() -> @Context<Module, Exports> + @Future<Exports>`:

- `@Context<Module, _>` habilita `use` no top-level
- `@Future<Exports>` torna o módulo async (carregamento de dependências)
- `@root()` e `@module("x")` retornam `@Context<Module, ModuleTree>` (não `@Future`)

```bp
use {std.List, std.Map} = @root()
use {state, memo, effect} = @module("framework")

pub fn App() -> Element {
    use {val, set} = state(0)
    div { val.to_string() }
}
```

### ContextBases (definidos por frameworks, não pela linguagem)

| ContextBase | Retorno típico | Hooks disponíveis                |
|-------------|----------------|----------------------------------|
| `Module`    | `Exports`      | `@root()`, `@module("x")`       |
| `Element`   | `Element`      | `state`, `memo`, `effect`, `context` |
| `Http`      | `Response`     | `connection`, `auth`, `session`  |
| `Cli`       | `CliApp`       | `flags`, `stdout`, `stdin`       |

A linguagem só fornece `Module`. Os demais são userland/framework.

### Fontes de import

```bp
@root()              // raiz do projeto atual
@module("name")      // dependência externa / pacote
```

Dotted path dentro do `{}`:
```bp
use {std.List} = @root()             // binding: List
use {ui.components.Button} = @root() // binding: Button
use {std.List as L} = @root()        // binding: L
```

### `use` sem binding (void)

```bp
use _ = effect({ -> cleanup() })     // @Context<_, void> — `_` descarta resultado
use {val, set} = state(0)            // @Context<_, T> — binding obrigatório
```

### Prefix estático

Todos os `use` devem vir antes de qualquer branch/return no body:

```bp
fn Dashboard(loading: bool) -> Element {
    // === prefix estático ===
    use {val, set} = state(0)
    use doubled = memo({ -> val * 2 })
    // === fim ===
    if loading { return Spinner() }
    div { doubled.to_string() }
}
```

### `@Future` e `await`

`await` é habilitado quando o retorno implementa `@Future<_>`. `*fn` é açúcar para declarar que o retorno implementa `@Future`:

```bp
// *fn = retorno impl @Future
*fn fetch(url: string) -> @Result<Response, Error> {
    val resp = await http.get(url)
    try resp.json()
}

// Equivalente explícito (sem *fn):
fn fetch(url: string) -> @Future<@Result<Response, Error>> {
    val resp = await http.get(url)
    try resp.json()
}

// Módulo: impl @Context + @Future — pode usar use + await
// Componente: impl só @Context — pode usar use, não pode await
// *fn pura: impl só @Future — pode usar await, não pode use
// Tipo custom que impl ambos — pode usar use + await
```

### Custom hooks

Funções cujo retorno implementa `@Context<B, _>` são hooks. A validação é transitiva.
`@Context` é uma interface builtin — implementação inline via `struct implement`:

```bp
val AuthState = struct implement @Context<Element, {user: User, isLoggedIn: bool}> {
    user: User
    isLoggedIn: bool
}

fn useAuth() -> AuthState {
    use {token} = state(null)        // @Context<Element, _> ✓
    use {user} = context(UserCtx)    // @Context<Element, _> ✓
    AuthState { user, isLoggedIn: token != null }
}

fn Dashboard() -> Element {
    use {user, isLoggedIn} = useAuth() // @Context<Element, _> ✓
}
```

Ambas as formas são válidas:
```bp
// Inline — curta, para o caso comum
val AuthState = struct implement @Context<Element, AuthState> {}

// Separada — para implementar interface em tipo já existente
val CircleDrawing = implement Drawable for Circle {
    fn draw(self: Self) {}
}
```

### Generators e Iterators

`*fn` com `yield` produz `@Iterator<T>` ou `@AsyncIterator<T, E>`:

```bp
*fn fibonacci() -> @Iterator<i32> {
    yield 0
    yield 1
}

*fn stream(url: string) -> @AsyncIterator<string, Error> {
    loop {
        yield await readLine(url)
    }
}

// yield com label (desambiguação)
*fn chunks(items: i32[]) -> @Iterator<i32[]> :gen {
    var batch = loop (items) :acc { item ->
        if needFlush() {
            yield :gen batch
        }
        yield :acc item
    }
}

// loop await para async iterators
loop await (stream) { line ->
    @print(line)
}
```

### Erros do compilador

```
error: ContextBase mismatch
  function returns @Context<Element, _>
  but `connection()` returns @Context<Http, _>
  all `use` in a function must share the same ContextBase

error: `use` not allowed
  function returns `string` which does not implement @Context
  `use` requires the return type to implement @Context<_, _>

error: `await` not allowed
  function returns `Element` which does not implement @Future
  `await` requires the return type to implement @Future<_>

error: `use` must be in static prefix
  `use` cannot appear after `if`, `case`, `loop`, or `return`
  move all `use` statements to the top of the function body

error: `*fn` requires @Future or @Iterator return
  function declared as `*fn` but return type `string`
  does not implement @Future<_> or @Iterator<_>

error: `fn` cannot return @Future directly
  use `*fn` to declare async/generator functions
  or return a type that implements @Future<_> explicitly
```

---

## Pending — @Context Implementation

`@Context<B, R>` é uma interface builtin (como `@Result<D, E>`).
Duas formas de implementar:
- **Inline**: `val X = struct implement @Context<B, R> { }` — curta, caso comum
- **Separada**: `val Y = implement @Context<B, R> for X { }` — para tipo já existente

### Fase 1: AST

- [x] `interface` keyword/declaração no AST — já existia
- [x] `Expr.useHook` variant para `use` como hook no body (distinto de `UseDecl` de imports)
- [x] `TypeRef.generic` com `is_builtin` já representa `@Context<B, R>`
- [x] Adicionar `implement: []TypeRef` ao `StructDecl`/`EnumDecl`/`RecordDecl` para `struct implement I1, I2 { }`

### Fase 2: Parser

- [x] Parsear `struct implement Interface1, Interface2 { }` — lista de TypeRef após `implement` keyword
- [x] Parsear `enum implement Interface { }` e `record(...) implement Interface { }` — mesma regra
- [x] Parsear `use _ = expr` e `use name = expr` e `use {a, b} = expr` como hooks no body
- [x] Validar prefix estático: emitir erro se `use` aparece após branch/return

### Fase 3: Type Inference

- [x] Definir `@Context<B, R>` como interface builtin em `builtins.d.bp`
- [ ] Resolver `implement` (inline e separado) — registrar que T impl @Context
- [ ] Ao entrar em fn body: extrair ContextBase do return type se impl `@Context`
- [ ] Ao encontrar `use`: verificar que a expressão retorna `@Context<B, _>` com B == ContextBase da fn
- [ ] Erro se `use` em fn cujo retorno não impl `@Context`
- [ ] Erro se ContextBase do `use` diverge do ContextBase da fn
- [ ] Validação transitiva: custom hooks propagam ContextBase via return type

### Fase 4: Codegen

- [ ] CommonJS: `use {v, s} = state(0)` → `const [v, s] = useState(0)` — mapping framework-specific
- [ ] CommonJS: `use expr` (void) → `useEffect(...)` etc.
- [ ] Erlang: `use` → slot no process dictionary ou gen_server state
- [ ] BEAM ASM: `use` → hook slot management
- [ ] WAT: `use` → load/store em offset fixo na memória linear
- [ ] TypeScript: emitir tipos de interface `@Context` no `.d.ts`
- [ ] ContextBase erased — não gerar código para phantom type

### Fase 5: Formatter + LSP

- [ ] Formatter: emitir `use binding = expr` e `use expr` (void)
- [ ] LSP hover: mostrar ContextBase da fn e tipo do hook
- [ ] LSP error: mostrar ContextBase mismatch inline
- [ ] LSP autocomplete: sugerir hooks compatíveis com ContextBase da fn

### Cenários de teste

```
parser ---- struct implement @Context<B, R> { } (inline implement)
parser ---- struct implement A, B { } (multiple inline interfaces)
parser ---- enum implement @Context<B, R> { } (inline implement on enum)
parser ---- record(...) implement @Context<B, R> { } (inline implement on record)
parser ---- use expr (void hook, no binding)
parser ---- use name = expr (hook with simple binding)
parser ---- use {a, b} = expr (hook with destructuring)
parser ---- use after if branch (error: not in static prefix)
parser ---- use after early return (error: not in static prefix)
context ---- use in fn -> @Context<Element, _> (pass)
context ---- use in fn -> string (error: not @Context)
context ---- ContextBase mismatch Element vs Http (error)
context ---- use without binding for void hook (pass)
context ---- use with binding for non-void hook (pass)
context ---- custom hook propagates ContextBase transitively (pass)
context ---- struct implement @Context — resolved via inline impl (pass)
context ---- implement @Context for struct — resolved via separate impl (pass)
context ---- struct missing @Context impl but used with use (error)
codegen ---- inline implement erased at runtime (no code for phantom)
codegen ---- separate implement erased at runtime (no code for phantom)
```

---

## Pending — Use Syntax: `from "mod"` → `= @root()` / `= @module("name")`

### Fases completas (AST ✓, Lexer ✓, Parser ✓, Formatter ✓, Tests parciais ✓)

Detalhes das fases completas no histórico de commits.

### Fase restante: Parser error

- [x] Rejeitar sintaxe antiga `use { X } from "mod"` com hint para usar `= @root()` / `= @module("name")`

### Fase restante: Type Inference / Comptime

- [ ] `resolveImports`: resolver `@root()` como caminho para o módulo raiz do projeto (`comptime.zig` / `infer.zig`)
- [ ] `resolveImports`: resolver `@module("name")` como caminho para dependência nomeada
- [ ] Resolver dotted paths: `std.List` navega submodules/exports aninhados
- [ ] Definir semântica exata de `@root()` vs `@module("name")`

### Fase restante: Codegen

- [ ] CommonJS: `use {std.List} = @root()` → `const { List } = require("./std");` (`commonJS.zig`)
- [ ] CommonJS: dotted path `std.List` → destructuring aninhado ou qualified access
- [ ] Erlang: `use {std.List} = @root()` → `-import(std, [list/0]).` (`erlang.zig`)
- [ ] TypeScript: `use {std.List} = @root()` → `import { List } from "./std";` (`typescript.zig`)
- [ ] BEAM ASM: atualizar se necessário (`beam_asm.zig`)
- [ ] WAT: atualizar se necessário (`wat.zig`)

### Fase restante: Language Server

- [ ] LSP folding: atualizar detecção de blocos `use` consecutivos (`engine.zig`)
- [ ] LSP unused imports: atualizar scan para nova sintaxe (`engine.zig`)
- [ ] LSP go-to-definition: resolver `@root()` / `@module("name")` para arquivo/módulo correto

### Fase restante: Docs

- [ ] Atualizar `docs.md` com nova sintaxe de imports
- [ ] Atualizar `examples.md` com exemplos usando `@root()` / `@module("name")`
- [ ] Atualizar AGENTS.md com mudança de sintaxe

### Cenários de teste pendentes

```
parser ---- rejected old syntax from "mod" (error with hint) ✓
comptime ---- import single val from @root() dependency
comptime ---- import multiple vals from @root() dependency
comptime ---- import fn from @module("name") dependency
comptime ---- three-level chain a imports b via @root(), b imports c via @module("x")
comptime ---- dotted path std.List resolves nested export
comptime ---- unresolved segment (error)
comptime ---- @root() vs @module("name") correct module resolution
codegen ---- single import @root() (CommonJS: require, Erlang: -import, TS: import)
codegen ---- dotted path std.List (CommonJS: nested destructure, Erlang: qualified, TS: import)
codegen ---- multi-module pub fn import with @root()
codegen ---- multi-module pub val import with @module("name")
```

---

## Pending — Async, Generator & Iterator

### Relação com @Context/@Future

`*fn` é açúcar: indica que o retorno implementa `@Future<_>` ou `@Iterator<_>`. As regras de `await`/`yield` seguem do tipo de retorno, não do `*fn` em si:

- Retorno impl `@Future<T>` → `await` habilitado
- Retorno impl `@Iterator<T>` → `yield` (suspend) habilitado
- Retorno impl `@Context<B, R> + @Future<T>` → `use` + `await` habilitados
- `fn` normal retornando `@Future`/`@Iterator` sem `*fn` → compile error

### Fase 1: Lexer + AST

**Arquivos**: `lexer/token.zig`, `lexer.zig`, `ast.zig`

- [ ] Lexer: adicionar token `await` ao `TokenKind` enum
- [ ] Lexer: adicionar reconhecimento `"await"` no `identifierType`
- [ ] AST: adicionar `Expr.await` variant (prefix unary, como `try`)
- [ ] AST: adicionar campo `isStarFn: bool` ao `FnDecl` / fn expressions
- [ ] AST: adicionar campo `awaitLoop: bool` ao `LoopExpr` (para `loop await`)
- [ ] AST: adicionar campo `label: ?[]const u8` ao `JumpExpr.yield`
- [ ] AST: adicionar campo `label: ?[]const u8` ao `LoopExpr`
- [ ] AST: adicionar campo `label: ?[]const u8` ao `FnDecl`

### Fase 2: Parser

**Arquivo**: `parser.zig`

- [ ] Parsear `*fn` — detectar `*` antes de `fn` como declaração de função especial
- [ ] Parsear `await expr` como expressão prefix (similar a `try expr`)
- [ ] Parsear `loop await (iter) { ... }` — detectar `await` token após `loop`
- [ ] Parsear labels `:name` após keyword `loop` ou após return type de `*fn`
- [ ] Parsear `yield :label expr` — label opcional no yield
- [ ] Erro se `*fn` sem body

### Fase 3: Type Inference

**Arquivo**: `comptime/infer.zig`

- [ ] Validar `*fn`: retorno deve implementar `@Future<_>` ou `@Iterator<_>`
- [ ] Erro se `fn` normal retorna tipo que impl `@Future`/`@Iterator` (deve usar `*fn`)
- [ ] `await expr`: verificar que `expr` impl `@Future<T>`, resultado = `T`
- [ ] Erro se `await` em fn cujo retorno não impl `@Future`
- [ ] `yield expr` em `*fn`: unificar tipo de `expr` com `T` de `@Iterator<T>`
- [ ] `yield` sem `*fn`: mantém comportamento atual (accumulate em loop)
- [ ] Labels: verificar que label referenciado existe, erro se label inexistente
- [ ] `loop await`: verificar que iter impl `@AsyncIterator<T, E>`, inferir param como `T`
- [ ] `try await expr`: unwrap `@Future<@Result<T,E>>` → `T`

### Fase 4: Codegen

| Feature | CommonJS | Erlang | BEAM ASM | WAT |
|---------|----------|--------|----------|-----|
| `*fn` async | `async function` | spawn + receive | spawn/receive OTP | state machine |
| `*fn` generator | `function*` | processo com estado | spawn + msg passing | state machine |
| `*fn` async gen | `async function*` | spawn + receive loop | spawn + receive | callback chain |
| `await expr` | `await expr` | `receive` / `gen_server:call` | receive + match | continuation |
| `yield expr` | `yield expr` | send | send | store + return |
| `loop await` | `for await (...)` | receive loop recursivo | receive + match | callback loop |

TypeScript `.d.ts`:
- [ ] `@Future<T>` → `Promise<T>`
- [ ] `@Iterator<T>` → `IterableIterator<T>`
- [ ] `@AsyncIterator<T, E>` → `AsyncIterableIterator<T>`

### Fase 5: Formatter + LSP

- [ ] Formatter: emitir `*fn`, `await expr`, `loop await`, `yield :label`
- [ ] LSP hover: mostrar tipo unwrapped de `await`/`yield`, indicar `*fn`
- [ ] LSP autocomplete: sugerir `next()`, `iter()`, `map()`, `flatMap()` nos tipos correspondentes

### Cenários de teste

```
parser ---- *fn async function declaration with @Future return
parser ---- *fn generator function with @Iterator return
parser ---- *fn async generator with @AsyncIterator return
parser ---- *fn with label :gen after return type
parser ---- *fn without body (error)
parser ---- await prefix expression inside *fn
parser ---- await chained on method call
parser ---- loop await iteration over async iterator
parser ---- yield with label :gen targets generator
parser ---- yield with label :acc targets loop accumulator
parser ---- yield without label in generator context
inference ---- *fn with @Future return is valid
inference ---- *fn with @Iterator return is valid
inference ---- *fn with string return (error: must impl @Future or @Iterator)
inference ---- fn normal returning @Future (error: must use *fn)
inference ---- fn normal returning @Iterator (error: must use *fn)
inference ---- await inside *fn @Future unwraps to T
inference ---- await outside *fn (error: return must impl @Future)
inference ---- await on non-@Future type (error)
inference ---- yield in *fn @Iterator unifies expr with T
inference ---- yield :label references existing loop label (pass)
inference ---- yield :label references nonexistent label (error)
inference ---- loop await infers param type T from @AsyncIterator<T, E>
inference ---- loop await on non-async-iterable (error)
inference ---- try await @Future<@Result<T,E>> double unwrap to T
codegen ---- *fn async simple fetch (CommonJS: async function, Erlang: spawn+receive)
codegen ---- *fn generator fibonacci yields (CommonJS: function*, Erlang: process)
codegen ---- *fn async generator stream (CommonJS: async function*, Erlang: spawn+receive loop)
codegen ---- await inside async fn (CommonJS: await, Erlang: receive)
codegen ---- yield suspend generator (CommonJS: yield, Erlang: send)
codegen ---- loop await iterate stream (CommonJS: for await, Erlang: receive loop)
codegen ---- yield :label disambiguated yield targets correct scope
codegen ---- try await unwrap async result in one expression
```

---

## Pending — AST & Parser Simplification

Refactoring para reduzir verbosidade do AST e eliminar duplicação no parser.

**Arquivos principais**: `ast.zig` (1360 linhas), `parser.zig` (3630 linhas)
**Consumidores do AST**: `format.zig`, `infer.zig`, `transform.zig`, `beam_asm.zig`, `wat.zig`, `erlang.zig`, `typescript.zig`, `print.zig`

### Fase 1: Helpers de construção no parser (só parser.zig)

Reduzir verbosidade na construção de nós — zero impacto nos consumidores.

- [ ] Substituir 27 instâncias manuais de `alloc.create(Expr); ptr.* = expr` pelo helper `boxExpr()` já existente
- [ ] Criar helper `makeBinOp(alloc, op, opTok, lhs, rhs) -> Expr` — encapsula box de lhs/rhs + construção do nó
- [ ] Criar helper `makeCall(tok, receiver, callee, is_builtin, args, trailing) -> Expr` — substitui 11 sites de construção de call
- [ ] Criar helper `makeJump(tok, comptime variant, inner) -> Expr` — unifica return/throw/try/break/yield
- [ ] Criar helper `tryParseCommentStmt(alloc) -> ?Stmt` — extrai o padrão duplicado de `check(.commentNormal) or .commentDoc or .commentModule` + conversão CommentKind (3-4 ocorrências)

### Fase 2: Unificar parsing de blocos (só parser.zig)

5 métodos quase idênticos → 1 método parametrizado + 1 wrapper fino.

- [ ] Criar `BlockParseOptions = struct { trackEmptyLines: bool, handleComments: bool, semicolonPolicy: enum { strict, required_except_last, always_optional } }`
- [ ] Criar `parseBlock(alloc, opts) -> []Stmt` unificando os 5 métodos
- [ ] Manter `parseBlockOrExpr` como wrapper fino
- [ ] Remover os 5 métodos antigos

### Fase 3: Unificar operadores binários (só parser.zig)

6 métodos idênticos → 1 método genérico com tabela de precedência comptime.

- [ ] Criar tabela `precedence_table` mapeando nível → tokens + op enum
- [ ] Criar `parseBinaryExpr(alloc, comptime level: u8) -> Expr` recursivo
- [ ] Remover `parseOrExpr`, `parseAndExpr`, `parseEqExpr`, `parseCompareExpr`, `parseAddExpr`, `parseMulExpr`

### Fase 4: Flatten AST — eliminar triplo aninhamento (ast.zig + consumidores)

Nós struct-based perdem a camada `.kind`, campos ficam direto no struct.

- [ ] Flatten `BinOpExprOf`: struct direto com `loc, type_, op, lhs, rhs`
- [ ] Flatten `UnaryOpExprOf`: struct direto com `loc, type_, op, expr`
- [ ] Flatten `LoopExprOf`: struct direto com `loc, type_, iter, indexRange, params, body`
- [ ] Para nós union-based: manter `MakeExpr` mas avaliar renomear `kind`
- [ ] Migrar consumidores (search-and-replace mecânico)
- [ ] Atualizar `deinit` de cada tipo flattened

### Fase 5: Merge lambda/fnExpr (ast.zig + consumidores)

- [ ] Substituir `FunctionExprOf.Kind` (union lambda/fnExpr) por struct: `{ syntax: enum { lambda, fnExpr }, params, body }`
- [ ] Migrar consumidores e simplificar `deinit`

### Fase 6: Unificar preamble de declarações (só parser.zig)

- [ ] Criar `DeclPreamble` + `parseDeclPreamble` extraindo padrão comum dos 10 métodos de parse de declarações
- [ ] Refatorar 4 pares struct/record/enum/interface para usar `parseDeclPreamble`

### Fase 7 (opcional): Merge pattern variants (ast.zig + consumidores)

- [ ] Unificar `variantBinding`, `variantFields`, `variantLiterals` em `variant` com payload union
- [ ] Migrar 14 sites de match em 4 arquivos

### Verificação

Após cada fase, rodar `zig build test`. O compilador Zig garante que qualquer acesso a campo removido falha em compilação.

---

## Pending — Type System

### Typeparam constraints

- [ ] Constraint syntax: `comptime f: typeparam string | int`
- [ ] Parser: parse `|`-separated type list after `typeparam`
- [ ] Inference: validate comptime argument satisfies declared constraints
- [ ] Error message: clear diagnostic when constraint is violated

```
parser ---- typeparam with single constraint
parser ---- typeparam with multiple pipe-separated constraints
parser ---- typeparam without constraint (backwards compat)
inference ---- comptime arg satisfies single constraint (pass)
inference ---- comptime arg satisfies one of multiple constraints (pass)
inference ---- comptime arg violates constraint (error)
inference ---- comptime arg with no constraint accepts any type (pass)
codegen ---- constrained typeparam specializes correctly
```

### Throw type checking

- [ ] Verify thrown value matches `E` of enclosing `@Result<D, E>` return
- [ ] Error message: mismatch between thrown type and declared `E`

```
throw ---- string matches declared E = string (pass)
throw ---- record matches declared E = ErrorRecord (pass)
throw ---- type mismatch i32 thrown but E = string (error)
throw ---- throw inside nested fn does not check outer fn's E
throw ---- throw inside catch handler checks enclosing fn's E
throw ---- multiple throw sites all must match E
throw ---- throw without enclosing Result return type (error)
```

---

## Pending — Codegen

### try/catch lowering

`try`/`catch` deve lowerar para pattern matching em `Ok`/`Error` (não JS try/catch):

- [ ] CommonJS: `try expr catch fallback` → `const _r = expr(); if (_r.tag === "Error") { ... } else { _r.data }`
- [ ] Erlang: → `case Expr of {ok, V} -> V; {error, E} -> Fallback end`
- [ ] BEAM ASM: via `{test, is_tagged_tuple, ...}` or case dispatch
- [ ] WAT: → `if` on Ok/Error i32 tag in linear memory

```
try ---- simple try unwraps Ok to value (CommonJS, Erlang, BEAM, WAT)
try ---- catch with literal fallback on Error (CommonJS, Erlang)
try ---- catch with lambda handler receives error value (CommonJS, Erlang)
try ---- nested try catch both lowered to pattern match
try ---- try without catch propagates Error variant up
try ---- catch tail on method call chain
try ---- multiple try in same fn body independent temps
try ---- try on non-Result type (comptime error)
```

### BEAM ASM — remaining fases

- [ ] **Fase 3**: strings/binaries — `{put_string, ...}`, binary syntax, `@print` via `io:format`
- [ ] **Fase 4**: records/structs — map creation `{put_map_assoc, ...}`, field access
- [ ] **Fase 5**: enums — tagged tuple `{tag, Fields...}`, case dispatch on tag
- [ ] **Fase 6**: closures/lambdas — `{make_fun3, ...}`, higher-order calls
- [ ] **Fase 7**: ranges — `lists:seq/2` or loop counter lowering
- [ ] **Fase 8**: try/catch — `{try, ...}` / `{try_end, ...}` / `{try_case, ...}` instructions
- [ ] **Fase 9**: polish — register allocation, tail-call optimization, dead code elimination

### WAT — remaining features

- [ ] Destructure patterns (record, tuple)
- [ ] Pipeline operator lowering
- [ ] String operations (concat, compare) via linear memory
- [ ] Enum/record representation in linear memory (tagged structs)
- [ ] try/catch → tag-based if/else

### Erlang codegen gaps

- [ ] List patterns in case arms (currently placeholder)
- [ ] Constructor patterns in case arms (currently placeholder)
- [ ] Proper arity tracking for qualified function calls

---

## Pending — Interface / Struct / Record / Implement Full Coverage

### Fase 1: Parser tests

- [ ] Interface with field + abstract method + default method (full Drawable spec)
- [ ] Interface with multiple abstract methods (Canvas spec)
- [ ] Struct with private field + getter + setter (with throw) + method
- [ ] Record with fields + method (toString pattern)
- [ ] Implement single interface with method body (separada: `implement I for T {}`)
- [ ] Implement multiple interfaces with qualified method disambiguation (separada)
- [ ] Struct with inline implement (`struct implement I1, I2 {}`)
- [ ] Enum with inline implement (`enum implement I {}`)
- [ ] Record with inline implement (`record(...) implement I {}`)

### Fase 2: Comptime / Inference tests

- [ ] Interface with field and abstract method infers correctly
- [ ] Interface with multiple abstract methods infers param types
- [ ] Struct with getter/setter/method infers Self and field types
- [ ] Record with fields and method infers return type
- [ ] Implement single interface — binding list sees implement decl
- [ ] Implement two interfaces with qualified methods — disambiguation resolves

### Fase 3: Semantic validation

- [ ] Error: implement block missing a required interface method
- [ ] Error: implement block has method not declared in interface
- [ ] Error: qualified method prefix doesn't match any declared interface
- [ ] Error: duplicate method name across interfaces without qualification
- [ ] Error: struct getter return type mismatch with field type
- [ ] Error: setter called with wrong value type

### Fase 4: Codegen

- [ ] CommonJS: interface → comment, struct → class with getter/setter, record → class with constructor
- [ ] CommonJS: implement → prototype.method attachment
- [ ] Erlang: struct → map + accessor fns, record → tagged tuple, implement → module export
- [ ] BEAM ASM: struct/record/implement lowering
- [ ] WAT: struct/record memory layout

### Cenários de teste

```
parser ---- interface with field + abstract + default method
parser ---- interface with multiple abstract methods (Canvas)
parser ---- struct with private field + getter + setter(throw) + method
parser ---- record with two fields + toString method
parser ---- implement single interface with method body (separada)
parser ---- implement two interfaces with qualified disambiguation (separada)
parser ---- struct with inline implement single interface
parser ---- struct with inline implement multiple interfaces
parser ---- enum with inline implement
parser ---- record with inline implement
infer ---- interface with field and abstract method
infer ---- interface with multiple abstract methods
infer ---- struct with getter/setter/method
infer ---- record with fields and method
infer ---- implement single interface for record (separada)
infer ---- implement two interfaces with qualified methods (separada)
infer ---- struct with inline implement resolves interface
infer ---- inline implement + separate implement both visible
infer error ---- implement missing required method
infer error ---- implement extra method not in interface
infer error ---- qualified prefix doesn't match interface
infer error ---- duplicate method without qualification
codegen ---- interface as comment (CommonJS, Erlang)
codegen ---- struct to class with getter/setter (CommonJS)
codegen ---- record to class with constructor (CommonJS)
codegen ---- implement attaches methods to prototype (CommonJS)
```

---

## Pending — Stdlib

- [ ] `@Result.map(fn(D) -> D2)` — transform Ok value
- [ ] `@Result.flatMap(fn(D) -> @Result<D2, E>)` — chain fallible operations
- [ ] `@Result.unwrapOr(default: D)` — extract Ok or use default
- [ ] `@Result.isOk()` / `@Result.isError()` — boolean predicates
- [ ] `@Option.map` / `@Option.flatMap` / `@Option.unwrapOr` — mirror Result API

---

## Pending — Language Features

### Lambda syntax

- [ ] Lambda with full type annotations: `val func: fn(String, Int) -> String = { s, i -> ... }`
- [ ] Infer lambda param types from context when annotation is present

### Pattern matching

- [ ] Exhaustiveness checking for case expressions
- [ ] Nested pattern matching (pattern inside pattern)
- [ ] Guard clauses in case arms: `case x { n if n > 0 -> ... }`

---

## Pending — Tooling

### Language Server

- [ ] Go-to-definition for imported symbols (`use {std.List} = @root()`)
- [ ] Auto-complete for record/struct fields
- [ ] Auto-complete for enum variants
- [ ] Diagnostic squiggles for type errors in editor

### Formatter

- [ ] Format `@Result<D, E>` return type annotations consistently
- [ ] Format `comptime` param modifiers consistently with type constraints
- [ ] Format `@Context<B, R>` interface implementations

---

## Done

### @Result(D, E) → @Result<D, E> migration ✓

- [x] Refactor `TypeRef.builtin` to `TypeRef.generic` with `is_builtin` flag (`ast.zig`)
- [x] Parse `@Name<T1, T2>` as builtin generic, `Name<T1, T2>` as user generic (`parser.zig`)
- [x] Emit `removedBuiltinType` error for old `@Name(...)` parenthesis syntax
- [x] Remove `@Result` from `inferBuiltinCallReturnType` (`infer.zig`)
- [x] Update `appendTypeRefStr` and `resolveTypeRefInContext` for `.generic` with `is_builtin`
- [x] Update formatter, TypeScript codegen, LSP hover
- [x] Define `Result<R, E>` as generic enum in `builtins.d.bp`
- [x] Update error messages, all tests, regenerate all snapshots

### typeinfo → typeparam migration ✓

- [x] Remove `typeinfo` keyword/token from lexer, AST, parser
- [x] Replace builtins.d.bp `typeinfo` params with `comptime T: typeparam`
- [x] Formatter: `comptime` params output as `comptime name: type`

### Runtime expansion ✓

- [x] Add `wasm` + `beam` variants to `Runtime` enum (`eval.zig`)
- [x] Create `comptime/runtime/wasm.zig` (WAT via wasmtime) and `beam.zig` (BEAM via erlang)
- [x] Update codegen configs for comptime runtimes

### @print test coverage ✓

- [x] Add `@print` to ~20 codegen tests + ~10 comptime tests
- [x] Add 9 new `@print` dedicated tests
- [x] Regenerate all snapshots (4 runtimes × 4 targets)

### Use syntax migration (parcial) ✓

- [x] AST: `Source` type usa `*Expr`, `UseDecl.imports` usa `[]const ImportPath`
- [x] Lexer: `@` + identifier já parseado como `builtinIdent`
- [x] Parser: `=` + `parseExpr` para source, `parseDottedPath` para imports
- [x] Formatter + codegen emitters atualizados
- [x] Parser tests + format tests + codegen snapshots atualizados
