import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

class NodeGenerator extends Generator {
  @override
  String? generate(LibraryReader library, BuildStep buildStep) {
    final buffer = StringBuffer();

    for (final cls in library.classes) {
      if (!_extendsNodeInterface(cls)) continue;

      final signalFields = _getSignalFields(cls);
      if (signalFields.isEmpty) continue;
      final className = cls.name;
      final readableName = 'Readable$className';

      buffer.writeln('class $readableName {');
      buffer.writeln('  final $className _node;');
      buffer.writeln('  const $readableName(this._node);');
      buffer.writeln();

      for (final field in signalFields) {
        final valueType = _resolveSignalValueType(field);
        buffer.writeln(
          '  $valueType get ${field.name} => '
          '_node.${field.name}.readable.value;',
        );
      }
    }

    if (buffer.isEmpty) return null;
    // Obtiene el nombre del archivo fuente para el part of
    final sourceUri = library.element.firstFragment.source.uri;
    final fileName = sourceUri.pathSegments.last;
    return "part of '$fileName';\n\n$buffer";
  }

  // Sube la cadena de herencia buscando NodeInterface
  bool _extendsNodeInterface(ClassElement cls) {
    var supertype = cls.supertype;
    while (supertype != null) {
      if (supertype.element.name == 'NodeInterface') return true;
      supertype = supertype.element.supertype;
    }
    return false;
  }

  // Campos cuyo tipo sea Signal<T> o derive de él
  List<FieldElement> _getSignalFields(ClassElement cls) {
    return cls.fields.where((f) => _isSignal(f.type)).toList();
  }

  bool _isSignal(DartType type) {
    if (type is! InterfaceType) return false;
    if (type.element.name == 'Signal') return true;
    return type.element.allSupertypes.any((t) => t.element.name == 'Signal');
  }

  // Extrae T de Signal<T>, subiendo supertypes si hace falta
  String _resolveSignalValueType(FieldElement field) {
    final type = field.type;
    if (type is! InterfaceType) return 'dynamic';

    // Si el tipo ya ES Signal<T>, tomamos el argumento directo
    if (type.element.name == 'Signal') {
      if (type.typeArguments.isEmpty) return 'dynamic';
      return type.typeArguments.first.getDisplayString();
    }

    // Si es subtype (BridgeSignal, etc.), buscamos en los supertypes
    // del TIPO INSTANCIADO (no del elemento)
    final signalType = type
        .allSupertypes // <-- aquí el cambio
        .where((t) => t.element.name == 'Signal')
        .firstOrNull;

    if (signalType == null || signalType.typeArguments.isEmpty) {
      return 'dynamic';
    }

    return signalType.typeArguments.first.getDisplayString();
  }
}
