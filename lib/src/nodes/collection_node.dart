import 'package:dslink/dslink.dart';
import 'package:dslink/nodes.dart';
import 'package:dslink_mongodb_controller/mongo_dslink.dart';
import 'package:dslink_mongodb_controller/nodes.dart';

class CollectionNode extends SimpleNode {
  static const String isType = 'collectionNode';

  final MongoClient client;
  final String collectionName;

  @override
  bool get serializable => false;

  CollectionNode(String path, this.client, this.collectionName) : super(path) {
    load(definition(collectionName));
  }

  /// For testing purpose only
  CollectionNode.withCustomProvider(String path, this.client,
      this.collectionName, SimpleNodeProvider provider)
      : super(path, provider) {
    load(definition(collectionName));
  }

  static Map<String, dynamic> definition(String collectionName) => {
        r'$is': isType,
        r'$name': NodeNamer.createName(collectionName),
        r'$collectionName': collectionName,
      };

  @override
  void onCreated() {
    final findNode =
        new FindNode('$path/${FindNode.pathName}', client, collectionName);
    provider.setNode(findNode.path, findNode);

    final findStreamNode = new FindStreamNode(
        '$path/${FindStreamNode.pathName}', client, collectionName);
    provider.setNode(findStreamNode.path, findStreamNode);

    final countNode =
        new CountNode('$path/${CountNode.pathName}', client, collectionName);
    provider.setNode(countNode.path, countNode);

    final aggregateNode = new AggregateNode(
        '$path/${AggregateNode.pathName}', client, collectionName);
    provider.setNode(aggregateNode.path, aggregateNode);

    final insertNode =
        new InsertNode('$path/${InsertNode.pathName}', client, collectionName);
    provider.setNode(insertNode.path, insertNode);
  }
}
