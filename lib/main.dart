import 'package:flutter/material.dart';
import 'package:notepad/routes/app_routes.dart';
import 'package:notepad/routes/route_name.dart';

import 'constants/theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notepad',
      theme: appTheme,
      initialRoute: RouteNames.splashScreen,
      routes:AppRoutes.routes ,
    );
  }
}

