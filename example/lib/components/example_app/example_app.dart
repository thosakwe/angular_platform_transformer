import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';

@Component(selector: 'example-app', templateUrl: 'example_app.html')
@RouteConfig(const [
  const Route(path: '/a', name: 'A', component: AComponent, useAsDefault: true),
  const Route(path: '/b', name: 'B', component: BComponent),
])
class ExampleAppComponent {}

@Component(selector: 'a-cmp', template: 'Hey! A component!')
class AComponent {}

@Component(selector: 'b-cmp', template: 'Another component!')
class BComponent {}
