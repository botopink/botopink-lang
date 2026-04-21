```json
{
  "decls": [
    {
      "fn": {
        "isPub": false,
        "name": "greet",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [
          {
            "name": "person",
            "typeRef": {
              "named": "Person"
            },
            "typeName": "",
            "modifier": "none",
            "typeinfoConstraints": null,
            "fnType": null,
            "destruct": null,
            "defaultVal": null
          }
        ],
        "returnType": {
          "named": "string"
        },
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
                      "names": {
                        "fields": [
                          {
                            "field_name": "name",
                            "bind_name": "name"
                          },
                          {
                            "field_name": "age",
                            "bind_name": "age"
                          }
                        ],
                        "hasSpread": false
                      }
                    },
                    "value": {
                      "identifier": {
                        "loc": {
                          "line": 2,
                          "col": 25
                        },
                        "kind": {
                          "ident": "person"
                        }
                      }
                    },
                    "mutable": false
                  }
                }
              }
            },
            "emptyLinesBefore": 0
          },
          {
            "expr": {
              "controlFlow": {
                "loc": {
                  "line": 3,
                  "col": 5
                },
                "kind": {
                  "return": {
                    "identifier": {
                      "loc": {
                        "line": 3,
                        "col": 12
                      },
                      "kind": {
                        "ident": "name"
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