```json
{
  "decls": [
    {
      "fn": {
        "isPub": false,
        "name": "bind",
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
                  "localBindDestruct": {
                    "pattern": {
                      "tuple_": [
                        "a",
                        "b"
                      ]
                    },
                    "value": {
                      "collection": {
                        "loc": {
                          "line": 2,
                          "col": 19
                        },
                        "kind": {
                          "tupleLit": {
                            "elems": [
                              {
                                "literal": {
                                  "loc": {
                                    "line": 2,
                                    "col": 21
                                  },
                                  "kind": {
                                    "numberLit": "12"
                                  }
                                }
                              },
                              {
                                "literal": {
                                  "loc": {
                                    "line": 2,
                                    "col": 25
                                  },
                                  "kind": {
                                    "stringLit": "5452"
                                  }
                                }
                              }
                            ],
                            "comments": [],
                            "commentsPerElem": []
                          }
                        }
                      }
                    },
                    "mutable": false
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