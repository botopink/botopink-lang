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
        "name": "greet",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [
          {
            "name": "",
            "typeRef": {
              "named": "Person"
            },
            "typeName": "Person",
            "modifier": "none",
            "fnType": null,
            "destruct": {
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
            "defaultVal": null
          }
        ],
        "returnType": {
          "named": "string"
        },
        "body": [
          {
            "expr": {
              "jump": {
                "loc": {
                  "line": 2,
                  "col": 5
                },
                "kind": {
                  "return": {
                    "identifier": {
                      "loc": {
                        "line": 2,
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