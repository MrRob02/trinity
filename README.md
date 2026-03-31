# Trinity

**Signals + Nodes = Simple State Management**
```dart
// 1. Define state
class CounterNode extends NodeInterface {
  late final count = registerSignal(Signal(0));

  void increment() => count.value++;
}

// 2. Build UI
final node = context.findNode<CounterNode>();
SignalBuilder(
  signal: node.count,
  builder: (context, value) => Text('$value'),
)
```

**That's it.** No streams, no boilerplate.

Trinity is a robust state management package for Flutter that implements a node-based architecture using reactive signals. It provides a structured way to separate business logic from UI code, ensuring modularity, testability, and efficient implementation of reactive patterns.

## Features

- **Node-Based Architecture**: Encapsulate logic and state within `Node` classes, promoting clean separation of concerns.
- **Reactive Signals**: Use `Signal` and `ReadableSignal` for granular and efficient UI updates without boilerplate.
- **Dependency Injection**: Built-in scoping mechanism (`TrinityScope`) and dependency provision (`NodeProvider`) simplify node lifecycle management.
- **Async State Handling**: Integrated `AsyncValue` support for easy management of loading, error, and data states in asynchronous operations.
- **Widget Integration**: Specialized `SignalBuilder` widget for strictly typed, reactive UI construction.
- **Context Extensions**: Easy access to nodes from the widget tree using `context.findNode<N>()`.

## Quick Start

1. Add to pubspec:
```yaml
dependencies:
  trinity: ^0.2.0
```

2. Wrap your app:
```dart
import 'package:trinity/trinity.dart';

void main() {
  runApp(TrinityScope(child: const MyApp()));
}
```

3. Create your first node (see Usage below).

# Why Trinity?

Trinity was born from the necessity to simplify code while ensuring robustness. Drawing inspiration from the most popular state management solutions—Bloc, GetX, and Riverpod—Trinity aims to unify their strengths while mitigating their weaknesses.

### The Landscape

| Feature | BLoC | Riverpod | GetX | Trinity |
|---------|------|----------|------|---------|
| Global scope | ✅ | ✅ | ✅ | ✅ |
| Auto dispose | ✅ | ⚠️ | ❌ | ✅ |
| No magic | ✅ | ✅ | ❌ | ✅ |
| Cross-node signals | ❌ | ⚠️ | ✅ | ✅ (BridgeSignal) |
| Learning curve | High | Medium | Low | Low |

- **Bloc**: Celebrated for its robustness and adherence to good practices via the widget tree lifecycle. However, it suffers from excessive boilerplate (requiring repetitive variable definitions for constructors, `Equatable`, getters, and `copyWith`) and lacks native inter-bloc communication.
- **Riverpod**: A strong middle ground with excellent dependency injection. However, its lifecycle management can be confusing (e.g., balancing caching with auto-dispose), and the architectural separation of data from controllers can complicate flow control.
- **GetX**: Loved for its flexibility and minimal file count. However, its heavy reliance on runtime checks makes it error-prone, and managing controllers outside the widget tree often leads to unmaintainable code and bad practices.

### The Trinity Solution

Trinity offers a balanced approach:

- **Zero Boilerplate**: Forget about managing massive state objects or implementing `Equatable`. In Trinity, each property manages its own state independently. Controllers simply update specific values, and only the relevant components rebuild.
- **Flutter-Native Robustness**: Utilizing `TrinityScope`, you can access any active node from anywhere in your app—whether navigating screens or opening dialogs. Nodes remain available while needed and are automatically cleaned up from memory (including its signals) when their master page is closed.
- **Modular Controllers**: Say goodbye to "God Controllers." `TrinityScope` removes barriers between nodes, enabling secure cross-communication. You can use **Bridges** to derive local state from a parent node or access parent data directly without duplication (e.g., accessing `orders.length` from `OrdersNode` inside `OrderDetailPage`).
- **Signals at the Core**: Signals act as state translators. Whether you have a mutable value, a stream, or a future, Trinity wraps it into a reactive Signal that manages the underlying complexity. No more manual stream creation—just wrap your data in a Signal and let Trinity handle the rest.
- **Componentization First**: Trinity prioritizes efficient UI updates. The `SignalBuilder` listens exclusively to the specific Signal it requires. If the `orders` signal updates, your list rebuilds, but unrelated changes (like `isLoading`) won't trigger unnecessary repaints.

## Usage

### 1. Define a Node

Create a custom node by extending `NodeInterface`. Define your state using `Signal`s and expose them via `ReadableSignal`s to maintain encapsulation.

```dart
import 'package:trinity/trinity.dart';

class CounterNode extends NodeInterface {
  // Mutable signal
  late final count = registerSignal(Signal<int>(0));

  void increment() {
    count.value++;
  }
}
```

We use `registerSignal` so the node could handle the signal's dispose automatically, so you don't have to call `count.dispose()` when closing the node.

### 2. Provide the Node

Inject the node into the widget tree using `NodeProvider`. This ensures the node is initialized and disposed of correctly.

```dart
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: NodeProvider(
          create: () => CounterNode(),
          child: const HomePage(),
        ),
      ),
    );
  }
}
```

> **Note**: simpler usage `NodeProvider(create: () => MyNode(), child: ...)`
> - Use `NodeProvider.builder` to provide a node and a builder at once.
> - Use `NodeProvider.many` to provide multiple nodes at once.
> - Use `NodeProvider.reuse` to reuse a node if it already exists in the scope.

### 3. Consume the Node

Use `SignalBuilder` to listen to signal changes and rebuild your UI. The builder automatically finds the required node from the context.

```dart
import 'package:trinity/widgets/signal_builder.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // You can also access the node directly for callbacks
    final node = context.findNode<CounterNode>();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('You have pushed the button this many times:'),
          SignalBuilder(
            signal: node.count,
            builder: (context, value) {
              return Text(
                '$value',
                style: Theme.of(context).textTheme.headlineMedium,
              );
            },
          ),
          ElevatedButton(
            onPressed: node.increment,
            child: const Text('Increment'),
          ),
        ],
      ),
    );
  }
}
```

You can use `SignalListener` or `SignalListenerMany` to listen to signal changes and perform side effects.

```dart
SignalListener(
  signal: node.count,
  listener: (previous, current) {
    print('Count changed from $previous to $current');
  },
);
```

## Advanced: Multiple Signals with Code Generation

For large nodes with many signals, you can use `SignalBuilderMany` with generated readonly wrappers.

> **IMPORTANT**: This feature requires code generation using `build_runner`.
> 
> 1. Add `build_runner` and `trinity_generator` to `dev_dependencies`.
> 2. Add `part 'your_file.readable.dart';` to your node file.
> 3. Run `dart run build_runner build`.
> 4. Mixin the generated class: `class OrdersNode extends NodeInterface<ReadableOrdersNode>`.
> 5. Add `@override ReadableOrdersNode get readable => ReadableOrdersNode(this);` to your node.

```dart
// orders_node.dart
import 'package:trinity/trinity.dart';
import 'package:trinity_generator/trinity_generator.dart';
part 'orders_node.readable.dart';

@Readable()
class OrdersNode extends NodeInterface<ReadableOrdersNode> {
  late final orders = registerSignal(Signal<List<OrderModel>>([]));
  late final user = registerSignal(Signal<User>(User.empty()));

  @override
  ReadableOrdersNode get readable => ReadableOrdersNode(this);
}
```

```dart
// home_page.dart
final node = context.findNode<OrdersNode>();
SignalBuilderMany<ReadableOrdersNode>(
  signals: {node.orders, node.user},
  builder: (context, reader) {
    // reader is the generated class that exposes values directly
    // This is type-safe and updates only when specific signals change
    final (orders, user) = (reader.orders, reader.user);
    
    return Text('User: ${user.name}, Orders: ${orders.length}');
  },
);
```

## Async Operations & Loading States

`NodeInterface` includes built-in helpers for managing asynchronous operations. The `loading()` method automatically updates `isLoading`, `fullScreenLoading`, and `error` signals.

```dart
class DataNode extends NodeInterface {
  Future<void> fetchData() async {
    // Automatically sets isLoading to true, awaits the future,
    // handles errors, and resets isLoading to false.
    await loading(() async {
      await someAsyncService.getData();
    });
  }
}
```

You also have a dedicated `findNode` function with the `Node` class to find other nodes in the tree.

```dart
class DataNode extends NodeInterface {
  late final otherNode = findNode<OtherNode>();
  Future<void> fetchData() async {
    // Automatically sets isLoading to true, awaits the future,
    // handles errors, and resets isLoading to false.
    await loading(() async {
      await someAsyncService.getData();
    });
  }
}
```

Listening to loading states in the UI:

```dart
SignalBuilder(
  signal: node.isLoading,
  builder: (context, isLoading) {
    if (isLoading) {
      return const CircularProgressIndicator();
    }
    return const ContentWidget();
  },
);
```

### FutureSignal

For specific asynchronous data requirements, use `FutureSignal`. It automatically manages the state lifecycle (`AsyncLoading`, `AsyncData`, `AsyncError`).

```dart
class DataNode extends NodeInterface {
  late final userSignal = registerSignal(FutureSignal(() => _fetchUser()));

  Future<User> _fetchUser() async {
    // Fetch user logic
  }
  
  void refresh() => userSignal.fetch();
}
```

In the UI:

```dart
SignalBuilder(
  signal: node.userSignal,
  builder: (context, state) {
    return state.when(
      builder: (data) => Text(data.value?.name ?? 'No data'),
      loading: () => const CircularProgressIndicator(),
      error: (error) => Text('Error: $error'),
    );
  },
);
```

### StreamSignal

`StreamSignal` allows you to easily bridge `Stream`s from your repositories or services into Trinity's reactive system.

```dart
class DataNode extends NodeInterface {
  late final messages = registerSignal(StreamSignal(repository.messagesStream()));
}
```

In the UI:

```dart
SignalBuilder(
  signal: node.messages,
  builder: (context, messages) {
    return messages==null
      ? const CircularProgressIndicator()
      : ListView.builder(
          itemCount: messages.length,
          itemBuilder: (context, index) {
            return Text(messages[index].text);
          },
      );
  },
);
```

### ComputedSignal

`ComputedSignal` allows you to create a signal whose value is derived from another signal on the same node.

```dart
class DataNode extends NodeInterface {
  late final messages = registerSignal(
    StreamSignal(repository.messagesStream()),
  );
  late final unreadMessages = registerSignal(
    ComputedSignal(
      source: messages,
      transform: (messages) =>
          messages.where((message) => !message.isRead).length,
    ),
  );
}
```

In the UI:

```dart
SignalBuilder(
  signal: node.unreadMessages,
  builder: (context, unreadMessages) {
    return Text(unreadMessages.toString());
  },
);
```

You can see it as a getter that handles its own state on the UI.

## Additional information

- **Node Lifecycle**: Nodes have `onInit`, `onReady`, and `onDispose` methods that you can override to hook into their lifecycle.

## Problem: Stale Data Between Screens

You tap an order in a list → navigate to detail → edit the price. 
Now you go back. **The list still shows the old price.**

**Solutions people try:**
- Pass the object → It's a copy, changes don't sync back ❌
- Refetch the list → Wasteful, slow, flickers ❌
- Use a God Controller → Couples everything together ❌

**Trinity's solution: Bridges**

The detail screen *connects* to the list's data source. Changes sync automatically, both ways.

### How it works

The `DetailNode` connects to `OrdersNode`. It "selects" the list of orders, "transforms" it to find the specific order it cares about, and "updates" the parent when changes occur.

1. **Decentralized**: The `DetailNode` manages its own connection to the data source.
2. **Synchronization**: Bridge automatically handles setting the `value`, so you don't need to worry about update it in the parent manually.
3. **Reactive**: `Bridge` updates the data directly on the parent and `DetailNode` automatically receives the new version of its specific order.

### Example

**1. The Parent Node (List)**

`OrdersNode` holds the source of truth for the list.

```dart
class OrdersNode extends NodeInterface {
  late final orders = registerSignal(Signal<List<OrderModel>>([]));

  // Method to update a single order in the list
  void updateOrder(OrderModel updatedOrder) {
    final newOrders = orders.value.map((o) {
      return o.id == updatedOrder.id ? updatedOrder : o;
    }).toList();
    orders.value = newOrders;
  }
}
```

**2. The Child Node (Detail)**

`DetailNode` bridges to `OrdersNode` to stay in sync.

```dart
class DetailNode extends NodeInterface {
  final int orderId;

  // 1. Define the Bridge
  // <TargetNode, SourceType, LocalType>
  late final orderBridge = registerSignal(
    TransformBridgeSignal(
      // Select the signal from the parent
      select: (OrdersNode node) => node.orders,

      // Transform: Find the specific order by ID
      transform: (List<OrderModel> orders) {
        return orders.firstWhereOrNull((o) => o.id == orderId);
      },

      // Update: synchronize changes back to the parent
      update: (OrdersNode node, OrderModel? value) {
        if (value != null) {
          node.updateOrder(value);
        }
      },
    ),
  );

  DetailNode(this.orderId);

  // Helper to update the order from the UI
  void changePrice(double newPrice) {
    final currentOrder = orderBridge.readableSignal.value;
    if (currentOrder != null) {
      // This triggers the 'update' callback defined above
      orderBridge.value = currentOrder.copyWith(price: newPrice);
    }
  }
}
```

The ```update``` property is optional, if you don't want your bridges to update the parent node, you can remove it. An ```Exception``` will be thrown if you try to update a signal with ```mySignal.value = newValue``` that doesn't have an ```update``` function.

You can also use `BridgeSignal` if you don't need to transform the data. ```update``` is allowed by default.

```dart
late final ordersBridge = registerSignal(
  BridgeSignal(
    select: (OrdersNode node) => node.orders,
  ),
);
```

With this setup:
- If `OrdersNode` updates the list (e.g., from a websocket), `DetailNode` updates automatically.
- If `DetailNode` changes the price, `OrdersNode` receives the update and the list (and any other listeners) update automatically.
