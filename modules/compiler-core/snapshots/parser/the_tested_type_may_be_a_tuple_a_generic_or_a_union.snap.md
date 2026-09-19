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
              "binding": {
                "loc": {
                  "line": 2,
                  "col": 5
                },
                "kind": {
                  "localBind": {
                    "name": "t",
                    "value": {
                      "call": {
                        "loc": {
                          "line": 2,
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
                                      "line": 2,
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
                              "tuple_": [
                                {
                                  "named": "i32"
                                },
                                {
                                  "named": "string"
                                }
                              ]
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
              "binding": {
                "loc": {
                  "line": 3,
                  "col": 5
                },
                "kind": {
                  "localBind": {
                    "name": "g",
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
                              "generic": {
                                "name": "Box",
                                "args": [
                                  {
                                    "named": "unknown"
                                  }
                                ],
                                "is_builtin": false
                              }
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
              "binding": {
                "loc": {
                  "line": 4,
                  "col": 5
                },
                "kind": {
                  "localBind": {
                    "name": "u",
                    "value": {
                      "call": {
                        "loc": {
                          "line": 4,
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
                                      "line": 4,
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
                              "generic": {
                                "name": "|",
                                "args": [
                                  {
                                    "named": "i32"
                                  },
                                  {
                                    "named": "string"
                                  }
                                ],
                                "is_builtin": false
                              }
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
                  "line": 5,
                  "col": 5
                },
                "kind": {
                  "return": {
                    "identifier": {
                      "loc": {
                        "line": 5,
                        "col": 12
                      },
                      "kind": {
                        "ident": "t"
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