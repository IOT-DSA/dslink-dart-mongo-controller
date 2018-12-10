import 'dart:math';

import 'package:test/test.dart';

expectThrowsAsync(func, dynamic expected) async {
  try {
    await func();
    fail("Should throw.");
  } catch (e) {
    if (e is TestFailure) {
      rethrow;
    }
    expect(e, expected);
  }
}

Matcher containsAllInOrder(Iterable expected) =>
    new _ContainsAllInOrder(expected);

class _ContainsAllInOrder implements Matcher {
  final Iterable _expected;

  _ContainsAllInOrder(this._expected);

  String _test(item, Map matchState) {
    if (item is! Iterable) return 'not an iterable';
    var matchers = _expected.map(wrapMatcher).toList();
    var matcherIndex = 0;
    for (var value in item) {
      if (matchers[matcherIndex].matches(value, matchState)) matcherIndex++;
      if (matcherIndex == matchers.length) return null;
    }
    return new StringDescription()
        .add('did not find a value matching ')
        .addDescriptionOf(matchers[matcherIndex])
        .add(' following expected prior values')
        .toString();
  }

  @override
  bool matches(item, Map matchState) => _test(item, matchState) == null;

  @override
  Description describe(Description description) => description
      .add('contains in order(')
      .addDescriptionOf(_expected)
      .add(')');

  @override
  Description describeMismatch(item, Description mismatchDescription,
          Map matchState, bool verbose) =>
      mismatchDescription.add(_test(item, matchState));
}

String generateRandomCollectionName() {
  var rng = new Random();
  return new List.generate(10, (_) => rng.nextInt(9)).join();
}
