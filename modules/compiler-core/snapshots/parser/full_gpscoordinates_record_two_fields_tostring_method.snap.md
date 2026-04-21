```json
{
  "decls": [
    {
      "record": {
        "name": "GPSCoordinates",
        "id": 1,
        "isPub": false,
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "fields": [
          {
            "name": "lat",
            "typeRef": {
              "named": "number"
            },
            "default": null
          },
          {
            "name": "lon",
            "typeRef": {
              "named": "number"
            },
            "default": null
          }
        ],
        "trailingComma": false,
        "methods": [
          {
            "name": "toString",
            "genericParams": [],
            "params": [
              {
                "name": "self",
                "typeRef": {
                  "named": "Self"
                },
                "typeName": "",
                "modifier": "none",
                "typeinfoConstraints": null,
                "fnType": null,
                "destruct": null,
                "defaultVal": null
              }
            ],
            "returnType": {
              "named": "string"
            },
            "body": [
              {
                "expr": {
                  "controlFlow": {
                    "loc": {
                      "line": 5,
                      "col": 9
                    },
                    "kind": {
                      "return": {
                        "binaryOp": {
                          "loc": {
                            "line": 5,
                            "col": 46
                          },
                          "kind": {
                            "add": {
                              "lhs": {
                                "binaryOp": {
                                  "loc": {
                                    "line": 5,
                                    "col": 35
                                  },
                                  "kind": {
                                    "add": {
                                      "lhs": {
                                        "binaryOp": {
                                          "loc": {
                                            "line": 5,
                                            "col": 24
                                          },
                                          "kind": {
                                            "add": {
                                              "lhs": {
                                                "literal": {
                                                  "loc": {
                                                    "line": 5,
                                                    "col": 16
                                                  },
                                                  "kind": {
                                                    "stringLit": "Lat: "
                                                  }
                                                }
                                              },
                                              "rhs": {
                                                "identifier": {
                                                  "loc": {
                                                    "line": 5,
                                                    "col": 26
                                                  },
                                                  "kind": {
                                                    "identAccess": {
                                                      "receiver": {
                                                        "identifier": {
                                                          "loc": {
                                                            "line": 5,
                                                            "col": 26
                                                          },
                                                          "kind": {
                                                            "ident": "self"
                                                          }
                                                        }
                                                      },
                                                      "member": "lat"
                                                    }
                                                  }
                                                }
                                              }
                                            }
                                          }
                                        }
                                      },
                                      "rhs": {
                                        "literal": {
                                          "loc": {
                                            "line": 5,
                                            "col": 37
                                          },
                                          "kind": {
                                            "stringLit": " Lon: "
                                          }
                                        }
                                      }
                                    }
                                  }
                                }
                              },
                              "rhs": {
                                "identifier": {
                                  "loc": {
                                    "line": 5,
                                    "col": 48
                                  },
                                  "kind": {
                                    "identAccess": {
                                      "receiver": {
                                        "identifier": {
                                          "loc": {
                                            "line": 5,
                                            "col": 48
                                          },
                                          "kind": {
                                            "ident": "self"
                                          }
                                        }
                                      },
                                      "member": "lon"
                                    }
                                  }
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                },
                "emptyLinesBefore": 0
              }
            ],
            "is_default": false,
            "is_declare": false,
            "isPub": true
          }
        ]
      }
    }
  ]
}
```