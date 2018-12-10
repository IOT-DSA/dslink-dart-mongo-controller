import 'package:dslink/dslink.dart';
import 'package:dslink_mongodb_controller/mongo_dslink.dart';
import 'package:dslink_mongodb_controller/nodes.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'mocks.dart';

void main() {
  CollectionNode node;
  MongoClient mongoClient;
  SimpleNodeProvider provider;

  final path = '/somePath';
  final collectionName = 'some name';

  setUp(() {
    mongoClient = new MongoClientMock();
    provider = new ProviderMock();
    node = new CollectionNode.withCustomProvider(
        path, mongoClient, collectionName, provider);
  });

  group('adding actions onCreated', () {
    test('find node', () {
      node.onCreated();

      verify(provider.setNode('$path/${FindNode.pathName}',
          argThat(const isInstanceOf<FindNode>())));
    });

    test('find stream node', () {
      node.onCreated();

      verify(provider.setNode('$path/${FindStreamNode.pathName}',
          argThat(const isInstanceOf<FindStreamNode>())));
    });

    test('count node', () {
      node.onCreated();

      verify(provider.setNode('$path/${CountNode.pathName}',
          argThat(const isInstanceOf<CountNode>())));
    });

    test('aggregate node', () {
      node.onCreated();

      verify(provider.setNode('$path/${AggregateNode.pathName}',
          argThat(const isInstanceOf<AggregateNode>())));
    });

    test('insert node', () {
      node.onCreated();

      verify(provider.setNode('$path/${InsertNode.pathName}',
          argThat(const isInstanceOf<InsertNode>())));
    });
  });
}
