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
                  "typeinfoConstraints": null,
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
                  "typeinfoConstraints": null,
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
                        "fieldAssign": {
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
                          "field": "_balance",
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