import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:angular/src/core/metadata.dart' as ng;
import 'package:barback/barback.dart';
import 'package:code_transformers/resolver.dart';
import 'package:source_gen/source_gen.dart';

class PlatformInjector extends RecursiveAstVisitor {
  final List<String> directives = [], pipes = [];
  final TransformLogger logger;
  final Resolver resolver;
  final String packageName;
  final bool verbose;

  static final TypeChecker _component =
      const TypeChecker.fromRuntime(ng.Component);

  static final Token _at = new Token(TokenType.AT, 0),
      _colon = new Token(TokenType.COLON, 0),
      _const = new KeywordToken(Keyword.CONST, 0),
      _lbracket = new Token(TokenType.OPEN_SQUARE_BRACKET, 0),
      _rbracket = new Token(TokenType.CLOSE_SQUARE_BRACKET, 0),
      _lparen = new Token(TokenType.OPEN_PAREN, 0),
      _rparen = new Token(TokenType.CLOSE_PAREN, 0);

  PlatformInjector(this.logger, this.resolver, this.packageName, this.verbose,
      {Iterable<String> directives: const [],
      Iterable<String> pipes: const []}) {
    this.directives.addAll(directives ?? []);
    this.pipes.addAll(pipes ?? []);
  }

  CompilationUnit apply(LibraryElement lib) {
    var ctx = lib.definingCompilationUnit.computeNode();
    ctx.accept(this);

// Add imports
    var newDirectives = new List<Directive>.from(ctx.directives)
      ..addAll((new List<String>.from(directives)..addAll(pipes))
          .map<ImportDirective>((spec) {
        var uri = spec.split('#')[0];
        return astFactory.importDirective(
          null,
          null,
          new KeywordToken(Keyword.IMPORT, 0),
          astFactory.simpleStringLiteral(
              new StringToken(
                  TokenType.STRING, '"' + uri.replaceAll('"', '\\"') + '"', 0),
              uri),
          null,
          null,
          null,
          null,
          null,
          new Token(TokenType.SEMICOLON, 0),
        );
      }));

    var transformed = astFactory.compilationUnit(ctx.beginToken, ctx.scriptTag,
        newDirectives, ctx.declarations, ctx.endToken);

    return transformed;
  }

  @override
  visitCompilationUnit(CompilationUnit ctx) {
    // Crawl all imports
    for (var directive in ctx.directives) {
      if (directive is ImportDirective &&
          directive.uriContent.contains(packageName)) {
        var lib = resolver.getLibraryByUri(Uri.parse(directive.uriContent));
        if (lib != null)
          visitCompilationUnit(lib.definingCompilationUnit.computeNode());
      }
    }

    super.visitCompilationUnit(ctx);
  }

  void visitClassDeclaration(ClassDeclaration ctx) {
    if (verbose) logger.info('Entering class ${ctx.name.name}');
    var matching = _component.firstAnnotationOfExact(ctx.element);

    if (matching == null) return;

    for (int i = 0; i < ctx.metadata.length; i++) {
      var ann = ctx.metadata[i];

      if (ann.elementAnnotation?.constantValue == matching) {
        ({
          'directives': directives,
          'pipes': pipes,
        }).forEach((targetName, targetList) {
          // Create a new argument list, with every argument preserved
          // EXCEPT `directives`.
          var args = <Expression>[];
          NamedExpression target;

          for (var arg in ann.arguments.arguments) {
            if (arg is NamedExpression && arg.name.label.name == targetName) {
              target = arg;
            } else {
              args.add(arg);
            }
          }

          // Compile a list of necessary identifiers
          var injections = <Identifier>[];
          var finalArgs = <Expression>[];

          for (var spec in targetList) {
            var split = spec.split('#');
            injections.add(astFactory.simpleIdentifier(
                new StringToken(TokenType.IDENTIFIER, split[1], 0)));
          }

          if (target == null) {
            // Create a new list arg
            finalArgs = injections;
          } else {
            // Ensure the arg is a list
            if (target.expression is! ListLiteral) {
              throw new UnsupportedError(
                  'The value of `$targetName` in class `${ctx.name}` must be a list literal.');
            }

            //  Add to the existing list
            var list = target.expression as ListLiteral;
            finalArgs = new List<Expression>.from(list.elements)
              ..addAll(injections);
          }

          args.add(
            astFactory.namedExpression(
              astFactory.label(
                astFactory.simpleIdentifier(
                    new StringToken(TokenType.IDENTIFIER, targetName, 0)),
                _colon,
              ),
              astFactory.listLiteral(
                _const,
                null,
                _lbracket,
                finalArgs,
                _rbracket,
              ),
            ),
          );

          var argList = astFactory.argumentList(_lparen, args, _rparen);
          var newAnnotation =
              astFactory.annotation(_at, ann.name, null, null, argList);
          var replacer = new NodeReplacer(ann, newAnnotation);
          if (verbose) {
            logger.info(
                'New @Component() directive: ${newAnnotation.toSource()}');
          }
          ctx.accept(replacer);
          ann = newAnnotation;
        });

        break;
      }
    }
  }
}
