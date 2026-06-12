```json
{
  "decls": [
    {
      "record": {
        "name": "Config",
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
            "name": "host",
            "typeRef": {
              "named": "string"
            },
            "default": {
              "literal": {
                "loc": {
                  "line": 1,
                  "col": 38
                },
                "kind": {
                  "stringLit": "localhost"
                }
              }
            },
            "annotations": []
          },
          {
            "name": "port",
            "typeRef": {
              "named": "i32"
            },
            "default": {
              "literal": {
                "loc": {
                  "line": 1,
                  "col": 63
                },
                "kind": {
                  "numberLit": "8080"
                }
              }
            },
            "annotations": []
          }
        ],
        "trailingComma": false,
        "methods": []
      }
    }
  ]
}
```