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
                  "typeinfoConstraints": null,
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
                  "typeinfoConstraints": null,
                  "fnType": null,
                  "destruct": null,
                  "defaultVal": null
                }
              ],
              "body": [
                {
                  "expr": {
                    "controlFlow": {
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