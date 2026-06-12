```json
{
  "decls": [
    {
      "fn": {
        "isPub": false,
        "effect": null,
        "isDeclare": false,
        "isDefault": false,
        "label": null,
        "name": "greet",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [
          {
            "name": "name",
            "typeRef": {
              "named": "string"
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "default": {
              "literal": {
                "loc": {
                  "line": 1,
                  "col": 25
                },
                "kind": {
                  "stringLit": "world"
                }
              }
            }
          }
        ],
        "returnType": {
          "named": "string"
        },
        "body": [
          {
            "expr": {
              "jump": {
                "loc": {
                  "line": 2,
                  "col": 5
                },
                "kind": {
                  "return": {
                    "identifier": {
                      "loc": {
                        "line": 2,
                        "col": 12
                      },
                      "kind": {
                        "ident": "name"
                      }
                    }
                  }
                }
              }
            },
            "emptyLinesBefore": 0
          }
        ]
      }
    }
  ]
}
```