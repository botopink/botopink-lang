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
        "name": "f",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [
          {
            "name": "a",
            "typeRef": {
              "named": "unknown"
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "default": null
          },
          {
            "name": "b",
            "typeRef": {
              "named": "bool"
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "default": null
          }
        ],
        "returnType": {
          "named": "bool"
        },
        "typeGuardParam": null,
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
                    "binaryOp": {
                      "loc": {
                        "line": 2,
                        "col": 21
                      },
                      "op": "eq",
                      "lhs": {
                        "call": {
                          "loc": {
                            "line": 2,
                            "col": 14
                          },
                          "kind": {
                            "call": {
                              "receiver": null,
                              "callee": "is",
                              "is_builtin": true,
                              "is_tagged": false,
                              "optional": false,
                              "args": [
                                {
                                  "label": null,
                                  "value": {
                                    "identifier": {
                                      "loc": {
                                        "line": 2,
                                        "col": 12
                                      },
                                      "kind": {
                                        "ident": "a"
                                      }
                                    }
                                  },
                                  "comments": [],
                                  "is_default_inj": false
                                }
                              ],
                              "trailing": [],
                              "isType": {
                                "named": "i32"
                              }
                            }
                          }
                        }
                      },
                      "rhs": {
                        "identifier": {
                          "loc": {
                            "line": 2,
                            "col": 24
                          },
                          "kind": {
                            "ident": "b"
                          }
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
  ]
}
```