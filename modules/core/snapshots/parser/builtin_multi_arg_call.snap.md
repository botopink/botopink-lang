{
  "decls": [
    {
      "interface": {
        "name": "Test",
        "id": 1,
        "isPub": false,
        "annotations": [],
        "genericParams": [],
        "extends": [],
        "fields": [],
        "methods": [
          {
            "name": "run",
            "genericParams": [],
            "params": [],
            "returnType": null,
            "body": [
              {
                "expr": {
                  "loc": {
                    "line": 3,
                    "col": 9
                  },
                  "kind": {
                    "builtinCall": {
                      "name": "@min",
                      "args": [
                        {
                          "label": null,
                          "value": {
                            "loc": {
                              "line": 3,
                              "col": 14
                            },
                            "kind": {
                              "ident": "a"
                            }
                          }
                        },
                        {
                          "label": null,
                          "value": {
                            "loc": {
                              "line": 3,
                              "col": 17
                            },
                            "kind": {
                              "ident": "b"
                            }
                          }
                        }
                      ]
                    }
                  }
                }
              },
              {
                "expr": {
                  "loc": {
                    "line": 4,
                    "col": 9
                  },
                  "kind": {
                    "builtinCall": {
                      "name": "@max",
                      "args": [
                        {
                          "label": null,
                          "value": {
                            "loc": {
                              "line": 4,
                              "col": 14
                            },
                            "kind": {
                              "ident": "x"
                            }
                          }
                        },
                        {
                          "label": null,
                          "value": {
                            "loc": {
                              "line": 4,
                              "col": 17
                            },
                            "kind": {
                              "ident": "y"
                            }
                          }
                        }
                      ]
                    }
                  }
                }
              },
              {
                "expr": {
                  "loc": {
                    "line": 5,
                    "col": 9
                  },
                  "kind": {
                    "builtinCall": {
                      "name": "@as",
                      "args": [
                        {
                          "label": null,
                          "value": {
                            "loc": {
                              "line": 5,
                              "col": 13
                            },
                            "kind": {
                              "ident": "Int"
                            }
                          }
                        },
                        {
                          "label": null,
                          "value": {
                            "loc": {
                              "line": 5,
                              "col": 18
                            },
                            "kind": {
                              "ident": "value"
                            }
                          }
                        }
                      ]
                    }
                  }
                }
              }
            ],
            "is_default": true,
            "is_declare": false,
            "isPub": false
          }
        ]
      }
    }
  ]
}