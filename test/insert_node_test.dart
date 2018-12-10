import 'dart:convert';

import 'package:dslink_mongodb_controller/mongo_dslink.dart';
import 'package:dslink_mongodb_controller/nodes.dart';
import 'package:dslink_mongodb_controller/utils.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'mocks.dart';

void main() {
  Map<String, dynamic> validParams;

  final document = '{}';

  setUp(() {
    validParams = {InsertNodeParams.document: document};
  });

  group('Null parameters validation', () {
    final testCases = <Tuple>[
      const Tuple(
          InsertNodeParams.document, InsertNodeParams.invalidDocumentErrorMsg),
    ];

    for (var testCase in testCases) {
      test('throws when ${testCase.first} is null', () {
        expect(
            () => InsertNodeParams
                .validateParams(validParams..remove(testCase.first)),
            throwsA(testCase.second));
      });
    }
  });

  group('document must be valid JSON map', () {
    test('throws when invalid JSON', () {
      validParams[InsertNodeParams.document] = '{missing: quotes}';

      expect(() => InsertNodeParams.validateParams(validParams),
          throwsA(InsertNodeParams.invalidDocumentErrorMsg));
    });
  });

  group('onInvoke', () {
    final path = '/somePath';
    final collectionName = 'some name';
    MongoClient client;
    InsertNode node;

    setUp(() {
      client = new MongoClientMock();
      node = new InsertNode(path, client, collectionName);
    });

    test('delegates to MongoClient', () async {
      await node.onInvoke(validParams);

      verify(client.insert(collectionName, JSON.decode(document)));
    });
  });
}
