```json
{
  "decls": [
    {
      "enum": {
        "name": "Level",
        "id": 1,
        "isPub": false,
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "implement": [],
        "variants": [
          {
            "name": "Info",
            "fields": [
              {
                "name": "message",
                "typeRef": {
                  "named": "string"
                },
                "default": {
                  "literal": {
                    "loc": {
                      "line": 2,
                      "col": 28
                    },
                    "kind": {
                      "stringLit": "info"
                    }
                  }
                }
              }
            ],
            "numeric": false
          },
          {
            "name": "Warn",
            "fields": [
              {
                "name": "message",
                "typeRef": {
                  "named": "string"
                },
                "default": {
                  "literal": {
                    "loc": {
                      "line": 3,
                      "col": 28
                    },
                    "kind": {
                      "stringLit": "warning"
                    }
                  }
                }
              }
            ],
            "numeric": false
          }
        ],
        "trailingComma": true,
        "methods": [],
        "sections": []
      }
    }
  ]
}
```