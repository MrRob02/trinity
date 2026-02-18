<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.
-->

# Trinity

Trinity is a robust state management package for Flutter that implements a node-based architecture using reactive signals. It provides a structured way to separate business logic from UI code, ensuring modularity, testability, and efficient implementation of reactive patterns.

# Documentation

## Features

- **Node-Based Architecture**: Encapsulate logic and state within `Node` classes, promoting clean separation of concerns.
- **Reactive Signals**: Use `Signal` and `ReadableSignal` for granular and efficient UI updates without boilerplate.
- **Dependency Injection**: Built-in scoping mechanism (`TrinityScope`) and dependency provision (`NodeProvider`) simplify node lifecycle management.
- **Async State Handling**: Integrated `AsyncValue` support for easy management of loading, error, and data states in asynchronous operations.
- **Widget Integration**: Specialized `SignalBuilder` widget for strictly typed, reactive UI construction.
- **Context Extensions**: Easy access to nodes from the widget tree using `context.findNode<N>()`.

## Getting started

Wrap your application or a specific subtree with `TrinityScopeWidget` to initialize the scope required for node management.

```dart
import 'package:flutter/material.dart';
import 'package:trinity/trinity.dart';

void main() {
  runApp(TrinityScopeWidget(child: const MainApp()));
}
```

## Usage

### 1. Define a Node

Create a custom node by extending `NodeInterface`. Define your state using `Signal`s and expose them via `ReadableSignal`s to maintain encapsulation.

```dart
import 'package:trinity/trinity.dart';

class CounterNode extends NodeInterface {
  // Private mutable signal
  final _count = Signal<int>(0);

  // Public read-only signal
  ReadableSignal<int> get count => _count.readable;

  void increment() {
    _count.value++;
  }
}
```

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
          SignalBuilder<CounterNode, int>(
            signal: (node) => node.count,
            builder: (context, count) {
              return Text(
                '$count',
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

Listening to loading states in the UI:

```dart
SignalBuilder(
  signal: (DataNode node) => node.isLoading,
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
  late final userSignal = FutureSignal(() => _fetchUser());

  Future<User> _fetchUser() async {
    // Fetch user logic
  }
  
  void refresh() => userSignal.fetch();
}
```

In the UI:

```dart
SignalBuilder<DataNode, AsyncValue<User>>(
  signal: (node) => node.userSignal,
  builder: (context, state) {
    return switch (state) {
      AsyncLoading() => const CircularProgressIndicator(),
      AsyncError(:final error) => Text('Error: $error'),
      AsyncData(:final value) => Text(value?.name ?? 'No data'),
    };
  },
);
```

## Additional information

- **Node Lifecycle**: Nodes have `onInit`, `onReady`, and `onDispose` methods that you can override to hook into their lifecycle.
## Inter-Node Communication with Bridges

One of Trinity's most powerful features is the **Bridge System**. It allows nodes to communicate without a "Parent Controller" or "God Object".

A common pattern is a **Master-Detail** relationship:
- `OrdersNode` holds a list of all orders.
- `DetailNode` manages the state of a *single* order.

Instead of passing the order object to the detail screen (which becomes stale if the list updates), or making the detail node fetch the entire list again, you use a **Bridge**.

### How it works

The `DetailNode` connects to `OrdersNode`. It "selects" the list of orders, "transforms" it to find the specific order it cares about, and "updates" the parent when changes occur.

1. **Decentralized**: The `DetailNode` manages its own connection to the data source.
2. **Reactive**: If `OrdersNode` updates the list, `DetailNode` automatically receives the new version of its specific order.
3. **Synchronization**: If `DetailNode` modifies the order, it can push changes back to `OrdersNode` via the `update` callback.

### Example

**1. The Parent Node (List)**

`OrdersNode` holds the source of truth for the list.

```dart
class OrdersNode extends NodeInterface {
  late final _orders = registerSignal(Signal<List<OrderModel>>([]));
  ReadableSignal<List<OrderModel>> get orders => _orders.readable;

  // Method to update a single order in the list
  void updateOrder(OrderModel updatedOrder) {
    final newOrders = _orders.value.map((o) {
      return o.id == updatedOrder.id ? updatedOrder : o;
    }).toList();
    _orders.value = newOrders;
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
  late final _orderBridge = registerSignal(
    BridgeSignal(
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
  // And just like that, you have a ReadableSignal that works
  //exactly like a normal signal, but it's connected to the parent node
  ReadableSignal<OrderModel?> get order => _orderBridge.readableSignal;

  DetailNode(this.orderId);

  // Helper to update the order from the UI
  void changePrice(double newPrice) {
    final currentOrder = _orderBridge.readableSignal.value;
    if (currentOrder != null) {
      // This triggers the 'update' callback defined above
      _orderBridge.value = currentOrder.copyWith(price: newPrice);
    }
  }
}
```

With this setup:
- If `OrdersNode` updates the list (e.g., from a websocket), `DetailNode` updates automatically.
- If `DetailNode` changes the price, `OrdersNode` receives the update and the list (and any other listeners) update automatically.

# Why Trinity?

Trinity was born from the necessity to simplify code while ensuring robustness. Drawing inspiration from the most popular state management solutions—Bloc, GetX, and Riverpod—Trinity aims to unify their strengths while mitigating their weaknesses.

### The Landscape

- **Bloc**: Celebrated for its robustness and adherence to good practices via the widget tree lifecycle. However, it suffers from excessive boilerplate (requiring repetitive variable definitions for constructors, `Equatable`, getters, and `copyWith`) and lacks native inter-bloc communication.
- **GetX**: Loved for its flexibility and minimal file count. However, its heavy reliance on runtime checks makes it error-prone, and managing controllers outside the widget tree often leads to unmaintainable code and bad practices.
- **Riverpod**: A strong middle ground with excellent dependency injection. However, its lifecycle management can be confusing (e.g., balancing caching with auto-dispose), and the architectural separation of data from controllers can complicate flow control.

### The Trinity Solution

Trinity offers a balanced approach:

- **Zero Boilerplate**: Forget about managing massive state objects or implementing `Equatable`. In Trinity, each property manages its own state independently. Controllers simply update specific values, and only the relevant components rebuild.
- **Flutter-Native Robustness**: Utilizing `TrinityScope`, you can access any active node from anywhere in your app—whether navigating screens or opening dialogs. Nodes remain available while needed and are automatically cleaned up from memory when their master page is closed.
- **Modular Controllers**: Say goodbye to "God Controllers." `TrinityScope` removes barriers between nodes, enabling secure cross-communication. You can use **Bridges** to derive local state from a parent node or access parent data directly without duplication (e.g., accessing `orders.length` from `OrdersNode` inside `OrderDetail`).
- **Signals at the Core**: Signals act as state translators. Whether you have a mutable value, a stream, or a future, Trinity wraps it into a reactive Signal that manages the underlying complexity. No more manual stream creation—just wrap your data in a Signal and let Trinity handle the rest.
- **Componentization First**: Trinity prioritizes efficient UI updates. The `SignalBuilder` listens exclusively to the specific Signal it requires. If the `orders` signal updates, your list rebuilds, but unrelated changes (like `isLoading`) won't trigger unnecessary repaints.