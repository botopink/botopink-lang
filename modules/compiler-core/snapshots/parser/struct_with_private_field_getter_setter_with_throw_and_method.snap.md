```json
{
  "decls": [
    {
      "struct": {
        "name": "Account",
        "id": 1,
        "isPub": false,
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "implement": [],
        "members": [
          {
            "field": {
              "name": "_balance",
              "typeRef": {
                "named": "number"
              },
              "init": {
                "literal": {
                  "loc": {
                    "line": 2,
                    "col": 24
                  },
                  "kind": {
                    "numberLit": "0"
                  }
                }
              },
              "annotations": []
            }
          },
          {
            "getter": {
              "name": "balance",
              "selfParam": {
                "name": "self",
                "typeRef": {
                  "named": "Self"
                },
                "typeName": "Self",
                "modifier": "none",
                "fnType": null,
                "destruct": null,
                "defaultVal": null
              },
              "returnType": "number",
              "body": [
                {
                  "expr": {
                    "jump": {
                      "loc": {
                        "line": 4,
                        "col": 9
                      },
                      "kind": {
                        "return": {
                          "identifier": {
                            "loc": {
                              "line": 4,
                              "col": 21
                            },
                            "kind": {
                              "identAccess": {
                                "receiver": {
                                  "identifier": {
                                    "loc": {
                                      "line": 4,
                                      "col": 16
                                    },
                                    "kind": {
                                      "ident": "self"
                                    }
                                  }
                                },
                                "member": "_balance",
                                "optional": false
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
            "setter": {
              "name": "balance",
              "params": [
                {
                  "name": "self",
                  "typeRef": {
                    "named": "Self"
                  },
                  "typeName": "",
                  "modifier": "none",
                  "fnType": null,
                  "destruct": null,
                  "defaultVal": null
                },
                {
                  "name": "value",
                  "typeRef": {
                    "named": "number"
                  },
                  "typeName": "",
                  "modifier": "none",
                  "fnType": null,
                  "destruct": null,
                  "defaultVal": null
                }
              ],
              "body": [
                {
                  "expr": {
                    "jump": {
                      "loc": {
                        "line": 7,
                        "col": 9
                      },
                      "kind": {
                        "throw_": {
                          "call": {
                            "loc": {
                              "line": 7,
                              "col": 15
                            },
                            "kind": {
                              "call": {
                                "receiver": null,
                                "callee": "Error",
                                "is_builtin": false,
                                "is_tagged": false,
                                "optional": false,
                                "args": [
                                  {
                                    "label": "msg",
                                    "value": {
                                      "literal": {
                                        "loc": {
                                          "line": 7,
                                          "col": 26
                                        },
                                        "kind": {
                                          "stringLit": "Balance cannot be negative"
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
            "method": {
              "name": "deposit",
              "annotations": [],
              "genericParams": [],
              "params": [
                {
                  "name": "self",
                  "typeRef": {
                    "named": "Self"
                  },
                  "typeName": "",
                  "modifier": "none",
                  "fnType": null,
                  "destruct": null,
                  "defaultVal": null
                },
                {
                  "name": "amount",
                  "typeRef": {
                    "named": "number"
                  },
                  "typeName": "",
                  "modifier": "none",
                  "fnType": null,
                  "destruct": null,
                  "defaultVal": null
                }
              ],
              "returnType": null,
              "body": [
                {
                  "expr": {
                    "binding": {
                      "loc": {
                        "line": 10,
                        "col": 9
                      },
                      "kind": {
                        "assign": {
                          "target": {
                            "fieldAccess": {
                              "receiver": {
                                "identifier": {
                                  "loc": {
                                    "line": 10,
                                    "col": 9
                                  },
                                  "kind": {
                                    "ident": "self"
                                  }
                                }
                              },
                              "field": "_balance"
                            }
                          },
                          "op": "plusAssign",
                          "value": {
                            "identifier": {
                              "loc": {
                                "line": 10,
                                "col": 26
                              },
                              "kind": {
                                "ident": "amount"
                              }
                            }
                          }
                        }
                      }
                    }
                  },
                  "emptyLinesBefore": 0
                }
              ],
              "is_default": false,
              "is_declare": false,
              "isPub": false
            }
          }
        ],
        "trailingComma": false
      }
    }
  ]
}
```