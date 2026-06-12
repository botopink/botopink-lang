```json
{
  "decls": [
    {
      "struct": {
        "name": "E",
        "id": 1,
        "isPub": false,
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "implement": [
          {
            "generic": {
              "name": "Context",
              "args": [
                {
                  "named": "E"
                },
                {
                  "named": "E"
                }
              ],
              "is_builtin": true
            }
          }
        ],
        "members": [
          {
            "field": {
              "name": "tag",
              "typeRef": {
                "named": "string"
              },
              "init": null,
              "annotations": []
            }
          },
          {
            "field": {
              "name": "children",
              "typeRef": {
                "array": {
                  "named": "E"
                }
              },
              "init": null,
              "annotations": []
            }
          }
        ],
        "trailingComma": false
      }
    }
  ]
}
```