import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'node_generator.dart';

Builder nodeBuilder(BuilderOptions options) =>
    LibraryBuilder(NodeGenerator(), generatedExtension: '.g.dart');
