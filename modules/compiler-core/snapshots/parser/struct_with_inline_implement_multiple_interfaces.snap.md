```json
{
  "decls": [
    {
      "struct": {
        "name": "Widget",
        "id": 1,
        "isPub": false,
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "implement": [
          {
            "named": "Drawable"
          },
          {
            "generic": {
              "name": "Context",
              "args": [
                {
                  "named": "Element"
                },
                {
                  "named": "Widget"
                }
              ],
              "is_builtin": true
            }
          }
        ],
        "members": [],
        "trailingComma": false
      }
    }
  ]
}
```