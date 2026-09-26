```json
{
  "decls": [
    {
      "behavior": {
        "name": "Decl",
        "id": 1,
        "isPub": true,
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "extends": [],
        "fields": [
          {
            "name": "name",
            "typeRef": {
              "named": "string"
            }
          },
          {
            "name": "fields",
            "typeRef": {
              "array": {
                "named": "Field"
              }
            }
          },
          {
            "name": "methods",
            "typeRef": {
              "generic": {
                "name": "Array",
                "args": [
                  {
                    "named": "Method"
                  }
                ],
                "is_builtin": false
              }
            }
          },
          {
            "name": "parent",
            "typeRef": {
              "optional": {
                "named": "Decl"
              }
            }
          }
        ],
        "trailingComma": false,
        "methods": []
      }
    }
  ]
}
```