```json
{
  "decls": [
    {
      "val": {
        "name": "s",
        "isPub": false,
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "typeAnnotation": null,
        "value": {
          "literal": {
            "loc": {
              "line": 1,
              "col": 9
            },
            "kind": {
              "stringTemplate": {
                "multiline": false,
                "parts": [
                  {
                    "text": "sum "
                  },
                  {
                    "expr": {
                      "binaryOp": {
                        "loc": {
                          "line": 1,
                          "col": 18
                        },
                        "op": "add",
                        "lhs": {
                          "literal": {
                            "loc": {
                              "line": 1,
                              "col": 16
                            },
                            "kind": {
                              "numberLit": "1"
                            }
                          }
                        },
                        "rhs": {
                          "literal": {
                            "loc": {
                              "line": 1,
                              "col": 20
                            },
                            "kind": {
                              "numberLit": "2"
                            }
                          }
                        }
                      }
                    }
                  },
                  {
                    "text": "!"
                  }
                ]
              }
            }
          }
        }
      }
    }
  ]
}
```