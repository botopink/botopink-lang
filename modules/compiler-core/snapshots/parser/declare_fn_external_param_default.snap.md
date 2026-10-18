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
            "name": "external",
            "args": [
              ".Erlang(\"string:slice($0, $1, $2)\")"
            ],
            "is_builtin": false
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
        "typeGuardParam": null,
        "body": []
      }
    },
    {
      "use": {
        "imports": [
          {
            "segments": [
              "compiler"
            ],
            "activate": false,
            "alias": null
          }
        ],
        "source": {
          "module": "std"
        },
        "package": null,
        "activationOnly": false,
        "docComment": null,
        "comment": null,
        "moduleComment": null
      }
    }
  ]
}
```