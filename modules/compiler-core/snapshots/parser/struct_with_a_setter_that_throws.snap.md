```json
{
  "decls": [
    {
      "struct": {
        "name": "Account",
        "id": 1,
        "isPub": false,
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "implement": [],
        "members": [
          {
            "setter": {
              "name": "balance",
              "params": [
                {
                  "name": "self",
                  "typeRef": {
                    "named": "Self"
                  },
                  "typeName": "",
                  "modifier": "none",
                  "fnType": null,
                  "destruct": null,
                  "defaultVal": null
                },
                {
                  "name": "value",
                  "typeRef": {
                    "named": "number"
                  },
                  "typeName": "",
                  "modifier": "none",
                  "fnType": null,
                  "destruct": null,
                  "defaultVal": null
                }
              ],
              "body": [
                {
                  "expr": {
                    "jump": {
                      "loc": {
                        "line": 3,
                        "col": 9
                      },
                      "kind": {
                        "throw_": {
                          "call": {
                            "loc": {
                              "line": 3,
                              "col": 15
                            },
                            "kind": {
                              "call": {
                                "receiver": null,
                                "callee": "Error",
                                "is_builtin": false,
                                "is_tagged": false,
                                "optional": false,
                                "args": [
                                  {
                                    "label": "msg",
                                    "value": {
                                      "literal": {
                                        "loc": {
                                          "line": 3,
                                          "col": 26
                                        },
                                        "kind": {
                                          "stringLit": "Saldo nao pode ser negativo"
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
                        }
                      }
                    }
                  },
                  "emptyLinesBefore": 0
                }
              ]
            }
          }
        ],
        "trailingComma": false
      }
    }
  ]
}
```