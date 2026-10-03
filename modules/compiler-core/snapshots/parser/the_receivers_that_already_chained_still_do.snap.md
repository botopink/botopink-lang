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
            "name": "xs",
            "typeRef": {
              "array": {
                "named": "i32"
              }
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "default": null
          },
          {
            "name": "r",
            "typeRef": {
              "named": "Box"
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
                          "col": 20
                        },
                        "kind": {
                          "identAccess": {
                            "receiver": {
                              "collection": {
                                "loc": {
                                  "line": 2,
                                  "col": 13
                                },
                                "kind": {
                                  "arrayLit": {
                                    "elems": [
                                      {
                                        "literal": {
                                          "loc": {
                                            "line": 2,
                                            "col": 14
                                          },
                                          "kind": {
                                            "numberLit": "1"
                                          }
                                        }
                                      },
                                      {
                                        "literal": {
                                          "loc": {
                                            "line": 2,
                                            "col": 17
                                          },
                                          "kind": {
                                            "numberLit": "2"
                                          }
                                        }
                                      }
                                    ],
                                    "spread": null,
                                    "spreadExpr": null,
                                    "comments": [],
                                    "commentsPerElem": [],
                                    "trailingComma": false
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
                          "col": 31
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
                                          "stringLit": "x"
                                        }
                                      }
                                    },
                                    "callee": "toUpperCase",
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
                  "line": 4,
                  "col": 5
                },
                "kind": {
                  "localBind": {
                    "name": "c",
                    "value": {
                      "identifier": {
                        "loc": {
                          "line": 4,
                          "col": 21
                        },
                        "kind": {
                          "identAccess": {
                            "receiver": {
                              "call": {
                                "loc": {
                                  "line": 4,
                                  "col": 15
                                },
                                "kind": {
                                  "call": {
                                    "receiver": {
                                      "identifier": {
                                        "loc": {
                                          "line": 4,
                                          "col": 13
                                        },
                                        "kind": {
                                          "ident": "r"
                                        }
                                      }
                                    },
                                    "callee": "get",
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
                  "line": 5,
                  "col": 5
                },
                "kind": {
                  "localBind": {
                    "name": "d",
                    "value": {
                      "call": {
                        "loc": {
                          "line": 5,
                          "col": 16
                        },
                        "kind": {
                          "call": {
                            "receiver": {
                              "identifier": {
                                "loc": {
                                  "line": 5,
                                  "col": 13
                                },
                                "kind": {
                                  "ident": "r"
                                }
                              }
                            },
                            "callee": "get",
                            "is_builtin": false,
                            "is_tagged": false,
                            "optional": true,
                            "args": [],
                            "trailing": []
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
                  "line": 6,
                  "col": 5
                },
                "kind": {
                  "return": {
                    "binaryOp": {
                      "loc": {
                        "line": 6,
                        "col": 18
                      },
                      "op": "add",
                      "lhs": {
                        "binaryOp": {
                          "loc": {
                            "line": 6,
                            "col": 14
                          },
                          "op": "add",
                          "lhs": {
                            "identifier": {
                              "loc": {
                                "line": 6,
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
                                "line": 6,
                                "col": 16
                              },
                              "kind": {
                                "ident": "b"
                              }
                            }
                          }
                        }
                      },
                      "rhs": {
                        "identifier": {
                          "loc": {
                            "line": 6,
                            "col": 20
                          },
                          "kind": {
                            "ident": "c"
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