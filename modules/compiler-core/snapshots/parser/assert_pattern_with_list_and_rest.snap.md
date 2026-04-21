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
              "comptime_": {
                "loc": {
                  "line": 2,
                  "col": 9
                },
                "kind": {
                  "assertPattern": {
                    "pattern": {
                      "list": {
                        "elems": [
                          {
                            "bind": "first"
                          },
                          {
                            "bind": "second"
                          }
                        ],
                        "spread": "rest"
                      }
                    },
                    "expr": {
                      "identifier": {
                        "loc": {
                          "line": 2,
                          "col": 42
                        },
                        "kind": {
                          "ident": "items"
                        }
                      }
                    },
                    "handler": {
                      "collection": {
                        "loc": {
                          "line": 2,
                          "col": 54
                        },
                        "kind": {
                          "arrayLit": {
                            "elems": [],
                            "spread": null,
                            "spreadExpr": null,
                            "comments": [],
                            "commentsPerElem": [],
                            "trailingComma": false
                          }
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