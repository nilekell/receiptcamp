import 'package:flutter/material.dart';
import 'package:receiptcamp/presentation/screens/a_file_explorer.dart';
import 'package:receiptcamp/presentation/screens/home.dart';

class AppRouter {
  Route onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (_) => const Home(),
        );
      case '/explorer':
        return MaterialPageRoute(
          builder: (_) => const FileExplorer()
        );
      default:
        return _errorRoute();
    }
  }
}

Route<dynamic> _errorRoute() {
  return MaterialPageRoute(builder: (_) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Error"),
        ),
        body: const Center(
          child: Text('ERROR'),
        ));
  });
}