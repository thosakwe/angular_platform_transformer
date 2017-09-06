import 'dart:io';
import 'package:barback/barback.dart';
import 'package:code_transformers/messages/build_logger.dart';
import 'package:code_transformers/resolver.dart';
import 'package:dart_style/dart_style.dart';
import 'src/apply_platform.dart';

class AngularPlatformTransformer extends Transformer {
  static final DartFormatter _fmt = new DartFormatter();

  final Resolvers resolvers = new Resolvers(
      new File(Platform.resolvedExecutable).parent.parent.absolute.path);

  final BarbackSettings settings;

  AngularPlatformTransformer.asPlugin(this.settings);

  @override
  String get allowedExtensions => '.dart';

  @override
  apply(Transform transform) async {
    List<String> directives = settings.configuration['directives'] ?? [],
        pipes = settings.configuration['pipes'] ?? [];

    var resolver =
        await resolvers.get(transform, [transform.primaryInput.id], false);
    var lib = resolver.getLibrary(transform.primaryInput.id);
    var logger = new BuildLogger(transform);

    if (settings.configuration['verbose'] == true)
      logger.info('Config: ${settings.configuration}');

    var inj = new PlatformInjector(
      logger,
      resolver,
      transform.primaryInput.id.package,
      settings.configuration['verbose'] == true,
      directives: directives,
      pipes: pipes,
    );

    var transformed = inj.apply(lib);
    var formatted = _fmt.format(transformed.toSource());

    if (settings.configuration['verbose'] == true)
      logger.info('New source:\n$formatted');

    resolver.release();

    transform.addOutput(new Asset.fromString(
      transform.primaryInput.id,
      formatted,
    ));
  }

  @override
  String toString() => 'package:angular_platform_transformer';
}
