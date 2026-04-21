```json
{
  "decls": [
    {
      "record": {
        "name": "Point",
        "id": 1,
        "isPub": false,
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "fields": [
          {
            "name": "x",
            "typeRef": {
              "named": "number"
            },
            "default": null
          }
        ],
        "trailingComma": false,
        "methods": [
          {
            "name": "show",
            "genericParams": [],
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
              }
            ],
            "returnType": null,
            "body": [
              {
                "expr": {
                  "controlFlow": {
                    "loc": {
                      "line": 4,
                      "col": 9
                    },
                    "kind": {
                      "return": {
                        "identifier": {
                          "loc": {
                            "line": 4,
                            "col": 16
                          },
                          "kind": {
                            "identAccess": {
                              "receiver": {
                                "identifier": {
                                  "loc": {
                                    "line": 4,
                                    "col": 16
                                  },
                                  "kind": {
                                    "ident": "self"
                                  }
                                }
                              },
                              "member": "x"
                            }
                          }
                        }
                      }
                    }
                  }
                },
                "emptyLinesBefore": 0
              }
            ],
            "is_default": false,
            "is_declare": false,
            "isPub": false
          }
        ]
      }
    }
  ]
}
```