{
  "decls": [
    {
      "record": {
        "name": "GPSCoordinates",
        "id": 1,
        "isPub": false,
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
        "methods": [
          {
            "name": "toString",
            "genericParams": [],
            "params": [
              {
                "name": "self",
                "typeName": "Self",
                "modifier": "none",
                "typeinfoConstraints": null,
                "fnType": null,
                "destruct": null
              }
            ],
            "returnType": {
              "named": "string"
            },
            "body": [
              {
                "expr": {
                  "loc": {
                    "line": 5,
                    "col": 9
                  },
                  "kind": {
                    "return": {
                      "loc": {
                        "line": 5,
                        "col": 46
                      },
                      "kind": {
                        "add": {
                          "lhs": {
                            "loc": {
                              "line": 5,
                              "col": 35
                            },
                            "kind": {
                              "add": {
                                "lhs": {
                                  "loc": {
                                    "line": 5,
                                    "col": 24
                                  },
                                  "kind": {
                                    "add": {
                                      "lhs": {
                                        "loc": {
                                          "line": 5,
                                          "col": 16
                                        },
                                        "kind": {
                                          "stringLit": "Lat: "
                                        }
                                      },
                                      "rhs": {
                                        "loc": {
                                          "line": 5,
                                          "col": 26
                                        },
                                        "kind": {
                                          "identAccess": {
                                            "receiver": {
                                              "loc": {
                                                "line": 5,
                                                "col": 26
                                              },
                                              "kind": {
                                                "ident": "self"
                                              }
                                            },
                                            "member": "lat"
                                          }
                                        }
                                      }
                                    }
                                  }
                                },
                                "rhs": {
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
                          },
                          "rhs": {
                            "loc": {
                              "line": 5,
                              "col": 48
                            },
                            "kind": {
                              "identAccess": {
                                "receiver": {
                                  "loc": {
                                    "line": 5,
                                    "col": 48
                                  },
                                  "kind": {
                                    "ident": "self"
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