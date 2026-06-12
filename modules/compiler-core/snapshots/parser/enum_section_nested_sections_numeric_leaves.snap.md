```json
{
  "decls": [
    {
      "enum": {
        "name": "Token",
        "id": 1,
        "isPub": false,
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "implement": [],
        "variants": [],
        "trailingComma": false,
        "methods": [],
        "sections": [
          {
            "name": "Color",
            "variants": [
              {
                "name": "Hex",
                "fields": [
                  {
                    "name": "value",
                    "typeRef": {
                      "named": "string"
                    },
                    "default": null
                  }
                ],
                "numeric": false
              }
            ],
            "sections": [
              {
                "name": "Red",
                "variants": [
                  {
                    "name": "100",
                    "fields": [],
                    "numeric": true
                  },
                  {
                    "name": "500",
                    "fields": [],
                    "numeric": true
                  },
                  {
                    "name": "700",
                    "fields": [],
                    "numeric": true
                  }
                ],
                "sections": []
              },
              {
                "name": "Blue",
                "variants": [
                  {
                    "name": "100",
                    "fields": [],
                    "numeric": true
                  },
                  {
                    "name": "500",
                    "fields": [],
                    "numeric": true
                  }
                ],
                "sections": []
              }
            ]
          },
          {
            "name": "Pad",
            "variants": [],
            "sections": [
              {
                "name": "X",
                "variants": [
                  {
                    "name": "1",
                    "fields": [],
                    "numeric": true
                  },
                  {
                    "name": "2",
                    "fields": [],
                    "numeric": true
                  },
                  {
                    "name": "4",
                    "fields": [],
                    "numeric": true
                  },
                  {
                    "name": "8",
                    "fields": [],
                    "numeric": true
                  }
                ],
                "sections": []
              },
              {
                "name": "Y",
                "variants": [
                  {
                    "name": "1",
                    "fields": [],
                    "numeric": true
                  },
                  {
                    "name": "2",
                    "fields": [],
                    "numeric": true
                  },
                  {
                    "name": "4",
                    "fields": [],
                    "numeric": true
                  }
                ],
                "sections": []
              }
            ]
          }
        ]
      }
    }
  ]
}
```