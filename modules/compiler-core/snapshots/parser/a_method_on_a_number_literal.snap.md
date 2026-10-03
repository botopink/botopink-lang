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
        "returnType": {
          "named": "i32"
        },
        "typeGuardParam": null,
        "body": [
          {
            "expr": {
              "binding": {
                "loc": {
                  "line": 2,
                  "col": 5
                },
                "kind": {
                  "localBind": {
                    "name": "a",
                    "value": {
                      "identifier": {
                        "loc": {
                          "line": 2,
                          "col": 27
                        },
                        "kind": {
                          "identAccess": {
                            "receiver": {
                              "call": {
                                "loc": {
                                  "line": 2,
                                  "col": 16
                                },
                                "kind": {
                                  "call": {
                                    "receiver": {
                                      "literal": {
                                        "loc": {
                                          "line": 2,
                                          "col": 13
                                        },
                                        "kind": {
                                          "numberLit": "42"
                                        }
                                      }
                                    },
                                    "callee": "toString",
                                    "is_builtin": false,
                                    "is_tagged": false,
                                    "optional": false,
                                    "args": [],
                                    "trailing": []
                                  }
                                }
                              }
                            },
                            "member": "length",
                            "optional": false
                          }
                        }
                      }
                    },
                    "mutable": false,
                    "typeAnnotation": null
                  }
                }
              }
            },
            "emptyLinesBefore": 0
          },
          {
            "expr": {
              "binding": {
                "loc": {
                  "line": 3,
                  "col": 5
                },
                "kind": {
                  "localBind": {
                    "name": "b",
                    "value": {
                      "identifier": {
                        "loc": {
                          "line": 3,
                          "col": 28
                        },
                        "kind": {
                          "identAccess": {
                            "receiver": {
                              "call": {
                                "loc": {
                                  "line": 3,
                                  "col": 17
                                },
                                "kind": {
                                  "call": {
                                    "receiver": {
                                      "literal": {
                                        "loc": {
                                          "line": 3,
                                          "col": 13
                                        },
                                        "kind": {
                                          "numberLit": "3.0"
                                        }
                                      }
                                    },
                                    "callee": "toString",
                                    "is_builtin": false,
                                    "is_tagged": false,
                                    "optional": false,
                                    "args": [],
                                    "trailing": []
                                  }
                                }
                              }
                            },
                            "member": "length",
                            "optional": false
                          }
                        }
                      }
                    },
                    "mutable": false,
                    "typeAnnotation": null
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
                  "line": 4,
                  "col": 5
                },
                "kind": {
                  "return": {
                    "binaryOp": {
                      "loc": {
                        "line": 4,
                        "col": 14
                      },
                      "op": "add",
                      "lhs": {
                        "identifier": {
                          "loc": {
                            "line": 4,
                            "col": 12
                          },
                          "kind": {
                            "ident": "a"
                          }
                        }
                      },
                      "rhs": {
                        "identifier": {
                          "loc": {
                            "line": 4,
                            "col": 16
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