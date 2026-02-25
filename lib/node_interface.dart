import 'package:flutter/material.dart';
import 'package:trinity/models/signal.dart';
import 'package:trinity/node.dart';
import 'package:trinity/node_anatomy.dart';

///You can use this class to add loading and error states to your nodes
///```dart
/// ReadableSignal<bool> isLoading
///
/// ReadableSignal<Object?> error
///
/// //A separate signal for full screen loading
/// ReadableSignal<bool> fullScreenLoading
///
/// //You can use the [loading] method to wrap any async operation
/// //so you don't have to handle the loading state yourself
/// Future<T> loading<T>(
///    Future<T> future, {
///    bool invokeLoading = true,
///    //If you want to show a full screen loading, just set this to true
///    bool fullScreen = false,
///  })
///```
abstract class NodeInterface<R> extends Node {
  late final isLoading = registerSignal(Signal<bool>(false));
  late final fullScreenLoading = registerSignal(Signal<bool>(false));
  late final error = registerSignal(NullableSignal<Object>());

  static N of<N extends NodeInterface>(BuildContext context) {
    return context.findNode<N>();
  }

  Future<T> loading<T>(
    Future<T> Function() future, {
    bool invokeLoading = true,
    bool fullScreen = false,
  }) async {
    if (invokeLoading) {
      if (fullScreen) {
        fullScreenLoading.value = true;
      } else {
        isLoading.value = true;
      }
    }
    try {
      return await future();
    } catch (e) {
      error.emit(e);
      rethrow;
    } finally {
      if (invokeLoading) {
        if (fullScreen) {
          fullScreenLoading.value = false;
        } else {
          isLoading.value = false;
        }
      }
    }
  }

  Widget when<W extends Widget>({
    required W Function() loading,
    required W Function(Object) error,
    required W Function() orElse,
  }) {
    if (isLoading.value) {
      return loading();
    }
    if (this.error.value != null) {
      return error(this.error.value!);
    }
    return orElse();
  }
}
