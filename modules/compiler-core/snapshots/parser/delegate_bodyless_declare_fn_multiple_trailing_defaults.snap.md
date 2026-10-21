```json
{
  "decls": [
    {
      "fn": {
        "isPub": true,
        "effect": null,
        "isDeclare": true,
        "isDefault": false,
        "label": null,
        "name": "open",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [
          {
            "name": "path",
            "typeRef": {
              "named": "string"
            },
            "typeName": "",
            "modifier": "none",
            "destruct": null,
            "default": null
          },
          {
            "name": "mode",
            "typeRef": {
              "named": "string"
            },
            "typeName": "",
            "modifier": "none",
            "destruct": null,
            "default": {
              "literal": {
                "loc": {
                  "line": 1,
                  "col": 50
                },
                "kind": {
                  "stringLit": "r"
                }
              }
            }
          },
          {
            "name": "buffer",
            "typeRef": {
              "named": "i32"
            },
            "typeName": "",
            "modifier": "none",
            "destruct": null,
            "default": {
              "literal": {
                "loc": {
                  "line": 1,
                  "col": 69
                },
                "kind": {
                  "numberLit": "4096"
                }
              }
            }
          }
        ],
        "returnType": {
          "named": "i32"
        },
        "typeGuardParam": null,
        "body": []
      }
    }
  ]
}
```