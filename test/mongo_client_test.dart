import 'dart:io';

import 'package:dslink_mongodb_controller/mongo_dslink.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  final uriString = Platform.environment['DB_URI'];
  final username = Platform.environment['DB_USERNAME'];
  final writerUser = Platform.environment['DB_USERNAME_WRITER'];
  final password = Platform.environment['DB_PASSWORD'];

  final simpleDataCount = 9;

  assert(uriString != null);
  assert(username != null);
  assert(password != null);

  final uri = Uri.parse(uriString);

  void validateAllSimpleData(List<Map<String, dynamic>> result) {
    expect(result, hasLength(simpleDataCount));
    expect(result[0]['name'], 'joel');
    expect(result[1]['name'], 'matt');
    expect(result[2]['name'], 'martine');
    // more data
  }

  group('test connection', () {
    test('returns OK when success', () async {
      final client = new MongoClient(uri, username, password);

      final result = await client.testConnection();

      expect(result, AuthResult.ok);
    });

    test('returns authError when wrong username', () async {
      final client = new MongoClient(uri, 'wrong username', password);

      final result = await client.testConnection();

      expect(result, AuthResult.authError);
    });

    test('returns authError when wrong password', () async {
      final client = new MongoClient(uri, username, 'wrong password');

      final result = await client.testConnection();

      expect(result, AuthResult.authError);
    });

    test('returns notFound when wrong server', () async {
      final newUri = uri.replace(host: 'wrongserver');
      final client = new MongoClient(newUri, username, password);

      final result = await client.testConnection();

      expect(result, AuthResult.notFound);
    });
  });

  group('find', () {
    final client = new MongoClient(uri, username, password);
    final limit = 0, skip = 0, fields = [];

    group('simple data', () {
      final collectionName = 'simple_data';
      final batchSize = 20;

      test('empty map returns all data', () async {
        final selector = {};
        final result = await client.find(
            collectionName, selector, fields, limit, skip, batchSize);

        validateAllSimpleData(result);
      });

      test('regex is supported', () async {
        final selector = {
          "name": {"\$regex": "mat.*", "\$options": "i"}
        };
        final result = await client.find(
            collectionName, selector, fields, limit, skip, batchSize);

        expect(result, hasLength(1));
        expect(result[0]['name'], 'matt');
      });

      test('field projection is supported', () async {
        final selector = {'name': 'joel'};
        final fields = ['dob'];
        final result = await client.find(
            collectionName, selector, fields, limit, skip, batchSize);

        expect(result, hasLength(1));
        expect(result[0].containsKey('name'), isFalse);
        expect(result[0]['dob'], 1990);
      });

      test("limit is respected", () async {
        final limit = 2;
        final selector = {};

        var result = await client.find(
            collectionName, selector, fields, limit, skip, batchSize);

        expect(result, hasLength(limit));
      });

      test("skip is respected", () async {
        final skip = 2;
        final selector = {};

        var result = await client.find(
            collectionName, selector, fields, limit, skip, batchSize);

        expect(result[0]['name'], 'martine');
      });

      test("orderby is supported", () async {
        final selector = {
          r'$query': {},
          r'$orderby': {'name': 1}
        };

        var result = await client.find(
            collectionName, selector, fields, limit, skip, batchSize);

        var expected = copyAndSortResultsBy(result, 'name');
        expect(result, containsAllInOrder(expected));
      });
    });
  });

  group('findStream', () {
    final client = new MongoClient(uri, username, password);
    final limit = 0, skip = 0, batchSize = 20, fields = [];
    final selector = {};

    group('simple data', () {
      final collectionName = 'simple_data';

      test('empty map returns all data', () async {
        final result = await client
            .findStreaming(
                collectionName, selector, fields, limit, skip, batchSize)
            .toList();

        validateAllSimpleData(result);
      });

      test("limit is respected", () async {
        final limit = 2;

        var result = await client
            .findStreaming(
                collectionName, selector, fields, limit, skip, batchSize)
            .toList();

        expect(result, hasLength(limit));
      });

      test("skip is respected", () async {
        final skip = 2;

        var result = await client
            .findStreaming(
                collectionName, selector, fields, limit, skip, batchSize)
            .toList();

        expect(result[0]['name'], 'martine');
      });

      test('field projection is supported', () async {
        final selector = {'name': 'joel'};
        final fields = ['dob'];
        final result = await client
            .findStreaming(
                collectionName, selector, fields, limit, skip, batchSize)
            .toList();

        expect(result, hasLength(1));
        expect(result[0].containsKey('name'), isFalse);
        expect(result[0]['dob'], 1990);
      });
    });
  });

  group('count', () {
    final client = new MongoClient(uri, username, password);
    final collectionName = 'simple_data';

    test('count with empty selector returns count all', () async {
      final result = await client.count(collectionName, {});

      expect(result, simpleDataCount);
    });

    test('count respects regex selector', () async {
      final result = await client.count(collectionName, {
        "name": {"\$regex": "ma.*", "\$options": "i"}
      });

      expect(result, 2);
    });
  });

  group('aggregate', () {
    final client = new MongoClient(uri, username, password);

    test('throws an error when mongo returns an error', () async {
      final collectionName = 'any';

      // Should throw because _id isn't provided
      await expectThrowsAsync(
          () => client.aggregate(collectionName, [
                {
                  r'$group': {
                    'avgDob': {r'$avg': r'$dob'}
                  }
                }
              ]),
          (String s) =>
              s.contains('a group specification must include an _id'));
    });

    test('average', () async {
      final collectionName = 'simple_data';

      final result = await client.aggregate(collectionName, [
        {
          r'$group': {
            '_id': 'dob',
            'avgDob': {r'$avg': r'$dob'}
          }
        }
      ]);

      expect((result.first['avgDob'] as num).round(), 1988);
    });

    test('average with filtering', () async {
      final collectionName = 'simple_data';

      final result = await client.aggregate(collectionName, [
        {
          r'$match': {
            'dob': {'\$lt': 1990}
          }
        },
        {
          r'$group': {
            '_id': null,
            'count': {'\$sum': 1}
          }
        }
      ]);

      expect((result.first['count'] as num).round(), 5);
    });
  });
  group('aggregate to stream', () {
    final client = new MongoClient(uri, username, password);

    // TODO: See why this doesn't throw. It just returns an empty list.
    // Result: It doesn't throw because mongo_dart
    // doesn't handle errors properly here
    test('throws an error when mongo returns an error', () async {
      final collectionName = 'any';

      // Should throw because _id isn't provided
      await expectThrowsAsync(
          () => client.aggregateToStream(collectionName, [
                {
                  r'$group': {
                    'avgDob': {r'$avg': r'$dob'}
                  }
                }
              ]).toList(),
          (String s) =>
              s.contains('a group specification must include an _id'));
    }, skip: true);

    test('average', () async {
      final collectionName = 'simple_data';

      final result = await client.aggregateToStream(collectionName, [
        {
          r'$group': {
            '_id': 'dob',
            'avgDob': {r'$avg': r'$dob'}
          }
        }
      ]).toList();

      expect((result.first['avgDob'] as num).round(), 1988);
    });

    test('average with filtering', () async {
      final collectionName = 'simple_data';

      final result = await client.aggregateToStream(collectionName, [
        {
          r'$match': {
            'dob': {'\$lt': 1990}
          }
        },
        {
          r'$group': {
            '_id': null,
            'count': {'\$sum': 1}
          }
        }
      ]).toList();

      expect((result.first['count'] as num).round(), 5);
    });
  });

  group('insert', () {
    final client = new MongoClient(uri, writerUser, password);
    String collectionName;

    setUp(() {
      collectionName = generateRandomCollectionName();
    });

    tearDown(() async {
      await client.dropCollection(collectionName);
    });

    test('successful insert', () async {
      final doc = {'id': 'Hello!'};

      await client.insert(collectionName, doc);

      var count = await client.count(collectionName, {});
      expect(count, 1);
    });

    group('read only user', () {
      final client = new MongoClient(uri, username, password);
      test('throws when read only collection', () async {
        final doc = {};
        await expectThrowsAsync(
            () => client.insert(collectionName, doc), "Permission denied.");
      });
    });
  });
}

List<Map<String, dynamic>> copyAndSortResultsBy(
    List<Map<String, dynamic>> result, dynamic valueToSortBy) {
  final expected = new List.from(result)
    ..sort((Map<String, dynamic> first, Map<String, dynamic> second) =>
        first[valueToSortBy].compareTo(second[valueToSortBy]));
  return expected;
}
