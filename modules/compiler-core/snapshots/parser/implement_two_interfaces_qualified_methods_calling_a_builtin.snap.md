```json
{
  "decls": [
    {
      "implement": {
        "name": "CameraPowerCharger",
        "isPub": false,
        "shorthand": false,
        "genericParams": [],
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "interfaces": [
          {
            "named": "UsbCharger"
          },
          {
            "named": "SolarCharger"
          }
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
                "destruct": null,
                "default": null
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
                        "is_builtin": false,
                        "is_tagged": false,
                        "optional": false,
                        "args": [
                          {
                            "label": null,
                            "value": {
                              "binaryOp": {
                                "loc": {
                                  "line": 3,
                                  "col": 52
                                },
                                "op": "add",
                                "lhs": {
                                  "literal": {
                                    "loc": {
                                      "line": 3,
                                      "col": 15
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
                                      "col": 59
                                    },
                                    "kind": {
                                      "identAccess": {
                                        "receiver": {
                                          "identifier": {
                                            "loc": {
                                              "line": 3,
                                              "col": 54
                                            },
                                            "kind": {
                                              "ident": "self"
                                            }
                                          }
                                        },
                                        "member": "batteryLevel",
                                        "optional": false
                                      }
                                    }
                                  }
                                }
                              }
                            },
                            "comments": [],
                            "is_default_inj": false
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
                "destruct": null,
                "default": null
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
                        "is_builtin": false,
                        "is_tagged": false,
                        "optional": false,
                        "args": [
                          {
                            "label": null,
                            "value": {
                              "binaryOp": {
                                "loc": {
                                  "line": 6,
                                  "col": 60
                                },
                                "op": "add",
                                "lhs": {
                                  "literal": {
                                    "loc": {
                                      "line": 6,
                                      "col": 15
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
                                      "col": 67
                                    },
                                    "kind": {
                                      "identAccess": {
                                        "receiver": {
                                          "identifier": {
                                            "loc": {
                                              "line": 6,
                                              "col": 62
                                            },
                                            "kind": {
                                              "ident": "self"
                                            }
                                          }
                                        },
                                        "member": "batteryLevel",
                                        "optional": false
                                      }
                                    }
                                  }
                                }
                              }
                            },
                            "comments": [],
                            "is_default_inj": false
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
    },
    {
      "use": {
        "imports": [
          {
            "segments": [
              "io",
              "terminal",
              "print"
            ],
            "activate": false,
            "alias": null
          }
        ],
        "source": {
          "module": "std"
        },
        "package": null,
        "activationOnly": false,
        "docComment": null,
        "comment": null,
        "moduleComment": null
      }
    }
  ]
}
```