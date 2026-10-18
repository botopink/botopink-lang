```json
{
  "decls": [
    {
      "fn": {
        "isPub": true,
        "effect": null,
        "isDeclare": false,
        "isDefault": false,
        "label": null,
        "name": "wrap",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [
          {
            "name": "T",
            "typeRef": {
              "typeparam": []
            },
            "typeName": "",
            "modifier": "comptime",
            "destruct": null,
            "default": null,
            "exprWrapped": true,
            "arrival": "value"
          }
        ],
        "returnType": {
          "typeparam": []
        },
        "typeGuardParam": null,
        "body": [
          {
            "expr": {
              "call": {
                "loc": {
                  "line": 2,
                  "col": 5
                },
                "kind": {
                  "call": {
                    "receiver": null,
                    "callee": "panic",
                    "is_builtin": false,
                    "is_tagged": false,
                    "optional": false,
                    "args": [
                      {
                        "label": null,
                        "value": {
                          "literal": {
                            "loc": {
                              "line": 2,
                              "col": 11
                            },
                            "kind": {
                              "stringLit": "not implemented"
                            }
                          }
                        },
                        "comments": [],
                        "is_default_inj": false
                      }
                    ],
                    "trailing": []
                  }
                }
              }
            },
            "emptyLinesBefore": 0
          }
        ]
      }
    },
    {
      "use": {
        "imports": [
          {
            "segments": [
              "failure",
              "panic"
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