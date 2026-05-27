```json
{
  "decls": [
    {
      "implement": {
        "name": "CameraPowerCharger",
        "genericParams": [],
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "interfaces": [
          "UsbCharger",
          "SolarCharger"
        ],
        "target": "SmartCamera",
        "methods": [
          {
            "qualifier": "UsbCharger",
            "name": "Connect",
            "params": [
              {
                "name": "self",
                "typeRef": {
                  "named": "Self"
                },
                "typeName": "",
                "modifier": "none",
                "fnType": null,
                "destruct": null,
                "defaultVal": null
              }
            ],
            "body": [
              {
                "expr": {
                  "call": {
                    "loc": {
                      "line": 3,
                      "col": 9
                    },
                    "kind": {
                      "call": {
                        "receiver": null,
                        "callee": "print",
                        "is_builtin": true,
                        "args": [
                          {
                            "label": null,
                            "value": {
                              "binaryOp": {
                                "loc": {
                                  "line": 3,
                                  "col": 53
                                },
                                "kind": {
                                  "op": "add",
                                  "lhs": {
                                    "literal": {
                                      "loc": {
                                        "line": 3,
                                        "col": 16
                                      },
                                      "kind": {
                                        "stringLit": "Connected via USB. Battery level: "
                                      }
                                    }
                                  },
                                  "rhs": {
                                    "identifier": {
                                      "loc": {
                                        "line": 3,
                                        "col": 55
                                      },
                                      "kind": {
                                        "identAccess": {
                                          "receiver": {
                                            "identifier": {
                                              "loc": {
                                                "line": 3,
                                                "col": 55
                                              },
                                              "kind": {
                                                "ident": "self"
                                              }
                                            }
                                          },
                                          "member": "batteryLevel"
                                        }
                                      }
                                    }
                                  }
                                }
                              }
                            },
                            "comments": []
                          }
                        ],
                        "trailing": []
                      }
                    }
                  }
                },
                "emptyLinesBefore": 0
              }
            ]
          },
          {
            "qualifier": "SolarCharger",
            "name": "Connect",
            "params": [
              {
                "name": "self",
                "typeRef": {
                  "named": "Self"
                },
                "typeName": "",
                "modifier": "none",
                "fnType": null,
                "destruct": null,
                "defaultVal": null
              }
            ],
            "body": [
              {
                "expr": {
                  "call": {
                    "loc": {
                      "line": 6,
                      "col": 9
                    },
                    "kind": {
                      "call": {
                        "receiver": null,
                        "callee": "print",
                        "is_builtin": true,
                        "args": [
                          {
                            "label": null,
                            "value": {
                              "binaryOp": {
                                "loc": {
                                  "line": 6,
                                  "col": 61
                                },
                                "kind": {
                                  "op": "add",
                                  "lhs": {
                                    "literal": {
                                      "loc": {
                                        "line": 6,
                                        "col": 16
                                      },
                                      "kind": {
                                        "stringLit": "Connected via Solar Panel. Battery level: "
                                      }
                                    }
                                  },
                                  "rhs": {
                                    "identifier": {
                                      "loc": {
                                        "line": 6,
                                        "col": 63
                                      },
                                      "kind": {
                                        "identAccess": {
                                          "receiver": {
                                            "identifier": {
                                              "loc": {
                                                "line": 6,
                                                "col": 63
                                              },
                                              "kind": {
                                                "ident": "self"
                                              }
                                            }
                                          },
                                          "member": "batteryLevel"
                                        }
                                      }
                                    }
                                  }
                                }
                              }
                            },
                            "comments": []
                          }
                        ],
                        "trailing": []
                      }
                    }
                  }
                },
                "emptyLinesBefore": 0
              }
            ]
          }
        ]
      }
    }
  ]
}
```