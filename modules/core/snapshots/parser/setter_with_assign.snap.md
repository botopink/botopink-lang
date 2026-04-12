{
  "decls": [
    {
      "struct": {
        "name": "Account",
        "id": 1,
        "isPub": false,
        "annotations": [],
        "genericParams": [],
        "members": [
          {
            "setter": {
              "name": "balance",
              "params": [
                {
                  "name": "self",
                  "typeName": "Self",
                  "modifier": "none",
                  "typeinfoConstraints": null,
                  "fnType": null,
                  "destruct": null
                },
                {
                  "name": "value",
                  "typeName": "number",
                  "modifier": "none",
                  "typeinfoConstraints": null,
                  "fnType": null,
                  "destruct": null
                }
              ],
              "body": [
                {
                  "expr": {
                    "loc": {
                      "line": 3,
                      "col": 9
                    },
                    "kind": {
                      "fieldAssign": {
                        "receiver": {
                          "loc": {
                            "line": 3,
                            "col": 9
                          },
                          "kind": {
                            "ident": "self"
                          }
                        },
                        "field": "_balance",
                        "value": {
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
              ]
            }
          }
        ]
      }
    }
  ]
}