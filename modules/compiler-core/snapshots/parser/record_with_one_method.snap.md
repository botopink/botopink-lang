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
        "implement": [],
        "fields": [
          {
            "name": "x",
            "typeRef": {
              "named": "number"
            },
            "default": null,
            "annotations": []
          }
        ],
        "trailingComma": false,
        "methods": [
          {
            "name": "show",
            "annotations": [],
            "genericParams": [],
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
              }
            ],
            "returnType": null,
            "body": [
              {
                "expr": {
                  "jump": {
                    "loc": {
                      "line": 4,
                      "col": 9
                    },
                    "kind": {
                      "return": {
                        "identifier": {
                          "loc": {
                            "line": 4,
                            "col": 21
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
                              "member": "x",
                              "optional": false
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