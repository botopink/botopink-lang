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
        "params": [],
        "returnType": null,
        "body": [
          {
            "expr": {
              "comptime_": {
                "loc": {
                  "line": 2,
                  "col": 9
                },
                "kind": {
                  "assertPattern": {
                    "pattern": {
                      "list": {
                        "elems": [
                          {
                            "numberLit": "1"
                          },
                          {
                            "numberLit": "2"
                          },
                          {
                            "numberLit": "3"
                          }
                        ],
                        "spread": null
                      }
                    },
                    "expr": {
                      "identifier": {
                        "loc": {
                          "line": 2,
                          "col": 28
                        },
                        "kind": {
                          "ident": "numbers"
                        }
                      }
                    },
                    "handler": {
                      "jump": {
                        "loc": {
                          "line": 2,
                          "col": 42
                        },
                        "kind": {
                          "throw_": {
                            "call": {
                              "loc": {
                                "line": 2,
                                "col": 48
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
                                      "label": null,
                                      "value": {
                                        "literal": {
                                          "loc": {
                                            "line": 2,
                                            "col": 54
                                          },
                                          "kind": {
                                            "stringLit": "not matching"
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