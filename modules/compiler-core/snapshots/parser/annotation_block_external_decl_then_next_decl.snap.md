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
        "name": "absolute_value",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [
          {
            "name": "external",
            "args": [
              "erlang",
              "\"erlang\"",
              "\"abs\""
            ],
            "is_builtin": true
          }
        ],
        "genericParams": [],
        "params": [
          {
            "name": "n",
            "typeRef": {
              "named": "i32"
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "defaultVal": null
          }
        ],
        "returnType": {
          "named": "i32"
        },
        "body": []
      }
    },
    {
      "fn": {
        "isPub": false,
        "effect": null,
        "isDeclare": false,
        "isDefault": false,
        "label": null,
        "name": "main",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [],
        "returnType": null,
        "body": [
          {
            "expr": {
              "call": {
                "loc": {
                  "line": 5,
                  "col": 5
                },
                "kind": {
                  "call": {
                    "receiver": null,
                    "callee": "absolute_value",
                    "is_builtin": false,
                    "is_tagged": false,
                    "optional": false,
                    "args": [
                      {
                        "label": null,
                        "value": {
                          "unaryOp": {
                            "loc": {
                              "line": 5,
                              "col": 20
                            },
                            "op": "neg",
                            "expr": {
                              "literal": {
                                "loc": {
                                  "line": 5,
                                  "col": 21
                                },
                                "kind": {
                                  "numberLit": "5"
                                }
                              }
                            }
                          }
                        },
                        "comments": []
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
    }
  ]
}
```