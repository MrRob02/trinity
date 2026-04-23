## 0.5.0
* Changes in `NodeProvider` lifecycle.
* Corrected `TransformBridgeSignal` to accept `BaseSignal` instead of `Signal`.

## 0.4.1
* Added `BoolSignal`
* Added `NullableListSignal`

## 0.4.0
* Added `ListSignal` and `IterableSignal`

## 0.3.8
* Created `ProtectedSignal` as a signal that can be read from the outside, but can only be written to from the inside.
* Created `StreamSignalWithInitialValue`
* Added `onInit` callback to `NodeProvider` and `NodeProvider.reuse()`.

## 0.3.7
* Improve `NodeProvider` speed when disposing nodes.

## 0.3.6
* Fixed `ComputedSignal` to extend `BaseSignal` instead of `Signal`

## 0.3.5
* Added `findNodeOrNull` inside `Node` using `late`

## 0.3.4
* Added `findNode` inside `Node` using `late`
* Removed forced nullable when using `BridgeSignal`

## 0.3.3
* Fixed `findNode` to allow use on `initState()` method

## 0.3.2
* Fixed `ComputedSignal` and `ComputedSignalMany` to use named parameters instead of positional parameters.

## 0.3.1
* Added `ComputedSignalMany` as a read-only signal whose value is derived from multiple signals.

## 0.3.0
* Changed SignalListenerMany to receive `List<SignalListenerItem>` instead of a list of signals

## 0.2.1
* Added `ComputedSignal` as a read-only signal whose value is derived from another signal.

## 0.2.0
* Added `NodeProvider.reuse()` constructor.
* Fix docs.

## 0.1.7
* Remove function bulder for `(node)=>node.mySignal` in SignalBuilder and SignalBuilderMany

## 0.1.6
* Added `SignalListener` and `SignalListenerMany` widgets.
* Added `when` function to `FutureSignal`.
* Translated all remaining exceptions and comments to English.

## 0.1.5
* Added listener to `SignalBuilder` and `SignalBuilderMany`.
* Fixed `SignalBuilder` and `SignalBuilderMany` to initialize futures on the first frame.
* Changed `StreamSignal` result.

## 0.1.4
* Fix pub.dev documentation

## 0.1.3
* Add `NodeProvider`, `NodeInterface`, and `BaseSignal` for structured node and signal management.

## 0.1.2
* Remove build.yaml

## 0.1.1
* Extracted node generation logic to the `trinity_generator` package and removed internal build dependencies.

## 0.1.0
* Separate `BridgeSignal` into `BridgeSignal` and `TransformBridgeSignal`
* Shortened `Signal` function in `SignalBuilder` to allow returning the signal, not the readable
* Fixed generator to generate `ReadableNode` for nodes with signals