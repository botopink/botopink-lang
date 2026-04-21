```json
{
  "decls": [
    {
      "fn": {
        "isPub": false,
        "name": "f",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [],
        "returnType": null,
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
                    "name": "name",
                    "value": {
                      "literal": {
                        "loc": {
                          "line": 2,
                          "col": 16
                        },
                        "kind": {
                          "stringLit": "old"
                        }
                      }
                    },
                    "mutable": true
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
                  "assign": {
                    "name": "name",
                    "value": {
                      "literal": {
                        "loc": {
                          "line": 3,
                          "col": 12
                        },
                        "kind": {
                          "stringLit": "new"
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