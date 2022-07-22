import 'package:flutter/material.dart';

import 'home_page.dart';
import 'receipt_explorer_page.dart';
import 'package:receiptcamp/pages/login_page.dart';

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
      case 'LoginPage':
        return MaterialPageRoute(builder: (_) => LoginPage());
      /*
      SYNTAX to vist another page is shown commented here
      case 'AnotherPage':
      return MaterialPageRoute(builder: (_) => AnotherPageClassName());
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
