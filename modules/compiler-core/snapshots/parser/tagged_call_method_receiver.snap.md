```json
{
  "decls": [
    {
      "val": {
        "name": "q",
        "isPub": false,
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "typeAnnotation": null,
        "value": {
          "call": {
            "loc": {
              "line": 1,
              "col": 9
            },
            "kind": {
              "call": {
                "receiver": {
                  "identifier": {
                    "loc": {
                      "line": 1,
                      "col": 9
                    },
                    "kind": {
                      "ident": "db"
                    }
                  }
                },
                "callee": "sql",
                "is_builtin": false,
                "is_tagged": true,
                "optional": false,
                "args": [
                  {
                    "label": null,
                    "value": {
                      "literal": {
                        "loc": {
                          "line": 1,
                          "col": 16
                        },
                        "kind": {
                          "stringLit": "SELECT 1"
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
  ]
}
```