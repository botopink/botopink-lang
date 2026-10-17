```json
{
  "decls": [
    {
      "type_": {
        "name": "Option",
        "id": 1,
        "isPub": true,
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [
          {
            "name": "T",
            "default": null
          }
        ],
        "implement": [],
        "shape": {
          "enum_": {
            "variants": [
              {
                "name": "None",
                "fields": [],
                "numeric": false
              },
              {
                "name": "Some",
                "fields": [
                  {
                    "name": "value",
                    "typeRef": {
                      "named": "T"
                    },
                    "default": null,
                    "annotations": []
                  }
                ],
                "numeric": false
              }
            ],
            "sections": []
          }
        },
        "trailingComma": true,
        "methods": []
      }
    }
  ]
}
```