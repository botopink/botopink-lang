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
                          "col": 13
                        },
                        "kind": {
                          "ident": "true"
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
                          "col": 13
                        },
                        "kind": {
                          "ident": "false"
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
              "branch": {
                "loc": {
                  "line": 4,
                  "col": 5
                },
                "kind": {
                  "if_": {
                    "cond": {
                      "binaryOp": {
                        "loc": {
                          "line": 4,
                          "col": 11
                        },
                        "op": "and",
                        "lhs": {
                          "identifier": {
                            "loc": {
                              "line": 4,
                              "col": 9
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
                              "col": 14
                            },
                            "kind": {
                              "ident": "b"
                            }
                          }
                        }
                      }
                    },
                    "binding": null,
                    "then_": [
                      {
                        "expr": {
                          "call": {
                            "loc": {
                              "line": 4,
                              "col": 27
                            },
                            "kind": {
                              "call": {
                                "receiver": {
                                  "identifier": {
                                    "loc": {
                                      "line": 4,
                                      "col": 19
                                    },
                                    "kind": {
                                      "ident": "console"
                                    }
                                  }
                                },
                                "callee": "log",
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
                                          "col": 31
                                        },
                                        "kind": {
                                          "stringLit": "both"
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
              "branch": {
                "loc": {
                  "line": 5,
                  "col": 5
                },
                "kind": {
                  "if_": {
                    "cond": {
                      "binaryOp": {
                        "loc": {
                          "line": 5,
                          "col": 11
                        },
                        "op": "or",
                        "lhs": {
                          "identifier": {
                            "loc": {
                              "line": 5,
                              "col": 9
                            },
                            "kind": {
                              "ident": "a"
                            }
                          }
                        },
                        "rhs": {
                          "identifier": {
                            "loc": {
                              "line": 5,
                              "col": 14
                            },
                            "kind": {
                              "ident": "b"
                            }
                          }
                        }
                      }
                    },
                    "binding": null,
                    "then_": [
                      {
                        "expr": {
                          "call": {
                            "loc": {
                              "line": 5,
                              "col": 27
                            },
                            "kind": {
                              "call": {
                                "receiver": {
                                  "identifier": {
                                    "loc": {
                                      "line": 5,
                                      "col": 19
                                    },
                                    "kind": {
                                      "ident": "console"
                                    }
                                  }
                                },
                                "callee": "log",
                                "is_builtin": false,
                                "is_tagged": false,
                                "optional": false,
                                "args": [
                                  {
                                    "label": null,
                                    "value": {
                                      "literal": {
                                        "loc": {
                                          "line": 5,
                                          "col": 31
                                        },
                                        "kind": {
                                          "stringLit": "either"
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
              "branch": {
                "loc": {
                  "line": 6,
                  "col": 5
                },
                "kind": {
                  "if_": {
                    "cond": {
                      "binaryOp": {
                        "loc": {
                          "line": 6,
                          "col": 19
                        },
                        "op": "and",
                        "lhs": {
                          "binaryOp": {
                            "loc": {
                              "line": 6,
                              "col": 11
                            },
                            "op": "eq",
                            "lhs": {
                              "identifier": {
                                "loc": {
                                  "line": 6,
                                  "col": 9
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
                                  "col": 14
                                },
                                "kind": {
                                  "ident": "true"
                                }
                              }
                            }
                          }
                        },
                        "rhs": {
                          "binaryOp": {
                            "loc": {
                              "line": 6,
                              "col": 24
                            },
                            "op": "ne",
                            "lhs": {
                              "identifier": {
                                "loc": {
                                  "line": 6,
                                  "col": 22
                                },
                                "kind": {
                                  "ident": "b"
                                }
                              }
                            },
                            "rhs": {
                              "identifier": {
                                "loc": {
                                  "line": 6,
                                  "col": 27
                                },
                                "kind": {
                                  "ident": "true"
                                }
                              }
                            }
                          }
                        }
                      }
                    },
                    "binding": null,
                    "then_": [
                      {
                        "expr": {
                          "call": {
                            "loc": {
                              "line": 6,
                              "col": 43
                            },
                            "kind": {
                              "call": {
                                "receiver": {
                                  "identifier": {
                                    "loc": {
                                      "line": 6,
                                      "col": 35
                                    },
                                    "kind": {
                                      "ident": "console"
                                    }
                                  }
                                },
                                "callee": "log",
                                "is_builtin": false,
                                "is_tagged": false,
                                "optional": false,
                                "args": [
                                  {
                                    "label": null,
                                    "value": {
                                      "literal": {
                                        "loc": {
                                          "line": 6,
                                          "col": 47
                                        },
                                        "kind": {
                                          "stringLit": "mixed"
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
          }
        ]
      }
    }
  ]
}
```