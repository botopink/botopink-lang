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
                        "elems": [],
                        "spread": null
                      }
                    },
                    "expr": {
                      "identifier": {
                        "loc": {
                          "line": 2,
                          "col": 21
                        },
                        "kind": {
                          "ident": "list"
                        }
                      }
                    },
                    "handler": {
                      "jump": {
                        "loc": {
                          "line": 2,
                          "col": 32
                        },
                        "kind": {
                          "throw_": {
                            "call": {
                              "loc": {
                                "line": 2,
                                "col": 38
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
                                            "col": 44
                                          },
                                          "kind": {
                                            "stringLit": "not empty"
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