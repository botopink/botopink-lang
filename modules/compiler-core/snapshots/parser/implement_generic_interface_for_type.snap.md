```json
{
  "decls": [
    {
      "record": {
        "name": "E",
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
            "name": "tag",
            "typeRef": {
              "named": "string"
            },
            "default": null,
            "annotations": []
          }
        ],
        "trailingComma": false,
        "methods": []
      }
    },
    {
      "implement": {
        "name": "C",
        "isPub": false,
        "shorthand": false,
        "genericParams": [],
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "interfaces": [
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
        "target": "E",
        "methods": []
      }
    },
    {
      "implement": {
        "name": "D",
        "isPub": false,
        "shorthand": false,
        "genericParams": [],
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "interfaces": [
          {
            "generic": {
              "name": "Foo",
              "args": [
                {
                  "named": "E"
                },
                {
                  "named": "E"
                }
              ],
              "is_builtin": false
            }
          }
        ],
        "target": "E",
        "methods": []
      }
    }
  ]
}
```