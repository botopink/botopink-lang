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
              "named": "unknown"
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "default": null
          }
        ],
        "returnType": {
          "named": "bool"
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
                      "call": {
                        "loc": {
                          "line": 2,
                          "col": 11
                        },
                        "kind": {
                          "call": {
                            "receiver": null,
                            "callee": "is",
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
                                      "col": 9
                                    },
                                    "kind": {
                                      "ident": "a"
                                    }
                                  }
                                },
                                "comments": [],
                                "is_default_inj": false
                              }
                            ],
                            "trailing": [],
                            "isType": {
                              "named": "i32"
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
                              "line": 2,
                              "col": 21
                            },
                            "kind": {
                              "call": {
                                "receiver": null,
                                "callee": "print",
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
                                          "col": 28
                                        },
                                        "kind": {
                                          "ident": "a"
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
                            "callee": "is",
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
                                      "ident": "a"
                                    }
                                  }
                                },
                                "comments": [],
                                "is_default_inj": false
                              }
                            ],
                            "trailing": [],
                            "isType": {
                              "named": "string"
                            }
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
                    "identifier": {
                      "loc": {
                        "line": 4,
                        "col": 12
                      },
                      "kind": {
                        "ident": "b"
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