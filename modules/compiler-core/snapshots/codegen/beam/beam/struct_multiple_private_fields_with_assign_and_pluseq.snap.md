----- SOURCE CODE -- main.bp
```botopink
val BankAccount = struct {
    _balance: f64 = 0.0,
    _owner: string = "",
    fn deposit(self: Self, amount: f64) {
        self._balance += amount;
    }
    fn setOwner(self: Self, name: string) {
        self._owner = name;
    }
    get balance(self: Self) -> f64 {
        return self._balance;
    }
    get owner(self: Self) -> string {
        return self._owner;
    }
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, [{'BankAccount_balance', 1}, {'BankAccount_owner', 1}]}.
{attributes, []}.
{labels, 12}.

{function, 'BankAccount_deposit', 2, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, 'BankAccount_deposit'}, 2}.
  {label, 3}.
    {allocate, 0, 2}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {put_map_exact, {f, 0}, {x, 0}, {x, 0}, 3, {list, [{atom, _balance}, {x, 2}]}}.
    {move, {x, 0}, {x, 0}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, 'BankAccount_setOwner', 2, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, 'BankAccount_setOwner'}, 2}.
  {label, 5}.
    {allocate, 0, 2}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {put_map_exact, {f, 0}, {x, 0}, {x, 0}, 3, {list, [{atom, _owner}, {x, 2}]}}.
    {move, {x, 0}, {x, 0}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, 'BankAccount_balance', 1, 7}.
  {label, 6}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, 'BankAccount_balance'}, 1}.
  {label, 7}.
    {allocate, 0, 1}.
    {test, is_map, {f, 10}, [{x, 0}]}.
    {get_map_elements, {f, 10}, {x, 0}, {list, [{atom, '_balance'}, {x, 0}]}}.
  {label, 10}.
    {deallocate, 0}.
    return.

{function, 'BankAccount_owner', 1, 9}.
  {label, 8}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, 'BankAccount_owner'}, 1}.
  {label, 9}.
    {allocate, 0, 1}.
    {test, is_map, {f, 11}, [{x, 0}]}.
    {get_map_elements, {f, 11}, {x, 0}, {list, [{atom, '_owner'}, {x, 0}]}}.
  {label, 11}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
