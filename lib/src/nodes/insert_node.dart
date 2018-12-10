import 'dart:async';
import 'dart:convert';

import 'package:dslink/dslink.dart';
import 'package:dslink_mongodb_controller/mongo_dslink.dart';
import 'package:dslink_mongodb_controller/utils.dart';

class InsertNodeParams {
  static const String document = 'document';

  static const String invalidDocumentErrorMsg =
      'Cannot parse document properly. It should be a valid JSON map.';

  static void validateParams(Map<String, String> params) {
    if (params[document] is! String || isNullOrEmpty(params[document])) {
      throw invalidDocumentErrorMsg;
    }

    try {
      final decodedDocument = JSON.decode(params[document]);
      if (decodedDocument is! Map) {
        throw new FormatException('Document is not a Map.');
      }
    } on FormatException catch (_) {
      throw invalidDocumentErrorMsg;
    }
  }
}

class InsertNode extends SimpleNode {
  static const String pathName = 'insert';
  static const String isType = 'insertNode';
  static const String _result = 'result';

  final MongoClient client;
  final String collectionName;

  InsertNode(String path, this.client, this.collectionName) : super(path) {
    load(definition());
  }

  @override
  bool get serializable => false;

  @override
  Future<Map<String, String>> onInvoke(Map<String, dynamic> params) async {
    InsertNodeParams.validateParams(params);

    final document = JSON.decode(params[InsertNodeParams.document]);

    await client.insert(collectionName, document);

    return {'result': 'Insert was successful'};
  }

  static Map<String, dynamic> definition() => {
        r"$name": "Find",
        r"$is": isType,
        r"$invokable": "write",
        r"$params": [
          {
            "name": InsertNodeParams.document,
            "type": "string",
            "editor": 'textarea',
            "description": "Document (JSON Map)",
            "default": "{}"
          },
        ],
        r'$columns': [
          {"name": _result, "type": "string"}
        ],
      };
}
