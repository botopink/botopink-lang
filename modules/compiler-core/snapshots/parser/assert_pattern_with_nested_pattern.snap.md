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
                      "variant": {
                        "name": "Ok",
                        "payload": {
                          "literals": [
                            {
                              "list": {
                                "elems": [
                                  {
                                    "bind": "first"
                                  }
                                ],
                                "spread": ""
                              }
                            }
                          ]
                        }
                      }
                    },
                    "expr": {
                      "identifier": {
                        "loc": {
                          "line": 2,
                          "col": 34
                        },
                        "kind": {
                          "ident": "result"
                        }
                      }
                    },
                    "handler": {
                      "jump": {
                        "loc": {
                          "line": 2,
                          "col": 47
                        },
                        "kind": {
                          "throw_": {
                            "call": {
                              "loc": {
                                "line": 2,
                                "col": 53
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
                                            "col": 59
                                          },
                                          "kind": {
                                            "stringLit": "not ok"
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