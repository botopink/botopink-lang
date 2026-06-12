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
                    "mutable": true,
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
                  "assign": {
                    "target": {
                      "name": "name"
                    },
                    "op": "assign",
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