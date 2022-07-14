import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'main.dart';
import 'receipt_explorer_page.dart';

class RouteGenerator {
  // static function to generate route
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // getting arguments passed in while callling Navigator.pushNamed()
    final args = settings.arguments;

    // checking if the name of the route is the home route
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => MyHomePage());
      case 'ReceiptExplorer':
        return MaterialPageRoute(builder: (_) => ReceiptExplorer());
      /*
      SYNTAX to vist another page is shown commented here
      case 'AnotherPage':
      return MaterialPageRoute(builder: (_) => AnotherPage());
      */

      default:
        return _errorRoute();
    }
  }
}

Route<dynamic> _errorRoute() {
  return MaterialPageRoute(builder: (_) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Error"),
        ),
        body: Center(
          child: Text('ERROR'),
        ));
  });
}
