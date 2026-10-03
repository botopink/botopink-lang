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
        "name": "rows",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [
          {
            "name": "n",
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
          "array": {
            "named": "i32"
          }
        },
        "typeGuardParam": null,
        "body": [
          {
            "expr": {
              "jump": {
                "loc": {
                  "line": 1,
                  "col": 28
                },
                "kind": {
                  "return": {
                    "collection": {
                      "loc": {
                        "line": 1,
                        "col": 35
                      },
                      "kind": {
                        "arrayLit": {
                          "elems": [
                            {
                              "identifier": {
                                "loc": {
                                  "line": 1,
                                  "col": 36
                                },
                                "kind": {
                                  "ident": "n"
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
                  "line": 3,
                  "col": 5
                },
                "kind": {
                  "localBind": {
                    "name": "a",
                    "value": {
                      "call": {
                        "loc": {
                          "line": 3,
                          "col": 20
                        },
                        "kind": {
                          "call": {
                            "receiver": null,
                            "callee": "[]",
                            "is_builtin": true,
                            "is_tagged": false,
                            "optional": false,
                            "args": [
                              {
                                "label": null,
                                "value": {
                                  "call": {
                                    "loc": {
                                      "line": 3,
                                      "col": 13
                                    },
                                    "kind": {
                                      "call": {
                                        "receiver": null,
                                        "callee": "rows",
                                        "is_builtin": false,
                                        "is_tagged": false,
                                        "optional": false,
                                        "args": [
                                          {
                                            "label": null,
                                            "value": {
                                              "literal": {
                                                "loc": {
                                                  "line": 3,
                                                  "col": 18
                                                },
                                                "kind": {
                                                  "numberLit": "1"
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
                                "comments": [],
                                "is_default_inj": false
                              },
                              {
                                "label": null,
                                "value": {
                                  "literal": {
                                    "loc": {
                                      "line": 3,
                                      "col": 21
                                    },
                                    "kind": {
                                      "numberLit": "0"
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
                    "name": "b",
                    "value": {
                      "identifier": {
                        "loc": {
                          "line": 4,
                          "col": 30
                        },
                        "kind": {
                          "identAccess": {
                            "receiver": {
                              "call": {
                                "loc": {
                                  "line": 4,
                                  "col": 19
                                },
                                "kind": {
                                  "call": {
                                    "receiver": {
                                      "call": {
                                        "loc": {
                                          "line": 4,
                                          "col": 15
                                        },
                                        "kind": {
                                          "call": {
                                            "receiver": null,
                                            "callee": "[]",
                                            "is_builtin": true,
                                            "is_tagged": false,
                                            "optional": false,
                                            "args": [
                                              {
                                                "label": null,
                                                "value": {
                                                  "identifier": {
                                                    "loc": {
                                                      "line": 4,
                                                      "col": 13
                                                    },
                                                    "kind": {
                                                      "ident": "xs"
                                                    }
                                                  }
                                                },
                                                "comments": [],
                                                "is_default_inj": false
                                              },
                                              {
                                                "label": null,
                                                "value": {
                                                  "literal": {
                                                    "loc": {
                                                      "line": 4,
                                                      "col": 16
                                                    },
                                                    "kind": {
                                                      "numberLit": "0"
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
                  "line": 5,
                  "col": 5
                },
                "kind": {
                  "localBind": {
                    "name": "c",
                    "value": {
                      "call": {
                        "loc": {
                          "line": 5,
                          "col": 21
                        },
                        "kind": {
                          "call": {
                            "receiver": null,
                            "callee": "[]",
                            "is_builtin": true,
                            "is_tagged": false,
                            "optional": false,
                            "args": [
                              {
                                "label": null,
                                "value": {
                                  "collection": {
                                    "loc": {
                                      "line": 5,
                                      "col": 13
                                    },
                                    "kind": {
                                      "grouped": {
                                        "collection": {
                                          "loc": {
                                            "line": 5,
                                            "col": 14
                                          },
                                          "kind": {
                                            "arrayLit": {
                                              "elems": [
                                                {
                                                  "literal": {
                                                    "loc": {
                                                      "line": 5,
                                                      "col": 15
                                                    },
                                                    "kind": {
                                                      "numberLit": "1"
                                                    }
                                                  }
                                                },
                                                {
                                                  "literal": {
                                                    "loc": {
                                                      "line": 5,
                                                      "col": 18
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
                                      }
                                    }
                                  }
                                },
                                "comments": [],
                                "is_default_inj": false
                              },
                              {
                                "label": null,
                                "value": {
                                  "literal": {
                                    "loc": {
                                      "line": 5,
                                      "col": 22
                                    },
                                    "kind": {
                                      "numberLit": "0"
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