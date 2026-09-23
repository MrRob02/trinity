import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trinity/trinity.dart';

class TestNode extends NodeInterface {
  late final count = registerSignal(Signal<int>(0));
  late final name = registerSignal(Signal<String>('Trinity'));
  late final doubleCount = registerSignal(
    ComputedSignal<int, int>(source: count, transform: (v) => v * 2),
  );
  late final computedCombined = registerSignal(
    ComputedSignalMany<String>(
      source: {count, name},
      transform: () => '${name.value}: ${count.value}',
    ),
  );

  TestNode({super.key}) {
    // Eagerly access to register
    count;
    name;
    doubleCount;
    computedCombined;
  }
}

class ParentNode extends NodeInterface {
  late final score = registerSignal(Signal<int>(100));

  ParentNode({super.key}) {
    score;
  }
}

class ChildNode extends NodeInterface {
  late final parentScore = registerSignal(
    BridgeSignal<ParentNode, int>(select: (p) => p.score),
  );

  ChildNode({super.key}) {
    parentScore;
  }
}

void main() {
  group('Node signals & computedSignals registration', () {
    test(
      'Node properly registers signals and separates computed from non-computed',
      () {
        final node = TestNode();
        final doubleSignal = node.doubleCount;
        final combinedSignal = node.computedCombined;

        expect(node.signals.contains(node.count), isTrue);
        expect(node.signals.contains(node.name), isTrue);
        expect(node.signals.contains(doubleSignal), isFalse);
        expect(node.signals.contains(combinedSignal), isFalse);

        expect(node.computedSignals.contains(doubleSignal), isTrue);
        expect(node.computedSignals.contains(combinedSignal), isTrue);
        expect(
          node.computedSignals.cast<dynamic>().contains(node.count),
          isFalse,
        );

        expect(node.isSignalRegistered(node.count), isTrue);
        expect(node.isSignalRegistered(node.name), isTrue);
        expect(node.isSignalRegistered(doubleSignal), isTrue);
        expect(node.isSignalRegistered(combinedSignal), isTrue);
      },
    );

    test('Node dispose cleans up both regular and computed signals', () {
      final node = TestNode();
      final countSignal = node.count;
      final doubleSignal = node.doubleCount;

      expect(countSignal.isDisposed, isFalse);
      expect(doubleSignal.isDisposed, isFalse);

      node.dispose();

      expect(countSignal.isDisposed, isTrue);
      expect(doubleSignal.isDisposed, isTrue);
    });
  });

  group('SignalBuilder & ManySignalsBuilder widgets', () {
    testWidgets('SignalBuilder builds and updates with computed signal', (
      tester,
    ) async {
      final node = TestNode();

      await tester.pumpWidget(
        TrinityScope(
          child: NodeProvider<TestNode>(
            create: () => node,
            child: SignalBuilder<int>(
              signal: node.doubleCount,
              builder: (context, value) {
                return Text('Double: $value', textDirection: TextDirection.ltr);
              },
            ),
          ),
        ),
      );

      expect(find.text('Double: 0'), findsOneWidget);

      node.count.value = 5;
      await tester.pump();
      await tester.pump();
      expect(find.text('Double: 10'), findsOneWidget);
    });

    testWidgets('ManySignalsBuilder listens to multiple signals', (
      tester,
    ) async {
      final node = TestNode();
      int buildCount = 0;

      await tester.pumpWidget(
        TrinityScope(
          child: NodeProvider<TestNode>(
            create: () => node,
            child: ManySignalsBuilder(
              signals: {node.count, node.name},
              builder: (context) {
                buildCount++;
                return Text(
                  '${node.name.value}: ${node.count.value}',
                  textDirection: TextDirection.ltr,
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Trinity: 0'), findsOneWidget);
      expect(buildCount, 1);

      node.count.value = 7;
      await tester.pump();
      await tester.pump();
      expect(find.text('Trinity: 7'), findsOneWidget);
      expect(buildCount, 2);

      node.name.value = 'Updated';
      await tester.pump();
      await tester.pump();
      expect(find.text('Updated: 7'), findsOneWidget);
      expect(buildCount, 3);
    });

    testWidgets(
      'ManySignalsBuilder.all subscribes to all non-computed signals',
      (tester) async {
        final node = TestNode();

        await tester.pumpWidget(
          TrinityScope(
            child: NodeProvider<TestNode>(
              create: () => node,
              child: ManySignalsBuilder.all(
                node: node,
                builder: (context) {
                  return Text(
                    '${node.name.value}-${node.count.value}',
                    textDirection: TextDirection.ltr,
                  );
                },
              ),
            ),
          ),
        );

        expect(find.text('Trinity-0'), findsOneWidget);

        node.count.value = 42;
        await tester.pump();
        await tester.pump();
        expect(find.text('Trinity-42'), findsOneWidget);
      },
    );

    testWidgets('BridgeSignal connects and reflects parent node signal value', (
      tester,
    ) async {
      final parent = ParentNode();
      final child = ChildNode();

      await tester.pumpWidget(
        TrinityScope(
          child: NodeProvider<ParentNode>(
            create: () => parent,
            child: NodeProvider<ChildNode>(
              create: () => child,
              child: SignalBuilder<int>(
                signal: child.parentScore,
                builder: (context, value) {
                  return Text(
                    'Score: $value',
                    textDirection: TextDirection.ltr,
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Score: 100'), findsOneWidget);

      parent.score.value = 250;
      await tester.pump();
      await tester.pump();
      expect(find.text('Score: 250'), findsOneWidget);
    });

    testWidgets(
      'ManySignalsBuilder.readable asserts when signals set is empty',
      (tester) async {
        final node = TestNode();

        await tester.pumpWidget(
          TrinityScope(
            child: NodeProvider<TestNode>(
              create: () => node,
              child: ManySignalsBuilder.readable(
                signals: {},
                builder: (context, dynamic readable) {
                  return const Text('Empty');
                },
              ),
            ),
          ),
        );

        expect(tester.takeException(), isA<AssertionError>());
      },
    );

    testWidgets(
      'SignalBuilderMany (deprecated) builds and updates with readable',
      (tester) async {
        final node = TestNode();

        await tester.pumpWidget(
          TrinityScope(
            child: NodeProvider<TestNode>(
              create: () => node,
              child: SignalBuilderMany(
                signals: {node.count},
                builder: (context, dynamic readable) {
                  return Text(
                    'Count: ${node.count.value}',
                    textDirection: TextDirection.ltr,
                  );
                },
              ),
            ),
          ),
        );

        expect(find.text('Count: 0'), findsOneWidget);

        node.count.value = 5;
        await tester.pump();
        await tester.pump();
        expect(find.text('Count: 5'), findsOneWidget);
      },
    );
  });

  group('SignalListener & ManySignalsListener widgets', () {
    testWidgets('ManySignalsListener listens to multiple signals', (
      tester,
    ) async {
      final node = TestNode();
      int countUpdates = 0;
      int nameUpdates = 0;

      await tester.pumpWidget(
        TrinityScope(
          child: NodeProvider<TestNode>(
            create: () => node,
            child: ManySignalsListener(
              listeners: [
                SignalListenerItem.of<int>(
                  signal: node.count,
                  listener: (prev, next) => countUpdates++,
                ),
                SignalListenerItem.of<String>(
                  signal: node.name,
                  listener: (prev, next) => nameUpdates++,
                ),
              ],
              child: const Text(
                'Listener Test',
                textDirection: TextDirection.ltr,
              ),
            ),
          ),
        ),
      );

      expect(countUpdates, 0);
      expect(nameUpdates, 0);

      node.count.value = 1;
      await tester.pump();
      await tester.pump();
      expect(countUpdates, 1);

      node.name.value = 'Updated';
      await tester.pump();
      await tester.pump();
      expect(nameUpdates, 1);
    });

    testWidgets(
      'SignalListenerMany (deprecated) delegates to ManySignalsListener',
      (tester) async {
        final node = TestNode();
        int updates = 0;

        await tester.pumpWidget(
          TrinityScope(
            child: NodeProvider<TestNode>(
              create: () => node,
              child: SignalListenerMany(
                listeners: [
                  SignalListenerItem.of<int>(
                    signal: node.count,
                    listener: (prev, next) => updates++,
                  ),
                ],
                child: const Text(
                  'Deprecated Listener',
                  textDirection: TextDirection.ltr,
                ),
              ),
            ),
          ),
        );

        node.count.value = 99;
        await tester.pump();
        await tester.pump();
        expect(updates, 1);
      },
    );
  });
}
