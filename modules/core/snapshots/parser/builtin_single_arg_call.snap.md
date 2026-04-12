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
                      "name": "@sizeOf",
                      "args": [
                        {
                          "label": null,
                          "value": {
                            "loc": {
                              "line": 3,
                              "col": 17
                            },
                            "kind": {
                              "ident": "Int"
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
                      "name": "@typeName",
                      "args": [
                        {
                          "label": null,
                          "value": {
                            "loc": {
                              "line": 4,
                              "col": 19
                            },
                            "kind": {
                              "ident": "Bool"
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
                      "name": "@panic",
                      "args": [
                        {
                          "label": null,
                          "value": {
                            "loc": {
                              "line": 5,
                              "col": 16
                            },
                            "kind": {
                              "stringLit": "unreachable"
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