
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