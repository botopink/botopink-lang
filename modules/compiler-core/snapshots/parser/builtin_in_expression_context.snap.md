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
        "name": "doubled",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [
          {
            "name": "x",
            "typeRef": {
              "named": "Int"
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "defaultVal": null
          }
        ],
        "returnType": {
          "named": "Int"
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
                    "binaryOp": {
                      "loc": {
                        "line": 2,
                        "col": 20
                      },
                      "op": "add",
                      "lhs": {
                        "call": {
                          "loc": {
                            "line": 2,
                            "col": 12
                          },
                          "kind": {
                            "call": {
                              "receiver": null,
                              "callee": "abs",
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
                                        "col": 17
                                      },
                                      "kind": {
                                        "ident": "x"
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
                      "rhs": {
                        "call": {
                          "loc": {
                            "line": 2,
                            "col": 22
                          },
                          "kind": {
                            "call": {
                              "receiver": null,
                              "callee": "abs",
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
                                        "col": 27
                                      },
                                      "kind": {
                                        "ident": "x"
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