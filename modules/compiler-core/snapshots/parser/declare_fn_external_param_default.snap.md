```json
{
  "decls": [
    {
      "fn": {
        "isPub": true,
        "effect": null,
        "isDeclare": true,
        "isDefault": false,
        "label": null,
        "name": "slice",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [
          {
            "name": "External.Erlang",
            "args": [
              "\"string\"",
              "\"slice\""
            ],
            "is_builtin": true
          }
        ],
        "genericParams": [],
        "params": [
          {
            "name": "s",
            "typeRef": {
              "named": "string"
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "default": null
          },
          {
            "name": "start",
            "typeRef": {
              "named": "i32"
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "default": null
          },
          {
            "name": "end",
            "typeRef": {
              "named": "i32"
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "default": {
              "unaryOp": {
                "loc": {
                  "line": 2,
                  "col": 56
                },
                "op": "neg",
                "expr": {
                  "literal": {
                    "loc": {
                      "line": 2,
                      "col": 57
                    },
                    "kind": {
                      "numberLit": "1"
                    }
                  }
                }
              }
            }
          }
        ],
        "returnType": {
          "named": "string"
        },
        "body": []
      }
    }
  ]
}
```