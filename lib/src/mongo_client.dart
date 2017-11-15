import 'dart:async';
import 'dart:io';

import 'package:mongo_dart/mongo_dart.dart';
import 'package:pool/pool.dart';

class MongoClientFactory {
  MongoClient create(Uri uri, String username, String password) =>
      new MongoClient(uri, username, password);
}

typedef Db _DbFactory();

class ConnectionPool {
  List<Db> _connections = [];
  int _index = 0;
  Pool _pool;

  /// The maximum number of concurrent connections allowed.
  final int maxConnections;

  /// A [_DbFactory], a parameterless function that returns a [Db]. The function can be asynchronous if necessary.
  final _DbFactory dbFactory;

  /// Initializes a connection pool.
  ///
  /// * `maxConnections`: The maximum amount of connections to keep open simultaneously.
  /// * `dbFactory*: a parameterless function that returns a [Db]. The function can be asynchronous if necessary.
  ConnectionPool(this.maxConnections, this.dbFactory) {
    _pool = new Pool(maxConnections);
  }

  /// Connects to the database, using an existent connection, only creating a new one if
  /// the number of active connections is less than [maxConnections].
  Future<Db> connect() {
    return _pool.withResource/*<Db>*/(() async {
      int i = _index;
      if (_index >= maxConnections) _index = 0;

      if (i < _connections.length)
        return _connections[i];
      else {
        var db = await dbFactory();
        await db.open();
        _connections.add(db);
        return db;
      }
    });
  }

  /// Closes all active database connections.
  Future close() {
    return Future
        .wait(_connections.map/*<Future>*/((c) => c.close()))
        .then((_) => _pool.close());
  }
}

class MongoClient {
  final Uri uri;
  final String username;
  final String password;

  ConnectionPool connectionPool; // Not final due to 1.17.1 initialization

  static const int maxConnections = 3;

  MongoClient(this.uri, this.username, this.password) {
    connectionPool = new ConnectionPool(maxConnections,
        () => new Db(makeAuthenticatedUri(uri, username, password).toString()));
  }

  Future<AuthResult> testConnection() async {
    final uriWithAuth = makeAuthenticatedUri(uri, username, password);

    final db = new Db(uriWithAuth.toString());
    try {
      await db.open();
      await db.close();
      return AuthResult.ok;
    } on SocketException catch (_) {
      return AuthResult.notFound;
    } on MongoDartError catch (_) {
      rethrow;
    } catch (e) {
      if (e['code'] == 18) {
        return AuthResult.authError;
      } else {
        return AuthResult.other;
      }
    }
  }

  /// List collection names for a given database
  Future<List<String>> listCollections() async {
    final db = await connectionPool.connect();
    return db.getCollectionNames();
  }

  Future<List<Map<String, dynamic>>> find(String collectionName,
      Map<String, dynamic> selector, int limit, int skip) async {
    final db = await connectionPool.connect();
    final collection = db.collection(collectionName);

    final sb = new SelectorBuilder()
      ..raw(selector)
      ..limit(limit)
      ..skip(skip);

    final result = await collection.find(sb).toList();

    return result;
  }

  Stream<Map<String, dynamic>> findStreaming(String collectionName,
      Map<String, dynamic> selector, int limit, int skip) async* {
    final db = await connectionPool.connect();
    final collection = db.collection(collectionName);

    final sb = new SelectorBuilder()
      ..raw(selector)
      ..limit(limit)
      ..skip(skip);

    await for (var row in collection.find(sb)) {
      yield row;
    }
  }

  Future<int> count(
      String collectionName, Map<String, dynamic> selector) async {
    final db = await connectionPool.connect();
    final collection = db.collection(collectionName);

    final count = await collection.count(selector);

    return count;
  }
}

enum AuthResult { ok, authError, notFound, other }

Uri makeAuthenticatedUri(Uri source, String username, String password) =>
    source.replace(userInfo: '$username:$password');
