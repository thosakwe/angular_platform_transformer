# angular_platform_transformer
# angular_platform_transformer
[![Pub](https://img.shields.io/pub/v/angular_platform_transformer.svg)](https://pub.dartlang.org/packages/angular_platform_transformer)
[![build status](https://travis-ci.org/thosakwe/angular_platform_transformer.svg)](https://travis-ci.org/thosakwe/angular_platform_transformer)

Brings back PLATFORM_DIRECTIVES and PLATFORM_PIPES in Angular Dart 4.

As of `package:angular@4.0.0`, the `angular` transformer no longer supports `PLATFORM_DIRECTIVES` and `PLATFORM_PIPES`,
which effectively allowed to you import directives and pipes into all of your components without having to explicitly declare them.

This package is a *transformer*, and it automatically rewrites your `@Component()` annotations to import the directives and pipes
declared in the transformer configuration.

**Please, do not use this in packages published to Pub, as not every user will be using this package.**
It is perfectly suitable for in-house dev, or side projects.

# Installation and Usage
In your `pubspec.yaml`:

```yaml
dev_dependencies:
  angular_platform_transformer: ^1.0.0
transformers:
  - angular_platform_transformer:
      directives:
        - "package:angular/angular.dart#COMMON_DIRECTIVES"
      pipes:
        - "package:foo/foo.dart#BAR_BAZ"
```

