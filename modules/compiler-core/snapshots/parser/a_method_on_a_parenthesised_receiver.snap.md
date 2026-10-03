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
              "named": "i32"
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
              "named": "i32"
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
                    "name": "n",
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
                                  "grouped": {
                                    "literal": {
                                      "loc": {
                                        "line": 2,
                                        "col": 14
                                      },
                                      "kind": {
                                        "stringLit": "ab"
                                      }
                                    }
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
                    "name": "s",
                    "value": {
                      "call": {
                        "loc": {
                          "line": 3,
                          "col": 22
                        },
                        "kind": {
                          "call": {
                            "receiver": {
                              "collection": {
                                "loc": {
                                  "line": 3,
                                  "col": 13
                                },
                                "kind": {
                                  "grouped": {
                                    "binaryOp": {
                                      "loc": {
                                        "line": 3,
                                        "col": 16
                                      },
                                      "op": "eq",
                                      "lhs": {
                                        "identifier": {
                                          "loc": {
                                            "line": 3,
                                            "col": 14
                                          },
                                          "kind": {
                                            "ident": "a"
                                          }
                                        }
                                      },
                                      "rhs": {
                                        "identifier": {
                                          "loc": {
                                            "line": 3,
                                            "col": 19
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
                    "name": "m",
                    "value": {
                      "identifier": {
                        "loc": {
                          "line": 4,
                          "col": 32
                        },
                        "kind": {
                          "identAccess": {
                            "receiver": {
                              "call": {
                                "loc": {
                                  "line": 4,
                                  "col": 21
                                },
                                "kind": {
                                  "call": {
                                    "receiver": {
                                      "collection": {
                                        "loc": {
                                          "line": 4,
                                          "col": 13
                                        },
                                        "kind": {
                                          "grouped": {
                                            "binaryOp": {
                                              "loc": {
                                                "line": 4,
                                                "col": 16
                                              },
                                              "op": "add",
                                              "lhs": {
                                                "identifier": {
                                                  "loc": {
                                                    "line": 4,
                                                    "col": 14
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
                                                    "col": 18
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
                  "line": 5,
                  "col": 5
                },
                "kind": {
                  "return": {
                    "binaryOp": {
                      "loc": {
                        "line": 5,
                        "col": 14
                      },
                      "op": "add",
                      "lhs": {
                        "identifier": {
                          "loc": {
                            "line": 5,
                            "col": 12
                          },
                          "kind": {
                            "ident": "n"
                          }
                        }
                      },
                      "rhs": {
                        "identifier": {
                          "loc": {
                            "line": 5,
                            "col": 16
                          },
                          "kind": {
                            "ident": "m"
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