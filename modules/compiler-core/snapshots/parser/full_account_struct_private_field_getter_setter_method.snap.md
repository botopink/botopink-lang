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
        "members": [
          {
            "field": {
              "name": "_balance",
              "typeName": "number",
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
              }
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
                "typeinfoConstraints": null,
                "fnType": null,
                "destruct": null,
                "defaultVal": null
              },
              "returnType": "number",
              "body": [
                {
                  "expr": {
                    "controlFlow": {
                      "loc": {
                        "line": 4,
                        "col": 9
                      },
                      "kind": {
                        "return": {
                          "identifier": {
                            "loc": {
                              "line": 4,
                              "col": 16
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
                                "member": "_balance"
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
                  "typeinfoConstraints": null,
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
                  "typeinfoConstraints": null,
                  "fnType": null,
                  "destruct": null,
                  "defaultVal": null
                }
              ],
              "body": [
                {
                  "expr": {
                    "binding": {
                      "loc": {
                        "line": 7,
                        "col": 9
                      },
                      "kind": {
                        "fieldAssign": {
                          "receiver": {
                            "identifier": {
                              "loc": {
                                "line": 7,
                                "col": 9
                              },
                              "kind": {
                                "ident": "self"
                              }
                            }
                          },
                          "field": "_balance",
                          "value": {
                            "identifier": {
                              "loc": {
                                "line": 7,
                                "col": 25
                              },
                              "kind": {
                                "ident": "value"
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
              "genericParams": [],
              "params": [
                {
                  "name": "self",
                  "typeRef": {
                    "named": "Self"
                  },
                  "typeName": "",
                  "modifier": "none",
                  "typeinfoConstraints": null,
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
                  "typeinfoConstraints": null,
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
                        "fieldPlusEq": {
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
                          "field": "_balance",
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