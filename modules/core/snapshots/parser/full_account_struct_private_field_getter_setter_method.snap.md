{
  "decls": [
    {
      "struct": {
        "name": "Account",
        "id": 1,
        "isPub": false,
        "annotations": [],
        "genericParams": [],
        "members": [
          {
            "field": {
              "name": "_balance",
              "typeName": "number",
              "init": {
                "loc": {
                  "line": 2,
                  "col": 24
                },
                "kind": {
                  "numberLit": "0"
                }
              }
            }
          },
          {
            "getter": {
              "name": "balance",
              "selfParam": {
                "name": "self",
                "typeName": "Self",
                "modifier": "none",
                "typeinfoConstraints": null,
                "fnType": null,
                "destruct": null
              },
              "returnType": "number",
              "body": [
                {
                  "expr": {
                    "loc": {
                      "line": 4,
                      "col": 9
                    },
                    "kind": {
                      "return": {
                        "loc": {
                          "line": 4,
                          "col": 16
                        },
                        "kind": {
                          "identAccess": {
                            "receiver": {
                              "loc": {
                                "line": 4,
                                "col": 16
                              },
                              "kind": {
                                "ident": "self"
                              }
                            },
                            "member": "_balance"
                          }
                        }
                      }
                    }
                  }
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
                  "typeName": "Self",
                  "modifier": "none",
                  "typeinfoConstraints": null,
                  "fnType": null,
                  "destruct": null
                },
                {
                  "name": "value",
                  "typeName": "number",
                  "modifier": "none",
                  "typeinfoConstraints": null,
                  "fnType": null,
                  "destruct": null
                }
              ],
              "body": [
                {
                  "expr": {
                    "loc": {
                      "line": 7,
                      "col": 9
                    },
                    "kind": {
                      "fieldAssign": {
                        "receiver": {
                          "loc": {
                            "line": 7,
                            "col": 9
                          },
                          "kind": {
                            "ident": "self"
                          }
                        },
                        "field": "_balance",
                        "value": {
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
                  "typeName": "Self",
                  "modifier": "none",
                  "typeinfoConstraints": null,
                  "fnType": null,
                  "destruct": null
                },
                {
                  "name": "amount",
                  "typeName": "number",
                  "modifier": "none",
                  "typeinfoConstraints": null,
                  "fnType": null,
                  "destruct": null
                }
              ],
              "returnType": null,
              "body": [
                {
                  "expr": {
                    "loc": {
                      "line": 10,
                      "col": 9
                    },
                    "kind": {
                      "fieldPlusEq": {
                        "receiver": {
                          "loc": {
                            "line": 10,
                            "col": 9
                          },
                          "kind": {
                            "ident": "self"
                          }
                        },
                        "field": "_balance",
                        "value": {
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
              ],
              "is_default": false,
              "is_declare": false,
              "isPub": false
            }
          }
        ]
      }
    }
  ]
}