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
        "name": "isString",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [
          {
            "name": "x",
            "typeRef": {
              "optional": {
                "named": "string"
              }
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "default": null
          }
        ],
        "returnType": {
          "named": "string"
        },
        "typeGuardParam": "x",
        "body": [
          {
            "expr": {
              "jump": {
                "loc": {
                  "line": 1,
                  "col": 42
                },
                "kind": {
                  "return": {
                    "identifier": {
                      "loc": {
                        "line": 1,
                        "col": 49
                      },
                      "kind": {
                        "ident": "true"
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