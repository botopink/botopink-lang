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
        "name": "add",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [
          {
            "name": "a",
            "typeRef": {
              "named": "i32"
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "defaultVal": null
          },
          {
            "name": "b",
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
        "body": [
          {
            "expr": {
              "jump": {
                "loc": {
                  "line": 1,
                  "col": 33
                },
                "kind": {
                  "return": {
                    "binaryOp": {
                      "loc": {
                        "line": 1,
                        "col": 42
                      },
                      "op": "add",
                      "lhs": {
                        "identifier": {
                          "loc": {
                            "line": 1,
                            "col": 40
                          },
                          "kind": {
                            "ident": "a"
                          }
                        }
                      },
                      "rhs": {
                        "identifier": {
                          "loc": {
                            "line": 1,
                            "col": 44
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
    },
    {
      "val": {
        "name": "x",
        "isPub": false,
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "typeAnnotation": null,
        "value": {
          "binaryOp": {
            "loc": {
              "line": 2,
              "col": 19
            },
            "op": "eq",
            "lhs": {
              "call": {
                "loc": {
                  "line": 2,
                  "col": 9
                },
                "kind": {
                  "call": {
                    "receiver": null,
                    "callee": "add",
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
                              "col": 13
                            },
                            "kind": {
                              "numberLit": "1"
                            }
                          }
                        },
                        "comments": []
                      },
                      {
                        "label": null,
                        "value": {
                          "literal": {
                            "loc": {
                              "line": 2,
                              "col": 16
                            },
                            "kind": {
                              "numberLit": "2"
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
              "literal": {
                "loc": {
                  "line": 2,
                  "col": 22
                },
                "kind": {
                  "numberLit": "3"
                }
              }
            }
          }
        }
      }
    }
  ]
}
```