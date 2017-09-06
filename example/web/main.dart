import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:example/components/example_app/example_app.dart';

main() {
  bootstrap(ExampleAppComponent, [
    ROUTER_PROVIDERS,
    const Provider(
      LocationStrategy,
      useClass: HashLocationStrategy,
    ),
  ]);
}
