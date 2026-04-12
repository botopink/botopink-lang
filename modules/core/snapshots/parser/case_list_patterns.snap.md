{
  "decls": [
    {
      "implement": {
        "name": "X",
        "genericParams": [],
        "interfaces": [
          "Foo"
        ],
        "target": "Bar",
        "methods": [
          {
            "qualifier": null,
            "name": "run",
            "params": [
              {
                "name": "self",
                "typeName": "Self",
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
                    "line": 3,
                    "col": 9
                  },
                  "kind": {
                    "case": {
                      "subject": {
                        "loc": {
                          "line": 3,
                          "col": 14
                        },
                        "kind": {
                          "ident": "xs"
                        }
                      },
                      "arms": [
                        {
                          "pattern": {
                            "list": {
                              "elems": [],
                              "spread": null
                            }
                          },
                          "body": {
                            "loc": {
                              "line": 4,
                              "col": 19
                            },
                            "kind": {
                              "stringLit": "empty"
                            }
                          }
                        },
                        {
                          "pattern": {
                            "list": {
                              "elems": [
                                {
                                  "numberLit": "1"
                                }
                              ],
                              "spread": null
                            }
                          },
                          "body": {
                            "loc": {
                              "line": 5,
                              "col": 20
                            },
                            "kind": {
                              "stringLit": "one"
                            }
                          }
                        },
                        {
                          "pattern": {
                            "list": {
                              "elems": [
                                {
                                  "wildcard": {}
                                },
                                {
                                  "wildcard": {}
                                }
                              ],
                              "spread": null
                            }
                          },
                          "body": {
                            "loc": {
                              "line": 6,
                              "col": 23
                            },
                            "kind": {
                              "stringLit": "two"
                            }
                          }
                        },
                        {
                          "pattern": {
                            "list": {
                              "elems": [
                                {
                                  "bind": "first"
                                }
                              ],
                              "spread": "rest"
                            }
                          },
                          "body": {
                            "loc": {
                              "line": 7,
                              "col": 32
                            },
                            "kind": {
                              "ident": "first"
                            }
                          }
                        }
                      ]
                    }
                  }
                }
              }
            ]
          }
        ]
      }
    }
  ]
}