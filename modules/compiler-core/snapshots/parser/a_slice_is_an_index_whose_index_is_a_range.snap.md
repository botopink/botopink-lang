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
            "name": "i",
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
                    "name": "a",
                    "value": {
                      "call": {
                        "loc": {
                          "line": 2,
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
                                      "line": 2,
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
                                  "collection": {
                                    "loc": {
                                      "line": 2,
                                      "col": 17
                                    },
                                    "kind": {
                                      "range": {
                                        "start": {
                                          "literal": {
                                            "loc": {
                                              "line": 2,
                                              "col": 16
                                            },
                                            "kind": {
                                              "numberLit": "0"
                                            }
                                          }
                                        },
                                        "end": {
                                          "literal": {
                                            "loc": {
                                              "line": 2,
                                              "col": 19
                                            },
                                            "kind": {
                                              "numberLit": "2"
                                            }
                                          }
                                        }
                                      }
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
                  "line": 3,
                  "col": 5
                },
                "kind": {
                  "localBind": {
                    "name": "b",
                    "value": {
                      "call": {
                        "loc": {
                          "line": 3,
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
                                      "line": 3,
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
                                  "collection": {
                                    "loc": {
                                      "line": 3,
                                      "col": 17
                                    },
                                    "kind": {
                                      "range": {
                                        "start": {
                                          "literal": {
                                            "loc": {
                                              "line": 3,
                                              "col": 16
                                            },
                                            "kind": {
                                              "numberLit": "0"
                                            }
                                          }
                                        },
                                        "end": null
                                      }
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
                    "name": "c",
                    "value": {
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
                                  "collection": {
                                    "loc": {
                                      "line": 4,
                                      "col": 17
                                    },
                                    "kind": {
                                      "range": {
                                        "start": {
                                          "identifier": {
                                            "loc": {
                                              "line": 4,
                                              "col": 16
                                            },
                                            "kind": {
                                              "ident": "i"
                                            }
                                          }
                                        },
                                        "end": {
                                          "binaryOp": {
                                            "loc": {
                                              "line": 4,
                                              "col": 21
                                            },
                                            "op": "add",
                                            "lhs": {
                                              "identifier": {
                                                "loc": {
                                                  "line": 4,
                                                  "col": 19
                                                },
                                                "kind": {
                                                  "ident": "i"
                                                }
                                              }
                                            },
                                            "rhs": {
                                              "literal": {
                                                "loc": {
                                                  "line": 4,
                                                  "col": 23
                                                },
                                                "kind": {
                                                  "numberLit": "2"
                                                }
                                              }
                                            }
                                          }
                                        }
                                      }
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
                  "line": 5,
                  "col": 5
                },
                "kind": {
                  "return": {
                    "literal": {
                      "loc": {
                        "line": 5,
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