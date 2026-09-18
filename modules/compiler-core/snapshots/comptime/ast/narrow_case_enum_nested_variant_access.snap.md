----- SOURCE CODE -- main.bp
```botopink
type Payload(code: i32, msg: string)
type Result_ { OkData(data: Payload), Fail }
fn describe(r: Result_) -> string {
    return case r {
        OkData(d) -> d.msg;
        Fail -> "failed";
    };
}
fn main() {
    @print(describe(Result_.OkData(Payload(code: 200, msg: "ok"))));
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "record_def",
      "name": "Payload",
      "id": 0,
      "fields": {
        "code": "i32",
        "msg": "string"
      }
    },
    {
      "ast": "enum_def",
      "name": "Result_",
      "id": 0
    },
    {
      "ast": "fn_def",
      "name": "describe",
      "is_pub": false,
      "params": [
        {
          "name": "r",
          "type": "Result_"
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "return case r {"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "main",
      "is_pub": false,
      "params": [],
      "return_type": "void",
      "body": [
        {
          "source": "@print(describe(Result_.OkData(Payload(code: 200, msg: \"ok\"))));"
        }
      ]
    }
  ]
}
```

