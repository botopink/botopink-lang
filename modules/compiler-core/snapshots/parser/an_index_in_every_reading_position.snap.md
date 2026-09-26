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
            "name": "d",
            "typeRef": {
              "generic": {
                "name": "Dict",
                "args": [
                  {
                    "named": "string"
                  },
                  {
                    "named": "i32"
                  }
                ],
                "is_builtin": false
              }
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "default": null
          },
          {
            "name": "s",
            "typeRef": {
              "named": "string"
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
                          "col": 14
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
                                      "ident": "d"
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
                                      "col": 15
                                    },
                                    "kind": {
                                      "stringLit": "k"
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
                          "col": 14
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
                                      "ident": "s"
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
                                      "col": 15
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
                  "line": 5,
                  "col": 5
                },
                "kind": {
                  "localBind": {
                    "name": "e",
                    "value": {
                      "call": {
                        "loc": {
                          "line": 5,
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
                                      "line": 5,
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
                                  "binaryOp": {
                                    "loc": {
                                      "line": 5,
                                      "col": 18
                                    },
                                    "op": "add",
                                    "lhs": {
                                      "identifier": {
                                        "loc": {
                                          "line": 5,
                                          "col": 16
                                        },
                                        "kind": {
                                          "ident": "i"
                                        }
                                      }
                                    },
                                    "rhs": {
                                      "literal": {
                                        "loc": {
                                          "line": 5,
                                          "col": 20
                                        },
                                        "kind": {
                                          "numberLit": "1"
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
                  "line": 6,
                  "col": 5
                },
                "kind": {
                  "localBind": {
                    "name": "g",
                    "value": {
                      "call": {
                        "loc": {
                          "line": 6,
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
                                      "line": 6,
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
                                  "call": {
                                    "loc": {
                                      "line": 6,
                                      "col": 18
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
                                                  "line": 6,
                                                  "col": 16
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
                                                  "line": 6,
                                                  "col": 19
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
                  "line": 7,
                  "col": 5
                },
                "kind": {
                  "return": {
                    "binaryOp": {
                      "loc": {
                        "line": 7,
                        "col": 22
                      },
                      "op": "add",
                      "lhs": {
                        "binaryOp": {
                          "loc": {
                            "line": 7,
                            "col": 18
                          },
                          "op": "add",
                          "lhs": {
                            "binaryOp": {
                              "loc": {
                                "line": 7,
                                "col": 14
                              },
                              "op": "add",
                              "lhs": {
                                "identifier": {
                                  "loc": {
                                    "line": 7,
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
                                    "line": 7,
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
                                "line": 7,
                                "col": 20
                              },
                              "kind": {
                                "ident": "e"
                              }
                            }
                          }
                        }
                      },
                      "rhs": {
                        "identifier": {
                          "loc": {
                            "line": 7,
                            "col": 24
                          },
                          "kind": {
                            "ident": "g"
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