import 'package:flutter_test/flutter_test.dart';

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

  group('Keyed Nodes & Lookup', () {
    testWidgets(
      'Multiple nodes of different types can share the same ValueKey without collision',
      (tester) async {
        const sharedKey = ValueKey('item_42');
        final userNode = UserTestNode(key: sharedKey);
        final orderNode = OrderTestNode(key: sharedKey);

        late BuildContext capturedContext;

        await tester.pumpWidget(
          TrinityScope(
            child: NodeProvider<UserTestNode>(
              create: () => userNode,
              child: NodeProvider<OrderTestNode>(
                create: () => orderNode,
                child: Builder(
                  builder: (context) {
                    capturedContext = context;
                    return const Text(
                      'Ready',
                      textDirection: TextDirection.ltr,
                    );
                  },
                ),
              ),
            ),
          ),
        );

        // context.findNode
        final foundUser = capturedContext.findNode<UserTestNode>(
          key: sharedKey,
        );
        final foundOrder = capturedContext.findNode<OrderTestNode>(
          key: sharedKey,
        );
        expect(foundUser, equals(userNode));
        expect(foundOrder, equals(orderNode));

        // NodeInterface.of
        expect(
          NodeInterface.of<UserTestNode>(capturedContext, key: sharedKey),
          equals(userNode),
        );
        expect(
          NodeInterface.of<OrderTestNode>(capturedContext, key: sharedKey),
          equals(orderNode),
        );

        // findNodeOrNull
        expect(
          capturedContext.findNodeOrNull<UserTestNode>(key: sharedKey),
          equals(userNode),
        );
        expect(
          capturedContext.findNodeOrNull<UserTestNode>(
            key: const ValueKey('other'),
          ),
          isNull,
        );
      },
    );

    testWidgets(
      'Node can find other keyed nodes using findNode and findNodeOrNull',
      (tester) async {
        const key1 = ValueKey('id_1');
        const key2 = ValueKey('id_2');

        final user1 = UserTestNode(key: key1)..name.value = 'User 1';
        final user2 = UserTestNode(key: key2)..name.value = 'User 2';
        final order1 = OrderTestNode(key: key1);
        final finder = FinderTestNode();

        await tester.pumpWidget(
          TrinityScope(
            child: NodeProvider<UserTestNode>.many(
              nodes: [() => user1, () => user2],
              child: NodeProvider<OrderTestNode>(
                create: () => order1,
                child: NodeProvider<FinderTestNode>(
                  create: () => finder,
                  child: const Text('Ready', textDirection: TextDirection.ltr),
                ),
              ),
            ),
          ),
        );

        // Inside finder node
        final foundUser1 = finder.findItemUser(key1);
        final foundUser2 = finder.findItemUser(key2);
        expect(foundUser1.name.value, 'User 1');
        expect(foundUser2.name.value, 'User 2');

        final foundOrder = finder.findItemOrderOrNull(key1);
        expect(foundOrder, equals(order1));

        final nonExistent = finder.findItemOrderOrNull(
          const ValueKey('non_existent'),
        );
        expect(nonExistent, isNull);
      },
    );

    testWidgets(
      'BridgeSignal and TransformBridgeSignal resolve parent node by key',
      (tester) async {
        const targetKey = ValueKey('special_user');
        final targetUser = UserTestNode(key: targetKey)..name.value = 'Target';
        final defaultUser = UserTestNode()..name.value = 'Default';
        final targetOrder = OrderTestNode(key: targetKey);

        final interactor = BridgeInteractorTestNode();

        await tester.pumpWidget(
          TrinityScope(
            child: NodeProvider<UserTestNode>.many(
              nodes: [() => defaultUser, () => targetUser],
              child: NodeProvider<OrderTestNode>(
                create: () => targetOrder,
                child: NodeProvider<BridgeInteractorTestNode>(
                  create: () => interactor,
                  child: SignalBuilder<String>(
                    signal: interactor.bridgedName,
                    builder: (context, name) {
                      return Text(
                        'Name: $name',
                        textDirection: TextDirection.ltr,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Name: Target'), findsOneWidget);

        targetUser.name.value = 'Updated Target';
        await tester.pump();
        await tester.pump();
        expect(find.text('Name: Updated Target'), findsOneWidget);

        // Check transform bridge
        expect(interactor.bridgedOrderId.value, 'Transformed-ORD-123');
      },
    );

    testWidgets('Subtype lookup works with key for interfaces', (tester) async {
      const cardKey = ValueKey('card_1');
      final cardPayment = CreditCardPaymentNode(key: cardKey);

      late BuildContext capturedContext;

      await tester.pumpWidget(
        TrinityScope(
          child: NodeProvider<CreditCardPaymentNode>(
            create: () => cardPayment,
            child: Builder(
              builder: (context) {
                capturedContext = context;
                return const Text('Ready', textDirection: TextDirection.ltr);
              },
            ),
          ),
        ),
      );

      final foundInterface = capturedContext.findNode<PaymentTestInterface>(
        key: cardKey,
      );
      expect(foundInterface, equals(cardPayment));
      expect(foundInterface.amount.value, 50.0);
    });
  });
}

class UserTestNode extends NodeInterface {
  late final name = registerSignal(Signal<String>('Alice'));
  UserTestNode({super.key}) {
    name;
  }
}

class OrderTestNode extends NodeInterface {
  late final orderId = registerSignal(Signal<String>('ORD-123'));
  OrderTestNode({super.key}) {
    orderId;
  }
}

abstract class PaymentTestInterface extends NodeInterface {
  PaymentTestInterface({super.key});
  Signal<double> get amount;
}

class CreditCardPaymentNode extends PaymentTestInterface {
  @override
  late final amount = registerSignal(Signal<double>(50.0));
  CreditCardPaymentNode({super.key}) {
    amount;
  }
}

class FinderTestNode extends NodeInterface {
  FinderTestNode({super.key});

  UserTestNode findItemUser(Key key) => findNode<UserTestNode>(key: key);
  OrderTestNode? findItemOrderOrNull(Key key) =>
      findNodeOrNull<OrderTestNode>(key: key);
}

class BridgeInteractorTestNode extends NodeInterface {
  late final bridgedName = registerSignal(
    BridgeSignal<UserTestNode, String>(
      key: const ValueKey('special_user'),
      select: (u) => u.name,
    ),
  );

  late final bridgedOrderId = registerSignal(
    TransformBridgeSignal<OrderTestNode, String, String>(
      key: const ValueKey('special_user'),
      select: (o) => o.orderId,
      transform: (id) => 'Transformed-$id',
    ),
  );

  BridgeInteractorTestNode({super.key}) {
    bridgedName;
    bridgedOrderId;
  }
}
