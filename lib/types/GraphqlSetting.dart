// Copyright (c) 2018, the Black Salt authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:json_object_lite/json_object_lite.dart';
import 'package:logging/logging.dart';

import '../fetch.dart';

GraphqlBuildSetting createSetting(
    {String schemaUrl,
    String method: "post",
    bool postIntrospectionQuery: true,
    String schemaFile}) {
  return new GraphqlBuildSetting(
      schemaUrl, method, postIntrospectionQuery, schemaFile);
}

class GraphqlBuildSetting {
  final Logger log = new Logger('GraphqlSetting');

  String schemaUrl;
  String method;
  bool postIntrospectionQuery;

  String schemaFile;

  GraphqlBuildSetting(this.schemaUrl, this.method, this.postIntrospectionQuery,
      this.schemaFile);

  dynamic _schemaObject;

  Future getSchema() async {
    if (_schemaObject == null) {
      if (schemaFile != null) {
        log.info("reading schema from file:$schemaFile");
        var fileContent = await new File(schemaFile).readAsString();
        _schemaObject = new JsonObjectLite.fromJsonString(fileContent);
      } else if (schemaUrl != null) {
        var client = new RestClient(this.schemaUrl);
        log.info("fetching schema from url:${this.schemaUrl}");
        JsonResponse result;
        if (method == "post") {
          Map<String, dynamic> query = {};
          if (postIntrospectionQuery) {
            query = {"query": IntrospectionQuery};
          }
          result = await client.postJson("", query);
        } else {
          result = await client.getJson("", <String, dynamic>{});
        }
        _schemaObject = result
            .decode((d) => new JsonObjectLite.fromJsonString(d))
            .data
            .__schema;
      }
    }
    return _schemaObject;
  }

  static const String IntrospectionQuery = """
     query IntrospectionQuery {
    __schema {
      queryType { name }
      mutationType { name }
      subscriptionType { name }
      types {
        ...FullType
      }
      directives {
        name
        description
        locations
        args {
          ...InputValue
        }
      }
    }
  }

  fragment FullType on __Type {
    kind
    name
    description
    fields(includeDeprecated: true) {
      name
      description
      args {
        ...InputValue
      }
      type {
        ...TypeRef
      }
      isDeprecated
      deprecationReason
    }
    inputFields {
      ...InputValue
    }
    interfaces {
      ...TypeRef
    }
    enumValues(includeDeprecated: true) {
      name
      description
      isDeprecated
      deprecationReason
    }
    possibleTypes {
      ...TypeRef
    }
  }

  fragment InputValue on __InputValue {
    name
    description
    type { ...TypeRef }
    defaultValue
  }

  fragment TypeRef on __Type {
    kind
    name
    ofType {
      kind
      name
      ofType {
        kind
        name
        ofType {
          kind
          name
          ofType {
            kind
            name
            ofType {
              kind
              name
              ofType {
                kind
                name
                ofType {
                  kind
                  name
                }
              }
            }
          }
        }
      }
    }
  }
  """;
}