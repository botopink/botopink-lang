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
            "name": "v",
            "typeRef": {
              "optional": {
                "named": "i32"
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
          "named": "i32"
        },
        "typeGuardParam": null,
        "body": [
          {
            "expr": {
              "branch": {
                "loc": {
                  "line": 2,
                  "col": 5
                },
                "kind": {
                  "if_": {
                    "cond": {
                      "identifier": {
                        "loc": {
                          "line": 2,
                          "col": 9
                        },
                        "kind": {
                          "ident": "v"
                        }
                      }
                    },
                    "binding": "x",
                    "then_": [
                      {
                        "expr": {
                          "literal": {
                            "loc": {
                              "line": 3,
                              "col": 9
                            },
                            "kind": {
                              "comment": {
                                "kind": {
                                  "normal": ""
                                },
                                "text": "the binding is the block's prologue, the comment is its body"
                              }
                            }
                          }
                        },
                        "emptyLinesBefore": 0
                      },
                      {
                        "expr": {
                          "call": {
                            "loc": {
                              "line": 4,
                              "col": 9
                            },
                            "kind": {
                              "call": {
                                "receiver": null,
                                "callee": "println",
                                "is_builtin": false,
                                "is_tagged": false,
                                "optional": false,
                                "args": [
                                  {
                                    "label": null,
                                    "value": {
                                      "literal": {
                                        "loc": {
                                          "line": 4,
                                          "col": 17
                                        },
                                        "kind": {
                                          "stringLit": "has"
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
                    ],
                    "else_": null
                  }
                }
              }
            },
            "emptyLinesBefore": 0
          },
          {
            "expr": {
              "jump": {
                "loc": {
                  "line": 6,
                  "col": 5
                },
                "kind": {
                  "return": {
                    "literal": {
                      "loc": {
                        "line": 6,
                        "col": 12
                      },
                      "kind": {
                        "numberLit": "1"
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