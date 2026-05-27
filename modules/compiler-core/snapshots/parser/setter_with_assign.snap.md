```json
{
  "decls": [
    {
      "struct": {
        "name": "Account",
        "id": 1,
        "isPub": false,
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "implement": [],
        "members": [
          {
            "setter": {
              "name": "balance",
              "params": [
                {
                  "name": "self",
                  "typeRef": {
                    "named": "Self"
                  },
                  "typeName": "",
                  "modifier": "none",
                  "fnType": null,
                  "destruct": null,
                  "defaultVal": null
                },
                {
                  "name": "value",
                  "typeRef": {
                    "named": "number"
                  },
                  "typeName": "",
                  "modifier": "none",
                  "fnType": null,
                  "destruct": null,
                  "defaultVal": null
                }
              ],
              "body": [
                {
                  "expr": {
                    "binding": {
                      "loc": {
                        "line": 3,
                        "col": 9
                      },
                      "kind": {
                        "assign": {
                          "target": {
                            "fieldAccess": {
                              "receiver": {
                                "identifier": {
                                  "loc": {
                                    "line": 3,
                                    "col": 9
                                  },
                                  "kind": {
                                    "ident": "self"
                                  }
                                }
                              },
                              "field": "_balance"
                            }
                          },
                          "op": "assign",
                          "value": {
                            "identifier": {
                              "loc": {
                                "line": 3,
                                "col": 25
                              },
                              "kind": {
                                "ident": "value"
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
        ],
        "trailingComma": false
      }
    }
  ]
}
```