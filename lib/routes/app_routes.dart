
import '../screen/input_screen.dart';
import '../screen/main_screen.dart';
import '../screen/splash_screen.dart';
import 'route_name.dart';

class AppRoutes {
  static final routes = {

    RouteNames.splashScreen: (context) => Splashscreen(),
    RouteNames.mainScreen: (context) => MainScreen(),
    RouteNames.inputScreen: (context) => InputScreen(),

  };
}